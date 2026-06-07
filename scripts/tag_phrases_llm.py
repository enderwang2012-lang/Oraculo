#!/usr/bin/env python3
"""LLM 语义打标层 → config/phrase_context_tags.json（overlay）。

这一层补足规则层（tag_phrases_rules.py）做不到的「语义应景」判断：
  - colorMoods / colorBan        颜色匹配（句 → 色）
  - boostAdd: festival/weather/scene/daypart/season 软加权（语义而非字面）
  - negativeAdd                  反讽/冲突降权
  - _meta: emotion/tone/scene    归档（不进 phrases.json，供人工与日后用）

判断以「策划编辑的语义直觉」编码为关键词映射 + 锚点句逐条 override，
对全库 218 条一致打标，且可复现——日后新增语料只需重跑本脚本。

权重口径见 config/tag_vocabulary.json 的 weight_range。
合并语义见 scripts/dispatch_overlay.py（boost 同名取 max，overlay 不削弱规则）。

用法：python3 scripts/tag_phrases_llm.py
"""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from embed_corpus import theme_slug  # noqa: E402

SOURCE = ROOT / "starbucks_now_passphrases.csv"
OUT = ROOT / "config" / "phrase_context_tags.json"
REVIEW = ROOT / "scripts" / "phrase_context_tags_review.md"


def kw(text: str, words: list[str]) -> bool:
    return any(w in text for w in words)


# ───────────────────────── 颜色匹配（句 → 色） ─────────────────────────
# 暖：喜庆 / 好运 / 爱意 / 暖阳 / 红橙焰
WARM_WORDS = [
    "锦鲤", "好运", "福", "财", "暴富", "喜", "爱", "热爱", "玫瑰", "礼物",
    "红", "绯", "赤", "橙", "焰", "烈", "暖", "新年", "新春", "桃", "团圆",
    "胜意", "欢愉", "称心", "如愿", "惊艳", "高光", "发光", "追光", "曙光",
    "明媚", "元气", "桃气", "苹", "兔", "万象更新", "开门红", "财神",
]
# 冷：水 / 海 / 天空 / 风 / 自由 / 旷野 / 青碧翠
COOL_WORDS = [
    "蔚蓝", "海", "蓝", "碧", "翠", "青", "澄", "潜水", "水上", "浪", "旷野",
    "天空", "望天", "云", "风", "清风", "自由", "远方", "山河", "旷", "明月",
    "踏千重浪", "有风的地方",
]
# 浅：明亮 / 晴 / 白 / 纯真 / 微笑
LIGHT_WORDS = [
    "明媚", "曙光", "晴", "白", "雪", "浅", "清浅", "纯真", "微笑", "赞",
    "明朗", "高光", "发光", "光", "桃气启新芳",
]
# 深：夜 / 深 / 墨 / 静谧（少用，仅真夜景）
DARK_WORDS = ["秋夜", "明月照山河", "墨", "深夜", "夜色"]

# 细色族（P4）：仅在句面有「明确的实物/颜色」时点名，宁缺毋滥（命中权重 ×3，过宽会单调）。
FAMILY_WORDS: dict[str, list[str]] = {
    "blue": ["蔚蓝", "蓝天", "碧海", "海面", "大海", "星辰大海", "天空", "瑠璃", "靛"],
    "green": ["翠", "绿", "苔", "森林", "竹", "草原", "山林", "碧绿"],
    "red": ["红", "玫瑰", "绯", "赤", "朱", "枫", "焰", "丹"],
    "pink": ["桃", "樱", "粉", "撫子"],
    "white": ["雪", "纯白", "皑", "霜"],
    "yellow": ["金", "向日", "麦", "稻", "银杏"],
    "purple": ["紫", "薰衣草", "藤"],
}


def family_tags(phrase: str) -> list[str]:
    fams = [fam for fam, words in FAMILY_WORDS.items() if kw(phrase, words)]
    # 多于 2 个色族说明句面色彩混杂，点名反而失焦——放弃，交给 moods/context 兜。
    return fams if 0 < len(fams) <= 2 else []


