# Cluster Management & Provisioning

Q: What are the four main ways Rancher can manage a downstream cluster?
A: 
- **Provision new nodes** in an infrastructure provider via a node driver (Rancher creates the VMs and installs RKE2/K3s).
- **Custom cluster** — you bring your own machines and run a generated registration command on each.
- **Register/import** an existing cluster.
- **Hosted** — provision/manage a cloud-managed cluster (**EKS/AKS/GKE**).

Q: How does node-driver (infrastructure-provider) provisioning work in Rancher?
A: You store a **cloud credential**, enable the relevant **node driver**, then define **machine pools**. Rancher calls the provider's API to create the Linux VMs and installs **RKE2 or K3s** on them automatically — a fully Rancher-managed lifecycle where deleting the cluster also removes the nodes.

Q: What is a custom cluster in Rancher and how do nodes join it?
A: A **custom cluster** runs on machines you provision yourself (any infra). Rancher generates a **registration command** you run on each node; you tick which **roles** (etcd / controlplane / worker) that node should take, and the node registers itself and gets RKE2/K3s installed.

Q: What is a cloud credential in Rancher and why is it separate from a node driver?
A: A **cloud credential** securely stores the provider API keys/secrets (as a Secret). A **node driver** is the plugin that knows how to create machines on that provider. Separating them lets many clusters/machine pools reuse one credential, and lets admins rotate credentials without editing each cluster.

Q: What is a machine pool in a Rancher-provisioned RKE2/K3s cluster?
A: A **machine pool** is a group of identically configured machines (same size/image/provider template) with an assigned set of **roles** and a **machine count**. Scaling the pool count up or down tells Rancher to create or remove machines; you typically use separate pools for etcd, controlplane, and worker.

Q: What are the three node roles in an RKE2/K3s cluster managed by Rancher?
A: **etcd** (holds cluster state; use an odd number for quorum), **controlplane** (runs the API server, scheduler, controller-manager), and **worker** (runs user workloads). A pool/node can hold one or several roles; small clusters may combine all three.

Q: What underlying technology backs Rancher's RKE2/K3s provisioning (Provisioning v2)?
A: **Provisioning v2** is built on **Cluster API (CAPI)** and driven by the **`provisioning.cattle.io`** `Cluster` resource (the "rancher-provisioned" model). A planner in Rancher plus **rancher-system-agent** on each node orchestrates install, config, and upgrades.

Q: How do you set node labels and taints on a Rancher-provisioned cluster?
A: In each **machine pool** you can define **Kubernetes node labels** and **taints** so every machine in that pool is created with them. Pools also offer **Drain Before Delete** and **Auto Replace** (replace an unreachable node after a timeout) for lifecycle control.

Q: How can you access full RKE2 configuration options not shown in the Rancher form?
A: Switch the cluster to the **YAML / "Edit as YAML"** view and edit the **`rkeConfig`** block — e.g. `machineGlobalConfig` (cluster-wide RKE2 settings), `machineSelectorConfig` (per-label settings), `machineSelectorFiles`, `registries`, and `additionalManifest`. This exposes the standalone RKE2 options through Rancher.

Q: How do you scale a Rancher-provisioned cluster up or down?
A: Edit the **machine pool** and change its **machine count** (or add/remove pools). Rancher provisions new machines or drains and deletes machines through Cluster API. For manual control you can also add/remove etcd or worker capacity by adjusting the relevant pool.

Q: How does Rancher handle etcd snapshots and restore for RKE2/K3s clusters?
A: The cluster config offers **automatic recurring etcd snapshots** (schedule + retention, stored locally and optionally to S3). To recover, you pick a snapshot and Rancher performs an **etcd restore**, with options to also roll back the Kubernetes version and cluster config to that point in time.

Q: What kinds of clusters can be registered (imported) into Rancher?
A: A wide range: generic **CNCF-conformant** clusters, **RKE2/K3s**, and hosted **EKS/AKS/GKE**. Full lifecycle features (version upgrades, etcd snapshot/restore, config editing) are available for RKE2/K3s; generic imports get RBAC, monitoring, logging, and workload management but not node lifecycle.

Q: What happens when you register an existing cluster with Rancher?
A: Rancher gives you a **`kubectl apply`** command pointing at a manifest URL containing a **cluster registration token** (e.g. `/v3/import/<token>_<clusterID>.yaml`). Applying it deploys the **cattle-cluster-agent** plus RBAC into the target cluster, which then dials home and brings the cluster under management.

Q: Why can current Rancher no longer provision RKE1 clusters?
A: **RKE1** used the older Provisioning v1 / docker-machine model. Modern Rancher standardizes on **RKE2 and K3s** via Provisioning v2 (Cluster API); Rancher **2.12+ dropped provisioning and managing downstream RKE1 clusters**, and SUSE recommends replatforming RKE1 to RKE2.
