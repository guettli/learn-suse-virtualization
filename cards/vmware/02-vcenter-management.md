# vCenter & Management

Q: What is vCenter Server?
A: **vCenter Server** is the **centralized management platform** for a vSphere environment. It manages many ESXi hosts and their VMs from a single pane, maintains the shared inventory, and enables cluster-wide features that need coordination — **vMotion, DRS, HA, and vSphere Lifecycle Manager**. Hosts can run without it, but those features require vCenter.

**SUSE Virtualization:** The **Harvester UI** plus **Rancher** provide centralized management, with the **Kubernetes API** as the control plane that coordinates cluster-wide features like live migration and VM HA.

Q: What is the vCenter Server Appliance (VCSA)?
A: The **vCenter Server Appliance (VCSA)** is a preconfigured Linux virtual machine that runs vCenter Server and its bundled services. It is based on VMware's **Photon OS** and ships with an embedded **PostgreSQL** database, the authentication/SSO services, and lifecycle components — deployed from an OVA, so no separate OS or database install is needed.

**SUSE Virtualization:** No separate appliance VM — the management plane runs as **pods on the cluster's own RKE2 Kubernetes**, so there is nothing like a VCSA to deploy.

Q: Is the Windows version of vCenter Server still available in vSphere 8?
A: No. The Windows installable vCenter Server was **deprecated in vSphere 6.7 and removed in vSphere 7.0**, so vSphere 7 and 8 ship **only the appliance (VCSA)**. Any older Windows vCenter must be **migrated to the VCSA** before upgrading. The appliance is now the sole deployment model.

**SUSE Virtualization:** No equivalent — Harvester has only ever shipped as a Kubernetes-based appliance, with no alternate installable management-server platform.

Q: What is the vSphere Client?
A: The **vSphere Client** is the browser-based **HTML5** web UI, served by vCenter Server, used to manage the whole inventory. It replaced the older Adobe **Flash/Flex** vSphere Web Client (removed in vSphere 7) and the legacy Windows C# "thick" client. A separate **VMware Host Client** (also HTML5) manages a single ESXi host directly.

**SUSE Virtualization:** The browser-based **Harvester UI** (built in, and also surfaced inside **Rancher**) is the equivalent management console.

Q: What was the Platform Services Controller (PSC), and where is it in vSphere 8?
A: The **Platform Services Controller (PSC)** hosted shared services — **Single Sign-On, licensing, and the certificate authority**. It could once be deployed externally, but external PSC was deprecated; in vSphere 7 and 8 the PSC role is **always embedded inside vCenter Server**, so it is no longer a separate deployable component.

**SUSE Virtualization:** No direct equivalent — shared services such as authentication come from **Rancher**, and certificates are managed by Kubernetes (cert-manager) rather than a PSC-style component.

Q: What is vCenter Single Sign-On (SSO)?
A: **vCenter Single Sign-On (SSO)** is the authentication service that issues security tokens so users log in **once** and access all vSphere components and linked vCenters. It brokers between users and identity sources (its own directory plus **Active Directory / LDAP**), and it underpins Enhanced Linked Mode.

**SUSE Virtualization:** **Rancher authentication** plays this role — local users plus **AD/LDAP/SAML/OIDC** providers — once the Harvester cluster is imported into Rancher.

Q: What is the SSO domain and what is vsphere.local?
A: The **SSO domain** is the internal identity/authentication domain created when vCenter is deployed; its default name is **vsphere.local**. It contains built-in accounts such as **administrator@vsphere.local** and defines the trust boundary within which vCenter Servers can be joined together. It is distinct from any Active Directory domain you also connect.

**SUSE Virtualization:** The closest analog is **Rancher's local authentication** realm (with its built-in admin user); there is no vsphere.local-style internal SSO domain.

Q: What is Enhanced Linked Mode?
A: **Enhanced Linked Mode** joins multiple vCenter Server systems into **one SSO domain** so you can log in to any one of them and **view and manage the combined inventory** of all. It replicates roles, permissions, licenses, tags, and policies across the members — giving a single view without a separate external PSC.

