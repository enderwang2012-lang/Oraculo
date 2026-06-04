#!/usr/bin/env python3
"""生成可上传到 CDN / GitHub Pages 的静态热更新包。

用法:
  python3 scripts/embed_corpus.py
  python3 scripts/publish_corpus_static.py --base-url https://your.cdn/oraculo

输出目录 dist/corpus/:
  manifest.json   — App 拉取的清单
  phrases.json    — 与 App 内格式相同的语料数组

发布前请递增 config/corpus_version.txt。
"""
from __future__ import annotations

import argparse
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHRASES = ROOT / "ios" / "Shared" / "Resources" / "phrases.json"
META = ROOT / "ios" / "Shared" / "Resources" / "corpus_bundled_meta.json"
DIST = ROOT / "dist" / "corpus"
PUBLIC = ROOT / "public" / "oraculo"


def main() -> None:
    parser = argparse.ArgumentParser(description="Build static corpus hot-update bundle")
    parser.add_argument(
        "--base-url",
        required=True,
        help="CDN 根 URL，无尾斜杠，例如 https://cdn.example.com/oraculo",
    )
    parser.add_argument(
        "--min-app-version",
        default="0.1.0",
        help="低于此版本的 App 忽略该 manifest",
    )
    parser.add_argument("--release-notes", default="")
    parser.add_argument(
        "--no-sync-public",
        action="store_true",
        help="不复制到 public/oraculo/（Vercel 从该目录发布）",
    )
    args = parser.parse_args()

    if not PHRASES.exists() or not META.exists():
        raise SystemExit("Run: python3 scripts/embed_corpus.py first")

    meta = json.loads(META.read_text(encoding="utf-8"))
    base = args.base_url.rstrip("/")

    DIST.mkdir(parents=True, exist_ok=True)
    shutil.copy2(PHRASES, DIST / "phrases.json")

    manifest = {
        "corpusVersion": meta["corpusVersion"],
        "publishedAt": meta["generatedAt"],
        "minAppVersion": args.min_app_version,
        "releaseNotes": args.release_notes or None,
        "phrases": {
            "url": f"{base}/phrases.json",
            "sha256": meta["phrasesSHA256"],
        },
    }
    manifest_path = DIST / "manifest.json"
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    if not args.no_sync_public:
        PUBLIC.mkdir(parents=True, exist_ok=True)
        shutil.copy2(manifest_path, PUBLIC / "manifest.json")
        shutil.copy2(DIST / "phrases.json", PUBLIC / "phrases.json")
        print(f"  synced → {PUBLIC}/")

    print(f"Published corpus v{meta['corpusVersion']} → {DIST}")
    print(f"  manifest: {manifest_path}")
    print(f"  phrases:  {DIST / 'phrases.json'}")
    print(f"\nApp 配置: AppConstants.corpusManifestURLString = \"{base}/manifest.json\"")
    if not args.no_sync_public:
        print("Vercel: git push 后自动部署 public/oraculo/（仓库 https://github.com/enderwang2012-lang/Oraculo）")


if __name__ == "__main__":
    main()
