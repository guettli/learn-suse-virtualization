# Authentication & RBAC

Q: Which external authentication providers can Rancher integrate with?
A: Beyond **local** auth, Rancher supports **Active Directory**, **LDAP/OpenLDAP**, **SAML** (Keycloak, Okta, ADFS, PingID, Shibboleth), **OIDC** (generic + Keycloak OIDC), **GitHub**, and **Azure AD / Entra ID**. External identity providers are the preferred method; local is meant for small/test setups.

Q: How does Rancher use external users and groups from an auth provider?
A: Rancher authenticates against the provider, then maps the returned **user identity and group memberships** onto Rancher access. You can grant roles directly to a user or to a **group**, so every member of that group inherits the assigned cluster/project permissions automatically.

Q: What are the three tiers of Rancher's RBAC hierarchy?
A: - **Global roles/permissions** — what a user can do across the whole Rancher install.
- **Cluster roles** — access within a specific managed cluster.
- **Project roles** — access within a Rancher project (group of namespaces).
Each tier is granted independently.

Q: What is a RoleTemplate in Rancher?
A: A **`RoleTemplate`** (in `management.cattle.io`) is a reusable set of permissions with a **context of `cluster` or `project`**. Built-ins include **`cluster-owner`**, **`cluster-member`**, **`project-owner`**, **`project-member`**, and **read-only**; admins can also author **custom** RoleTemplates.

Q: How does a Rancher cluster/project role actually take effect in the downstream cluster?
A: Rancher creates binding CRDs — a **`ClusterRoleTemplateBinding`** or **`ProjectRoleTemplateBinding`** — that reference a `RoleTemplate` and a subject. Rancher's controllers then project these into **native Kubernetes `ClusterRole`/`RoleBinding` objects** on the downstream cluster.

Q: What do the built-in Cluster Owner and Cluster Member roles grant?
A: **Cluster Owner** = full control of the cluster and all its resources. **Cluster Member** = view most cluster-level resources and create new projects; when a member creates a project they become its **Project Owner**.

Q: What distinguishes Project Owner, Project Member, and Read Only project roles?
A: **Project Owner** fully controls the project and can manage its members. **Project Member** manages project resources (namespaces, workloads) but **not other members**. **Read Only** can view everything in the project but cannot create, update, or delete.

Q: What are the default built-in global roles in Rancher?
A: - **Administrator** — full control of Rancher and all clusters.
- **Standard User** — can create/use clusters and grant access on their own clusters.
- **User-Base** — login only, minimal permissions.
A **`GlobalRoleBinding`** ties a user/group to a `GlobalRole`.

Q: Which global role does a brand-new user receive by default?
A: New users get the **"New User Default"** global role, which is **Standard User** out of the box. Admins can change which RoleTemplate(s) are marked as the default so new logins land with different baseline permissions.

Q: What is the restricted-admin global role and what is its status?
A: **restricted-admin** has full admin over **downstream clusters but not the local Rancher cluster**, preventing privilege escalation on the management plane. It was **deprecated in v2.8, fully deprecated in v2.10, and removed in v2.11**; SUSE recommends a **custom global role** using **`inheritedClusterRoles`** instead.

Q: How can a GlobalRole grant the same cluster permissions on every downstream cluster?
A: Via its **`inheritedClusterRoles`** field, which lists cluster-context `RoleTemplate`s. Users with that global role automatically receive those permissions on **all current and future downstream clusters**, avoiding per-cluster binding.

Q: How do users differ from service accounts and API keys in Rancher access?
A: **Users** authenticate interactively (local or external IdP) and carry Rancher roles. **API keys / tokens** are bearer credentials a user creates for programmatic access under their own permissions; they can be scoped and time-limited, unlike a persistent in-cluster ServiceAccount.

Q: What does the auth-provider "Site Access" / allow-mode setting control?
A: It scopes **who may log in** after a provider is configured: **Allow any valid users** (anyone the IdP authenticates) vs restricting to **specified users and groups (members) only**. It gates authentication, separate from the RBAC roles granted afterward.

Q: How is the TTL of downloaded kubeconfig tokens controlled in Rancher?
A: The global setting **`kubeconfig-default-token-ttl-minutes`** sets kubeconfig token lifetime (default **43200 min = 30 days** in current 2.x); it must not exceed `auth-token-max-ttl-minutes`. Setting **`kubeconfig-generate-token=false`** makes kubeconfigs fetch short-lived tokens via the Rancher CLI instead.

Q: How do you scope a user to a single cluster or project?
A: Grant only a **cluster role** (via `ClusterRoleTemplateBinding`) on that one cluster, or only a **project role** (via `ProjectRoleTemplateBinding`) on that one project — while keeping their global role at **User-Base/Standard User**. They see and access only what those bindings allow.

Q: How does the initial local admin/bootstrap work in Rancher?
A: On first start Rancher creates a **local `admin` user**; the initial password is set with the **bootstrap password** (shown in server logs or provided at Helm install, e.g. `bootstrapPassword`). That admin then configures the external auth provider and grants roles to real users.
