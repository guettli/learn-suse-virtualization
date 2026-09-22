# Upgrades

Q: How is a cluster upgrade initiated and orchestrated in SUSE Virtualization?
A: Upgrades are driven by the built-in **Upgrade** feature: clicking **Upgrade** in the dashboard creates an **Upgrade custom resource (CRD)** that the system reconciles. A managed **upgrade repository** (a Deployment as of v1.7.0) serves the new artifacts to every node.

Q: Where does the new version's content come from during an upgrade?
A: From an official **release channel** (e.g., `releases.rancher.com/harvester/{version}`) that the dashboard offers when a new version is available. For **air-gapped** clusters you download the release **ISO**, host it locally, and point a modified `version.yaml` (`isoURL`) at it.

Q: What kinds of pre-upgrade checks does SUSE Virtualization run?
A: It validates readiness before proceeding, including: sufficient **free system-partition space** per node, **certificate validity**, **NTP time sync** across nodes, and general cluster health. Failing checks (e.g., low disk) **block the upgrade** until resolved.

Q: How does an upgrade keep VMs available while updating nodes?
A: Nodes are upgraded **one at a time**. Before a node is drained/rebooted, its **live-migratable VMs are automatically live-migrated** to other nodes, so running VMs stay available with no downtime while each node reboots into the new version.

Q: Why should VMs be live-migratable for a smooth upgrade?
A: Only migratable VMs can be **moved off a node** before it reboots. **Non-migratable** VMs must instead be **shut down** (manually or automatically, per the upgrade config) during their node's turn, causing downtime. Making VMs migratable lets the rolling upgrade proceed without stopping workloads.

Q: What components get upgraded together in a single SUSE Virtualization upgrade?
A: An upgrade is a **bundle**: the host OS (**SUSE Linux Micro**), the Kubernetes distribution (**RKE2**), and managed components (**KubeVirt, Longhorn/SUSE Storage, Rancher**) all advance **in lockstep**. You do not upgrade these pieces independently.

Q: What are the rules about which versions you can upgrade to and from?
A: Direct upgrades are limited to about **one minor version at a time** (e.g., v1.5.x → v1.6.x). **Skipping minor versions is not allowed**; you must step through intermediate releases, consistent with upstream Kubernetes version-skew rules. Consult the official upgrade matrix for exact supported paths.

Q: Can you roll back or downgrade after an upgrade?
A: No. SUSE Virtualization **does not support downgrades/rollback** of the cluster version. Because the OS, Kubernetes, and components move together, reverting risks incompatibility and data corruption — so protect against a bad upgrade with **VM backups** beforehand instead.

Q: How do air-gapped upgrades differ from connected ones?
A: In air-gapped environments there is no reachable release channel, so you **download the release ISO** yourself, host it on a local HTTP(S) server, and provide a custom **`version.yaml`** whose `isoURL` points at it. The upgrade then proceeds using those locally hosted artifacts.

Q: How do you monitor upgrade progress and troubleshoot it?
A: The dashboard shows a live **upgrade progress** view (open the progress/status indicator) tracking per-node and per-component phases. The **Upgrade CRD** status and pod/job logs provide deeper detail, and individual node upgrades can be paused for manual maintenance between phases.
