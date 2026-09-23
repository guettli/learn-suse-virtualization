# Resource Management

Q: What is the difference between a share, a reservation, and a limit?
A: **Reservation** = guaranteed minimum resource; **Limit** = hard ceiling; **Shares** = relative priority used to divide resources **only under contention**. Reservations and limits are absolute (MHz for CPU, MB for memory); shares are proportional and matter only when hosts are oversubscribed.

**SUSE Virtualization:** Maps to pod-style **requests/limits** (guaranteed floor vs hard ceiling) plus the cluster **overcommit-config**; there is **no relative "shares" weighting**.

Q: How do CPU and memory reservations differ in what they guarantee?
A: A **CPU reservation** (MHz) guarantees scheduling time so the VM's vCPUs get at least that much compute. A **memory reservation** (MB) guarantees physical RAM that is **never reclaimed or swapped** — protected memory. Unreserved memory can be reclaimed by ballooning, compression, or swapping under pressure.

**SUSE Virtualization:** A KubeVirt VM's **requests** guarantee CPU/memory, and **dedicatedCpuPlacement** with Guaranteed QoS pins and protects them; there is no vSphere-style balloon reclaim of a reservation.

Q: What is a resource pool?
A: A **resource pool** is a container that carves out a slice of a host's or cluster's CPU and memory, with its own **shares, reservation, and limit**. Pools nest hierarchically to delegate capacity (e.g. Production vs Test) so groups of VMs share and compete for resources as a unit rather than individually.

**SUSE Virtualization:** **No direct equivalent** — the closest analog is a Kubernetes **namespace with a ResourceQuota** bounding aggregate CPU/memory for a group of VMs.

Q: What does "expandable reservation" mean on a resource pool?
A: With **expandable reservation** enabled, a child pool that has exhausted its own reserved capacity can **borrow unreserved reservation from its parent** to power on or admit more VMs. If disabled, the pool is capped at its own explicit reservation regardless of free parent capacity.

**SUSE Virtualization:** **No direct equivalent** — ResourceQuotas do not borrow from a parent, and there is no nested expandable-reservation model.

Q: What is memory overcommitment?
A: **Memory overcommitment** is allocating VMs more total configured RAM than the host physically has, relying on the fact that VMs rarely use all their RAM at once. ESXi backs it with reclamation techniques (TPS, ballooning, compression, swapping) and safely serves the real working set from physical RAM.

**SUSE Virtualization:** The **overcommit-config** setting does the same (defaults memory **150%**, CPU 1600%), scheduling more configured RAM/CPU than physically present.

Q: In what order does ESXi apply memory reclamation techniques under pressure?
A: As free memory drops through the host states (high → clear/soft → hard → low), ESXi escalates: **Transparent Page Sharing (TPS)** runs continuously, then **ballooning**, then **memory compression**, and finally **hypervisor swapping** as a last resort. Later techniques hurt performance more, so ESXi uses them only as pressure increases.

**SUSE Virtualization:** **No vSphere-style escalation ladder** — the Linux host relies on **KSM** page-merging and kernel memory management; there is no TPS→balloon→compress→swap sequence by those names.

Q: What is Transparent Page Sharing (TPS)?
A: **Transparent Page Sharing (TPS)** deduplicates identical memory pages so multiple VMs share one physical copy, reclaiming redundant RAM. By default inter-VM TPS is **disabled for security** (a side-channel concern); **intra-VM** (salted, same-VM) sharing still runs. Large pages also reduce its effectiveness until broken down under pressure.

**SUSE Virtualization:** **KSM (kernel same-page merging)** is the Linux equivalent, deduplicating identical memory pages across VMs on the host.

Q: What is memory ballooning and the vmmemctl driver?
A: **Ballooning** reclaims memory cooperatively: the **vmmemctl** balloon driver (part of VMware Tools) inflates inside the guest, pinning pages so the guest's own OS pages out its least-needed memory, which ESXi then reclaims. It needs VMware Tools installed and is gentler than hypervisor swapping because the guest chooses what to give up.

**SUSE Virtualization:** **No vmmemctl/VMware-Tools balloon** — the closest is the KubeVirt/KVM **virtio-balloon** device with free-page reporting, but no vSphere-style balloon-under-pressure driver by that name.

