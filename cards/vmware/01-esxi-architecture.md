# ESXi & Architecture

Q: What is ESXi?
A: **ESXi** is VMware's **type-1 (bare-metal) hypervisor** — it installs directly on server hardware with no underlying host OS and runs virtual machines. Its kernel is the **VMkernel**, which schedules CPU, memory, and I/O for VMs and for the management agents. ESXi is the compute foundation of a vSphere environment.

Q: What is the VMkernel in ESXi?
A: The **VMkernel** is the core of ESXi — a POSIX-like operating-system kernel that owns the hardware and **schedules CPU, memory, storage, and network I/O** for virtual machines and system processes. Each running VM and system process executes as a scheduled entity called a **world** on top of the VMkernel.

Q: What does the hostd agent do on an ESXi host?
A: **hostd** is the main **host management daemon**. It manages most operations on the host — VMs, storage, networking, and inventory state — and is the process the **VMware Host Client**, the ESXi Shell, and (indirectly) vCenter talk to. If hostd is down, the host cannot be managed even though VMs keep running.

Q: What is the vpxa agent on an ESXi host?
A: **vpxa** is the **vCenter agent** on ESXi — the middleman between the host and vCenter Server's **vpxd** service. When a host is added to vCenter, vpxa relays vCenter's requests down to **hostd** and reports host state back up. A standalone (non-vCenter) host has no active vpxa role.

Q: What is the DCUI on an ESXi host?
A: The **DCUI (Direct Console User Interface)** is the yellow-and-grey, text-based console shown on the host's physical monitor (or via remote console/IPMI). It is used for initial and low-level configuration — setting the **management IP**, root password, restarting management agents, and enabling troubleshooting services — not for day-to-day VM management.

Q: What are the ESXi Shell and SSH used for?
A: The **ESXi Shell** is a local command-line shell on the host (reached from the DCUI), and **SSH** gives remote access to that same shell. Both are **disabled by default** and are meant for troubleshooting and support tasks (e.g. `esxcli`, log inspection). They are enabled via the DCUI or the Host Client, and their state is logged as a security event.

Q: What does ESXi lockdown mode do?
A: **Lockdown mode** hardens a host by forcing management to go **through vCenter Server** and restricting direct logins. In **normal** lockdown the DCUI stays available (so an admin can recover a host that loses vCenter); in **strict** lockdown the DCUI service is stopped as well. Accounts on the **Exception Users** list can still access the host directly if configured.

Q: What is the difference between a vmnic and a vmk adapter on ESXi?
A: A **vmnic** (e.g. `vmnic0`) is a **physical NIC** — an actual network port on the host, used as an uplink for virtual switches. A **vmk** (e.g. `vmk0`) is a **VMkernel adapter** — a virtual network interface the host itself uses for its own IP-based traffic. VMs connect through port groups, not through vmk adapters.

Q: What is a VMkernel port and which services can it carry?
A: A **VMkernel port** is a virtual adapter (`vmkN`) that gives the ESXi host an IP stack for its own system traffic. Each one is enabled for one or more services: **Management**, **vMotion**, **vSAN**, **Provisioning** (clone/cold-migrate/snapshot NFC traffic), **Fault Tolerance logging**, and iSCSI/NFS storage access. Tagging a service on a vmk selects which port carries that traffic.

Q: What is the VMX process (world) for a virtual machine?
A: Each powered-on VM runs a **VMX process** — a `vmx` **world** on the host that represents that VM. It handles the VM's device emulation, its virtual BIOS/UEFI, and mouse/keyboard/console, and works alongside per-vCPU **VMM** contexts. One VMX world exists per running VM; killing it powers the VM off.

Q: What is the scratch partition on an ESXi host?
A: The **scratch partition** is a small persistent storage location ESXi uses for **logs, core dumps, and temporary files**. If none is configured (e.g. on small USB/SD boot media or PXE boot), ESXi keeps scratch on a RAM disk, so logs are lost on reboot — so a persistent scratch location on a datastore is recommended.

Q: What do TPM 2.0 and UEFI Secure Boot provide for an ESXi host?
A: **UEFI Secure Boot** ensures each component of the ESXi boot chain is cryptographically signed, so unsigned or tampered code will not load. A hardware **TPM 2.0** chip lets the host measure that boot and store the measurements, enabling **host attestation** — vCenter can verify a host booted trusted, unmodified software. Together they protect boot integrity.

Q: What is a boot bank on ESXi?
A: A **boot bank** is a partition holding an ESXi image (the hypervisor payload). ESXi keeps a **primary boot bank** plus a secondary **alt boot bank**; an upgrade or patch is written to the alternate bank so the host can **roll back** to the previous image if the new one fails to boot. This gives resilient, reversible updates.

Q: What does putting an ESXi host into maintenance mode do?
A: **Maintenance mode** prepares a host for service (patching, hardware work). No VMs may be powered on or migrated **onto** it, and running VMs must first be **powered off or evacuated** (DRS/vMotion moves them elsewhere in a cluster). The host does not fully enter maintenance mode until it holds no running VMs. It is the prerequisite for safe reboots and upgrades.

Q: How does ESXi differ from a type-2 (hosted) hypervisor like VMware Workstation?
A: **ESXi is a type-1 hypervisor**: it runs directly on the hardware, giving VMs near-native performance and no competing host OS. A **type-2 (hosted) hypervisor** like **VMware Workstation** or Fusion runs as an application **on top of an existing OS** (Windows, Linux, macOS), which is convenient for desktops but adds overhead and depends on the host OS. ESXi targets servers and data centers.
