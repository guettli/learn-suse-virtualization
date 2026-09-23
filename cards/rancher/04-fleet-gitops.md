# Fleet (GitOps)

Q: What is Fleet in the Rancher ecosystem?
A: Fleet is Rancher's **built-in GitOps engine** for deploying workloads from Git to many clusters at once ("GitOps at scale"). It ships as **Continuous Delivery** in the Rancher UI and can manage thousands of clusters from a single set of Git repos.

Q: Where do the fleet-controller and fleet-agent each run?
A: The **fleet-controller** runs in the **local (management) cluster** and watches `GitRepo` resources. A **fleet-agent** runs in **each downstream/managed cluster**, pulling its assigned `BundleDeployments` and applying them locally.

Q: What does the Fleet GitRepo custom resource define?
A: A **`GitRepo`** (in `fleet.cattle.io`) points Fleet at a source: it sets the **`repo`** URL, **`branch`**/**`revision`**, and one or more **`paths`** inside the repo to scan. Creating a `GitRepo` is how you register a repository with Fleet.

Q: How does a Git repository become deployable units in Fleet?
A: Fleet scans each configured path and produces a **`Bundle`** per path (a packaged set of manifests/Helm/Kustomize). For every matching target cluster, the controller creates a **`BundleDeployment`**, which the local **fleet-agent** applies. Flow: `GitRepo → Bundle → BundleDeployment`.

Q: What is the difference between a Bundle and a BundleDeployment?
A: A **`Bundle`** is the cluster-independent definition (what to deploy plus targeting rules). A **`BundleDeployment`** is the **per-cluster instance** of that bundle — one is created for each targeted cluster and tracked/applied by that cluster's agent.

Q: How does Fleet decide which clusters a bundle deploys to?
A: Via **`targets`**, which match clusters by **label selector** (`clusterSelector`), by **`clusterName`**, or by a **`clusterGroup`**. A **`ClusterGroup`** is a named, label-based grouping of clusters, so you roll out by group rather than listing clusters individually.

Q: What is the role of the fleet.yaml file?
A: **`fleet.yaml`** sits in a repo path and configures that path's bundle: choose **raw manifests, Helm, or Kustomize**, set `defaultNamespace`, supply Helm `chart`/`repo`/`version`/`values`, and declare **`dependsOn`** so a bundle waits for another to be Ready before deploying.

Q: How do you give one bundle different configuration per cluster in Fleet?
A: With **`targetCustomizations`** in `fleet.yaml`: each entry has a name plus a matcher (`clusterSelector`/`clusterName`/`clusterGroup`) and overrides such as Helm `values` or `kustomize.dir`. This lets one bundle deploy tailored config to dev vs prod without separate repos.

Q: What is the fleet-local cluster (and the fleet-default namespace)?
A: **`fleet-local`** is the Fleet workspace/namespace used to deploy into the **local Rancher management cluster itself**. Downstream clusters live in **`fleet-default`** (or custom workspaces). You put a `GitRepo` in `fleet-local` to GitOps-manage the local cluster.

Q: How does Fleet handle configuration drift on target clusters?
A: Fleet supports **drift correction** via **`correctDrift`** (set on the `GitRepo` or in `fleet.yaml`). When enabled, if live resources are changed out-of-band, the agent **reverts them to the Git-defined state**; `force` can be used for changes that would otherwise be rejected.

Q: What do the main Fleet bundle status states mean?
A: - **Ready** — resources applied and matching desired state.
- **Modified** — bundle deployed and resources ready, but live resources changed out-of-band from the Git-defined state.
- **ErrApplied** — applying the bundle failed (e.g. invalid manifest or RBAC error).
Fleet surfaces these per bundle and per cluster in Continuous Delivery.

Q: How does Fleet authenticate to a private Git repository?
A: Reference a Kubernetes **Secret** from the `GitRepo`: **`clientSecretName`** holds either an **SSH key** (`ssh-privatekey`, PEM, no passphrase) or **HTTP basic-auth** (username + token/password). A separate **`helmSecretName`** authenticates to private Helm/OCI chart registries.

Q: Why use Fleet instead of running raw Argo CD or Flux?
A: Fleet is **native to and installed with Rancher**, so it reuses Rancher's cluster registry, auth, and UI, and is built for **fan-out to large fleets** via cluster labels/groups and per-cluster `targetCustomizations`. Argo/Flux target a single cluster each and need separate multi-cluster tooling.
