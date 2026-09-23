# NeuVector Security

Q: What is NeuVector and how does it relate to SUSE and Rancher?
A: **NeuVector** is an open-source **"Full Lifecycle Container Security"** platform, now **SUSE Security**. It secures containers across the pipeline (image scanning) and at runtime (L7 firewall, process/file rules, admission control). In Rancher it installs as the **NeuVector chart** from the Apps/marketplace into the `cattle-neuvector-system` namespace.

Q: What are NeuVector's four core component types?
A: - **Controller** — control plane; stores policy/config, exposes the **REST API**, coordinates enforcers.
- **Enforcer** — per-node agent doing the actual **DPI/firewall** and process/file enforcement.
- **Manager** — stateless web **UI console** (talks to the Controller API).
- **Scanner** — runs **vulnerability & compliance scans** (bundles the CVE database).

Q: How is the NeuVector Enforcer deployed across a cluster?
A: The **Enforcer runs as a DaemonSet** — one pod per node — so every host is protected and it auto-scales as nodes are added or removed. The **Controller** runs as a small replicated Deployment (typically 3 for HA); the **Manager** is a single Deployment.

Q: What are NeuVector's three container-firewall policy modes?
A: - **Discover** — learns normal network conversations and processes, auto-building a whitelist of rules (default for new groups).
- **Monitor** — no new rules learned; violations of the baseline are **alerted** but allowed.
- **Protect** — violations are **blocked** (zero-trust enforcement).
Modes are set per **group** and progressed Discover → Monitor → Protect.

Q: Why is NeuVector's L7 container firewall different from a Kubernetes NetworkPolicy?
A: NetworkPolicy is **L3/L4** (pod/namespace selectors, ports) enforced by the CNI. NeuVector uses a per-node **deep packet inspection (DPI)** engine acting as an **L7 firewall**: it inspects payloads to allow/deny by application protocol and detect threats (SQLi, DDoS, DNS attacks). It learns rules per service automatically and can **block** at Protect mode.

Q: How does NeuVector achieve network segmentation between services?
A: In **Discover** mode it observes East-West (container-to-container) conversations and builds a **whitelist of Network Rules** per group. Switching the group to **Protect** enforces **zero-trust segmentation** — only learned/allowed flows pass, everything else is blocked, without you hand-writing NetworkPolicies.

Q: What does NeuVector admission control do?
A: NeuVector registers as a Kubernetes **admission (validating) webhook** and evaluates **admission control rules** on deploy — e.g. deny images with high-severity CVEs, non-whitelisted registries, running as root, or missing image signatures. Rules can **deny** or **monitor-only**, blocking risky workloads before they schedule.

Q: What are DLP and WAF sensors in NeuVector?
A: **DLP** (Data Loss Prevention) sensors inspect traffic for sensitive patterns (e.g. credit-card/PII regexes); **WAF** sensors detect common **OWASP Top 10** web attacks. Both are **sensors** attached to groups, and in Protect mode matching traffic is blocked.

Q: What kinds of scanning does the NeuVector Scanner perform?
A: - **Image/registry scanning** — CVE vulnerability scans of images (registry integration + admission-time scan).
- **Running container/host/node** vulnerability scans.
- **Compliance** — **CIS Kubernetes/Docker benchmarks** and custom compliance templates.
The Scanner ships its own **CVE database**, updated regularly.

Q: What runtime protections beyond the network does NeuVector enforce?
A: Per-group **process profile rules** (whitelist of allowed executables) and **file access rules** (protected file/directory monitoring). In **Protect** mode, an unauthorized process launch or write to a protected path inside a container is **blocked** and reported as an incident.

Q: How can NeuVector be automated or integrated with Rancher for auth?
A: The Controller exposes a **REST API**; there is a **CLI** and the UI is just an API client, so policies (groups, rules, admission control) can be scripted. NeuVector supports **SSO/SAML/OIDC** and can federate auth with **Rancher**, so Rancher users log into NeuVector with mapped roles.

Q: What is NeuVector Federation used for?
A: **Federation** joins multiple NeuVector deployments under a **primary/master cluster** managing **remote/member clusters**, letting you author admission and security policies once and **push them fleet-wide** with centralized reporting across clusters.
