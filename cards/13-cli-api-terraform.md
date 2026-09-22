# CLI, API & Terraform

Q: How do you get a kubeconfig to run kubectl against a SUSE Virtualization cluster?
A: Download it from the Harvester UI — click **Support** (bottom-left) then **Download KubeConfig** — or on a management node use the underlying RKE2 kubeconfig at `/etc/rancher/rke2/rke2.yaml`. Point `kubectl` at it via `--kubeconfig` or the `KUBECONFIG` env var.

Q: Why can you manage almost everything in SUSE Virtualization directly with kubectl?
A: Its API **is** the Kubernetes API — every object is a **CRD**. VMs are KubeVirt `VirtualMachine`/`VirtualMachineInstance`, images are `VirtualMachineImage`, extra networks are `NetworkAttachmentDefinition`, volumes are Longhorn-backed PVCs, so `kubectl get/apply/patch` works on all of them.

Q: What is virtctl and which VM operations does it handle?
A: **virtctl** is KubeVirt's VM-focused CLI. It covers lifecycle (`virtctl start`/`stop`/`restart <vm>`), console access (`virtctl console`, `virtctl vnc`), and image upload (`virtctl image-upload`). It complements `kubectl` for actions that aren't plain CRUD on a manifest.

Q: How do you open a VM's serial or graphical console from the command line?
A: `virtctl console <vm-name>` attaches to the VM's **serial console**; `virtctl vnc <vm-name>` opens a **graphical VNC** console. Both proxy through the KubeVirt API, so no direct node/hypervisor access is needed. The Harvester UI exposes the same VNC and serial consoles.

Q: How do you upload a local disk image into the cluster with virtctl?
A: `virtctl image-upload` streams a local disk image into a PVC/DataVolume backed by Harvester storage. Alternatively, create a `VirtualMachineImage` that **downloads from a URL** or accepts an **upload** from the UI — both source types are supported.

Q: What is the official Harvester Terraform provider used for?
A: The **harvester/harvester** provider manages Harvester as **Infrastructure-as-Code**. Resources include `harvester_virtualmachine`, `harvester_image`, `harvester_volume`, `harvester_network`, `harvester_ssh_key`, `harvester_clusternetwork`, `harvester_vlanconfig`, and `harvester_cloudinit_secret`.

Q: How does the Harvester Terraform provider authenticate to the cluster?
A: You configure the `provider "harvester"` block with the cluster **kubeconfig** (the one downloaded from the UI). Terraform then talks to the Harvester Kubernetes API and reconciles the CRD-backed resources declared in your `.tf` files.

Q: Why can you drive SUSE Virtualization with GitOps tools like Fleet or Argo CD?
A: Because its resources are **CRDs**, a GitOps controller (Fleet or Argo CD) can reconcile `VirtualMachine`, `VirtualMachineImage`, and network manifests straight from Git — exactly as it would manage any other Kubernetes object, giving declarative, versioned VM infrastructure.

Q: How do you inject configuration into a VM at first boot?
A: Via **cloud-init** — Harvester stores the user-data and network-data in a cloud-init secret referenced by the VM. You define users, SSH keys, packages, and run-commands, and the guest's cloud-init applies them on first boot. Terraform exposes this as `harvester_cloudinit_secret`.

Q: Where do the API tokens/credentials for scripting Harvester come from?
A: From the **kubeconfig**, which carries the client certificate or token that authenticates to the Harvester API. When Harvester is imported into Rancher, you can instead use a Rancher-issued kubeconfig or API token scoped to that downstream cluster.

Q: How would you script a bulk stop of every VM in a namespace?
A: Loop over the CRDs with kubectl, e.g. `kubectl get vm -n <ns> -o name | xargs -n1 -I{} virtctl stop -n <ns> {}`, or patch `spec.running=false` on each `VirtualMachine`. Because VMs are CRDs, label selectors (`-l app=web`) let you target subsets for bulk operations.
