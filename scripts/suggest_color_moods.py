#!/usr/bin/env python3
"""扫描 304 条啡快口令，给"特别需要色情绪约束"的句子建议 colorMoods/colorBan 初值。

策略（保守，宁缺毋滥）：
  - 已有 onlyWhen 季节绑定的句子 → 按季节给一组色情绪建议
  - 名称含"夏天/盛夏" → warm（暑热感）
  - 名称含"春" → 倾向 warm + light（樱粉系）
  - 名称含"秋" → 倾向 earthy 在 4 桶里没有，warm + （light 看个例）
  - 名称含"冬日暖阳" → warm + dark 共存（取暖+冬日）
  - 含"绿茶/翠/绿"等 → cool
  - 含直白情绪词（"爱/喜欢"）→ warm
  - 名称含"难过/孤独/冷"等 → cool + dark；ban warm

只输出建议——你需要扫一眼接受/否决/改写。结果写入 scripts/phrase_dispatch.suggested.json。
"""
from __future__ import annotations

import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "starbucks_now_passphrases.csv"
DISPATCH = ROOT / "scripts" / "phrase_dispatch.json"
OUT = ROOT / "scripts" / "phrase_dispatch.suggested.json"
REVIEW = ROOT / "scripts" / "phrase_color_moods_review.md"


def suggest(phrase: str, theme: str, current: dict) -> dict | None:
    """给一条句返回 {colorMoods?, colorBan?, _why}。返回 None 表示不建议改。"""
    moods: list[str] = []
    ban: list[str] = []
    why: list[str] = []

    only_when = current.get("onlyWhen", [])

    # —— 季节硬绑定 ——
    if "season:spring" in only_when:
        moods.extend(["warm", "light"])
        why.append("春→warm+light（樱粉系）")
    elif "season:summer" in only_when:
        moods.append("warm")
        why.append("夏→warm")
    elif "season:autumn" in only_when:
        moods.append("warm")
        why.append("秋→warm（无 earthy 桶，落 warm）")
    elif "season:winter" in only_when:
        # 冬季的"暖阳"类应该是 warm；冬日"冷感"是 cool+dark
        if "暖" in phrase:
            moods.append("warm")
            why.append("冬日暖阳→warm")
        else:
            moods.append("cool")
            why.append("冬→cool")

    # —— 字面颜色 / 水象 ——
    if any(t in phrase for t in ["蔚蓝", "蓝天", "碧海", "海面", "大海", "翠", "绿茶", "青", "碧", "澄"]):
        if "cool" not in moods:
            moods.append("cool")
        if "warm" not in ban:
            ban.append("warm")
        why.append("字面蓝/海/绿→cool，ban warm")

    # —— 字面物理感受 ——
    if any(t in phrase for t in ["热", "炎", "盛夏", "暑"]):
        if "warm" not in moods:
            moods.append("warm")
        if "cool" not in ban:
            ban.append("cool")
        why.append("字面热→ban cool")
    if any(t in phrase for t in ["冷", "寒", "冰", "雪"]):
        if "cool" not in moods:
            moods.append("cool")
        if "warm" not in ban:
            ban.append("warm")
        why.append("字面冷→ban warm")

    # —— 直白情绪 ——
    if any(t in phrase for t in ["爱你", "喜欢你", "我爱"]):
        if "dark" not in ban:
            ban.append("dark")
        why.append("爱意句→ban dark")
    # 葬礼/悲伤——啡快语料里几乎没有，这里只占位

    # —— theme 类别提示 ——
    if theme in ("好运祝福", "节日祝福"):
        # 喜庆类倾向暖
        if "warm" not in moods:
            moods.append("warm")
        if "dark" not in ban:
            ban.append("dark")
        why.append(f"theme={theme}→喜庆 warm，ban dark")

    if not moods and not ban:
        return None

    result: dict = {}
    if moods:
        result["colorMoods"] = moods
    if ban:
        result["colorBan"] = ban
    result["_why"] = "; ".join(why)
    return result


def main() -> None:
    dispatch = json.loads(DISPATCH.read_text(encoding="utf-8"))
    rows = list(csv.DictReader(SOURCE.open(encoding="utf-8")))

    suggestions: dict[str, dict] = {}
    review_lines = [
        "# 句的 colorMoods / colorBan 建议初值",
        "",
        "**这是 AI 跑规则给出的建议**，需要你扫一眼接受/否决/改写。",
        "",
        "判定优先级：`colorBan` 硬剔除 > `colorMoods` 加权 ×2。",
        "绝大多数句子不需要标——只标真正需要色情绪约束的。",
        "",
        "**操作**：你认可的，把 colorMoods/colorBan 字段合并到 `phrase_dispatch.json`；",
        "不认可的直接忽略。重跑 embed_corpus.py 把改动嵌入 phrases.json。",
        "",
        "---",
        "",
    ]

    for row in rows:
        pid = f"sb_{row['id'].strip()}"
        phrase = row["phrase"].strip()
        theme = row.get("theme", "").strip()
        current = dispatch.get(pid, {})
        result = suggest(phrase, theme, current)
        if result:
            suggestions[pid] = {k: v for k, v in result.items() if not k.startswith("_")}
            review_lines.append(
                f"### {pid} — {phrase}"
            )
            review_lines.append(f"- theme: {theme}")
            review_lines.append(f"- 当前 onlyWhen: {current.get('onlyWhen', [])}")
            if result.get("colorMoods"):
                review_lines.append(f"- 建议 colorMoods: `{result['colorMoods']}`")
            if result.get("colorBan"):
                review_lines.append(f"- 建议 colorBan: `{result['colorBan']}`")
            review_lines.append(f"- 原因: {result['_why']}")
            review_lines.append("")

    OUT.write_text(
        json.dumps(suggestions, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    REVIEW.write_text("\n".join(review_lines), encoding="utf-8")

    print(f"Generated suggestions for {len(suggestions)} / {len(rows)} phrases")
    print(f"  → {OUT}")
    print(f"  → {REVIEW}")


if __name__ == "__main__":
    main()
