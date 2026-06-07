#!/usr/bin/env python3
"""情境标签共享逻辑：词表加载、base+overlay 合并、标签解析。

被 embed_corpus.py 与 validate_dispatch.py 复用，保证两边语义一致。

数据流：
  tag_phrases_rules.py        → scripts/phrase_dispatch.json        （规则基线：universal/onlyWhen/boost）
  config/phrase_context_tags.json （LLM+人工 overlay：colorMoods/colorBan/boostAdd/negativeAdd）
  merge_dispatch(base, overlay) → 最终 dispatch（embed 写进 phrases.json）
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOCAB_PATH = ROOT / "config" / "tag_vocabulary.json"
OVERLAY_PATH = ROOT / "config" / "phrase_context_tags.json"


def load_vocabulary() -> dict:
    return json.loads(VOCAB_PATH.read_text(encoding="utf-8"))


def load_overlay() -> dict:
    if not OVERLAY_PATH.exists():
        return {}
    return json.loads(OVERLAY_PATH.read_text(encoding="utf-8"))


def parse_tag(tag: str) -> tuple[str, str]:
    """'season:spring' → ('season', 'spring')；无冒号 → ('', tag)。"""
    if ":" in tag:
        dim, _, value = tag.partition(":")
        return dim, value
    return "", tag


def merge_dispatch(base: dict, overlay: dict | None) -> dict:
    """把 overlay 合并进 base，返回新 dict（不改原对象）。

    合并规则：
      - universal / onlyWhen：以 base 为准（硬门槛只在规则层定义，overlay 不动）。
      - boost：按 tag 取并集；overlay 的 boostAdd 权重覆盖同名 tag。
      - negative：base + overlay.negativeAdd 去重并集。
      - colorMoods / colorBan：overlay 直接赋值（overlay 优先；缺省保留 base）。
      - _meta：归档用，不进最终 dispatch（embed 会丢弃）。
    """
    merged: dict = {
        "universal": base.get("universal", True),
        "onlyWhen": list(base.get("onlyWhen", [])),
        "boost": [dict(b) for b in base.get("boost", [])],
    }
    if base.get("negative"):
        merged["negative"] = list(base["negative"])
    if base.get("colorMoods"):
        merged["colorMoods"] = list(base["colorMoods"])
    if base.get("colorBan"):
        merged["colorBan"] = list(base["colorBan"])
    if base.get("colorFamilies"):
        merged["colorFamilies"] = list(base["colorFamilies"])

    if not overlay:
        return merged

    # boost 并集（同名 tag 取最大权重，overlay 不会削弱规则层的强字面 boost）
    boost_by_tag = {b["tag"]: b["weight"] for b in merged["boost"]}
    for b in overlay.get("boostAdd", []):
        prev = boost_by_tag.get(b["tag"])
        boost_by_tag[b["tag"]] = b["weight"] if prev is None else max(prev, b["weight"])
    merged["boost"] = [
        {"tag": t, "weight": w} for t, w in boost_by_tag.items()
    ]

    # negative 并集
    if overlay.get("negativeAdd"):
        neg = set(merged.get("negative", [])) | set(overlay["negativeAdd"])
        merged["negative"] = sorted(neg)

    # 颜色：overlay 优先
    if overlay.get("colorMoods"):
        merged["colorMoods"] = list(overlay["colorMoods"])
    if overlay.get("colorBan"):
        merged["colorBan"] = list(overlay["colorBan"])
    if overlay.get("colorFamilies"):
        merged["colorFamilies"] = list(overlay["colorFamilies"])

    return merged


def strip_for_embed(dispatch: dict) -> dict:
    """落地到 phrases.json 前清掉空字段与归档字段，保持文件干净。"""
    out: dict = {
        "universal": dispatch.get("universal", True),
        "onlyWhen": list(dispatch.get("onlyWhen", [])),
        "boost": [dict(b) for b in dispatch.get("boost", [])],
    }
    if dispatch.get("negative"):
        out["negative"] = list(dispatch["negative"])
    if dispatch.get("colorMoods"):
        out["colorMoods"] = list(dispatch["colorMoods"])
    if dispatch.get("colorBan"):
        out["colorBan"] = list(dispatch["colorBan"])
    if dispatch.get("colorFamilies"):
        out["colorFamilies"] = list(dispatch["colorFamilies"])
    return out
