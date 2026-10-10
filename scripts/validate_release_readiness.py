#!/usr/bin/env python3
"""Static App Store readiness checks for Oraculo."""

from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

from corpus_release_guard import unresolved_rights_ids
from publish_corpus_static import asset_filename, calendar_asset_filename
from calendar_release import build_calendar_asset, validate_calendar
from validate_app_store_assets import validate_repository as validate_app_store_assets


ROOT = Path(__file__).resolve().parents[1]
IOS = ROOT / "ios"
APP_PRIVACY = IOS / "Oraculo" / "PrivacyInfo.xcprivacy"
WIDGET_PRIVACY = IOS / "OraculoWidget" / "PrivacyInfo.xcprivacy"
PROJECT_YML = IOS / "project.yml"
PBXPROJ = IOS / "Oraculo.xcodeproj" / "project.pbxproj"
APP_FILE = IOS / "Oraculo" / "OraculoApp.swift"
LOCATION_PROVIDER = IOS / "Shared" / "LocationContextProvider.swift"
WEATHER_SERVICE = IOS / "Shared" / "OpenMeteoWeatherService.swift"
BUNDLED_META = IOS / "Shared" / "Resources" / "corpus_bundled_meta.json"
BUNDLED_PHRASES = IOS / "Shared" / "Resources" / "phrases.json"
PUBLIC_MANIFEST = ROOT / "public" / "oraculo" / "manifest.json"
PUBLIC_CORPUS = ROOT / "public" / "oraculo"
EDITORIAL_REVIEW = ROOT / "config" / "phrase_editorial_review.json"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def check_corpus_rights(errors: list[str], review: dict | None = None) -> None:
    if review is None:
        if not EDITORIAL_REVIEW.exists():
            fail(errors, f"editorial review missing: {EDITORIAL_REVIEW.relative_to(ROOT)}")
            return
        review = load_json(EDITORIAL_REVIEW)
    blocked = unresolved_rights_ids(review)
    if blocked:
        fail(
            errors,
            "unresolved account-holder rights review blocks release: "
            + ", ".join(blocked),
        )


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_privacy_manifest(path: Path, label: str, errors: list[str]) -> None:
    if not path.exists():
        fail(errors, f"{label}: missing {path.relative_to(ROOT)}")
        return

    with path.open("rb") as f:
        manifest = plistlib.load(f)
    api_types = manifest.get("NSPrivacyAccessedAPITypes", [])
    user_defaults = [
        entry for entry in api_types
        if entry.get("NSPrivacyAccessedAPIType") == "NSPrivacyAccessedAPICategoryUserDefaults"
    ]
    if not user_defaults:
        fail(errors, f"{label}: missing UserDefaults required-reason API declaration")
        return
    reasons = set()
    for entry in user_defaults:
        reasons.update(entry.get("NSPrivacyAccessedAPITypeReasons", []))
    if "CA92.1" not in reasons:
        fail(errors, f"{label}: UserDefaults required-reason API must include CA92.1")


def check_project_references(errors: list[str]) -> None:
    yml = read_text(PROJECT_YML)
    pbx = read_text(PBXPROJ)
    if "PrivacyInfo.xcprivacy" not in yml:
        fail(errors, "project.yml must include PrivacyInfo.xcprivacy resources")
    if "PrivacyInfo.xcprivacy" not in pbx:
        fail(errors, "generated project must include PrivacyInfo.xcprivacy resources")
    if "INFOPLIST_KEY_UIRequiresFullScreen: YES" not in yml:
        fail(errors, "project.yml must set UIRequiresFullScreen for portrait-only v1")
    if "INFOPLIST_KEY_UIRequiresFullScreen = YES;" not in pbx:
        fail(errors, "generated project must set UIRequiresFullScreen for portrait-only v1")


def check_location_opt_in(errors: list[str]) -> None:
    app = read_text(APP_FILE)
    provider = read_text(LOCATION_PROVIDER)
    weather = read_text(WEATHER_SERVICE)

    guarded_refresh = (
        "if LocationContextProvider.isLocationContextEnabled" in app
        and "LocationContextProvider.shared.refreshIfNeeded()" in app
    )
    if "LocationContextProvider.shared.refreshIfNeeded()" in app and not guarded_refresh:
        fail(errors, "OraculoApp active scene must not automatically request location")
    if "isLocationContextEnabled" not in provider:
        fail(errors, "LocationContextProvider must gate requests behind an explicit opt-in flag")
    if re.search(r"return\s+31\.2304|return\s+121\.4737", weather):
        fail(errors, "OpenMeteoWeatherService must not default to Shanghai coordinates")
    if "refreshSharedCacheIfPossible" not in weather:
        fail(errors, "OpenMeteoWeatherService should expose a no-coordinate safe refresh path")


