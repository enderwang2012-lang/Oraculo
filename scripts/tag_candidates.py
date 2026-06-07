#!/usr/bin/env python3
"""给候选语料按「场合」自动打标（硬锁 onlyWhen），产出供人工筛选的审阅表。

输入 CSV 列：id,phrase,occasion,note
  occasion 取值（与 config/tag_vocabulary.json 对齐）：
    season:summer|autumn|winter|spring
    festival:dragon_boat|spring_festival|mid_autumn|... (见词表)
    month:1..12
    weather:rain|snow|clear|windy|overcast|...
    daypart:morning|noon|afternoon|evening|late_night
    none  → 通用兜底（universal）

打标规则：
  - 先用 tag_phrases_rules.build_dispatch 取字面 boost（节日/天气/节气等）
  - occasion != none → 硬锁：universal=False, onlyWhen=[occasion]，并去掉与之重复的 boost
  - occasion = season:summer 时剔除「冰/冻」误命中的 weather:snow boost
  - 全部标签对 tag_vocabulary.json 强校验

输出（与输入同目录、同名）：
  *.md            可读审阅表
  *.tagged.json   结构化（筛选后可直接合并）
不改主 CSV / phrases.json。
"""
from __future__ import annotations

import argparse
import csv
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from tag_phrases_rules import build_dispatch  # noqa: E402

MAIN_CSV = ROOT / "starbucks_now_passphrases.csv"
VOCAB = ROOT / "config" / "tag_vocabulary.json"
DEFAULT_IN = ROOT / "review" / "phrase_candidates_batch2.csv"

OCC_CN = {
    "season:spring": "春天", "season:summer": "夏天",
    "season:autumn": "秋天", "season:winter": "冬天",
    "festival:spring_festival": "春节", "festival:lantern_festival": "元宵",
    "festival:qingming": "清明", "festival:labor_day": "五一",
    "festival:dragon_boat": "端午", "festival:mid_autumn": "中秋",
    "festival:national_day": "国庆", "festival:valentine": "情人节",
    "festival:christmas": "圣诞", "festival:new_year": "元旦",
    "weather:rain": "雨天", "weather:snow": "雪天", "weather:clear": "晴天",
    "weather:windy": "大风", "weather:overcast": "阴天", "weather:fog": "雾天",
    "daypart:morning": "清晨", "daypart:noon": "正午",
    "daypart:afternoon": "午后", "daypart:evening": "黄昏",
    "daypart:late_night": "深夜",
}


def occ_cn(occ: str) -> str:
    if occ.startswith("month:"):
        return f"{occ.split(':')[1]}月"
    return OCC_CN.get(occ, occ)


def load_existing_texts() -> set[str]:
    texts: set[str] = set()
    if MAIN_CSV.exists():
        with MAIN_CSV.open(encoding="utf-8") as f:
            for row in csv.DictReader(f):
                t = row["phrase"].strip()
                if t:
                    texts.add(t)
    return texts


def load_vocab() -> dict:
    return json.loads(VOCAB.read_text(encoding="utf-8"))


def add_boost(d: dict, tag: str, weight: float) -> None:
    for b in d["boost"]:
        if b["tag"] == tag:
            b["weight"] = max(b["weight"], weight)
            return
    d["boost"].append({"tag": tag, "weight": weight})


def apply_occasion(d: dict, occ: str) -> dict:
    occ = (occ or "none").strip()
    if occ in ("", "none"):
        return d
    d["universal"] = False
    d["onlyWhen"] = [occ]
    occ_dim = occ.split(":")[0]
    # 去掉与锁定同维度的 boost（锁定后只在该窗口出，同维其它取值无意义，
    # 也顺带清掉「十二月」误命中「二月」这类子串噪声）
    d["boost"] = [b for b in d.get("boost", []) if b["tag"].split(":")[0] != occ_dim]
    if occ == "season:summer":
        d["boost"] = [b for b in d["boost"] if b["tag"] != "weather:snow"]
    return d


def validate_tag(tag: str, vocab: dict) -> str | None:
    dim, _, val = tag.partition(":")
    dims = vocab["dimensions"]
    if dim not in dims:
        return f"未知维度 {dim}"
    spec = dims[dim]
    if spec.get("skip_value_check"):
        return None
    if val not in spec["values"]:
        return f"未知取值 {tag}"
    return None


