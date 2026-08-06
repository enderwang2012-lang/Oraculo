#!/usr/bin/env python3
"""Build the explicit 248-row editorial review and derived corpus metadata."""
from __future__ import annotations

import csv
import json
from pathlib import Path

from starbucks_phrases_en import TRANSLATIONS

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "starbucks_now_passphrases.csv"
REVIEW_JSON = ROOT / "config" / "phrase_editorial_review.json"
REVIEW_CSV = ROOT / "review" / "corpus_review_2026_08_full.csv"
EN_MAP = ROOT / "scripts" / "phrases_en.json"
DISPATCH_OVERRIDES = ROOT / "config" / "phrase_dispatch_overrides.json"


# This is a content-first review of an unseen launch corpus. Historical
# lifecycle values are deliberately absent from the decision inputs.
KEEP_IDS = {
    "sb_10", "sb_12", "sb_13", "sb_20", "sb_22", "sb_29", "sb_31", "sb_37",
    "sb_39", "sb_41", "sb_49", "sb_50", "sb_51", "sb_52", "sb_68", "sb_69",
    "sb_74", "sb_77", "sb_78", "sb_93", "sb_95", "sb_96", "sb_102", "sb_111",
    "sb_113", "sb_116", "sb_118", "sb_122", "sb_124", "sb_129", "sb_131",
    "sb_133", "sb_138", "sb_140", "sb_142", "sb_148", "sb_150", "sb_157",
    "sb_162", "sb_164", "sb_165", "sb_169", "sb_174", "sb_175", "sb_176",
    "sb_177", "sb_183", "sb_188", "sb_189", "sb_195", "sb_197", "sb_198",
    "sb_201", "sb_205", "sb_206", "sb_208", "sb_210", "sb_217", "sb_219",
    "sb_227", "sb_237", "sb_238", "sb_241", "sb_242", "sb_245", "sb_246",
    "sb_247", "sb_248", "sb_252", "sb_256", "sb_264", "sb_267", "sb_268",
    "sb_274", "sb_277", "sb_278", "sb_281", "sb_282", "sb_287", "sb_290",
    "sb_291", "sb_294", "sb_300", "sb_2005", "sb_2006", "sb_2021", "sb_2023",
    "sb_2035", "sb_2041", "sb_2042", "sb_2043", "sb_2044", "sb_2045", "sb_2046",
    "sb_2047", "sb_2048", "sb_2050", "sb_2051", "sb_2052", "sb_2053", "sb_2054",
    "sb_2055", "sb_2056", "sb_2057", "sb_2058", "sb_2059", "sb_2060",
}

REWRITE_PROPOSALS = {
    "sb_3": ("今日尚好", "Today is holding up"),
    "sb_32": ("人间有晚风", "There is an evening breeze"),
    "sb_40": ("新岁有晴天", "Clear skies in the new year"),
    "sb_42": ("秋夜月明", "A bright autumn moon"),
    "sb_45": ("晨光初启", "First light unfolds"),
    "sb_61": ("秋天正好", "Autumn, just right"),
    "sb_76": ("浪漫未完", "Romance, unfinished"),
    "sb_83": ("悄悄开花", "Blooming quietly"),
    "sb_100": ("今夜初霜", "First frost tonight"),
    "sb_144": ("有趣有盼", "Joy and something to hope for"),
    "sb_149": ("前路可奔赴", "A road worth taking"),
    "sb_181": ("抬头见天光", "Look up and find the light"),
    "sb_186": ("忙有度，闲有趣", "Work in measure, rest with joy"),
    "sb_190": ("玫瑰正开", "Roses in bloom"),
    "sb_240": ("知足于此刻", "Content in this moment"),
    "sb_266": ("远方可奔赴", "A horizon worth heading toward"),
    "sb_289": ("好奇未减", "Curiosity still alive"),
    "sb_2049": ("汗珠映着光", "Sweat beads catch the light"),
}

DIRECTIVE_IDS = {
    "sb_21", "sb_123", "sb_125", "sb_172", "sb_209",
    "sb_112", "sb_146", "sb_166", "sb_216", "sb_218", "sb_222", "sb_236", "sb_239",
    "sb_244", "sb_249", "sb_251", "sb_257", "sb_258", "sb_265", "sb_270",
}

