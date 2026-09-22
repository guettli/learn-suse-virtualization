# Live Migration, HA & Scheduling

Q: How does live migration move a running VM between hosts?
A: A **`VirtualMachineInstanceMigration`** object is created; the source keeps running while its **memory pages (and, for local storage, disk state) are copied to the destination**. Once state converges, execution is switched over with only a brief pause, so the guest experiences **no reboot and effectively no downtime**.

Q: When is a VM eligible for live migration?
A: When it has **no non-migratable properties**, its storage is accessible from another host, and there is at least one **other schedulable node** with a **CPU-compatible** processor and enough free resources for the VM's full request. Harvester triggers it via the VM menu's **Migrate** action or automatically during maintenance.

Q: What storage requirement must a VM meet to be migratable?
A: Its volumes must be reachable from the target host — either **`ReadWriteMany` (RWX)** access mode or a **replica count greater than one** so a replica already lives on other nodes. Longhorn/SUSE Storage replicates volumes across nodes, which is what makes shared-nothing hosts support live migration.

Q: Why does CPU compatibility matter for live migration?
A: The guest keeps running the **same CPU feature set** after the move, so the destination CPU must expose at least those features. With the default **`host-model`** CPU, migration is restricted to nodes with a **matching/compatible CPU model**; mismatched microarchitectures can block migration.

Q: Which VM characteristics make a VM non-migratable?
A: A VM cannot live-migrate if it uses **host-device/PCI passthrough or vGPU**, has a **CD-ROM or container-disk** volume, is bound by a **node selector** to specific hardware, or has **strict anti-affinity** it cannot satisfy elsewhere. Such VMs must be stopped to move them.

Q: What does putting a node into Maintenance Mode do?
A: It **cordons** the node and **live-migrates all migratable VMs off it** in batches, letting you safely do firmware updates, reboots, or hardware work. It needs **at least one other active node** to receive the VMs; non-migratable VMs must be shut down first.

Q: What provides VM high availability when a node fails unexpectedly?
A: VMs with **`runStrategy: Always`** are automatically **restarted on healthy nodes** after Harvester detects the node is down. Because Longhorn keeps **replicas on other nodes**, the volumes reattach elsewhere, so the guest reboots (cold, not live) on surviving capacity without operator action.

Q: What actually happens to a VM the moment its host node dies?
A: The VMI's pod becomes unreachable and cannot be live-migrated (its memory is gone). Once Harvester confirms the node is truly down, it **force-deletes the stale VMI pod** so the controller can **reschedule and cold-start** the VM elsewhere. The guest loses in-memory state and boots fresh from its replicated disks.

Q: How does the Kubernetes scheduler place VMs given Harvester's overcommit?
A: A VM's pod requests are **divided down by the overcommit ratios** before scheduling. For example, at the default **1600% CPU** overcommit a VM asking for 2 vCPUs only reserves ~**125 mCPU** from the scheduler, so many VMs pack onto a node; the scheduler then places pods by these reduced requests plus any affinity rules.

Q: How do node affinity and anti-affinity control VM placement?
A: You attach **`nodeSelector`/`affinity`** rules (matching node labels) to steer a VM **toward** specific nodes, and **anti-affinity** to keep VMs **apart** — e.g. spreading replicas of an app across hosts. Note that **hard node selectors and strict anti-affinity make a VM non-migratable**, trading placement control for mobility.

Q: What are the default CPU, memory, and storage overcommit ratios?
A: Set in the **`overcommit-config`** setting, the defaults are **CPU 1600%, Memory 150%, Storage 200%**. Values above 100% let Harvester schedule VMs whose nominal totals exceed physical capacity, on the assumption they won't all peak at once — raising density at the cost of contention risk if oversubscribed.

Q: How do you give a VM dedicated, pinned physical CPUs?
A: Enable the **CPU Manager (static policy)** on the node, then enable **CPU pinning** on the VM, which sets **`dedicatedCpuPlacement: true`** and creates a 1:1 vCPU-to-physical-CPU mapping in libvirt. This gives latency-sensitive guests stable cores. A pinned VM can only migrate to a target node that **also has the CPU Manager enabled**.

Q: What timeouts can cause a live migration to fail, and how are they tuned?
A: Two, both set in the **`kubevirt-migration`** setting:
- **`completionTimeoutPerGiB`** — fails the migration if it runs longer than about 150 s per GiB of VM memory (an 8 GiB VM is roughly 1200 s).
- **`progressTimeout`** — aborts if memory copy makes **no progress for ~150 s**.
When memory dirties faster than it copies, enable **`allowAutoConverge`** to throttle the guest CPU so the migration can converge.

Q: How do you cancel an in-progress live migration, and when should you not?
A: Use **⋮ > Abort Migration** on the migrating VM; it is only available while a migration is active and rolls the VM back to its source node. **Do not** abort migrations that Harvester triggers **automatically in batches** during node maintenance or a cluster **upgrade** — cancelling those can disrupt the orchestrated drain.

Q: When you migrate a VM manually, do you choose the destination node?
A: Yes — the **Migrate** action lets you **pick a target node** (or leave it to the scheduler) and Apply. The option is unavailable on single-node clusters, for non-migratable VMs, or while a migration is already running. During **maintenance or upgrade**, targets are chosen **automatically** as VMs are evacuated node by node.

Q: How do you relocate a VM that cannot be live-migrated?
A: **Cold-migrate** it: **stop** the VM (its cluster-wide Longhorn volumes detach), then **start** it again so the scheduler places the fresh `VirtualMachineInstance` on another eligible node. This moves VMs with PCI/vGPU passthrough, single-replica or CD-ROM volumes, or strict node selectors — at the cost of **downtime** that live migration would avoid.