def color_tags(phrase: str, theme: str) -> tuple[list[str], list[str]]:
    moods: list[str] = []
    bans: list[str] = []

    def add(lst: list[str], v: str) -> None:
        if v not in lst:
            lst.append(v)

    is_warm = kw(phrase, WARM_WORDS) or theme in (
        "好运祝福", "节日祝福", "新年祝福", "财运祝福", "平安祝福", "美好祝福", "长久祝福",
    )
    is_cool = kw(phrase, COOL_WORDS)
    is_light = kw(phrase, LIGHT_WORDS)
    is_dark = kw(phrase, DARK_WORDS)

    # 冷暖冲突时，以字面意象（cool 的水/海/风）优先，避免「蔚蓝海面」被判暖。
    if is_cool and not (kw(phrase, ["热", "炎", "暑", "暖阳"])):
        add(moods, "cool")
        add(bans, "warm")
    elif is_warm:
        add(moods, "warm")

    if is_dark:
        add(moods, "dark")
    elif is_light:
        add(moods, "light")
        add(bans, "dark")

    # 喜庆 / 爱意：禁灰黑（不配丧气色）
    if is_warm and "dark" not in moods:
        add(bans, "dark")

    return moods, bans


# ───────────────────────── 情境软加权（语义） ─────────────────────────
FESTIVAL_THEMES = {
    "好运祝福", "节日祝福", "新年祝福", "财运祝福", "平安祝福", "美好祝福",
}
FESTIVAL_WORDS = [
    "福", "好运", "财", "如愿", "称心", "顺", "平安", "团圆", "岁", "年年",
    "新年", "新春", "桃", "苹", "兔", "万象更新", "开门红", "财神", "胜意", "欢愉",
]

WINDY_WORDS = ["风", "清风", "吹风", "有风"]
CLEAR_WORDS = ["乌云散开", "云开", "拨云", "望天", "晴", "曙光", "明朗", "云朵"]
TRAVEL_WORDS = [
    "远方", "前路", "前行", "奔赴", "坦途", "出发", "启程", "踏", "浪", "潜水",
    "路上", "旷野", "去有风的地方", "无所不达", "天涯", "山河", "千重浪",
]
RESTART_WORDS = ["新起点", "新序章", "重启", "新开始", "起点", "新一年", "今天起"]
MEET_WORDS = ["见面", "相见", "相逢", "手牵手", "执手", "勾勾手", "一起走", "宜相见", "宜见面"]
COMFORT_WORDS = [
    "烦恼", "水逆", "乌云", "愁", "过滤", "退散", "消除", "解药", "与万事言和",
    "允许一切", "眉目舒展", "只记欢喜", "心缓", "事缓",
]
SELFTIME_WORDS = ["慢下来", "慢慢", "留白", "闲", "听从内心", "值得记录", "恰到好处", "轻松自在"]
MORNING_WORDS = ["元气", "新一天", "记得微笑", "向快乐出发", "明媚媚", "新开始", "起新"]


def context_boosts(phrase: str, theme: str) -> list[dict]:
    boosts: list[dict] = []
    seen: set[str] = set()

    def add(tag: str, weight: float) -> None:
        if tag in seen:
            return
        seen.add(tag)
        boosts.append({"tag": tag, "weight": weight})

    # 节日软加权：祝福类全年可出，年节大幅加权（「岁岁常欢愉」式）
    if theme in FESTIVAL_THEMES or kw(phrase, FESTIVAL_WORDS):
        add("festival:spring_festival", 2.5)
        add("festival:new_year", 1.5)

    # 圣诞 / 情人节
    if kw(phrase, ["礼物", "圣诞", "平安夜"]):
        add("festival:christmas", 3.0)
    if kw(phrase, ["玫瑰", "执手", "手牵手", "爱你", "心动", "勾勾手"]):
        add("festival:valentine", 2.0)

    # 天气语义
    if kw(phrase, WINDY_WORDS):
        add("weather:windy", 2.0)
    if kw(phrase, CLEAR_WORDS):
        add("weather:clear", 2.0)
    if kw(phrase, ["霜", "挂霜"]):
        add("temp:cold", 1.5)

    # 场景软加权
    if kw(phrase, TRAVEL_WORDS):
        add("scene:travel", 1.2)
    if kw(phrase, RESTART_WORDS):
        add("scene:restart", 1.2)
    if kw(phrase, MEET_WORDS):
        add("scene:meeting_friend", 1.2)
    if kw(phrase, COMFORT_WORDS):
        add("scene:after_setback", 1.2)
    if kw(phrase, SELFTIME_WORDS):
        add("scene:self_time", 1.0)

    # 时段软加权
    if kw(phrase, MORNING_WORDS):
        add("daypart:morning", 0.8)

    return boosts


