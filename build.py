#!/usr/bin/env python3
"""Compile cards/<subject>/*.md into one Anki .apkg + TSV per subject.

Layout:

    cards/
      suse-virtualization/   # one deck
        01-architecture.md   # H1 -> per-card tag; Q:/A: blocks
        ...
      rancher/               # another deck
        ...

Each subject is registered in DECKS below with a STABLE deck_id / model_id so
re-importing updates the existing deck instead of creating a new one. Card GUIDs
are derived from the question text so re-importing an updated deck UPDATES cards
rather than duplicating them.

Source format inside each file:

    # Topic Title            <- H1, becomes the card tag (slugified)

    Q: A question on one line
    A: An answer that may span multiple lines and use **Markdown**
    (lists, `code`, tables) until the next `Q:` or EOF.
"""
from __future__ import annotations

import hashlib
import pathlib
import re
import sys

import genanki
import markdown as md

ROOT = pathlib.Path(__file__).resolve().parent
CARDS_DIR = ROOT / "cards"
DIST_DIR = ROOT / "dist"

# Registered decks. IDs are FIXED — never change them for an existing deck or
# Anki will treat re-imports as a brand-new deck. `legacy_guid` keeps the very
# first deck's original GUID scheme (bare question hash) so already-shipped
# cards keep their identity; new decks namespace the GUID by slug to avoid any
# cross-deck collision in a shared collection.
DECKS = {
    "suse-virtualization": {
        "name": "SUSE Virtualization",
        "deck_id": 1728394650123,
        "model_id": 1728394650999,
        "out": "learn-suse-virtualization",
        "legacy_guid": True,
    },
    "rancher": {
        "name": "Rancher",
        "deck_id": 1758600001111,
        "model_id": 1758600009999,
        "out": "learn-rancher",
        "legacy_guid": False,
    },
}

CARD_CSS = (
    ".card{font-family:-apple-system,Segoe UI,Roboto,sans-serif;"
    "font-size:18px;line-height:1.5;text-align:left;padding:16px;"
    "max-width:52em;margin:0 auto}"
    "code{background:rgba(128,128,128,0.22);color:inherit;padding:1px 4px;"
    "border-radius:4px;font-size:0.9em;"
    "font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}"
    "pre{background:rgba(128,128,128,0.16);border-radius:6px;overflow-x:auto}"
    "pre code{display:block;padding:10px;background:none}"
    "hr#answer{margin:14px 0;border:0;border-top:1px solid rgba(128,128,128,0.5)}"
    "ul,ol{margin:6px 0 6px 22px}"
    "table{border-collapse:collapse}"
    "th,td{border:1px solid rgba(128,128,128,0.5);padding:4px 8px}"
)

CARD_RE = re.compile(r"^Q:\s*(.*)$", re.MULTILINE)


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.strip().lower()).strip("-")


def make_model(spec) -> genanki.Model:
    return genanki.Model(
        spec["model_id"],
        f"{spec['name']} Q&A",
        fields=[{"name": "Front"}, {"name": "Back"}],
        templates=[
            {
                "name": "Card 1",
                "qfmt": "{{Front}}",
                "afmt": '{{FrontSide}}<hr id="answer">{{Back}}',
            }
        ],
        css=CARD_CSS,
    )


def parse_file(path: pathlib.Path):
    """Return (tag, [(question, answer_markdown), ...]) for one file."""
    text = path.read_text(encoding="utf-8")
    tag = slugify(path.stem)
    h1 = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    if h1:
        tag = slugify(h1.group(1))

    cards = []
    matches = list(CARD_RE.finditer(text))
    for i, m in enumerate(matches):
        question = m.group(1).strip()
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        body = text[start:end]
        am = re.search(r"A:\s*(.*)", body, re.DOTALL)
        if not am:
            raise ValueError(f"{path}: 'Q:' without matching 'A:' near: {question[:60]!r}")
        answer = re.split(r"\n#\s+", am.group(1).strip())[0].strip()
        if question and answer:
            cards.append((question, answer))
    return tag, cards


def to_html(text: str) -> str:
    return md.markdown(text, extensions=["fenced_code", "tables", "sane_lists"])


def oneline(s: str) -> str:
    return s.replace("\t", " ").replace("\n", " ").strip()


def build_deck(slug: str, spec: dict) -> int:
    subject_dir = CARDS_DIR / slug
    model = make_model(spec)
    deck = genanki.Deck(spec["deck_id"], spec["name"])
    tsv_rows = []
    seen_q = set()
    total = 0

    for path in sorted(subject_dir.glob("*.md")):
        tag, cards = parse_file(path)
        for question, answer in cards:
            key = question.strip().lower()
            if key in seen_q:
                print(f"WARNING: duplicate question skipped in {slug}/{path.name}: "
                      f"{question[:70]}", file=sys.stderr)
                continue
            seen_q.add(key)

            front = to_html(question)
            back = to_html(answer)
            guid_src = key if spec.get("legacy_guid") else f"{slug}::{key}"
            note = genanki.Note(
                model=model,
                fields=[front, back],
                tags=[slug, tag],
                guid=genanki.guid_for(hashlib.sha1(guid_src.encode()).hexdigest()),
            )
            deck.add_note(note)
            tsv_rows.append(f"{oneline(front)}\t{oneline(back)}\t{slug} {tag}")
            total += 1

    apkg = DIST_DIR / f"{spec['out']}.apkg"
    tsv = DIST_DIR / f"{spec['out']}.tsv"
    genanki.Package(deck).write_to_file(str(apkg))
    tsv.write_text("\n".join(tsv_rows) + "\n", encoding="utf-8")
    print(f"[{slug}] {total} cards -> {apkg.relative_to(ROOT)}, {tsv.relative_to(ROOT)}")
    return total


def main() -> int:
    if not CARDS_DIR.is_dir():
        print(f"No cards directory at {CARDS_DIR}", file=sys.stderr)
        return 1
    DIST_DIR.mkdir(exist_ok=True)

    # Every subject subdirectory that holds cards must be registered.
    subjects = sorted(p.name for p in CARDS_DIR.iterdir()
                      if p.is_dir() and any(p.glob("*.md")))
    unknown = [s for s in subjects if s not in DECKS]
    if unknown:
        print(f"ERROR: unregistered card subject(s): {unknown}. "
              f"Add them to DECKS in build.py.", file=sys.stderr)
        return 1

    grand = 0
    for slug in subjects:
        grand += build_deck(slug, DECKS[slug])
    print(f"Built {grand} cards across {len(subjects)} deck(s): {', '.join(subjects)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
