#!/usr/bin/env python3
"""Validate corpus source consistency before rebuilding."""
from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "starbucks_now_passphrases.csv"
EN_MAP = ROOT / "scripts" / "phrases_en.json"
DISPATCH_MAP = ROOT / "scripts" / "phrase_dispatch.json"
OVERLAY = ROOT / "config" / "phrase_context_tags.json"
FRESHNESS = ROOT / "config" / "phrase_freshness_tags.json"
DELETIONS = ROOT / "scripts" / "corpus_deletions.json"


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def load_rows() -> list[dict]:
    with SOURCE.open(encoding="utf-8") as handle:
        return [row for row in csv.DictReader(handle) if row.get("phrase", "").strip()]


def deletion_ids(raw: object) -> set[str]:
    if isinstance(raw, dict):
        values = raw.get("ids", raw.get("deleted", []))
    else:
        values = raw if isinstance(raw, list) else []
    ids: set[str] = set()
    for value in values:
        text = str(value)
        ids.add(text if text.startswith("sb_") else f"sb_{text}")
    return ids


def main() -> None:
    rows = load_rows()
    ids = [f"sb_{row['id'].strip()}" for row in rows]
    phrases = [row["phrase"].strip() for row in rows]
    en_map = load_json(EN_MAP)
    dispatch_map = load_json(DISPATCH_MAP)
    overlay_map = load_json(OVERLAY)
    freshness_map = load_json(FRESHNESS)
    deleted = deletion_ids(load_json(DELETIONS))

    errors: list[str] = []
    warnings: list[str] = []

    id_counts = Counter(ids)
    phrase_counts = Counter(phrases)
    duplicate_ids = sorted(pid for pid, count in id_counts.items() if count > 1)
    duplicate_phrases = sorted(text for text, count in phrase_counts.items() if count > 1)
    if duplicate_ids:
        errors.append("Duplicate ids: " + ", ".join(duplicate_ids))
    if duplicate_phrases:
        errors.append("Duplicate phrases: " + ", ".join(duplicate_phrases))

    missing_en = [pid for pid in ids if not str(en_map.get(pid, "")).strip()]
    missing_dispatch = [pid for pid in ids if pid not in dispatch_map]
    missing_overlay = [pid for pid in ids if pid not in overlay_map]
    missing_freshness = [pid for pid in ids if pid not in freshness_map]
    deleted_present = sorted(set(ids) & deleted, key=lambda pid: int(pid.split("_", 1)[1]))

    if missing_en:
        errors.append("Missing English translations: " + ", ".join(missing_en))
    if missing_dispatch:
        warnings.append("Missing dispatch before rebuild: " + ", ".join(missing_dispatch))
    if missing_overlay:
        warnings.append("Missing overlay before rebuild: " + ", ".join(missing_overlay))
    if missing_freshness:
        warnings.append("Missing freshness before rebuild: " + ", ".join(missing_freshness))
    if deleted_present:
        errors.append("Deleted ids present in CSV: " + ", ".join(deleted_present))

    print(f"Corpus rows: {len(rows)}")
    print(f"English entries: {len(en_map)}")
    print(f"Dispatch entries: {len(dispatch_map)}")
    print(f"Overlay entries: {len(overlay_map)}")
    print(f"Freshness entries: {len(freshness_map)}")

    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)

    print("✅ Corpus source validation passed")


if __name__ == "__main__":
    main()
