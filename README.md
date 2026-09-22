# learn-suse-virtualization

Open-source **Anki flashcards for learning SUSE Virtualization** — the SUSE
hyperconverged-infrastructure (HCI) product formerly and still known upstream as
**Harvester**. It runs virtual machines on Kubernetes using KubeVirt, with
distributed storage from SUSE Storage (Longhorn), and integrates with Rancher.

The deck is a **deep dive** (150+ cards) aimed at people who already know Kubernetes.
It deliberately contains **no Kubernetes basics** — it covers what is specific to SUSE
Virtualization / Harvester: architecture, VM lifecycle, live migration & HA, networking,
storage, backup/restore, Rancher integration, upgrades, observability, CRDs/internals,
tooling, and troubleshooting.

> Content targets **SUSE Virtualization v1.7** (the latest GA line) and is based on the
> official documentation. It is a community learning aid, not an official SUSE product.
> Docs: <https://documentation.suse.com/cloudnative/virtualization/> and
> <https://docs.harvesterhci.io/>.

## Get the deck

**Option A — one-click `.apkg` (recommended).** Download
`dist/learn-suse-virtualization.apkg` (built by CI and attached to
[Releases](../../releases)), then in Anki: **File → Import** and pick the file. It creates
a "SUSE Virtualization" deck with all cards tagged `suse-virtualization` plus a per-topic
tag.

**Option B — plain TSV.** Import `dist/learn-suse-virtualization.tsv` via **File → Import**
with:
- Field separator: **Tab**
- **Allow HTML in fields:** on
- Field mapping: 1 → Front, 2 → Back, 3 → **Tags**

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

## License

[MIT](LICENSE) — content and scripts. Corrections and additions welcome.
