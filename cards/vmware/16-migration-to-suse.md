# Migrating to SUSE Virtualization

Q: What changed in the VMware ecosystem that is driving migrations to SUSE Virtualization?
A: **Broadcom's acquisition of VMware** shifted vSphere to subscription-only, **per-core licensing** with large price increases, product bundling, and tighter lock-in. This pushed many shops to seek alternatives. **SUSE Virtualization** (upstream **Harvester**) is positioned as an open-source, Kubernetes-native cloud alternative to vSphere.

Q: How does SUSE Virtualization differ architecturally and commercially from vSphere?
A: It is **open source** (upstream Harvester) and **hyperconverged**: VMs run on Kubernetes via **KubeVirt**, storage via **Longhorn/SUSE Storage**, all on one cluster. There is **no proprietary per-core licensing** — you pay for an optional **SUSE support subscription**, not the software itself.

Q: What are the main paths to move VMs from vSphere into SUSE Virtualization?
A: Three:
- The built-in **vm-import-controller** addon (source-connected, automated per-VM import).
- A **manual** export → `qemu-img` convert → upload-as-image path.
- SUSE's partner tool **Coriolis** (Cloudbase) for live/agentless bulk migration.

Q: How do core vSphere compute concepts map to SUSE Virtualization?
A:
| vSphere | SUSE Virtualization |
|---|---|
| ESXi host | Harvester **node** |
| vCenter Server | Harvester UI + **Rancher** Virtualization Management |
| vSphere cluster | Harvester **cluster** |
| Resource pool | **Namespace/project** + **ResourceQuota** |
| Virtual machine | **VirtualMachine** (KubeVirt) |

Q: How do vSphere storage concepts map to SUSE Virtualization?
A:
- VMFS/vSAN **datastore** → **SUSE Storage/Longhorn StorageClass**.
- **VMDK** → **Longhorn volume** (backed by a raw/qcow2 image).
- **Storage vMotion** → Longhorn **replica move/rebalance** (data lives as replicas, not a datastore path).
- Thin provisioning → Longhorn thin-provisioned volumes.

Q: How do vSphere networking concepts map to SUSE Virtualization?
A:
- vSwitch/dvSwitch **uplink** → **ClusterNetwork** + bonded uplink NIC config.
- **Portgroup / VLAN** → a **VM (VLAN) Network** implemented as a **Multus NetworkAttachmentDefinition**.
- **NSX** overlay/microsegmentation → **Multus** networks + Kubernetes **NetworkPolicy** — a rough functional overlap, **not** a like-for-like replacement.

Q: How do vSphere availability and mobility features map to SUSE Virtualization?
A:
- **vMotion** → KubeVirt **live migration**.
- **DRS** → the Kubernetes **scheduler** for initial placement; there is **no continuous automatic load-rebalancing** equivalent to DRS.
- **vSphere HA** → **VM auto-restart** on a healthy node when a node fails.

Q: How do vSphere templates and guest tooling map to SUSE Virtualization?
A:
- **VM template / OVA** → a **VirtualMachineImage** and/or a **VM template**.
- **VMware Tools** → **qemu-guest-agent**.
- **Guest customization spec** → **cloud-init** (Linux) or sysprep/unattend (Windows).

Q: Which addon must you enable to import vSphere VMs, and what does it add?
A: The **vm-import-controller** addon (disabled by default). Enabling it installs the source CRDs — **VmwareSource**, **OpenstackSource**, **OvaSource** — and the **VirtualMachineImport** CRD, all under `apiVersion: migration.harvesterhci.io/v1beta1`.

Q: How do you register a vCenter/ESXi endpoint as an import source?
A: Create a **VmwareSource** with `spec.endpoint` (the vSphere SDK URL, e.g. `https://vc/sdk`), `spec.dc` (datacenter name), and `spec.credentials` referencing a **Secret** holding `username`/`password`. The controller validates the datacenter and marks the source **clusterReady**.

Q: Which object triggers importing one VM, and what does its spec reference?
A: A **VirtualMachineImport** (one per VM). Key fields: `virtualMachineName` (name or UUID), `sourceCluster` (a ref to the VmwareSource), `networkMapping`, `storageClass`, `defaultDiskBusType`, `forcePowerOff`, and `gracefulShutdownTimeoutSeconds`.

Q: How does the importer connect a migrated VM to the right Harvester networks?
A: Via `spec.networkMapping`, a list mapping each `sourceNetwork` (portgroup/dvSwitch name) to a `destinationNetwork` (`namespace/NAD`, e.g. `default/vlan1`), with an optional per-NIC `networkInterfaceModel`. `defaultNetworkInterfaceModel` defaults to **virtio**. Unmapped source networks are not attached.

