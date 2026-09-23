# Rancher Integration

Q: What is the difference between the embedded Rancher in SUSE Virtualization and a standalone Rancher Manager?
A: Every Harvester cluster ships an **embedded Rancher** used internally for **authentication and the built-in dashboard**. To manage many clusters and provision guest Kubernetes clusters, you **import** the Harvester cluster into a **standalone Rancher Manager**, which then exposes Virtualization Management, the node driver, and centralized RBAC.

Q: How do you bring a Harvester cluster under a standalone Rancher Manager?
A: In Rancher you **import the Harvester cluster** via the **Virtualization Management** feature. Rancher then manages the cluster's hosts, VMs, images, and volumes through its UI, reusing Rancher's auth providers and multi-tenancy.

Q: What does the Virtualization Management area in Rancher let you do?
A: It lets you **manage imported Harvester clusters** centrally — viewing and operating hosts, virtual machines, images, and volumes — and it is the entry point for creating **cloud credentials** and provisioning **guest clusters** onto Harvester.

Q: How does importing Harvester into Rancher enable multi-tenancy and RBAC?
A: Rancher applies its existing **projects, namespaces, and RBAC roles** and its **authentication providers** to the Harvester cluster. This gives you **multi-tenant** access control over virtualization resources without Harvester implementing its own separate identity system.

Q: What is the Harvester node driver and what does it do?
A: The **Harvester node driver** (built into Rancher v2.6.1+) lets Rancher **provision guest RKE2/K3s Kubernetes clusters** whose nodes are **VMs running on Harvester**. Rancher creates, scales, and replaces those VM-backed nodes automatically, treating Harvester like an infrastructure/cloud provider.

Q: What cloud credential do you create to provision guest clusters on Harvester?
A: In **Cluster Management > Cloud Credentials** you create a credential of type **Imported Harvester Cluster**, pointing at the imported Harvester cluster. This credential authorizes Rancher/the node driver to create VMs there when building an RKE2 or K3s cluster.

Q: What image and network prerequisites does the Harvester node driver require for guest cluster nodes?
A: Node VMs must boot from a **cloud image** (cloud-init capable), not an ISO install image. A **VLAN network** is required for the node driver, and node IPs come from a **DHCP server** or Harvester's **Managed DHCP**. You also supply cluster name, namespace, image, network, and SSH user.

Q: What does the Harvester cloud provider give a guest Kubernetes cluster?
A: It implements Kubernetes **`LoadBalancer` services** for guest workloads, backed by Harvester. It supports IPAM modes including **DHCP**, **Pool** (pre-configured IP pools), and **Share IP**, so guest cluster services get real external load-balancer addresses.

Q: What does the Harvester CSI driver provide inside a guest cluster?
A: The **Harvester CSI driver** offers **storage passthrough**: guest-cluster PersistentVolumes are provisioned from the **underlying Harvester (Longhorn/SUSE Storage)** storage. Guest pods get dynamically provisioned block storage without the guest cluster owning its own storage backend.

Q: How do the Harvester cloud provider and CSI driver get installed in a guest cluster?
A: When you provision an RKE2/K3s cluster with the **node driver**, both are **deployed automatically** (RKE2 v1.21.5+rke2r2 and later bundle the integration). For custom/manual clusters you generate a cloud config (e.g., via `generate_addon.sh`) and set the cloud provider to **External**.

Q: Why run guest RKE2/K3s clusters on top of Harvester instead of directly on hardware?
A: Harvester provides the **VM lifecycle, networking (VLAN/LoadBalancer), and storage (CSI)** as an on-prem cloud, so Rancher can spin up, scale, heal, and tear down full Kubernetes clusters on demand from **cloud images** — turning bare-metal HCI into a self-service, cloud-like platform for many isolated clusters.

Q: How do you scale the number of nodes in a Harvester-backed guest cluster, and can it autoscale?
A: Guest nodes are grouped into **machine pools (node pools)**; you scale a pool by changing its **quantity**, and Rancher creates or deletes the backing Harvester VMs accordingly. For autoscaling, deploy the **Kubernetes Cluster Autoscaler** and annotate the pool with min/max size (`cluster.provisioning.cattle.io/autoscaler-min-size` / `-max-size`) so pending, unschedulable pods trigger scale-up and idle nodes are scaled down.

Q: Why must you check a support matrix before pairing an external Rancher with a Harvester cluster?
A: Rancher and Harvester release **independently**, so only specific version pairs are supported for import and management. From **Rancher v2.10+** you also need the matching **Harvester UI Extension** to reach the Harvester UI inside Rancher. When upgrading an integrated setup the guidance is generally to **upgrade Rancher first, then Harvester**. Always confirm the exact pair against the official Harvester/Rancher support matrix.

Q: Who controls the Kubernetes version of a Harvester-hosted guest cluster and its upgrades?
A: **Rancher** does, not Harvester. You pick the **RKE2/K3s Kubernetes version** from Rancher's release channel when provisioning, and you **upgrade the guest cluster through Rancher** independently of the underlying Harvester version. Harvester only supplies the VMs, networking, and storage (CSI); the guest cluster is otherwise a normal Rancher-managed RKE2/K3s cluster.

Q: What extra infrastructure does provisioning guest clusters on Harvester need in an air-gapped Rancher environment?
A: A reachable **private container registry** mirroring the RKE2/K3s **system images** and **Rancher agent images**, plus a locally hosted **VM cloud image**, since nodes cannot reach the internet. Rancher must be told to use that mirror via its **system-default-registry** setting so provisioned nodes and the Harvester cloud-provider/CSI images pull from it rather than public registries.
