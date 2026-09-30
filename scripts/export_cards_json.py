#!/usr/bin/env python3
"""Export all decks in cards/ to a JSON file formatted for the Flutter mobile app.

Generates:
  - Cleaned text for TTS (removing markdown tags, backticks, asterisks, URLs)
  - Raw markdown for display
  - Stable card IDs matching build.py
"""
from __future__ import annotations

import hashlib
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CARDS_DIR = ROOT / "cards"
OUT_FILE = ROOT / "app" / "assets" / "cards.json"

DECKS = {
    "suse-virtualization": {
        "name": "SUSE Virtualization",
        "description": "Harvester HCI, KubeVirt, Longhorn, VM lifecycle",
        "legacy_guid": True,
    },
    "rancher": {
        "name": "Rancher",
        "description": "Multi-cluster management, Fleet, RKE2/K3s, NeuVector",
        "legacy_guid": False,
    },
    "vmware": {
        "name": "VMware",
        "description": "vSphere terminology, ESXi, vCenter, DRS/HA, vMotion",
        "legacy_guid": False,
    },
}

CARD_RE = re.compile(r"^Q:\s*(.*)$", re.MULTILINE)


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.strip().lower()).strip("-")


def clean_for_tts(text: str) -> str:
    """Clean markdown formatting for natural Text-To-Speech pronunciation."""
    # Remove code blocks
    s = re.sub(r"```[\w-]*\n(.*?)```", r"\1", text, flags=re.DOTALL)
    # Remove inline code backticks
    s = re.sub(r"`([^`]+)`", r"\1", s)
    # Replace markdown links [label](url) with just label
    s = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", s)
    # Remove raw URLs
    s = re.sub(r"https?://\S+", "", s)
    # Remove bold / italic markers
    s = re.sub(r"\*\*([^*]+)\*\*", r"\1", s)
    s = re.sub(r"\*([^*]+)\*", r"\1", s)
    s = re.sub(r"__([^_]+)__", r"\1", s)
    s = re.sub(r"_([^_]+)_", r"\1", s)
    # Remove markdown table separator lines like |---|---|
    s = re.sub(r"^\|[-:\s|]+\|$", "", s, flags=re.MULTILINE)

    # Convert list bullets and tables to natural sentences
    lines = []
    for line in s.splitlines():
        line = line.strip()
        if not line:
            continue
        # Table row: | cell1 | cell2 |
        if line.startswith("|") and line.endswith("|"):
            cells = [c.strip() for c in line.split("|") if c.strip()]
            if cells:
                content = ", ".join(cells)
                if not content.endswith((".", "!", "?", ";", ":")):
                    content += "."
                lines.append(content)
            continue
        # Numbered list: "1. item" -> "1: item."
        m_num = re.match(r"^(\d+)\.\s+(.*)", line)
        if m_num:
            num, content = m_num.groups()
            if not content.endswith((".", "!", "?", ";", ":")):
                content += "."
            lines.append(f"{num}: {content}")
            continue
        # Bullet list: "- item" or "* item"
        m_bullet = re.match(r"^[-*]\s+(.*)", line)
        if m_bullet:
            content = m_bullet.group(1)
            if not content.endswith((".", "!", "?", ";", ":")):
                content += "."
            lines.append(content)
            continue
        lines.append(line)

    result = " ".join(lines)
    # Normalize multiple whitespace
    result = re.sub(r"\s+", " ", result).strip()
    return result


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


def export_decks():
    data = {
        "version": 1,
        "decks": {},
    }

    total_cards = 0
    for slug, meta in DECKS.items():
        subject_dir = CARDS_DIR / slug
        if not subject_dir.is_dir():
            continue

        deck_cards = []
        seen_q = set()

        for path in sorted(subject_dir.glob("*.md")):
            tag, cards = parse_file(path)
            for question, answer in cards:
                key = question.strip().lower()
                if key in seen_q:
                    continue
                seen_q.add(key)

                guid_src = key if meta["legacy_guid"] else f"{slug}::{key}"
                card_id = hashlib.sha1(guid_src.encode()).hexdigest()[:16]

                deck_cards.append({
                    "id": card_id,
                    "deck_slug": slug,
                    "tag": tag,
                    "question": question,
                    "answer": answer,
                    "spoken_question": clean_for_tts(question),
                    "spoken_answer": clean_for_tts(answer),
                })
                total_cards += 1

        data["decks"][slug] = {
            "slug": slug,
            "name": meta["name"],
            "description": meta["description"],
            "total_cards": len(deck_cards),
            "cards": deck_cards,
        }

    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    OUT_FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Exported {total_cards} cards across {len(data['decks'])} decks to {OUT_FILE.relative_to(ROOT)}")


if __name__ == "__main__":
    export_decks()
