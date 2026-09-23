# VM Lifecycle

Q: How do you create a VM from an image in Harvester?
A: In the UI you pick a **namespace**, set **CPU and memory**, and choose a **VM Image** to back the root disk (Harvester Images are imported from URLs or uploads). You can add extra volumes, networks, and cloud-init. The root disk defaults to **10 GiB or the image's virtual size, whichever is larger**.

Q: What is the difference between the VirtualMachine and VirtualMachineInstance objects?
A: **`VirtualMachine`** is the desired-state CRD you edit — its `runStrategy` and template define whether and how the VM should run. **`VirtualMachineInstance` (VMI)** is the running instance the controller creates from it, roughly the "process" of a live guest. Deleting the VMI stops the guest; the VirtualMachine can recreate it.

Q: How are CPU and memory defined in a VM's spec?
A: Under `spec.template.spec.domain` you set **`cpu`** (cores/sockets/threads) and **`memory`/resources**. Guest topology comes from cores×sockets×threads. Harvester advises that total **vCPUs should not exceed the host's physical threads**, though CPU overcommit relaxes what the scheduler actually reserves.

Q: Why does a VM reserve more memory than its guest RAM, and how is that tuned?
A: KubeVirt/QEMU need **overhead memory** (for the emulator, page tables, etc.) on top of guest RAM. Harvester sizes this automatically and lets you scale it with the **`additional-guest-memory-overhead-ratio`** setting (default `1.5`, range `1.0`–`10.0`) to avoid the VM being OOM-killed under load.

Q: What are the four KubeVirt run strategies and what does each mean?
A: **`Always`** — keep the VM running, restart it if it stops or crashes. **`RerunOnFailure`** — restart only after a failure, not after a clean guest shutdown. **`Manual`** — state changes only via explicit start/stop/restart. **`Halted`** — keep the VM stopped (shown as "Stopped" in the UI).

Q: What do the start, stop, restart, and pause actions do to a VM?
A: **Start/Stop** create or delete the VMI (a stop is a graceful ACPI shutdown). **Restart** stops then starts it. **Pause** freezes the running guest's vCPUs in memory (via libvirt) without shutting it down, so it can be resumed instantly; a paused VM still holds its host resources.

Q: What does the qemu-guest-agent enable inside a VM?
A: Installed in the guest, it lets the host **read guest info** (IP addresses, hostname, filesystem/OS details), perform **graceful shutdown/restart**, do **filesystem-quiesced snapshots**, and support **guest-level password/SSH-key injection**. Without it, the UI cannot report the guest IP or run agent-based operations.

Q: What is disk hotplug and when can you use it?
A: You can **attach or detach data volumes to a running VM** without rebooting it. The added volume appears to the guest as a new block device. Hotplug applies to additional disks (not the boot disk); a persistent volume added this way remains bound to the VM until detached.

Q: Can you hot-add a network interface to a running VM?
A: **NIC hotplug** lets you attach an additional network interface to a live VM without a reboot; the guest sees a new NIC and can configure it. (Hot-**remove** support is more limited, so plan interface changes accordingly.)

Q: What is a VM template in Harvester?
A: A reusable, versioned **blueprint** capturing a VM's configuration — CPU/memory, disks, images, networks, and cloud-init. New VMs created "from template" inherit those defaults, standardizing provisioning. You can maintain multiple template **versions** and pick a default.

Q: What is the difference between cloud-init user-data and network-data?
A: Both are cloud-init documents injected at first boot. **user-data** configures the OS — users, SSH keys, packages, and run commands. **network-data** configures **networking** — interfaces, static IPs, DNS, routes. Splitting them keeps host setup separate from network setup. Linux guests must have cloud-init installed to consume them.

Q: How are Windows guests customized at first boot instead of cloud-init?
A: Windows uses **Sysprep**: Harvester supplies an **`autounattend.xml` / `unattend.xml`** answer file (via a cloud-init-style volume) that Windows Setup consumes to set hostname, product key, users, and locale on generalized images — the Windows equivalent of Linux cloud-init.

Q: How do you access a VM's console in Harvester?
A: The UI offers a **graphical VNC console** and a **serial (text) console** to the guest, reachable even before the guest network is up. This is the out-of-band path for installs, boot troubleshooting, and recovering VMs with broken networking.

Q: What happens to a VM's volumes when you delete the VM?
A: Delete is selective: the UI lets you choose which attached **volumes/PVCs are deleted along with the VM** and which are **retained**. Typically the root disk is removed while data volumes can be kept for reuse. Retained volumes stay as Longhorn PVCs until you delete them explicitly.

Q: How does CPU and memory hotplug let you resize a running VM?
A: Tick **Enable CPU and Memory Hotplug** when creating the VM; Harvester then computes a **maximum** as the allocated amount times the global **`max-hotplug-ratio`** (default **4**, range 1–20). Later you raise cores/RAM live and Harvester **live-migrates** the VM onto a node with the new size, so the VM must be **migratable**. On **x86** both CPU and memory are hot; on **ARM64** only memory is hot and CPU changes need a restart.

Q: How do you enable UEFI, Secure Boot, and a virtual TPM for a VM?
A: A VM boots in either **BIOS** or **UEFI (EFI)** firmware. **Secure Boot** is an option layered on UEFI and needs an image that supports it. **Enable TPM** adds an emulated **TPM 2.0** device. Windows 11 guests require the full set — **UEFI + Secure Boot + TPM 2.0** — or Setup refuses to install.

Q: What does enabling the USB tablet input device fix for a VM?
A: It adds a **USB tablet (absolute-pointer)** input device to the guest. Without it the graphical/VNC console uses a relative PS/2 mouse, so the guest cursor **drifts out of sync** with your real pointer. The USB tablet makes pointer position **absolute**, so clicks land where you aim in the web console.

Q: What is the difference between adding an image-backed volume and a blank data volume to a VM?
A: An **image-backed (VM Image) volume** is cloned from a golden OS image and is normally the **bootable root disk**. A **blank data volume** provisions an **empty** PVC of a chosen size, StorageClass, and volume mode for the guest to format and use for data. Both are Longhorn PVCs; set **boot order** so the OS disk boots first.
