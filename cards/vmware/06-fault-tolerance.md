# Fault Tolerance

Q: What is vSphere Fault Tolerance (FT)?
A: **vSphere FT** provides continuous availability by running a live **secondary (shadow) VM** in lockstep with the primary on a different host. Both execute the same instructions, but only the primary produces output. If the primary's host fails, the secondary takes over instantly with **zero downtime and no data loss**.

**SUSE Virtualization:** No direct equivalent — KubeVirt/Harvester has no lockstep secondary; the closest is **VM high availability**, which auto-restarts a VM on another node after a failure (a reboot, not zero-downtime).

Q: What is Fast Checkpointing in FT?
A: **Fast Checkpointing** is the mechanism modern SMP-FT uses to keep the secondary VM in sync: the primary's full execution state is streamed continuously to the secondary at a high checkpoint rate over the FT network. It replaced the older single-vCPU **Record/Replay** technique, enabling multi-vCPU FT.

**SUSE Virtualization:** No direct equivalent — with no lockstep FT there is no checkpoint-streaming mechanism to keep a shadow VM in sync.

Q: What is the difference between the primary and secondary VM in FT?
A: The **primary VM** is the one users interact with and that handles all I/O and network output. The **secondary VM** runs hidden in lockstep on another host as a hot standby. On primary-host failure the secondary is promoted to primary, and a new secondary is spawned automatically to restore protection.

**SUSE Virtualization:** No direct equivalent — there is no hidden secondary VM; only a single running VM instance exists, recreated elsewhere on failure.

Q: How does Fault Tolerance differ from vSphere HA?
A: **HA restarts** a failed VM on another host, meaning a reboot and some downtime. **FT** keeps a running duplicate ready, so failover is **instantaneous with no reboot and no lost state**. HA protects many VMs cheaply; FT gives a small number of critical VMs true zero-downtime continuity.

**SUSE Virtualization:** Only the HA-style model exists — **VM high availability** restarts a failed VM on a healthy node (a reboot with downtime); there is no zero-downtime FT counterpart.

Q: What are the main limitations of vSphere FT?
A: FT-protected VMs are capped at up to **8 vCPUs** (Enterprise Plus; 2 on Standard/Enterprise) and a bounded memory size, and they cannot use **snapshots**, **Storage vMotion**, **NPIV**, **physical RDMs**, or hot-add of devices. Hosts must have compatible CPUs, and the secondary consumes duplicate compute resources.

**SUSE Virtualization:** Not applicable — with no FT feature there are no FT vCPU/memory or feature caps; the availability model is simply auto-restart via **VM high availability**.

Q: What is the FT logging network?
A: The **FT logging network** is a dedicated, low-latency VMkernel link (a **10 Gbit** network is recommended) that carries the continuous checkpoint stream from the primary to the secondary VM. Insufficient bandwidth or high latency here degrades the protected VM's performance.

**SUSE Virtualization:** No direct equivalent — with no checkpoint stream there is no dedicated FT logging network.

Q: What does transparent failover mean in FT?
A: **Transparent failover** means that when the primary's host dies, the secondary instantly assumes the primary role while preserving the exact CPU and memory state, keeping the same MAC/IP and open connections. Applications and users experience no interruption or reconnect.

**SUSE Virtualization:** No direct equivalent — failover is not transparent; **VM high availability** reboots the VM on another node, so in-memory state is lost and connections reset.

Q: When should you use FT versus HA?
A: Use **FT** for a few mission-critical VMs that cannot tolerate even a reboot's worth of downtime, staying within FT's vCPU/memory and feature limits. Use **HA** for broad, cost-effective protection of many VMs where a quick automatic restart after a host failure is acceptable.

**SUSE Virtualization:** Only the HA-style choice applies — **VM high availability** covers automatic restart of VMs after node failure; there is no FT option for workloads that cannot tolerate a reboot.
