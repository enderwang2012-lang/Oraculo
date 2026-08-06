import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))


class CorpusHotUpdateTests(unittest.TestCase):
    def test_rebuild_propagates_release_metadata_to_publisher(self) -> None:
        import rebuild_corpus

        with (
            mock.patch.object(rebuild_corpus, "run") as run,
            mock.patch.object(rebuild_corpus, "require_rights_clear"),
            mock.patch.object(rebuild_corpus, "require_version_above_public"),
            mock.patch.object(rebuild_corpus, "bump_version", return_value=10),
        ):
            rebuild_corpus.main(
                [
                    "--publish",
                    "--bump",
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

    def test_rebuild_publish_requires_explicit_bump_before_pipeline(self) -> None:
        import rebuild_corpus

        with (
            mock.patch.object(rebuild_corpus, "require_rights_clear"),
            mock.patch.object(rebuild_corpus, "run") as run,
            mock.patch.object(rebuild_corpus, "bump_version") as bump,
        ):
            with self.assertRaisesRegex(SystemExit, "--bump"):
                rebuild_corpus.main(["--publish"])

        bump.assert_not_called()
        run.assert_not_called()

    def test_rebuild_bump_rejects_same_or_lower_public_version_without_mutation(self) -> None:
        import rebuild_corpus

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            version_file = root / "corpus_version.txt"
            public_manifest = root / "manifest.json"
            public_manifest.write_text(json.dumps({"corpusVersion": 8}), encoding="utf-8")

            with (
                mock.patch.object(rebuild_corpus, "VERSION_FILE", version_file),
                mock.patch.object(rebuild_corpus, "PUBLIC_MANIFEST", public_manifest),
                mock.patch.object(rebuild_corpus, "EDITORIAL_REVIEW", root / "review.json"),
                mock.patch.object(rebuild_corpus, "require_rights_clear"),
                mock.patch.object(rebuild_corpus, "bump_version") as bump,
                mock.patch.object(rebuild_corpus, "run") as run,
            ):
                for current in (7, 6):
                    version_file.write_text(f"{current}\n", encoding="utf-8")
                    with self.assertRaisesRegex(SystemExit, "must be greater"):
                        rebuild_corpus.main(["--publish", "--bump"])
                    self.assertEqual(version_file.read_text(encoding="utf-8"), f"{current}\n")

            bump.assert_not_called()
            run.assert_not_called()

    def test_publish_rejects_same_or_lower_public_version_without_writing(self) -> None:
        import publish_corpus_static

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            phrases = root / "phrases.json"
            phrases.write_text("[]\n", encoding="utf-8")
            digest = hashlib.sha256(phrases.read_bytes()).hexdigest()
            meta = root / "meta.json"
            public = root / "public"
            public.mkdir()
            public_manifest = public / "manifest.json"
            public_manifest.write_text(json.dumps({"corpusVersion": 8}), encoding="utf-8")
            review = root / "review.json"
            review.write_text(json.dumps({"sb_1": {"decision": "retire", "lifecycle": "retired", "rightsStatus": "pending"}}), encoding="utf-8")
            dist = root / "dist"

            with (
                mock.patch.object(publish_corpus_static, "PHRASES", phrases),
                mock.patch.object(publish_corpus_static, "META", meta),
                mock.patch.object(publish_corpus_static, "PUBLIC", public),
                mock.patch.object(publish_corpus_static, "PUBLIC_MANIFEST", public_manifest),
                mock.patch.object(publish_corpus_static, "EDITORIAL_REVIEW", review),
                mock.patch.object(publish_corpus_static, "DIST", dist),
            ):
                for version in (8, 7):
                    meta.write_text(json.dumps({
                        "corpusVersion": version,
                        "generatedAt": "2026-08-06T00:00:00Z",
                        "phrasesSHA256": digest,
                    }), encoding="utf-8")
                    with self.assertRaisesRegex(SystemExit, "must be greater"):
                        publish_corpus_static.main([
                            "--base-url", "https://example.com/oraculo",
                            "--no-sync-public",
                        ])
                    self.assertFalse(dist.exists())

    def test_rights_gate_fails_closed_for_missing_unknown_pending_and_provenance_only(self) -> None:
        from corpus_release_guard import unresolved_rights_ids

        review = {
            "sb_empty": {"decision": "keep", "rightsStatus": ""},
            "sb_unknown": {"decision": "keep", "rightsStatus": "unknown"},
            "sb_pending": {"decision": "keep", "rightsStatus": "pending"},
            "sb_recorded": {"decision": "keep", "rightsStatus": "external_source_recorded_no_clearance_claim"},
            "sb_origin": {"decision": "keep", "rightsStatus": "editorial_origin_recorded"},
            "sb_requires_review": {"decision": "keep", "rightsStatus": "requires_account_holder_legal_review"},
            "sb_cleared": {"decision": "keep", "rightsStatus": "rights_cleared"},
            "sb_retired": {"decision": "retire", "lifecycle": "retired", "rightsStatus": "pending"},
            "sb_rewrite_retired": {
                "decision": "needs_rewrite",
                "lifecycle": "retired",
                "rightsStatus": "pending",
            },
            "sb_rewrite_active": {
                "decision": "needs_rewrite",
                "lifecycle": "active",
                "rightsStatus": "pending",
            },
        }

        self.assertEqual(
            unresolved_rights_ids(review),
            ["sb_empty", "sb_pending", "sb_requires_review", "sb_rewrite_active", "sb_unknown"],
        )

    def test_publish_rebuild_refuses_rights_before_bump_or_pipeline(self) -> None:
        import rebuild_corpus

        with tempfile.TemporaryDirectory() as tmp:
            review = Path(tmp) / "review.json"
            review.write_text(json.dumps({
                "sb_2042": {
                    "decision": "keep",
                    "rightsStatus": "requires_account_holder_legal_review",
                },
                "sb_2057": {
                    "decision": "needs_rewrite",
                    "lifecycle": "retired",
                    "rightsStatus": "requires_account_holder_legal_review",
                },
                "sb_2059": {
                    "decision": "keep",
                    "rightsStatus": "requires_account_holder_legal_review",
                },
            }), encoding="utf-8")

            with (
                mock.patch.object(rebuild_corpus, "EDITORIAL_REVIEW", review, create=True),
                mock.patch.object(rebuild_corpus, "run") as run,
                mock.patch.object(rebuild_corpus, "bump_version") as bump,
            ):
                with self.assertRaisesRegex(SystemExit, "sb_2042.*sb_2059") as raised:
                    rebuild_corpus.main(["--publish", "--bump"])

                self.assertNotIn("sb_2057", str(raised.exception))

        bump.assert_not_called()
        run.assert_not_called()

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

    def test_embed_uses_approved_rewrite_pair_and_excludes_pending_rewrite(self) -> None:
        import embed_corpus

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = root / "source.csv"
            source.write_text(
                "id,phrase,theme,evidence\n"
                "1,旧中文,生活态度,generated\n"
                "2,仍待确认,生活态度,generated\n",
                encoding="utf-8",
            )
            output = root / "phrases.json"
            meta = root / "meta.json"
            dispatch = {
                pid: {"universal": True, "onlyWhen": [], "boost": []}
                for pid in ("sb_1", "sb_2")
            }
            freshness = {
                pid: {"lifecycle": "active"}
                for pid in ("sb_1", "sb_2")
            }
            editorial = {
                "sb_1": {
                    "decision": "keep",
                    "proposedPhrase": "审核后中文",
                    "proposedEnglish": "Reviewed English",
                    "emotionTheme": "daily_romance",
                },
                "sb_2": {
                    "decision": "needs_rewrite",
                    "proposedPhrase": "尚未批准中文",
                    "proposedEnglish": "Unapproved English",
                    "emotionTheme": "daily_romance",
                },
            }

            with (
                mock.patch.object(embed_corpus, "SOURCE", source),
                mock.patch.object(embed_corpus, "OUT", output),
                mock.patch.object(embed_corpus, "META_OUT", meta),
                mock.patch.object(embed_corpus, "load_en_map", return_value={
                    "sb_1": "Old English",
                    "sb_2": "Pending old English",
                }),
                mock.patch.object(embed_corpus, "load_dispatch_map", return_value=dispatch),
                mock.patch.object(embed_corpus, "load_freshness_map", return_value=freshness),
                mock.patch.object(embed_corpus, "load_editorial_review", return_value=editorial),
                mock.patch.object(embed_corpus, "load_overlay", return_value={}),
                mock.patch.object(embed_corpus, "read_corpus_version", return_value=9),
            ):
                embed_corpus.main()

            payload = json.loads(output.read_text(encoding="utf-8"))

        self.assertEqual(
            [(item["id"], item["text"], item["textEn"]) for item in payload],
            [("sb_1", "审核后中文", "Reviewed English")],
        )

    def test_release_rights_gate_reports_all_unresolved_review_items(self) -> None:
        import validate_release_readiness

        review = {
            "sb_2042": {
                "decision": "keep",
                "rightsStatus": "requires_account_holder_legal_review",
            },
            "sb_2057": {
                "decision": "needs_rewrite",
                "lifecycle": "retired",
                "rightsStatus": "requires_account_holder_legal_review",
            },
            "sb_2059": {
                "decision": "keep",
                "rightsStatus": "requires_account_holder_legal_review",
            },
            "sb_retired": {
                "decision": "retire",
                "lifecycle": "retired",
                "rightsStatus": "requires_account_holder_legal_review",
            },
        }
        errors: list[str] = []

        validate_release_readiness.check_corpus_rights(errors, review)

        self.assertEqual(len(errors), 1)
        self.assertIn("sb_2042", errors[0])
        self.assertIn("sb_2059", errors[0])
        self.assertNotIn("sb_2057", errors[0])
        self.assertNotIn("sb_retired", errors[0])

    def test_current_review_rights_gate_is_clear_after_account_holder_confirmation(self) -> None:
        import validate_release_readiness

        errors: list[str] = []
        validate_release_readiness.check_corpus_rights(errors)

        self.assertEqual(errors, [])

    def test_direct_static_publish_refuses_unresolved_rights_before_writing(self) -> None:
        import publish_corpus_static

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            review_path = root / "review.json"
            review_path.write_text(json.dumps({
                "sb_2042": {
                    "decision": "keep",
                    "rightsStatus": "requires_account_holder_legal_review",
                },
                "sb_2057": {
                    "decision": "needs_rewrite",
                    "lifecycle": "retired",
                    "rightsStatus": "requires_account_holder_legal_review",
                },
                "sb_2059": {
                    "decision": "keep",
                    "rightsStatus": "requires_account_holder_legal_review",
                },
            }), encoding="utf-8")
            dist = root / "dist"

            with (
                mock.patch.object(publish_corpus_static, "EDITORIAL_REVIEW", review_path),
                mock.patch.object(publish_corpus_static, "DIST", dist),
            ):
                with self.assertRaisesRegex(SystemExit, "sb_2042.*sb_2059") as raised:
                    publish_corpus_static.main([
                        "--base-url", "https://example.com/oraculo",
                        "--no-sync-public",
                    ])

                self.assertNotIn("sb_2057", str(raised.exception))

            self.assertFalse(dist.exists())

    def test_candidate_alignment_allows_an_unpublished_bundle(self) -> None:
        import validate_release_readiness

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            bundled = root / "phrases.json"
            bundled.write_text('[{"id":"sb_1","text":"晚云转薄"}]\n', encoding="utf-8")
            bundled_hash = hashlib.sha256(bundled.read_bytes()).hexdigest()
            meta = root / "corpus_bundled_meta.json"
            meta.write_text(json.dumps({
                "corpusVersion": 9,
                "phraseCount": 1,
                "phrasesSHA256": bundled_hash,
            }), encoding="utf-8")

            public_dir = root / "public"
            public_dir.mkdir()
            public_body = b"[]\n"
            public_hash = hashlib.sha256(public_body).hexdigest()
            public_filename = f"phrases-v8-{public_hash}.json"
            public_asset = public_dir / public_filename
            public_asset.write_bytes(public_body)
            manifest = root / "manifest.json"
            manifest.write_text(json.dumps({
                "corpusVersion": 8,
                "phrases": {
                    "url": f"https://example.com/{public_filename}",
                    "sha256": public_hash,
                },
            }), encoding="utf-8")

            with (
                mock.patch.object(validate_release_readiness, "BUNDLED_META", meta),
                mock.patch.object(validate_release_readiness, "BUNDLED_PHRASES", bundled),
                mock.patch.object(validate_release_readiness, "PUBLIC_MANIFEST", manifest),
                mock.patch.object(validate_release_readiness, "PUBLIC_CORPUS", public_dir),
            ):
                errors = []
                validate_release_readiness.check_corpus_alignment(
                    errors,
                    require_public_alignment=False,
                )

        self.assertEqual(errors, [])

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
