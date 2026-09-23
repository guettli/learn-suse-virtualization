# ESXi & Architecture

Q: What is ESXi?
A: **ESXi** is VMware's **type-1 (bare-metal) hypervisor** — it installs directly on server hardware with no underlying host OS and runs virtual machines. Its kernel is the **VMkernel**, which schedules CPU, memory, and I/O for VMs and for the management agents. ESXi is the compute foundation of a vSphere environment.

**SUSE Virtualization:** A **Harvester node** — bare-metal, immutable **SUSE Linux Micro** running **KVM/QEMU under KubeVirt** — is the equivalent compute foundation, except the hypervisor sits on top of Kubernetes rather than standing alone.

Q: What is the VMkernel in ESXi?
A: The **VMkernel** is the core of ESXi — a POSIX-like operating-system kernel that owns the hardware and **schedules CPU, memory, storage, and network I/O** for virtual machines and system processes. Each running VM and system process executes as a scheduled entity called a **world** on top of the VMkernel.

**SUSE Virtualization:** No single named analog — the node's **Linux kernel with KVM** owns the hardware while KubeVirt's **virt-handler** manages each VM's execution and I/O.

Q: What does the hostd agent do on an ESXi host?
A: **hostd** is the main **host management daemon**. It manages most operations on the host — VMs, storage, networking, and inventory state — and is the process the **VMware Host Client**, the ESXi Shell, and (indirectly) vCenter talk to. If hostd is down, the host cannot be managed even though VMs keep running.

**SUSE Virtualization:** The per-node **kubelet** plus KubeVirt's **virt-handler** fill the host-management role, driven declaratively through the Kubernetes API.

Q: What is the vpxa agent on an ESXi host?
A: **vpxa** is the **vCenter agent** on ESXi — the middleman between the host and vCenter Server's **vpxd** service. When a host is added to vCenter, vpxa relays vCenter's requests down to **hostd** and reports host state back up. A standalone (non-vCenter) host has no active vpxa role.

**SUSE Virtualization:** The node's **kubelet** (alongside virt-handler) is the equivalent agent, reporting to and taking direction from the **Kubernetes API server** rather than a vCenter vpxd.

Q: What is the DCUI on an ESXi host?
A: The **DCUI (Direct Console User Interface)** is the yellow-and-grey, text-based console shown on the host's physical monitor (or via remote console/IPMI). It is used for initial and low-level configuration — setting the **management IP**, root password, restarting management agents, and enabling troubleshooting services — not for day-to-day VM management.

**SUSE Virtualization:** The node **console or SSH** to the immutable **SUSE Linux Micro** host, used mainly for recovery/troubleshooting since host configuration is otherwise declarative.

Q: What are the ESXi Shell and SSH used for?
A: The **ESXi Shell** is a local command-line shell on the host (reached from the DCUI), and **SSH** gives remote access to that same shell. Both are **disabled by default** and are meant for troubleshooting and support tasks (e.g. `esxcli`, log inspection). They are enabled via the DCUI or the Host Client, and their state is logged as a security event.

**SUSE Virtualization:** **SSH to the SUSE Linux Micro node** gives shell access for troubleshooting, but because the host is immutable/appliance-style it is not the normal management path.

Q: What does ESXi lockdown mode do?
A: **Lockdown mode** hardens a host by forcing management to go **through vCenter Server** and restricting direct logins. In **normal** lockdown the DCUI stays available (so an admin can recover a host that loses vCenter); in **strict** lockdown the DCUI service is stopped as well. Accounts on the **Exception Users** list can still access the host directly if configured.

**SUSE Virtualization:** No direct equivalent — the **immutable, appliance-style host** limits direct changes by design, with no lockdown toggle to enable.

Q: What is the difference between a vmnic and a vmk adapter on ESXi?
A: A **vmnic** (e.g. `vmnic0`) is a **physical NIC** — an actual network port on the host, used as an uplink for virtual switches. A **vmk** (e.g. `vmk0`) is a **VMkernel adapter** — a virtual network interface the host itself uses for its own IP-based traffic. VMs connect through port groups, not through vmk adapters.

**SUSE Virtualization:** Physical NICs are the node's uplinks (bonded into the **management/cluster network**), while the node's own IP traffic rides that management interface rather than a separate vmk-style adapter.

