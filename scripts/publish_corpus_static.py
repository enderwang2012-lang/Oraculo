#!/usr/bin/env python3
"""生成可上传到 CDN / GitHub Pages 的静态热更新包。

用法:
  python3 scripts/embed_corpus.py
  python3 scripts/publish_corpus_static.py --base-url https://your.cdn/oraculo

输出目录 dist/corpus/:
  manifest.json                         — App 拉取的清单
  phrases-v<version>-<sha256>.json      — 与 App 内格式相同的不可变语料数组

发布前请递增 config/corpus_version.txt。
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
from pathlib import Path

from corpus_release_guard import require_rights_clear, require_version_above_public
from calendar_release import build_calendar_asset, validate_calendar

ROOT = Path(__file__).resolve().parents[1]
PHRASES = ROOT / "ios" / "Shared" / "Resources" / "phrases.json"
META = ROOT / "ios" / "Shared" / "Resources" / "corpus_bundled_meta.json"
CALENDAR = ROOT / "ios" / "Shared" / "Resources" / "calendar.json"
DIST = ROOT / "dist" / "corpus"
PUBLIC = ROOT / "public" / "oraculo"
PUBLIC_MANIFEST = PUBLIC / "manifest.json"
EDITORIAL_REVIEW = ROOT / "config" / "phrase_editorial_review.json"


def asset_filename(corpus_version: int, digest: str) -> str:
    normalized = digest.strip().lower()
    if len(normalized) != 64 or any(char not in "0123456789abcdef" for char in normalized):
        raise ValueError("phrasesSHA256 must be a 64-character lowercase hex digest")
    return f"phrases-v{corpus_version}-{normalized}.json"


def calendar_asset_filename(version: int, digest: str) -> str:
    return asset_filename(version, digest).replace("phrases-", "calendar-", 1)


def build_manifest(
    meta: dict,
    *,
    calendar_bytes: bytes | None = None,
    base_url: str,
    min_app_version: str,
    release_notes: str,
) -> dict:
    filename = asset_filename(int(meta["corpusVersion"]), str(meta["phrasesSHA256"]))
    manifest = {
        "corpusVersion": int(meta["corpusVersion"]),
        "publishedAt": meta["generatedAt"],
        "minAppVersion": min_app_version,
        "releaseNotes": release_notes or None,
        "phrases": {
            "url": f"{base_url.rstrip('/')}/{filename}",
            "sha256": str(meta["phrasesSHA256"]).lower(),
        },
    }
    if calendar_bytes is not None:
        version = int(meta["corpusVersion"])
        if json.loads(calendar_bytes).get("version") != version:
            raise ValueError("calendar version must match release version")
        if tuple(int(part) for part in min_app_version.split(".")) < (1, 1, 0):
            raise ValueError("calendar releases require minAppVersion >= 1.1.0")
        digest = hashlib.sha256(calendar_bytes).hexdigest()
        manifest["releaseVersion"] = version
        manifest["calendar"] = {
            "url": f"{base_url.rstrip('/')}/{calendar_asset_filename(version, digest)}",
            "sha256": digest,
        }
    return manifest


def copy_immutable(source: Path, destination: Path) -> None:
    if destination.exists():
        if source.read_bytes() != destination.read_bytes():
            raise SystemExit(f"Refusing to replace immutable corpus asset: {destination}")
        return
    shutil.copy2(source, destination)


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Build static corpus hot-update bundle")
    parser.add_argument(
        "--base-url",
        required=True,
        help="CDN 根 URL，无尾斜杠，例如 https://cdn.example.com/oraculo",
    )
    parser.add_argument(
        "--min-app-version",
        default="1.1.0",
        help="低于此版本的 App 忽略该 manifest",
    )
    parser.add_argument("--release-notes", default="")
    parser.add_argument(
        "--no-sync-public",
        action="store_true",
        help="不复制到 public/oraculo/（Vercel 从该目录发布）",
    )
    args = parser.parse_args(argv)

    # Local candidates may retain editorial decisions awaiting rights review;
    # the static publish boundary may never promote them.
    require_rights_clear(EDITORIAL_REVIEW)

    if not PHRASES.exists() or not META.exists():
        raise SystemExit("Run: python3 scripts/embed_corpus.py first")

    meta = json.loads(META.read_text(encoding="utf-8"))
    require_version_above_public(int(meta["corpusVersion"]), PUBLIC_MANIFEST)
    base = args.base_url.rstrip("/")
    body = PHRASES.read_bytes()
    actual_hash = hashlib.sha256(body).hexdigest()
    expected_hash = str(meta["phrasesSHA256"]).lower()
    if actual_hash != expected_hash:
        raise SystemExit(
            "Bundled phrases SHA does not match corpus_bundled_meta.json\n"
            f"  expected {expected_hash}\n"
            f"  actual   {actual_hash}"
        )
    if not CALENDAR.exists():
        raise SystemExit("Run embed_corpus.py to generate calendar.json")
    calendar_body = CALENDAR.read_bytes()
    calendar_hash = hashlib.sha256(calendar_body).hexdigest()
    if meta.get("calendarSHA256") != calendar_hash or meta.get("calendarVersion") != meta["corpusVersion"]:
        raise SystemExit("Bundled calendar metadata does not match the release")
    calendar_errors = validate_calendar(json.loads(calendar_body), int(meta["corpusVersion"]), json.loads(body))
    if calendar_errors:
        raise SystemExit("\n".join(calendar_errors))
    manifest = build_manifest(
        meta,
        calendar_bytes=calendar_body,
        base_url=base,
        min_app_version=args.min_app_version,
        release_notes=args.release_notes,
    )

    DIST.mkdir(parents=True, exist_ok=True)
    filename = asset_filename(int(meta["corpusVersion"]), expected_hash)
    asset_path = DIST / filename
    copy_immutable(PHRASES, asset_path)
    calendar_filename = calendar_asset_filename(int(meta["corpusVersion"]), calendar_hash)
    calendar_path = DIST / calendar_filename
    copy_immutable(CALENDAR, calendar_path)
    manifest_path = DIST / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    if not args.no_sync_public:
        PUBLIC.mkdir(parents=True, exist_ok=True)
        copy_immutable(asset_path, PUBLIC / filename)
        copy_immutable(calendar_path, PUBLIC / calendar_filename)
        shutil.copy2(manifest_path, PUBLIC / "manifest.json")
        print(f"  synced → {PUBLIC}/")

    print(f"Published corpus v{meta['corpusVersion']} → {DIST}")
    print(f"  manifest: {manifest_path}")
    print(f"  phrases:  {asset_path}")
    print(f"  calendar: {calendar_path}")
    print(f"\nApp 配置: AppConstants.corpusManifestURLString = \"{base}/manifest.json\"")
    if not args.no_sync_public:
        print("Vercel: git push 后自动部署 public/oraculo/（仓库 https://github.com/enderwang2012-lang/Oraculo）")


if __name__ == "__main__":
    main()
