import csv
import json
import unittest
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class CorpusReviewResetTests(unittest.TestCase):
    def load_source_ids(self):
        with (ROOT / "starbucks_now_passphrases.csv").open(encoding="utf-8-sig") as handle:
            return [f"sb_{row['id']}" for row in csv.DictReader(handle) if row.get("phrase", "").strip()]

    def load_json(self, path):
        return json.loads((ROOT / path).read_text(encoding="utf-8"))

    def test_every_source_phrase_has_one_explicit_editorial_decision(self):
        source_ids = set(self.load_source_ids())
        review = self.load_json("config/phrase_editorial_review.json")

        self.assertEqual(len(source_ids), 248)
        self.assertEqual(set(review), source_ids)
        self.assertTrue(all(item["decision"] in {"keep", "needs_rewrite", "retire"} for item in review.values()))
        self.assertTrue(all(item["lifecycle"] != "cooling" for item in review.values()))
        self.assertTrue(all(item["lifecycle"] == "active" for item in review.values() if item["decision"] == "keep"))
        self.assertTrue(all(item["lifecycle"] == "retired" for item in review.values() if item["decision"] != "keep"))
        self.assertTrue(all(item["reviewBasis"] == "fresh_initial_content_review" for item in review.values()))
        self.assertTrue(all(item["proposedPhrase"] for item in review.values() if item["proposedPhrase"]))
        self.assertGreaterEqual(sum(item["decision"] == "keep" for item in review.values()), 90)

        categories = Counter(item["sourceCategory"] for item in review.values())
        self.assertEqual(categories, {"external_observed": 218, "editorial_original": 27, "user_provided": 3})
        self.assertTrue(all(item["rightsStatus"] for item in review.values()))
        self.assertEqual(Counter(item["decision"] for item in review.values()), {
            "keep": 161,
            "retire": 87,
        })
        self.assertEqual(sum(bool(item.get("reviewerNote")) for item in review.values()), 40)

        rewrites = {
            pid: (item["proposedPhrase"], item["proposedEnglish"])
            for pid, item in review.items()
            if item["proposedPhrase"]
        }
        self.assertEqual(rewrites, {
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
        })
        self.assertTrue(all(review[pid]["decision"] == "keep" for pid in rewrites))
        self.assertTrue(all(review[pid]["lifecycle"] == "active" for pid in rewrites))
        self.assertTrue(all(review[pid]["englishStatus"] == "approved" for pid in rewrites))
        self.assertEqual(
            review["sb_2057"]["rightsStatus"],
            "rights_cleared",
        )

    def test_local_candidate_contains_only_content_approved_rows(self):
        review = self.load_json("config/phrase_editorial_review.json")
        payload = self.load_json("ios/Shared/Resources/phrases.json")
        rewrites = {
            pid: (item["proposedPhrase"], item["proposedEnglish"])
            for pid, item in review.items()
            if item["proposedPhrase"]
        }

        approved_ids = {pid for pid, item in review.items() if item["decision"] == "keep"}
        self.assertEqual({item["id"] for item in payload}, approved_ids)
        self.assertEqual(len(payload), 161)
        self.assertEqual(
            {
                item["id"] for item in payload if item["id"] in rewrites
            },
            set(rewrites),
        )
        for item in payload:
            if item["id"] in rewrites:
                self.assertEqual(item["text"], rewrites[item["id"]][0])
                self.assertEqual(item["textEn"], rewrites[item["id"]][1])
        self.assertTrue(all(item["freshness"]["lifecycle"] == "active" for item in payload))

    def test_human_review_csv_matches_machine_review_source(self):
        review = self.load_json("config/phrase_editorial_review.json")
        with (ROOT / "review/corpus_review_2026_08_full.csv").open(encoding="utf-8-sig") as handle:
            rows = list(csv.DictReader(handle))

        self.assertEqual(len(rows), 248)
        self.assertEqual({row["id"] for row in rows}, set(review))
        for row in rows:
            item = review[row["id"]]
            for field in (
                "phrase", "english", "decision", "reviewCode", "lifecycle", "proposedPhrase",
                "proposedEnglish", "sourceCategory", "rightsStatus", "editorialTheme",
                "semanticCluster", "cadenceGroup", "dispatchConstraint", "reviewReason",
            ):
                actual = json.loads(row[field]) if field == "dispatchConstraint" else row[field]
                self.assertEqual(actual, item[field], f"{row['id']} field {field}")

        proposed = [row["proposedPhrase"] for row in rows if row["proposedPhrase"]]
        self.assertEqual(len(proposed), len(set(proposed)))

    def test_freshness_groups_are_reused_as_real_buckets(self):
        tags = self.load_json("config/phrase_freshness_tags.json")
        source_ids = set(self.load_source_ids())
        groups = {pid: item["cadenceGroup"] for pid, item in tags.items() if pid in source_ids}

        self.assertEqual(set(groups), source_ids)
        self.assertLessEqual(len(set(groups.values())), 24)
        self.assertGreaterEqual(max(Counter(groups.values()).values()), 3)

    def test_known_dispatch_boundaries_and_translations_are_fixed(self):
        dispatch = self.load_json("scripts/phrase_dispatch.json")
        translations = self.load_json("scripts/phrases_en.json")

        self.assertIn("season:autumn", dispatch["sb_100"]["onlyWhen"])
        self.assertIn("season:winter", dispatch["sb_100"]["onlyWhen"])
        self.assertTrue(dispatch["sb_188"]["onlyWhen"])
        self.assertEqual(dispatch["sb_2035"]["onlyWhen"], ["month:7"])
        self.assertEqual(dispatch["sb_164"]["onlyWhen"], ["season:spring"])
        self.assertEqual(dispatch["sb_2052"]["onlyWhen"], ["season:summer"])
        self.assertEqual(dispatch["sb_2054"]["onlyWhen"], ["season:summer"])
        self.assertEqual(dispatch["sb_39"]["onlyWhen"], ["season:spring"])
        self.assertEqual(dispatch["sb_41"]["onlyWhen"], ["season:winter"])
        self.assertEqual(dispatch["sb_42"]["onlyWhen"], ["festival:mid_autumn"])
        self.assertEqual(dispatch["sb_49"]["onlyWhen"], ["festival:spring_festival"])
        self.assertEqual(dispatch["sb_81"]["onlyWhen"], ["festival:father_day"])
        self.assertEqual(dispatch["sb_194"]["onlyWhen"], ["festival:christmas"])
        self.assertEqual(dispatch["sb_222"]["onlyWhen"], ["festival:new_year"])
        self.assertEqual(dispatch["sb_257"]["onlyWhen"], ["festival:new_year"])
        self.assertEqual(dispatch["sb_263"]["onlyWhen"], ["festival:christmas"])
        self.assertEqual(dispatch["sb_273"]["onlyWhen"], ["festival:new_year"])
        self.assertEqual(dispatch["sb_2022"]["onlyWhen"], ["festival:dragon_boat"])
        self.assertEqual(dispatch["sb_2047"]["onlyWhen"], ["solar_term:xiazhi"])
        self.assertEqual(translations["sb_13"], "Loving summer")
        self.assertEqual(translations["sb_113"], "With patience, things find their shape")
        self.assertEqual(translations["sb_277"], "Time, clear and unhurried")

    def test_review_metadata_preserves_every_manual_dispatch_constraint(self):
        review = self.load_json("config/phrase_editorial_review.json")
        overrides = self.load_json("config/phrase_dispatch_overrides.json")
        original_manual_ids = {
            "sb_100", "sb_164", "sb_188", "sb_2005", "sb_2035", "sb_2052", "sb_2054",
        }
        reviewed_note_ids = {
            "sb_39", "sb_41", "sb_42", "sb_49", "sb_50", "sb_51", "sb_52",
            "sb_68", "sb_78", "sb_81", "sb_99", "sb_101", "sb_194", "sb_222",
            "sb_257", "sb_263", "sb_273", "sb_2006", "sb_2021", "sb_2022", "sb_2047",
        }

        for pid in original_manual_ids | reviewed_note_ids:
            self.assertEqual(review[pid]["dispatchStatus"], "manual", pid)
            self.assertEqual(review[pid]["dispatchConstraint"], overrides[pid]["onlyWhen"], pid)

    def test_review_dispatch_constraints_match_final_dispatch_for_all_248_rows(self):
        review = self.load_json("config/phrase_editorial_review.json")
        dispatch = self.load_json("scripts/phrase_dispatch.json")

        mismatches = {
            pid: (item.get("dispatchConstraint", []), dispatch.get(pid, {}).get("onlyWhen", []))
            for pid, item in review.items()
            if item.get("dispatchConstraint", []) != dispatch.get(pid, {}).get("onlyWhen", [])
        }
        self.assertEqual(mismatches, {})

    def test_father_day_is_a_real_calendar_constraint(self):
        vocabulary = self.load_json("config/tag_vocabulary.json")
        festivals = self.load_json("config/festivals_cn.json")
        bundled_festivals = self.load_json("ios/Shared/Resources/festivals_cn.json")

        self.assertIn("father_day", vocabulary["dimensions"]["festival"]["values"])
        father_day = next(item for item in festivals["festivals"] if item["id"] == "father_day")
        self.assertEqual(father_day["ranges"], [])
        self.assertEqual(father_day["recurrence"], {
            "type": "nth_weekday_of_month",
            "month": 6,
            "weekday": 1,
            "ordinal": 3,
        })
        self.assertEqual(bundled_festivals, festivals)


if __name__ == "__main__":
    unittest.main()
