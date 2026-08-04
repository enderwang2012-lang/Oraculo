import hashlib
import json
import sys
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))


class CorpusHotUpdateTests(unittest.TestCase):
    def test_rebuild_propagates_release_metadata_to_publisher(self) -> None:
        import rebuild_corpus

        with mock.patch.object(rebuild_corpus, "run") as run:
            rebuild_corpus.main(
                [
                    "--publish",
                    "--skip-preflight",
                    "--base-url",
                    "https://example.com/oraculo",
                    "--min-app-version",
                    "1.1.0",
                    "--release-notes",
                    "reviewed corpus",
                ]
            )

        self.assertEqual(
            run.call_args_list[-1].args[0],
            [
                sys.executable,
                "scripts/publish_corpus_static.py",
                "--base-url",
                "https://example.com/oraculo",
                "--min-app-version",
                "1.1.0",
                "--release-notes",
                "reviewed corpus",
            ],
        )

    def test_manifest_references_immutable_versioned_asset(self) -> None:
        from publish_corpus_static import asset_filename, build_manifest

        digest = "a" * 64
        filename = asset_filename(8, digest)
        manifest = build_manifest(
            {
                "corpusVersion": 8,
                "generatedAt": "2026-08-04T00:00:00Z",
                "phraseCount": 1,
                "phrasesSHA256": digest,
            },
            base_url="https://example.com/oraculo",
            min_app_version="1.0.0",
            release_notes="reviewed corpus",
        )

        self.assertEqual(filename, f"phrases-v8-{digest}.json")
        self.assertEqual(
            manifest["phrases"]["url"],
            f"https://example.com/oraculo/{filename}",
        )
        self.assertEqual(manifest["phrases"]["sha256"], digest)

    def test_exact_release_validation_checks_version_sha_count_and_ids(self) -> None:
        from verify_corpus_cdn import validate_release

        body = json.dumps(
            [{"id": "sb_1", "text": "晚云转薄"}],
            ensure_ascii=False,
        ).encode("utf-8")
        digest = hashlib.sha256(body).hexdigest()
        manifest = {
            "corpusVersion": 8,
            "phrases": {"url": "https://example.com/phrases.json", "sha256": digest},
        }

        self.assertEqual(
            validate_release(
                manifest,
                body,
                expected_version=8,
                expected_sha=digest,
                expected_count=1,
                expected_phrases={"sb_1": "晚云转薄"},
            ),
            [],
        )

        errors = validate_release(
            manifest,
            body,
            expected_version=9,
            expected_sha=digest,
            expected_count=2,
            expected_phrases={"sb_1": "错误文本", "sb_2": "缺失"},
        )
        self.assertTrue(any("version" in error.lower() for error in errors))
        self.assertTrue(any("count" in error.lower() for error in errors))
        self.assertTrue(any("sb_1" in error for error in errors))
        self.assertTrue(any("sb_2" in error for error in errors))

    def test_retired_entries_are_excluded_from_payload(self) -> None:
        from embed_corpus import should_embed

        self.assertFalse(should_embed({"lifecycle": "retired"}))
        self.assertTrue(should_embed({"lifecycle": "cooling"}))
        self.assertTrue(should_embed({"lifecycle": "active"}))

    def test_simulation_context_weight_honors_only_when(self) -> None:
        from simulate_phrase_freshness import context_weight

        phrase = {
            "dispatch": {
                "universal": False,
                "onlyWhen": ["season:summer"],
                "boost": [{"tag": "temp:hot", "weight": 2.0}],
            }
        }

        self.assertEqual(context_weight(phrase, {"season:winter"}), 0)
        self.assertEqual(context_weight(phrase, {"season:summer"}), 0.6)
        self.assertEqual(context_weight(phrase, {"season:summer", "temp:hot"}), 2.6)

    def test_simulation_seed_uses_full_stable_hash_range(self) -> None:
        from simulate_phrase_freshness import stable_unit

        values = [stable_unit(f"user-{index}|2026-08-04|draw") for index in range(100)]

        self.assertLess(min(values), 0.1)
        self.assertGreater(max(values), 0.9)

    def test_simulation_reports_complete_lifecycle_distribution(self) -> None:
        from simulate_phrase_freshness import simulate

        metrics = simulate(days=1, users=1)
        lifecycle_rates = [
            metrics["lifecycle_active_exposure_rate"],
            metrics["lifecycle_anchor_exposure_rate"],
            metrics["lifecycle_cooling_exposure_rate"],
            metrics["lifecycle_new_exposure_rate"],
            metrics["retired_exposure_rate"],
        ]

        self.assertAlmostEqual(sum(lifecycle_rates), 1.0)


if __name__ == "__main__":
    unittest.main()
