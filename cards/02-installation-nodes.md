# Installation & Nodes

Q: What three modes does the Harvester ISO installer offer at boot?
A: The installer lets you **create a new Harvester cluster**, **join an existing cluster**, or **install Harvester binaries only** (for a later scripted config). Creating makes this the first node; joining requires the existing cluster's **VIP** and **cluster token**.

Q: How do you perform an automated (unattended) install via PXE/iPXE?
A: Boot the node over **PXE/iPXE** and point the kernel to a **Harvester configuration file** (served over HTTP) with the boot arg `harvester.install.config_url=<url>`. The config file supplies all answers the interactive installer would otherwise prompt for, so no console interaction is needed.

Q: What is the Harvester install config file and what style does it use?
A: A YAML file (commonly `config.yaml` / `config-create.yaml`) describing the node: install mode, disks, hostname, networking, VIP, token, SSH keys, etc. It is **cloud-init style** and embeds an `os:` section for host-OS settings; the same file can be referenced by URL during PXE install or pasted into the ISO installer.

Q: What is the difference between creating and joining a cluster during install?
A: **Create** bootstraps a brand-new cluster; the first node becomes the initial management node and defines the VIP and token. **Join** adds a node to an existing cluster — you must supply that cluster's **management VIP** and its **cluster token** so the new node can authenticate and register.

Q: What is the management VIP in Harvester?
A: A **virtual IP** that floats across the management nodes and provides a single, stable endpoint for the Harvester UI/API and for new nodes joining the cluster. It can be assigned via **DHCP** or set **statically**, and it follows the active management node if one fails.

Q: What is the cluster token used for?
A: It is a **shared secret** set when the cluster is created. Every node that joins must present the same token (along with the VIP) to be admitted. It authenticates node enrollment, similar to an RKE2/K3s join token.

Q: What node roles exist in a Harvester cluster?
A: **Management** nodes run the control plane (etcd + Kubernetes control plane) and can also run VMs; **worker/compute** nodes only run workloads and are **never promoted** to management; and a special **witness** node participates in etcd quorum only. Roles can be pre-assigned at install time.

Q: What is a witness node and why would you use one?
A: A **witness node** joins the cluster purely as an **etcd/quorum member** — it does not run VM workloads. It lets you keep an **odd number of etcd members** (e.g. 2 management + 1 witness) so the cluster tolerates one failure without dedicating a third full management host. A cluster has **at most one** witness node.

Q: Why is a 3-node minimum recommended for a highly-available Harvester cluster?
A: etcd needs an **odd quorum majority** to survive a failure. With **three management (etcd) members** the cluster tolerates exactly **one node failure** and still keeps quorum. A single-node install has no HA, and two members cannot form a fault-tolerant quorum.

Q: How does automatic node promotion work?
A: When a cluster has fewer than three management nodes and additional nodes join, Harvester **auto-promotes** eligible nodes to management to reach three, restoring HA. Promotion is only triggered by a management node being **deliberately deleted** — not by a node being temporarily down. Nodes pre-assigned the **worker** role are excluded from promotion.

Q: Why is the Harvester host OS described as immutable?
A: Harvester runs on an **immutable OS based on SLE Micro / Elemental**: the root filesystem is read-only and not meant to be hand-edited. Persistent changes are made declaratively through **CloudInit resources** (applied via `kubectl`) or the UI, and survive upgrades, which keeps every node reproducible.

Q: How do you add a new node to an existing Harvester cluster?
A: Install Harvester on the new host in **Join** mode, giving it the cluster's **VIP** and **token** (interactively or via a config file). Once it registers it appears in Hosts; if HA needs it, Harvester may auto-promote it to management. VMs can then be scheduled onto it.

Q: What must you do to safely remove a node from the cluster?
A: Confirm the remaining nodes have enough CPU/memory/storage and that Longhorn volumes are healthy; **evict Longhorn replicas** off the node; handle non-migratable VMs (shutdown/snapshot); put the node into **Maintenance Mode** so live-migratable VMs drain off; then run the RKE2 uninstall script (`/opt/rke2/bin/rke2-uninstall.sh`) on it and **delete the host** from the UI.
