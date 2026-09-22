# CRDs & Internals (KubeVirt)

Q: What is the difference between a `VirtualMachine` and a `VirtualMachineInstance`?
A: **`VirtualMachine` (VM)** is the *desired-state / stateful* object — it holds the definition and a run strategy, behaving roughly like a StatefulSet with one replica. **`VirtualMachineInstance` (VMI)** is the *running, ephemeral* instance. Setting the VM to running causes KubeVirt to create the VMI; stopping it deletes the VMI while the VM definition persists.

Q: What is the virt-launcher pod and what runs inside it?
A: For each running VMI, KubeVirt schedules a **`virt-launcher` pod** on a node. Inside that pod run **`libvirtd` and QEMU**, which boot and manage the actual guest via **KVM** acceleration. The pod is the cgroup/namespace boundary that lets Kubernetes treat the VM like any other workload for scheduling, networking, and storage.

Q: What are the roles of virt-controller, virt-handler, and virt-api?
A:
- **`virt-api`** — the API server extension validating and serving KubeVirt CRDs and subresources (console, VNC, start/stop).
- **`virt-controller`** — cluster-wide controller that, for each VMI, creates the virt-launcher pod and reconciles VMI state.
- **`virt-handler`** — a node **DaemonSet** (like a kubelet peer) that drives libvirt inside each virt-launcher to reach the desired VMI state.

Q: What does `kubectl get vmi` tell you that `kubectl get vm` does not?
A: `get vm` shows the **desired** object and whether it should be running; **`get vmi`** shows the **actually running** instance — its **phase** (Scheduling/Scheduled/Running), the **node** it landed on, and its IP. No VMI row means nothing is running, regardless of the VM's config.

Q: What is the relationship between a VMI and its pod?
A: It is **1:1** — one running VMI is backed by exactly one **virt-launcher pod**. The pod is owned by the VMI; if the pod dies the VMI is lost, and on restart the VMI is rescheduled onto a **new** virt-launcher pod (a fresh pod name each time). Deleting the pod terminates the guest.

Q: How is a VM's disk backed by storage in SUSE Virtualization?
A: A VM disk is a **PVC** provisioned by the **Longhorn/SUSE Storage CSI driver**; the PVC is attached into the virt-launcher pod and presented to QEMU as a block device. Longhorn replicates that volume across nodes, which is what makes VM live migration and volume-level backup/snapshot possible.

Q: What role does the CDI (Containerized Data Importer) play?
A: **CDI** imports/uploads disk images into PVCs (`DataVolume`-style population). In Harvester a `VirtualMachineImage` uses the **Longhorn backing-image** backend by default, but can instead use the **CDI backend** — required to place images on third-party storage or **Longhorn V2** volumes via a chosen StorageClass.

Q: What does the `VirtualMachineImage` CRD represent?
A: **`VirtualMachineImage`** (`harvesterhci.io/v1beta1`) is Harvester's abstraction over a bootable OS image (uploaded or URL-sourced). By default it is stored as a **Longhorn backing image**; creating a VM/volume from it clones a **new independent PVC** per VM, inheriting parameters (e.g. replica count) from the selected StorageClass.

Q: Which Harvester CRDs implement VM backup and restore, and what backs them?
A: **`VirtualMachineBackup`** and **`VirtualMachineRestore`** (`harvesterhci.io/v1beta1`). Backups are written to an external **backup target** (S3-compatible or NFS, set via the `backup-target` setting) and are cross-cluster restorable; **snapshots** stay in-cluster. Both are **limited to Longhorn volumes** and build on Longhorn's snapshot/backup mechanism.

Q: How does node labeling influence where VMs (VMIs) get scheduled?
A: KubeVirt labels nodes for capability and eligibility — e.g. **`kubevirt.io/schedulable`** and CPU-model/feature labels (`cpu-model.node.kubevirt.io/...`) published by node-labeller. The VMI's `nodeSelector`/affinity is matched against these so a guest only lands on a host with a compatible CPU and virtualization support.

Q: How does KubeVirt give the guest hardware-accelerated virtualization on a node?
A: The virt-launcher pod requests the host's **`/dev/kvm`** through KubeVirt's **KVM device plugin** (resource **`devices.kubevirt.io/kvm`**). QEMU inside the pod then uses **KVM** for hardware acceleration. If `/dev/kvm` is unavailable the guest can only fall back to slow software emulation.

Q: How is VM firmware chosen — BIOS versus UEFI — and what is the machine type?
A: Firmware is set via `spec.domain.firmware.bootloader`: **BIOS by default**, or **UEFI backed by OVMF** when `efi` is specified. Enabling `efi` turns on **Secure Boot** unless `secureBoot: false` (Secure Boot also needs SMM and the **q35** machine type). The **`spec.domain.machine.type`** field (e.g. a `pc-q35-*` type) pins the emulated chipset.

Q: Why do VMs appear as pods to the Kubernetes scheduler?
A: Because KubeVirt wraps each VMI in a **virt-launcher pod**, the scheduler only ever sees a normal pod with CPU/memory requests. This is KubeVirt's design ("the Razor"): reuse the existing pod machinery so **scheduling, networking (Multus), storage (CSI), and quotas** apply to VMs exactly as they do to containers, with QEMU/KVM hidden inside the pod.

Q: What does the `blockdevices.harvesterhci.io` CRD represent, and which component manages it?
A: Each **`BlockDevice`** (`harvesterhci.io/v1beta1`) mirrors one physical disk on a node — filesystem state, mount point, UUID/WWN — and is created and reconciled by **node-disk-manager (NDM)**: a scanner discovers disks, a controller updates the CRs. Its key field **`spec.provisioner`** decides whether the disk is provisioned for **Longhorn V1, Longhorn V2, or LVM**; every disk needs a unique **WWN** or NDM refuses to add it.

Q: What is the `KeyPair` CRD and how do its keys reach a VM?
A: **`KeyPair`** (`harvesterhci.io/v1beta1`) stores a named **public SSH key** (in `spec.publicKey`) in the cluster so it can be reused across VMs. Selecting it at VM creation performs **static injection** — the key is placed in the guest's **cloud-init** at first boot. Harvester can also **dynamically** push keys into a running guest via the **qemu-guest-agent** propagation method.

Q: How are cluster-wide options like `backup-target` or `overcommit-config` stored under the hood?
A: As **`Setting`** objects (`settings.harvesterhci.io`, `harvesterhci.io/v1beta1`) — a flat, **cluster-scoped** CRD where each named object (e.g. `backup-target`, `vip-pools`, `overcommit-config`, `support-bundle-timeout`) carries a `value`. `kubectl get settings.harvesterhci.io` lists them and `kubectl edit` changes one without the UI; this is the same store the Settings page writes to.

Q: Which Harvester CRDs drive a cluster upgrade, and what does each hold?
A: A **`Version`** (`harvesterhci.io/v1beta1`, namespace `harvester-system`) describes an available release — **`isoURL`**, **`isoChecksum`**, `releaseDate`. Creating an **`Upgrade`** object then starts the process, and its **`status`** tracks per-node/component progress. Both live in `harvester-system` (`kubectl get version,upgrade -n harvester-system`); the actual node work runs through **System Upgrade Controller** plans.
