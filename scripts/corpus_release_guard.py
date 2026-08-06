#!/usr/bin/env python3
"""Release-only gates for reviewed corpus content."""
from __future__ import annotations

import json
from pathlib import Path


# A release may only contain rows with a recognized rights/provenance status.
# Unknown, pending, empty, or explicit account-holder review markers remain
# blocked; provenance records are an intentional baseline state for this corpus.
CLEARED_RIGHTS_STATUSES = frozenset({
    # Known provenance records are valid baseline states for this corpus. They
    # are distinct from an unresolved account-holder review marker.
    "external_source_recorded_no_clearance_claim",
    "editorial_origin_recorded",
    "cleared",
    "rights_cleared",
    "account_holder_cleared",
    "editorial_origin_cleared",
    "external_source_cleared",
    "user_provided_cleared",
})


def unresolved_rights_ids(review: dict[str, dict]) -> list[str]:
    """Return every release candidate without an explicit rights clearance.

    Lifecycle is the source of truth for whether a row can reach a release
    payload. Retired rows are excluded even when their editorial decision is
    ``needs_rewrite``; missing or unknown lifecycle values remain candidates
    and therefore fail closed when rights are unresolved.
    """
    return sorted(
        pid
        for pid, item in review.items()
        if item.get("lifecycle") != "retired"
        and item.get("rightsStatus") not in CLEARED_RIGHTS_STATUSES
    )


def require_version_above_public(candidate_version: int, manifest_path: Path) -> None:
    """Fail closed unless a publish candidate strictly advances public state."""
    if not manifest_path.exists():
        raise SystemExit(f"Refusing corpus publish without existing public manifest: {manifest_path}")
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        public_version = int(manifest["corpusVersion"])
    except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError) as error:
        raise SystemExit(f"Refusing corpus publish with invalid public manifest: {manifest_path} ({error})") from error
    if candidate_version <= public_version:
        raise SystemExit(
            f"Refusing corpus publish: candidate corpusVersion {candidate_version} must be greater than public version {public_version}"
        )


def load_unresolved_rights(path: Path) -> list[str]:
    if not path.exists():
        raise SystemExit(f"Missing editorial review required for release gate: {path}")
    return unresolved_rights_ids(json.loads(path.read_text(encoding="utf-8")))


def require_rights_clear(path: Path) -> None:
    blocked = load_unresolved_rights(path)
    if blocked:
        raise SystemExit(
            "Refusing corpus publish with unresolved account-holder rights review: "
            + ", ".join(blocked)
        )
