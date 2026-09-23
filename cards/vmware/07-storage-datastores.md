# Storage & Datastores

Q: What is a datastore in vSphere?
A: A **datastore** is a logical storage container that abstracts the underlying physical storage (a disk, LUN, or NFS share) into a uniform place to hold VM files (VMDKs, config, logs, ISOs). Types include **VMFS**, **NFS**, **vSAN**, and **vVol** datastores.

**SUSE Virtualization:** The equivalent is a **Longhorn StorageClass**, which backs VM volumes (PVCs) rather than a datastore holding VM files.

Q: What is VMFS and what are its versions and block sizes?
A: **VMFS (Virtual Machine File System)** is VMware's clustered filesystem that lets multiple ESXi hosts read/write the same volume concurrently with on-disk locking. **VMFS-6** (default in current releases) uses a **1 MB** unified block size with small/large file blocks and **automatic UNMAP**; the older **VMFS-5** required manual space reclamation. There is no in-place upgrade from 5 to 6.

**SUSE Virtualization:** The equivalent is **SUSE Storage (Longhorn)**, distributed replicated block storage built from node disks — a Kubernetes CSI layer rather than a clustered on-disk filesystem.

Q: How do NFS v3 and v4.1 datastores differ in vSphere?
A: An **NFS datastore** mounts a file share exported by a NAS. **NFS v3** uses a single connection and VMware's own client-side locking, and does not support Kerberos. **NFS v4.1** adds **multipathing/session trunking**, native server-side locking, and **Kerberos authentication**. A datastore must be mounted with one version consistently across all hosts.

**SUSE Virtualization:** The equivalent is adding an external **CSI StorageClass** (e.g. an NFS or other vendor CSI driver) to the cluster alongside the default Longhorn StorageClass.

Q: What is a VMDK?
A: A **VMDK (Virtual Machine Disk)** is the file that represents a VM's virtual hard disk on a datastore. It can be **thick** (eager or lazy zeroed) or **thin** provisioned, and it is the unit that Storage vMotion, snapshots, and cloning operate on.

**SUSE Virtualization:** The equivalent is a **Longhorn volume** (a PVC), the block device attached to a VM.

Q: What is an RDM and how do physical and virtual compatibility differ?
A: A **Raw Device Mapping (RDM)** gives a VM direct access to a physical LUN via a mapping file on VMFS instead of a VMDK. **Virtual compatibility (vRDM)** virtualizes the LUN so snapshots and most VMDK features work. **Physical compatibility (pRDM)** passes SCSI commands straight to the array (needed for SAN-aware apps and MSCS), forgoing vSphere snapshots.

**SUSE Virtualization:** The closest analog is **host device/disk passthrough** (PCI or disk passthrough) or a dedicated volume; there is no exact raw-LUN-mapping equivalent.

Q: What is a LUN, and how does a datastore differ from a LUN?
A: A **LUN (Logical Unit Number)** is a block storage volume presented by a SAN array to hosts. A **datastore** is the higher-level, formatted container ESXi places on top of storage. A VMFS datastore is typically formatted onto a LUN (usually one-to-one), so the LUN is raw block storage and the datastore is the usable filesystem.

**SUSE Virtualization:** No direct equivalent — Longhorn builds storage from local node disks rather than SAN LUNs, so LUNs aren't exposed at the VM layer; the usable unit is a volume (PVC).

Q: What is Fibre Channel (FC) storage in vSphere?
A: **Fibre Channel** is a high-speed block SAN protocol that carries SCSI commands over a dedicated FC fabric using HBAs and WWNs for addressing. ESXi hosts see FC LUNs as local block devices to format with VMFS. It offers high throughput and low latency but needs dedicated FC switches and adapters.

**SUSE Virtualization:** No direct equivalent — FC SAN transport isn't used or exposed at the VM layer; **Longhorn** aggregates local node disks instead (an external array would come in via a separate CSI driver).

Q: How does iSCSI work in vSphere (initiator, target, IQN)?
A: **iSCSI** carries SCSI commands over standard TCP/IP Ethernet. The host runs an **initiator** (software iSCSI adapter or a hardware HBA) that connects to a storage **target**; each endpoint is named by an **IQN (iSCSI Qualified Name)**. It delivers block LUNs over the existing IP network without an FC fabric.

