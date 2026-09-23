# Upgrades & Troubleshooting

Q: What is the safe procedure to upgrade the Rancher management server?
A: Rancher installs via **Helm**, so upgrade is `helm upgrade rancher rancher-<channel>/rancher --version <new>` in `cattle-system` (keeping the same `hostname`/settings). **Before upgrading, take a rancher-backup** so you can roll back. Match the target version to the **support matrix** for your Kubernetes/downstream versions.

Q: What is rancher-backup and why take one before an upgrade?
A: **rancher-backup** is the official operator (installed as a chart) that backs up Rancher's resources — CRDs and `management.cattle.io` objects — to a target (S3/PVC) via a **Backup** CR, and restores via a **Restore** CR. A pre-upgrade backup is the **rollback path**: a failed Rancher upgrade is recovered by restoring the backup, not by downgrading Helm.

Q: What is the Rancher support/version matrix and why does upgrade order matter?
A: The **support matrix** lists which Rancher version supports which downstream Kubernetes, RKE2/K3s, OS, and Docker versions. Rule of thumb: **upgrade Rancher first**, then downstream Kubernetes — a newer Rancher supports older k8s, but old Rancher may not manage a newer k8s. Never skip to a k8s version the running Rancher doesn't list as supported.

Q: How do you roll back a failed Rancher upgrade?
A: Rancher is stateful, so a Helm rollback alone is not enough — **restore the pre-upgrade rancher-backup**. Reinstall the matching **prior Rancher version** chart, then apply a **Restore** CR pointing at the backup; this rebuilds the management CRDs/objects to the pre-upgrade state.

Q: A downstream cluster shows Updating/Unavailable in Rancher — cause, check, fix?
A: **Cause:** the **cattle-cluster-agent** (in the downstream cluster) can't reach the Rancher server, so status stops flowing. **Check:** `kubectl -n cattle-system logs -l app=cattle-cluster-agent` for TLS/DNS/proxy errors; verify the agent can resolve/reach the Rancher URL and CA. **Fix:** correct DNS/firewall/CA trust, or re-apply the registration manifest to update the agent's server URL.

Q: What do cattle-cluster-agent and cattle-node-agent do?
A: - **cattle-cluster-agent** — one Deployment per downstream cluster; the **tunnel** back to Rancher for API/control-plane operations.
- **cattle-node-agent** — a **DaemonSet** on each node used for node-level tasks (e.g. etcd snapshot ops, node commands).
If a cluster goes unavailable, these agents' connectivity to Rancher is the first thing to check.

Q: How do you regenerate a cluster's registration command / re-register agents?
A: In the UI, cluster → **Registration** tab shows the current `kubectl apply -f <registration-url>` command. Re-running it re-deploys **cattle-cluster-agent/cattle-node-agent** with the correct server URL, CA checksum, and token — the fix after changing the Rancher **server-url**, hostname, or CA cert.

Q: How do you take and restore an etcd snapshot for an RKE2/K3s downstream cluster?
A: In Rancher, the cluster's **Snapshots** let you take an **etcd snapshot** (local or S3) on demand or on a schedule. **Restore** selects a snapshot and can restore etcd only, or etcd + Kubernetes version + cluster config. Restore is disruptive (rolls the control plane back to snapshot state), so snapshot before risky changes.

Q: Certificates in Rancher/downstream are expiring — cause, check, fix?
A: **Cause:** internal TLS certs (Rancher-generated or RKE2/K3s) reaching their ~1-year expiry. **Check:** Rancher UI surfaces cert expiry; on RKE2/K3s inspect `/var/lib/rancher/<distro>/server/tls`. **Fix:** **rotate** — RKE2/K3s auto-rotate certs on restart within the renewal window (or use the distro's cert rotate command); for Rancher itself, roll the leader pods / renew the ingress cert.

Q: The Rancher local cluster is unhealthy — how do you recover management access?
A: Rancher runs in the **local** cluster, so treat it as any k8s outage: `kubectl -n cattle-system get pods` and check the **rancher** Deployment/leader election and its datastore (the local RKE2/K3s etcd). Recover the local cluster's etcd from an **etcd snapshot** if needed; as a last resort restore Rancher state from a **rancher-backup** into a rebuilt local cluster.

Q: How do you reach downstream clusters when the Rancher server is down?
A: Use a kubeconfig context for the **authorized cluster endpoint (ACE)**, which talks to the downstream API server **directly** rather than through the Rancher proxy. Without ACE, downloaded kubeconfigs route only through Rancher and stop working when Rancher is unavailable — so enable ACE in advance for break-glass access.

Q: Air-gapped install/upgrade fails pulling images — cause, check, fix?
A: **Cause:** images/charts not mirrored, or nodes not pointed at the private registry. **Check:** confirm the release's **image list** was fully synced to your registry and that RKE2/K3s **`registries.yaml`** (mirror + credentials) is in place; look for `ImagePullBackOff`. **Fix:** re-run the mirror for the exact version, set the Helm `rancherImage`/`systemDefaultRegistry` values, and add registry auth secrets.

Q: How do you collect logs for a Rancher problem?
A: Pull the management logs with `kubectl -n cattle-system logs -l app=rancher` (leader pod is most useful), plus **cattle-cluster-agent** logs in the affected downstream cluster. For deep diagnostics use Rancher's **support-tools** collector (`rancherlabs/support-tools`, the `rancher2_logs_collector.sh` script) or **`rancher/support-bundle-kit`**, and gather RKE2/K3s server logs (`journalctl -u rke2-server`) on the local cluster nodes.
