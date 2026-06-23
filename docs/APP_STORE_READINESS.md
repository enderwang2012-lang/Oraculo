# Oraculo App Store Readiness

This checklist captures the project-side and App Store Connect items needed before submitting Oraculo.

## Project-Side Gate

Run these checks before every release candidate:

```bash
python3 scripts/validate_release_readiness.py
python3 scripts/validate_corpus.py
python3 scripts/validate_dispatch.py
python3 scripts/validate_phrase_freshness.py
python3 -m unittest tests/test_tag_phrases_rules.py tests/test_phrase_freshness_tags.py
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Oraculo.xcodeproj -scheme Oraculo -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Oraculo.xcodeproj -scheme Oraculo -destination 'generic/platform=iOS' -configuration Release CODE_SIGNING_ALLOWED=NO build
```

## Signing

- Register bundle ID `ai.oraculo.app`.
- Register bundle ID `ai.oraculo.app.OraculoWidget`.
- Enable App Group `group.ai.oraculo.shared` for both bundle IDs.
- Set `DEVELOPMENT_TEAM` in `ios/project.yml` or in Xcode before Archive.
- For public release, set `MARKETING_VERSION` to the intended App Store version, such as `1.0.0`.
- Increment `CURRENT_PROJECT_VERSION` for each uploaded build.

After changing `ios/project.yml`, regenerate:

```bash
cd ios
xcodegen generate
```

## Privacy

Project manifests:

- `ios/Oraculo/PrivacyInfo.xcprivacy`
- `ios/OraculoWidget/PrivacyInfo.xcprivacy`

App Store Connect privacy answers should match the actual release behavior:

- No tracking.
- No ads.
- No analytics SDK.
- No account.
- Optional location context is off by default.
- If location context is enabled, rounded coordinates may be sent to Open-Meteo for weather/elevation lookup.
- Local App Group storage is used to sync the current phrase/color and widget state.

Publish a privacy policy URL. `docs/PRIVACY_POLICY_DRAFT.md` is a draft; confirm the contact email and host the final policy before publication.

## Corpus Release

The bundled corpus and public hot-update corpus must use one version/SHA line.

To rebuild and sync public artifacts:

```bash
python3 scripts/rebuild_corpus.py --publish
python3 scripts/publish_corpus_static.py --base-url https://oraculo-corpus.vercel.app/oraculo
python3 scripts/validate_release_readiness.py
```

After push/deploy, verify the live CDN:

```bash
python3 scripts/verify_corpus_cdn.py
```

## TestFlight QA

Run these on a real device:

- Fresh install, no network: app opens with bundled phrase/color.
- Fresh install, network on: app opens without blocking on network.
- First launch: no location prompt appears automatically.
- Tap location control: iOS location prompt appears.
- Deny location: app remains usable, widgets still work.
- Allow location: weather/elevation context refreshes without visible delay.
- Disable location context: no further location requests are made from normal scene activation.
- Home screen small widget shows phrase and color.
- Home screen medium widget shows phrase and subtitle.
- Lock screen inline widget shows one-line phrase.
- Lock screen rectangular widget fits two-line phrase.
- App background/foreground transition does not leave half-faded text.
- Long-press logo changes phrase/color after charge.
- Reduce Motion and VoiceOver are usable enough for v1.

## App Store Metadata Notes

- Do not mention third-party coffee brands or imply affiliation in title, subtitle, screenshots, or description.
- Describe Oraculo as a daily phrase/color widget app.
- Screenshots should show the app, small/medium widgets, and lock screen widget.
- Support URL and Privacy Policy URL must be live before submission.
