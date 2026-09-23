# CLI, API & Terraform

Q: How do you log the `rancher` CLI in to a Rancher server?
A: Run `rancher login <server-url> --token <API-token>` (e.g. `rancher login https://rancher.example.com --token token-xxxxx:...`). It stores context in `~/.rancher/cli2.json`. If the token has access to multiple clusters/projects, the CLI prompts you to pick a default context.

Q: What do `rancher clusters`, `rancher projects`, and `rancher kubectl` do?
A: - `rancher clusters` / `rancher projects` — list the clusters/projects your token can see.
- `rancher context switch` — change the active cluster/project context.
- `rancher kubectl ...` — proxy `kubectl` at the currently selected cluster through Rancher (no separate kubeconfig needed).

Q: How are Rancher API tokens created and scoped?
A: In the UI under **Account & API Keys**, you create an **API Key** producing a **bearer token** like `token-abcde:...`. Tokens can be **scoped to a single cluster** and given a **TTL/expiry** (or no scope for account-wide). The token is passed as `Authorization: Bearer <token>` to the Rancher API.

Q: What is the difference between Rancher's Norman (v3) API and the Steve API?
A: - **Norman / v3** (`/v3`) — Rancher's legacy **management REST API** with Rancher-shaped resources (clusters, projects, users, catalogs).
- **Steve** (`/v1`) — a newer **Kubernetes-style** API that proxies raw k8s + CRD resources (the Cluster Explorer UI uses it).
The Terraform provider and CLI use both under the hood.

Q: What is the authorized cluster endpoint (ACE) and why use it?
A: The **authorized cluster endpoint** exposes a downstream cluster's API server **directly** (not proxied through Rancher). The downloaded kubeconfig includes both a Rancher-proxy context and a direct ACE context, so `kubectl` still works **if the Rancher server is down**. Requires ACE enabled on the cluster (RKE2/K3s/RKE).

Q: How do you get a kubeconfig for a downstream cluster from Rancher?
A: In the UI, cluster menu → **Download KubeConfig**, or via CLI `rancher clusters kubeconfig <cluster>`. The file typically contains multiple contexts: one that routes through the **Rancher proxy** and, if enabled, one for the **authorized cluster endpoint** (direct API access).

Q: In the Terraform rancher2 provider, what is bootstrap mode vs admin mode?
A: - **Bootstrap mode** (`bootstrap = true`) — first-run setup of a fresh Rancher: sets the initial admin password and creates the first API token; you **must not** supply `token_key`/`api_url` credentials with it.
- **Admin mode** — normal operation authenticated with `api_url` + `token_key` to manage resources.

Q: Which Terraform rancher2 resources provision a downstream cluster and its cloud credentials?
A: - **`rancher2_cluster_v2`** — provisions an **RKE2/K3s** cluster (the current provisioning API).
- **`rancher2_cloud_credential`** — stores provider credentials (e.g. vSphere, AWS) used by machine pools.
- **`rancher2_machine_config_v2`** — per-provider node template referenced by the cluster.

Q: How do you manage catalogs, projects, namespaces, and users as code with rancher2?
A: - **`rancher2_catalog_v2`** — register a Helm chart repo (Rancher 2.5+).
- **`rancher2_project`** and **`rancher2_namespace`** — Rancher projects and project-scoped namespaces.
- **`rancher2_user`**, **`rancher2_global_role_binding`**, **`rancher2_cluster_role_template_binding`**, **`rancher2_project_role_template_binding`** — users and RBAC bindings.

Q: How can Fleet GitRepos be managed via Terraform or CRDs?
A: Fleet is CRD-driven, so you can `kubectl apply` a **`fleet.cattle.io/v1 GitRepo`** in `fleet-default`/`fleet-local`, or manage it through Terraform (e.g. `rancher2_fleet_git_repo`, or a generic `kubernetes_manifest`). This declaratively points Fleet at a Git repo to continuously deploy across target clusters.

Q: How do you automate Rancher directly against its CRDs, and what is Hosted Rancher Prime?
A: Against the **local** cluster you can `kubectl apply` Rancher CRDs: `management.cattle.io` (clusters, users, tokens, projects) and `provisioning.cattle.io` (`Cluster`) — the API objects the UI/Terraform ultimately write. **Rancher Prime** is the SUSE-supported build; its charts/images come from the **Prime registry** (e.g. `registry.rancher.com`) which needs your Prime entitlement/credentials.
