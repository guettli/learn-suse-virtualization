# Resource Management

Q: What is the difference between a share, a reservation, and a limit?
A: **Reservation** = guaranteed minimum resource; **Limit** = hard ceiling; **Shares** = relative priority used to divide resources **only under contention**. Reservations and limits are absolute (MHz for CPU, MB for memory); shares are proportional and matter only when hosts are oversubscribed.

Q: How do CPU and memory reservations differ in what they guarantee?
A: A **CPU reservation** (MHz) guarantees scheduling time so the VM's vCPUs get at least that much compute. A **memory reservation** (MB) guarantees physical RAM that is **never reclaimed or swapped** — protected memory. Unreserved memory can be reclaimed by ballooning, compression, or swapping under pressure.

Q: What is a resource pool?
A: A **resource pool** is a container that carves out a slice of a host's or cluster's CPU and memory, with its own **shares, reservation, and limit**. Pools nest hierarchically to delegate capacity (e.g. Production vs Test) so groups of VMs share and compete for resources as a unit rather than individually.

Q: What does "expandable reservation" mean on a resource pool?
A: With **expandable reservation** enabled, a child pool that has exhausted its own reserved capacity can **borrow unreserved reservation from its parent** to power on or admit more VMs. If disabled, the pool is capped at its own explicit reservation regardless of free parent capacity.

Q: What is memory overcommitment?
A: **Memory overcommitment** is allocating VMs more total configured RAM than the host physically has, relying on the fact that VMs rarely use all their RAM at once. ESXi backs it with reclamation techniques (TPS, ballooning, compression, swapping) and safely serves the real working set from physical RAM.

Q: In what order does ESXi apply memory reclamation techniques under pressure?
A: As free memory drops through the host states (high → clear/soft → hard → low), ESXi escalates: **Transparent Page Sharing (TPS)** runs continuously, then **ballooning**, then **memory compression**, and finally **hypervisor swapping** as a last resort. Later techniques hurt performance more, so ESXi uses them only as pressure increases.

Q: What is Transparent Page Sharing (TPS)?
A: **Transparent Page Sharing (TPS)** deduplicates identical memory pages so multiple VMs share one physical copy, reclaiming redundant RAM. By default inter-VM TPS is **disabled for security** (a side-channel concern); **intra-VM** (salted, same-VM) sharing still runs. Large pages also reduce its effectiveness until broken down under pressure.

Q: What is memory ballooning and the vmmemctl driver?
A: **Ballooning** reclaims memory cooperatively: the **vmmemctl** balloon driver (part of VMware Tools) inflates inside the guest, pinning pages so the guest's own OS pages out its least-needed memory, which ESXi then reclaims. It needs VMware Tools installed and is gentler than hypervisor swapping because the guest chooses what to give up.

Q: What are memory compression and hypervisor swapping as reclamation techniques?
A: **Memory compression** stores would-be-swapped pages compressed in a per-VM cache in RAM — far faster than disk. **Hypervisor swapping** writes guest pages to the VM's `.vswp` swap file on disk; it is the **last-resort** technique and causes the worst performance because ESXi swaps blindly without knowing which pages the guest needs.

Q: What is CPU Ready time (%RDY) and what does it indicate?
A: **CPU Ready (%RDY)** is the percentage of time a VM's vCPU is **ready to run but waiting for a physical core** to be scheduled. High %RDY signals **CPU contention / overcommitment** — too many vCPUs competing for pCPUs — and manifests as sluggish VMs even when guest CPU usage looks low.

Q: What is co-stop (%CSTP) on a multi-vCPU VM?
A: **Co-stop (%CSTP)** is time a **multi-vCPU** VM is stopped because ESXi must **co-schedule its vCPUs** and could not run enough of them simultaneously. High %CSTP means the VM has more vCPUs than the host can schedule together — often a sign the VM is **oversized**; reducing vCPU count usually helps.

Q: Which metrics reveal CPU and memory contention on ESXi?
A: For **CPU**: high **%RDY** (waiting for a core) and high **%CSTP** (vCPUs waiting to co-schedule). For **memory**: active **ballooning**, compression, and especially **swapping** indicate the host is reclaiming RAM under pressure. These are the primary red flags that a host is overcommitted.

Q: What are NUMA and vNUMA?
A: **NUMA (Non-Uniform Memory Access)** means each CPU socket has local memory that is faster to reach than another socket's memory. ESXi's NUMA scheduler keeps a VM's vCPUs and RAM on one node when possible. **vNUMA** exposes the physical NUMA topology to the guest so a large VM's OS and apps can optimize their own placement.

Q: How can CPU or memory hot-add affect vNUMA?
A: Enabling **CPU or memory hot-add** can **disable vNUMA**, forcing the guest to see a single flat NUMA node (UMA). A wide VM then loses NUMA-aware placement and may suffer remote-memory latency. For large NUMA-sensitive VMs, prefer sizing correctly over relying on hot-add.

Q: What does the Latency Sensitivity = High setting do?
A: Setting a VM's **Latency Sensitivity to High** gives it near-exclusive access to resources: it effectively requires **full CPU and memory reservations**, grants **exclusive pCPU affinity** for its vCPUs, and reduces virtualization overhead/jitter. It is meant for latency-critical workloads (e.g. trading, real-time) at the cost of consolidation.

Q: Under contention, how do a reservation and shares behave differently?
A: A **reservation** is honored first and absolutely — that capacity is guaranteed no matter how busy the host is. **Shares** only decide how the **remaining, contended** capacity is divided among VMs by relative weight. So reservations protect a floor; shares arbitrate the leftover.
