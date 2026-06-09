#!/usr/bin/env python3
"""将收集的啡快口令语料嵌入 ios/Shared/Resources/phrases.json

数据源（唯一）：仓库根目录 starbucks_now_passphrases.csv
不合并生成语料、不合并 lab/v2。

同时生成 corpus_bundled_meta.json（版本号 + SHA256，供静态热更新校验）。

色板 nippon_colors.json 已入库；若需从上游刷新：
  curl -o /tmp/nipponcolor.json https://raw.githubusercontent.com/lcat/nippon-colors/master/nipponcolor.json
  再运行 scripts/curate_nippon_colors.py（如有）
"""
import csv
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
from dispatch_overlay import load_overlay, merge_dispatch, strip_for_embed  # noqa: E402
SOURCE = ROOT / "starbucks_now_passphrases.csv"
EN_MAP = ROOT / "scripts" / "phrases_en.json"
DISPATCH_MAP = ROOT / "scripts" / "phrase_dispatch.json"
VERSION_FILE = ROOT / "config" / "corpus_version.txt"
OUT = ROOT / "ios" / "Shared" / "Resources" / "phrases.json"
META_OUT = ROOT / "ios" / "Shared" / "Resources" / "corpus_bundled_meta.json"

ANCHOR_EVIDENCE = frozenset({"official_text", "image_verified"})


def theme_slug(theme: str) -> str:
    """主题标签 → 稳定 ASCII id（emotionTheme 字段）。"""
    mapping = {
        "好运祝福": "luck_blessing",
        "治愈劝慰": "light_comfort",
        "治愈鼓励": "light_comfort",
        "治愈祝福": "light_comfort",
        "自我肯定": "self_affirmation",
        "行动鼓励": "gentle_departure",
        "前路祝福": "soft_hope",
        "未来祝福": "soft_hope",
        "美好祝福": "soft_hope",
        "生活浪漫": "daily_romance",
        "季节画面": "daily_romance",
        "季节景象": "daily_romance",
        "季节心情": "daily_romance",
        "季节文艺": "daily_romance",
        "生活态度": "daily_romance",
        "情感表达": "daily_romance",
        "自由浪漫": "daily_romance",
        "诗性意象": "lyric_image",
        "日常提醒": "daily_romance",
        "从容劝慰": "light_comfort",
        "从容治愈": "light_comfort",
        "状态鼓励": "soft_hope",
        "人生感怀": "quiet_mirror",
        "人生鼓励": "gentle_departure",
        "旅途祝愿": "gentle_departure",
        "旅途浪漫": "daily_romance",
        "出行祝福": "soft_hope",
        "相见温情": "daily_romance",
        "新起点": "gentle_departure",
        "节日祝福": "luck_blessing",
        "联名主题": "ip_collab",
        "IP玩梗": "ip_collab",
        "IP身份": "ip_collab",
        "歌词玩梗": "ip_collab",
        "影视玩梗": "ip_collab",
        "武侠玩梗": "playful_meme",
        "玩梗": "playful_meme",
        "身份玩梗": "playful_meme",
        "身份标签": "playful_meme",
        "网络口语": "playful_meme",
        "方言口语": "playful_meme",
        "城市口语": "playful_meme",
        "咖啡谐音与好运": "playful_meme",
        "流行文化与安慰": "playful_meme",
        "英文鼓励": "latin_phrase",
        "英文祝福": "latin_phrase",
        "亲昵身份": "playful_meme",
        "鼓励": "gentle_departure",
        "即时心情": "daily_romance",
        "自然季节": "daily_romance",
        "速度与武侠": "playful_meme",
        "歌曲与季节": "daily_romance",
        "治愈肯定": "light_comfort",
        "网络流行语": "playful_meme",
        "春季诗意": "daily_romance",
        "希望鼓励": "soft_hope",
        "鼓励玩梗": "playful_meme",
        "身份自夸": "self_affirmation",
        "口语玩梗": "playful_meme",
        "好运身份": "luck_blessing",
        "食物奇趣": "playful_meme",
        "网络鼓励": "playful_meme",
        "夏日祝福": "luck_blessing",
        "鼓励祝福": "soft_hope",
        "好运预告": "soft_hope",
        "月份希望": "soft_hope",
        "称呼玩梗": "playful_meme",
        "成长鼓励": "gentle_departure",
        "顺遂祝福": "soft_hope",
        "努力鼓励": "gentle_departure",
        "收获祝福": "luck_blessing",
        "自由鼓励": "gentle_departure",
        "未来鼓励": "soft_hope",
        "生活祝福": "soft_hope",
        "夏日场景": "daily_romance",
        "夏日景象": "daily_romance",
        "夏日行动": "gentle_departure",
        "秋季饮品": "daily_romance",
        "秋季心情": "daily_romance",
        "秋季温柔": "daily_romance",
        "冬季温暖": "daily_romance",
        "秋夜诗意": "lyric_image",
        "平安祝福": "luck_blessing",
        "财运祝福": "luck_blessing",
        "长久祝福": "luck_blessing",
        "夸张祝福": "playful_meme",
        "夸赞鼓励": "self_affirmation",
        "人格鼓励": "self_affirmation",
        "热爱鼓励": "gentle_departure",
        "生活鼓励": "gentle_departure",
        "前路安慰": "light_comfort",
        "浪漫祝福": "daily_romance",
        "远方浪漫": "daily_romance",
        "转运祝福": "light_comfort",
        "文艺治愈": "light_comfort",
        "新年祝福": "luck_blessing",
        "日常玩梗": "playful_meme",
        "学习鼓励": "gentle_departure",
        "哈利波特联名": "ip_collab",
    }
    t = theme.strip()
    if t in mapping:
        return mapping[t]
    slug = re.sub(r"[^\w]+", "_", t).strip("_").lower()
    return slug or "collected"


