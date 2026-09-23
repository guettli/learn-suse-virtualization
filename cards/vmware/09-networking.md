# Networking (vSS & vDS)

Q: What is a vSphere Standard Switch (vSS)?
A: A **vSphere Standard Switch (vSS / vSwitch)** is a virtual switch **configured per ESXi host**. Each host has its own copy, so port groups and policies must be created identically on every host — there is no central management.

**SUSE Virtualization:** No exact per-host switch; VM networking uses a **ClusterNetwork** plus per-node NIC config wired through **Multus**, managed centrally rather than replicated per host.

Q: What is a vSphere Distributed Switch (vDS)?
A: A **vDS (DVS)** is a virtual switch **created and managed centrally in vCenter** that spans multiple ESXi hosts, giving consistent port groups and policies cluster-wide — unlike the per-host **vSS**.

**SUSE Virtualization:** A **ClusterNetwork** is the cluster-wide, centrally managed network configuration, making it the closest analog to a vDS.

Q: What is the difference between a port group and a distributed port group?
A: A **port group** is a template of network settings (VLAN, security, teaming) applied to ports on a **standard switch (per host)**. A **distributed port group** does the same on a **vDS**, so the settings are defined once and applied across all member hosts.

**SUSE Virtualization:** A **VM Network** (a Multus `NetworkAttachmentDefinition`, usually a VLAN) is the equivalent per-network template attached to VM NICs.

Q: What is an uplink on a virtual switch?
A: An **uplink** is a **physical NIC (vmnic)** of the host bound to the virtual switch, connecting VM/VMkernel traffic to the physical network. On a vDS, physical NICs map to logical **uplink ports** in an uplink port group.

**SUSE Virtualization:** The cluster network's **uplink** binds one or more host NICs (typically **bonded**, e.g. active-backup) to carry VM traffic onto the physical network.

Q: What is the difference between a VMkernel adapter and a VM port group?
A: A **VMkernel adapter (vmk)** is a host's own IP interface for infrastructure services (management, vMotion, vSAN, NFS/iSCSI). A **VM port group** connects **virtual machine vNICs** to the network. VMkernel traffic is the host's; VM port groups carry guest traffic.

**SUSE Virtualization:** There is **no VMkernel adapter** — node/management traffic uses the **management network** (storage optionally on a dedicated **storage network**), while guest traffic rides **VM Networks**.

Q: What are VST, EST and VGT VLAN tagging modes?
A: **VST (Virtual Switch Tagging)** — the vSwitch tags with the port group's VLAN ID (most common). **EST (External Switch Tagging)** — VLAN 0, the physical switch tags. **VGT (Virtual Guest Tagging)** — VLAN 4095, the guest OS handles 802.1Q tags itself.

**SUSE Virtualization:** Tagging is done by **VLAN networks** on a ClusterNetwork (like VST); the **untagged network** is closest to EST, with **no direct VGT equivalent**.

Q: What is NIC teaming on a virtual switch?
A: **NIC teaming** binds multiple physical uplinks to one switch/port group for **redundancy and increased throughput**, distributing traffic per a load-balancing policy and failing over to remaining uplinks if one goes down.

**SUSE Virtualization:** The cluster network **uplink** bonds multiple host NICs (bond modes such as active-backup or 802.3ad) for the same redundancy and throughput.

Q: What load-balancing policies can a vSphere virtual switch use?
A: **Route based on originating virtual port ID** (default), **source MAC hash**, and **IP hash** (requires matching physical link aggregation). The vDS adds **Load-Based Teaming (LBT) — route based on physical NIC load**, which rebalances when an uplink exceeds ~75% utilization.

**SUSE Virtualization:** Teaming is set by the Linux **bond mode** on the uplink (e.g. active-backup, balance-tlb, 802.3ad), not by port-ID/MAC/IP-hash policies.

Q: What are failover order and standby uplinks in NIC teaming?
A: The **failover order** classes uplinks as **active**, **standby**, or **unused**. Traffic uses active uplinks; a **standby uplink** only takes over when an active one fails. Failback and failure detection (link status vs beacon probing) are also configured here.

**SUSE Virtualization:** No active/standby/unused classification — the **bond mode** (e.g. active-backup) determines which slave NIC is primary and how failover occurs.

Q: What is the difference between the VMXNET3 and E1000 virtual NICs?
A: **VMXNET3** is a **paravirtualized** adapter — higher throughput, lower CPU, offloads and multiqueue — but needs VMware Tools drivers. **E1000/E1000E** emulate real Intel NICs, so they work without extra drivers but perform worse. VMXNET3 is preferred for modern guests.

**SUSE Virtualization:** The paravirtualized NIC model is **virtio-net** (with **e1000** emulation available), analogous to VMXNET3 vs E1000.

Q: What is traffic shaping on a vSphere switch?
A: **Traffic shaping** caps bandwidth using **average bandwidth, peak bandwidth, and burst size**. A vSS shapes **outbound** traffic only; a **vDS can shape both ingress and egress**.

**SUSE Virtualization:** **No direct equivalent** — Harvester has no built-in per-port bandwidth traffic-shaping feature.

Q: What is a Private VLAN (PVLAN) on a vDS?
A: A **PVLAN** subdivides one VLAN into **promiscuous, isolated, and community** secondary VLANs to control which ports can talk to each other while sharing an IP subnet. PVLANs are a **vDS-only** feature and require the physical switch to support them.

**SUSE Virtualization:** **No direct equivalent** — Harvester VLAN networks have no promiscuous/isolated/community private-VLAN concept.

Q: What are LACP and LAG on a vSphere Distributed Switch?
A: A **LAG (Link Aggregation Group)** bundles multiple uplinks into one logical link. **LACP (802.3ad)** dynamically negotiates that bundle with the physical switch. LACP is supported only on a **vDS**, and port groups using it must use the LAG as their teaming uplink.

**SUSE Virtualization:** The uplink bond supports **802.3ad (LACP) mode**, giving the same link aggregation negotiated with the physical switch.

Q: What is Network I/O Control (NIOC)?
A: **NIOC** is a **vDS** feature that allocates bandwidth to traffic types (vMotion, vSAN, management, VM, etc.) using **shares, reservations, and limits**, so no single traffic class starves others on shared uplinks.

**SUSE Virtualization:** **No direct equivalent** — there is no shares/reservation/limit bandwidth allocation across traffic types.

Q: What do the promiscuous mode, forged transmits and MAC changes security settings do?
A: These are virtual-switch **security policies**. **Promiscuous mode** (default Reject) lets a vNIC see all traffic on the port group. **MAC address changes** and **Forged transmits** (default Reject) control whether a VM may receive/send with a MAC different from its configured one — important against spoofing.

**SUSE Virtualization:** **No per-port-group toggles by these names** — behavior is governed by the Linux **bridge/Multus** layer, without promiscuous/forged-transmit/MAC-change security switches.

Q: What are MTU and jumbo frames in vSphere networking?
A: **MTU** is the maximum frame size; raising it to **9000 bytes (jumbo frames)** reduces per-packet overhead for vMotion, vSAN, iSCSI/NFS. It must be set **end-to-end** — on the vSwitch/vDS, VMkernel adapters, and every physical switch — or fragmentation/drops occur.

**SUSE Virtualization:** **MTU** is a per-**ClusterNetwork** setting that VM networks inherit and must match end-to-end across nodes and physical switches.
