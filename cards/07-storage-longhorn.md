# Storage (SUSE Storage / Longhorn)

Q: What is SUSE Storage and what does it provide to Harvester?
A: **SUSE Storage is Longhorn**, shipped and supported inside Harvester. It provides **distributed, replicated block storage** built from the local disks of the cluster nodes. VM disks are Longhorn volumes exposed through a CSI StorageClass, so no external SAN/NAS is required for hyperconverged operation.

Q: How does Longhorn protect VM data against a node failure?
A: Each Longhorn volume keeps multiple **replicas** on different nodes and writes to them **synchronously**, so every replica is consistent. The default replica count is **3** (`numberOfReplicas: 3`). If a node dies, the volume stays available from a surviving replica and Longhorn rebuilds a fresh replica elsewhere.

Q: What StorageClass do Harvester VM volumes use by default?
A: The default StorageClass is **`harvester-longhorn`**, which provisions Longhorn volumes with 3 replicas. You can create additional StorageClasses to change parameters such as `numberOfReplicas`, `staleReplicaTimeout`, `dataLocality`, `migratable`, and node/disk selector tags for different performance or availability tiers.

Q: How are Longhorn volumes attached to VMs at the Kubernetes level?
A: Through the **Longhorn CSI driver**. Harvester requests a PVC from a Longhorn StorageClass, the CSI driver provisions and attaches the volume to the node running the VM's virt-launcher pod, and KubeVirt presents it to the guest as a disk. Volume lifecycle (provision/attach/detach/resize) is all CSI-driven.

Q: What volume operations does Harvester/Longhorn support?
A: Common operations include **create**, **expand** (grow capacity online), **clone** (copy into a new volume), **export to image** (turn a volume into a VirtualMachineImage), and **snapshot** (point-in-time state). Snapshots are local restore points on the volume; backups (to an external target) are the off-cluster counterpart.

Q: What does the dataLocality setting do?
A: **`dataLocality`** controls whether a replica is kept on the same node as the workload consuming the volume. `disabled` (default) lets Longhorn place replicas anywhere for balance; `best-effort` tries to keep one local replica to cut read latency and cross-node traffic. It is a hint, not a guarantee.

Q: What do the volume states healthy, degraded, and rebuilding mean?
A: - **Healthy** — all expected replicas are present and in sync.
- **Degraded** — one or more replicas are missing/faulted (e.g. after a node/disk failure); data is still served but redundancy is reduced.
- **Rebuilding** — Longhorn is copying data to a new replica to restore the target count, after which the volume returns to healthy.

Q: What is the difference between the Longhorn v1 and v2 data engines?
A: The **v1 data engine** is the mature default, using a user-space engine exposed through the kernel block/iSCSI path with the full Longhorn feature set. The **v2 data engine** is the newer **SPDK/NVMe-oF** engine that runs in user space for much higher IOPS and lower CPU use, but it is newer and supports fewer features, so v1 remains the general-purpose choice.

Q: What are the tradeoffs of choosing the v2 (SPDK) data engine?
A: v2 delivers near-bare-metal NVMe performance and low latency, best on **NVMe SSDs** (gains shrink on SATA/spinning disks). The costs: it is a **newer engine with reduced feature coverage** versus v1, needs dedicated disk provisioning, and — like v1 — is still bounded by replica network bandwidth since every write is replicated across nodes.

Q: How do you add storage capacity to a Harvester node?
A: In **Hosts > Edit Config > Storage**, add a block device and pick a provisioner: **LonghornV1 (CSI)**, **LonghornV2 (CSI)**, or **LVM**. Unformatted disks need "Force Formatted", and each disk needs a unique WWN. You can apply **storage tags** (e.g. `ssd`, `nvme`) so specific StorageClasses schedule onto those disks.

Q: What do reserved storage and over-provisioning mean in Longhorn?
A: Each disk has a **reserved** amount that Longhorn will not schedule onto (protecting the OS/root disk and leaving headroom). The **over-provisioning** percentage lets the sum of volume nominal sizes exceed physical capacity, which is safe because Longhorn volumes are **thin-provisioned** and only consume space as data is written — but you must monitor real usage.

Q: Which Harvester nodes can hold Longhorn replicas?
A: Any node that **contributes disks** can host replicas, so in a hyperconverged cluster both management and worker nodes typically store data. You constrain placement with node/disk **tags** and StorageClass selectors. A dedicated **witness** node provides quorum only and does **not** store volume data.

Q: How can Harvester use storage other than built-in Longhorn?
A: You can install **third-party CSI drivers** and create StorageClasses against them for VM volumes; the **CDI** image backend imports golden images into those StorageClasses (and into Longhorn V2/LVM). This is how you place VM disks on external enterprise storage while keeping the Harvester/KubeVirt workflow.

Q: Why do live-migratable VMs need ReadWriteMany volumes, and how does that relate to backups?
A: Live migration briefly runs the VM on two nodes, so its volume must allow attach from multiple nodes — **ReadWriteMany (RWX)** with the StorageClass `migratable` parameter enabled (a single-replica or RWO volume is not migratable). Separately, volume **snapshots** are in-cluster restore points, whereas **backups** copy volume data to an external **backup target** (S3/NFS) for off-cluster recovery.
