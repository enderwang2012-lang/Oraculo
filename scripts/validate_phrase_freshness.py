#!/usr/bin/env python3
"""Validate phrase freshness metadata against the primary corpus."""
from __future__ import annotations

import json
import re
from pathlib import Path

from tag_phrase_freshness import OUT, load_rows

VALID_LIFECYCLES = {"new", "active", "anchor", "cooling", "retired"}
SLUG_RE = re.compile(r"^[a-z0-9_]+$")


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def validate_tags(path: Path = OUT) -> list[str]:
    tags = load_json(path)
    rows = load_rows()
    ids = {f"sb_{row['id'].strip()}" for row in rows if row.get("phrase", "").strip()}
    errors: list[str] = []

    missing = sorted(ids - set(tags), key=lambda pid: int(pid.split("_", 1)[1]))
    extra = sorted(set(tags) - ids)
    if missing:
        errors.append("Missing freshness tags: " + ", ".join(missing))
    if extra:
        errors.append("Unknown freshness tags: " + ", ".join(extra))

    for pid in sorted(ids & set(tags), key=lambda value: int(value.split("_", 1)[1])):
        entry = tags.get(pid)
        if not isinstance(entry, dict):
            errors.append(f"{pid}: freshness entry must be an object")
            continue
        semantic = str(entry.get("semanticCluster", "")).strip()
        cadence = str(entry.get("cadenceGroup", "")).strip()
        lifecycle = str(entry.get("lifecycle", "")).strip()
        if not SLUG_RE.fullmatch(semantic):
            errors.append(f"{pid}: invalid semanticCluster '{semantic}'")
        if not SLUG_RE.fullmatch(cadence):
            errors.append(f"{pid}: invalid cadenceGroup '{cadence}'")
        if lifecycle not in VALID_LIFECYCLES:
            errors.append(f"{pid}: invalid lifecycle '{lifecycle}'")
    return errors


def main() -> None:
    errors = validate_tags()
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        raise SystemExit(1)
    print("✅ Phrase freshness validation passed")


if __name__ == "__main__":
    main()