Q: What is the source-VM power-state behavior during a vm-import-controller import?
A: It is a **cold** migration. The controller **gracefully shuts down** the guest first (which needs VMware Tools), then copies its disks. `forcePowerOff: true` does a **hard power off** instead, and `gracefulShutdownTimeoutSeconds` (default **60**) bounds the wait. The VM is unavailable while disks copy.

Q: What does the vm-import-controller actually do end to end?
A: It **exports the source VMDK(s)**, converts them to Harvester-compatible disk images, creates a **VirtualMachineImage** per disk, then builds a **VirtualMachine** wired to the mapped networks and storage class and starts it. Status advances to **virtualMachineRunning** on success.

Q: How do you monitor the progress of a VM import?
A: Run `kubectl get virtualmachineimport.migration`; the **STATUS** column shows the phase (e.g. `virtualMachineRunning`). Detailed conditions live on the object, and progress/errors appear in the **vm-import-controller** pod logs (missing VMware Tools shows as shutdown errors).

Q: What storage gotcha affects importing large VMs, and how do you fix it?
A: By default the controller **stages disks on node ephemeral storage** under `/var/lib/kubelet`, which can exhaust node capacity for big VMs. Enable **PVC-backed storage** for the controller; the recommended PVC is about **twice the largest VM disk**.

Q: How does the importer choose a disk bus, and why does that matter for booting?
A: `defaultDiskBusType` accepts `sata`, `scsi`, `usb`, or `virtio`; for VMware it is used **only when auto-detection fails**. **virtio** is fastest but requires virtio drivers in the guest — an unmodified guest on a virtio disk may fail to boot, so **sata/scsi** can be the safer bus until drivers are installed.

Q: How do you migrate a VM manually without the vm-import-controller?
A: Power off the VM, export/copy its VMDK, then convert it:
`qemu-img convert -f vmdk -O qcow2 disk.vmdk disk.qcow2` (or `-O raw`). Upload the result as a **VirtualMachineImage** (UI or `virtctl image-upload`) and create a VM from that image.

Q: When would you use the manual VMDK path instead of the built-in importer?
A: When you **cannot grant vCenter API credentials**, the source isn't a reachable VmwareSource/OpenstackSource (bare disk, foreign hypervisor), or you must **pre-modify the disk** (e.g. inject virtio drivers) before first boot. The importer is better for **repeatable, network-mapped, many-VM** migrations.

Q: What must you do to a Windows guest so it still boots after migration?
A: Inject the **VirtIO (`virtio-win`) drivers** for disk and NIC — otherwise Windows **blue-screens (`INACCESSIBLE_BOOT_DEVICE`)** on a virtio disk. Install the drivers while the guest is still on a SATA/SCSI bus (or attach the virtio-win ISO), then switch the bus to virtio.

Q: What guest-agent change should accompany a VMware-to-SUSE migration?
A: **Uninstall VMware Tools** and **install qemu-guest-agent** in the guest. That restores the functions Tools provided on vSphere: graceful shutdown, IP reporting in the UI, and **filesystem-consistent snapshots/backups**.

Q: Why must you match firmware settings when migrating a VM, and what breaks if you don't?
A: The target must match the source: a **UEFI** guest needs UEFI firmware (`efi`) or it won't boot; a **BIOS** guest needs BIOS. Windows UEFI guests using **Secure Boot / vTPM** need those enabled on the target too, otherwise boot or Windows activation fails.

Q: What must you do to a source VM's VMware snapshots before migrating its disk?
A: **Consolidate (delete) all snapshots first** so the base VMDK is flat and current. Copying a disk that still has unconsolidated delta/redo files migrates a **stale base image** and loses recent writes.

Q: How do you preserve a VM's MAC address and static IP across the migration?
A: Set the target NIC's **`macAddress`** to the original so DHCP reservations and MAC-bound licenses still match, and reproduce static IPs via **cloud-init network-data** or in-guest config. Expect to re-point the guest onto the new **bridge/VLAN** network.

Q: What should a phased vSphere-to-SUSE migration plan include?
A: An **inventory/assessment**; a **pilot** of non-critical VMs first; realistic **cold-downtime** budgets per VM (copy + convert time scales with disk size); **validation** that each VM boots, networks, and passes app tests before cutover; and keeping the source VM **powered off but not deleted** as a rollback until validated.
