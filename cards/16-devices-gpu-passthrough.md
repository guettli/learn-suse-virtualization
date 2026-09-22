# Devices & GPU Passthrough

Q: What must you enable before you can pass PCI devices through to VMs?
A: Enable the **`pcidevices-controller` add-on** (the **PCI Devices** feature). Once deployed it **scans each node** and, after a few minutes, populates **`PCIDevice` CRDs** for the discovered host devices. Until the add-on is enabled there are no device objects to claim, so nothing can be passed through.

Q: What is the difference between the `PCIDevice` and `PCIDeviceClaim` CRDs?
A: A **`PCIDevice`** is read-only inventory — it represents one **host device at a PCI address** that the controller discovered. A **`PCIDeviceClaim`** is the request you create (via the UI or directly) to **reserve that device for passthrough**; creating the claim triggers the controller to prepare the device so a VM can own it.

Q: What does claiming a PCI device actually do to the host driver?
A: The controller **unbinds the device from its host driver and binds it to `vfio-pci`**. That detaches the device from the host OS and hands it to the VMFS/VFIO layer, so the guest can **load its own native driver and directly own the device** rather than sharing a virtualized one.

Q: What firmware prerequisite must be satisfied for PCI passthrough to work at all?
A: The platform's **IOMMU** must be enabled in firmware — **Intel VT-d** or **AMD-Vi (AMD IOMMU)** — usually alongside virtualization (VT-x/SVM). Without IOMMU the host cannot safely isolate the device's DMA, so `vfio-pci` binding and passthrough will not function even with the add-on enabled.

Q: How do you attach a whole GPU to a VM once its device is claimed?
A: In the VM's config under **PCI Devices**, pick the GPU from the **Available PCI Devices** list; this adds it as a passed-through device in `spec.domain.devices`. The GPU then appears as real hardware inside the guest, which must **install the vendor driver** (e.g. NVIDIA) to use it.

Q: How is NVIDIA vGPU (sliced GPU) support enabled, and how does it differ from full passthrough?
A: vGPU splits one physical GPU into **mediated (mdev) profiles** shared by several VMs, instead of dedicating the whole card. You enable the **`nvidia-driver-toolkit` add-on** (to run the NVIDIA vGPU manager) together with **`pcidevices-controller`**; SR-IOV-capable GPUs are surfaced as **`sriovgpudevices` / `vgpudevices` CRDs** under **Advanced → SR-IOV GPU Devices**, where you enable a device, choose a profile, and attach the vGPU to a VM.

Q: A VM has a GPU passed through — what migration limitation applies and what is the workaround?
A: It becomes **non-migratable**: a passed-through PCI device is bound to one node, so KubeVirt marks the VMI `LiveMigratable=false`. To move it you must do a **cold migration** — stop the VM, let it reschedule (or pin it with "run on specific node"), and start it on a host that has an equivalent device.

Q: How is USB device passthrough handled, and what constraint does it add?
A: USB passthrough uses the **`USBDevice` / `USBDeviceClaim` CRDs** (also from `pcidevices-controller`), letting you expose an **individual USB port/device** to a VM rather than a whole controller. Like PCI passthrough, an attached USB device **binds the VM to that node**, so the VM **cannot be live-migrated**.

Q: How are SR-IOV NIC virtual functions given to VMs?
A: The controller discovers SR-IOV-capable NICs as **`SRIOVNetworkDevice` objects**; you enable a device and set the **number of Virtual Functions (VFs)**. On the next scan each VF becomes a **`PCIDevice`** that you pass through like any other PCI device, giving the guest a near-bare-metal NIC — but such VMs are again **not live-migratable**.

Q: How does KubeVirt decide which host devices a VM is even allowed to use?
A: Only devices listed in the KubeVirt CR's **`configuration.permittedHostDevices`** are assignable. It has **`pciHostDevices`** (with `pciVendorSelector` + `resourceName`), **`mediatedDevices`** (with `mdevNameSelector` for vGPU), and **`usb`**. The `pcidevices-controller` maintains these entries and often sets **`externalResourceProvider: true`** so its own device plugin advertises them.

Q: How does a VM reference an assigned device, and how are device resources named?
A: Devices are exposed as **extended resources with vendor-style names** like `nvidia.com/TU104GL_Tesla_T4`. The VM lists them under **`spec.domain.devices.gpus`** (GPUs) or **`spec.domain.devices.hostDevices`**, where each entry gives a local `name` plus a **`deviceName` matching the `resourceName`** from `permittedHostDevices`.

Q: What is required inside the guest OS to actually use a passed-through or virtual GPU?
A: The guest must load the **matching vendor driver**: the **full native driver** for a fully passed-through GPU, or the **NVIDIA vGPU guest driver** for an mdev vGPU (its version must be compatible with the host vGPU manager). Without the correct in-guest driver the device is present but non-functional.

Q: What is needed for CPU pinning, and how do hugepages and NUMA improve performance VMs?
A: Pinning requires the node's **CPU Manager (static policy)** to be enabled first; the VM then requests whole cores and lands in the **Guaranteed QoS** class so cores are dedicated to it. For best latency you also align the VM to a single **NUMA node** and back its memory with **hugepages**, keeping vCPUs and memory local to the same socket.

Q: How does the scheduler ensure a VM lands on a node that actually has its device?
A: Because a claimed device is advertised as a **node-local extended resource**, requesting it makes the scheduler place the VMI **only on nodes exposing that resource**. A caveat: when identical devices exist on multiple nodes they can share a resource name, so you may need **"run VM on a specific node"** to guarantee the right host.
