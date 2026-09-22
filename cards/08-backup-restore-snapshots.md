# Backup, Restore & Snapshots

Q: What is the core difference between a VM snapshot and a VM backup in SUSE Virtualization?
A: A **VM snapshot** is stored **locally in-cluster** on Longhorn/SUSE Storage, so it is fast to take and restore but is lost if the cluster is lost. A **VM backup** is copied to an **external backup target** (S3 or NFS), making it slower but **durable** and usable for disaster recovery and cross-cluster restore.

Q: When would you choose a snapshot over a backup, and vice versa?
A: Use a **snapshot** for quick, local rollback points (e.g., before an in-guest change) — cheap and fast but tied to cluster availability. Use a **backup** when you need **durability off the cluster**: protection against cluster loss, retention on external storage, or restoring the VM into a **different cluster**.

Q: What is a volume snapshot and how does it differ from a VM snapshot?
A: A **volume snapshot** captures the state of a **single volume** rather than the whole VM. It is taken from the Volumes page (**Take Snapshot**) and can be **restored to create a new volume** (effectively cloning) or revert the volume. A **VM snapshot** covers all of a VM's volumes plus VM configuration as one consistent unit.

Q: What must you configure before you can take VM backups, and where?
A: You must configure a **backup target** under **Settings > backup-target**. Until a valid target is set, backups cannot be created. The same target definition is what a second cluster uses to see and restore those backups.

Q: What backup target types does SUSE Virtualization support and what does each need?
A: Two types:
- **S3** — requires **Endpoint**, **BucketName**, **BucketRegion**, **AccessKeyID**, **SecretAccessKey** (plus optional Certificate / VirtualHostedStyle).
- **NFS** — requires only the **Endpoint** (the NFS server URL/export).
Both accept a **Refresh Interval** controlling how often Harvester syncs backup metadata from the store.

Q: What does a VM backup actually contain?
A: It contains the VM's **volume data** (from Longhorn/SUSE Storage) plus the **VM definition/metadata** needed to reconstruct it. This lets a backup be restored as a complete, bootable VM rather than just raw disk contents.

Q: What are the two ways to restore a VM backup?
A: From **Backup & Snapshot > VM Backups > Restore Backup** you can either:
- **Restore into a new VM** — provide a new VM name; the original VM is untouched.
- **Replace an existing VM** (**Replace Existing**) — overwrites the target VM in place.

Q: What are the constraints when restoring a backup by replacing an existing VM?
A: The target VM must be **powered off** first. During the restore you choose whether to **delete or retain the previous volumes** (deletion is the default). The VM keeps its identity but its disks are rolled back to the backup's contents.

Q: How do you restore a VM backup into a completely different cluster (disaster recovery)?
A: Configure the **identical backup target** on the second cluster. Harvester **syncs the backup metadata** from the store automatically, after which the synced backup appears in **VM Backups** and can be restored under a chosen VM name. The backup target is the shared link — without the same target the backups are invisible.

Q: Why must the destination cluster use the same backup target for cross-cluster restore?
A: The backup data lives only in the **external target**, not in the source cluster. The destination cluster discovers and reads backups **by pointing at that same S3 bucket/NFS export**; a different target has no knowledge of those backups. (From v1.4.0+, referenced VM images are also synced automatically to the new cluster.)

Q: How does SUSE Virtualization ensure a snapshot or backup is filesystem-consistent?
A: When the **QEMU Guest Agent** is installed and connected, the controller triggers a **filesystem freeze (quiesce)** via KubeVirt's **virt-freezer** before capturing, then thaws afterward. Linux uses **`fsfreeze`**; Windows uses **VSS (Volume Shadow Copy Service)**. Without the guest agent the capture is only crash-consistent.

Q: How do you schedule recurring backups or snapshots and control retention?
A: SUSE Virtualization supports **scheduled** VM backups and snapshots (a VM schedule). Key fields:
- **Cron Schedule** — a cron expression (minimum interval **one hour**).
- **Retain** — number of most-recent backups/snapshots to keep; older ones are pruned automatically.
- **Max Failure** — consecutive failures allowed before the schedule is suspended.
