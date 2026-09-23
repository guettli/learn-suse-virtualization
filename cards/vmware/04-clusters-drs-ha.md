# Clusters, DRS & HA

Q: What is a vSphere cluster?
A: A **cluster** is a logical grouping of ESXi hosts managed as a single pooled resource by vCenter. Their combined CPU and memory form one shared capacity, enabling cluster-wide features like **DRS**, **vSphere HA**, and **EVC**. Adding a host to a cluster contributes its resources to the pool.

Q: What is DRS (Distributed Resource Scheduler)?
A: **DRS** balances CPU and memory load across the hosts in a cluster. It decides where to power on VMs (**initial placement**) and uses **vMotion** to migrate running VMs between hosts to keep utilization even and honor resource-pool entitlements.

Q: What are the DRS automation levels?
A: DRS has three **automation levels**: **Manual** (recommendations only, admin applies them), **Partially automated** (auto initial placement, migrations only recommended), and **Fully automated** (both placement and load-balancing migrations applied automatically without prompting).

Q: What does the DRS migration threshold control?
A: The **migration threshold** is a slider (conservative to aggressive) that sets how much cluster imbalance DRS tolerates before recommending or performing a **vMotion**. Aggressive settings act on smaller imbalances (more migrations); conservative settings only act on significant imbalances.

Q: How does DRS initial placement differ from load balancing?
A: **Initial placement** picks the best host to power a VM on for the first time (or after power-on). **Load balancing** is the ongoing work of migrating already-running VMs via vMotion to smooth out CPU/memory imbalance as demand shifts.

Q: What is a resource pool in vSphere?
A: A **resource pool** is a container that partitions a cluster's or host's CPU and memory into hierarchical sub-allocations. Pools can be nested, letting you delegate a slice of aggregate capacity to a group of VMs or a team.

Q: What do shares, reservations, and limits mean for resource pools and VMs?
A: **Shares** set relative priority when resources are contended (proportional weighting). A **reservation** is a guaranteed minimum amount of CPU/memory that is always available. A **limit** is a hard ceiling the object can never exceed, even when spare capacity exists.

Q: What is vSphere HA (High Availability)?
A: **vSphere HA** restarts VMs on surviving hosts after a host fails, so downtime is limited to a reboot rather than being lost. It also restarts VMs on the same host if their guest OS fails (VM monitoring). HA does not prevent the crash; it recovers from it automatically.

Q: How do HA primary and subordinate hosts and the FDM agent work?
A: HA elects one **primary** (master) host; the rest are **subordinates** (slaves). The **FDM (Fault Domain Manager)** agent runs on every host: subordinates report state to the primary, and the primary monitors hosts/VMs and orchestrates restarts. If the primary fails, a new one is elected.

Q: What is HA admission control and what policies enforce it?
A: **Admission control** reserves enough spare capacity so HA can actually restart VMs after a failure, blocking power-ons that would consume the reserve. Policies include **Slot Policy** (fixed slot sizing), **Cluster resource percentage** (reserve a % of CPU/RAM), and **Dedicated failover hosts** (hold specific hosts idle for failover).

Q: What are host isolation and the HA isolation response?
A: A host is **isolated** when it stops receiving HA network heartbeats and cannot reach its isolation-address gateway, yet is still running. The **isolation response** decides what happens to its VMs: **Leave powered on**, **Power off** (hard), or **Shut down** (graceful) so another host can safely restart them.

Q: What is datastore heartbeating in vSphere HA?
A: **Datastore heartbeating** is HA's secondary liveness channel. When network heartbeats stop, the primary checks whether the host still updates heartbeat files on shared datastores. This distinguishes a truly dead host from a merely network-isolated or partitioned one, preventing needless restarts.

Q: What is Proactive HA?
A: **Proactive HA** acts before a host fully fails. Using hardware health data from a vendor provider (e.g., failing PSU, fan, or memory), it flags a host as degraded and evacuates its VMs via vMotion, optionally placing the host in quarantine or maintenance mode.

Q: What is EVC (Enhanced vMotion Compatibility) and what is a baseline?
A: **EVC** masks newer CPU features so all hosts in a cluster present a common instruction set, allowing vMotion between hosts with different CPU generations of the same vendor. The **baseline** is that agreed lowest common feature set; hosts must support at least the baseline to join.

Q: What is DPM (Distributed Power Management)?
A: **DPM** saves power by consolidating VMs onto fewer hosts during low demand via DRS, then powering the emptied hosts off (using IPMI, iLO, or Wake-on-LAN to wake them). When load rises again, DPM powers hosts back on and rebalances.

Q: What are VM/host affinity and anti-affinity rules?
A: **Affinity/anti-affinity rules** constrain DRS placement. **VM-VM affinity** keeps VMs together; **VM-VM anti-affinity** keeps them apart (e.g., spread cluster nodes across hosts). **VM-host** rules tie VMs to a host group, either as "should"/"must" run on (affinity) or not run on (anti-affinity).

Q: What is predictive DRS?
A: **Predictive DRS** combines DRS with **vRealize/Aria Operations** forecast data to act on predicted demand spikes before they occur, migrating VMs ahead of time rather than only reacting to current load.
