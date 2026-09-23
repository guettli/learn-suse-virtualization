# Monitoring, Logging & Backup

Q: What does the rancher-monitoring chart deploy?
A: A packaged **kube-prometheus-stack**: the **Prometheus Operator**, **Prometheus**, **Alertmanager**, **Grafana**, plus node-exporter and kube-state-metrics. It installs into **`cattle-monitoring-system`** as a Rancher cluster tool.

Q: What does rancher-monitoring add on top of a vanilla Prometheus stack?
A: Rancher-integrated **Grafana dashboards** for cluster/node/workload metrics wired into the Rancher UI, RBAC-aware access to those graphs per project/namespace, and preconfigured scrape targets for the Rancher-managed control plane and components.

Q: Which CRDs do you use to add scrape targets and alert rules under rancher-monitoring?
A: The standard Prometheus Operator CRDs:
- **`ServiceMonitor`** / **`PodMonitor`** — declare what to scrape.
- **`PrometheusRule`** — define recording and **alerting rules**.
Rancher's Prometheus is configured to select these across namespaces.

Q: How is alert routing configured in rancher-monitoring?
A: Through **Alertmanager**, managed via the Rancher UI or the **`AlertmanagerConfig`** CRD. Native receivers like **Slack, email, PagerDuty, and webhook** are built in; you define routes and receivers that fire on `PrometheusRule` alerts.

Q: What is rancher-alerting-drivers for?
A: A companion chart adding notification **drivers not native to Alertmanager**, specifically **Microsoft Teams** and **SMS** (via Prometheus webhook receivers). Slack and email are handled by Alertmanager directly, so those don't need the extra drivers.

Q: What operator underpins the rancher-logging chart?
A: The **Logging operator** (the kube-logging project, formerly **Banzai Cloud**). It manages **Fluent Bit** (log collection per node) and **Fluentd** (aggregation/routing) for you, installed in **`cattle-logging-system`**.

Q: Which CRDs configure log collection and routing in rancher-logging?
A: Four:
- **`Flow`** / **`ClusterFlow`** — select and filter which logs to route.
- **`Output`** / **`ClusterOutput`** — define destinations (Elasticsearch, S3, Loki, syslog, etc.).
`Flow`/`Output` are **namespaced**; the `Cluster*` variants apply cluster-wide.

Q: What is the rancher-backup operator and what CRDs does it use?
A: An operator (`resources.cattle.io/v1`) that backs up and restores the **Rancher application itself**. CRDs:
- **`Backup`** — take a backup (references a ResourceSet + storage).
- **`Restore`** — restore from a backup file.
- **`ResourceSet`** — declares which resources/CRDs to capture.

Q: Why is rancher-backup different from etcd snapshots?
A: **etcd snapshots** capture a whole downstream cluster's key-value store (bound to that cluster's etcd). **rancher-backup** captures only the **Rancher management state** — its CRs, config, and secrets — as a portable **`.tar.gz`**, so you can **restore or migrate Rancher onto a different Kubernetes cluster**.

Q: What storage targets can rancher-backup write to?
A: An **S3-compatible** bucket (AWS S3 or **MinIO**, with a credential Secret) or a **PersistentVolume** via a StorageClass. The target is set in the `Backup` spec's `storageLocation`.

Q: How are schedules, retention, and encryption set on a rancher-backup Backup?
A: In the `Backup` spec:
- **`schedule`** — a cron expression (e.g. `"@midnight"`) for recurring backups.
- **`retentionCount`** — how many files to keep (default **10**).
- **`encryptionConfigSecretName`** — a Secret in **`cattle-resources-system`** holding an encryption config so backups are stored encrypted.

Q: Which ResourceSet should you use when migrating Rancher to a new cluster?
A: **`rancher-resource-set-full`**, which includes the essential **secrets** needed for a clean restore. `rancher-resource-set-basic` excludes secrets and is meant for lighter, same-cluster backups.

Q: Does Istio ship as a Rancher cluster tool?
A: Yes — **rancher-istio** packages upstream **Istio** (istiod, ingress gateway) as a chart into **`istio-system`**, integrated with rancher-monitoring for a **Kiali/Jaeger**-style mesh view. It's optional and installed like any other Apps & Marketplace tool.

Q: How does monitoring a downstream cluster differ from the Rancher local cluster?
A: rancher-monitoring is installed **per cluster** — each downstream cluster runs its own Prometheus/Grafana stack scoped to that cluster. The **local** (management) cluster is monitored separately; there is no single cross-cluster Prometheus, so you enable the tool on each cluster you want observed.