GUARANTEE_IDS = {
    "sb_161", "sb_262", "sb_99", "sb_153", "sb_155", "sb_163", "sb_207",
    "sb_215", "sb_261",
    "sb_279", "sb_295", "sb_299",
}

SLOGAN_IDS = {
    "sb_70", "sb_117", "sb_151", "sb_154", "sb_5", "sb_25", "sb_58", "sb_71",
    "sb_91", "sb_107", "sb_108", "sb_109", "sb_121", "sb_141", "sb_147", "sb_152",
    "sb_158", "sb_160", "sb_187", "sb_213", "sb_214", "sb_221", "sb_228", "sb_243",
    "sb_250", "sb_269", "sb_271", "sb_272", "sb_275", "sb_286",
    "sb_288", "sb_292", "sb_304",
}

LOW_SIGNAL_IDS = {
    "sb_9", "sb_23", "sb_43", "sb_143", "sb_184", "sb_194", "sb_199",
    "sb_212", "sb_254", "sb_255", "sb_259", "sb_263", "sb_276", "sb_297", "sb_2001",
    "sb_2002", "sb_2003", "sb_2004", "sb_2022",
}

DUPLICATE_IDS = {"sb_128", "sb_130", "sb_220", "sb_293", "sb_302"}

EDITORIAL_THEME_TO_EMOTION = {
    "blessing": "luck_blessing",
    "connection": "daily_romance",
    "daily_mood": "daily_romance",
    "departure": "gentle_departure",
    "landscape": "daily_romance",
    "lyric_image": "lyric_image",
    "rest": "light_comfort",
    "seasonal_image": "daily_romance",
    "seasonal_blessing": "luck_blessing",
    "self_stance": "light_comfort",
    "soft_hope": "soft_hope",
    "time_reflection": "quiet_mirror",
    "wordplay": "playful_meme",
    "daily_observation": "daily_romance",
}


def has_any(text: str, words: tuple[str, ...]) -> bool:
    return any(word in text for word in words)


def editorial_theme(text: str, source_theme: str) -> str:
    if has_any(text, ("相见", "相逢", "见面", "爱", "执手", "牵手", "手牵手", "勾勾手", "家人", "朋友")):
        return "connection"
    if any(token in source_theme for token in ("身份", "玩梗", "网络", "流行", "方言", "英文", "武侠")):
        return "wordplay"
    if has_any(text, ("春", "夏", "秋", "冬", "霜", "小满", "蝉", "暖阳")) or any(
        token in source_theme for token in ("季节", "春季", "夏日", "秋季", "冬季")
    ):
        return "seasonal_image"
    if has_any(text, ("雨", "风", "云", "天空", "天高", "海", "山", "月亮", "明月", "微光", "长街")):
        return "landscape"
    if any(token in source_theme for token in ("诗", "歌词", "歌曲")):
        return "lyric_image"
    if has_any(text, ("昼夜", "时光", "钟", "懂得", "过半")) or "人生感怀" in source_theme:
        return "time_reflection"
    if has_any(text, ("将至", "正在", "路上", "期待", "好事", "好消息", "答案", "发芽", "奔来", "不期", "可期", "明朗")):
        return "soft_hope"
    if any(token in source_theme for token in ("前路祝福", "未来祝福")):
        return "soft_hope"
    if has_any(text, ("好运", "平安", "喜乐", "胜意", "诸事", "心愿", "所愿", "财神", "苹苹", "十全")):
        return "blessing"
    if any(token in source_theme for token in ("祝福", "顺遂", "收获")):
        if has_any(text, ("将至", "正在", "路上", "期待", "发芽", "奔来", "不期")):
            return "soft_hope"
        return "blessing"
    if has_any(text, ("歇", "缓", "慢", "清闲", "自在", "眉目", "清风")):
        return "rest"
    if any(token in source_theme for token in ("治愈", "劝慰", "从容")):
        return "rest"
    if "思路" in text:
        return "daily_mood"
    if has_any(text, ("出发", "远方", "路", "桥", "去", "走", "旷野", "千重浪")):
        return "departure"
    if any(token in source_theme for token in ("行动", "成长", "前路", "新起点")):
        return "departure"
    if has_any(text, ("新", "故事")):
        return "soft_hope"
    if has_any(text, ("心情", "开心", "明媚", "好奇", "状态")):
        return "daily_mood"
    if any(token in source_theme for token in ("自我", "人格", "状态", "生活态度")):
        return "self_stance"
    return "daily_observation"