TONE_BY_THEME = {
    "playful_meme": "playful",
    "ip_collab": "playful",
    "luck_blessing": "bright",
    "self_affirmation": "bright",
    "light_comfort": "calm",
    "soft_hope": "tender",
    "daily_romance": "tender",
    "gentle_departure": "warm",
    "lyric_image": "calm",
    "quiet_mirror": "calm",
}


def meta(phrase: str, theme: str, boosts: list[dict]) -> dict:
    slug = theme_slug(theme)
    m: dict = {}
    if slug in (
        "light_comfort", "soft_hope", "daily_romance", "self_affirmation",
        "gentle_departure", "luck_blessing", "lyric_image", "playful_meme",
        "quiet_mirror", "ip_collab", "latin_phrase",
    ):
        m["emotion"] = slug
    if slug in TONE_BY_THEME:
        m["tone"] = TONE_BY_THEME[slug]
    scenes = sorted({b["tag"].split(":", 1)[1] for b in boosts if b["tag"].startswith("scene:")})
    if scenes:
        m["scene"] = scenes
    return m


# ───────────── 锚点句逐条 override（true per-phrase 判断，优先级最高） ─────────────
# 结构同 overlay 条目；会整条替换生成结果（而非合并）。
OVERRIDES: dict[str, dict] = {
    "sb_20": {  # 蔚蓝海面
        "colorMoods": ["cool"], "colorBan": ["warm"], "colorFamilies": ["blue"],
        "boostAdd": [{"tag": "season:summer", "weight": 2.0}, {"tag": "weather:clear", "weight": 1.5}, {"tag": "scene:travel", "weight": 1.2}],
        "_meta": {"emotion": "daily_romance", "tone": "cool", "scene": ["travel"]},
    },
    "sb_41": {  # 冬日暖阳（季节已锁 winter）
        "colorMoods": ["warm"], "colorBan": ["cool"],
        "boostAdd": [{"tag": "weather:clear", "weight": 2.0}, {"tag": "temp:cold", "weight": 1.5}],
        "_meta": {"emotion": "daily_romance", "tone": "warm"},
    },
    "sb_42": {  # 月是秋夜明（季节已锁 autumn）
        "colorMoods": ["dark"], "colorBan": ["light"],
        "boostAdd": [{"tag": "daypart:late_night", "weight": 1.2}, {"tag": "festival:mid_autumn", "weight": 2.5}],
        "_meta": {"emotion": "lyric_image", "tone": "calm", "scene": []},
    },
    "sb_51": {  # 岁岁常欢愉（春节硬门槛由规则保证）
        "colorMoods": ["warm"], "colorBan": ["dark"],
        "boostAdd": [{"tag": "festival:new_year", "weight": 4.0}, {"tag": "festival:lantern_festival", "weight": 3.0}],
        "_meta": {"emotion": "luck_blessing", "tone": "bright", "scene": ["festival"]},
    },
    "sb_91": {  # 自由是终极魔法
        "colorMoods": ["cool"],
        "boostAdd": [{"tag": "scene:travel", "weight": 1.2}],
        "_meta": {"emotion": "ip_collab", "tone": "playful", "scene": ["travel"]},
    },
    "sb_122": {  # 清风为我翻书
        "colorMoods": ["cool", "light"], "colorBan": ["dark"],
        "boostAdd": [{"tag": "weather:windy", "weight": 2.5}, {"tag": "weather:clear", "weight": 1.5}, {"tag": "scene:self_time", "weight": 1.2}],
        "_meta": {"emotion": "light_comfort", "tone": "calm", "scene": ["self_time"]},
    },
    "sb_194": {  # 被礼物包围
        "colorMoods": ["warm"], "colorBan": ["dark"],
        "boostAdd": [{"tag": "festival:christmas", "weight": 4.0}, {"tag": "festival:spring_festival", "weight": 2.0}],
        "_meta": {"emotion": "luck_blessing", "tone": "bright", "scene": ["festival"]},
    },
    "sb_190": {  # 你值得玫瑰
        "colorMoods": ["warm"], "colorBan": ["dark"], "colorFamilies": ["red", "pink"],
        "boostAdd": [{"tag": "festival:valentine", "weight": 3.0}],
        "_meta": {"emotion": "self_affirmation", "tone": "tender", "scene": ["love_resonance"]},
    },
    "sb_29": {  # 乌云散开
        "colorMoods": ["light"], "colorBan": ["dark"],
        "boostAdd": [{"tag": "weather:clear", "weight": 2.5}, {"tag": "scene:after_setback", "weight": 1.5}],
        "_meta": {"emotion": "light_comfort", "tone": "bright", "scene": ["after_setback"]},
    },
    "sb_248": {  # 不追风时吹吹风
        "colorMoods": ["cool"],
        "boostAdd": [{"tag": "weather:windy", "weight": 2.5}, {"tag": "scene:self_time", "weight": 1.2}],
        "_meta": {"emotion": "light_comfort", "tone": "calm", "scene": ["self_time"]},
    },
    "sb_100": {  # 挂霜予你（季节已锁 autumn）
        "colorMoods": ["light", "cool"],
        "boostAdd": [{"tag": "temp:cold", "weight": 2.0}, {"tag": "solar_term:shuangjiang", "weight": 2.0}],
        "_meta": {"emotion": "daily_romance", "tone": "tender"},
    },
}


