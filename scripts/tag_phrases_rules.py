#!/usr/bin/env python3
"""规则打标：季节硬约束 + 通用库 + 节日/天气/月份 boost。"""
from __future__ import annotations

import csv
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from embed_corpus import theme_slug  # noqa: E402

SOURCE = ROOT / "starbucks_now_passphrases.csv"
OUT = ROOT / "scripts" / "phrase_dispatch.json"

SUMMER_EXCLUSIVE = [r"夏天", r"夏日", r"夏夜", r"盛夏", r"夏至", r"消暑", r"乘凉"]
AUTUMN_EXCLUSIVE = [r"秋天", r"秋日", r"秋夜", r"金秋", r"秋意", r"秋枫", r"秋凉", r"秋高气爽"]
WINTER_EXCLUSIVE = [r"冬天", r"冬日", r"冬夜", r"寒冬", r"冬至", r"围炉", r"冬日暖阳"]

SPRING_FALSE_POSITIVE = [
    r"四季",
    r"青春",
    r"常春",
    r"阳春",
    r"春节",
    r"新春",
    r"立春",
]

FESTIVAL_RULES: list[tuple[re.Pattern[str], str, float]] = [
    (re.compile(r"新年|春节|新春|压岁|锦鲤|福袋|团圆|守岁|拜年|红包"), "festival:spring_festival", 3.0),
    (re.compile(r"元宵|花灯|汤圆"), "festival:lantern_festival", 2.5),
    (re.compile(r"清明|踏青"), "festival:qingming", 2.0),
    (re.compile(r"端午|粽子"), "festival:dragon_boat", 2.5),
    (re.compile(r"中秋|月饼|月圆"), "festival:mid_autumn", 2.5),
    (re.compile(r"国庆"), "festival:national_day", 2.0),
    (re.compile(r"圣诞|平安夜"), "festival:christmas", 2.5),
    (re.compile(r"情人|520|1314"), "festival:valentine", 2.0),
    (re.compile(r"元旦"), "festival:new_year", 2.0),
]

SOLAR_TERM_RULES: list[tuple[str, str, float]] = [
    ("小寒", "solar_term:xiaohan", 2.0),
    ("大寒", "solar_term:dahan", 2.0),
    ("立春", "solar_term:lichun", 2.5),
    ("雨水", "solar_term:yushui", 2.0),
    ("惊蛰", "solar_term:jingzhe", 2.0),
    ("春分", "solar_term:chunfen", 2.5),
    ("清明", "solar_term:qingming", 2.5),
    ("谷雨", "solar_term:guyu", 2.0),
    ("立夏", "solar_term:lixia", 2.0),
    ("小满", "solar_term:xiaoman", 2.0),
    ("芒种", "solar_term:mangzhong", 2.0),
    ("夏至", "solar_term:xiazhi", 2.5),
    ("小暑", "solar_term:xiaoshu", 2.0),
    ("大暑", "solar_term:dashu", 2.0),
    ("立秋", "solar_term:liqiu", 2.0),
    ("处暑", "solar_term:chushu", 2.0),
    ("白露", "solar_term:bailu", 2.0),
    ("秋分", "solar_term:qiufen", 2.5),
    ("寒露", "solar_term:hanlu", 2.0),
    ("霜降", "solar_term:shuangjiang", 2.0),
    ("立冬", "solar_term:lidong", 2.0),
    ("小雪", "solar_term:xiaoxue", 2.0),
    ("大雪", "solar_term:daxue", 2.0),
    ("冬至", "solar_term:dongzhi", 2.5),
]

WEATHER_BOOST: list[tuple[re.Pattern[str], str, float]] = [
    (re.compile(r"雨|淋|伞|潮湿|淅沥"), "weather:rain", 1.5),
    (re.compile(r"雪|霜|冰|寒|冷|冻"), "weather:cold", 1.5),
    (re.compile(r"晴|阳光|烈日|晒|晴朗"), "weather:clear", 1.2),
    (re.compile(r"风|微风|清风|大风"), "weather:windy", 1.2),
    (re.compile(r"雾|霾|阴"), "weather:overcast", 1.2),
]


def has_spring_signal(text: str) -> bool:
    if not re.search(r"春", text):
        return False
    return not any(re.search(pat, text) for pat in SPRING_FALSE_POSITIVE)


def season_exclusive(text: str) -> list[str] | None:
    if any(re.search(p, text) for p in SUMMER_EXCLUSIVE):
        return ["season:summer"]
    if any(re.search(p, text) for p in AUTUMN_EXCLUSIVE):
        return ["season:autumn"]
    if any(re.search(p, text) for p in WINTER_EXCLUSIVE):
        return ["season:winter"]
    if has_spring_signal(text):
        return ["season:spring"]
    return None


def collect_boosts(text: str, theme_slug_value: str) -> list[dict]:
    boosts: list[dict] = []
    seen: set[str] = set()

    def add(tag: str, weight: float) -> None:
        if tag in seen:
            return
        seen.add(tag)
        boosts.append({"tag": tag, "weight": weight})

    for pattern, tag, w in FESTIVAL_RULES:
        if pattern.search(text):
            add(tag, w)

    for pattern, tag, w in WEATHER_BOOST:
        if pattern.search(text):
            add(tag, w)

    for keyword, tag, w in SOLAR_TERM_RULES:
        if keyword in text:
            add(tag, w)

    month_hints = [
        (r"一月|元月", "month:1", 1.0),
        (r"二月", "month:2", 1.0),
        (r"三月", "month:3", 1.0),
        (r"四月", "month:4", 1.0),
        (r"五月", "month:5", 1.0),
        (r"六月", "month:6", 1.0),
        (r"七月|盛夏", "month:7", 1.0),
        (r"八月", "month:8", 1.0),
        (r"九月|金秋", "month:9", 1.0),
        (r"十月", "month:10", 1.0),
        (r"十一月", "month:11", 1.0),
        (r"十二月|岁末", "month:12", 1.0),
    ]
    for pat, tag, w in month_hints:
        if re.search(pat, text):
            add(tag, w)

    if theme_slug_value == "ip_collab":
        add("theme:ip", 1.5)

    return boosts


def build_dispatch(text: str, theme: str) -> dict:
    slug = theme_slug(theme)
    exclusive = season_exclusive(text)
    boosts = collect_boosts(text, slug)

    if exclusive:
        return {"universal": False, "onlyWhen": exclusive, "boost": boosts}

    return {"universal": True, "onlyWhen": [], "boost": boosts}


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing {SOURCE}")

    dispatch_by_id: dict[str, dict] = {}
    seen: set[str] = set()

    with SOURCE.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            text = row["phrase"].strip()
            if not text or text in seen:
                continue
            seen.add(text)
            pid = f"sb_{row['id'].strip()}"
            dispatch_by_id[pid] = build_dispatch(text, row.get("theme", "").strip())

    OUT.write_text(
        json.dumps(dispatch_by_id, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    universal = sum(1 for d in dispatch_by_id.values() if d["universal"])
    seasonal = len(dispatch_by_id) - universal
    print(f"Wrote {len(dispatch_by_id)} dispatch ({universal} universal, {seasonal} season-locked) → {OUT}")


if __name__ == "__main__":
    main()