def semantic_cluster(text: str, source_theme: str) -> str:
    if any(token in source_theme for token in ("玩梗", "网络", "流行", "身份", "英文", "方言", "武侠")):
        return "playful_wordplay"
    if has_any(text, ("雨", "伞", "淋")):
        return "weather_rain"
    if has_any(text, ("风", "云", "天空", "天高", "长街")):
        return "sky_wind"
    if has_any(text, ("海", "浪", "潜水", "桥", "山", "远方", "旷野")):
        return "distance_landscape"
    if has_any(text, ("春", "夏", "秋", "冬", "蝉", "霜", "小满", "暖阳")) or any(
        token in source_theme for token in ("季节", "春季", "夏日", "秋季", "冬季")
    ):
        return "seasonal_nature"
    if has_any(text, ("昼夜", "时光", "钟", "懂得", "过半")):
        return "time_reflection"
    if has_any(text, ("歇", "缓", "慢", "清闲", "凉", "自在", "眉目")):
        return "rest_pause"
    if has_any(text, ("相见", "相逢", "见面", "爱", "执手", "牵手", "手牵手", "勾勾手", "家人")):
        return "connection"
    if "思路" in text:
        return "daily_mood"
    if has_any(text, ("出发", "去", "走", "路", "奔赴", "新起点", "新序章")):
        return "departure_motion"
    if has_any(text, ("好事", "好消息", "期待", "答案", "发芽", "明朗", "可期")):
        return "hope_arrival"
    if has_any(text, ("好运", "平安", "喜乐", "胜意", "诸事", "心愿", "所愿", "财神")):
        return "blessing_wish"
    if "年" in text:
        return "time_reflection"
    if has_any(text, ("心情", "开心", "明媚", "好奇", "状态")):
        return "daily_mood"
    if any(token in source_theme for token in ("诗", "歌词", "歌曲")):
        return "lyric_image"
    if has_any(text, ("心", "自己", "自由", "坦荡")):
        return "self_stance"
    return "daily_observation"


def cadence_group(text: str, source_theme: str) -> str:
    length = len(text)
    if "英文" in source_theme:
        return "wordplay_latin"
    if any(token in source_theme for token in ("玩梗", "网络", "流行", "方言", "身份", "武侠")):
        return "wordplay_social"
    if "思路" in text:
        return "mood_state"
    if any(token in text for token in ("不", "无", "别", "允许", "保持", "听从", "重要的是")):
        return "stance_short" if length <= 4 else "stance_sentence"
    if any(token in text for token in ("正在", "将至", "加载", "发芽", "奔来", "路上", "等一场", "期待")):
        return "process_arrival"
    if any(token in text for token in ("平安", "喜乐", "胜意", "好运", "好事", "心愿", "所愿", "诸事", "皆", "宜")):
        return "blessing_parallel"
    if any(token in text for token in ("与", "和", "亦", "也", "为我", "杯中", "有诗有")):
        return "relational_phrase"
    if any(token in text for token in ("去", "走", "出发", "向", "奔赴", "远方", "千重浪")):
        return "departure_action"
    if any(token in text for token in ("雨", "风", "云", "海", "山", "蝉", "月", "霜", "长街")):
        return "landscape_image" if length >= 5 else "short_image"
    if any(token in text for token in ("时光", "昼夜", "钟", "过半", "懂得")):
        return "time_observation"
    if any(token in text for token in ("歇", "缓", "慢", "自在", "眉目", "清闲")):
        return "rest_state"
    if any(token in text for token in ("心情", "开心", "明媚", "好奇", "状态", "轻松")):
        return "mood_state"
    if "年" in text:
        return "time_observation"
    if length <= 4:
        if any(token in source_theme for token in ("祝福", "好运", "财运", "新年", "节日", "收获", "顺遂")):
            return "short_blessing"
        if any(token in source_theme for token in ("鼓励", "肯定", "劝慰", "治愈", "生活态度", "状态")):
            return "short_state"
        return "short_plain"
    if length <= 7:
        if any(token in source_theme for token in ("行动", "未来", "新起点")):
            return "medium_action"
        if any(token in source_theme for token in ("鼓励", "肯定", "劝慰", "治愈", "状态")):
            return "medium_state"
        if any(token in source_theme for token in ("祝福", "好运", "节日", "美好")):
            return "medium_blessing"
        return "medium_plain"
    return "long_sentence"


