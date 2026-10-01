# Rancher Prime, Cluster API & Dual-Stack Networking

Q: What is Rancher Prime and how is registration validated?
A: **Rancher Prime** is the enterprise distribution of Rancher with certified container images, SLA-backed commercial support, and access to the **Prime Registry (`registry.rancher.com`)**. Registration is activated by connecting the management server to the **SUSE Customer Center (SCC)** or entering an offline entitlement key for air-gapped deployments.

Q: How does Rancher utilize Cluster API (CAPI) under the hood for provisioning?
A: Rancher's v2 provisioning engine is built on **upstream Kubernetes Cluster API (CAPI)**. Rancher defines custom CAPI providers:
- **CAPR (Cluster API Provider Rancher)**: Orchestrates RKE2/K3s control plane and worker initialization.
- **Node Driver Infrastructure Providers** (e.g., Harvester, AWS, vSphere): Manage machine VM lifecycle and OS bootstrapping via cloud-init.

Q: What are the requirements for Dual-Stack (IPv4/IPv6) networking in Rancher-provisioned RKE2 clusters?
A: 
1. Dual-Stack must be enabled during cluster provisioning in the **Cluster Configuration → Advanced Networking** section.
2. Both an **IPv4 and an IPv6 CIDR** must be specified for **Cluster Pod CIDR** and **Service CIDR**.
3. The underlying CNI plugin must support dual-stack (such as **Canal with Cilium/Calico** or pure **Cilium**).
4. All host nodes must have routable IPv4 and IPv6 addresses configured on their primary network interfaces.

Q: What are the three recovery modes supported by the Rancher Backup Operator during a restore?
A: 
1. **Restore to Existing Cluster**: Replaces resources in an existing live management cluster.
2. **Migration to New Cluster**: Deploys Rancher configuration and managed cluster states onto a fresh Kubernetes cluster.
3. **Disaster Recovery with Cert Rotation**: Restores backup state while rotating expired or changed TLS certificates and updating hostnames.

Q: How do Fleet Workspaces provide multi-tenant GitOps isolation?
A: Fleet organizes Git repositories and cluster targets into **Workspaces** (Kubernetes namespaces labeled for Fleet). Clusters and GitRepos in one workspace cannot deploy to or see clusters in another workspace, allowing distinct teams or environments (e.g. `dev`, `staging`, `prod`) to operate independently without overlapping privileges.

Q: How does Fleet match Git repositories to target clusters?
A: Using **Cluster Selectors and Target Labels**. In the `fleet.yaml` manifest, administrators specify `targets` with `clusterSelector.matchLabels` (e.g. `env: production`, `location: edge`). Fleet evaluates cluster inventory labels and automatically fans out deployment bundles to all matching clusters.
