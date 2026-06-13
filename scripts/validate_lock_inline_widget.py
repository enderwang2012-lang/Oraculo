#!/usr/bin/env python3
from pathlib import Path
import json
import re
import struct
import sys

checks = []

def check(name, ok):
    checks.append((name, ok))

views_path = Path("ios/OraculoWidget/PhraseWidgetViews.swift")
views = views_path.read_text()
inline_match = re.search(
    r"struct\s+LockInlineView\s*:\s*View\s*\{(?P<body>.*?)\n\}\n\nstruct\s+LockRectangularView",
    views,
    re.S,
)
if not inline_match:
    print("FAIL: LockInlineView block not found", file=sys.stderr)
    sys.exit(1)

inline_block = inline_match.group("body")
check("inline binds text to entry.phraseText", "entry.phraseText" in inline_block)
check("inline uses WidgetMarkInline text image", 'Text(Image("WidgetMarkInline"))' in inline_block and "Text(entry.phraseText)" in inline_block)
check("inline avoids Label", "Label" not in inline_block)
check("inline avoids custom title/icon closures", 'OraculoTypography.styledText' not in inline_block)
check("inline avoids HStack", "HStack" not in inline_block)
check("inline lock text is pure white", "lockTextColor = Color.white" in inline_block)
check("inline lock text avoids adaptive entry colors", "entry.primaryTextColor" not in inline_block and "entry.secondaryTextColor" not in inline_block)
check("inline lock text avoids opacity", ".opacity" not in inline_block)

rect_match = re.search(
    r"struct\s+LockRectangularView\s*:\s*View\s*\{(?P<body>.*?)\n\}\n\nextension\s+PhraseEntry",
    views,
    re.S,
)
if not rect_match:
    print("FAIL: LockRectangularView block not found", file=sys.stderr)
    sys.exit(1)

rect_block = rect_match.group("body")
check("rectangular lock text is pure white", "lockTextColor = Color.white" in rect_block)
check("rectangular lock text avoids adaptive entry colors", "entry.primaryTextColor" not in rect_block and "entry.secondaryTextColor" not in rect_block)
check("rectangular lock text avoids opacity", ".opacity" not in rect_block)

sync_path = Path("ios/Shared/DailyOracle.swift")
sync_source = sync_path.read_text()
sync_match = re.search(r"func\s+syncDisplayedMoment\(_\s+moment:\s+OracleMoment\)\s*\{(?P<body>.*?)\n    \}", sync_source, re.S)
if not sync_match:
    print("FAIL: syncDisplayedMoment block not found", file=sys.stderr)
    sys.exit(1)

sync_body = sync_match.group("body")
reload_index = sync_body.find("WidgetTimelineRefresher.reloadAllIfPossible()")
sync_index = sync_body.find("defaults.synchronize()")
check("shared defaults are flushed before widget reload", sync_index != -1 and reload_index != -1 and sync_index < reload_index)

for asset_path in [
    Path("ios/OraculoWidget/Assets.xcassets/WidgetMarkInline.imageset/Contents.json"),
    Path("ios/Oraculo/Assets.xcassets/WidgetMarkInline.imageset/Contents.json"),
]:
    asset_text = asset_path.read_text()
    asset_json = json.loads(asset_text)
    check(
        f"{asset_path} marks WidgetMark as template",
        asset_json.get("properties", {}).get("template-rendering-intent") == "template",
    )

for image_path, expected_size in [
    (Path("ios/OraculoWidget/Assets.xcassets/WidgetMarkInline.imageset/widget-mark-inline.png"), 20),
    (Path("ios/OraculoWidget/Assets.xcassets/WidgetMarkInline.imageset/widget-mark-inline@2x.png"), 40),
    (Path("ios/OraculoWidget/Assets.xcassets/WidgetMarkInline.imageset/widget-mark-inline@3x.png"), 60),
    (Path("ios/Oraculo/Assets.xcassets/WidgetMarkInline.imageset/widget-mark-inline.png"), 20),
    (Path("ios/Oraculo/Assets.xcassets/WidgetMarkInline.imageset/widget-mark-inline@2x.png"), 40),
    (Path("ios/Oraculo/Assets.xcassets/WidgetMarkInline.imageset/widget-mark-inline@3x.png"), 60),
]:
    if image_path.exists():
        with image_path.open("rb") as image_file:
            header = image_file.read(24)
        width, height = struct.unpack(">II", header[16:24])
        check(f"{image_path} is {expected_size}px square", width == expected_size and height == expected_size)
        data = image_path.read_bytes()
        check(f"{image_path} is not the tiny source asset", len(data) > 0)
    else:
        check(f"{image_path} exists", False)

failed = [name for name, ok in checks if not ok]
if failed:
    for name in failed:
        print(f"FAIL: {name}", file=sys.stderr)
    sys.exit(1)

print("Lock inline widget regression checks OK")
