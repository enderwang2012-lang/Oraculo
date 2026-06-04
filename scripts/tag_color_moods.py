#!/usr/bin/env python3
"""给 ios/Shared/Resources/nippon_colors.json 的 248 色批量打 moods 标签。

4 桶（与 docs/CONTEXTUAL_PHRASE_DISPATCH.md / docs/COLOR_MOODS.md 对齐）：
  warm   红橙黄系，色相在暖区
  cool   青蓝紫绿系，色相在冷区
  light  高明度（HSL.L >= 0.78）
  dark   低明度（HSL.L <= 0.32）

每色归 1-2 桶：1 个色相桶（warm/cool）+ 可选 1 个明度桶（light/dark）。
中等明度的色只归色相桶（避免 light/dark 被稀释）。

色相分桶用 HSL：H ∈ [0°,60°] ∪ [330°,360°] 视为 warm（红橙黄），其余视为 cool。
名称里出现明确的"墨/玄/铁/漆/绀"等深色字必加 dark；
出现"樱/薄/淡/白/银/灰"等浅淡字必加 light（覆盖 HSL 边界模糊的 case）。

输出：
  - 原文件 in-place 注入 "moods": [...]（按 id 升序保持稳定）
  - scripts/tag_color_moods_review.md：按桶分组列出 248 色供人工校对
"""
from __future__ import annotations

import colorsys
import json
import re
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COLORS_PATH = ROOT / "ios" / "Shared" / "Resources" / "nippon_colors.json"
REVIEW_PATH = ROOT / "scripts" / "tag_color_moods_review.md"

# 色名硬规则：出现这些字必含相应桶（覆盖 HSL 边界模糊）。
DARK_TOKENS = ["墨", "玄", "鐡", "鉄", "漆", "紺", "绀", "黒", "黑", "暗", "深", "煤"]
LIGHT_TOKENS = ["樱", "櫻", "薄", "淡", "白", "銀", "银", "灰"]
# 寂淡灰系名（鸠羽、利休、鼠系）——HSL 上明度可能中等，但视觉偏寂，归 light（4 桶里没有 muted）
SUBTLE_LIGHT_TOKENS = ["鼠", "鳩", "鸠", "利休"]

LIGHT_THRESHOLD = 0.78
DARK_THRESHOLD = 0.32


def hex_to_hsl(hex_str: str) -> tuple[float, float, float]:
    h = hex_str.lstrip("#")
    r = int(h[0:2], 16) / 255
    g = int(h[2:4], 16) / 255
    b = int(h[4:6], 16) / 255
    h_, l, s = colorsys.rgb_to_hls(r, g, b)
    return h_ * 360, s, l  # H in degrees, S, L in [0,1]


def classify(hex_str: str, cname: str) -> list[str]:
    h, s, l = hex_to_hsl(hex_str)
    moods: list[str] = []

    # —— 色相桶（warm / cool） ——
    # 极低饱和（接近灰/黑/白）按明度处理，色相暂不归——但仍然需要一个色相桶兜底。
    # 经验：饱和 < 0.08 时，归 cool（中性灰偏冷感）。这是产品判断，非物理。
    if s < 0.08:
        hue_bucket = "cool"
    else:
        # 红橙黄区：H ∈ [0,60] ∪ [330,360]，再扩一点到 [0,70] ∪ [320,360] 容纳茶褐
        if h <= 70 or h >= 320:
            hue_bucket = "warm"
        else:
            hue_bucket = "cool"
    moods.append(hue_bucket)

    # —— 明度桶（light / dark），可选 ——
    has_dark_token = any(t in cname for t in DARK_TOKENS)
    has_light_token = any(t in cname for t in LIGHT_TOKENS) or any(
        t in cname for t in SUBTLE_LIGHT_TOKENS
    )

    if has_dark_token:
        moods.append("dark")
    elif has_light_token:
        moods.append("light")
    elif l <= DARK_THRESHOLD:
        moods.append("dark")
    elif l >= LIGHT_THRESHOLD:
        moods.append("light")
    # 中明度且无名称提示 → 不归明度桶

    return moods


def write_review(colors: list[dict]) -> None:
    by_mood: dict[str, list[dict]] = defaultdict(list)
    for c in colors:
        for m in c["moods"]:
            by_mood[m].append(c)

    lines = [
        "# Nippon 色 moods 校对清单",
        "",
        "4 桶定义（详见 docs/COLOR_MOODS.md，若未建可参考 SKILL.md 中的描述）：",
        "- **warm**：红橙黄系（含茶褐）",
        "- **cool**：青蓝紫绿系 + 中性灰（饱和度极低时归冷）",
        "- **light**：高明度（HSL L ≥ 0.78）或名称含 樱/薄/淡/白/银/灰/鼠/鸠/利休",
        "- **dark**：低明度（HSL L ≤ 0.32）或名称含 墨/玄/铁/漆/绀/黑",
        "",
        "**校对方法**：扫一遍各桶，看哪个色「不像这桶」——直接改 `nippon_colors.json` 的 `moods` 字段。",
        "中等明度的色只归色相桶（warm/cool），不归明度桶——这是设计选择，不是错。",
        "",
    ]

    for mood in ["warm", "cool", "light", "dark"]:
        cs = by_mood.get(mood, [])
        lines.append(f"## {mood}（{len(cs)} 色）")
        lines.append("")
        for c in cs:
            other = [m for m in c["moods"] if m != mood]
            other_label = f" ＋ {' '.join(other)}" if other else ""
            lines.append(
                f"- `{c['id']}` **{c['cname']}** ({c['name']}) `#{c['hex']}` "
                f"[L={hex_to_hsl(c['hex'])[2]:.2f}]{other_label}"
            )
        lines.append("")

    REVIEW_PATH.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    colors = json.loads(COLORS_PATH.read_text(encoding="utf-8"))
    if not isinstance(colors, list):
        raise SystemExit("expected a JSON array")

    for c in colors:
        c["moods"] = classify(c["hex"], c["cname"])

    payload = json.dumps(colors, ensure_ascii=False, indent=2) + "\n"
    COLORS_PATH.write_text(payload, encoding="utf-8")
    write_review(colors)

    counts: dict[str, int] = defaultdict(int)
    for c in colors:
        for m in c["moods"]:
            counts[m] += 1
    print(f"Tagged {len(colors)} colors:")
    for m in ["warm", "cool", "light", "dark"]:
        print(f"  {m:5s}: {counts[m]:3d}")
    print(f"\n  → {COLORS_PATH}")
    print(f"  → {REVIEW_PATH}（人工校对清单）")


if __name__ == "__main__":
    main()
