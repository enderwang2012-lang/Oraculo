# Oraculo 1.1.0 (7)

## Release scope

- Keep the 223 approved phrases and their display text.
- Publish phrases and festival/solar-term configuration together as corpus release v13.
- Use one validated App Group release for the app and widgets, with bundled offline fallback.
- Use Gregorian dates in Asia/Shanghai for date matching and widget midnight entries.
- Prefer the matching exclusive phrase pool on special dates. Preserve ordinary seasonal selection on other days.
- Prevent old release snapshots from overriding updated dates and phrases.

## Customer release notes

更新秋冬短签
让节日与特别日期遇见更应景的一句
优化 App 与小组件的内容同步

## Reviewer notes

No account is required. The app remains usable offline.
The static HTTPS update now downloads a calendar JSON alongside the existing phrase JSON.
Both files are data only. The app verifies checksums and activates them as one release.
Location access, privacy settings, screenshots, and entitlements are unchanged.

## Release boundary

The CDN release requires App 1.1.0. Existing 1.0.0 installations retain their previous content.
A successful CDN deployment does not mean the binary has passed App Store review.
Use the build/archive/upload logs and App Store Connect status to establish the binary's release state.

## Verified on 2026-10-10

- Implementation commit: `7c85ce53b84a627564c3cd174f3000be6c1858a6`, pushed to `origin/main`.
- Python: 50 tests passed. Swift: 44 tests passed, including 600 real-corpus date selections.
- Corpus, dispatch, freshness, candidate/release readiness and Git whitespace checks passed.
- iOS Release build and signed archive succeeded. App and Widget both contain 1.1.0 (7), v13, 223 phrases and matching calendar/phrase SHA values.
- All 223 Chinese/English display pairs match v12, including `Care for a cup` without punctuation.
- Vercel production read-back passed for release v13, both asset hashes, 223 phrases and selected IDs.
- Local default connection timed out. Read-back succeeded using the verified Vercel edge address `76.76.21.22` with the original HTTPS hostname.
- App Store Connect upload returned `Upload succeeded` and `EXPORT SUCCEEDED` at 18:13 China time.
- Build `d6c3f40d-2c31-4827-b393-08c83c58ca43` was processed and attached to version 1.1.0.
- App Store Connect submission `562377c6-e2bb-4d5d-b0b6-7bf2bc5c5790` was accepted at 18:19 China time. Status: waiting for review.
- Release mode remains manual after approval. App 1.1.0 is not yet publicly released.

Assets:

```text
phrases SHA256
8c1b7c852af7df9481a14fe5b23b39b6b4a7281eff0ebe80aeaba480ca1ee55e

calendar SHA256
6bf86a12944b80271231315da15b76c1a676b470b50870df1ef07ddf7c19a900
```

Archive: `outputs/releases/Oraculo-1.1.0-7.xcarchive`.
Upload options: `outputs/TestFlightExportOptions.plist`.
Uploaded reviewer notes: `review-notes-1.1.0.en.md`.
