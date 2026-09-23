# NSX & Network Virtualization

Q: What is VMware NSX?
A: **NSX** is VMware's **network and security virtualization (SDN)** platform. It reproduces L2-L7 networking — switching, routing, firewalling, load balancing — **in software**, decoupled from the physical fabric, and manages it centrally across hosts and clouds.

Q: How does modern NSX (NSX-T) differ from the older NSX-V?
A: **NSX-V** was tightly coupled to vCenter/vSphere only. **NSX-T** (now just **NSX 4.x**) is independent of vCenter and supports **multi-hypervisor, bare-metal, containers and multi-cloud**, using its own management plane and the Geneve overlay. NSX-V is end-of-life.

Q: What is overlay networking with Geneve encapsulation in NSX?
A: NSX builds **logical L2 overlay networks** on top of any routed IP fabric by **encapsulating** VM traffic in **Geneve** packets between host **Tunnel Endpoints (TEPs)**. This decouples logical networks from physical VLANs and makes segments span L3 boundaries transparently to guests.

Q: What is a segment in NSX?
A: A **segment** (formerly **logical switch**) is a virtual L2 broadcast domain. VMs attached to the same segment communicate as if on one switch; an overlay segment maps to a unique **Geneve virtual network identifier** distributed across all transport nodes in its transport zone.

Q: What are Tier-0 and Tier-1 gateways in NSX?
A: NSX uses a two-tier routing model. A **Tier-0 (T0) gateway** is the north-south edge that connects to the **physical/upstream network** (BGP, uplinks). A **Tier-1 (T1) gateway** provides **tenant/workload-level** routing and services, connecting segments and linking up to a T0.

Q: What is the NSX Distributed Firewall (DFW) and micro-segmentation?
A: The **DFW** enforces stateful firewall rules **at each VM's virtual NIC (vNIC)**, inside the hypervisor kernel. This enables **micro-segmentation** — granular east-west policy between workloads regardless of subnet — so lateral movement is blocked without hair-pinning traffic to a physical firewall.

Q: What is an NSX Edge node/cluster?
A: An **NSX Edge** is an appliance (VM or bare metal) that provides **centralized services** and north-south connectivity that can't be distributed: T0/T1 service routers, NAT, VPN, load balancing, gateway firewall. Edges are grouped into an **Edge cluster** for scale and high availability.

Q: What is N-VDS versus VDS in NSX transport nodes?
A: **N-VDS** was NSX's own host switch used to prepare transport nodes. Modern NSX (with vSphere 7+/8) instead runs NSX directly on the **vSphere Distributed Switch (VDS)**, converging on one switch. New deployments use the **VDS**; N-VDS is legacy.

Q: What are a Transport Zone and a Transport Node in NSX?
A: A **Transport Node** is a host or Edge prepared to participate in NSX networking (it runs the host switch and TEPs). A **Transport Zone** defines the span of a network — which transport nodes can reach a given set of segments — and is typed **overlay** or **VLAN**.

Q: What is the NSX Manager?
A: **NSX Manager** is the **management and control plane** — usually a cluster of three appliances. It provides the API/UI, stores configuration (policy), and pushes desired state to transport nodes and Edges. It is the single point of administration for NSX.

Q: What are security groups and security policies in NSX?
A: A **security group** is a dynamic membership of objects (by tag, name, OS, etc.) used as firewall rule source/destination. A **security policy** is an ordered set of DFW/gateway rules applied to those groups, enabling **intent-based, tag-driven** segmentation that follows workloads automatically.

Q: How does NSX differ from vSphere Distributed Switch (vDS) networking?
A: A **vDS** provides L2 switching, VLAN-backed port groups and teaming across hosts, but no overlay, routing, or distributed firewall. **NSX** adds **Geneve overlays, distributed logical routing (T0/T1), the distributed firewall/micro-segmentation, and multi-site/multi-cloud** networking and security on top.
