#!/usr/bin/env python3
"""校验情境标签合法性：所有 tag 在词表内、权重在区间、颜色桶合法。

校验对象：
  - scripts/phrase_dispatch.json（规则基线）
  - config/phrase_context_tags.json（LLM+人工 overlay）
  - 二者 merge 后的最终结构

退出码非 0 表示有 error（CI 可挡）。warning 不挡，仅提示。
用法：python3 scripts/validate_dispatch.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from dispatch_overlay import (  # noqa: E402
    load_overlay,
    load_vocabulary,
    merge_dispatch,
    parse_tag,
)

DISPATCH_PATH = ROOT / "scripts" / "phrase_dispatch.json"
COLOR_MOODS = {"warm", "cool", "light", "dark"}


def validate_tag(tag: str, vocab: dict, errors: list[str], where: str) -> None:
    dim, value = parse_tag(tag)
    dims = vocab["dimensions"]
    if not dim:
        errors.append(f"[{where}] 标签缺少维度前缀: '{tag}'")
        return
    if dim not in dims:
        errors.append(f"[{where}] 未知维度 '{dim}'（tag='{tag}'）")
        return
    spec = dims[dim]
    if spec.get("skip_value_check"):
        return
    if value not in spec["values"]:
        errors.append(
            f"[{where}] 维度 '{dim}' 非法取值 '{value}'（合法: {spec['values']}）"
        )


def validate_weight(tag: str, weight: float, vocab: dict, warnings: list[str], where: str) -> None:
    dim, _ = parse_tag(tag)
    spec = vocab["dimensions"].get(dim)
    if not spec:
        return
    lo, hi = spec.get("weight_range", [0, 999])
    if not (lo <= weight <= hi):
        warnings.append(
            f"[{where}] {tag} 权重 {weight} 越界（推荐 {lo}–{hi}）"
        )


def validate_color(field: str, values: list[str], errors: list[str], where: str) -> None:
    for v in values:
        if v not in COLOR_MOODS:
            errors.append(f"[{where}] {field} 非法色桶 '{v}'（合法: {sorted(COLOR_MOODS)}）")


def validate_color_family(values: list[str], vocab: dict, errors: list[str], where: str) -> None:
    valid = set(vocab.get("color_family", {}).get("values", []))
    for v in values:
        if v not in valid:
            errors.append(f"[{where}] colorFamilies 非法色族 '{v}'（合法: {sorted(valid)}）")


def validate_dispatch_obj(pid: str, d: dict, vocab: dict, errors: list[str], warnings: list[str]) -> None:
    for tag in d.get("onlyWhen", []):
        validate_tag(tag, vocab, errors, f"{pid}.onlyWhen")
    for b in d.get("boost", []):
        validate_tag(b["tag"], vocab, errors, f"{pid}.boost")
        validate_weight(b["tag"], b["weight"], vocab, warnings, f"{pid}.boost")
    for tag in d.get("negative", []) or []:
        validate_tag(tag, vocab, errors, f"{pid}.negative")
    if d.get("colorMoods"):
        validate_color("colorMoods", d["colorMoods"], errors, pid)
    if d.get("colorBan"):
        validate_color("colorBan", d["colorBan"], errors, pid)
    if d.get("colorFamilies"):
        validate_color_family(d["colorFamilies"], vocab, errors, pid)


def validate_overlay_meta(pid: str, overlay: dict, vocab: dict, warnings: list[str]) -> None:
    meta = overlay.get("_meta", {})
    dims = vocab["dimensions"]
    for tone in ([meta["tone"]] if meta.get("tone") else []):
        if tone not in dims["tone"]["values"]:
            warnings.append(f"[{pid}._meta.tone] 未知 tone '{tone}'")
    for sc in meta.get("scene", []):
        if sc not in dims["scene"]["values"]:
            warnings.append(f"[{pid}._meta.scene] 未知 scene '{sc}'")
    for em in ([meta["emotion"]] if meta.get("emotion") else []):
        if em not in dims["emotion"]["values"]:
            warnings.append(f"[{pid}._meta.emotion] 未知 emotion '{em}'")


def main() -> None:
    vocab = load_vocabulary()
    base_map = json.loads(DISPATCH_PATH.read_text(encoding="utf-8"))
    overlay_map = load_overlay()

    errors: list[str] = []
    warnings: list[str] = []

    # overlay 引用的 id 必须存在于 base
    for pid in overlay_map:
        if pid not in base_map:
            errors.append(f"[overlay] id '{pid}' 不在 phrase_dispatch.json 中")

    for pid, base in base_map.items():
        overlay = overlay_map.get(pid)
        if overlay:
            validate_overlay_meta(pid, overlay, vocab, warnings)
        merged = merge_dispatch(base, overlay)
        validate_dispatch_obj(pid, merged, vocab, errors, warnings)

    for w in warnings:
        print(f"⚠️  {w}")
    for e in errors:
        print(f"❌ {e}")

    overlaid = len(overlay_map)
    print(
        f"\n校验 {len(base_map)} 条 base（overlay 覆盖 {overlaid} 条）："
        f"{len(errors)} error, {len(warnings)} warning"
    )
    if errors:
        raise SystemExit(1)
    print("✅ 全部合法")


if __name__ == "__main__":
    main()