def check_corpus_alignment(
    errors: list[str],
    *,
    require_public_alignment: bool = True,
) -> None:
    meta = load_json(BUNDLED_META)
    manifest = load_json(PUBLIC_MANIFEST)
    bundled_hash = sha256(BUNDLED_PHRASES)
    phrases_url = str(manifest.get("phrases", {}).get("url", ""))
    public_filename = Path(urlparse(phrases_url).path).name
    public_phrases = PUBLIC_CORPUS / public_filename

    if meta.get("phrasesSHA256") != bundled_hash:
        fail(errors, "bundled meta phrasesSHA256 does not match bundled phrases.json")
    if not public_filename or not public_phrases.exists():
        fail(errors, f"public manifest asset does not exist: {public_filename or '(missing URL)'}")
        return

    public_hash = sha256(public_phrases)
    if manifest.get("phrases", {}).get("sha256") != public_hash:
        fail(errors, f"public manifest sha256 does not match {public_filename}")
    if require_public_alignment:
        if meta.get("corpusVersion") != manifest.get("corpusVersion"):
            fail(errors, "bundled and public corpusVersion must match before release")
        if meta.get("phrasesSHA256") != manifest.get("phrases", {}).get("sha256"):
            fail(errors, "bundled and public phrases SHA must match before release")

    version = manifest.get("corpusVersion")
    digest = str(manifest.get("phrases", {}).get("sha256", ""))
    if isinstance(version, int) and version >= 8:
        try:
            expected_filename = asset_filename(version, digest)
        except ValueError as error:
            fail(errors, f"invalid public corpus asset metadata: {error}")
        else:
            if public_filename != expected_filename:
                fail(
                    errors,
                    f"public corpus v{version} must reference immutable asset {expected_filename}",
                )
    bundled_calendar = BUNDLED_PHRASES.parent / "calendar.json"
    if meta.get("calendarVersion") is not None:
        if not bundled_calendar.exists():
            fail(errors, "bundled calendar.json is missing")
        else:
            calendar = load_json(bundled_calendar)
            errors.extend(validate_calendar(calendar, meta["corpusVersion"], load_json(BUNDLED_PHRASES)))
            if meta.get("calendarVersion") != meta["corpusVersion"] or meta.get("calendarSHA256") != sha256(bundled_calendar):
                fail(errors, "bundled calendar metadata mismatch")
            expected = build_calendar_asset(
                load_json(ROOT / "config" / "festivals_cn.json"),
                load_json(ROOT / "config" / "solar_terms_cn.json"),
                version=meta["corpusVersion"],
            )
            if bundled_calendar.read_bytes() != expected:
                fail(errors, "bundled calendar differs from source configs; run embed_corpus.py")
    if manifest.get("releaseVersion") is not None or manifest.get("calendar") is not None:
        if manifest.get("releaseVersion") != version:
            fail(errors, "manifest releaseVersion and corpusVersion must match")
        calendar_asset = manifest.get("calendar") or {}
        calendar_filename = Path(urlparse(str(calendar_asset.get("url", ""))).path).name
        public_calendar = PUBLIC_CORPUS / calendar_filename
        if not calendar_filename or not public_calendar.is_file():
            fail(errors, "public calendar asset is missing")
        else:
            errors.extend(validate_calendar(load_json(public_calendar), version, load_json(public_phrases)))
            calendar_digest = str(calendar_asset.get("sha256", ""))
            if sha256(public_calendar) != calendar_digest:
                fail(errors, "public calendar SHA mismatch")
            try:
                if calendar_filename != calendar_asset_filename(version, calendar_digest):
                    fail(errors, "public calendar must use an immutable asset filename")
            except ValueError as error:
                fail(errors, str(error))
            if require_public_alignment and meta.get("calendarSHA256") != calendar_digest:
                fail(errors, "bundled and public calendar SHA must match before release")
        if not manifest.get("minAppVersion") or tuple(map(int, manifest["minAppVersion"].split("."))) < (1, 1, 0):
            fail(errors, "calendar releases require minAppVersion >= 1.1.0")
    elif require_public_alignment and meta.get("calendarVersion") is not None:
        fail(errors, "public manifest must include the bundled calendar release")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--allow-unpublished-candidate",
        action="store_true",
        help="Validate the local bundle and existing public release independently without requiring version/SHA parity.",
    )
    args = parser.parse_args(argv)
    errors: list[str] = []
    errors.extend(validate_app_store_assets(ROOT))
    check_privacy_manifest(APP_PRIVACY, "Oraculo app", errors)
    check_privacy_manifest(WIDGET_PRIVACY, "Oraculo widget", errors)
    check_project_references(errors)
    check_location_opt_in(errors)
    if not args.allow_unpublished_candidate:
        check_corpus_rights(errors)
    check_corpus_alignment(
        errors,
        require_public_alignment=not args.allow_unpublished_candidate,
    )

    if errors:
        print("Release readiness checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    label = "Candidate" if args.allow_unpublished_candidate else "Release"
    print(f"✅ {label} readiness checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
