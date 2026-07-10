# Release Phase 1–2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make location opt-out enforceable and fix the release-blocking calendar, exposure, and App/Widget color-consistency defects.

**Architecture:** Introduce small shared policy/selection units with injectable state, then route existing App and Widget entry points through them. Use a standalone SwiftPM XCTest target so regression tests can run without regenerating the user-modified Xcode project.

**Tech Stack:** Swift 5.9, Foundation, SwiftUI, XCTest, Swift Package Manager, Python release validators.

---

### Task 1: Add the Swift regression-test harness

**Files:**
- Create: `ios/Package.swift`
- Create: `ios/OraculoCoreTests/LocationContextPrivacyTests.swift`
- Create: `ios/OraculoCoreTests/FestivalCalendarTests.swift`
- Create: `ios/OraculoCoreTests/PhraseExposureHistoryTests.swift`
- Create: `ios/OraculoCoreTests/DailyColorSelectorTests.swift`

- [ ] Write tests against the intended consent, calendar, exposure, and color APIs.
- [ ] Run `cd ios && swift test` and verify compilation or assertions fail because the intended APIs/behaviors do not exist yet.

### Task 2: Enforce location-context opt-out

**Files:**
- Modify: `ios/Shared/LocationContextCache.swift`
- Modify: `ios/Shared/WeatherContextCache.swift`
- Modify: `ios/Shared/GeoContext.swift`
- Modify: `ios/Shared/ContextSnapshotBuilder.swift`
- Modify: `ios/Shared/OpenMeteoWeatherService.swift`
- Modify: `ios/Shared/LocationContextProvider.swift`
- Modify: `ios/Oraculo/OraculoApp.swift`
- Modify: `docs/PRIVACY_POLICY_DRAFT.md`

- [ ] Make consent state injectable and clear all raw/derived caches on disable.
- [ ] Gate coordinate selection, weather refresh, and elevation requests on consent.
- [ ] Prevent asynchronous location callbacks from repopulating caches after opt-out.
- [ ] Make context construction ignore weather and cached location data while disabled.
- [ ] Run the location tests and verify they pass.

### Task 3: Correct festival boundaries

**Files:**
- Modify: `ios/Shared/FestivalCalendar.swift`

- [ ] Add JSON-data initialization for deterministic tests.
- [ ] Compare normalized calendar days using an exclusive end boundary.
- [ ] Evaluate the previous anchor year for recurring cross-year ranges.
- [ ] Run the festival tests and verify they pass.

### Task 4: Correct exposure accounting

**Files:**
- Modify: `ios/Shared/PhraseExposureHistory.swift`
- Modify: `ios/Shared/SharedOracleMomentStore.swift`
- Modify: `ios/Shared/DailyOracle.swift`
- Modify: `ios/Oraculo/OracleSessionModel.swift`

- [ ] Deduplicate consecutive records without comparing `shownAt`.
- [ ] Default persistence-only synchronization to `recordExposure: false`.
- [ ] Explicitly record only when a new moment is actually presented.
- [ ] Run the exposure tests and verify they pass.

### Task 5: Unify App and Widget color selection

**Files:**
- Modify: `ios/Shared/NipponColor.swift`
- Modify: `ios/Shared/PhraseStore.swift`
- Modify: `ios/Shared/NipponColorStore.swift`
- Modify: `ios/OraculoWidget/OraculoWidget.swift`

- [ ] Move deterministic hashing to `StableSeed`.
- [ ] Move candidate filtering and weighted color choice to `DailyColorSelector`.
- [ ] Route App and Widget through the same selector with context tags.
- [ ] Run the color tests and verify they pass.

### Task 6: Verify the complete change

- [ ] Run `cd ios && swift test`.
- [ ] Run `python3 -m unittest discover -s tests -v`.
- [ ] Run the corpus and release validators.
- [ ] Run an available unsigned Release source build without overwriting `Oraculo.xcodeproj`.
- [ ] Run `git diff --check` and inspect `git status`.
