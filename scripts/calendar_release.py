"""Shared calendar serialization and release validation."""
from __future__ import annotations

from datetime import date
import json
import re


def build_calendar_asset(festivals: dict, solar_terms: dict, *, version: int) -> bytes:
    calendar = {
        "version": version,
        "timezone": "Asia/Shanghai",
        "festivals": festivals["festivals"],
        "solar_terms": solar_terms["years"],
    }
    return (json.dumps(calendar, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def valid_date_token(value: str) -> bool:
    if not isinstance(value, str) or not re.fullmatch(r"(?:\d{4}-)?\d{2}-\d{2}", value):
        return False
    try:
        date.fromisoformat("2000-" + value if len(value) == 5 else value)
        return True
    except ValueError:
        return False


def validate_calendar(calendar: dict, version: int, phrases: list | None = None) -> list[str]:
    errors: list[str] = []
    if not isinstance(calendar, dict):
        return ["calendar must be an object"]
    if calendar.get("version") != version:
        errors.append("calendar version must match release version")
    if calendar.get("timezone") != "Asia/Shanghai":
        errors.append("calendar timezone must be Asia/Shanghai")
    festivals = calendar.get("festivals")
    terms_by_year = calendar.get("solar_terms")
    if not isinstance(festivals, list) or not isinstance(terms_by_year, dict):
        return errors + ["calendar must contain festivals and solar_terms"]
    festival_ids: set[str] = set()
    term_ids: set[str] = set()
    for festival in festivals:
        if not isinstance(festival, dict):
            errors.append("festival must be an object")
            continue
        fid = festival.get("id")
        if not isinstance(fid, str) or not fid or fid in festival_ids:
            errors.append(f"invalid or duplicate festival id: {fid}")
            continue
        festival_ids.add(fid)
        for name in ("pre_days", "post_days"):
            value = festival.get(name, 0)
            if type(value) is not int or not 0 <= value <= 366:
                errors.append(f"{fid}: invalid {name}")
        ranges = festival.get("ranges")
        if not isinstance(ranges, list):
            errors.append(f"{fid}: ranges must be an array")
            continue
        for window in ranges:
            if not isinstance(window, dict) or not all(
                valid_date_token(window.get(key)) for key in ("start", "end")
            ):
                errors.append(f"{fid}: invalid date range")
        recurrence = festival.get("recurrence")
        if recurrence is not None:
            if not isinstance(recurrence, dict) or (
                recurrence.get("type") != "nth_weekday_of_month"
                or any(type(recurrence.get(key)) is not int or not lo <= recurrence[key] <= hi
                       for key, lo, hi in (("month", 1, 12), ("weekday", 1, 7), ("ordinal", 1, 5)))
            ):
                errors.append(f"{fid}: invalid recurrence")
    for year, terms in terms_by_year.items():
        if not re.fullmatch(r"\d{4}", year) or not isinstance(terms, list):
            errors.append(f"invalid solar term year: {year}")
            continue
        seen: set[str] = set()
        for term in terms:
            if not isinstance(term, dict):
                errors.append(f"{year}: solar term must be an object")
                continue
            tid, start = term.get("id"), term.get("start")
            if not isinstance(tid, str) or not tid or tid in seen:
                errors.append(f"{year}: invalid or duplicate solar term id")
                continue
            seen.add(tid)
            term_ids.add(tid)
            if not valid_date_token(start) or not start.startswith(year + "-"):
                errors.append(f"{year}/{tid}: invalid start date")
    for phrase in phrases or []:
        dispatch = phrase.get("dispatch") or {}
        rules = dispatch.get("onlyWhen", []) + dispatch.get("dateBinding", {}).get("rules", [])
        for rule in rules:
            dim, _, value = rule.partition(":")
            if (dim == "festival" and value not in festival_ids
                    or dim == "solar_term" and value not in term_ids
                    or dim == "month_day" and (len(value) != 5 or not valid_date_token(value))):
                errors.append(f"{phrase.get('id')}: calendar cannot resolve {rule}")
    return errors
