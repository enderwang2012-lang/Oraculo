# Release Phase 1–2 Design

## Scope

This change implements the first two release-readiness phases approved after the repository review:

1. Make location opt-out authoritative across cache reads, network refreshes, derived context, and stored data.
2. Fix festival day boundaries and cross-year windows, prevent lifecycle-only exposure duplication, and make the App and Widget use one color-selection implementation.

Signing, AppIcon conversion, Archive validation, public privacy/support pages, and corpus hardening remain outside this change.

## Location privacy

`LocationContextSettings` in `LocationContextCache.swift` is the single source of truth for location-context consent. It owns reading and writing the opt-in flag and removes every raw or derived location/weather cache key when consent is disabled.

Cache and context readers accept injectable `UserDefaults` so the same production logic can be tested without the App Group container. `GeoContext` receives an explicit `allowCachedLocationContext` flag; when false, it ignores GPS-derived region, altitude, source, and geo-cell values and falls back to locale-only context. `ContextSnapshotBuilder` uses this flag and an empty weather cache whenever consent is disabled.

Open-Meteo high-level entry points check consent before selecting coordinates or issuing weather/elevation requests. The location provider also rechecks consent before and after asynchronous work so a callback that arrives after opt-out cannot repopulate cleared caches.

## Festival calendar

Festival matching compares `startOfDay` values and uses an exclusive end boundary one day after the configured end plus `post_days`. For recurring month/day ranges, both the current anchor year and the previous anchor year are evaluated so January dates can match windows beginning in December.

The calendar accepts JSON data through an internal initializer, allowing regression tests to use small deterministic fixtures without relying on `Bundle.main`.

## Exposure history

Consecutive exposure records are deduplicated by display identity—phrase, source, day, and corpus version—rather than full value equality that includes `shownAt`. A phrase can still be recorded again after another phrase has been displayed.

Persistence APIs default to not recording exposure. Actual moment presentation explicitly opts in; lifecycle-only Widget synchronization explicitly does not.

## Shared color selection

`DailyColorSelector` in `NipponColor.swift` owns candidate-pool filtering, deterministic seeding, and contextual weighting. Both `NipponColorStore` and the Widget call this implementation using the same day key, install ID, phrase dispatch, and context tags.

Stable hashing moves to `StableSeed`; existing `PhraseStore` helper methods remain as compatibility wrappers.

## Tests

A lightweight Swift Package in `ios/` compiles the production files needed by the regression suite without regenerating `Oraculo.xcodeproj`. Tests cover:

- opt-out cache deletion;
- stale coordinate rejection and zero network requests while disabled;
- locale-only context when cached location use is disabled;
- all-day, post-day, and cross-year festival boundaries;
- exposure deduplication without suppressing later real redisplays;
- deterministic, context-aware shared color selection.
