import sys
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from tag_phrases_rules import build_dispatch  # noqa: E402


def boost_tags(text: str) -> set[str]:
    return {boost["tag"] for boost in build_dispatch(text, "")["boost"]}


class TagPhraseRulesTests(unittest.TestCase):
    def test_explicit_summer_phrase_is_season_locked(self) -> None:
        dispatch = build_dispatch("夏意半熟", "季节心情")

        self.assertFalse(dispatch["universal"])
        self.assertEqual(dispatch["onlyWhen"], ["season:summer"])

    def test_explicit_spring_festival_phrase_is_festival_locked(self) -> None:
        dispatch = build_dispatch("财神到家", "财运祝福")

        self.assertFalse(dispatch["universal"])
        self.assertEqual(dispatch["onlyWhen"], ["festival:spring_festival"])

    def test_ice_drink_language_does_not_trigger_snow_weather(self) -> None:
        for text in ("好运加冰", "来杯冰美式"):
            with self.subTest(text=text):
                self.assertNotIn("weather:snow", boost_tags(text))

    def test_winter_weather_language_still_triggers_snow_weather(self) -> None:
        for text in ("雪落窗前", "路面结冰"):
            with self.subTest(text=text):
                self.assertIn("weather:snow", boost_tags(text))


if __name__ == "__main__":
    unittest.main()
