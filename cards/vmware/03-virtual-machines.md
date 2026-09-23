# Virtual Machines

Q: Which files make up a virtual machine on a VMFS datastore?
A: A VM is a **set of files** in its own folder. Key ones:
- **`.vmx`** — configuration (hardware definition)
- **`.vmdk`** + **`-flat.vmdk`** — virtual disk descriptor + actual data
- **`.nvram`** — virtual BIOS/UEFI settings
- **`.vswp`** — swap file
- **`.vmsd`** / **`.vmsn`** — snapshot metadata / memory snapshot
- **`.log`** — activity log

Q: What is the .vmx file?
A: The **`.vmx` file** is the VM's **configuration file** — a plain-text file listing its virtual hardware: number of vCPUs, memory size, NIC and disk definitions, boot firmware, and advanced settings. It is effectively the VM's definition; the host reads it to build the VM when it powers on.

Q: What is the difference between the .vmdk descriptor and the -flat.vmdk file?
A: A virtual disk is two files. The **`.vmdk`** is a small **text descriptor** — geometry, adapter type, and a pointer to the data extent. The **`-flat.vmdk`** is the large binary file holding the **actual disk data**. In the vSphere Client you usually see them as a single "**VMDK**"; both are needed for a usable disk.

Q: What does the .nvram file store?
A: The **`.nvram` file** stores the VM's **firmware settings** — its non-volatile memory, i.e. the virtual **BIOS or UEFI** configuration such as boot order and firmware variables. It is the VM-level equivalent of a physical machine's CMOS/NVRAM.

Q: What is the purpose of a VM's .vswp swap file?
A: The **`.vswp`** is the VM's **memory swap file**, created on the datastore when the VM powers on. It backs guest memory that the host cannot keep in physical RAM under contention. Its size is the VM's memory minus any **memory reservation**, so a full reservation makes it near-zero. The file is deleted when the VM powers off.

Q: What are the .vmsd and .vmsn snapshot files?
A: The **`.vmsd`** file holds **snapshot metadata** — the names, descriptions, and relationships of a VM's snapshots. Each **`.vmsn`** captures the VM's **state at one snapshot**, including memory contents if the snapshot included memory. Together with delta disks they let you revert a VM to an earlier point in time.

Q: What is virtual hardware version (VM compatibility)?
A: **Virtual hardware version** (shown as **VM compatibility**, e.g. "ESXi 8.0 and later" = hardware version 20/21) defines the **virtual chipset and feature set** a VM presents. Higher versions unlock newer capabilities and larger limits but require hosts at that ESXi level or newer to run the VM. Upgrading it is optional and one-way.

Q: What are VMware Tools and open-vm-tools?
A: **VMware Tools** is a suite of **drivers and services installed in the guest OS** that improves performance and integration: paravirtual device drivers (VMXNET3, PVSCSI), graceful shutdown, time sync, heartbeats, and quiesced snapshots. **open-vm-tools** is the **open-source implementation** bundled with most modern Linux distributions, so no manual install is needed there.

Q: What is meant by the "guest OS" of a virtual machine?
A: The **guest OS** is the operating system installed **inside** the virtual machine (Windows, Linux, etc.) — as opposed to the **host** (ESXi/VMkernel) that runs the VM. Setting the correct guest OS type in the VM's config lets ESXi pick sensible defaults for devices, optimizations, and VMware Tools.

Q: What is the difference between thick lazy-zeroed, thick eager-zeroed, and thin VMDK provisioning?
A: Three disk formats:
- **Thick lazy-zeroed** — full space allocated up front, but each block is **zeroed on first write**.
- **Thick eager-zeroed** — full space allocated **and zeroed at creation**; slowest to create, best initial write performance (required by legacy FT).
- **Thin** — allocates almost nothing up front and **grows on demand**, saving space but risking datastore overcommit.

Q: What are VMXNET3 and PVSCSI paravirtual devices?
A: **VMXNET3** is a **paravirtualized virtual NIC** and **PVSCSI** is a **paravirtual SCSI controller**. Being VMware-aware (via VMware Tools drivers) rather than emulating real hardware, they offer **higher throughput and lower CPU overhead** than emulated devices like the E1000 NIC or LSI Logic controller. They are the recommended adapters for modern VMs.

Q: What is the virtual NVMe controller for a VM?
A: The **virtual NVMe controller** presents disks to the guest over the **NVMe** protocol instead of SCSI. It offers a **lower-overhead, lower-latency** I/O path well suited to all-flash and modern guests, and is supported alongside PVSCSI/SATA/IDE. It is chosen per virtual disk controller when configuring VM hardware.

Q: What are CPU and memory hot-add?
A: **CPU hot-add** and **memory hot-add** let you **increase a running VM's vCPUs or RAM without powering it off**, provided the feature is enabled on the VM and the guest OS supports it. They allow scaling up live workloads; note that hot-*removal* is generally not supported, and enabling hot-add can disable some memory optimizations (e.g. vNUMA hot-add caveats).

Q: What do vCPU and "cores per socket" mean for a VM?
A: A **vCPU** is one **virtual processor** presented to the guest. **Cores per socket** determines how those vCPUs are grouped into virtual **sockets** — e.g. 8 vCPUs as 2 sockets × 4 cores. The total vCPU count drives scheduling; the socket/core layout mainly affects guest **licensing** and the virtual **NUMA (vNUMA)** topology exposed to the OS.

Q: What is a virtual TPM (vTPM) for a VM?
A: A **virtual TPM (vTPM)** is a software-emulated **TPM 2.0 device** added to a VM, letting the guest use TPM-backed features like **Windows BitLocker or Secure Boot measurements** without physical TPM hardware. Its secrets are protected by **VM encryption**, so a vTPM requires a configured **key provider** in vCenter. It encrypts the VM's config/NVRAM files, not the data disks.

Q: What is a Raw Device Mapping (RDM)?
A: A **Raw Device Mapping (RDM)** gives a VM **direct access to a physical LUN** on the SAN instead of storing its disk as a VMDK on a datastore. A small mapping file on VMFS points to the raw LUN. RDMs are used for cases like **shared-disk clustering** or SAN-management tooling that needs the physical device; ordinary VMs use normal VMDKs.

Q: What is the difference between BIOS and EFI firmware for a VM?
A: A VM boots with one of two virtual firmwares set in its config: legacy **BIOS** or **UEFI (EFI)**. **UEFI** supports modern features such as **Secure Boot**, GPT disks, and faster boot, and is required for a **vTPM**; **BIOS** exists for older guests. The choice is stored in the VM's `.nvram` and generally must be fixed **before** OS installation, since switching afterward can break booting.
