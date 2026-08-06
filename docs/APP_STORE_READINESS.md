# Oraculo App Store Readiness

This runbook separates repository-complete work from Apple-account, legal, deployment, and submission gates for Oraculo 1.0.0.

## Repository Baseline

The repository is configured for:

- App version `1.0.0`, build `3`
- iOS 17.0+
- iPhone and iPad device families
- Main bundle ID `ai.oraculo.app`
- Widget bundle ID `ai.oraculo.app.OraculoWidget`
- App Group `group.ai.oraculo.shared`
- Automatic signing with Team ID `Z2XJ76A563` (`ender wang`) stored in `ios/project.yml`
- `ITSAppUsesNonExemptEncryption = NO` for the current HTTPS and SHA-256-only implementation
- Chinese-first, free launch metadata
- Main App privacy disclosure for optional coarse location

The paid Apple Developer Program team and Team ID are confirmed. Bundle IDs, the App Group, certificates, and provisioning profiles must still resolve under this team before signed Archive.

## Release Gates

Run these checks before every release candidate:

```bash
python3 scripts/validate_app_store_assets.py
python3 scripts/validate_release_readiness.py
python3 scripts/validate_corpus.py
python3 scripts/validate_dispatch.py
python3 scripts/validate_phrase_freshness.py
python3 -m unittest discover -s tests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test --package-path ios
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Oraculo.xcodeproj -scheme Oraculo -destination 'generic/platform=iOS' -configuration Release CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

The machine's active developer directory may still point to Command Line Tools. Keep the explicit `DEVELOPER_DIR` prefix unless `xcode-select -p` already returns `/Applications/Xcode.app/Contents/Developer`.

## XcodeGen And Signing

`ios/project.yml` is the source of truth. After changing version, build, signing, capabilities, or target settings, regenerate:

```bash
cd ios
xcodegen generate
```

Before signed Archive:

- Verify Apple Developer Program membership is active.
- Verify the configured Team ID belongs to that paid team.
- Register `ai.oraculo.app` and `ai.oraculo.app.OraculoWidget`.
- Register `group.ai.oraculo.shared` and enable it for both identifiers.
- Confirm Automatic Signing resolves App Store distribution profiles for both targets.
- Increment `CURRENT_PROJECT_VERSION` for every new upload.

## Metadata And Public URLs

Repository-owned material:

- `app-store/metadata/zh-Hans.json`
- `app-store/review-notes.zh-Hans.md`
- `app-store/APP_PRIVACY_ANSWERS.md`
- `app-store/screenshots/README.md`
- `public/index.html`
- `public/support/index.html`
- `public/privacy/index.html`

Deploy `public/`, then read back all three pages over HTTPS before entering:

- Marketing URL: `https://oraculo-corpus.vercel.app/`
- Support URL: `https://oraculo-corpus.vercel.app/support/`
- Privacy Policy URL: `https://oraculo-corpus.vercel.app/privacy/`

Do not mention third-party coffee brands or imply affiliation in the title, subtitle, description, review notes, screenshots, or public pages.

## Privacy

The shipped behavior and all disclosures must remain aligned:

- No account, ads, tracking, or third-party analytics SDK.
- Location context is optional and off by default.
- The first launch does not automatically request location.
- When enabled, rounded coordinates are sent to Open-Meteo for weather or elevation lookup.
- App Privacy uses the conservative Approximate Location disclosure: App Functionality, not linked, not tracking.
- Disabling location context clears locally cached coordinates and location-derived values.
- App and Widget share local state through the App Group.

If network behavior changes, update the privacy manifest, public policy, App Store privacy answers, and reviewer notes together.

## Content Rights Decision

The Account Holder confirmed on 2026-08-04 that the content-rights judgment for the reviewed 1.0.0 corpus was complete. `app-store/CONTENT_RIGHTS_REVIEW.md` records that decision and the three individually reviewed homage/inspiration entries without presenting a legal opinion.

Reopen the gate for future externally sourced additions, rewrites, provenance changes, or newly discovered risks. Corpus quality retirement alone does not replace a content-rights decision.

After any corpus removal or replacement:

```bash
python3 scripts/rebuild_corpus.py \
  --publish \
  --base-url https://oraculo-corpus.vercel.app/oraculo \
  --min-app-version 1.0.0 \
  --release-notes "本次语料调整摘要"
python3 scripts/validate_release_readiness.py
```

## Screenshot And Device Scope

The current project supports both iPhone and iPad. Keep iPad screenshots and QA in scope unless `TARGETED_DEVICE_FAMILY` is deliberately changed before the final Archive.

Capture final screenshots only from the approved release candidate. Follow `app-store/screenshots/README.md`; do not use debug builds, personal notifications, uncleared corpus entries, or third-party branding.

## TestFlight QA

Run these checks on physical devices:

- Fresh install without network opens with bundled phrase and color.
- Fresh install with network does not block on corpus refresh.
- First launch shows no automatic location prompt.
- Tapping the location control shows the rationale before the iOS permission prompt.
- Denying or restricting location keeps the App and Widget usable.
- Allowing location refreshes weather/elevation context without blocking the UI.
- Disabling location stops further requests and clears location-derived caches.
- Home Screen Small and Medium Widgets render without clipping.
- Lock Screen Inline and Rectangular Widgets render without clipping.
- After Widget refresh, tapping into the App shows the synchronized current moment.
- Background/foreground transitions do not leave stale or half-faded text.
- Day rollover produces the expected daily state.
- Long-press charge changes phrase and color.
- VoiceOver and Reduce Motion are usable.
- iPad full-screen portrait layout is acceptable if iPad support remains enabled.

## App Store Connect Submission

Account-bound completion checklist:

- Create the App record with the main bundle ID and SKU `oraculo-ios-001`.
- Confirm App name availability, legal seller/copyright text, categories, and free pricing.
- Complete the current age-rating questionnaire.
- Confirm the generated `ITSAppUsesNonExemptEncryption = NO` declaration still matches the uploaded build.
- Reconfirm the recorded Content Rights decision if the corpus changed after 2026-08-04.
- Confirm mainland-China filing requirements before selecting that storefront.
- Upload a signed Archive and pass Xcode/App Store validation.
- Attach final screenshots and the approved TestFlight build.
- Verify public Support and Privacy URLs.
- Submit with the reviewer notes in `app-store/review-notes.zh-Hans.md`.
- Prefer manual release so the storefront can be checked after approval.
