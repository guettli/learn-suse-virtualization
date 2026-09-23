# Rancher Architecture

Q: What is Rancher Manager and what problem does it solve?
A: **Rancher Manager** (the Rancher server) is a centralized multi-cluster management platform. It runs as a set of workloads on one Kubernetes cluster and from there provisions, imports, and manages the lifecycle, access control, and add-ons of **many downstream Kubernetes clusters** through a single UI/API.

Q: What is the difference between Rancher's local cluster and its downstream clusters?
A: The **local cluster** (a.k.a. the **management cluster**) is the Kubernetes cluster where the Rancher server itself runs and stores its state. **Downstream clusters** (also called user clusters) are the clusters Rancher manages. Best practice is to run **no user workloads on the local cluster** and dedicate it to Rancher.

Q: What does the cattle-cluster-agent do in a downstream cluster?
A: The **cattle-cluster-agent** is a **Deployment** in each downstream cluster. It opens a tunnel back to the Rancher server's cluster controller and lets Rancher reach the downstream **Kubernetes API** — watching resources, deploying workloads, applying RBAC, and reporting events, stats, and health.

Q: What is the cattle-node-agent (and what replaced it on RKE2/K3s)?
A: The **cattle-node-agent** runs as a **DaemonSet** (on RKE1-style clusters) so a node-level agent exists on every node for operations like Kubernetes upgrades and etcd snapshot/restore. On **RKE2/K3s** provisioned clusters this node-lifecycle role is handled instead by **rancher-system-agent**.

Q: What is the Norman API in Rancher?
A: **Norman** is Rancher's legacy **/v3** API. It uses Kubernetes as a backend but layers substantial extra logic (clusters, projects, users, catalogs) on top. It is now considered **deprecated/legacy** and backs the older Ember UI.

Q: What is the Steve API in Rancher?
A: **Steve** is Rancher's **/v1** API — a thin Kubernetes API proxy/translator that exposes built-in resources, CRDs, and extensions as dashboard-friendly schemas. It powers the modern **Vue Dashboard** (Cluster Explorer) and passes `/api`, `/apis`, `/openapi`, `/version` straight through to Kubernetes.

Q: How does Rancher proxy kubectl/API traffic to a downstream cluster by default?
A: Rancher runs an **authentication proxy**. When you use a Rancher-generated kubeconfig, requests hit the Rancher server, which authenticates you (local, AD, GitHub, SAML, etc.), sets **Kubernetes user-impersonation headers**, and forwards the call over the agent tunnel to the downstream API server.

Q: What is the authorized cluster endpoint (ACE) and when is it used?
A: The **authorized cluster endpoint (ACE)** lets users talk to a downstream cluster's **Kubernetes API server directly**, bypassing the Rancher auth proxy (useful if Rancher is down). It is available on **RKE2 and K3s** clusters provisioned or registered by Rancher, and uses the **kube-api-auth** microservice for authentication. It is not available on hosted providers like EKS.

Q: What is the rancher-webhook and where does it run?
A: The **rancher-webhook** is a Kubernetes **admission controller** (a Deployment) that validates and mutates Rancher-specific resources before they persist. It runs in **both the local and every downstream cluster**, and Rancher manages its `rancher.cattle.io` **ValidatingWebhookConfiguration** and **MutatingWebhookConfiguration** (overriding manual edits).

Q: Where does a Helm-installed Rancher store its own data?
A: Rancher stores its state as **Kubernetes CRDs/objects in etcd of the local cluster** — there is **no external SQL database** in the Kubernetes (Helm) install. Backing up Rancher therefore means backing up the local cluster's etcd / using the Rancher Backup operator, not dumping an external DB.

Q: What are the two Rancher UIs, Ember and Vue?
A: The older **Ember UI** (Cluster Manager, served under `/g`) is the legacy interface backed by the Norman /v3 API and is being retired. The newer **Vue Dashboard** (Cluster Explorer) is backed by the Steve /v1 API and is now the primary interface for managing clusters and resources.

Q: What is Rancher Prime?
A: **Rancher Prime** is SUSE's commercially supported enterprise edition, built from the **same open-source Rancher code**. It adds SLA-backed support, extended lifecycles, security advisories, and pulls install images from a **trusted Prime registry** (`registry.rancher.com` / `registry.suse.com`) rather than public Docker Hub.
