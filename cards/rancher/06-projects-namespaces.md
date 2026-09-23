# Projects & Namespaces

Q: What is a Project in Rancher?
A: A **Project** is a **Rancher-only grouping of namespaces** (a `management.cattle.io` CRD), not a native Kubernetes object. It lets you apply access control, resource quotas, and default limits to several namespaces as a single unit within one cluster.

Q: How do you move a namespace into or out of a Rancher project?
A: Assign it in the Rancher UI, or set the **`field.cattle.io/projectId`** annotation on the namespace (value `<cluster-id>:<project-id>`). Removing that annotation / choosing "None" detaches the namespace so it becomes a standalone namespace with no project.

Q: How do project-scoped resource quotas reach individual namespaces?
A: You define the quota once on the **Project**; Rancher then propagates it into each namespace as a **native Kubernetes `ResourceQuota`**. Kubernetes itself enforces the limits per namespace — the project layer just distributes and tracks them.

Q: What are the two limits a Rancher project resource quota specifies?
A: A **project limit** (total pool of a resource shared across all namespaces in the project) and a **namespace default limit** (automatically bound to each new namespace). A namespace can override its default via the **`field.cattle.io/resourceQuota`** annotation, as long as the project total isn't exceeded.

Q: What does a project's Container Default Resource Limit do?
A: It sets **default CPU/memory requests and limits** (`requestsCpu`, `requestsMemory`, `limitsCpu`, `limitsMemory`) applied to containers in the project's namespaces via a Kubernetes **`LimitRange`**, so pods created without explicit limits still get sensible defaults.

Q: How are members and roles assigned at the project level?
A: You add **project members** and grant them a **project RoleTemplate** (Project Owner, Project Member, or Read Only). This is bound via a **`ProjectRoleTemplateBinding`**, giving scoped access to only that project's namespaces without cluster-wide rights.

Q: What can be deployed or configured at the Rancher project scope?
A: Projects can host **project-scoped Apps/Helm charts** and **project-level monitoring/alerting**, letting a team install and observe workloads within their own namespaces without needing cluster-admin.

Q: How does Rancher enforce pod security since PodSecurityPolicy was removed?
A: Rancher provides **Pod Security Admission (PSA) Configuration Templates** (a CRD, v2.7.2+) that wrap upstream **Pod Security Admission**. Built-ins **`rancher-privileged`** and **`rancher-restricted`** can be set cluster-wide or applied per namespace/project, replacing the deprecated PodSecurityPolicy.

Q: What does the project "network isolation" option provide?
A: When enabled, Rancher adds **project network policies** so that pods can talk within the project's namespaces but **inbound traffic from other projects is blocked** (system namespaces stay reachable). It relies on a NetworkPolicy-capable CNI and gives project-level tenant isolation.

Q: What labels/annotations does Rancher add to a namespace it manages?
A: Chiefly **`field.cattle.io/projectId`** (which project the namespace belongs to, `<cluster-id>:<project-id>`), plus related `field.cattle.io/*` annotations for quota overrides. These are how Rancher tracks project membership on otherwise-standard namespaces.

Q: Why don't projects show up in plain kubectl?
A: Projects live as **`management.cattle.io` resources on the Rancher management cluster**, not in the downstream cluster's API. `kubectl` on a downstream cluster only sees the **namespaces** (and their `field.cattle.io/projectId` annotation) — the project grouping itself exists only through Rancher.
