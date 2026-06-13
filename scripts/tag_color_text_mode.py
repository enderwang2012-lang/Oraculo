#!/usr/bin/env python3
"""Assign textMode to Nippon colors for Oraculo UI typography.

textMode is a design-facing typography mode:
  ink     — deep ink text on light / muted backgrounds
  paper   — warm paper text on deep backgrounds
  softInk — softened deep ink on vivid mid-bright backgrounds
"""
from __future__ import annotations

import colorsys
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
COLORS_PATH = ROOT / "ios" / "Shared" / "Resources" / "nippon_colors.json"

SOFT_INK_FAMILIES = {"red", "pink", "orange", "yellow", "purple"}


def hex_to_hsl(hex_str: str) -> tuple[float, float, float]:
    h = hex_str.lstrip("#")
    r = int(h[0:2], 16) / 255
    g = int(h[2:4], 16) / 255
    b = int(h[4:6], 16) / 255
    hue, lightness, saturation = colorsys.rgb_to_hls(r, g, b)
    return hue * 360, saturation, lightness


def text_mode(color: dict) -> str:
    _, saturation, lightness = hex_to_hsl(color["hex"])
    foreground = color.get("foreground", "dark")
    family = color.get("family", "")

    if foreground == "dark":
        return "ink"

    if lightness < 0.48:
        return "paper"

    if family in SOFT_INK_FAMILIES and saturation >= 0.35:
        return "softInk"

    return "paper"


def main() -> None:
    colors = json.loads(COLORS_PATH.read_text(encoding="utf-8"))
    for color in colors:
        color["textMode"] = text_mode(color)
    COLORS_PATH.write_text(json.dumps(colors, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote textMode for {len(colors)} colors → {COLORS_PATH}")


if __name__ == "__main__":
    main()
