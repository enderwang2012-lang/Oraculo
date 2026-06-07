#!/usr/bin/env python3
"""模拟 App 热更新：拉 manifest → 校验版本与 SHA256 → 下载 phrases。"""
from __future__ import annotations

import hashlib
import json
import sys
import urllib.request

MANIFEST_URL = "https://oraculo-corpus.vercel.app/oraculo/manifest.json"
SIMULATED_LOCAL_VERSION = 1


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> int:
    print(f"GET {MANIFEST_URL}")
    with urllib.request.urlopen(MANIFEST_URL, timeout=30) as resp:
        manifest = json.loads(resp.read().decode("utf-8"))

    remote_v = manifest["corpusVersion"]
    print(f"  remote corpusVersion = {remote_v}")
    print(f"  simulated bundled/applied = {SIMULATED_LOCAL_VERSION}")

    if remote_v <= SIMULATED_LOCAL_VERSION:
        print("FAIL: remote version not newer than local")
        return 1

    phrases_url = manifest["phrases"]["url"]
    expected = manifest["phrases"]["sha256"].lower()
    print(f"GET {phrases_url}")
    with urllib.request.urlopen(phrases_url, timeout=60) as resp:
        body = resp.read()

    actual = sha256_hex(body)
    if actual != expected:
        print(f"FAIL: sha256 mismatch\n  expected {expected}\n  actual   {actual}")
        return 1

    phrases = json.loads(body.decode("utf-8"))
    if not isinstance(phrases, list) or not phrases:
        print("FAIL: phrases.json empty or not an array")
        return 1

    notes = manifest.get("releaseNotes") or "(none)"
    print(f"  phrases count = {len(phrases)}")
    print(f"  sha256 OK")
    print(f"  releaseNotes = {notes}")
    print("OK: hot-update CDN path verified (client would download v2)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
