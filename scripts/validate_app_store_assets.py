#!/usr/bin/env python3
"""Validate repository-owned App Store release assets."""

from __future__ import annotations

import json
import plistlib
import re
import struct
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
METADATA_PATH = Path("app-store/metadata/zh-Hans.json")
REVIEW_NOTES_PATH = Path("app-store/review-notes.zh-Hans.md")
SCREENSHOT_PLAN_PATH = Path("app-store/screenshots/README.md")
PRIVACY_PAGE_PATH = Path("public/privacy/index.html")
SUPPORT_PAGE_PATH = Path("public/support/index.html")
PROJECT_PATH = Path("ios/project.yml")
PRIVACY_MANIFEST_PATH = Path("ios/Oraculo/PrivacyInfo.xcprivacy")
APP_ICON_PATH = Path("ios/Oraculo/Assets.xcassets/AppIcon.appiconset/AppIcon.png")

METADATA_LIMITS = {
    "name": 30,
    "subtitle": 30,
    "promotionalText": 170,
    "description": 4000,
    "keywords": 100,
}
REQUIRED_METADATA_FIELDS = (
    "version",
    "sku",
    "name",
    "subtitle",
    "promotionalText",
    "description",
    "keywords",
    "primaryCategory",
    "secondaryCategory",
    "privacyPolicyUrl",
    "supportUrl",
    "marketingUrl",
    "contactEmail",
)
PROHIBITED_CUSTOMER_COPY = ("starbucks", "星巴克", "啡快")
PLACEHOLDER_COPY = ("todo", "tbd", "example.com", "待填写", "待确认")


def validate_repository(root: Path) -> list[str]:
    """Return release-asset validation errors for ``root``."""
    errors: list[str] = []
    metadata = _load_metadata(root, errors)
    _check_metadata(metadata, errors)
    _check_release_configuration(root, metadata, errors)
    _check_public_pages(root, metadata, errors)
    _check_review_materials(root, errors)
    _check_privacy_manifest(root, errors)
    _check_app_icon(root, errors)
    return errors


