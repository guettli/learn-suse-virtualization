# Snapshots, Clones & Templates

Q: What is a VM snapshot in vSphere?
A: A **snapshot** captures a VM's **point-in-time state** — its disks, settings, and optionally memory. After it is taken, the base VMDK is frozen read-only and new writes go to a **delta (child) disk**, so you can revert to that exact state later.

**SUSE Virtualization:** A **VM snapshot** backed by a **Longhorn volume snapshot** captures point-in-time state locally, with the same revert capability.

Q: What is the delta (child) disk created by a snapshot?
A: When you snapshot, the base disk becomes read-only and changes are redirected to a **delta / child disk** (a redo log). It uses the **vmfsSparse** (redo-log) format (`-delta.vmdk`) on VMFS5, or the newer **SEsparse** (`-sesparse.vmdk`) format — the **default for all snapshots on VMFS6** (and used on VMFS5 for disks larger than 2 TB) — which adds space reclamation.

**SUSE Virtualization:** **Longhorn** stores changes as copy-on-write **snapshots** in its volume-replica chain (with **backing images** for base data) — there are no `-delta.vmdk` files.

Q: What is a memory snapshot and quiescing?
A: A **memory snapshot** also saves the VM's **RAM/running state**, so reverting returns to a live, powered-on point. **Quiescing** instead flushes and pauses the guest file system (via **VMware Tools / Windows VSS**) to capture an **application-consistent, on-disk** state without saving memory.

**SUSE Virtualization:** Harvester VM snapshots can be **quiesced via the qemu-guest-agent** (fsfreeze) for application consistency, analogous to VMware Tools/VSS quiescing.

Q: What is a snapshot chain (tree) and why do long chains hurt performance?
A: Each snapshot adds another **delta disk**, forming a **chain/tree** where reads must traverse every link. Long chains grow disk usage, slow I/O, and lengthen consolidation/deletion. Snapshots are meant to be **short-lived**, not left running for days.

**SUSE Virtualization:** **Longhorn** likewise builds a copy-on-write **snapshot chain**, so long chains grow space usage and slow I/O; snapshots are meant to stay short-lived.

Q: What does consolidating snapshots do?
A: **Consolidate** commits and removes **orphaned delta disks** left behind when a snapshot deletion didn't fully merge (vCenter shows a "Configuration Issue"). It collapses the redo logs back into the base disk to reclaim space and restore performance.

**SUSE Virtualization:** **No manual consolidate step** — **Longhorn** manages and coalesces its snapshot chain automatically.

Q: What is the difference between a full clone and a linked clone?
A: A **full clone** is an **independent copy** with its own complete disks — no ongoing dependency on the source. A **linked clone** shares the parent's base disk via a **snapshot delta**, so it is fast and space-efficient but **depends on the parent** and performs less well.

**SUSE Virtualization:** A **VM/volume clone** is the full-copy equivalent; **backing-image thin clones** give fast, space-efficient provisioning closest to a linked clone.

Q: What is a VM template in vSphere?
A: A **template** is a **master, non-runnable image** of a VM used to deploy identical new VMs. Converting a VM to a template changes its extension to **`.vmtx`** and marks it non-powerable; you can convert it back to a VM to patch it.

**SUSE Virtualization:** A **VM template** in Harvester serves the same master-image role for deploying identical new VMs.

Q: What is guest customization and a customization specification?
A: **Guest customization** personalizes a VM deployed from a template — hostname, IP/network, SID, domain join, license. A **customization specification** is a saved, reusable profile of those settings (managed in the Customization Specification Manager) applied during deploy/clone.

**SUSE Virtualization:** Personalization is done via **cloud-init / Sysprep** in the VM template or per-VM config, rather than a saved customization-specification profile.

Q: What are OVF and OVA formats?
A: **OVF (Open Virtualization Format)** is an open standard packaging a VM as several files — a descriptor (`.ovf`), disks (`.vmdk`), manifest. **OVA** is the same package bundled into a **single tar archive (`.ova`)**. Both are used to **export and deploy** portable VMs/appliances.

**SUSE Virtualization:** OVA/OVF are imported through the **vm-import-controller** (`OvaSource`), or a disk image is registered as a **VirtualMachineImage**.

Q: What is a Content Library in vSphere?
A: A **Content Library** is a container for VM templates, OVF/OVA, ISOs and other files, managed in vCenter. A **local** library can be **published**, and other vCenters create a **subscribed** library that syncs the content — giving consistent templates across sites.

**SUSE Virtualization:** The cluster's **VM Images** (`VirtualMachineImage` objects) act as the image catalog; there is **no exact published/subscribed** cross-cluster library.

Q: What advantage do VM templates in a Content Library offer over OVF templates?
A: Storing native **VM templates (VMTX)** in a Content Library lets you **check out** a template, patch it as a live VM, and **check it back in** with versioning — keeping images current in place, which the older OVF-in-library method could not do.

**SUSE Virtualization:** **No direct equivalent** — Harvester has no check-out/check-in versioned template workflow; VM templates and VM Images are updated in place.

Q: What is an instant clone and how does it differ from a linked clone?
A: An **instant clone** creates a running child VM that shares the parent's **disks and memory** at a live checkpoint, so the new VM is **powered on almost instantly** (parent stunned <1s). Unlike a **linked clone**, which is created powered-off from a snapshot, instant clones share running memory for just-in-time provisioning (e.g. Horizon).

**SUSE Virtualization:** **No direct equivalent** — there is no shared-running-memory instant clone; **backing-image thin clones** give fast disk-level provisioning but not live memory sharing.

Q: Why are VM snapshots not backups?
A: Snapshots **depend on the original base VMDK** and live on the same datastore — if that VMDK or datastore is lost, the snapshot is useless. They also degrade performance over time and have no separate copy or retention. A **backup** is an independent, off-host copy; snapshots are only short-term rollback points.

**SUSE Virtualization:** Same distinction — local **Longhorn snapshots** are rollback points, whereas **Longhorn/Harvester backups** to external S3/NFS targets are the independent off-host copies.
