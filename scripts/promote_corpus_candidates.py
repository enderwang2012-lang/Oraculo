#!/usr/bin/env python3
"""Promote accepted corpus candidates into the primary corpus CSV."""
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CANDIDATES = ROOT / "review" / "corpus_candidates.csv"
SOURCE = ROOT / "starbucks_now_passphrases.csv"
EN_MAP = ROOT / "scripts" / "phrases_en.json"
DELETIONS = ROOT / "scripts" / "corpus_deletions.json"

CANDIDATE_FIELDS = ["phrase", "theme_hint", "source_type", "source_note", "status", "rewrite_note"]


def load_json(path: Path) -> object:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def deletion_ids() -> set[int]:
    raw = load_json(DELETIONS)
    if isinstance(raw, dict):
        values = raw.get("ids", raw.get("deleted", []))
    elif isinstance(raw, list):
        values = raw
    else:
        values = []
    ids: set[int] = set()
    for value in values:
        text = str(value).removeprefix("sb_")
        if text.isdigit():
            ids.add(int(text))
    return ids


def next_id(existing: set[int], deleted: set[int]) -> int:
    candidate = max(existing or {0}) + 1
    while candidate in existing or candidate in deleted:
        candidate += 1
    return candidate


def ensure_candidate_file(path: Path) -> None:
    if path.exists():
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CANDIDATE_FIELDS)
        writer.writeheader()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--candidates", type=Path, default=DEFAULT_CANDIDATES)
    parser.add_argument("--source-id", default="USER")
    parser.add_argument("--period", default="2026")
    args = parser.parse_args()

    ensure_candidate_file(args.candidates)

    with args.candidates.open(encoding="utf-8") as handle:
        candidates = list(csv.DictReader(handle))
    with SOURCE.open(encoding="utf-8") as handle:
        corpus_rows = list(csv.DictReader(handle))
        corpus_fields = handle.name and list(corpus_rows[0].keys()) if corpus_rows else ["id", "phrase", "approx_period", "theme", "source_id", "evidence", "notes"]

    existing_ids = {int(row["id"]) for row in corpus_rows if row.get("id", "").isdigit()}
    existing_phrases = {row.get("phrase", "").strip() for row in corpus_rows}
    deleted = deletion_ids()
    en_map = load_json(EN_MAP)
    if not isinstance(en_map, dict):
        en_map = {}

    promoted: list[tuple[str, str]] = []
    skipped_duplicates: list[str] = []

    for candidate in candidates:
        if candidate.get("status", "").strip() != "accepted":
            continue
        phrase = candidate.get("phrase", "").strip()
        if not phrase:
            continue
        if phrase in existing_phrases:
            candidate["status"] = "duplicate"
            skipped_duplicates.append(phrase)
            continue
        new_id = next_id(existing_ids, deleted)
        existing_ids.add(new_id)
        existing_phrases.add(phrase)
        pid = f"sb_{new_id}"
        corpus_rows.append({
            "id": str(new_id),
            "phrase": phrase,
            "approx_period": args.period,
            "theme": candidate.get("theme_hint", "").strip() or "诗性意象",
            "source_id": candidate.get("source_type", "").strip() or args.source_id,
            "evidence": "generated" if candidate.get("source_type", "").strip() != "USER" else "user_provided",
            "notes": candidate.get("source_note", "").strip() or candidate.get("rewrite_note", "").strip(),
        })
        en_map.setdefault(pid, "TODO")
        candidate["status"] = "promoted"
        promoted.append((pid, phrase))

    with SOURCE.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=corpus_fields)
        writer.writeheader()
        writer.writerows(corpus_rows)
    with EN_MAP.open("w", encoding="utf-8") as handle:
        json.dump(en_map, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    with args.candidates.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=CANDIDATE_FIELDS)
        writer.writeheader()
        writer.writerows(candidates)

    print(f"Promoted {len(promoted)} candidates")
    for pid, phrase in promoted:
        print(f"  {pid}: {phrase}")
    if skipped_duplicates:
        print("Skipped duplicates:")
        for phrase in skipped_duplicates:
            print(f"  {phrase}")
    if promoted:
        print("Remember to replace TODO translations in scripts/phrases_en.json before rebuilding.")


if __name__ == "__main__":
    main()