def dispatch_summary(d: dict) -> str:
    parts = []
    if d.get("universal"):
        parts.append("通用兜底")
    if d.get("onlyWhen"):
        parts.append("仅当 " + " / ".join(d["onlyWhen"]))
    boosts = d.get("boost") or []
    if boosts:
        parts.append("加权 " + " ".join(f"{b['tag']}×{b['weight']}" for b in boosts))
    return "；".join(parts) if parts else "通用兜底"


def main() -> int:
    ap = argparse.ArgumentParser(description="Occasion-aware auto-tagger for review")
    ap.add_argument("--in", dest="in_path", default=str(DEFAULT_IN))
    args = ap.parse_args()

    in_path = Path(args.in_path)
    if not in_path.exists():
        raise SystemExit(f"Missing candidates: {in_path}")

    existing = load_existing_texts()
    vocab = load_vocab()
    md_path = in_path.with_suffix(".md")
    json_path = in_path.with_name(in_path.stem + ".tagged.json")

    rows: list[dict] = []
    dups: list[str] = []
    warns: list[str] = []
    seen: set[str] = set()

    with in_path.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            text = row["phrase"].strip()
            if not text:
                continue
            occ = row.get("occasion", "none").strip()
            note = "OK"
            if text in existing:
                note = "重复(主库已有)"
                dups.append(text)
            elif text in seen:
                note = "重复(批次内)"
                dups.append(text)
            seen.add(text)

            d = build_dispatch(text, "")
            d = apply_occasion(d, occ)

            for tag in list(d.get("onlyWhen", [])) + [b["tag"] for b in d.get("boost", [])]:
                err = validate_tag(tag, vocab)
                if err:
                    warns.append(f"{row['id']} {text}: {err}")

            rows.append({
                "id": f"sb_{row['id'].strip()}",
                "text": text,
                "occasion": occ,
                "dispatch": d,
                "review_note": note,
            })

    json_path.write_text(
        json.dumps(rows, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )

    universal = sum(1 for r in rows if r["dispatch"]["universal"])
    locked = len(rows) - universal
    occ_counter: Counter[str] = Counter()
    for r in rows:
        for t in r["dispatch"].get("onlyWhen", []):
            occ_counter[t.split(":")[0]] += 1

    lines = [
        f"# 候选语料审阅 · {in_path.name}",
        "",
        f"- 总数 **{len(rows)}**　通用兜底 **{universal}**　硬锁场合 **{locked}**",
        f"- 疑似重复 **{len(dups)}**" + (f"：{', '.join(dups)}" if dups else "（无）"),
        f"- 标签校验告警 **{len(warns)}**" + (f"：{'; '.join(warns)}" if warns else "（全部合法）"),
        "",
        "场合分布（硬锁 onlyWhen）：",
        "",
        "| 维度 | 条数 |",
        "| --- | --- |",
    ]
    for k, v in sorted(occ_counter.items(), key=lambda x: -x[1]):
        lines.append(f"| {k} | {v} |")
    lines += [
        "",
        "在「取舍」列写 ✅/❌，或直接删行。",
        "",
        "| 取舍 | id | 句子 | 出现时机 | 标签 | 备注 |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for r in rows:
        flag = "⚠️" if r["review_note"] != "OK" else ""
        when = occ_cn(r["occasion"]) if r["occasion"] not in ("", "none") else "任何时候"
        lines.append(
            f"| {flag} | {r['id']} | {r['text']} | {when} | "
            f"{dispatch_summary(r['dispatch'])} | {r['review_note']} |"
        )
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"打标完成 {len(rows)} 条 → {md_path.name} / {json_path.name}")
    print(f"  通用 {universal} / 硬锁 {locked} / 疑似重复 {len(dups)} / 告警 {len(warns)}")
    print("  场合:", dict(sorted(occ_counter.items(), key=lambda x: -x[1])))
    if dups:
        print("  ⚠️ 重复:", ", ".join(dups))
    if warns:
        print("  ⚠️ 告警:", "; ".join(warns))
    return 0


if __name__ == "__main__":
    sys.exit(main())