**SUSE Virtualization:** **Rancher** centrally manages many Harvester clusters from one console, giving the multi-cluster single-pane equivalent of Enhanced Linked Mode.

Q: What are the levels of the vCenter inventory hierarchy?
A: From the top down: the **vCenter Server** root, then **Datacenter** objects, then **Clusters** and standalone **Hosts**, then **resource pools** and the **VMs** themselves. **Folders** can be inserted at most levels to group objects (hosts, VMs, networks, datastores) for organization and permissions. This tree is how inventory and access are structured.

**SUSE Virtualization:** VMs are grouped by **Kubernetes namespaces** (surfaced as Rancher **projects**); the datacenter/cluster level maps to the **Harvester cluster** itself, and there is no folder tree.

Q: What is a datacenter object in vCenter, and how does it differ from a physical datacenter?
A: A **datacenter object** is a **logical inventory container** in vCenter — the top-level boundary that groups the hosts, clusters, VMs, networks, and datastores that share an inventory namespace. It is not a physical building: one vCenter can hold several datacenter objects, and they simply organize inventory rather than describe where the hardware physically sits.

**SUSE Virtualization:** No direct equivalent — a **Harvester cluster** is the top-level boundary, and logical grouping within it is done with **namespaces/projects** rather than datacenter objects.

Q: What are tags and categories in vCenter?
A: **Tags** are labels you attach to inventory objects (VMs, hosts, datastores) to classify them beyond the folder tree — e.g. `env:prod`, `tier:gold`. A **category** groups related tags and sets rules, such as which object types a tag applies to and whether **one or many** tags from that category may be assigned. Tags drive searches, permissions, and storage/DRS policies.

**SUSE Virtualization:** Kubernetes **labels and annotations** classify VMs and other objects, serving the role of tags and categories.

Q: What is the vpxd service in vCenter Server?
A: **vpxd** is the **core vCenter Server daemon** — the main process that holds the inventory, coordinates hosts, and drives cluster features like vMotion, DRS, and HA. It talks down to each host's **vpxa** agent. If vpxd is stopped, centralized management is unavailable even though the ESXi hosts keep running their VMs.

**SUSE Virtualization:** The **Kubernetes API server** (with KubeVirt's controllers) is the core coordinating service; if it is down, centralized management stops while the nodes keep running their VMs.

Q: What is vCenter High Availability (VCHA)?
A: **vCenter HA (VCHA)** protects the vCenter Server Appliance itself by running a three-node cluster — an **Active**, a **Passive** (a clone of Active), and a lightweight **Witness**. State is replicated to the passive node, which **automatically takes over** if the active node fails, reducing vCenter downtime. It protects the management plane, not the workload VMs.

**SUSE Virtualization:** Management-plane resilience comes from running **multiple management (control-plane) nodes** in the RKE2 cluster, so etcd and the API server stay available if one node fails.

Q: What is the VAMI, and on which port is it reached?
A: The **VAMI (vCenter/VMware Appliance Management Interface)** is the web UI for managing the **appliance** itself — networking, time/NTP, certificates, backups, updates, and service health — reached at **https://<vcenter>:5480**. It is separate from the vSphere Client (which manages the virtual infrastructure); the VAMI manages the VCSA as a Linux appliance.

**SUSE Virtualization:** No direct equivalent — there is no appliance VM to manage; node and cluster settings are configured through the **Harvester UI** and the immutable OS's declarative configuration.

Q: What does it mean for an ESXi host to be "added to vCenter"?
A: Adding a host to vCenter places it under **centralized management**: vCenter pushes a **vpxa** agent that connects to its **hostd**, imports the host's inventory, and takes over as the authority for changes. The host can then join clusters and use vMotion/DRS/HA. A host **not** added to vCenter is standalone and managed only via the Host Client or shell.

**SUSE Virtualization:** The analog is **importing a Harvester cluster into Rancher** for centralized management; an unimported cluster is still fully managed by its own embedded Harvester UI.