def _load_metadata(root: Path, errors: list[str]) -> dict[str, Any]:
    path = root / METADATA_PATH
    if not path.exists():
        errors.append(f"missing {METADATA_PATH}")
        return {}
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        errors.append(f"invalid {METADATA_PATH}: {error}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"{METADATA_PATH} must contain a JSON object")
        return {}
    return value


def _check_metadata(metadata: dict[str, Any], errors: list[str]) -> None:
    if not metadata:
        return

    for field in REQUIRED_METADATA_FIELDS:
        value = metadata.get(field)
        if not isinstance(value, str) or not value.strip():
            errors.append(f"metadata field {field} must be a non-empty string")

    for field, limit in METADATA_LIMITS.items():
        value = metadata.get(field)
        if isinstance(value, str) and len(value) > limit:
            errors.append(f"metadata field {field} exceeds Apple limit {limit}: {len(value)}")

    customer_copy = json.dumps(metadata, ensure_ascii=False).casefold()
    for brand in PROHIBITED_CUSTOMER_COPY:
        if brand.casefold() in customer_copy:
            errors.append(f"metadata contains prohibited third-party brand reference: {brand}")

    for field in ("privacyPolicyUrl", "supportUrl", "marketingUrl"):
        value = metadata.get(field)
        if isinstance(value, str) and not value.startswith("https://"):
            errors.append(f"metadata field {field} must use HTTPS")


def _check_release_configuration(
    root: Path,
    metadata: dict[str, Any],
    errors: list[str],
) -> None:
    path = root / PROJECT_PATH
    if not path.exists():
        errors.append(f"missing {PROJECT_PATH}")
        return

    text = path.read_text(encoding="utf-8")
    expected_version = metadata.get("version")
    versions = re.findall(r'MARKETING_VERSION:\s*["\']?([^"\'\s]+)', text)
    if not expected_version or not versions or any(version != expected_version for version in versions):
        errors.append(
            f"all MARKETING_VERSION values must match metadata version {expected_version or '<missing>'}"
        )

    build_numbers = re.findall(r'CURRENT_PROJECT_VERSION:\s*["\']?([^"\'\s]+)', text)
    if not build_numbers or any(not value.isdigit() or int(value) < 1 for value in build_numbers):
        errors.append("all CURRENT_PROJECT_VERSION values must be positive integers")
    elif len(set(build_numbers)) != 1:
        errors.append("all CURRENT_PROJECT_VERSION values must match")

    team_match = re.search(r'DEVELOPMENT_TEAM:\s*["\']?([^"\'\s]*)', text)
    team = team_match.group(1) if team_match else ""
    if not re.fullmatch(r"[A-Z0-9]{10}", team):
        errors.append("DEVELOPMENT_TEAM must contain the 10-character paid-team identifier")

    if not re.search(
        r"INFOPLIST_KEY_ITSAppUsesNonExemptEncryption:\s*NO\b",
        text,
        flags=re.IGNORECASE,
    ):
        errors.append("main app must declare that it does not use non-exempt encryption")


def _check_public_pages(
    root: Path,
    metadata: dict[str, Any],
    errors: list[str],
) -> None:
    contact_email = metadata.get("contactEmail")
    for relative_path, label in (
        (PRIVACY_PAGE_PATH, "privacy page"),
        (SUPPORT_PAGE_PATH, "support page"),
    ):
        path = root / relative_path
        if not path.exists():
            errors.append(f"missing {label}: {relative_path}")
            continue
        text = path.read_text(encoding="utf-8")
        folded = text.casefold()
        if isinstance(contact_email, str) and contact_email not in text:
            errors.append(f"{label} must include contact email {contact_email}")
        for token in PLACEHOLDER_COPY:
            if token.casefold() in folded:
                errors.append(f"{label} contains unresolved placeholder: {token}")
        for brand in PROHIBITED_CUSTOMER_COPY:
            if brand.casefold() in folded:
                errors.append(f"{label} contains prohibited third-party brand reference: {brand}")


def _check_review_materials(root: Path, errors: list[str]) -> None:
    review_path = root / REVIEW_NOTES_PATH
    if not review_path.exists():
        errors.append(f"missing {REVIEW_NOTES_PATH}")
    else:
        review_notes = review_path.read_text(encoding="utf-8")
        for required in ("不需要账号", "位置", "Open-Meteo", "Widget"):
            if required not in review_notes:
                errors.append(f"review notes must explain: {required}")
        _check_prohibited_copy("review notes", review_notes, errors)

    screenshot_path = root / SCREENSHOT_PLAN_PATH
    if not screenshot_path.exists():
        errors.append(f"missing {SCREENSHOT_PLAN_PATH}")
    else:
        screenshot_plan = screenshot_path.read_text(encoding="utf-8")
        for required in ("iPhone", "iPad", "1.0.0"):
            if required not in screenshot_plan:
                errors.append(f"screenshot plan must include: {required}")
        _check_prohibited_copy("screenshot plan", screenshot_plan, errors)


def _check_prohibited_copy(label: str, text: str, errors: list[str]) -> None:
    folded = text.casefold()
    for brand in PROHIBITED_CUSTOMER_COPY:
        if brand.casefold() in folded:
            errors.append(f"{label} contains prohibited third-party brand reference: {brand}")


def _check_privacy_manifest(root: Path, errors: list[str]) -> None:
    path = root / PRIVACY_MANIFEST_PATH
    if not path.exists():
        errors.append(f"missing {PRIVACY_MANIFEST_PATH}")
        return
    try:
        manifest = plistlib.loads(path.read_bytes())
    except (OSError, plistlib.InvalidFileException) as error:
        errors.append(f"invalid {PRIVACY_MANIFEST_PATH}: {error}")
        return

    matching = [
        entry
        for entry in manifest.get("NSPrivacyCollectedDataTypes", [])
        if entry.get("NSPrivacyCollectedDataType") == "NSPrivacyCollectedDataTypeCoarseLocation"
    ]
    if not matching:
        errors.append("main app privacy manifest must disclose coarse location")
        return

    entry = matching[0]
    purposes = entry.get("NSPrivacyCollectedDataTypePurposes", [])
    if entry.get("NSPrivacyCollectedDataTypeLinked") is not False:
        errors.append("coarse location must be declared as not linked to the user")
    if entry.get("NSPrivacyCollectedDataTypeTracking") is not False:
        errors.append("coarse location must be declared as not used for tracking")
    if "NSPrivacyCollectedDataTypePurposeAppFunctionality" not in purposes:
        errors.append("coarse location purpose must include App Functionality")


def _check_app_icon(root: Path, errors: list[str]) -> None:
    path = root / APP_ICON_PATH
    if not path.exists():
        errors.append(f"missing {APP_ICON_PATH}")
        return
    data = path.read_bytes()[:26]
    if len(data) < 26 or data[:8] != b"\x89PNG\r\n\x1a\n" or data[12:16] != b"IHDR":
        errors.append("AppIcon.png must be a valid PNG")
        return
    width, height = struct.unpack(">II", data[16:24])
    if (width, height) != (1024, 1024):
        errors.append(f"AppIcon.png must be 1024x1024, got {width}x{height}")
    if data[25] in (4, 6):
        errors.append("AppIcon.png must not contain an alpha channel")


def main() -> int:
    errors = validate_repository(ROOT)
    if errors:
        print("App Store asset validation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("App Store assets validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