**SUSE Virtualization:** No direct equivalent at the VM layer — **Longhorn** does use iSCSI internally to attach volumes to nodes, but VMs consume volumes (PVCs), not iSCSI targets you configure.

Q: What is FCoE?
A: **FCoE (Fibre Channel over Ethernet)** encapsulates Fibre Channel frames inside Ethernet, letting FC traffic share a converged 10 GbE (lossless/DCB) network with LAN traffic. It uses Converged Network Adapters (CNAs) so hosts get FC-style block storage without a separate physical FC fabric.

**SUSE Virtualization:** No direct equivalent — converged FC-over-Ethernet SAN transport isn't part of the stack; storage comes from **Longhorn/CSI** over the cluster network.

Q: What is NVMe-oF in vSphere?
A: **NVMe over Fabrics (NVMe-oF)** extends the low-latency NVMe protocol across a network fabric so ESXi can reach fast flash arrays with far less overhead than SCSI-based transports. vSphere supports transports including **NVMe/FC**, **NVMe/RDMA (RoCE v2)**, and **NVMe/TCP**.

**SUSE Virtualization:** No VM-facing equivalent, but the newer **Longhorn V2 (SPDK)** engine uses NVMe (NVMe-oF/TCP) internally for its data path; it isn't exposed to configure per VM.

Q: What is the Pluggable Storage Architecture (NMP, SATP, PSP)?
A: The **PSA** is ESXi's modular framework for managing storage paths. The **NMP (Native Multipathing Plugin)** is the default multipathing module; within it a **SATP (Storage Array Type Plugin)** handles array-specific path failover, and a **PSP (Path Selection Plugin)** chooses which path to use: **MRU (Most Recently Used)**, **Fixed**, or **Round Robin**.

**SUSE Virtualization:** No direct equivalent — there is no path-plugin framework at the VM layer; multipathing/path selection is handled below the VM by **Longhorn/CSI and Kubernetes**.

Q: What is multipathing in vSphere storage?
A: **Multipathing** provides multiple physical routes (HBAs, switches, array ports) between a host and a LUN. It delivers **failover** (survive a path/component failure) and, with Round Robin, **load balancing** by distributing I/O across active paths. The PSA/PSP decides the active path(s).

**SUSE Virtualization:** No direct equivalent at the VM layer — resilience comes from **Longhorn replicas** across nodes rather than multiple SAN paths to one LUN.

Q: What are a datastore cluster and Storage DRS?
A: A **datastore cluster** pools multiple datastores into one aggregate managed as a unit. **Storage DRS (SDRS)** then handles **initial placement** of new VMDKs and, using **Storage vMotion**, balances load based on space usage and I/O latency thresholds, and can enforce VMDK affinity/anti-affinity rules.

**SUSE Virtualization:** No direct equivalent — **Longhorn** automatically schedules and balances volume replicas across nodes and disks, so there is no datastore-cluster or SDRS construct to configure.

Q: What are VMware vVols and SPBM?
A: **vVols (Virtual Volumes)** make the array VM-aware: each virtual disk is a native array object exposed through a storage provider (VASA) via a **protocol endpoint**, so array data services apply per-VM. **SPBM (Storage Policy-Based Management)** lets you define capability policies (e.g., performance, replication) that vSphere applies and enforces when placing VMs on capable storage.

**SUSE Virtualization:** The equivalent is **StorageClass parameters** (e.g. `numberOfReplicas`) that set per-volume storage behavior, rather than array-integrated vVols/SPBM policies.

Q: What is thin provisioning at the datastore level?
A: **Datastore-level thin provisioning** is when the storage array presents a LUN larger than its backing capacity, allocating physical blocks only as data is written. vSphere integrates via VAAI thin-provisioning primitives, raising **out-of-space** warnings and issuing **UNMAP** to reclaim freed blocks, so admins must monitor real array usage to avoid overcommit.

**SUSE Virtualization:** The equivalent is **Longhorn thin provisioning** — volumes allocate space only as data is written, so cluster disk usage must be monitored to avoid overcommit.
