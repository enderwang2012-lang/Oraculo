#!/usr/bin/env python3
"""Export the current local bundle and its reviewed tags as Markdown."""
from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PHRASES = ROOT / "ios" / "Shared" / "Resources" / "phrases.json"
META = ROOT / "ios" / "Shared" / "Resources" / "corpus_bundled_meta.json"
REVIEW = ROOT / "config" / "phrase_editorial_review.json"
BY_THEME = ROOT / "docs" / "current-corpus-by-theme.md"
FULL_TAGS = ROOT / "docs" / "current-corpus-full-tags.md"


def cell(value: object) -> str:
    return str(value).replace("|", "\\|").replace("\n", "<br>")


def main() -> None:
    phrases = json.loads(PHRASES.read_text(encoding="utf-8"))
    meta = json.loads(META.read_text(encoding="utf-8"))
    review = json.loads(REVIEW.read_text(encoding="utf-8"))

    grouped: dict[str, list[dict]] = defaultdict(list)
    for phrase in phrases:
        grouped[phrase["emotionTheme"]].append(phrase)

    summary = [
        "# Current Local Corpus by Theme",
        "",
        f"- Local candidate version: {meta['corpusVersion']}",
        f"- Phrase count: {len(phrases)}",
        "- Source: `ios/Shared/Resources/phrases.json`",
        "- Production may still serve an older manifest; see `docs/CORPUS.md`.",
        "",
    ]
    for theme in sorted(grouped):
        summary.extend([
            f"## {theme}",
            "",
            "| ID | 中文 | 英文 | Lifecycle |",
            "| --- | --- | --- | --- |",
        ])
        for phrase in grouped[theme]:
            summary.append(
                f"| {phrase['id']} | {cell(phrase['text'])} | {cell(phrase['textEn'])} | "
                f"{phrase['freshness']['lifecycle']} |"
            )
        summary.append("")
    BY_THEME.write_text("\n".join(summary).rstrip() + "\n", encoding="utf-8")

    detail = [
        "# Current Local Corpus Full Tags",
        "",
        f"- Local candidate version: {meta['corpusVersion']}",
        f"- Phrase count: {len(phrases)}",
        f"- SHA256: `{meta['phrasesSHA256']}`",
        "- Production may still serve an older manifest; see `docs/CORPUS.md`.",
        "",
        "| ID | 中文 | 英文 | 编辑主题 | 语义簇 | 句式组 | Lifecycle | onlyWhen | boost | negative | 色彩倾向 | 色彩禁用 |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for phrase in phrases:
        pid = phrase["id"]
        dispatch = phrase.get("dispatch", {})
        item = review[pid]
        boosts = ", ".join(f"{entry['tag']}:{entry['weight']}" for entry in dispatch.get("boost", []))
        detail.append("| " + " | ".join([
            pid,
            cell(phrase["text"]),
            cell(phrase["textEn"]),
            item["editorialTheme"],
            phrase["freshness"]["semanticCluster"],
            phrase["freshness"]["cadenceGroup"],
            phrase["freshness"]["lifecycle"],
            cell(", ".join(dispatch.get("onlyWhen", []))),
            cell(boosts),
            cell(", ".join(dispatch.get("negative", []))),
            cell(", ".join(dispatch.get("colorMoods", []))),
            cell(", ".join(dispatch.get("colorBan", []))),
        ]) + " |")
    FULL_TAGS.write_text("\n".join(detail).rstrip() + "\n", encoding="utf-8")
    print(f"Wrote {len(phrases)} local-candidate rows to {BY_THEME.name} and {FULL_TAGS.name}")


if __name__ == "__main__":
    main()
