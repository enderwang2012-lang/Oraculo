#!/usr/bin/env python3
"""Run the corpus rebuild pipeline in the correct order."""
from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VERSION_FILE = ROOT / "config" / "corpus_version.txt"
DEFAULT_BASE_URL = "https://oraculo-corpus.vercel.app/oraculo"


def run(args: list[str]) -> None:
    print("$ " + " ".join(args))
    subprocess.run(args, cwd=ROOT, check=True)


def bump_version() -> int:
    current = int(VERSION_FILE.read_text(encoding="utf-8").strip())
    next_version = current + 1
    VERSION_FILE.write_text(f"{next_version}\n", encoding="utf-8")
    print(f"Bumped corpus version: {current} -> {next_version}")
    return next_version


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bump", action="store_true", help="Increment config/corpus_version.txt before embedding")
    parser.add_argument("--publish", action="store_true", help="Publish to dist/corpus and sync public/oraculo")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="Base URL for publish_corpus_static.py")
    parser.add_argument("--skip-preflight", action="store_true", help="Skip validate_corpus.py before rebuild")
    args = parser.parse_args()

    if args.bump:
        bump_version()

    run([sys.executable, "scripts/tag_phrase_freshness.py"])

    if not args.skip_preflight:
        run([sys.executable, "scripts/validate_corpus.py"])

    run([sys.executable, "scripts/tag_phrases_rules.py"])
    run([sys.executable, "scripts/tag_phrases_llm.py"])
    run([sys.executable, "scripts/validate_dispatch.py"])
    run([sys.executable, "scripts/validate_phrase_freshness.py"])
    run([sys.executable, "scripts/embed_corpus.py"])

    if args.publish:
        run([sys.executable, "scripts/publish_corpus_static.py", "--base-url", args.base_url])

    print("✅ Corpus rebuild complete")


if __name__ == "__main__":
    main()
