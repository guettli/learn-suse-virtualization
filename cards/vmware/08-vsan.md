# vSAN

Q: What is VMware vSAN?
A: **vSAN** is VMware's **hyperconverged (HCI), software-defined storage** built into the ESXi hypervisor. It aggregates the **local disks of the hosts in a cluster** into a single shared **vSAN datastore**, removing the need for external SAN/NAS.

Q: What is a vSAN disk group in the Original Storage Architecture (OSA)?
A: In **OSA**, a **disk group** is the unit of storage on a host: exactly **one cache-tier device** plus **one to seven capacity-tier devices**. A host can have multiple disk groups; losing the cache device takes the whole disk group offline.

Q: What is the difference between the cache tier and the capacity tier in vSAN OSA?
A: The **cache tier** is a fast flash device used for read cache and/or write buffering; the **capacity tier** provides the persistent bulk storage. In OSA every disk group pairs one cache device with several capacity devices.

Q: What is the vSAN 8 Express Storage Architecture (ESA)?
A: **ESA** is the vSAN 8 architecture optimized for **high-performance NVMe TLC flash**. It replaces disk groups with a single **storage pool** where **every device contributes to both capacity and performance** — no separate cache tier and no cache-device single point of failure.

Q: How does an ESA storage pool differ from an OSA disk group?
A: An OSA **disk group** is tiered (one cache + several capacity devices, cache failure kills the group). An ESA **storage pool** is single-tier: all NVMe devices are independent and dedicated to storage, so a single device failure only affects data on that device.

Q: What is the difference between all-flash and hybrid vSAN?
A: **Hybrid** vSAN uses flash for the cache tier and **spinning disks (HDD)** for capacity. **All-flash** uses flash for both tiers, enabling features like RAID-5/6 erasure coding, dedup and compression. ESA is all-NVMe-flash only.

Q: What is Storage Policy-Based Management (SPBM) in vSAN?
A: **SPBM** lets you define storage requirements as a **VM storage policy** (availability, performance, space efficiency) and apply it **per-VM or per-VMDK**. vSAN provisions and continuously enforces object placement to meet the policy.

Q: What do FTT and FTM control in a vSAN storage policy?
A: **FTT (Failures To Tolerate)** sets how many host/device failures an object survives. **FTM (Failure Tolerance Method)** sets *how* that redundancy is achieved — **RAID-1 mirroring** or **RAID-5/6 erasure coding**.

Q: How do RAID-1 mirroring and RAID-5/6 erasure coding differ in vSAN?
A: **RAID-1** keeps full mirror copies — fastest but highest capacity overhead. **RAID-5/6 erasure coding** stores data plus parity across nodes for the same FTT with **much less capacity overhead**, at some write cost. RAID-5 needs enough nodes (as few as 3 in ESA); RAID-6 tolerates two failures.

Q: What are objects and components in vSAN?
A: A vSAN **object** is a logical storage unit (e.g. a VMDK, VM namespace, or snapshot). Each object is split into **components** distributed across hosts/disks per the storage policy — mirrors, erasure-coding fragments, and witnesses are all components.

Q: What is a witness component and how does it relate to quorum?
A: A **witness** is a metadata-only component (no data) used as a tiebreaker. vSAN requires more than 50% of an object's **votes/components to remain available (quorum)**; witnesses ensure an object stays accessible and avoids split-brain after a failure.

Q: What is a vSAN stretched cluster and its witness host?
A: A **stretched cluster** spans two geographically separate **sites (fault domains)** with synchronous mirroring between them, plus a third **witness host/appliance** at a separate location that holds witness components to maintain quorum if a site or the inter-site link fails.

Q: What are fault domains in vSAN?
A: **Fault domains** group hosts (e.g. by rack or site) so vSAN places redundant components in **different domains**. This lets the cluster tolerate a whole rack or site failure, not just a single host or disk.

Q: What do deduplication and compression provide in vSAN?
A: **Dedup and compression** are space-efficiency features (all-flash) that remove duplicate blocks and compress data to reduce consumed capacity. In OSA they are enabled cluster-wide per disk group; ESA applies **compression per-object** and more granularly.

Q: What is the vSAN network used for?
A: The **vSAN network** is a dedicated **VMkernel-tagged network** carrying vSAN traffic (reads, writes, resync, metadata) between hosts. It typically uses 10/25 GbE or faster with jumbo frames recommended, and is critical to cluster performance and quorum.
