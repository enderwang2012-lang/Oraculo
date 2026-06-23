#!/usr/bin/env python3
"""Static App Store readiness checks for Oraculo."""

from __future__ import annotations

import hashlib
import json
import plistlib
import re
import sys
from pathlib import Path


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
PUBLIC_PHRASES = ROOT / "public" / "oraculo" / "phrases.json"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


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


def check_corpus_alignment(errors: list[str]) -> None:
    meta = load_json(BUNDLED_META)
    manifest = load_json(PUBLIC_MANIFEST)
    bundled_hash = sha256(BUNDLED_PHRASES)
    public_hash = sha256(PUBLIC_PHRASES)

    if meta.get("phrasesSHA256") != bundled_hash:
        fail(errors, "bundled meta phrasesSHA256 does not match bundled phrases.json")
    if manifest.get("phrases", {}).get("sha256") != public_hash:
        fail(errors, "public manifest sha256 does not match public phrases.json")
    if meta.get("corpusVersion") != manifest.get("corpusVersion"):
        fail(errors, "bundled and public corpusVersion must match before release")
    if meta.get("phrasesSHA256") != manifest.get("phrases", {}).get("sha256"):
        fail(errors, "bundled and public phrases SHA must match before release")


def main() -> int:
    errors: list[str] = []
    check_privacy_manifest(APP_PRIVACY, "Oraculo app", errors)
    check_privacy_manifest(WIDGET_PRIVACY, "Oraculo widget", errors)
    check_project_references(errors)
    check_location_opt_in(errors)
    check_corpus_alignment(errors)

    if errors:
        print("Release readiness checks failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("✅ Release readiness checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
