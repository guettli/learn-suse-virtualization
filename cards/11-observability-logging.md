# Observability & Logging

Q: What monitoring stack ships embedded with SUSE Virtualization, and how is it packaged?
A: It ships the **`rancher-monitoring` addon** — a bundled **Prometheus + Grafana + Alertmanager + Prometheus Node Exporter** stack (the Prometheus Operator). It is **disabled by default on fresh installs** (enabled by default on clusters upgraded from older versions) and is toggled like any other Harvester addon.

Q: Which built-in Grafana dashboards does the embedded monitoring provide out of the box?
A: Three main views:
- **Cluster dashboard** — aggregate cluster/node metrics (admin only).
- **Top 10 VM Metrics** — the most resource-intensive VMs.
- **Per-VM metrics** — CPU/memory/disk/network for a single VM via the *VM detail page > VM Metrics* tab.

Q: Where do the per-VM CPU, memory, disk, and network metrics actually come from?
A: They are exported by the **KubeVirt / node exporters running on each host** and scraped by the embedded **Prometheus**, then rendered in Grafana. Note the memory panel computes usage as **`(1 - free/total) * 100%`** rather than `used/total`, so cached memory counts as "used".

Q: How do you enable, disable, or tune the embedded monitoring stack?
A: Manage it as an addon:
- UI: **Advanced > Addons > `rancher-monitoring`**.
- CLI: `kubectl edit addons.harvesterhci.io -n cattle-monitoring-system rancher-monitoring`.

Here you set Prometheus/Node Exporter/Alertmanager resource requests and limits (Prometheus minimum ~500Mi, recommended 5–10% of system memory).

Q: How is alerting configured, and what CRD defines the alert routing?
A: **Alertmanager** is part of the stack; routing/receivers are defined with the **`AlertmanagerConfig`** CRD (`monitoring.coreos.com/v1alpha1`), which is **namespace-scoped only** (no global config). It supports webhook receivers; for Microsoft Teams or SMS you additionally install the separate **`rancher-alerting-drivers`** Helm chart (prom2teams / sachet).

Q: How do you integrate SUSE Virtualization with an external monitoring system instead of the built-in one?
A: Prometheus is standard, so an **external Prometheus can scrape the cluster's metrics endpoints / ServiceMonitors**, or you push alerts to external receivers via `AlertmanagerConfig` webhooks. Because the whole cluster surfaces through **Rancher**, Rancher's own monitoring can also aggregate metrics across managed Harvester clusters.

Q: What is the embedded logging stack in SUSE Virtualization?
A: The **`rancher-logging` addon**, driven by the **Logging Operator**, using **Fluent Bit** as the per-node log collector and **Fluentd** as the aggregator/router. It is **disabled by default** and lives in the **`cattle-logging-system`** namespace, collecting pod logs, kernel logs, and systemd service logs (rke2, rancherd, iscsid, etc.).

Q: Which CRDs route and ship logs to external destinations, and what is the namespace rule?
A: **`Flow`/`ClusterFlow`** filter and route logs; **`Output`/`ClusterOutput`** define destinations (Elasticsearch, Splunk, Loki, Graylog, S3, etc.). Rule: a namespaced **Flow can only reference Outputs in its own namespace**, but may reference **any `ClusterOutput`**.

Q: How are audit logs captured differently from ordinary logs?
A: Audit logs flow through the same logging pipeline but are opt-in: the `Output`/`Flow` handling them must carry **`loggingRef: harvester-kube-audit-log-ref`** so the operator wires the Kubernetes API audit log source to that destination.

Q: What is a support bundle and when do you use it?
A: A **support bundle** is a downloadable archive of cluster logs, YAMLs, and diagnostics for troubleshooting or support cases. Generate it via **Support > Generate Support Bundle** in the UI (backed by `SupportBundle` objects, `kubectl get supportbundle -A`). Tune scope with the **`support-bundle-namespaces`** setting and time limit with **`support-bundle-timeout`**.

Q: How do you make the embedded Prometheus retain metrics across pod restarts and for a longer window?
A: Both are fields on the **`Prometheus` CR** the monitoring operator manages: **`retention`** sets the time window (the rancher-monitoring default is short — on the order of **10 days** — and can be raised), while **`storageSpec`** binds a **PersistentVolumeClaim** so the TSDB survives restarts. With no `storageSpec` PVC the data lives in **emptyDir** and is **lost whenever the pod moves**.

Q: How do you add a custom, persistent Grafana dashboard to the embedded monitoring?
A: Create a **ConfigMap in the `cattle-dashboards` namespace** holding the dashboard JSON and carrying the label **`grafana_dashboard: "1"`** — Grafana's sidecar auto-loads any ConfigMap so labeled. Because it is a ConfigMap it **survives pod restarts**, but it **cannot be edited or deleted from the Grafana UI**; you change the ConfigMap instead.

Q: How do you define your own alerting rule for the embedded Prometheus?
A: Create a **`PrometheusRule`** CR (`monitoring.coreos.com/v1`) in **`cattle-monitoring-system`** with the label **`release: rancher-monitoring`** so the Prometheus Operator discovers it. Its `spec.groups[].rules` hold the **PromQL** alert expressions; firing alerts then reach Alertmanager and exit through your `AlertmanagerConfig` receivers.

Q: How do you route firing alerts to Slack or email from the embedded stack?
A: Slack and email are **native Alertmanager receivers**, so you configure them directly in a namespaced **`AlertmanagerConfig`** — a receiver with **`slackConfigs`** or **`emailConfigs`**, wired in by a `route`. Only non-native targets such as **Microsoft Teams or SMS** require the extra **`rancher-alerting-drivers`** chart (prom2teams / sachet).
