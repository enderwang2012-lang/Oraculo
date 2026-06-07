#!/usr/bin/env python3
"""给 ios/Shared/Resources/nippon_colors.json 的 248 色批量打「情境亲和」标签。

目标：让「颜色也应景」。Swift 选色时若某色的 context 标签命中当前 ContextSnapshot
（季节 / 节日 / 天气），该色额外加权（见 ColorMoodPicker.contextBoostMultiplier）。

写入字段（仅写非空键）：
  "context": {
    "season":   ["spring" | "summer" | "autumn" | "winter", ...],
    "festival": ["spring_festival" | "new_year" | "valentine" | "christmas"
                 | "mid_autumn" | "qingming", ...],
    "weather":  ["snow" | "clear" | "cloudy" | "overcast" | "rain" | "fog", ...]
  }

同时写入细色族字段（P4 精确配色，语料 dispatch.colorFamilies 可点名）：
  "family": "red" | "orange" | "yellow" | "green" | "blue" | "purple"
          | "pink" | "brown" | "white" | "gray" | "black"

分类基于 HSL（色相 / 明度 / 饱和度）+ 色名汉字硬规则。取值全部落在
config/tag_vocabulary.json 的枚举内（season / festival / weather / color_family）。

这是「产品判断」而非物理真值——目的是观感应景，可在 review.md 里人工校对后
直接改 nippon_colors.json 的 context 字段。

输出：
  - 原文件 in-place 注入 "context": {...}（按 id 升序保持稳定）
  - scripts/tag_color_context_review.md：按维度分组列出供人工校对
"""
from __future__ import annotations

import colorsys
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COLORS_PATH = ROOT / "ios" / "Shared" / "Resources" / "nippon_colors.json"
REVIEW_PATH = ROOT / "scripts" / "tag_color_context_review.md"

# —— 色名汉字硬规则（覆盖 HSL 边界模糊；同时给文化语义兜底） ——
# 季节
SPRING_TOKENS = ["桜", "櫻", "梅", "桃", "萌", "若", "春", "苺", "撫子", "薔薇", "菫", "藤"]
SUMMER_TOKENS = ["青", "縹", "水", "苔", "常磐", "夏", "瑠璃", "群青", "浅葱", "翠", "緑", "碧"]
AUTUMN_TOKENS = ["栗", "朽", "柿", "枯", "茶", "金", "黄", "葉", "秋", "桔", "琥珀", "丁子", "黄櫨"]
WINTER_TOKENS = ["雪", "霜", "鼠", "鉛", "墨", "冬", "銀", "灰", "紺", "鉄", "玄", "漆", "鳩"]
# 节日
RED_FEST_TOKENS = ["紅", "朱", "緋", "猩", "赤", "丹", "茜", "唐紅"]  # 红 → 春节/新年
VALENTINE_TOKENS = ["撫子", "紅梅", "桃", "薔薇", "退紅", "鴇", "一斤染"]  # 粉 → 情人节
XMAS_GREEN_TOKENS = ["常磐", "松", "緑", "千歳", "深緑", "萌黄"]  # 深绿 → 圣诞（与深红互补）
QINGMING_TOKENS = ["柳", "萌黄", "若草", "若竹", "苗"]  # 嫩绿柳色 → 清明
MIDAUTUMN_TOKENS = ["月", "黄金", "山吹"]  # 月华/金 → 中秋
# 天气
SNOW_TOKENS = ["雪", "霜", "白", "胡粉", "卯"]
CLEAR_TOKENS = ["曙", "晴", "陽", "茜", "朱", "向日"]
CLOUDY_TOKENS = ["鼠", "曇", "灰", "鳩", "煤"]
RAIN_TOKENS = ["雨", "水浅葱", "錆", "湿"]


def hex_to_hsl(hex_str: str) -> tuple[float, float, float]:
    h = hex_str.lstrip("#")
    r = int(h[0:2], 16) / 255
    g = int(h[2:4], 16) / 255
    b = int(h[4:6], 16) / 255
    h_, l, s = colorsys.rgb_to_hls(r, g, b)
    return h_ * 360, s, l  # H in degrees, S/L in [0,1]


