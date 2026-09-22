#!/usr/bin/env python3
"""Compile cards/*.md into an Anki .apkg and a plain TSV.

Source format (one file per topic):

    # Topic Title            <- H1, becomes the card tag (slugified)

    Q: A question on one line
    A: An answer that may span
    multiple lines and use **Markdown**
    (lists, `code`, etc.) until the next `Q:` or EOF.

    Q: Next question
    A: ...

Every card gets a stable GUID derived from its question text, so re-importing an
updated deck UPDATES existing cards in Anki instead of creating duplicates.
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

DECK_NAME = "SUSE Virtualization"
DECK_ID = 1728394650123  # fixed: keep stable across builds
MODEL_ID = 1728394650999  # fixed: keep stable across builds
GLOBAL_TAG = "suse-virtualization"

MODEL = genanki.Model(
    MODEL_ID,
    "SUSE Virtualization Q&A",
    fields=[{"name": "Front"}, {"name": "Back"}],
    templates=[
        {
            "name": "Card 1",
            "qfmt": "{{Front}}",
            "afmt": '{{FrontSide}}<hr id="answer">{{Back}}',
        }
    ],
    css=(
        ".card{font-family:-apple-system,Segoe UI,Roboto,sans-serif;"
        "font-size:18px;line-height:1.5;color:#1a1a1a;background:#fff;"
        "text-align:left;padding:16px;max-width:52em;margin:0 auto}"
        "code{background:#f0f0f0;padding:1px 4px;border-radius:4px;"
        "font-size:0.9em}"
        "pre code{display:block;padding:10px;overflow-x:auto}"
        "hr#answer{margin:14px 0;border:0;border-top:1px solid #ccc}"
        "ul,ol{margin:6px 0 6px 22px}"
    ),
)

CARD_RE = re.compile(r"^Q:\s*(.*)$", re.MULTILINE)


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.strip().lower()).strip("-")


def parse_file(path: pathlib.Path):
    """Yield (question, answer_markdown) tuples and the file's tag."""
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
            raise ValueError(f"{path.name}: 'Q:' without matching 'A:' near: {question[:60]!r}")
        answer = am.group(1).strip()
        # Drop a trailing heading that belongs to the next section, if any.
        answer = re.split(r"\n#\s+", answer)[0].strip()
        if question and answer:
            cards.append((question, answer))
    return tag, cards


def to_html(text: str) -> str:
    return md.markdown(text, extensions=["fenced_code", "tables", "sane_lists"])


def main() -> int:
    if not CARDS_DIR.is_dir():
        print(f"No cards directory at {CARDS_DIR}", file=sys.stderr)
        return 1
    DIST_DIR.mkdir(exist_ok=True)

    deck = genanki.Deck(DECK_ID, DECK_NAME)
    tsv_rows = []
    seen_q = set()
    total = 0

    for path in sorted(CARDS_DIR.glob("*.md")):
        tag, cards = parse_file(path)
        for question, answer in cards:
            key = question.strip().lower()
            if key in seen_q:
                print(f"WARNING: duplicate question skipped in {path.name}: {question[:70]}",
                      file=sys.stderr)
                continue
            seen_q.add(key)

            front = to_html(question)
            back = to_html(answer)
            guid = genanki.guid_for(hashlib.sha1(key.encode()).hexdigest())
            note = genanki.Note(
                model=MODEL,
                fields=[front, back],
                tags=[GLOBAL_TAG, tag],
                guid=guid,
            )
            deck.add_note(note)

            # TSV: single-line HTML fields; Anki treats \t as field sep.
            def oneline(s: str) -> str:
                return s.replace("\t", " ").replace("\n", " ").strip()

            tsv_rows.append(f"{oneline(front)}\t{oneline(back)}\t{GLOBAL_TAG} {tag}")
            total += 1

    apkg_path = DIST_DIR / "learn-suse-virtualization.apkg"
    tsv_path = DIST_DIR / "learn-suse-virtualization.tsv"

    genanki.Package(deck).write_to_file(str(apkg_path))
    tsv_path.write_text("\n".join(tsv_rows) + "\n", encoding="utf-8")

    print(f"Built {total} cards")
    print(f"  -> {apkg_path.relative_to(ROOT)}")
    print(f"  -> {tsv_path.relative_to(ROOT)}")
    if total < 150:
        print(f"NOTE: only {total} cards (<150).", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