def retire_reason(pid: str, source_theme: str) -> str:
    if pid in DUPLICATE_IDS:
        return "退出：与更自然或更有画面的保留条目语义重复"
    if pid in DIRECTIVE_IDS:
        return "退出：命令、训诫或自我管理口吻过强，替读者下结论"
    if pid in GUARANTEE_IDS:
        return "退出：把愿望写成确定结果，承诺过满"
    if pid in SLOGAN_IDS:
        return "退出：广告、励志口号或社交媒体模板感过强"
    if pid in LOW_SIGNAL_IDS:
        return "退出：独立成签的信息量不足，或场景过窄"
    if any(token in source_theme for token in ("玩梗", "网络", "流行", "身份", "英文", "联名", "方言")):
        return "退出：依赖身份、IP、联名、方言或网络语境，离开原场景后失真"
    return "退出：表达生硬、偏泛或缺少可感知的画面与关系"


def review_code(pid: str, decision: str, source_theme: str) -> str:
    if decision == "keep":
        return "approved_initial"
    if decision == "needs_rewrite":
        return "rewrite_language"
    if pid in DUPLICATE_IDS:
        return "duplicate"
    if pid in DIRECTIVE_IDS:
        return "directive_or_preachy"
    if pid in GUARANTEE_IDS:
        return "result_guarantee"
    if pid in SLOGAN_IDS:
        return "slogan_or_template"
    if pid in LOW_SIGNAL_IDS:
        return "low_signal_or_narrow"
    if any(token in source_theme for token in ("玩梗", "网络", "流行", "身份", "英文", "联名", "方言")):
        return "context_or_ip_dependency"
    return "awkward_or_generic"


def keep_reason(pid: str, theme: str) -> str:
    if theme in {"landscape", "seasonal_image"}:
        return "保留：具体物象和季节触感能独立承载情绪"
    if theme in {"rest", "time_reflection"}:
        return "保留：给出轻安顿或时间观察，没有要求读者表态"
    if theme in {"connection", "soft_hope"}:
        return "保留：关系或过程表达自然，仍给读者留下投射空间"
    if theme == "blessing":
        return "保留：作为初始好运签简短自然，未因假定曝光而降级"
    return "保留：短句自然，有人味，能在静屏上独立成立"


def source_category(evidence: str) -> str:
    if evidence == "generated":
        return "editorial_original"
    if evidence == "user_provided":
        return "user_provided"
    return "external_observed"


def rights_status(evidence: str) -> str:
    if evidence == "generated":
        return "editorial_origin_recorded"
    if evidence == "user_provided":
        return "requires_account_holder_legal_review"
    return "external_source_recorded_no_clearance_claim"


