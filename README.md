# learn-suse-virtualization

[![build-deck](https://github.com/guettli/learn-suse-virtualization/actions/workflows/build.yml/badge.svg)](https://github.com/guettli/learn-suse-virtualization/actions/workflows/build.yml)
[![latest release](https://img.shields.io/github/v/release/guettli/learn-suse-virtualization)](https://github.com/guettli/learn-suse-virtualization/releases/latest)

Open-source **Anki flashcards for learning SUSE Virtualization** — the SUSE
hyperconverged-infrastructure (HCI) product formerly and still known upstream as
**Harvester**. It runs virtual machines on Kubernetes using KubeVirt, with
distributed storage from SUSE Storage (Longhorn), and integrates with Rancher.

The deck is a **deep dive** (250+ cards) aimed at people who already know Kubernetes.
It deliberately contains **no Kubernetes basics** — it covers what is specific to SUSE
Virtualization / Harvester: architecture, installation & nodes, VM lifecycle, live migration
& HA, images & cloud-init, networking, storage, backup/restore, Rancher integration, upgrades,
observability, CRDs/internals, CLI/API/Terraform, troubleshooting, security & RBAC, and
device/GPU passthrough.

> Content targets **SUSE Virtualization v1.7** (the latest GA line) and is based on the
> official documentation. It is a community learning aid, not an official SUSE product.
> Docs: <https://documentation.suse.com/cloudnative/virtualization/> and
> <https://docs.harvesterhci.io/>.

## Get the deck

**One-click `.apkg` (recommended).** Download the latest deck — no login required:

**➡️ [learn-suse-virtualization.apkg](https://github.com/guettli/learn-suse-virtualization/releases/latest/download/learn-suse-virtualization.apkg)**

Then in Anki: **File → Import** and pick the file. It creates a "SUSE Virtualization" deck
with every card tagged `suse-virtualization` plus a per-topic tag. Each
[release](https://github.com/guettli/learn-suse-virtualization/releases) also attaches the
same file.

**Plain TSV alternative.** Download
[`learn-suse-virtualization.tsv`](https://github.com/guettli/learn-suse-virtualization/releases/latest/download/learn-suse-virtualization.tsv)
and import via **File → Import** with: separator **Tab**, **Allow HTML in fields** on, and
field mapping 1 → Front, 2 → Back, 3 → **Tags**.

Re-importing an updated deck **updates** existing cards instead of duplicating them, because
each card has a stable GUID derived from its question text.

## Build it yourself

```bash
pip install -r requirements.txt
python build.py
# -> dist/learn-suse-virtualization.apkg
# -> dist/learn-suse-virtualization.tsv
```

## Contribute

Cards live in [`cards/`](cards/), one Markdown file per topic. Format:

```markdown
# Topic Title            (H1 becomes the card's tag)

Q: A question on one line
A: An answer, which may span multiple lines and use **Markdown**
(lists, `code`, tables) until the next `Q:` or end of file.

Q: Next question
A: ...
```

Add or fix a card, run `python build.py` to verify it compiles, and open a PR. Please keep
questions atomic (one idea per card) and answers concise but complete.

## Releasing

Releases are cut automatically by CI when the version changes. The version lives in the
[`VERSION`](VERSION) file (semver, e.g. `0.2.0`).

To publish a new deck:
1. Bump `VERSION` in your PR (e.g. `0.1.0` → `0.2.0`).
2. Merge to `main`.
3. CI builds the deck and, seeing a version with no matching tag, creates tag `vX.Y.Z` and a
   **GitHub Release** with `learn-suse-virtualization.apkg` and `.tsv` attached.

Merges that don't touch `VERSION` just build and validate — no duplicate release. The built
files are **not** committed to the repo; they live only on Releases (and as CI artifacts on
PRs).

## License

[MIT](LICENSE) — content and scripts. Corrections and additions welcome.
