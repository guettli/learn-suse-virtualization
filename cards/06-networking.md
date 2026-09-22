# Networking

Q: What is the management network (mgmt) in Harvester?
A: The **mgmt** network is the built-in cluster network that is always enabled and cannot be deleted or disabled. It carries Kubernetes control-plane, node, and storage-by-default traffic, and it is the network a VM uses when attached to the pod/management network (via KubeVirt masquerade binding) rather than a VLAN.

Q: What is a ClusterNetwork in Harvester?
A: A **ClusterNetwork** is a cluster-wide, traffic-isolated forwarding path that groups the per-node network configurations and the VM networks built on top of them. The built-in `mgmt` cluster network exists automatically; you create additional cluster networks (e.g. `vlan`, `storage`) to carry VM or storage traffic on separate uplinks.

Q: What does a Network Config (uplink) define on each host?
A: A per-host **Network Config** binds a ClusterNetwork to physical NICs on that node and sets the **uplink**: which NICs, the **bond mode** (default `active-backup`), and the **MTU**. Using a node selector, different hosts can have different NIC layouts under the same cluster network, supporting heterogeneous hardware.

Q: Why bond NICs for a Harvester uplink?
A: **NIC bonding** aggregates multiple physical ports into one logical uplink for **redundancy** (and, depending on mode, throughput). The default `active-backup` mode keeps traffic on one NIC and fails over to the other if a link or switch dies, so VM and cluster networking survive a single-NIC or single-switch failure.

Q: What role do Multus and NetworkAttachmentDefinition play?
A: Harvester uses **Multus** to give VMs interfaces beyond the default pod network. Each VLAN/untagged VM network is represented by a **NetworkAttachmentDefinition (NAD)** CRD that describes the bridge and VLAN; attaching a VM to that NAD wires an extra NIC into the VM. The NAD inherits its MTU from the parent cluster network config.

Q: How does a VM NIC connect to a physical VLAN network?
A: For VLAN/untagged networks Harvester uses KubeVirt **bridge binding**: the VM's NIC is attached to the host bridge on the cluster network's bonded uplink, so the VM sits directly on the external L2 segment. By contrast the management network uses **masquerade binding**, NATing the VM behind the pod network.

Q: What is the storage network and why separate it?
A: The **storage network** is an optional dedicated network (its own cluster network + VLAN) that carries **Longhorn replication and data traffic**, moving it off the `mgmt` network. This prevents storage I/O from contending with control-plane traffic; Longhorn pods get an extra interface (e.g. `lhnet1`) on it. All VMs must be stopped to (re)configure it.

Q: What is the management VIP in Harvester and how is it provided?
A: The **management VIP** is a single virtual IP for reaching the cluster API/UI regardless of which node is active; it is provided by **kube-vip**. It is set at install via DHCP or static assignment, must be in the same L2 subnet as the node mgmt interfaces, and differ from every node IP. It moves between nodes using gratuitous ARP.

Q: How does Harvester load-balance traffic to VM workloads or guest clusters?
A: Harvester provides a built-in **Layer-4 (TCP/UDP) load balancer** that spreads traffic across backend VMs chosen by label selector, with health checks. Combined with the **Harvester Cloud Provider**, it also backs `LoadBalancer` Services in guest Kubernetes clusters, automatically creating a Harvester LB per guest service. It requires the guest agent and is IPv4-only.

Q: How do VMs and load balancers get their IP addresses?
A: Addresses come either from **DHCP** on the VLAN network or from a Harvester **IPPool** (IP pool), an administrator-defined range that IPAM hands out — using an `auto` pool by namespace/network or an explicitly named pool. IP pools use the Whereabouts CNI for allocation and let you assign LB IPs without an external DHCP server.

Q: What is the difference between a tagged (VLAN) and an untagged VM network?
A: A **VLAN network** carries a specific VLAN ID; the host uplink must be a switch **trunk port** passing that tagged VLAN. An **untagged network** carries no VLAN tag (native/access VLAN) and is used when the VMs should ride the uplink's untagged traffic. Both are Multus networks on a non-mgmt cluster network.

Q: What must you consider about MTU and jumbo frames?
A: The default **MTU is 1500**. If you raise it for jumbo frames (e.g. to boost storage throughput), the value must be set **consistently** across every node's network config for that cluster network **and** on the physical switches/uplinks end to end. A mismatch causes silent drops of large frames.

Q: How can a VM's VLAN network affect live migration?
A: A VM can only migrate to a host where its network is actually available. If the VM uses a VLAN network whose **cluster network / uplink does not span the destination node**, that node fails the scheduling rules and migration is blocked. Ensure the VLAN cluster network config covers all candidate nodes so the VM can move.

Q: How do you apply a cluster network's uplink configuration to only some hosts, and what happens to hosts it does not cover?
A: Each ClusterNetwork holds one or more **Network Configs**, and each config is bound to a set of hosts by **node selection** (all nodes, a **node-label** selector, or hand-picked nodes) — so hosts with different NIC layouts each get a suitable config. On any host **not covered** by a config the cluster network stays **inactive**, and a VM using a VM network on it **cannot be scheduled or migrated there**. Best practice is one config per node/group to ease NIC maintenance.

Q: What must you specify when enabling the storage network, and why size its IP range generously?
A: The storage network is built from a **VLAN ID**, a **cluster network**, an **IP Range (CIDR)**, and an optional **Exclude** list, together forming a Multus NAD that Longhorn pods attach to. Size the range for **future growth**: Longhorn pods take one IP each and are **restarted** whenever you add nodes or disks, and if the required IPs **exceed the range** those pods fail to start. All VMs must be stopped to (re)configure it.

Q: Why do VMs attached to the built-in mgmt network see an effective MTU of 1450 rather than 1500?
A: On `mgmt`, VM traffic rides the cluster's pod **VXLAN overlay** (RKE2's **Canal = Calico + Flannel**), which reserves roughly **50 bytes** of encapsulation header. VM interfaces therefore inherit an effective **MTU of 1450**. Guests that assume 1500 (or jumbo frames) can see fragmentation or black-holed large packets; putting VMs on a dedicated **VLAN network** over a separate uplink avoids this overlay tax.

Q: In what scope does a Harvester VM (VLAN) network live, and how does that constrain which VMs can attach to it?
A: A VM network is a **NetworkAttachmentDefinition created in a specific namespace**, so it is **namespace-scoped**. A VM normally attaches only to a network in **its own namespace** (cross-namespace use requires an explicit `namespace/name` reference), which lets Harvester hand out networks per tenant/project via RBAC. The physical uplink/VLAN is cluster-wide, but the NAD object VMs reference is namespaced.
