#!/usr/bin/env python3
"""Validate Oraculo's adaptive text color implementation guardrails."""
from __future__ import annotations

from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]

checks = [
    (
        ROOT / "ios/Shared/NipponColor.swift",
        [
            "struct NipponTextPalette",
            "enum NipponTextMode",
            "let textMode: NipponTextMode?",
            "var textPalette: NipponTextPalette",
            "var tertiaryTextColor: Color",
            "private var resolvedTextMode",
            "case .softInk",
            "family == \"orange\"",
            "primaryHex: \"2F2118\"",
            "secondaryHex: \"5E422F\"",
            "tertiaryHex: \"6D4D38\"",
            "secondaryHex: \"4F3A3D\"",
            "tertiaryHex: \"5F474B\"",
            "primaryHex: \"F8F5EA\"",
        ],
        [
            "usesLightText ? Color.white.opacity(0.96) : Color(white: 0.12)",
            "usesLightText ? Color.white.opacity(0.52) : Color(white: 0.12).opacity(0.45)",
            "secondaryHex: \"82756F\"",
            "tertiaryHex: \"958983\"",
            "secondaryOpacity: 0.9",
            "tertiaryOpacity: 0.84",
        ],
    ),
    (
        ROOT / "ios/OraculoWidget/PhraseWidgetViews.swift",
        [
            "entry.primaryTextColor",
            "entry.secondaryTextColor",
            "lockTextColor",
            "Color.white",
        ],
        [
            "entry.usesLightText ? .white.opacity(0.95) : Color(white: 0.12)",
            "entry.usesLightText ? .white.opacity(0.48) : Color(white: 0.12).opacity(0.42)",
            ".foregroundStyle(.secondary)",
        ],
    ),
    (
        ROOT / "ios/Oraculo/ContentView.swift",
        [
            "session.moment.nipponColor.tertiaryTextColor",
        ],
        [
            "session.usesLightText ? Color.white.opacity(0.52) : Color(white: 0.12).opacity(0.45)",
        ],
    ),
    (
        ROOT / "ios/Shared/DailyOracle.swift",
        [
            "sharedTodayColorTextModeKey",
            "moment.nipponColor.textMode?.rawValue",
            "colorTextMode: textMode",
        ],
        [],
    ),
    (
        ROOT / "ios/OraculoWidget/OraculoWidget.swift",
        [
            "let colorTextMode: String?",
            "colorTextMode: snapshot.colorTextMode",
            "colorTextMode: nippon.textMode?.rawValue",
        ],
        [],
    ),
]

failures: list[str] = []
for path, required, forbidden in checks:
    text = path.read_text(encoding="utf-8")
    for needle in required:
        if needle not in text:
            failures.append(f"{path.relative_to(ROOT)} missing required token: {needle}")
    for needle in forbidden:
        if needle in text:
            failures.append(f"{path.relative_to(ROOT)} still contains forbidden hard-coded color logic: {needle}")

colors = json.loads((ROOT / "ios/Shared/Resources/nippon_colors.json").read_text(encoding="utf-8"))
by_name = {color["name"]: color for color in colors}
expected_modes = {
    "kohbai": "softInk",
    "suoh": "paper",
    "nadeshiko": "ink",
}
for name, expected in expected_modes.items():
    actual = by_name.get(name, {}).get("textMode")
    if actual != expected:
        failures.append(f"nippon_colors.json {name} textMode is {actual!r}, expected {expected!r}")

if failures:
    print("Adaptive text color validation failed:")
    for failure in failures:
        print(f"- {failure}")
    raise SystemExit(1)

print("Adaptive text color validation passed.")
