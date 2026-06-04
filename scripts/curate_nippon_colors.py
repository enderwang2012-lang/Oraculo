#!/usr/bin/env python3
"""从 lcat/nippon-colors 生成 ios/Shared/Resources/nippon_colors.json"""
import json
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ios" / "Shared" / "Resources" / "nippon_colors.json"
URL = "https://raw.githubusercontent.com/lcat/nippon-colors/master/nipponcolor.json"

FORCE = {
    "nakabeni", "suoh", "kon", "ai", "sora", "mizu", "fuji", "matcha",
    "hanada", "shikon", "gunjo", "sumi", "enji", "kurenai",
}


def hex_to_rgb(h: str):
    h = h.strip().lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def luminance(r, g, b):
    def lin(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast(rgb, fg):
    la, lb = luminance(*rgb), luminance(*fg)
    hi, lo = (la, lb) if la >= lb else (lb, la)
    return (hi + 0.05) / (lo + 0.05)


def main():
    raw = json.loads(urllib.request.urlopen(URL, timeout=30).read())
    white, dark = (255, 255, 255), (26, 26, 28)
    curated = []
    for c in raw:
        rgb = hex_to_rgb(c["color"])
        lum = luminance(*rgb)
        cw, cd = contrast(rgb, white), contrast(rgb, dark)
        forced = c["name"] in FORCE
        if cw >= 3.0:
            fg = "light"
        elif cd >= 3.0:
            fg = "dark"
        elif forced:
            fg = "light" if lum < 0.55 else "dark"
        else:
            continue
        if lum > 0.90:
            continue
        curated.append({
            "id": c["id"],
            "name": c["name"],
            "cname": c["cname"],
            "hex": c["color"].upper(),
            "foreground": fg,
        })
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(curated, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(curated)} colors → {OUT}")


if __name__ == "__main__":
    main()
