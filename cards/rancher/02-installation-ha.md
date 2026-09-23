# Installation & High Availability

Q: What is the recommended way to install Rancher for production?
A: Install Rancher via its **Helm chart** onto an existing dedicated Kubernetes cluster (typically a 3-node **RKE2** cluster), into the **cattle-system** namespace. This gives a highly available control plane where Rancher replicas survive node loss, unlike the single-node Docker method.

Q: Why does the Rancher Helm chart usually require cert-manager?
A: **cert-manager** issues and renews the TLS certificate for the Rancher ingress. It is required for the two self-issuing TLS sources — Rancher's own generated CA (`ingress.tls.source=rancher`) and **Let's Encrypt** (`ingress.tls.source=letsEncrypt`). It is **not** needed if you bring your own certificate (`ingress.tls.source=secret`) or terminate TLS on an external load balancer.

Q: What are the three ingress.tls.source options for Rancher's certificate?
A: 
- **`rancher`** (default) — Rancher generates a self-signed CA; needs cert-manager.
- **`letsEncrypt`** — automated public certs via Let's Encrypt; needs cert-manager and a public DNS/HTTP-reachable hostname.
- **`secret`** — bring-your-own cert supplied as a Kubernetes TLS Secret; no cert-manager.

Q: What do the hostname and bootstrapPassword Helm values configure?
A: **`hostname`** is the DNS name (pointed at the load balancer/ingress) that Rancher serves on and puts into its certificate. **`bootstrapPassword`** sets the initial password for the built-in **admin** user, used for first login before you set a permanent password.

Q: When is the single-node Docker install of Rancher appropriate?
A: The **Docker install** (`docker run ... --privileged rancher/rancher`) runs Rancher with a bundled local Kubernetes inside one container. It is quick but is **only for development and testing** — it is not highly available and is not supported for production.

Q: What does a recommended HA management cluster for Rancher look like?
A: A dedicated **3-node RKE2** cluster where all three nodes carry the **etcd + controlplane + worker** roles, fronted by a load balancer for the Rancher ingress. Three etcd nodes tolerate one node failure while keeping quorum, and Rancher runs replicated across them.

Q: What is the difference between the latest and stable Rancher Helm channels?
A: They are different Helm repositories: **latest** (`.../server-charts/latest`) ships the newest features earlier, while **stable** (`.../server-charts/stable`) is the recommended channel for production. (There is also an unsupported **alpha** channel for previews.)

Q: How do the Rancher app version and Helm chart version differ?
A: The **chart version** is the version of the Helm chart package, while the **appVersion** is the Rancher server version (e.g. `v2.x`) it deploys. You pick a channel and chart version with Helm; `image.tag` can pin the exact Rancher server image.

Q: How do you configure Rancher for an air-gapped installation?
A: Mirror all required Rancher and downstream images into a **private registry**, then install with **`systemDefaultRegistry=<registry>`** so Rancher and the clusters it provisions pull from it. Set **`useBundledSystemChart=true`** to use packaged system charts instead of fetching them from the internet, plus registry pull-secret settings as needed.

Q: How do you upgrade a Helm-installed Rancher?
A: Update the Rancher Helm repo, then run **`helm upgrade`** of the `rancher` release in `cattle-system` **reusing your existing values** (e.g. `--reuse-values` or your values file) and bumping to the target chart version. Take a Rancher/etcd backup first and follow the supported upgrade path for your version.

Q: Why should the Rancher local cluster not run application workloads?
A: The local cluster's etcd and control plane hold **all of Rancher's state**; contention or an outage there breaks management of every downstream cluster. Keeping user workloads off it (dedicating it to Rancher) protects stability and keeps the blast radius small.

Q: Roughly what resources does a production Rancher management cluster need?
A: Each node in the HA cluster should be a reasonably provisioned server (multiple CPUs and several GB of RAM, e.g. on the order of 4 vCPU / 8 GB or more, scaling with the number and size of downstream clusters), with fast disks for **etcd**. Always confirm the exact requirements in the version's support/requirements matrix.