def color_family(h: float, s: float, l: float) -> str:
    """粗色族（P4 复用同一逻辑）。中性色按明度分 white/gray/black。"""
    if s < 0.12:
        if l >= 0.80:
            return "white"
        if l <= 0.20:
            return "black"
        return "gray"
    # 棕：暖色相 + 中低明度
    if (15 <= h <= 50) and l < 0.50 and s < 0.65:
        return "brown"
    if h < 15 or h >= 345:
        return "red"
    if h < 40:
        return "orange"
    if h < 70:
        return "yellow"
    if h < 160:
        return "green"
    if h < 255:
        return "blue"
    if h < 290:
        return "purple"
    return "pink" if l >= 0.55 else "purple"


def has(cname: str, tokens: list[str]) -> bool:
    return any(t in cname for t in tokens)


def classify_seasons(h, s, l, fam, cname) -> list[str]:
    out: set[str] = set()
    # 名称硬规则
    if has(cname, SPRING_TOKENS):
        out.add("spring")
    if has(cname, SUMMER_TOKENS):
        out.add("summer")
    if has(cname, AUTUMN_TOKENS):
        out.add("autumn")
    if has(cname, WINTER_TOKENS):
        out.add("winter")
    # HSL 规则
    if fam == "pink" or (fam in {"red", "orange"} and l >= 0.78):
        out.add("spring")  # 樱粉、淡暖 → 春
    if fam == "green" and l >= 0.60:
        out.add("spring")  # 嫩绿 → 春
    if fam in {"green", "blue"} and s >= 0.30:
        out.add("summer")  # 浓青碧 → 夏
    if fam == "yellow" and l >= 0.70:
        out.add("summer")  # 亮黄如夏日烈阳 → 夏
    if fam in {"orange", "brown"} or (fam == "yellow" and l < 0.70):
        out.add("autumn")  # 橙褐、金黄 → 秋
    if fam == "red" and l <= 0.45:
        out.add("autumn")  # 深红如红叶 → 秋
    if fam in {"white", "gray", "black"} or l <= 0.30:
        out.add("winter")  # 雪白、铅灰、墨黑 → 冬
    if fam in {"blue", "purple"} and l <= 0.45:
        out.add("winter")  # 深蓝紫 → 冬夜
    # 兜底：每色至少一个季节，按色族给一个最合理的
    if not out:
        out.add(
            {
                "red": "autumn", "orange": "autumn", "yellow": "autumn",
                "brown": "autumn", "green": "summer", "blue": "summer",
                "purple": "winter", "pink": "spring", "white": "winter",
                "gray": "winter", "black": "winter",
            }.get(fam, "spring")
        )
    return sorted(out)


def classify_festivals(h, s, l, fam, cname) -> list[str]:
    out: set[str] = set()
    # 红 → 春节 + 新年（鲜艳红或红字名）
    if has(cname, RED_FEST_TOKENS) or (fam == "red" and s >= 0.55 and 0.28 <= l <= 0.62):
        out.add("spring_festival")
        out.add("new_year")
    # 粉 → 情人节
    if has(cname, VALENTINE_TOKENS) or (fam == "pink" and l >= 0.70):
        out.add("valentine")
    # 深绿 → 圣诞
    if has(cname, XMAS_GREEN_TOKENS) or (fam == "green" and s >= 0.30 and l <= 0.42):
        out.add("christmas")
    # 嫩绿柳色 → 清明
    if has(cname, QINGMING_TOKENS):
        out.add("qingming")
    # 月华金 → 中秋
    if has(cname, MIDAUTUMN_TOKENS) or (fam == "yellow" and l >= 0.62):
        out.add("mid_autumn")
    return sorted(out)


