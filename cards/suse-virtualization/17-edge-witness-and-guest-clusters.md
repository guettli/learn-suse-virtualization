# Edge, Witness Nodes & Guest Clusters

Q: How does a two-node SUSE Virtualization / Harvester cluster prevent split-brain during a network partition?
A: By deploying an **external Witness Node** (or third lightweight quorum participant). The witness joins the cluster solely to participate in **RKE2 etcd quorum and Kubernetes control plane consensus**; it does not host virtual machines or store Longhorn data replicas. This creates an **odd voter count (3 nodes)**, allowing a single host to safely survive partition without risk of split-brain or data corruption.

Q: How do downstream Kubernetes clusters (guest clusters) consume storage from SUSE Virtualization?
A: Via the **Harvester CSI Driver** (`harvester-csi-driver`). When deployed inside an RKE2 or K3s guest cluster, it communicates with the underlying Harvester API to dynamically create **Harvester Virtual Disks (backed by Longhorn)** and attach them to the VM worker nodes as Kubernetes `PersistentVolumes`.

Q: What components comprise the Harvester Cloud Provider integration for guest clusters?
A: Two complementary components:
1. **Harvester Cloud Controller Manager (CCM)**: Manages node lifecycle, assigns node IP addresses, and orchestrates **LoadBalancer Service** allocation via Harvester's integrated VIP/IP pool.
2. **Harvester CSI Driver**: Automates dynamic block volume provisioning and snapshots for guest workloads.

Q: What are the prerequisites to run Windows 11 or Windows Server 2022 on SUSE Virtualization?
A: Windows 11 strictly mandates **UEFI boot with Secure Boot** and a **TPM 2.0 module**. In Harvester:
- Set VM Boot Mode to **UEFI (with Secure Boot enabled)**.
- Enable the **Virtual TPM (vTPM)** device, which runs an emulated `swtpm` daemon inside the virt-launcher pod to provide hardware-independent cryptographic storage.

Q: What is a VM Disruption Budget (`VMDisruptionBudget` / `VMDB`) in KubeVirt / Harvester?
A: Similar to Kubernetes Pod Disruption Budgets (`PDB`), a **`VMDB`** specifies the minimum number of VM instances that must remain operational during voluntary cluster maintenance (such as rolling node reboots or automated OS upgrades), ensuring services do not suffer simultaneous live migration or downtime.

Q: How does CPU and Memory hotplug work in SUSE Virtualization?
A: KubeVirt allows adding vCPUs and RAM to a running VM without rebooting, provided the guest OS and VM template have **hotplug enabled**:
- **CPU Hotplug**: Extra vCPU threads are hot-plugged into the guest through ACPI.
- **Memory Hotplug**: Uses **virtio-mem** or ACPI memory ballooning to allocate extra memory pages to the guest on the fly.

Q: How does Harvester provide layer-2 IP address assignment for VM Load Balancers?
A: Through the integrated **Harvester Load Balancer (kube-vip / IPAM pool)**. Administrators define an **IP Pool** on a VLAN network; when a LoadBalancer service is requested (in Harvester or a guest cluster), an IP from this pool is reserved and advertised across the VLAN via **gratuitous ARP (GARP)** or BGP.

Q: What is the difference between NoCloud and ConfigDrive cloud-init data sources in VM images?
A: 
- **NoCloud**: Injects cloud-init configuration via a simulated ISO or FAT filesystem labeled `cidata`. It is the default for KubeVirt and Harvester and works universally across modern Linux cloud images.
- **ConfigDrive**: Injects configuration labeled `config-2`, typically used in OpenStack environments. Both inject `user-data` and `network-config` without requiring external network connectivity.
