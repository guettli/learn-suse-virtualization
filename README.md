# learn-suse-virtualization

[![build-deck](https://github.com/guettli/learn-suse-virtualization/actions/workflows/build.yml/badge.svg)](https://github.com/guettli/learn-suse-virtualization/actions/workflows/build.yml)
[![latest release](https://img.shields.io/github/v/release/guettli/learn-suse-virtualization)](https://github.com/guettli/learn-suse-virtualization/releases/latest)

Open-source **Anki flashcards for learning the SUSE cloud-native stack** (and the VMware
terminology you'll want when migrating to it). Each subject is a separate importable Anki
deck. The SUSE decks are **deep dives** aimed at people who already know Kubernetes — they
deliberately contain **no Kubernetes basics**, only what is specific to each product.

| Deck | What it covers | Download |
|------|----------------|----------|
| **SUSE Virtualization** | The SUSE HCI product (upstream **Harvester**) — VMs on Kubernetes via KubeVirt, SUSE Storage/Longhorn, networking, backup, upgrades, GPU passthrough, and more. Targets **v1.7**. | [**learn-suse-virtualization.apkg**](https://github.com/guettli/learn-suse-virtualization/releases/latest/download/learn-suse-virtualization.apkg) |
| **Rancher** | The SUSE **Rancher** suite — multi-cluster management, provisioning, Fleet GitOps, auth/RBAC, projects, Apps, monitoring/logging/backup, RKE2 & K3s, NeuVector, Elemental. | [**learn-rancher.apkg**](https://github.com/guettli/learn-suse-virtualization/releases/latest/download/learn-rancher.apkg) |
| **VMware** | **VMware vSphere** terminology & concepts — ESXi, vCenter, VMs, DRS/HA, vMotion, storage/VMFS/vSAN, vSS/vDS networking, NSX, snapshots/templates, resource management, products/editions — plus migrating to SUSE Virtualization. Handy when coming from VMware. | [**learn-vmware.apkg**](https://github.com/guettli/learn-suse-virtualization/releases/latest/download/learn-vmware.apkg) |

> Community learning aids based on the official documentation — not official SUSE products.
> Sources: <https://documentation.suse.com/cloudnative/virtualization/>,
> <https://docs.harvesterhci.io/>, and <https://ranchermanager.docs.rancher.com/>.

## Get a deck

**One-click `.apkg` (recommended).** Download a deck from the table above (the links always
point at the newest release — no login required), then in Anki choose **File → Import** and
pick the file. Every card is tagged by subject (`suse-virtualization` or `rancher`) plus a
per-topic tag.

**Plain TSV alternative.** Each deck also ships a `.tsv` on the
[latest release](https://github.com/guettli/learn-suse-virtualization/releases/latest)
(e.g. `learn-rancher.tsv`). Import via **File → Import** with separator **Tab**, **Allow HTML
in fields** on, and field mapping 1 → Front, 2 → Back, 3 → **Tags**.

Re-importing an updated deck **updates** existing cards instead of duplicating them, because
each card has a stable GUID derived from its question text.

## Build it yourself

```bash
pip install -r requirements.txt
python build.py
# -> dist/learn-suse-virtualization.apkg (+ .tsv)
# -> dist/learn-rancher.apkg (+ .tsv)
```

## Contribute

Cards live under [`cards/<subject>/`](cards/), one Markdown file per topic. Format:

```markdown
# Topic Title            (H1 becomes the card's tag)

Q: A question on one line
A: An answer, which may span multiple lines and use **Markdown**
(lists, `code`, tables) until the next `Q:` or end of file.

Q: Next question
A: ...
```

Add or fix a card, run `python build.py` to verify it compiles, and open a PR. Keep questions
atomic (one idea per card) and answers concise but complete. To add a **new subject/deck**,
create a `cards/<new-subject>/` folder and register it in the `DECKS` map in
[`build.py`](build.py) with its own stable `deck_id`/`model_id`.

## Releasing

Releases are cut automatically by CI when the version changes. The version lives in the
[`VERSION`](VERSION) file (semver).

1. Bump `VERSION` in your PR (e.g. `0.2.1` → `0.3.0`).
2. Merge to `main`.
3. CI builds every deck and, seeing a version with no matching tag, creates tag `vX.Y.Z` and a
   **GitHub Release** with each deck's `.apkg` and `.tsv` attached.

Merges that don't touch `VERSION` just build and validate — no duplicate release. Built files
are **not** committed; they live only on Releases (and as CI artifacts on PRs).

## License

[MIT](LICENSE) — content and scripts. Corrections and additions welcome.
