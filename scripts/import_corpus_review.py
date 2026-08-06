#!/usr/bin/env python3
"""Import the account holder's 248-row XLSX review into corpus metadata.

The workbook is parsed directly from OOXML. In particular, shared-string cell
values are resolved before use so an empty shared string is never mistaken for
its numeric index.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
from collections import Counter
from pathlib import Path
from xml.etree import ElementTree as ET
from zipfile import ZipFile

from reset_corpus_review import (
DISPATCH_OVERRIDES,
    EDITORIAL_THEME_TO_EMOTION,
    REVIEW_CSV,
    REVIEW_JSON,
    SOURCE,
    cadence_group,
    editorial_theme,
    keep_reason,
    retire_reason,
    review_code,
    semantic_cluster,
)

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_WORKBOOK = (
    ROOT
    / "outputs"
    / "019fd20d-142a-73c1-b862-5ba2bad27a70"
    / "oraculo_corpus_review_2026_08.xlsx"
)
FINAL_DISPATCH = ROOT / "scripts" / "phrase_dispatch.json"
REVIEW_SHEETS = ("退出待确认", "改写待确认", "保留待确认")
VALID_DECISIONS = {"keep", "needs_rewrite", "retire"}
OOXML_NS = "http://schemas.openxmlformats.org/spreadsheetml/2006/main"
REL_NS = "http://schemas.openxmlformats.org/package/2006/relationships"
DOC_REL_NS = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"


# These are the final rewrite texts inferred from the account holder's explicit
# notes (when present) and the reviewed proposal columns (when no note exists).
FINAL_REWRITES: dict[str, tuple[str, str]] = {
    "sb_26": ("夏了夏天", "Summer in full swing"),
    "sb_83": ("悄悄惊艳", "Quietly dazzling"),
    "sb_140": ("答案在风中", "The answer is in the wind"),
    "sb_149": ("前路可奔赴", "A road worth taking"),
    "sb_181": ("抬头见天光", "Look up and find the light"),
    "sb_183": ("期待新故事", "Looking forward to new stories"),
    "sb_186": ("忙有度，闲有趣", "Work in measure, rest with joy"),
    "sb_212": ("元气满满", "Full of good energy"),
    "sb_266": ("奔赴", "Set forth"),
    "sb_278": ("明媚", "Radiance"),
    "sb_2022": ("甜还是咸", "Sweet or savory?"),
    "sb_2056": ("青山妩媚", "Green hills, graceful"),
    "sb_2057": ("孤独的海怪", "The lonely sea monster"),
}

# The account holder has confirmed these reviewed rewrites for the initial
# launch corpus.  They remain in proposed* fields as an audit trail, while the
# normalized decision below makes the reviewed copy publishable.
PROMOTED_REWRITE_IDS = frozenset(FINAL_REWRITES)


# Only notes containing an explicit "限定" are normalized as hard dispatch
# gates. Notes that merely say a phrase fits summer remain editorial context.
NOTE_DISPATCH_CONSTRAINTS: dict[str, list[str]] = {
    "sb_39": ["season:spring"],
    "sb_41": ["season:winter"],
    "sb_42": ["festival:mid_autumn"],
    "sb_49": ["festival:spring_festival"],
    "sb_50": ["festival:spring_festival"],
    "sb_51": ["festival:spring_festival"],
    "sb_52": ["festival:spring_festival"],
    "sb_68": ["festival:spring_festival"],
    "sb_78": ["festival:spring_festival"],
    "sb_81": ["festival:father_day"],
    "sb_99": ["festival:spring_festival"],
    "sb_101": ["festival:spring_festival"],
    "sb_194": ["festival:christmas"],
    "sb_222": ["festival:new_year"],
    "sb_257": ["festival:new_year"],
    "sb_263": ["festival:christmas"],
    "sb_273": ["festival:new_year"],
    "sb_2006": ["season:summer"],
    "sb_2021": ["festival:dragon_boat"],
    "sb_2022": ["festival:dragon_boat"],
    "sb_2047": ["solar_term:xiazhi"],
}


def _shared_strings(archive: ZipFile) -> list[str]:
    try:
        root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    except KeyError:
        return []
    ns = {"m": OOXML_NS}
    return [
        "".join(node.text or "" for node in item.findall(".//m:t", ns))
        for item in root.findall("m:si", ns)
    ]


def _worksheet_paths(archive: ZipFile) -> dict[str, str]:
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    relationships = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    targets = {
        rel.attrib["Id"]: rel.attrib["Target"]
        for rel in relationships.findall(f"{{{REL_NS}}}Relationship")
    }
    result: dict[str, str] = {}
    for sheet in workbook.findall(f".//{{{OOXML_NS}}}sheet"):
        rel_id = sheet.attrib[f"{{{DOC_REL_NS}}}id"]
        target = targets[rel_id].lstrip("/")
        result[sheet.attrib["name"]] = target if target.startswith("xl/") else f"xl/{target}"
    return result


def _column_name(reference: str) -> str:
    match = re.match(r"[A-Z]+", reference)
    if not match:
        raise ValueError(f"Invalid XLSX cell reference: {reference}")
    return match.group(0)


def _cell_text(cell: ET.Element, strings: list[str]) -> str:
    kind = cell.attrib.get("t")
    if kind == "inlineStr":
        return "".join(
            node.text or ""
            for node in cell.findall(f".//{{{OOXML_NS}}}t")
        )
    value = cell.find(f"{{{OOXML_NS}}}v")
    raw = "" if value is None else value.text or ""
    if kind == "s" and raw:
        return strings[int(raw)]
    return raw


def read_workbook_review(path: Path) -> dict[str, dict[str, str]]:
    with ZipFile(path) as archive:
        strings = _shared_strings(archive)
        sheets = _worksheet_paths(archive)
        review: dict[str, dict[str, str]] = {}
        for sheet_name in REVIEW_SHEETS:
            if sheet_name not in sheets:
                raise SystemExit(f"Workbook is missing sheet: {sheet_name}")
            root = ET.fromstring(archive.read(sheets[sheet_name]))
            rows = root.findall(f".//{{{OOXML_NS}}}sheetData/{{{OOXML_NS}}}row")
            if not rows:
                raise SystemExit(f"Workbook sheet is empty: {sheet_name}")
            values: list[dict[str, str]] = []
            for row in rows:
                values.append({
                    _column_name(cell.attrib["r"]): _cell_text(cell, strings)
                    for cell in row.findall(f"{{{OOXML_NS}}}c")
                })
            headers = {column: value for column, value in values[0].items()}
            by_header = {header: column for column, header in headers.items()}
            required = {"ID", "中文", "当前建议", "最终决定", "用户备注"}
            missing = sorted(required - set(by_header))
            if missing:
                raise SystemExit(f"{sheet_name} is missing columns: {', '.join(missing)}")
            for row in values[1:]:
                pid = row.get(by_header["ID"], "").strip()
                if not pid:
                    continue
                if pid in review:
                    raise SystemExit(f"Duplicate workbook review id: {pid}")
                review[pid] = {
                    "phrase": row.get(by_header["中文"], "").strip(),
                    "recommendation": row.get(by_header["当前建议"], "").strip(),
                    "decision": row.get(by_header["最终决定"], "").strip(),
                    "reviewerNote": row.get(by_header["用户备注"], "").strip(),
                }
    return review


def load_source_rows() -> list[dict[str, str]]:
    with SOURCE.open(encoding="utf-8-sig") as handle:
        return [row for row in csv.DictReader(handle) if row.get("phrase", "").strip()]


def import_review(
    source_rows: list[dict[str, str]],
    baseline: dict[str, dict],
    workbook_review: dict[str, dict[str, str]],
    dispatch_overrides: dict[str, dict] | None = None,
) -> dict[str, dict]:
    source_ids = {f"sb_{row['id'].strip()}" for row in source_rows}
    if len(source_rows) != 248 or len(source_ids) != 248:
        raise SystemExit(f"Expected 248 unique source rows, found {len(source_ids)}")
    if set(workbook_review) != source_ids:
        missing = sorted(source_ids - set(workbook_review))
        extra = sorted(set(workbook_review) - source_ids)
        raise SystemExit(f"Workbook/source ID mismatch; missing={missing}, extra={extra}")
    counts = Counter(item["decision"] for item in workbook_review.values())
    if set(counts) - VALID_DECISIONS:
        raise SystemExit(f"Invalid workbook decisions: {dict(counts)}")
    expected_counts = Counter({"keep": 148, "needs_rewrite": 13, "retire": 87})
    if counts != expected_counts:
        raise SystemExit(f"Unexpected workbook decision counts: {dict(counts)}")
    rewrite_ids = {pid for pid, item in workbook_review.items() if item["decision"] == "needs_rewrite"}
    if rewrite_ids != set(FINAL_REWRITES):
        raise SystemExit(
            "Workbook rewrite IDs do not match the approved rewrite set: "
            f"{sorted(rewrite_ids)}"
        )

    dispatch_overrides = dispatch_overrides or json.loads(
        DISPATCH_OVERRIDES.read_text(encoding="utf-8")
    )
    final_dispatch = json.loads(FINAL_DISPATCH.read_text(encoding="utf-8"))
    result: dict[str, dict] = {}
    for row in source_rows:
        pid = f"sb_{row['id'].strip()}"
        source_text = row["phrase"].strip()
        workbook_item = workbook_review[pid]
        if workbook_item["phrase"] != source_text:
            raise SystemExit(f"Workbook/source phrase mismatch for {pid}")
        workbook_decision = workbook_item["decision"]
        decision = (
            "keep"
            if workbook_decision == "needs_rewrite" and pid in PROMOTED_REWRITE_IDS
            else workbook_decision
        )
        proposal = FINAL_REWRITES.get(pid)
        reviewed_text = proposal[0] if proposal is not None else source_text
        source_theme = row.get("theme", "").strip()
        theme = editorial_theme(reviewed_text, source_theme)
        evidence = row.get("evidence", "").strip()
        previous = baseline.get(pid, {})
        lifecycle = "active" if decision == "keep" else "retired"
        # The review record must describe the actual final dispatch map for
        # every row.  ``dispatchStatus=manual`` is metadata only and cannot be
        # used as a proxy for the hard ``onlyWhen`` values.
        dispatch_constraint = list(final_dispatch.get(pid, {}).get("onlyWhen", []))
        result[pid] = {
            "phrase": source_text,
            "sourceTheme": source_theme,
            "evidence": evidence,
            "sourceId": row.get("source_id", "").strip(),
            "sourceCategory": previous.get("sourceCategory", ""),
            "rightsStatus": previous.get("rightsStatus", ""),
            "reviewBasis": "fresh_initial_content_review",
            "decision": decision,
            "reviewCode": review_code(pid, decision, source_theme),
            "lifecycle": lifecycle,
            "proposedPhrase": proposal[0] if proposal is not None else "",
            "proposedEnglish": proposal[1] if proposal is not None else "",
            "editorialTheme": theme,
            "emotionTheme": EDITORIAL_THEME_TO_EMOTION[theme],
            "semanticCluster": semantic_cluster(reviewed_text, source_theme),
            "cadenceGroup": cadence_group(reviewed_text, source_theme),
            "english": previous.get("english", ""),
            "englishStatus": (
                "approved" if decision == "keep"
                else "rewrite_ready" if decision == "needs_rewrite"
                else "archived"
            ),
            "dispatchStatus": (
                "manual" if pid in NOTE_DISPATCH_CONSTRAINTS or previous.get("dispatchStatus") == "manual"
                else "rule"
            ),
            "dispatchConstraint": dispatch_constraint,
            "reviewerNote": workbook_item["reviewerNote"],
            "reviewReason": (
                keep_reason(pid, theme)
                if decision == "keep"
                else "改写稿已整理：中文、英文与相关派发约束等待发布前终审"
                if workbook_decision == "needs_rewrite"
                else retire_reason(pid, source_theme)
            ),
        }
        if not result[pid]["sourceCategory"] or not result[pid]["rightsStatus"]:
            raise SystemExit(f"Missing source/rights baseline for {pid}")
        if not result[pid]["english"]:
            raise SystemExit(f"Missing English baseline for {pid}")
    return result


def write_review_outputs(source_rows: list[dict[str, str]], review: dict[str, dict]) -> None:
    REVIEW_JSON.write_text(json.dumps(review, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    fields = [
        "id", "phrase", "english", "sourceTheme", "evidence", "sourceId", "sourceCategory",
        "rightsStatus", "reviewBasis", "decision", "reviewCode", "lifecycle", "proposedPhrase",
        "proposedEnglish", "editorialTheme", "emotionTheme", "semanticCluster", "cadenceGroup",
        "englishStatus", "dispatchStatus", "dispatchConstraint", "reviewerNote", "reviewReason",
    ]
    with REVIEW_CSV.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in source_rows:
            pid = f"sb_{row['id'].strip()}"
            item = review[pid]
            writer.writerow({
                "id": pid,
                **{
                    field: json.dumps(item[field], ensure_ascii=False) if field == "dispatchConstraint" else item[field]
                    for field in fields
                    if field != "id"
                },
            })


def write_dispatch_constraints() -> None:
    overrides = json.loads(DISPATCH_OVERRIDES.read_text(encoding="utf-8"))
    for pid, only_when in NOTE_DISPATCH_CONSTRAINTS.items():
        existing = overrides.get(pid, {})
        overrides[pid] = {
            "universal": existing.get("universal", False),
            "onlyWhen": only_when,
            "boost": existing.get("boost", []),
        }
    DISPATCH_OVERRIDES.write_text(
        json.dumps(overrides, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("workbook", nargs="?", type=Path, default=DEFAULT_WORKBOOK)
    args = parser.parse_args(argv)
    if not args.workbook.exists():
        raise SystemExit(f"Missing review workbook: {args.workbook}")
    source_rows = load_source_rows()
    baseline = json.loads(REVIEW_JSON.read_text(encoding="utf-8"))
    workbook_review = read_workbook_review(args.workbook)
    dispatch_overrides = json.loads(DISPATCH_OVERRIDES.read_text(encoding="utf-8"))
    review = import_review(source_rows, baseline, workbook_review, dispatch_overrides)
    write_review_outputs(source_rows, review)
    write_dispatch_constraints()
    counts = Counter(item["decision"] for item in review.values())
    note_count = sum(bool(item["reviewerNote"]) for item in review.values())
    print(
        f"Imported {len(review)} workbook decisions: "
        f"keep={counts['keep']}, needs_rewrite={counts['needs_rewrite']}, "
        f"retire={counts['retire']}, notes={note_count}"
    )


if __name__ == "__main__":
    main()
