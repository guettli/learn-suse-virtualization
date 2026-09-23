# Architecture

Q: What is SUSE Virtualization, and what is its upstream open-source name?
A: SUSE Virtualization is SUSE's **hyperconverged infrastructure (HCI)** product for running
virtual machines. Upstream it is the open-source project **Harvester**. It bundles compute,
storage, and networking on a Kubernetes foundation and runs on bare metal, positioned as a
cloud-native alternative to traditional hypervisor stacks like VMware vSphere.

Q: What are the four foundational technologies in the SUSE Virtualization stack?
A: 1. **Kubernetes (RKE2)** as the control plane and orchestration layer.
2. **KubeVirt** to run and manage VMs as Kubernetes resources.
3. **Longhorn (SUSE Storage)** for distributed block storage.
4. **KVM/QEMU** as the actual hypervisor executing the guests.

Q: Which host operating system does a SUSE Virtualization node run?
A: A purpose-built, immutable OS based on **SLE Micro / openSUSE Leap Micro**, provisioned
with **Elemental**. The node is an appliance: you don't install packages into it directly —
configuration is declarative and upgrades replace the OS image atomically.

Q: Which Kubernetes distribution does SUSE Virtualization run on, and why does it matter?
A: **RKE2** (Rancher's CNCF-conformant, security-hardened Kubernetes). It matters because
Harvester components (KubeVirt, Longhorn, Multus, etc.) run as workloads on this cluster,
and RKE2 provides the embedded etcd, control-plane, and CNI that everything else builds on.

Q: How does KubeVirt let a VM run inside Kubernetes?
A: KubeVirt adds VM CRDs (`VirtualMachine`, `VirtualMachineInstance`) and controllers. A
running VM is hosted inside a normal pod called **virt-launcher**, which starts **libvirt +
QEMU/KVM** for that guest. The VM therefore participates in Kubernetes scheduling, networking,
and storage like any other pod.

Q: What role does Longhorn play in the architecture?
A: Longhorn (shipped as **SUSE Storage**) provides **distributed, replicated block storage**
built from the local disks of the nodes. VM disks are Longhorn volumes exposed through a CSI
StorageClass, synchronously replicated across nodes so a VM's data survives a node failure.

Q: What is the difference between the embedded Rancher in SUSE Virtualization and a separate Rancher Manager?
A: Each cluster ships an **embedded Rancher** used internally for authentication and the built-in
UI. For managing many clusters and provisioning guest Kubernetes clusters, you **import** the
Harvester cluster into a standalone **Rancher Manager**, which then offers Virtualization
Management and the Harvester node driver.

Q: Why is SUSE Virtualization described as "hyperconverged"?
A: Because **compute, storage, and networking are collapsed onto the same pool of commodity
nodes** rather than separated into distinct SAN/compute tiers. Every node contributes CPU,
RAM, and disk; adding a node scales all three at once.

Q: What is the management VIP in a SUSE Virtualization cluster and how is it provided?
A: A **virtual IP (VIP)** that floats across management nodes to give a stable endpoint for the
UI and Kubernetes API. It is provided by **kube-vip**, so the cluster stays reachable at one
address even when the leader node changes.

Q: How does SUSE Virtualization attach VMs to multiple networks beyond the pod network?
A: Via **Multus**, which lets a VM's interface be backed by additional
`NetworkAttachmentDefinition`s (for example VLAN-tagged bridge networks) in addition to the
default cluster pod network.

Q: Is SUSE Virtualization meant to run on top of another hypervisor or directly on hardware?
A: Directly on **bare metal**. It installs its own immutable OS and Kubernetes stack on the
physical servers; nesting it inside another hypervisor is only supported for testing/PoC, not
production.

Q: How does the "everything is a Kubernetes object" design benefit operators?
A: VMs, disks, images, networks, and backups are all **CRDs**, so they can be managed with
`kubectl`, GitOps, RBAC, and the same tooling as containers — giving consistent lifecycle,
policy, and automation across VMs and container workloads on one platform.

Q: What container runtime and CNI underpin the cluster that hosts the VMs?
A: RKE2's defaults: **containerd** as the container runtime and **Canal (Flannel + Calico)**
as the primary CNI, with **Multus** layered on top to provide the extra VM networks.

Q: At a high level, what happens when you start a VM in SUSE Virtualization?
A: The `VirtualMachine` object is set to running → KubeVirt creates a `VirtualMachineInstance`
→ the scheduler places a **virt-launcher** pod on a node → libvirt/QEMU boots the guest, with
its Longhorn volumes attached via CSI and its NICs wired through Multus.

Q: What is the Harvester addon framework and what does it provide?
A: Harvester ships a **minimal base** and packages optional features as **Addons** (an `Addon` CRD) that you **Enable/Disable** from the UI or `kubectl`. Enabling deploys the component (a Helm chart) into the cluster; disabling removes it but **keeps its configuration** for quick re-enable. Examples include `rancher-monitoring`, `rancher-logging`, `pcidevices-controller`, `vm-import-controller`, and `nvidia-driver-toolkit`.

Q: Which core components run in the harvester-system namespace?
A: The product's control plane lives in **`harvester-system`**: the **harvester** API/controller and its **harvester-webhook**, the **KubeVirt operator** with `virt-api`/`virt-controller`/`virt-handler`, and the **harvester-network-controller**. The embedded **Rancher** runs separately in **`cattle-system`**, and Longhorn's own pods run in **`longhorn-system`**. All of them are ordinary Deployments/DaemonSets managed by RKE2.

Q: What does Harvester add on top of plain KubeVirt?
A: KubeVirt only supplies the VM runtime. Harvester wraps it into a **turnkey HCI appliance**: an **immutable OS + RKE2**, integrated **Longhorn** storage, a management **VIP**, **Multus/VLAN** VM networks, a purpose-built **dashboard**, images/templates/backups as first-class objects, and **Rancher** multi-cluster integration. You install on bare metal and get working VMs without assembling the stack yourself.

Q: How does Harvester expose host PCI devices and GPUs to VMs?
A: Enable the **`pcidevices-controller`** addon; it scans nodes and lets you create a **`PCIDeviceClaim`** to pass a device through to a VM. For NVIDIA vGPU, the **`nvidia-driver-toolkit`** addon installs the host driver so a physical GPU can be sliced into vGPU profiles. Any VM using passthrough or vGPU becomes **non-migratable**.
