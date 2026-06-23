# Phrase Freshness And Widget Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a production-ready phrase freshness distribution layer where App interactions update Widget current state, while Widget still auto-generates a new daily phrase when the App has not opened today.

**Architecture:** Keep existing context dispatch as the base relevance score, then multiply by local freshness scoring from App Group exposure history. Phrase metadata ships inside `phrases.json`; current display state and exposure history stay local in App Group storage.

**Tech Stack:** Swift, WidgetKit, App Group UserDefaults, Python corpus pipeline, XCTest-ready pure Swift units through compiler-safe small types, Python unittest validation.

---

### Task 1: Corpus Freshness Metadata

**Files:**
- Create: `config/phrase_freshness_tags.json`
- Create: `scripts/tag_phrase_freshness.py`
- Create: `scripts/validate_phrase_freshness.py`
- Modify: `scripts/embed_corpus.py`
- Modify: `scripts/validate_corpus.py`
- Modify: `scripts/rebuild_corpus.py`
- Test: `tests/test_phrase_freshness_tags.py`

- [ ] **Step 1: Write failing tests for generated freshness metadata**

Create tests that assert generated tags include every phrase id, stable clusters, cadence groups, and lifecycle values.

- [ ] **Step 2: Implement tag generation and validation**

Generate deterministic initial metadata from existing CSV fields and text patterns. Keep the config file explicit so it can be manually curated later.

- [ ] **Step 3: Embed metadata into `phrases.json`**

Add `freshness` to each phrase object while keeping old JSON decoding compatible.

### Task 2: Local Exposure History And Freshness Scoring

**Files:**
- Create: `ios/Shared/PhraseFreshness.swift`
- Create: `ios/Shared/PhraseSelectionSource.swift`
- Create: `ios/Shared/PhraseExposureHistory.swift`
- Create: `ios/Shared/PhraseFreshnessScorer.swift`
- Modify: `ios/Shared/AppConstants.swift`
- Modify: `ios/Shared/Phrase.swift`
- Modify: `ios/Shared/PhrasePicker.swift`

- [ ] **Step 1: Add Codable data units**

Add local-only exposure records and phrase metadata models.

- [ ] **Step 2: Add scoring**

Use context score as base and multiply item, semantic cluster, cadence, lifecycle, and unseen-new-corpus factors.

- [ ] **Step 3: Keep fallback safe**

Missing metadata must decode and score as active fallback metadata.

### Task 3: Shared Current Moment Store

**Files:**
- Create: `ios/Shared/SharedOracleMomentStore.swift`
- Modify: `ios/Shared/DailyOracle.swift`
- Modify: `ios/Shared/AppConstants.swift`
- Modify: `ios/Shared/PhraseStore.swift`
- Modify: `ios/Shared/SessionOracleService.swift`
- Modify: `ios/Oraculo/OracleSessionModel.swift`
- Modify: `ios/OraculoWidget/OraculoWidget.swift`

- [ ] **Step 1: Add shared current moment**

Save phrase, color, dayKey, shownAt, source, and corpus version as one JSON payload in App Group.

- [ ] **Step 2: App writes every displayed moment**

Any moment displayed in App writes `appInteraction`, records one exposure, and reloads widgets.

- [ ] **Step 3: Widget reads today current moment or generates daily auto**

If shared current moment belongs to today, Widget renders it. If not, Widget generates `dailyAuto`, saves it, records one exposure, and renders it.

### Task 4: Simulation And Docs

**Files:**
- Create: `scripts/simulate_phrase_freshness.py`
- Modify: `docs/CORPUS.md`
- Modify: `docs/CONTEXTUAL_PHRASE_DISPATCH.md`

- [ ] **Step 1: Add simulation metrics**

Report exact repeats, semantic cluster repeats, cadence repeats, context match proxy, anchor exposure, new exposure, and fallback count.

- [ ] **Step 2: Document rules**

Document shared current sign behavior, daily auto fallback, freshness fields, exposure history, and rebuild steps.

### Task 5: Verification

**Files:**
- All modified files

- [ ] **Step 1: Run Python tests**

Run `python3 -m unittest discover -s tests`.

- [ ] **Step 2: Run corpus validation and rebuild**

Run `python3 scripts/validate_corpus.py`, `python3 scripts/validate_phrase_freshness.py`, and `python3 scripts/rebuild_corpus.py`.

- [ ] **Step 3: Run Swift compile check if toolchain is available**

Run the available Xcode or project generation command and report exact output.