def build_review(rows: list[dict[str, str]]) -> dict[str, dict[str, str]]:
    review: dict[str, dict[str, str]] = {}
    for row in rows:
        pid = f"sb_{row['id'].strip()}"
        text = row["phrase"].strip()
        source_theme = row.get("theme", "").strip()
        theme = editorial_theme(text, source_theme)
        proposal = REWRITE_PROPOSALS.get(pid)
        decision = "keep" if pid in KEEP_IDS else "needs_rewrite" if proposal else "retire"
        lifecycle = "active" if decision == "keep" else "retired"
        evidence = row.get("evidence", "").strip()
        review[pid] = {
            "phrase": text,
            "sourceTheme": source_theme,
            "evidence": evidence,
            "sourceId": row.get("source_id", "").strip(),
            "sourceCategory": source_category(evidence),
            "rightsStatus": rights_status(evidence),
            "reviewBasis": "fresh_initial_content_review",
            "decision": decision,
            "reviewCode": review_code(pid, decision, source_theme),
            "lifecycle": lifecycle,
            "proposedPhrase": proposal[0] if proposal else "",
            "proposedEnglish": proposal[1] if proposal else "",
            "editorialTheme": theme,
            "emotionTheme": EDITORIAL_THEME_TO_EMOTION[theme],
            "semanticCluster": semantic_cluster(text, source_theme),
            "cadenceGroup": cadence_group(text, source_theme),
            "english": TRANSLATIONS[pid],
            "englishStatus": "approved" if decision == "keep" else "review_after_rewrite" if proposal else "archived",
            "dispatchStatus": "manual" if pid in {
                "sb_100", "sb_164", "sb_188", "sb_2005", "sb_2006", "sb_2035",
                "sb_2052", "sb_2054",
            } else "rule",
            "reviewReason": (
                keep_reason(pid, theme)
                if decision == "keep"
                else "改写：保留原意或画面，去掉生硬、口号或过满部分；建议稿待人工确认"
                if proposal
                else retire_reason(pid, source_theme)
            ),
        }
    return review


def write_outputs(rows: list[dict[str, str]], review: dict[str, dict[str, str]]) -> None:
    REVIEW_JSON.parent.mkdir(parents=True, exist_ok=True)
    REVIEW_JSON.write_text(json.dumps(review, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    fields = [
        "id", "phrase", "english", "sourceTheme", "evidence", "sourceId", "sourceCategory",
        "rightsStatus", "reviewBasis", "decision", "reviewCode", "lifecycle", "proposedPhrase",
        "proposedEnglish", "editorialTheme", "emotionTheme", "semanticCluster", "cadenceGroup",
        "englishStatus", "dispatchStatus", "reviewReason",
    ]
    with REVIEW_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            pid = f"sb_{row['id'].strip()}"
            item = review[pid]
            writer.writerow({
                "id": pid,
                "phrase": row["phrase"].strip(),
                **{field: item[field] for field in fields if field not in {"id", "phrase"}},
            })

    EN_MAP.write_text(json.dumps(TRANSLATIONS, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    dispatch = json.loads(DISPATCH_OVERRIDES.read_text(encoding="utf-8"))
    dispatch.update({
        "sb_100": {
            "universal": False,
            "onlyWhen": ["season:autumn", "season:winter", "weather:snow"],
            "boost": [
                {"tag": "temp:cold", "weight": 2.0},
                {"tag": "solar_term:shuangjiang", "weight": 2.0},
            ],
        },
        "sb_188": {
            "universal": False,
            "onlyWhen": ["season:summer"],
            "boost": [{"tag": "solar_term:xiaoman", "weight": 2.0}],
        },
        "sb_2035": {
            "universal": False,
            "onlyWhen": ["month:7"],
            "boost": [{"tag": "month:7", "weight": 1.5}],
        },
        "sb_164": {
            "universal": False,
            "onlyWhen": ["season:spring"],
            "boost": [],
        },
        "sb_2052": {
            "universal": False,
            "onlyWhen": ["season:summer"],
            "boost": [],
        },
        "sb_2054": {
            "universal": False,
            "onlyWhen": ["season:summer"],
            "boost": [],
        },
    })
    DISPATCH_OVERRIDES.write_text(json.dumps(dispatch, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    with SOURCE.open(encoding="utf-8-sig") as handle:
        rows = [row for row in csv.DictReader(handle) if row.get("phrase", "").strip()]
    if len(rows) != 248:
        raise SystemExit(f"Expected 248 source rows, found {len(rows)}")
    review = build_review(rows)
    write_outputs(rows, review)
    counts = {decision: sum(item["decision"] == decision for item in review.values()) for decision in ("keep", "needs_rewrite", "retire")}
    print(f"Wrote explicit review for {len(review)} rows: " + ", ".join(f"{key}={value}" for key, value in counts.items()))


if __name__ == "__main__":
    main()
