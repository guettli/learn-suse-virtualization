# Apps & Marketplace

Q: What is the Rancher Apps & Marketplace feature built on?
A: It is a **Helm-based** application catalog. Every entry is a standard **Helm chart**, and installing one produces a real **Helm 3 release** in the target cluster. Rancher adds a UI, curation, and lifecycle tracking on top of plain Helm.

Q: What is the ClusterRepo custom resource used for?
A: **`ClusterRepo`** (`catalog.cattle.io/v1`) is a **cluster-scoped** CRD that registers a chart repository for Apps & Marketplace. Rancher periodically syncs its index so the charts appear in the **Charts** UI.

Q: What repository source types can a ClusterRepo point at?
A: Three kinds:
- A **Helm HTTP repository** via `spec.url` (a classic `index.yaml` repo).
- An **OCI registry** (`oci://…`) via `spec.url`.
- A **Git repository** via `spec.gitRepo` plus `spec.gitBranch`, where charts live in the repo tree.

Q: Which chart repositories ship built-in with Rancher?
A: Two by default:
- **Rancher** (the official SUSE/Rancher charts, e.g. cluster tools).
- **Partners** — the `rancher/partner-charts` collection of **partner/ISV** charts validated to run on Rancher.
You add your own via a custom **ClusterRepo**.

Q: How do Apps v2 and the deprecated v1 catalog differ?
A: **Apps v2** is the current system: pure **Helm 3**, driven by **ClusterRepo** CRDs, releases stored as Helm secrets. The old **v1 catalog** (`CatalogTemplate`/`Catalog`, Helm 2-era, Tiller-style templating in Rancher) is **deprecated/removed** in current Rancher 2.x.

Q: How is an installed app tracked under the hood?
A: As a normal **Helm 3 release** (release metadata in a `sha256.helm.release.v1...` Secret in the release namespace) plus a Rancher **wrapper**: an install/upgrade/uninstall runs in a **Helm operation Pod** (a Job), and Rancher records the app so it shows under **Installed Apps**.

Q: What are Rancher "cluster tools"?
A: A curated set of first-party charts surfaced in the UI, including **Monitoring**, **Logging**, **Istio**, **Longhorn**, **NeuVector**, **CIS Benchmark**, **Kubewarden** (the current policy engine; the older **OPA Gatekeeper** integration is deprecated), and **Alerting**. They are just charts from the Rancher repo, pre-integrated with Rancher's dashboards and RBAC.

Q: What does a chart's questions.yaml file do?
A: **`questions.yaml`** is a Rancher-specific file that drives a **form-based UI** for chart values. Each question maps to a path in `values.yaml`, so users configure the chart through drop-downs and fields instead of editing raw YAML. It is optional and ignored by plain Helm.

Q: How do you upgrade or roll back an installed app in Apps & Marketplace?
A: From **Installed Apps**, choose **Upgrade** to change chart version or values (a `helm upgrade`), or **Rollback** to a previous **Helm revision**. Rancher keeps the Helm release history, so rollback restores that revision's manifests and values.

Q: How do chart annotations pin the release name and namespace for certified apps?
A: Via **`catalog.cattle.io/release-name`** and **`catalog.cattle.io/namespace`** annotations. Rancher-certified cluster tools install into a **fixed name and system namespace** (e.g. `cattle-monitoring-system`, `cattle-logging-system`, `longhorn-system`) rather than an arbitrary user-chosen one.

Q: How does Apps & Marketplace work in an air-gapped environment?
A: You mirror the charts into a **private/OCI Helm registry** or a **Git repo** reachable inside the air gap, then register it as a **ClusterRepo** with that internal `url`/`gitRepo`. Chart container images must likewise be mirrored to a private registry and remapped via `registries.yaml` or chart value overrides.
