# Elemental & Edge

Q: What is Elemental in the Rancher ecosystem?
A: **Elemental** is Rancher's stack for **cloud-native, immutable-OS management**. It turns bare-metal and edge machines running an immutable OS (**SL Micro / SLE Micro**, or openSUSE Leap Micro) into **Rancher-managed nodes**, with OS install, config, and upgrades driven centrally from Rancher Manager.

Q: What are the two main software pieces of Elemental (operator vs client)?
A: - **elemental-operator** — runs in the Rancher cluster; reconciles Elemental CRDs (MachineRegistration, MachineInventory, ManagedOSImage, etc.) and talks to Rancher.
- **elemental-register** — the client binary baked into the OS image; on boot it contacts a MachineRegistration endpoint to **register the host** and trigger install via `elemental` (elemental-cli).

Q: What does a MachineRegistration CRD define?
A: A **MachineRegistration** describes how new machines enroll: the **cloud-init/install config**, labels/annotations to apply, and which cluster/pool they join. It exposes a **registration URL** that `elemental-register` on a booting host calls to claim an identity and receive its install configuration.

Q: What is a MachineInventory in Elemental?
A: A **MachineInventory** is the CRD representing an **individual enrolled machine** (one per host) — its identity, TLS/registration secret, labels, and state. Selecting MachineInventories (by label) is how you assign hardware into a downstream **cluster** via an inventory selector.

Q: What do ManagedOSImage and ManagedOSVersion CRDs do?
A: - **ManagedOSVersion** — defines an available **OS image version** (metadata: type `iso` for building seed images, or `container` for upgrades).
- **ManagedOSImage** — declares the **desired OS image/version for a set of nodes**; the operator generates a **Fleet Bundle** that applies an `upgrade.cattle.io` **Plan** run by the **System Upgrade Controller** on the target cluster.

Q: What is a SeedImage (and ManagedOSVersionChannel) used for?
A: A **SeedImage** builds a **bootable installer ISO/seed image** from a ManagedOSVersion plus a MachineRegistration reference, so a booted host auto-registers. A **ManagedOSVersionChannel** subscribes to an upstream feed and auto-populates available **ManagedOSVersions** (used for ISO builds and upgrades).

Q: How do Elemental OS upgrades work?
A: Elemental uses **immutable A/B upgrades**: a new OS image is deployed to the passive partition and the node **reboots into it**, with automatic **rollback** to the previous image if boot fails. Upgrades are driven declaratively by a **ManagedOSImage** → Fleet → System Upgrade Controller Plan, not by patching packages in place.

Q: What reset and recovery capabilities does Elemental provide?
A: Because the OS is **immutable**, Elemental keeps a **recovery partition** to boot into and **reset** a node to a clean, freshly-registered state (e.g. re-provision or decommission). Persistent state lives on separate partitions (e.g. `/oem`, persistent), so a reset restores the OS without losing declared machine config.

Q: How does Elemental fit with Cluster API / cluster provisioning?
A: Enrolled **MachineInventories** are consumed by Rancher provisioning as node sources; Elemental integrates with Rancher's **CAPI-based** provisioning (provisioning.cattle.io / Cluster API) to stand up a downstream **RKE2/K3s** cluster on the registered bare-metal hosts — Elemental supplies the machines, Rancher/CAPI builds the cluster on them.

Q: How does Elemental differ from a node driver or cloud VMs, and where does it fit in SUSE Edge?
A: Node drivers/cloud providers spin up **cloud VMs** on demand; **Elemental** manages **pre-existing bare-metal/edge hardware** with an immutable OS you can't just re-clone — ideal for **air-gapped and edge** sites (register once, manage remotely, A/B upgrade). It is a building block of the **SUSE Edge** stack (Elemental + RKE2 + Fleet + Rancher/Metal3) for large-scale edge fleets.
