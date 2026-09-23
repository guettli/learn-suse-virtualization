# Networking (vSS & vDS)

Q: What is a vSphere Standard Switch (vSS)?
A: A **vSphere Standard Switch (vSS / vSwitch)** is a virtual switch **configured per ESXi host**. Each host has its own copy, so port groups and policies must be created identically on every host — there is no central management.

Q: What is a vSphere Distributed Switch (vDS)?
A: A **vDS (DVS)** is a virtual switch **created and managed centrally in vCenter** that spans multiple ESXi hosts, giving consistent port groups and policies cluster-wide — unlike the per-host **vSS**.

Q: What is the difference between a port group and a distributed port group?
A: A **port group** is a template of network settings (VLAN, security, teaming) applied to ports on a **standard switch (per host)**. A **distributed port group** does the same on a **vDS**, so the settings are defined once and applied across all member hosts.

Q: What is an uplink on a virtual switch?
A: An **uplink** is a **physical NIC (vmnic)** of the host bound to the virtual switch, connecting VM/VMkernel traffic to the physical network. On a vDS, physical NICs map to logical **uplink ports** in an uplink port group.

Q: What is the difference between a VMkernel adapter and a VM port group?
A: A **VMkernel adapter (vmk)** is a host's own IP interface for infrastructure services (management, vMotion, vSAN, NFS/iSCSI). A **VM port group** connects **virtual machine vNICs** to the network. VMkernel traffic is the host's; VM port groups carry guest traffic.

Q: What are VST, EST and VGT VLAN tagging modes?
A: **VST (Virtual Switch Tagging)** — the vSwitch tags with the port group's VLAN ID (most common). **EST (External Switch Tagging)** — VLAN 0, the physical switch tags. **VGT (Virtual Guest Tagging)** — VLAN 4095, the guest OS handles 802.1Q tags itself.

Q: What is NIC teaming on a virtual switch?
A: **NIC teaming** binds multiple physical uplinks to one switch/port group for **redundancy and increased throughput**, distributing traffic per a load-balancing policy and failing over to remaining uplinks if one goes down.

Q: What load-balancing policies can a vSphere virtual switch use?
A: **Route based on originating virtual port ID** (default), **source MAC hash**, and **IP hash** (requires matching physical link aggregation). The vDS adds **Load-Based Teaming (LBT) — route based on physical NIC load**, which rebalances when an uplink exceeds ~75% utilization.

Q: What are failover order and standby uplinks in NIC teaming?
A: The **failover order** classes uplinks as **active**, **standby**, or **unused**. Traffic uses active uplinks; a **standby uplink** only takes over when an active one fails. Failback and failure detection (link status vs beacon probing) are also configured here.

Q: What is the difference between the VMXNET3 and E1000 virtual NICs?
A: **VMXNET3** is a **paravirtualized** adapter — higher throughput, lower CPU, offloads and multiqueue — but needs VMware Tools drivers. **E1000/E1000E** emulate real Intel NICs, so they work without extra drivers but perform worse. VMXNET3 is preferred for modern guests.

Q: What is traffic shaping on a vSphere switch?
A: **Traffic shaping** caps bandwidth using **average bandwidth, peak bandwidth, and burst size**. A vSS shapes **outbound** traffic only; a **vDS can shape both ingress and egress**.

Q: What is a Private VLAN (PVLAN) on a vDS?
A: A **PVLAN** subdivides one VLAN into **promiscuous, isolated, and community** secondary VLANs to control which ports can talk to each other while sharing an IP subnet. PVLANs are a **vDS-only** feature and require the physical switch to support them.

Q: What are LACP and LAG on a vSphere Distributed Switch?
A: A **LAG (Link Aggregation Group)** bundles multiple uplinks into one logical link. **LACP (802.3ad)** dynamically negotiates that bundle with the physical switch. LACP is supported only on a **vDS**, and port groups using it must use the LAG as their teaming uplink.

Q: What is Network I/O Control (NIOC)?
A: **NIOC** is a **vDS** feature that allocates bandwidth to traffic types (vMotion, vSAN, management, VM, etc.) using **shares, reservations, and limits**, so no single traffic class starves others on shared uplinks.

Q: What do the promiscuous mode, forged transmits and MAC changes security settings do?
A: These are virtual-switch **security policies**. **Promiscuous mode** (default Reject) lets a vNIC see all traffic on the port group. **MAC address changes** and **Forged transmits** (default Reject) control whether a VM may receive/send with a MAC different from its configured one — important against spoofing.

Q: What are MTU and jumbo frames in vSphere networking?
A: **MTU** is the maximum frame size; raising it to **9000 bytes (jumbo frames)** reduces per-packet overhead for vMotion, vSAN, iSCSI/NFS. It must be set **end-to-end** — on the vSwitch/vDS, VMkernel adapters, and every physical switch — or fragmentation/drops occur.
