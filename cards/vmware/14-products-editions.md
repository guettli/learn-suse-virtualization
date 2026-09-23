# Products & Editions

Q: How are the ESXi hypervisor and vCenter Server licensed relative to each other?
A: **ESXi** (the hypervisor) is licensed per host based on **physical CPU cores**, while **vCenter Server** (the central management platform) is licensed **per instance**. You need both in a managed environment: ESXi runs the VMs; vCenter licenses the management, clustering, vMotion, DRS/HA orchestration across hosts.

Q: What were the historic vSphere editions before the Broadcom bundles?
A: Perpetually licensed per-CPU editions such as **vSphere Standard**, **Enterprise**, and **Enterprise Plus** (plus Essentials kits) differentiated features like DRS, vMotion, and DvS. Broadcom retired most of this à-la-carte, perpetual model in favor of a few **subscription bundles**. (Broadcom-era packaging; specifics keep changing.)

Q: What are VCF and VVF in Broadcom's simplified VMware portfolio?
A: **VMware Cloud Foundation (VCF)** is the top full-stack private-cloud bundle; **VMware vSphere Foundation (VVF)** is the smaller virtualization bundle for general workloads. After acquiring VMware, Broadcom collapsed ~168 SKUs into a small set of subscription offerings centered on these two, plus the smaller **vSphere Standard** and **vSphere Enterprise Plus** tiers. (Broadcom-era packaging.)

Q: How does Broadcom license VMware bundles like VCF and VVF?
A: Licensing is **subscription**, priced **per physical core**, with a **minimum of 16 cores per CPU**. Broadcom **ended free ESXi and perpetual licensing**, moving everything to term subscriptions. Order minimums have shifted over 2025 (a 72-core-per-order minimum was introduced, then reversed toward 16). Treat exact minimums/prices as volatile.

Q: What does VMware Cloud Foundation (VCF) bundle together?
A: **VCF** bundles the full software-defined datacenter as one subscription: **vSphere** (ESXi + vCenter), **vSAN** (storage, generous per-core capacity), **NSX** (networking/security), and the **Aria** management suite, plus lifecycle automation (SDDC Manager). It targets a self-service **private cloud**; VVF is the lighter subset without NSX/full VCF entitlements.

Q: What is vSAN and how is its capacity entitled under Broadcom?
A: **vSAN** is VMware's software-defined storage that pools host-local disks into a shared datastore, licensed by **capacity (per-TiB)**. Under Broadcom it is **included** in the bundles with a per-core capacity allowance (e.g. more TiB/core with VCF than VVF); usage beyond the included amount is bought as **add-on vSAN capacity**. (Broadcom-era packaging.)

Q: What is NSX in the VMware portfolio?
A: **NSX** is VMware's **network and security virtualization** platform — software-defined switching, routing, distributed firewalling/micro-segmentation, and load balancing decoupled from physical hardware. It is a core component of the **VCF** bundle and generally not part of the lighter VVF tier.

Q: What is VMware Aria and what did it replace?
A: **VMware Aria** is the cloud-management suite, **renamed from vRealize** in 2022. Key pieces: **Aria Operations** (formerly vRealize Operations — monitoring/capacity), **Aria Automation** (formerly vRealize Automation — self-service/IaC), and **Aria Operations for Logs** (formerly vRealize Log Insight — log analytics). It ships within VCF.

Q: What is Tanzu / vSphere with Tanzu (VKS)?
A: **vSphere with Tanzu** turns a vSphere cluster into a **Kubernetes** platform, letting you run pods and provision conformant K8s clusters directly on ESXi via a Supervisor. The current productized Kubernetes runtime is branded **VKS (VMware vSphere Kubernetes Service)** — Tanzu's Kubernetes offering integrated with vSphere/VCF.

Q: What is VMware Horizon?
A: **VMware Horizon** is VMware's **VDI (Virtual Desktop Infrastructure)** platform — it delivers virtual desktops and published applications to end users from the datacenter or cloud. It is a separate product line from the core vSphere/VCF infrastructure bundles, licensed on its own (e.g. per named/concurrent user).

Q: What do Site Recovery Manager (SRM) and vSphere Replication provide?
A: **vSphere Replication** is host-based, per-VM **asynchronous replication** of VMs to a recovery site (no array required). **Site Recovery Manager (SRM)** adds **automated disaster-recovery orchestration** — recovery plans, ordered failover, and non-disruptive **DR testing**. Together they deliver planned/unplanned failover; both are add-on products.

Q: What is VMware Cloud (e.g. VMware Cloud on AWS)?
A: **VMware Cloud** is VMware's **hybrid-cloud** offering that runs the full **VCF/SDDC stack (vSphere, vSAN, NSX) on public-cloud bare metal** — the classic example being **VMware Cloud on AWS**. It lets you run familiar vSphere workloads in a hyperscaler without re-architecting, with consistent tooling across on-prem and cloud.

Q: What happened to free ESXi and perpetual VMware licenses under Broadcom?
A: Broadcom **discontinued the free ESXi hypervisor** and ended **perpetual licensing and Support-and-Subscription renewals** for legacy editions, steering all customers to **term subscriptions** priced per core within the VCF/VVF/Standard bundles. Existing perpetual licenses keep working but generally can't be renewed. (Broadcom-era packaging; details evolve.)

Q: Why did Broadcom reintroduce vSphere Enterprise Plus as a subscription tier?
A: After pushback on bundle-only licensing, Broadcom announced (November 2024) a standalone **vSphere Enterprise Plus** **subscription** tier for customers wanting advanced vSphere features (DRS, vDS, VM Encryption) without a full VCF/VVF bundle, and discontinued the **vSphere Essentials Plus** kit alongside it. (Broadcom-era packaging; edition lineup keeps shifting — verify against current price/SKU docs.)
