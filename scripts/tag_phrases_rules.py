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
# 手工授权的派发覆盖（口语句字面抽不出场合词，规则无法生成硬锁）。
OVERRIDES = ROOT / "config" / "phrase_dispatch_overrides.json"

# 主题级节日硬门槛：非窗口内权重为 0，摇一摇/回前台也抽不到。
FESTIVAL_EXCLUSIVE_THEMES: dict[str, str] = {
    "新年祝福": "festival:spring_festival",
    # 经典春节对仗祝福（语料里仅「岁岁常欢愉」「年年皆胜意」）
    "长久祝福": "festival:spring_festival",
}

# 字面春节祝福语（主题可能标成别的，用句式兜底）
FESTIVAL_EXCLUSIVE_TEXT: list[re.Pattern[str]] = [
    re.compile(r"岁岁常欢愉"),
    re.compile(r"年年皆胜意"),
]

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
    (re.compile(r"雪|霜|冰|冻"), "weather:snow", 1.5),
    (re.compile(r"晴|阳光|烈日|晒|晴朗|曙光"), "weather:clear", 1.2),
    (re.compile(r"风|微风|清风|大风"), "weather:windy", 1.2),
    (re.compile(r"雾|霾|阴|乌云"), "weather:overcast", 1.2),
]

ICE_DRINK_TEXT = re.compile(r"加冰|冰美式|冰咖啡|冰饮|冰拿铁|吃冰|喝冰|冰一下")

# 时段：句面明确时间意象才标，避免误伤（语义层的早安/晚安交给 overlay）。
DAYPART_BOOST: list[tuple[re.Pattern[str], str, float]] = [
    (re.compile(r"清晨|晨光|破晓|黎明|日出|朝阳|早安"), "daypart:morning", 1.0),
    (re.compile(r"黄昏|暮色|夕阳|日落|晚霞"), "daypart:evening", 1.0),
    (re.compile(r"深夜|星空|星河|明月|月色|晚安|子夜|夜色"), "daypart:late_night", 1.0),
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
        if tag == "weather:snow" and ICE_DRINK_TEXT.search(text):
            continue
        if pattern.search(text):
            add(tag, w)

    for pattern, tag, w in DAYPART_BOOST:
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


def festival_exclusive(theme: str) -> list[str] | None:
    tag = FESTIVAL_EXCLUSIVE_THEMES.get(theme.strip())
    return [tag] if tag else None


def festival_exclusive_by_text(text: str) -> list[str] | None:
    for pattern in FESTIVAL_EXCLUSIVE_TEXT:
        if pattern.search(text):
            return ["festival:spring_festival"]
    return None


# 长月份先匹配，避免「十一月」误命中「一月」。
MONTH_EXCLUSIVE_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"十一月"), "month:11"),
    (re.compile(r"十二月|岁末"), "month:12"),
    (re.compile(r"一月|元月"), "month:1"),
    (re.compile(r"二月"), "month:2"),
    (re.compile(r"三月"), "month:3"),
    (re.compile(r"四月"), "month:4"),
    (re.compile(r"五月"), "month:5"),
    (re.compile(r"六月"), "month:6"),
    (re.compile(r"七月"), "month:7"),
    (re.compile(r"八月"), "month:8"),
    (re.compile(r"九月|金秋"), "month:9"),
    (re.compile(r"十月"), "month:10"),
]


def month_exclusive(text: str, theme: str) -> list[str] | None:
    """「月份希望」主题：句内写明几月，则仅该月可出。"""
    if theme.strip() != "月份希望":
        return None
    for pattern, tag in MONTH_EXCLUSIVE_PATTERNS:
        if pattern.search(text):
            return [tag]
    return None


def build_dispatch(text: str, theme: str) -> dict:
    slug = theme_slug(theme)
    exclusive = season_exclusive(text)
    boosts = collect_boosts(text, slug)
    festival_only = festival_exclusive(theme) or festival_exclusive_by_text(text)
    month_only = month_exclusive(text, theme)

    if festival_only:
        return {"universal": False, "onlyWhen": festival_only, "boost": boosts}

    if month_only:
        return {"universal": False, "onlyWhen": month_only, "boost": boosts}

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

    overridden = 0
    if OVERRIDES.exists():
        raw = json.loads(OVERRIDES.read_text(encoding="utf-8"))
        for pid, rule in raw.items():
            if pid.startswith("_"):
                continue
            dispatch_by_id[pid] = rule
            overridden += 1

    OUT.write_text(
        json.dumps(dispatch_by_id, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    universal = sum(1 for d in dispatch_by_id.values() if d["universal"])
    seasonal = len(dispatch_by_id) - universal
    print(
        f"Wrote {len(dispatch_by_id)} dispatch ({universal} universal, "
        f"{seasonal} season-locked, {overridden} overridden) → {OUT}"
    )


if __name__ == "__main__":
    main()
