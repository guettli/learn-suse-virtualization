# Troubleshooting

Q: A VM is stuck in "Starting" or "Scheduling" — likely cause, check, and fix?
A: Likely **no node can schedule the virt-launcher pod** — insufficient CPU/memory, or a network affinity rule with no matching node. Check `kubectl describe vmi <vm>` and the virt-launcher pod's events. Fix: free or add node resources, or ensure nodes carry the required cluster-network labels.

Q: A live migration is stuck or failing — what typically blocks it?
A: A **non-migratable device or storage** — e.g. a passthrough PCI/host device, or a disk on non-shared storage. Check the `VirtualMachineInstanceMigration` object status and virt-launcher logs. Fix: remove the non-migratable device, or move the VM to migratable Longhorn-backed volumes.

Q: A Longhorn/SUSE Storage volume shows "Degraded" and rebuilding — what does that mean?
A: One or more **replicas are unhealthy** (a node or disk is down), so Longhorn is **rebuilding** to restore the configured replica count; data is still served from healthy replicas. Check the Longhorn UI or `kubectl -n longhorn-system get volumes`. It usually self-heals once the failed node/disk returns or spare capacity exists.

Q: A node goes NotReady — what happens to its VMs and what do you do?
A: The node's **VMIs stop running**, and a running VMI cannot live-migrate off a dead node. Check `kubectl get nodes` and the node conditions. Fix the node (or cordon/drain it); VMs on migratable storage can then be restarted elsewhere, and Longhorn rebuilds replicas onto healthy nodes.

Q: How do you generate a support bundle for SUSE support?
A: In the UI click **Support** (bottom-left) then **Generate Support Bundle**, enter a description, and it collects logs plus resource state and downloads a zip to attach to your support case. Use the **support-bundle-namespaces** setting to include extra workload namespaces.

Q: What's the fastest kubectl way to see why a VM or pod is misbehaving?
A: Read the **events**: `kubectl describe vmi/<vm>` (or the virt-launcher pod) and `kubectl get events -n <ns> --sort-by=.lastTimestamp`. Events surface scheduling failures, image-pull errors, and volume-attach problems before you need to dig into pod logs.

Q: A VM has no network connectivity — likely cause and check?
A: Usually a **missing or misconfigured NetworkAttachmentDefinition, or a wrong VLAN**. Check that the VM interface references an existing NAD, that the cluster network / `vlanconfig` is applied to the node's uplink, and that the VLAN ID is trunked on the switch. Fix the NAD/VLAN config, then restart the VM.

Q: An image import (VirtualMachineImage) fails — how do you troubleshoot?
A: Likely a **bad/unreachable URL, unsupported format, or timeout**. Check the `VirtualMachineImage` status conditions and events for the download error. Fix the URL/credentials or proxy, confirm a supported format (qcow2/raw), and ensure enough backing storage exists.

Q: The dashboard warns storage is over-provisioned, or a disk is full — what's going on?
A: Longhorn **thin-provisions** volumes, so allocated capacity can exceed physical disk; real usage then filling a node's disk stalls VMs and replica rebuilds. Check node/disk usage in the Longhorn UI. Fix: add disks or nodes, delete unused volumes/snapshots, or adjust the over-provisioning / storage-reserve settings.

Q: A running VM shows no IP address in the UI — why, and how do you fix it?
A: The **qemu guest agent isn't installed or running**, so Harvester can't read the guest's IP. Check whether the agent is present (installed via cloud-init) and active in the guest. Fix: install and enable `qemu-guest-agent`, then restart the VM — the reported IP then appears.

Q: An upgrade is stuck — where do you look?
A: Check the **upgrade objects and System Upgrade Controller plan pods** (`kubectl get upgrades`, plan jobs) plus node status — a NotReady node or a VM that refuses to migrate during a node drain often blocks progress. Fix the offending node/VM (or force-delete a stuck launcher pod), and grab a support bundle if it still can't proceed.

Q: Where are the key logs when debugging a VM or storage problem?
A: The **virt-launcher pod** logs (`kubectl logs -n <ns> virt-launcher-<vm>-xxxxx`) for the VM/QEMU itself, and **longhorn-manager** plus engine/replica pods in `longhorn-system` for storage. Node-level KubeVirt logs come from the **virt-handler** daemonset pods.