Q: What are memory compression and hypervisor swapping as reclamation techniques?
A: **Memory compression** stores would-be-swapped pages compressed in a per-VM cache in RAM — far faster than disk. **Hypervisor swapping** writes guest pages to the VM's `.vswp` swap file on disk; it is the **last-resort** technique and causes the worst performance because ESXi swaps blindly without knowing which pages the guest needs.

**SUSE Virtualization:** **No direct equivalent** — there is no per-VM compression cache or `.vswp` file; memory pressure is handled by the Linux host (KSM and, if enabled, host swap).

Q: What is CPU Ready time (%RDY) and what does it indicate?
A: **CPU Ready (%RDY)** is the percentage of time a VM's vCPU is **ready to run but waiting for a physical core** to be scheduled. High %RDY signals **CPU contention / overcommitment** — too many vCPUs competing for pCPUs — and manifests as sluggish VMs even when guest CPU usage looks low.

**SUSE Virtualization:** **No named %RDY metric** — CPU contention shows through standard node/VM CPU and scheduling metrics (Prometheus/Grafana), not a dedicated ready-time counter.

Q: What is co-stop (%CSTP) on a multi-vCPU VM?
A: **Co-stop (%CSTP)** is time a **multi-vCPU** VM is stopped because ESXi must **co-schedule its vCPUs** and could not run enough of them simultaneously. High %CSTP means the VM has more vCPUs than the host can schedule together — often a sign the VM is **oversized**; reducing vCPU count usually helps.

**SUSE Virtualization:** **No %CSTP equivalent** — KubeVirt/KVM does not strictly co-schedule a VM's vCPUs, so there is no co-stop metric.

Q: Which metrics reveal CPU and memory contention on ESXi?
A: For **CPU**: high **%RDY** (waiting for a core) and high **%CSTP** (vCPUs waiting to co-schedule). For **memory**: active **ballooning**, compression, and especially **swapping** indicate the host is reclaiming RAM under pressure. These are the primary red flags that a host is overcommitted.

**SUSE Virtualization:** Contention is read from **node/VM CPU and memory metrics** (Prometheus/Grafana) rather than %RDY/%CSTP or balloon/swap counters.

Q: What are NUMA and vNUMA?
A: **NUMA (Non-Uniform Memory Access)** means each CPU socket has local memory that is faster to reach than another socket's memory. ESXi's NUMA scheduler keeps a VM's vCPUs and RAM on one node when possible. **vNUMA** exposes the physical NUMA topology to the guest so a large VM's OS and apps can optimize their own placement.

**SUSE Virtualization:** KubeVirt **CPU pinning (dedicatedCpuPlacement)** with NUMA-aligned topology provides the equivalent NUMA-aware placement for performance VMs.

Q: How can CPU or memory hot-add affect vNUMA?
A: Enabling **CPU or memory hot-add** can **disable vNUMA**, forcing the guest to see a single flat NUMA node (UMA). A wide VM then loses NUMA-aware placement and may suffer remote-memory latency. For large NUMA-sensitive VMs, prefer sizing correctly over relying on hot-add.

**SUSE Virtualization:** **No direct equivalent** — NUMA-pinned (dedicatedCpuPlacement) VMs generally cannot hot-add vCPUs/memory, so the same "size correctly up front" guidance applies.

Q: What does the Latency Sensitivity = High setting do?
A: Setting a VM's **Latency Sensitivity to High** gives it near-exclusive access to resources: it effectively requires **full CPU and memory reservations**, grants **exclusive pCPU affinity** for its vCPUs, and reduces virtualization overhead/jitter. It is meant for latency-critical workloads (e.g. trading, real-time) at the cost of consolidation.

**SUSE Virtualization:** **dedicatedCpuPlacement** (full CPU reservation with exclusively pinned pCPUs) is the equivalent for latency-critical VMs.

Q: Under contention, how do a reservation and shares behave differently?
A: A **reservation** is honored first and absolutely — that capacity is guaranteed no matter how busy the host is. **Shares** only decide how the **remaining, contended** capacity is divided among VMs by relative weight. So reservations protect a floor; shares arbitrate the leftover.

**SUSE Virtualization:** KubeVirt **requests** protect a floor (Guaranteed QoS), but there is **no shares mechanism** to weight the contended remainder.
