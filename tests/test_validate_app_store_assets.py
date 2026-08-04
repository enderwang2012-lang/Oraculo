import json
import plistlib
import struct
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from validate_app_store_assets import validate_repository  # noqa: E402


class AppStoreAssetValidationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        self._write_valid_repository()

    def tearDown(self) -> None:
        self.temp_dir.cleanup()

    def test_valid_repository_has_no_errors(self) -> None:
        self.assertEqual(validate_repository(self.root), [])

    def test_rejects_metadata_over_apple_limits(self) -> None:
        metadata_path = self.root / "app-store/metadata/zh-Hans.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["subtitle"] = "超" * 31
        metadata_path.write_text(json.dumps(metadata, ensure_ascii=False), encoding="utf-8")

        errors = validate_repository(self.root)

        self.assertTrue(any("subtitle" in error and "30" in error for error in errors))

    def test_rejects_third_party_brand_in_customer_copy(self) -> None:
        metadata_path = self.root / "app-store/metadata/zh-Hans.json"
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        metadata["description"] += " 与 Starbucks 联名。"
        metadata_path.write_text(json.dumps(metadata, ensure_ascii=False), encoding="utf-8")

        errors = validate_repository(self.root)

        self.assertTrue(any("third-party brand" in error for error in errors))

    def test_rejects_third_party_brand_in_review_notes(self) -> None:
        review_path = self.root / "app-store/review-notes.zh-Hans.md"
        review_path.write_text(
            review_path.read_text(encoding="utf-8") + "星巴克合作内容。\n",
            encoding="utf-8",
        )

        errors = validate_repository(self.root)

        self.assertTrue(any("review notes" in error and "third-party brand" in error for error in errors))

    def test_rejects_non_release_version_and_missing_team(self) -> None:
        project_path = self.root / "ios/project.yml"
        project_path.write_text(
            project_path.read_text(encoding="utf-8")
            .replace('MARKETING_VERSION: "1.0.0"', 'MARKETING_VERSION: "0.1.0"')
            .replace('DEVELOPMENT_TEAM: "TEAMID1234"', 'DEVELOPMENT_TEAM: ""'),
            encoding="utf-8",
        )

        errors = validate_repository(self.root)

        self.assertTrue(any("MARKETING_VERSION" in error for error in errors))
        self.assertTrue(any("DEVELOPMENT_TEAM" in error for error in errors))

    def test_requires_non_exempt_encryption_declaration(self) -> None:
        project_path = self.root / "ios/project.yml"
        project_path.write_text(
            project_path.read_text(encoding="utf-8").replace(
                "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO",
                "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: YES",
            ),
            encoding="utf-8",
        )

        errors = validate_repository(self.root)

        self.assertTrue(any("non-exempt encryption" in error for error in errors))

    def test_requires_coarse_location_privacy_disclosure(self) -> None:
        manifest_path = self.root / "ios/Oraculo/PrivacyInfo.xcprivacy"
        manifest = plistlib.loads(manifest_path.read_bytes())
        manifest["NSPrivacyCollectedDataTypes"] = []
        manifest_path.write_bytes(plistlib.dumps(manifest))

        errors = validate_repository(self.root)

        self.assertTrue(any("coarse location" in error for error in errors))

    def test_requires_1024_square_app_icon(self) -> None:
        icon_path = self.root / "ios/Oraculo/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        icon_path.write_bytes(self._png_header(512, 1024))

        errors = validate_repository(self.root)

        self.assertTrue(any("1024x1024" in error for error in errors))

    def test_rejects_app_icon_with_alpha_channel(self) -> None:
        icon_path = self.root / "ios/Oraculo/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        icon_path.write_bytes(self._png_header(1024, 1024, color_type=6))

        errors = validate_repository(self.root)

        self.assertTrue(any("alpha channel" in error for error in errors))

    def _write_valid_repository(self) -> None:
        project = """\
name: Oraculo
options:
  xcodeVersion: "26.5"
settings:
  base:
    MARKETING_VERSION: "1.0.0"
    CURRENT_PROJECT_VERSION: "1"
    DEVELOPMENT_TEAM: "TEAMID1234"
targets:
  Oraculo:
    settings:
      base:
        INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
  OraculoWidget:
    settings:
      base:
        MARKETING_VERSION: "1.0.0"
        CURRENT_PROJECT_VERSION: "1"
"""
        self._write_text("ios/project.yml", project)

        manifest = {
            "NSPrivacyAccessedAPITypes": [
                {
                    "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryUserDefaults",
                    "NSPrivacyAccessedAPITypeReasons": ["CA92.1"],
                }
            ],
            "NSPrivacyCollectedDataTypes": [
                {
                    "NSPrivacyCollectedDataType": "NSPrivacyCollectedDataTypeCoarseLocation",
                    "NSPrivacyCollectedDataTypeLinked": False,
                    "NSPrivacyCollectedDataTypeTracking": False,
                    "NSPrivacyCollectedDataTypePurposes": [
                        "NSPrivacyCollectedDataTypePurposeAppFunctionality"
                    ],
                }
            ],
            "NSPrivacyTracking": False,
            "NSPrivacyTrackingDomains": [],
        }
        manifest_path = self.root / "ios/Oraculo/PrivacyInfo.xcprivacy"
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_bytes(plistlib.dumps(manifest))

        metadata = {
            "version": "1.0.0",
            "sku": "oraculo-ios-001",
            "name": "Oraculo",
            "subtitle": "每日一句与色彩小组件",
            "promotionalText": "每天打开一小会儿，看见一句话和一种颜色。",
            "description": "Oraculo 用一句短签和一种颜色陪你经过今天。",
            "keywords": "每日一句,日签,小组件,锁屏,色彩,短句",
            "primaryCategory": "Lifestyle",
            "secondaryCategory": "Utilities",
            "privacyPolicyUrl": "https://oraculo-corpus.vercel.app/privacy/",
            "supportUrl": "https://oraculo-corpus.vercel.app/support/",
            "marketingUrl": "https://oraculo-corpus.vercel.app/",
            "contactEmail": "enderwang2012@gmail.com",
        }
        self._write_text(
            "app-store/metadata/zh-Hans.json",
            json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        )
        self._write_text(
            "app-store/review-notes.zh-Hans.md",
            "Oraculo 不需要账号。位置情境由用户主动开启，并使用 Open-Meteo。请测试 Widget。\n",
        )
        self._write_text(
            "app-store/screenshots/README.md",
            "Capture final iPhone and iPad screenshots from release build 1.0.0.\n",
        )
        self._write_text(
            "public/privacy/index.html",
            "<html><title>Oraculo 隐私政策</title><body>enderwang2012@gmail.com</body></html>\n",
        )
        self._write_text(
            "public/support/index.html",
            "<html><title>Oraculo 支持</title><body>enderwang2012@gmail.com</body></html>\n",
        )

        icon_path = self.root / "ios/Oraculo/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
        icon_path.parent.mkdir(parents=True, exist_ok=True)
        icon_path.write_bytes(self._png_header(1024, 1024))

    def _write_text(self, relative_path: str, content: str) -> None:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    @staticmethod
    def _png_header(width: int, height: int, color_type: int = 2) -> bytes:
        return (
            b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR"
            + struct.pack(">II", width, height)
            + bytes((8, color_type, 0, 0, 0))
        )


if __name__ == "__main__":
    unittest.main()