def build_entry(phrase: str, theme: str) -> dict | None:
    moods, bans = color_tags(phrase, theme)
    boosts = context_boosts(phrase, theme)
    families = family_tags(phrase)
    entry: dict = {}
    if moods:
        entry["colorMoods"] = moods
    if bans:
        entry["colorBan"] = sorted(set(bans))
    if families:
        entry["colorFamilies"] = families
    if boosts:
        entry["boostAdd"] = boosts
    m = meta(phrase, theme, boosts)
    if m:
        entry["_meta"] = m
    return entry or None


def main() -> None:
    rows = list(csv.DictReader(SOURCE.open(encoding="utf-8")))
    overlay: dict[str, dict] = {}

    for row in rows:
        pid = f"sb_{row['id'].strip()}"
        phrase = row["phrase"].strip()
        theme = row.get("theme", "").strip()
        if not phrase:
            continue
        if pid in OVERRIDES:
            overlay[pid] = OVERRIDES[pid]
            continue
        entry = build_entry(phrase, theme)
        if entry:
            overlay[pid] = entry

    OUT.write_text(json.dumps(overlay, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    # 校对清单
    lines = [
        "# 语义 overlay 校对清单（config/phrase_context_tags.json）",
        "",
        "AI 语义层产出，逐条扫一眼接受/改写。锚点句在 tag_phrases_llm.py 的 OVERRIDES 里。",
        "",
        f"覆盖 {len(overlay)} / {len(rows)} 条。",
        "",
    ]
    by_phrase = {f"sb_{r['id'].strip()}": r["phrase"].strip() for r in rows}
    for pid, e in overlay.items():
        parts = []
        if e.get("colorMoods"):
            parts.append(f"moods={e['colorMoods']}")
        if e.get("colorBan"):
            parts.append(f"ban={e['colorBan']}")
        if e.get("colorFamilies"):
            parts.append(f"family={e['colorFamilies']}")
        if e.get("boostAdd"):
            parts.append("boost=" + ",".join(f"{b['tag']}×{b['weight']}" for b in e["boostAdd"]))
        lines.append(f"- `{pid}` **{by_phrase.get(pid,'')}** — {'; '.join(parts)}")
    REVIEW.write_text("\n".join(lines) + "\n", encoding="utf-8")

    cm = sum(1 for e in overlay.values() if e.get("colorMoods"))
    cb = sum(1 for e in overlay.values() if e.get("colorBan"))
    cf = sum(1 for e in overlay.values() if e.get("colorFamilies"))
    ba = sum(1 for e in overlay.values() if e.get("boostAdd"))
    print(f"Wrote overlay {len(overlay)}/{len(rows)} → {OUT}")
    print(f"  colorMoods={cm} colorBan={cb} colorFamilies={cf} boostAdd={ba}")
    print(f"  → {REVIEW}")


if __name__ == "__main__":
    main()
