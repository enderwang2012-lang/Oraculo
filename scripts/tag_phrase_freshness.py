#!/usr/bin/env python3
"""Generate phrase freshness metadata for local repeat control.

The output is intentionally explicit and committed so future corpus reviews can
curate semantic clusters without changing app code.
"""
from __future__ import annotations

import csv
import json
import re
from pathlib import Path

from embed_corpus import ANCHOR_EVIDENCE, SOURCE, theme_slug

OUT = Path(__file__).resolve().parents[1] / "config" / "phrase_freshness_tags.json"

RESTART_WORDS = ("新", "开始", "出发", "启程", "重启", "未来", "明天", "前路")
RAIN_WORDS = ("雨", "伞", "淋", "晴雨")
WIND_WORDS = ("风", "云", "天空", "蓝天")
SEA_WORDS = ("海", "浪", "潜水", "水上", "蔚蓝")
SUMMER_WORDS = ("夏", "冰", "暑", "西瓜", "冷萃")
WINTER_WORDS = ("雪", "冬", "霜", "暖", "圣诞")
LUCK_WORDS = ("好运", "幸运", "发财", "胜意", "顺遂", "锦鲤", "欧气")
LOVE_WORDS = ("爱", "喜欢", "心动", "玫瑰", "相见", "想你")
SELF_WORDS = ("自己", "自由", "勇敢", "热爱", "理想", "闪闪")
TRAVEL_WORDS = ("远方", "旅行", "路", "桥", "山", "岛", "走", "去")


def load_rows() -> list[dict[str, str]]:
    with SOURCE.open(encoding="utf-8") as handle:
        return [row for row in csv.DictReader(handle) if row.get("phrase", "").strip()]


def slug(text: str) -> str:
    value = re.sub(r"[^a-z0-9_]+", "_", text.lower()).strip("_")
    return value or "general"


def char_token(char: str) -> str:
    value = slug(char)
    if value != "general":
        return value
    return f"u{ord(char):04x}"


def has_any(text: str, words: tuple[str, ...]) -> bool:
    return any(word in text for word in words)


def semantic_cluster(phrase: str, theme: str) -> str:
    if has_any(phrase, RAIN_WORDS):
        return "weather_rain"
    if has_any(phrase, SEA_WORDS):
        return "summer_water"
    if has_any(phrase, WIND_WORDS):
        return "sky_wind"
    if has_any(phrase, SUMMER_WORDS):
        return "summer_cool"
    if has_any(phrase, WINTER_WORDS):
        return "winter_warmth"
    if has_any(phrase, LUCK_WORDS):
        return "luck_blessing"
    if has_any(phrase, LOVE_WORDS):
        return "love_meeting"
    if has_any(phrase, RESTART_WORDS):
        return "new_beginning"
    if has_any(phrase, SELF_WORDS):
        return "self_light"
    if has_any(phrase, TRAVEL_WORDS):
        return "travel_distance"
    return slug(theme_slug(theme))


def cadence_group(phrase: str) -> str:
    length = len(phrase)
    if phrase.endswith("吧"):
        return "invitation_ba"
    if phrase.startswith("去"):
        return "go_action"
    if phrase.startswith("愿"):
        return "wish_sentence"
    if phrase.startswith("把"):
        return "imperative_soft"
    if "正在" in phrase or "快要" in phrase or phrase.endswith("来了"):
        return "arrival_statement"
    if "一起" in phrase:
        return "together_phrase"
    if re.fullmatch(r"[A-Za-z ,.'!-]+", phrase):
        return "latin_phrase"
    structure = "plain"
    if any(char in phrase for char in ("，", "。", "！", "?", "？", " ")):
        structure = "punctuated"
    elif any(word in phrase for word in ("的", "在", "是", "有", "和", "与")):
        structure = "relational"
    elif any(word in phrase for word in ("一", "每", "满", "再")):
        structure = "quantified"
    elif any(word in phrase for word in ("小", "大", "好", "慢", "轻")):
        structure = "modifier"

    prefix = char_token(phrase[:1])
    suffix = char_token(phrase[-1:])
    if length <= 4:
        band = "short"
    elif length <= 7:
        band = "medium"
    else:
        band = "long"
    return f"{band}_{structure}_{prefix}_{suffix}"


def lifecycle(row: dict[str, str]) -> str:
    evidence = row.get("evidence", "").strip()
    return "anchor" if evidence in ANCHOR_EVIDENCE else "active"


def generate_tags(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for row in rows:
        phrase = row["phrase"].strip()
        pid = f"sb_{row['id'].strip()}"
        result[pid] = {
            "semanticCluster": semantic_cluster(phrase, row.get("theme", "")),
            "cadenceGroup": cadence_group(phrase),
            "lifecycle": lifecycle(row),
        }
    return result


def main() -> None:
    tags = generate_tags(load_rows())
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(tags, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(tags)} phrase freshness tags -> {OUT}")


if __name__ == "__main__":
    main()
