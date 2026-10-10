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
