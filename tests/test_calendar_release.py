import hashlib
import json
import sys
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from publish_corpus_static import build_calendar_asset, build_manifest  # noqa: E402
from calendar_release import validate_calendar, valid_date_token
from dispatch_overlay import merge_dispatch, strip_for_embed, load_vocabulary
from validate_dispatch import validate_dispatch_obj
from verify_corpus_cdn import validate_release


class CalendarReleaseTests(unittest.TestCase):
    def test_calendar_asset_combines_festivals_and_solar_terms(self) -> None:
        festivals = {"version": 1, "festivals": [{"id": "new_year"}]}
        solar_terms = {"version": 1, "years": {"2027": [{"id": "dongzhi"}]}}

        body = build_calendar_asset(festivals, solar_terms, version=13)
        decoded = json.loads(body)

        self.assertEqual(decoded["version"], 13)
        self.assertEqual(decoded["timezone"], "Asia/Shanghai")
        self.assertEqual(decoded["festivals"], festivals["festivals"])
        self.assertEqual(decoded["solar_terms"], solar_terms["years"])

    def test_manifest_contains_calendar_asset_with_same_release_version(self) -> None:
        phrases = b"[]\n"
        calendar = b'{"version":13}\n'
        manifest = build_manifest(
            {
                "corpusVersion": 13,
                "generatedAt": "2026-10-10T00:00:00Z",
                "phraseCount": 0,
                "phrasesSHA256": hashlib.sha256(phrases).hexdigest(),
            },
            calendar_bytes=calendar,
            base_url="https://example.test/oraculo",
            min_app_version="1.1.0",
            release_notes="calendar release",
        )

        self.assertEqual(manifest["releaseVersion"], 13)
        self.assertEqual(manifest["corpusVersion"], 13)
        self.assertEqual(manifest["minAppVersion"], "1.1.0")
        self.assertEqual(manifest["calendar"]["sha256"], hashlib.sha256(calendar).hexdigest())
        self.assertIn("calendar-v13-", manifest["calendar"]["url"])

    def test_calendar_asset_is_stable_for_identical_inputs(self) -> None:
        festivals = {"version": 1, "festivals": []}
        solar_terms = {"version": 1, "years": {}}

        first = build_calendar_asset(festivals, solar_terms, version=13)
        second = build_calendar_asset(festivals, solar_terms, version=13)

        self.assertEqual(first, second)

    def test_calendar_requires_valid_dates_and_timezone(self):
        body = build_calendar_asset({"festivals": []}, {"years": {}}, version=13)
        config = json.loads(body)
        self.assertEqual(validate_calendar(config, 13), [])
        config["timezone"] = "UTC"
        self.assertTrue(validate_calendar(config, 13))
        self.assertTrue(valid_date_token("02-29"))
        for invalid in ("02-30", "2026-02-29", "13-01", "11-31", "1-1"):
            self.assertFalse(valid_date_token(invalid))

    def test_calendar_rejects_unresolvable_phrase_binding(self):
        config = {"version": 13, "timezone": "Asia/Shanghai", "festivals": [], "solar_terms": {}}
        phrases = [{"id": "test", "dispatch": {"dateBinding": {"rules": ["festival:missing"]}}}]
        self.assertTrue(validate_calendar(config, 13, phrases))

    def test_date_binding_survives_overlay_and_embed(self):
        binding = {"mode": "exclusive", "rules": ["month_day:12-31"], "priority": 100}
        base = {"universal": False, "onlyWhen": ["month_day:12-31"], "boost": [], "dateBinding": binding}
        result = strip_for_embed(merge_dispatch(base, {"colorMoods": ["warm"]}))
        self.assertEqual(result["dateBinding"], binding)
        errors = []
        validate_dispatch_obj("test", result, load_vocabulary(), errors, [])
        self.assertEqual(errors, [])
        result["dateBinding"]["rules"] = ["month_day:02-30"]
        validate_dispatch_obj("test", result, load_vocabulary(), errors, [])
        self.assertTrue(errors)

    def test_cdn_verifier_requires_both_assets(self):
        body = b'[{"id":"test","text":"test"}]'
        calendar = build_calendar_asset({"festivals": []}, {"years": {}}, version=13)
        digest, calendar_digest = hashlib.sha256(body).hexdigest(), hashlib.sha256(calendar).hexdigest()
        manifest = {"corpusVersion": 13, "releaseVersion": 13,
                    "phrases": {"sha256": digest}, "calendar": {"sha256": calendar_digest}}
        args = dict(expected_version=13, expected_sha=digest, expected_count=1,
                    expected_phrases={"test": "test"}, expected_calendar_sha=calendar_digest)
        self.assertEqual(validate_release(manifest, body, calendar_body=calendar, **args), [])
        self.assertTrue(validate_release(manifest, body, **args))
        self.assertTrue(validate_release(manifest, body, calendar_body=b"{}", **args))

    def test_calendar_manifest_rejects_old_clients_and_mixed_versions(self):
        meta = {"corpusVersion": 13, "generatedAt": "", "phrasesSHA256": "a" * 64}
        for version, minimum in ((12, "1.1.0"), (13, "1.0.0")):
            with self.assertRaises(ValueError):
                build_manifest(meta, calendar_bytes=json.dumps({"version": version}).encode(),
                               base_url="https://example.test", min_app_version=minimum, release_notes="")


if __name__ == "__main__":
    unittest.main()
