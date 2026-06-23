import json
import sys
import tempfile
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))


class PhraseFreshnessTagTests(unittest.TestCase):
    def test_generate_tags_covers_each_phrase_with_valid_fields(self) -> None:
        from tag_phrase_freshness import generate_tags, load_rows

        rows = load_rows()
        tags = generate_tags(rows)
        ids = {f"sb_{row['id'].strip()}" for row in rows if row.get("phrase", "").strip()}

        self.assertEqual(set(tags), ids)
        for pid, entry in tags.items():
            with self.subTest(pid=pid):
                self.assertRegex(entry["semanticCluster"], r"^[a-z0-9_]+$")
                self.assertRegex(entry["cadenceGroup"], r"^[a-z0-9_]+$")
                self.assertIn(entry["lifecycle"], {"new", "active", "anchor", "cooling", "retired"})

    def test_cadence_groups_are_not_overly_broad(self) -> None:
        from tag_phrase_freshness import generate_tags, load_rows

        tags = generate_tags(load_rows())
        counts = Counter(entry["cadenceGroup"] for entry in tags.values())
        most_common, count = counts.most_common(1)[0]

        self.assertLessEqual(
            count,
            24,
            f"cadence group '{most_common}' is too broad to prevent rhythm fatigue",
        )

    def test_validate_rejects_missing_ids(self) -> None:
        from validate_phrase_freshness import validate_tags

        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "freshness.json"
            path.write_text(json.dumps({}), encoding="utf-8")
            errors = validate_tags(path)

        self.assertTrue(any("Missing freshness tags" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