def classify_weather(h, s, l, fam, cname) -> list[str]:
    out: set[str] = set()
    # 雪 → 极浅 / 白
    if has(cname, SNOW_TOKENS) or fam == "white" or l >= 0.86:
        out.add("snow")
    # 晴 → 明亮暖色
    if has(cname, CLEAR_TOKENS) or (fam in {"yellow", "orange"} and l >= 0.55 and s >= 0.35):
        out.add("clear")
    # 阴 → 灰
    if has(cname, CLOUDY_TOKENS) or fam == "gray":
        out.add("cloudy")
        out.add("overcast")
    # 雨 → 暗淡冷青蓝
    if has(cname, RAIN_TOKENS) or (fam in {"blue", "green"} and s < 0.40 and 0.30 <= l <= 0.70):
        out.add("rain")
    # 雾 → 极低饱和的浅灰
    if s < 0.10 and 0.60 <= l < 0.86:
        out.add("fog")
    return sorted(out)


def classify(hex_str: str, cname: str) -> dict[str, list[str]]:
    h, s, l = hex_to_hsl(hex_str)
    fam = color_family(h, s, l)
    ctx: dict[str, list[str]] = {}
    seasons = classify_seasons(h, s, l, fam, cname)
    festivals = classify_festivals(h, s, l, fam, cname)
    weather = classify_weather(h, s, l, fam, cname)
    if seasons:
        ctx["season"] = seasons
    if festivals:
        ctx["festival"] = festivals
    if weather:
        ctx["weather"] = weather
    return ctx


def write_review(colors: list[dict]) -> None:
    by_tag: dict[str, list[dict]] = defaultdict(list)
    for c in colors:
        for dim, values in c.get("context", {}).items():
            for v in values:
                by_tag[f"{dim}:{v}"].append(c)

    lines = [
        "# Nippon 色 context 亲和校对清单",
        "",
        "用途：Swift 选色时命中当前情境（季节/节日/天气）的色额外加权——「颜色也应景」。",
        "分类基于 HSL + 色名汉字，属产品判断。校对时直接改 `nippon_colors.json` 的 `context` 字段。",
        "",
    ]
    order = [
        "season:spring", "season:summer", "season:autumn", "season:winter",
        "festival:spring_festival", "festival:new_year", "festival:valentine",
        "festival:christmas", "festival:qingming", "festival:mid_autumn",
        "weather:snow", "weather:clear", "weather:cloudy", "weather:overcast",
        "weather:rain", "weather:fog",
    ]
    for tag in order:
        cs = by_tag.get(tag, [])
        lines.append(f"## {tag}（{len(cs)} 色）")
        lines.append("")
        for c in cs:
            lines.append(
                f"- `{c['id']}` **{c['cname']}** ({c['name']}) `#{c['hex']}`"
            )
        lines.append("")

    REVIEW_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    colors = json.loads(COLORS_PATH.read_text(encoding="utf-8"))
    if not isinstance(colors, list):
        raise SystemExit("expected a JSON array")

    for c in colors:
        h, s, l = hex_to_hsl(c["hex"])
        c["family"] = color_family(h, s, l)
        c["context"] = classify(c["hex"], c["cname"])

    payload = json.dumps(colors, ensure_ascii=False, indent=2) + "\n"
    COLORS_PATH.write_text(payload, encoding="utf-8")
    write_review(colors)

    counts: dict[str, int] = defaultdict(int)
    fam_counts: dict[str, int] = defaultdict(int)
    for c in colors:
        fam_counts[c["family"]] += 1
        for dim, values in c["context"].items():
            for v in values:
                counts[f"{dim}:{v}"] += 1
    print(f"Tagged {len(colors)} colors with context affinity + family:")
    for tag in sorted(counts):
        print(f"  {tag:28s}: {counts[tag]:3d}")
    print("  --- color_family ---")
    for fam in sorted(fam_counts):
        print(f"  {fam:28s}: {fam_counts[fam]:3d}")
    print(f"\n  → {COLORS_PATH}")
    print(f"  → {REVIEW_PATH}（人工校对清单）")


if __name__ == "__main__":
    main()