Q: What is a VMkernel port and which services can it carry?
A: A **VMkernel port** is a virtual adapter (`vmkN`) that gives the ESXi host an IP stack for its own system traffic. Each one is enabled for one or more services: **Management**, **vMotion**, **vSAN**, **Provisioning** (clone/cold-migrate/snapshot NFC traffic), **Fault Tolerance logging**, and iSCSI/NFS storage access. Tagging a service on a vmk selects which port carries that traffic.

**SUSE Virtualization:** No per-service VMkernel ports — the node carries Kubernetes, storage, and **live-migration** traffic over its **management network**, with separate **cluster/VLAN networks** for VM traffic.

Q: What is the VMX process (world) for a virtual machine?
A: Each powered-on VM runs a **VMX process** — a `vmx` **world** on the host that represents that VM. It handles the VM's device emulation, its virtual BIOS/UEFI, and mouse/keyboard/console, and works alongside per-vCPU **VMM** contexts. One VMX world exists per running VM; killing it powers the VM off.

**SUSE Virtualization:** Each running VM is backed by a **virt-launcher pod** wrapping a QEMU process — KubeVirt's equivalent of the per-VM VMX world.

Q: What is the scratch partition on an ESXi host?
A: The **scratch partition** is a small persistent storage location ESXi uses for **logs, core dumps, and temporary files**. If none is configured (e.g. on small USB/SD boot media or PXE boot), ESXi keeps scratch on a RAM disk, so logs are lost on reboot — so a persistent scratch location on a datastore is recommended.

**SUSE Virtualization:** No direct equivalent — the immutable OS keeps logs and state on its own persistent partitions, and cluster-wide logs are handled by the **Prometheus/Grafana/logging stack** rather than a datastore scratch area.

Q: What do TPM 2.0 and UEFI Secure Boot provide for an ESXi host?
A: **UEFI Secure Boot** ensures each component of the ESXi boot chain is cryptographically signed, so unsigned or tampered code will not load. A hardware **TPM 2.0** chip lets the host measure that boot and store the measurements, enabling **host attestation** — vCenter can verify a host booted trusted, unmodified software. Together they protect boot integrity.

**SUSE Virtualization:** Harvester nodes likewise support hardware **UEFI Secure Boot**, and the immutable SUSE Linux Micro OS provides a verified boot chain (vCenter-style host TPM attestation is not a Harvester-exposed feature).

Q: What is a boot bank on ESXi?
A: A **boot bank** is a partition holding an ESXi image (the hypervisor payload). ESXi keeps a **primary boot bank** plus a secondary **alt boot bank**; an upgrade or patch is written to the alternate bank so the host can **roll back** to the previous image if the new one fails to boot. This gives resilient, reversible updates.

**SUSE Virtualization:** The immutable **SUSE Linux Micro** OS uses **A/B image slots** (via Elemental) so upgrades are applied atomically and roll back on failure, mirroring the boot-bank model.

Q: What does putting an ESXi host into maintenance mode do?
A: **Maintenance mode** prepares a host for service (patching, hardware work). No VMs may be powered on or migrated **onto** it, and running VMs must first be **powered off or evacuated** (DRS/vMotion moves them elsewhere in a cluster). The host does not fully enter maintenance mode until it holds no running VMs. It is the prerequisite for safe reboots and upgrades.

**SUSE Virtualization:** Harvester has a **node maintenance mode** that cordons the node and **live-migrates its VMs** off before servicing — the same prerequisite for safe reboots and upgrades.

Q: How does ESXi differ from a type-2 (hosted) hypervisor like VMware Workstation?
A: **ESXi is a type-1 hypervisor**: it runs directly on the hardware, giving VMs near-native performance and no competing host OS. A **type-2 (hosted) hypervisor** like **VMware Workstation** or Fusion runs as an application **on top of an existing OS** (Windows, Linux, macOS), which is convenient for desktops but adds overhead and depends on the host OS. ESXi targets servers and data centers.

**SUSE Virtualization:** Harvester is likewise a **bare-metal platform** — KVM/KubeVirt run directly on the node hardware, not as an application on top of a desktop host OS.
