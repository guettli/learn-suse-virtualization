# Storage & Datastores

Q: What is a datastore in vSphere?
A: A **datastore** is a logical storage container that abstracts the underlying physical storage (a disk, LUN, or NFS share) into a uniform place to hold VM files (VMDKs, config, logs, ISOs). Types include **VMFS**, **NFS**, **vSAN**, and **vVol** datastores.

Q: What is VMFS and what are its versions and block sizes?
A: **VMFS (Virtual Machine File System)** is VMware's clustered filesystem that lets multiple ESXi hosts read/write the same volume concurrently with on-disk locking. **VMFS-6** (default in current releases) uses a **1 MB** unified block size with small/large file blocks and **automatic UNMAP**; the older **VMFS-5** required manual space reclamation. There is no in-place upgrade from 5 to 6.

Q: How do NFS v3 and v4.1 datastores differ in vSphere?
A: An **NFS datastore** mounts a file share exported by a NAS. **NFS v3** uses a single connection and VMware's own client-side locking, and does not support Kerberos. **NFS v4.1** adds **multipathing/session trunking**, native server-side locking, and **Kerberos authentication**. A datastore must be mounted with one version consistently across all hosts.

Q: What is a VMDK?
A: A **VMDK (Virtual Machine Disk)** is the file that represents a VM's virtual hard disk on a datastore. It can be **thick** (eager or lazy zeroed) or **thin** provisioned, and it is the unit that Storage vMotion, snapshots, and cloning operate on.

Q: What is an RDM and how do physical and virtual compatibility differ?
A: A **Raw Device Mapping (RDM)** gives a VM direct access to a physical LUN via a mapping file on VMFS instead of a VMDK. **Virtual compatibility (vRDM)** virtualizes the LUN so snapshots and most VMDK features work. **Physical compatibility (pRDM)** passes SCSI commands straight to the array (needed for SAN-aware apps and MSCS), forgoing vSphere snapshots.

Q: What is a LUN, and how does a datastore differ from a LUN?
A: A **LUN (Logical Unit Number)** is a block storage volume presented by a SAN array to hosts. A **datastore** is the higher-level, formatted container ESXi places on top of storage. A VMFS datastore is typically formatted onto a LUN (usually one-to-one), so the LUN is raw block storage and the datastore is the usable filesystem.

Q: What is Fibre Channel (FC) storage in vSphere?
A: **Fibre Channel** is a high-speed block SAN protocol that carries SCSI commands over a dedicated FC fabric using HBAs and WWNs for addressing. ESXi hosts see FC LUNs as local block devices to format with VMFS. It offers high throughput and low latency but needs dedicated FC switches and adapters.

Q: How does iSCSI work in vSphere (initiator, target, IQN)?
A: **iSCSI** carries SCSI commands over standard TCP/IP Ethernet. The host runs an **initiator** (software iSCSI adapter or a hardware HBA) that connects to a storage **target**; each endpoint is named by an **IQN (iSCSI Qualified Name)**. It delivers block LUNs over the existing IP network without an FC fabric.

Q: What is FCoE?
A: **FCoE (Fibre Channel over Ethernet)** encapsulates Fibre Channel frames inside Ethernet, letting FC traffic share a converged 10 GbE (lossless/DCB) network with LAN traffic. It uses Converged Network Adapters (CNAs) so hosts get FC-style block storage without a separate physical FC fabric.

Q: What is NVMe-oF in vSphere?
A: **NVMe over Fabrics (NVMe-oF)** extends the low-latency NVMe protocol across a network fabric so ESXi can reach fast flash arrays with far less overhead than SCSI-based transports. vSphere supports transports including **NVMe/FC**, **NVMe/RDMA (RoCE v2)**, and **NVMe/TCP**.

Q: What is the Pluggable Storage Architecture (NMP, SATP, PSP)?
A: The **PSA** is ESXi's modular framework for managing storage paths. The **NMP (Native Multipathing Plugin)** is the default multipathing module; within it a **SATP (Storage Array Type Plugin)** handles array-specific path failover, and a **PSP (Path Selection Plugin)** chooses which path to use: **MRU (Most Recently Used)**, **Fixed**, or **Round Robin**.

Q: What is multipathing in vSphere storage?
A: **Multipathing** provides multiple physical routes (HBAs, switches, array ports) between a host and a LUN. It delivers **failover** (survive a path/component failure) and, with Round Robin, **load balancing** by distributing I/O across active paths. The PSA/PSP decides the active path(s).

Q: What are a datastore cluster and Storage DRS?
A: A **datastore cluster** pools multiple datastores into one aggregate managed as a unit. **Storage DRS (SDRS)** then handles **initial placement** of new VMDKs and, using **Storage vMotion**, balances load based on space usage and I/O latency thresholds, and can enforce VMDK affinity/anti-affinity rules.

Q: What are VMware vVols and SPBM?
A: **vVols (Virtual Volumes)** make the array VM-aware: each virtual disk is a native array object exposed through a storage provider (VASA) via a **protocol endpoint**, so array data services apply per-VM. **SPBM (Storage Policy-Based Management)** lets you define capability policies (e.g., performance, replication) that vSphere applies and enforces when placing VMs on capable storage.

Q: What is thin provisioning at the datastore level?
A: **Datastore-level thin provisioning** is when the storage array presents a LUN larger than its backing capacity, allocating physical blocks only as data is written. vSphere integrates via VAAI thin-provisioning primitives, raising **out-of-space** warnings and issuing **UNMAP** to reclaim freed blocks, so admins must monitor real array usage to avoid overcommit.
