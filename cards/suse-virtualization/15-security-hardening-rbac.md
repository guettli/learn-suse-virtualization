# Security, Hardening & RBAC

Q: How do you authenticate to a standalone SUSE Virtualization cluster before it is imported into Rancher?
A: A standalone cluster uses the **embedded Rancher's local authentication**: on first access to the UI/API you set the **initial admin password**, and further logins use that **local admin user**. There is no external identity provider until the cluster is imported into a full Rancher, so day-one access is a single local account you should immediately give a strong password.

Q: Which external identity providers become available for user login once a cluster is imported into Rancher?
A: Importing delegates login to **Rancher's authentication providers**, which include **Active Directory / LDAP, SAML (Okta, ADFS, Keycloak, Ping, Shibboleth), OIDC/Keycloak, GitHub, and others**. Rancher maps each authenticated user to local or external identities, so you stop relying on the single built-in admin and can enforce central password/MFA policy.

Q: How do you restrict a team so it can see and manage only its own VMs?
A: Use **Rancher Projects and namespaces with RBAC**: put the team's VM namespaces in a **Project**, then grant that team a **project role** (e.g. project member/owner) instead of a cluster-wide role. Because every VM is a namespaced `VirtualMachine`, the RoleBindings confine them to their namespaces and they never see other tenants' VMs.

Q: How do you replace the self-signed certificate on the Harvester UI/API and management VIP?
A: Set the **`ssl-certificates`** setting (a `settings.harvesterhci.io` object) with your **CA cert, public cert, and private key in PEM**. The certificate must include an **IP SAN for the VIP** or clients reject it. Tune protocols/ciphers with **`ssl-parameters`**; rotation is done by updating the setting with a new cert/key.

Q: How do you cap how much CPU, memory, or storage a tenant's VMs can consume in a namespace?
A: Apply a standard Kubernetes **`ResourceQuota`** to the namespace (surfaced through the **Rancher Project quota** UI). Because VMs run as pods, the VM's CPU/memory **requests and limits** count against the quota, bounding a tenant even though Harvester allows overcommit at the node level.

Q: How do you keep one tenant's VM traffic isolated from another's at layer 2?
A: Give each tenant its **own VLAN**, exposed as a **`NetworkAttachmentDefinition` (Multus)** scoped to that tenant's namespace/Project. VMs attach only to the NAD in their namespace, so their frames are tagged onto separate VLANs and tenants cannot reach each other's L2 segment even though they share the same uplink/ClusterNetwork.

Q: How should SSH keys and passwords for cloud-init be stored rather than embedding them in the VM spec?
A: Store them in a **Kubernetes `Secret`** and reference it from the VM (cloud-init `secretRef` / the managed **SSH key** objects), instead of pasting plaintext into `spec` user-data. This keeps credentials out of the VM manifest, lets RBAC control who can read them, and allows rotation without editing every VM.

Q: How do you enable Secure Boot for a VM, and what other feature must be turned on with it?
A: Set **`spec.domain.firmware.bootloader.efi.secureBoot: true`** (UEFI/OVMF), which **requires SMM** — you must also set **`spec.domain.features.smm.enabled: true`**. Secure Boot then validates the guest bootloader/kernel signatures; it is also a prerequisite (with vTPM) for Windows 11 guests.

Q: What host-OS properties shrink the attack surface of a SUSE Virtualization node?
A: The node runs an **immutable SLE Micro (SUSE Linux Micro)** base: a **read-only root filesystem, minimal package set, and transactional (atomic) updates**, so there is no package manager or ad-hoc daemon to tamper with at runtime. **SELinux** confines processes on top of that, and configuration is driven declaratively rather than by logging in and editing files.

Q: What actually isolates a tenant VM from the host kernel and from other VMs?
A: Each VM runs as a **QEMU/KVM process inside a `virt-launcher` pod**, so the guest sits behind a **hardware-virtualization (VMX/SVM) boundary** with its own kernel — a much stronger boundary than containers, which share the host kernel. KVM plus the pod's namespaces/SELinux context contain a compromised guest to that VM.

Q: How are host and hypervisor CVEs patched on a SUSE Virtualization cluster?
A: Through the **cluster upgrade mechanism**, not `zypper`/manual patching. An upgrade bundles a **new immutable host OS image plus updated KubeVirt/Longhorn/RKE2/Rancher components** and rolls it node-by-node with live migration, so applying security fixes means moving to the next patched release rather than mutating a running node.

Q: How do you stop ordinary users from opening VM consoles or driving VMs with virtctl?
A: Console/VNC and `virtctl` act on **KubeVirt subresources** (`virtualmachineinstances/console`, `.../vnc`, and start/stop subresources). Grant those verbs only in roles for privileged users, and scope each user's **kubeconfig/API token** via RBAC — a user without the subresource permission cannot attach a console even if they can list the VM.

Q: How do you protect VM data at rest on the underlying disks?
A: Use an **encrypted Longhorn/SUSE Storage StorageClass** (`parameters.encrypted: "true"`), which encrypts each volume with **LUKS/dm-crypt** before the filesystem is written. The passphrase lives in a **`Secret`** referenced via `csi.storage.k8s.io/{provisioner,node-stage,node-publish}-secret-name` (fields like `CRYPTO_KEY_VALUE`, `CRYPTO_KEY_CIPHER`), so stolen disks are unreadable without the key.

Q: Where is hardening guidance for a SUSE Virtualization cluster found, and what does it build on?
A: Follow the product's **security/hardening guide** plus the underlying **RKE2 and SUSE Linux Micro hardening** guidance (CIS-aligned): enable SELinux enforcement, restrict RBAC to least privilege, protect the VIP with real TLS, and rely on the **Kubernetes API audit log** (RKE2 writes it to `/var/lib/rancher/rke2/server/logs/audit.log`) for accountability. Harvester inherits RKE2's CIS-benchmark posture rather than defining a separate benchmark.
