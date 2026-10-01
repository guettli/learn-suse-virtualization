# Modern vSphere 8, DPUs & Tanzu

Q: What is the vSphere Distributed Services Engine (Project Monterey)?
A: An architecture in vSphere 8 that offloads core hypervisor and infrastructure services (such as **NSX virtual networking, distributed firewalls, and storage filters**) directly onto **Data Processing Units (DPUs / SmartNICs)** equipped with ARM processors, freeing host x86 CPU cores for application VM workloads.

Q: What is a Supervisor Cluster in vSphere with Tanzu?
A: A vSphere cluster where ESXi hosts are configured as Kubernetes worker nodes using a native in-kernel agent called the **Spherelet**. Administrators and developers interact with standard Kubernetes API endpoints to provision native Pod VMs, Tanzu Kubernetes clusters, and storage volumes directly within vCenter.

Q: What is the role of ClusterClass in Tanzu Kubernetes Grid (TKG 2.x)?
A: A **ClusterClass** is a declarative Cluster API (CAPI) blueprint that standardizes the topology, operating system, CNI, storage, and cloud-init definitions for Kubernetes guest clusters. Creating a new cluster simply references the `ClusterClass` and overrides specific variables (such as worker count or VM size).

Q: How does vSphere Native Key Provider (NKP) differ from external Key Management Servers (KMS)?
A: 
- **External KMS**: Relies on an external KMIP-compliant server cluster to generate and store encryption keys for vSAN and VM encryption.
- **Native Key Provider (NKP)**: Built directly into vCenter without external third-party appliances; vCenter generates the primary encryption keys and distributes them to ESXi hosts, enabling **vTPM 2.0 and VM encryption** with zero additional licensing or infrastructure.

Q: How does vSAN Erasure Coding (RAID-5/6) optimize storage efficiency compared to RAID-1 mirroring?
A: 
- **RAID-1 Mirroring**: Requires 200% storage capacity (`1 / FTT+1`) — storing 100 GB consumes 200 GB.
- **RAID-5 Erasure Coding (3+1)**: Tolerates 1 failure (`FTT=1`) with only **1.33x capacity overhead** (100 GB consumes 133 GB), requiring a minimum of 4 hosts.
- **RAID-6 Erasure Coding (4+2)**: Tolerates 2 failures (`FTT=2`) with **1.5x capacity overhead** (100 GB consumes 150 GB), requiring a minimum of 6 hosts.