def load_en_map() -> dict[str, str]:
    if not EN_MAP.exists():
        raise SystemExit(
            f"Missing {EN_MAP}. Run: python3 scripts/starbucks_phrases_en.py"
        )
    return json.loads(EN_MAP.read_text(encoding="utf-8"))


def load_dispatch_map() -> dict[str, dict]:
    if not DISPATCH_MAP.exists():
        raise SystemExit(
            f"Missing {DISPATCH_MAP}. Run: python3 scripts/tag_phrases_rules.py"
        )
    return json.loads(DISPATCH_MAP.read_text(encoding="utf-8"))


def read_corpus_version() -> int:
    if not VERSION_FILE.exists():
        raise SystemExit(f"Missing {VERSION_FILE}")
    raw = VERSION_FILE.read_text(encoding="utf-8").strip()
    return int(raw)


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing corpus: {SOURCE}")

    en_map = load_en_map()
    dispatch_map = load_dispatch_map()
    overlay_map = load_overlay()
    corpus_version = read_corpus_version()
    phrases = []
    seen: set[str] = set()

    with SOURCE.open(encoding="utf-8") as f:
        for row in csv.DictReader(f):
            text = row["phrase"].strip()
            if not text or text in seen:
                continue
            seen.add(text)

            evidence = row.get("evidence", "").strip()
            layer = "anchor" if evidence in ANCHOR_EVIDENCE else "active"

            pid = f"sb_{row['id'].strip()}"
            text_en = en_map.get(pid, "")
            if not text_en:
                raise SystemExit(f"Missing textEn for {pid} in {EN_MAP}")

            base = dispatch_map.get(pid)
            if not base:
                raise SystemExit(f"Missing dispatch for {pid} in {DISPATCH_MAP}")

            merged = merge_dispatch(base, overlay_map.get(pid))
            dispatch = strip_for_embed(merged)

            phrases.append({
                "id": pid,
                "text": text,
                "textEn": text_en,
                "layer": layer,
                "emotionTheme": theme_slug(row.get("theme", "")),
                "dispatch": dispatch,
            })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(phrases, ensure_ascii=False, indent=2) + "\n"
    OUT.write_text(payload, encoding="utf-8")
    digest = sha256_hex(payload.encode("utf-8"))

    generated_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    meta = {
        "corpusVersion": corpus_version,
        "generatedAt": generated_at,
        "phraseCount": len(phrases),
        "phrasesSHA256": digest,
    }
    META_OUT.write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    anchors = sum(1 for p in phrases if p["layer"] == "anchor")
    missing = len(en_map) - len(phrases)
    extra = f", en_map +{missing}" if missing > 0 else ""
    print(
        f"Wrote {len(phrases)} phrases v{corpus_version} ({anchors} anchor{extra})"
        f"\n  → {OUT}\n  → {META_OUT}\n  sha256={digest[:16]}…"
    )


if __name__ == "__main__":
    main()
