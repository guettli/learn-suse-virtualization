# Images & Cloud-Init

Q: What is a VirtualMachineImage in Harvester?
A: A **VirtualMachineImage** is a Harvester CRD that represents a golden OS image used as the source for VM boot disks. When you create a VM, its root volume is cloned from the image rather than downloaded again, so many VMs can share one prepared image. It has a `displayName`, a `sourceType`, an optional `checksum`, and a target storage backend.

Q: What are the three source types for creating a VirtualMachineImage?
A: The `sourceType` field selects how the image is obtained:
- **download** — Harvester pulls the file from an HTTP(S) `url`.
- **upload** — you push a local file to the image's upload endpoint.
- **export-from-volume** — a new image is created from the data of an existing Longhorn volume/PVC.

Q: What does the export-from-volume source type let you do?
A: **export-from-volume** creates a VirtualMachineImage from the current contents of an existing volume (PVC). This is how you "golden-image" a VM you have already customized: prepare one VM, export its disk to an image, then clone new VMs from that image.

Q: What are the two image backends in Harvester and when is each used?
A: - **Longhorn backing image** (default) — used with the Longhorn **V1** data engine; Harvester generates a per-image StorageClass that inherits replica count and node/disk selectors.
- **CDI** (Containerized Data Importer), set via `backend: cdi` — required for the Longhorn **V2** data engine, **LVM**, and **third-party CSI** storage; it imports the image into a golden PVC in the chosen StorageClass.

Q: Which disk image formats can a VirtualMachineImage use?
A: Harvester supports **qcow2**, **raw**, and **ISO** images. qcow2 and raw are used as bootable OS disks (cloud images), while ISO is installation/optical media attached as a CD-ROM. Harvester detects the virtual size and requires the target volume to be at least as large as the image.

Q: What does the targetStorageClassName field control on an image?
A: **targetStorageClassName** (used with the CDI backend) selects which StorageClass — and therefore which storage backend, e.g. a third-party CSI or Longhorn V2 — stores the golden image PVC. It **cannot be changed after the image is created**, so the backend choice is fixed at creation time.

Q: How does Harvester speed up VM boot from a shared image?
A: With the Longhorn backing-image backend, the image is downloaded/uploaded once and then **cached as a backing image on nodes**. New VM disks are thin clones layered on top of that cached backing image, so subsequent VMs boot quickly without re-fetching or fully copying the OS data.

Q: How are SSH public keys injected into a Linux VM?
A: SSH keys are delivered through **cloud-init user-data**. In the Harvester UI you select or upload keys in the **SSH Keys** field on the VM's Basics tab; Harvester adds them to the user-data so the guest's cloud-init writes them to the user's `authorized_keys` at first boot. No manual login is required to enable key-based access.

Q: Why are cloud images preferred over ISOs for Linux VMs?
A: **Cloud images** (qcow2/raw) ship pre-installed with the OS and the **cloud-init** agent, so they boot straight to a configured system and accept user-data/network-data automatically. An ISO is bare install media that would require an interactive, manual OS installation, so cloud images give unattended, reproducible provisioning.

Q: How do you install a guest from an ISO in Harvester?
A: Attach the ISO as a **cd-rom** type volume and add a blank **disk** volume for the target. Use **bootOrder** so the VM boots the CD-ROM first, run the installer onto the disk, then set the disk's boot order ahead of the CD-ROM so later boots come from the installed system. ISO-backed (and CD-ROM) volumes are not live-migratable.
