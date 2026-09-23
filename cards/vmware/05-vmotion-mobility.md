# vMotion & Mobility

Q: What is vMotion and how does memory pre-copy work?
A: **vMotion** live-migrates a running VM's **compute state (CPU + memory)** from one ESXi host to another with **no downtime**. It iteratively **pre-copies** memory pages to the target while tracking pages that change (dirty pages), copies successively smaller dirty sets, then does a brief switchover to the target. Storage stays on the shared datastore.

**SUSE Virtualization:** **Live migration** (KubeVirt `VirtualMachineInstanceMigration`) moves a running VM's CPU and memory to another node via iterative memory pre-copy with no downtime.

Q: What is Storage vMotion (svMotion)?
A: **Storage vMotion** live-migrates a running VM's **disk files (VMDKs)** from one datastore to another with no downtime, while the VM keeps running on the same host. It is used to rebalance capacity, evacuate a datastore for maintenance, or change disk format (e.g., thick to thin).

**SUSE Virtualization:** No direct equivalent — there is no live storage migration, but **Longhorn** replicates each volume across nodes and can rebuild/rebalance replicas, so data isn't tied to one node.

Q: What are the requirements for a standard vMotion?
A: vMotion needs: a configured **vMotion VMkernel network** on both hosts, **CPU compatibility** between hosts (same vendor and compatible features, often enforced by **EVC**), and access to the VM's storage. Classic vMotion assumes **shared storage**, though Enhanced vMotion can move storage too.

**SUSE Virtualization:** **Live migration** similarly requires **replicated/RWX Longhorn volumes**, a compatible CPU (**host-model**), and a working cluster (migration) network.

Q: What is cross-vCenter vMotion?
A: **Cross-vCenter vMotion** migrates a running VM between hosts managed by **different vCenter Server instances** (even in different SSO domains), moving compute and optionally storage and networking in one operation. It enables workload mobility across datacenters or between separate vSphere environments.

**SUSE Virtualization:** No direct equivalent — **live migration** works only within a single Harvester cluster, not between separate clusters.

Q: What is long-distance vMotion?
A: **Long-distance vMotion** extends vMotion across sites separated by high round-trip latency (supported up to roughly **150 ms RTT**). It is typically paired with cross-vCenter vMotion for datacenter migrations, disaster avoidance, and follow-the-sun operations over WAN links.

**SUSE Virtualization:** No direct equivalent — there is no cross-site/long-distance live migration; migration is confined to one cluster's network.

Q: How does cold migration differ from vMotion?
A: **Cold migration** moves a **powered-off** (or suspended) VM to another host and/or datastore. Because the VM is not running there is no memory to pre-copy, CPU compatibility is relaxed, and it can cross more boundaries. **vMotion** by contrast moves a **live** VM with zero downtime.

**SUSE Virtualization:** The equivalent is a **cold move** — stop the VM and let it restart/reschedule on another node, with no memory pre-copy.

Q: What is Enhanced vMotion (XvMotion / unified vMotion)?
A: **Enhanced vMotion** (also called XvMotion or unified vMotion) migrates a running VM's **compute and storage together in a single operation without requiring shared storage** between the source and target hosts. This allows live migration between hosts that have only local or non-shared datastores.

**SUSE Virtualization:** No direct equivalent — live migration doesn't relocate disks, but distributed **Longhorn** volumes are reachable from every node, so no external shared storage is needed in the first place.

Q: What is the vMotion network and what is multi-NIC vMotion?
A: The **vMotion network** is a dedicated VMkernel port used to transfer memory/state during migration; isolating it protects performance and security. **Multi-NIC vMotion** binds vMotion to several physical NICs so a single migration (or several concurrent ones) can use the combined bandwidth for faster switchover.

**SUSE Virtualization:** Harvester can route live-migration traffic over a dedicated **Storage Network** (a separate Multus VLAN) to isolate it; there is no multi-NIC-per-migration bonding feature.

Q: What does it mean to quiesce or stun a VM during migration?
A: To **stun** (quiesce) a VM is to briefly pause its execution so a consistent point-in-time state can be captured. In vMotion the final switchover involves a very short stun to transfer the last dirty memory and CPU registers; it is milliseconds long, so the guest sees no meaningful interruption.

**SUSE Virtualization:** **Live migration** ends with the same brief final switchover pause to transfer the last dirty pages and CPU state; the guest sees only a millisecond-scale interruption.

Q: How do vMotion, Storage vMotion, and cold migration compare?
A: **vMotion** moves live compute between hosts (storage stays). **Storage vMotion** moves live disks between datastores (host stays). **Enhanced vMotion** moves both live. **Cold migration** moves a powered-off VM's compute and/or storage. Only cold migration involves downtime.

**SUSE Virtualization:** **Live migration** moves live compute between nodes; there is no live storage move, and a **cold move** (stop and reschedule) is the only option involving downtime.

Q: What is encrypted vMotion?
A: **Encrypted vMotion** encrypts the migration data stream between hosts so memory and state cannot be intercepted in transit. It can be set per VM to **Disabled**, **Opportunistic** (encrypt if both hosts support it), or **Required**. Encrypted VMs always use it.

**SUSE Virtualization:** No direct equivalent — there is no separately named "encrypted live migration" toggle; migration traffic rides the cluster/storage network and is secured at that network layer.
