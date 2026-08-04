#!/usr/bin/env python3
"""Verify that production serves the exact local corpus release."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST_URL = "https://oraculo-corpus.vercel.app/oraculo/manifest.json"
LOCAL_META = ROOT / "ios" / "Shared" / "Resources" / "corpus_bundled_meta.json"


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def validate_release(
    manifest: dict,
    body: bytes,
    *,
    expected_version: int,
    expected_sha: str,
    expected_count: int,
    expected_phrases: dict[str, str],
) -> list[str]:
    errors: list[str] = []
    remote_version = manifest.get("corpusVersion")
    manifest_sha = str(manifest.get("phrases", {}).get("sha256", "")).lower()
    actual_sha = sha256_hex(body)

    if remote_version != expected_version:
        errors.append(f"corpus version mismatch: expected {expected_version}, got {remote_version}")
    if manifest_sha != expected_sha.lower():
        errors.append(f"manifest SHA mismatch: expected {expected_sha.lower()}, got {manifest_sha}")
    if actual_sha != manifest_sha:
        errors.append(f"payload SHA mismatch: manifest {manifest_sha}, downloaded {actual_sha}")

    try:
        phrases = json.loads(body.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        return errors + [f"phrases payload is not valid UTF-8 JSON: {error}"]

    if not isinstance(phrases, list) or not phrases:
        return errors + ["phrases payload must be a non-empty array"]
    if len(phrases) != expected_count:
        errors.append(f"phrase count mismatch: expected {expected_count}, got {len(phrases)}")

    actual_phrases = {
        str(entry.get("id")): str(entry.get("text"))
        for entry in phrases
        if isinstance(entry, dict)
    }
    for phrase_id, expected_text in expected_phrases.items():
        actual_text = actual_phrases.get(phrase_id)
        if actual_text != expected_text:
            errors.append(
                f"{phrase_id} mismatch: expected {expected_text!r}, got {actual_text!r}"
            )
    return errors


def fetch(url: str, timeout: int) -> bytes:
    request = urllib.request.Request(url, headers={"Cache-Control": "no-cache"})
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return response.read()


def parse_expected_phrase(raw: str) -> tuple[str, str]:
    phrase_id, separator, text = raw.partition("=")
    if not separator or not phrase_id or not text:
        raise argparse.ArgumentTypeError("expected phrase must use ID=TEXT")
    return phrase_id, text


def main() -> int:
    local_meta = json.loads(LOCAL_META.read_text(encoding="utf-8"))
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest-url", default=DEFAULT_MANIFEST_URL)
    parser.add_argument("--expected-version", type=int, default=local_meta["corpusVersion"])
    parser.add_argument("--expected-sha", default=local_meta["phrasesSHA256"])
    parser.add_argument("--expected-count", type=int, default=local_meta["phraseCount"])
    parser.add_argument("--expect", action="append", default=[], type=parse_expected_phrase)
    parser.add_argument("--attempts", type=int, default=1)
    parser.add_argument("--interval", type=float, default=20.0)
    parser.add_argument("--timeout", type=int, default=30)
    args = parser.parse_args()

    expected_phrases = dict(args.expect)
    last_errors: list[str] = []
    for attempt in range(1, max(1, args.attempts) + 1):
        try:
            manifest = json.loads(fetch(args.manifest_url, args.timeout).decode("utf-8"))
            phrases_url = manifest.get("phrases", {}).get("url")
            if not isinstance(phrases_url, str) or not phrases_url:
                last_errors = ["manifest is missing phrases.url"]
            else:
                body = fetch(phrases_url, max(args.timeout, 60))
                last_errors = validate_release(
                    manifest,
                    body,
                    expected_version=args.expected_version,
                    expected_sha=args.expected_sha,
                    expected_count=args.expected_count,
                    expected_phrases=expected_phrases,
                )
        except (OSError, UnicodeDecodeError, json.JSONDecodeError, urllib.error.URLError) as error:
            last_errors = [f"production request failed: {error}"]

        if not last_errors:
            print(f"OK: production corpus v{args.expected_version} matches local release")
            print(f"  phrases count = {args.expected_count}")
            print(f"  sha256 = {args.expected_sha.lower()}")
            if expected_phrases:
                print(f"  expected phrases = {len(expected_phrases)}")
            return 0

        if attempt < max(1, args.attempts):
            print(f"Attempt {attempt}/{args.attempts} not ready:")
            for error in last_errors:
                print(f"  - {error}")
            time.sleep(max(0, args.interval))

    print("FAIL: production corpus does not match the expected local release")
    for error in last_errors:
        print(f"  - {error}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
