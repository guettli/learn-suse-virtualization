# Lifecycle & Updates

Q: What is vSphere Lifecycle Manager (vLCM)?
A: **vSphere Lifecycle Manager (vLCM)** is the vSphere 8 service that manages ESXi host software and firmware lifecycle from vCenter. Its modern model applies a single **desired-state cluster image** to every host in a cluster, checking compliance and remediating drift, so all hosts converge on one defined software/firmware spec.

**SUSE Virtualization:** The built-in **Harvester upgrade** flow (an **Upgrade** CRD) plays the same role, rolling the whole cluster to one released image covering OS, Kubernetes, and components together.

Q: How does vLCM shift host updates from baselines to a desired-state image?
A: The old **baselines** model attached lists of individual patches/upgrades to hosts and reported which were missing. vLCM's **cluster image** model instead declares one **desired end state** for the whole cluster; vLCM makes every host match that image. It is declarative (define the target) rather than incremental (add these patches).

**SUSE Virtualization:** Likewise **declarative** — you upgrade to a **whole immutable release** (a single OS/K8s image), not by attaching per-host patch lists.

Q: What was VMware Update Manager (VUM)?
A: **VMware Update Manager (VUM)** was the legacy patching tool, driven entirely by **baselines** and baseline groups. It was the predecessor to vLCM; its baseline workflow was folded into vLCM and is deprecated, with cluster images being the current, recommended approach.

**SUSE Virtualization:** No separate legacy patch tool — there is one **Harvester upgrade** mechanism (the Upgrade CRD) rather than an old baseline-driven predecessor.

Q: What is the difference between a baseline and a cluster image in vLCM?
A: A **baseline** is a set of individual patches/upgrades checked per host (legacy, additive). A **cluster image** is a complete **desired-state definition** for the whole cluster — ESXi version plus vendor content — that vLCM enforces uniformly. A cluster is managed by one or the other, not both.

**SUSE Virtualization:** Closest to the **cluster image** side only — an upgrade targets a **whole release** (immutable image) for every node, with no per-host baseline alternative.

Q: What components make up a vLCM cluster image?
A: A cluster image is built from: the **ESXi base image** (the vanilla ESXi release from VMware), an optional **vendor add-on** (OEM customizations/drivers for that server model), optional standalone **components** (extra drivers or software), and an optional **firmware and drivers add-on** supplied via a Hardware Support Manager.

**SUSE Virtualization:** An **upgrade bundle** is a single released artifact combining the **SLE Micro OS, Kubernetes (RKE2), and Harvester components**, but firmware is not part of it (managed out-of-band).

Q: What is a Hardware Support Manager (HSM) and a firmware add-on in vLCM?
A: A **Hardware Support Manager (HSM)** is a vendor-provided plug-in (e.g. Dell OMIVV, HPE) registered with vCenter that lets vLCM manage **server firmware** alongside ESXi. Adding its **firmware and drivers add-on** to the cluster image means one remediation brings both **ESXi software and hardware firmware** to the desired state together.

**SUSE Virtualization:** No equivalent — **server firmware is managed out-of-band** (BMC/vendor tooling); the Harvester upgrade covers only OS/Kubernetes/components.

Q: What are host profiles used for?
A: A **host profile** captures a reference host's configuration (networking, storage, security, services, etc.) as a **desired-state template**. Attaching it to other hosts lets vCenter check **compliance** and **remediate** drift, enforcing consistent host configuration across a cluster and simplifying provisioning of new hosts.

**SUSE Virtualization:** No direct equivalent — hosts run an **immutable SLE Micro** OS with declarative config (config.yaml/cloud-init), so nodes are consistent by construction rather than by compliance remediation.

Q: How does host lifecycle split configuration from software?
A: **Host profiles** govern desired host **configuration** (settings), while **vLCM cluster images** govern desired **software and firmware**. They are complementary: one keeps every host configured the same, the other keeps every host running the same ESXi/driver/firmware stack.

**SUSE Virtualization:** These are not split — the **immutable SLE Micro host** fixes configuration by construction, and a single **Harvester upgrade** advances the software stack, so one release governs both.

Q: What is the difference between staging and remediating an update?
A: **Staging** copies the required patch/image payloads down to the hosts **without applying them** or requiring a reboot — a preparation step that shortens the maintenance window. **Remediating** actually **applies** the image/patches, entering maintenance mode and rebooting as needed to bring hosts into compliance.

**SUSE Virtualization:** The upgrade job first **pre-downloads the release image** onto nodes, then applies it node-by-node (a rolling reboot), so image staging and the disruptive apply are likewise distinct phases.

Q: What happens during vLCM remediation of a host?
A: To remediate, vLCM puts the host into **maintenance mode** (evacuating VMs), applies the desired ESXi image and any firmware, **reboots** if required, then exits maintenance mode and rechecks compliance. It proceeds host-by-host (respecting DRS/HA) so the cluster keeps running throughout.

**SUSE Virtualization:** During an upgrade each node enters **Maintenance Mode**, which **live-migrates** its VMs off and drains it before the node is rebooted onto the new image, proceeding node-by-node.

Q: How does maintenance mode interact with DRS during remediation?
A: Entering **maintenance mode** requires the host to be evacuated of running VMs. In a DRS cluster, **DRS automatically vMotions** those VMs to other hosts so the host can be freed non-disruptively. Without DRS (or with insufficient capacity), VMs must be migrated or powered off manually before the host will enter maintenance mode.

**SUSE Virtualization:** Node **Maintenance Mode** is the analog — it automatically **live-migrates** running VMs to other nodes before draining, keeping workloads up without a DRS-equivalent scheduler being named.

Q: What is Quick Boot in ESXi lifecycle operations?
A: **Quick Boot** restarts the **ESXi hypervisor without re-initializing the physical hardware** — it skips the lengthy BIOS/firmware POST. This dramatically shortens reboots during patching/remediation. It requires supported server hardware and drivers; when available, vLCM uses it to speed up remediation windows.

**SUSE Virtualization:** No direct equivalent — upgrades do a **full node reboot** onto the new image, and disruption is hidden by **live-migrating** VMs off first rather than by skipping hardware POST.
