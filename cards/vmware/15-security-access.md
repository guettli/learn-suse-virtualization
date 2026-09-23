# Security & Access

Q: How do roles, privileges, and permissions relate in vCenter?
A: A **privilege** is a single fine-grained right (e.g. "power on VM"). A **role** is a named bundle of privileges. A **permission** binds a **role** to a **user/group** on a specific **inventory object**. So you grant access by pairing "who + what role + on which object," and privileges roll up from there.

Q: What is the difference between a global permission and an object permission in vCenter?
A: An **object (inventory) permission** applies to one object and, by default, **propagates down** to its children within a single vCenter. A **global permission** applies across the **entire hierarchy of all linked vCenters** (Enhanced Linked Mode) from the root, ideal for administrators who must span every inventory.

Q: What is vCenter Single Sign-On (SSO) and what identity sources can it use?
A: **vCenter Single Sign-On (SSO)** is the authentication broker that issues tokens for vSphere logins. It supports identity sources such as **Active Directory (integrated Windows / LDAP)**, **OpenLDAP**, its local **vsphere.local** domain, and modern **OIDC** federation via **Identity Federation** (e.g. to Entra ID/ADFS) for external IdPs and MFA.

Q: What does ESXi lockdown mode restrict, and how do normal and strict differ?
A: **Lockdown mode** forces host management to go **through vCenter**, blocking most direct root logins. In **normal** lockdown the **DCUI stays available** so an admin can recover a host locally; in **strict** lockdown the **DCUI service is stopped** too. Accounts on the **Exception Users** list retain direct access if explicitly allowed.

Q: What is VM Encryption in vSphere?
A: **VM Encryption** encrypts a VM's **VMDK virtual disks and other files** (and its vMotion traffic) at the hypervisor level, transparently to the guest OS. ESXi encrypts the data using keys obtained from a configured **key provider**, protecting VM data at rest against theft of the underlying storage or files.

Q: What is a key provider / KMS, and what is the Native Key Provider?
A: A **key provider** supplies the encryption keys ESXi uses for VM Encryption, vTPM, and encrypted vMotion. Traditionally this was an external **KMS (KMIP server)**. The **Native Key Provider** is vCenter's **built-in** key provider requiring no external KMS — vCenter manages the keys, backed up via an admin-exported recovery file.

Q: What are a vTPM and VM Secure Boot?
A: A **vTPM (virtual Trusted Platform Module)** gives a VM a virtual TPM 2.0 device for guest features like BitLocker and Windows credential protection; its state is protected by VM Encryption/a key provider. **VM Secure Boot** validates the guest bootloader/kernel signatures at boot, ensuring only trusted, unmodified boot code runs inside the VM.

Q: What is the VMware Certificate Authority (VMCA)?
A: The **VMCA** is a certificate authority built into vCenter (part of the Platform Services stack) that **issues and manages certificates** for vCenter services and ESXi hosts. By default it acts as the **root CA**, auto-provisioning host and solution-user certs so the environment is trusted internally without manual per-host certificate work.

Q: What certificate modes can vSphere use for ESXi host certificates?
A: Three modes: **VMCA** (default) — VMCA signs each host's certificate automatically; **Custom** — an external/enterprise CA issues host certificates you manage; and **Thumbprint** (legacy, discouraged) — vCenter trusts the host's existing self-signed cert by fingerprint. VMCA-as-subordinate is also possible to chain to a corporate root.

Q: What is the vSphere "Secure Boot" for an ESXi host (vs a VM)?
A: **ESXi host Secure Boot** uses the server's **UEFI Secure Boot** to verify the signatures of the ESXi bootloader, VMkernel, and every installed VIB at boot, so tampered or unsigned code will not load. It protects the hypervisor itself — distinct from **VM Secure Boot**, which validates a guest OS's bootloader inside a VM.

Q: What is Virtualization-Based Security (VBS) support in vSphere?
A: **VBS (Virtualization-Based Security)** is a Windows feature that uses hardware virtualization to isolate secrets (e.g. Credential Guard, HVCI). vSphere supports running VBS-enabled guests by exposing the needed virtual hardware — **vTPM, Secure Boot, I/O MMU, and nested virtualization** — so the guest can create its isolated secure region.

Q: Why use least-privilege service accounts in vCenter?
A: **Least privilege** means giving each integration or service account only the specific **privileges/role on the objects it needs** — not full Administrator. This limits blast radius if credentials leak, and makes actions auditable to a distinct identity. Backup, monitoring, and automation tools should each get a scoped custom role rather than admin rights.
