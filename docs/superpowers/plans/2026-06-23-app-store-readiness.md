# App Store Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare Oraculo for TestFlight/App Store submission by closing privacy, permission, corpus version, orientation, and release-documentation gaps.

**Architecture:** Keep the release checks local and deterministic. Privacy manifests live in each target, location becomes an explicit user-enabled enhancement, corpus CDN artifacts stay version/SHA-aligned with bundled resources, and release docs capture the App Store Connect/manual steps.

**Tech Stack:** SwiftUI, WidgetKit, CoreLocation, XcodeGen project.yml, Python release validation, Vercel static corpus hosting.

---

### Task 1: Release Readiness Static Gate

**Files:**
- Create: `scripts/validate_release_readiness.py`

- [ ] Add checks for PrivacyInfo files, UserDefaults required reason declaration, no active-scene automatic location request, no Shanghai weather fallback, corpus bundle/public version alignment, and orientation/fullscreen configuration.
- [ ] Run before implementation and confirm it fails on current gaps.
- [ ] Run after implementation and require it to pass.

### Task 2: Privacy Manifest Coverage

**Files:**
- Create: `ios/Oraculo/PrivacyInfo.xcprivacy`
- Create: `ios/OraculoWidget/PrivacyInfo.xcprivacy`
- Modify: `ios/project.yml`
- Modify generated project if XcodeGen is unavailable.

- [ ] Add `NSPrivacyAccessedAPICategoryUserDefaults` with reason `CA92.1`.
- [ ] Include each manifest in the matching target resources.
- [ ] Verify the built app scans privacy files during `xcodebuild`.

### Task 3: Location Opt-In

**Files:**
- Modify: `ios/Shared/AppConstants.swift`
- Modify: `ios/Shared/LocationContextProvider.swift`
- Modify: `ios/Shared/OpenMeteoWeatherService.swift`
- Modify: `ios/Oraculo/OraculoApp.swift`
- Modify: `ios/Oraculo/ContentView.swift`

- [ ] Store a user-controlled location enhancement flag in App Group defaults.
- [ ] Do not request CoreLocation from scene activation until the user opts in.
- [ ] Add a small accessible control to enable/disable location-enhanced daily context.
- [ ] Avoid fetching Shanghai weather for users who have not opted into location or provided cached coordinates.

### Task 4: Corpus Version Alignment

**Files:**
- Modify: `public/oraculo/manifest.json`
- Modify: `public/oraculo/phrases.json`

- [ ] Re-publish static corpus from the currently bundled resources so v6 means the same payload locally and remotely.
- [ ] Verify CDN path script locally against updated public artifacts; live deploy remains a separate push/deploy step.

### Task 5: Orientation and Release Docs

**Files:**
- Modify: `ios/project.yml`
- Modify generated project if needed.
- Create: `docs/APP_STORE_READINESS.md`
- Create: `docs/PRIVACY_POLICY_DRAFT.md`

- [ ] Add `UIRequiresFullScreen` for the portrait-only v1 experience.
- [ ] Document App Store Connect privacy answers, signing requirements, TestFlight checklist, and release commands.
- [ ] Document the privacy policy draft without implying third-party brand affiliation.

### Task 6: Verification

**Commands:**
- `python3 scripts/validate_release_readiness.py`
- `python3 scripts/validate_corpus.py`
- `python3 scripts/validate_dispatch.py`
- `python3 scripts/validate_phrase_freshness.py`
- `python3 -m unittest tests/test_tag_phrases_rules.py tests/test_phrase_freshness_tags.py`
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Oraculo.xcodeproj -scheme Oraculo -destination 'generic/platform=iOS Simulator' -configuration Debug CODE_SIGNING_ALLOWED=NO build`
- `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project ios/Oraculo.xcodeproj -scheme Oraculo -destination 'generic/platform=iOS' -configuration Release CODE_SIGNING_ALLOWED=NO build`

- [ ] All checks pass before declaring readiness.
