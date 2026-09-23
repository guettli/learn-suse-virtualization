# RKE2 & K3s Distributions

Q: What is RKE2 and what is its design focus?
A: **RKE2** ("RKE Government") is SUSE's **single-binary** Kubernetes distribution focused on **security and compliance**: it is **CIS-hardened** by default and **FIPS 140-2 capable**. It targets datacenter, government, and regulated workloads.

Q: How does RKE2 run the Kubernetes control plane?
A: As **static Pods** managed by the kubelet — the apiserver, controller-manager, scheduler, and etcd run as containers (not host processes as in RKE1), on an **embedded containerd** runtime bundled in the binary.

Q: What is K3s and what is it optimized for?
A: **K3s** is a **lightweight, single-binary** CNCF Kubernetes distro (<100MB, low memory) for **edge, IoT, CI, and ARM**. It strips legacy/in-tree cloud drivers and is **batteries-included** so a full cluster runs from one binary.

Q: What is K3s's default datastore, and what alternatives exist?
A: Default is **SQLite** (single-server). Alternatives: **embedded etcd** (for an HA cluster of servers) or an **external datastore** (MySQL, Postgres, or external etcd) via `--datastore-endpoint`.

Q: What components does K3s bundle out of the box?
A: Batteries-included: **Traefik** ingress, **ServiceLB / Klipper** load-balancer, **local-path** storage provisioner, **CoreDNS**, **metrics-server**, and the **helm-controller**. Any of these can be disabled with `--disable`.

Q: What is the difference between server and agent nodes in RKE2/K3s?
A: A **server** node runs the control plane (and the datastore); an **agent** node runs only the kubelet/workloads. Agents (and additional servers) join an existing cluster by contacting a server's supervisor port with the cluster **token**.

Q: What is the node token used for when joining RKE2/K3s nodes?
A: The **token** is the shared secret a joining node presents to authenticate to the cluster. On a server it's at **`/var/lib/rancher/{rke2,k3s}/server/node-token`**; new nodes set it via `token:` in config (or `K3S_TOKEN`/`RKE2_TOKEN`) plus the server URL.

Q: Where is the main RKE2/K3s node configuration file?
A: **`/etc/rancher/rke2/config.yaml`** (or `/etc/rancher/k3s/config.yaml`) — a YAML file whose keys mirror the CLI flags (`token`, `server`, `tls-san`, `node-label`, `cni`, `disable`, etc.), read at service start.

Q: What is tls-san and why set it?
A: **`tls-san`** adds extra **Subject Alternative Names** to the API server's serving certificate. You add the load-balancer hostname/VIP or extra IPs so `kubectl` and joining nodes can reach the API over those names without TLS errors — essential for HA setups.

Q: What is registries.yaml used for?
A: **`/etc/rancher/{rke2,k3s}/registries.yaml`** configures the embedded **containerd** for private/mirror registries: endpoint **mirrors/rewrites** and per-registry **auth/TLS**. It's the standard way to point an **air-gapped** cluster at an internal registry.

Q: How do RKE2 and K3s perform automated upgrades?
A: Via the **system-upgrade-controller** and its **`Plan`** CRD: a Plan selects nodes by label and cordon/drains and upgrades them in a controlled rollout. Rancher-provisioned clusters drive the same mechanism through the UI/API instead of hand-authored Plans.

Q: What CNI options does RKE2 offer and which is default?
A: Default is **Canal** (Flannel VXLAN + Calico NetworkPolicy). Also supported: **Cilium** (eBPF), **Calico**, and **Multus** (multiple interfaces, layered over another CNI). Select with the **`cni:`** key in config.yaml. K3s defaults to plain **Flannel**.

Q: How do you customize a bundled RKE2 CNI or component chart?
A: With a **`HelmChartConfig`** (`helm.cattle.io/v1`) whose **name and namespace match** the bundled **`HelmChart`** (e.g. `rke2-canal` in `kube-system`). Drop it in **`/var/lib/rancher/rke2/server/manifests/`** and the embedded helm-controller applies your `valuesContent` overrides.

Q: How does the bundled helm-controller / auto-deploying manifests directory work?
A: Any YAML placed in **`/var/lib/rancher/{rke2,k3s}/server/manifests/`** is auto-applied at startup. The embedded **helm-controller** reconciles **`HelmChart`** CRs there, which is how RKE2/K3s deploy Traefik, CoreDNS, the CNI, etc. — declarative add-ons without running `helm` by hand.

Q: What are the main differences between K3s and RKE2?
A: 
| | K3s | RKE2 |
|---|---|---|
| Focus | Edge/IoT, small footprint | Security/compliance, datacenter |
| Datastore default | **SQLite** | **embedded etcd** |
| Hardening | not CIS by default | **CIS-hardened, FIPS-capable** |
| Control plane | host processes | **static Pods** |
| Default CNI/ingress | Flannel + Traefik | Canal, no default ingress |

Q: How does an air-gapped install of RKE2/K3s work?
A: You download the release **tarball** of prestaged **images** (e.g. `rke2-images.linux-amd64.tar.zst`) plus the install script/binary, place images under **`/var/lib/rancher/{rke2,k3s}/agent/images/`**, and use **`registries.yaml`** to pull any remaining images from an internal mirror.

Q: How does Rancher manage RKE2/K3s clusters versus a standalone install?
A: Standalone, you install the binary and edit `config.yaml` yourself. Rancher-**provisioned** clusters are driven by **CAPI/Cluster (provisioning.cattle.io)** objects — Rancher writes the config, joins nodes, and orchestrates upgrades/snapshots from the UI, so you don't touch `config.yaml` directly.
