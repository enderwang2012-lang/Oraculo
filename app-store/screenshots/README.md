# Oraculo 1.0.0 App Store Screenshot Plan

Final screenshots must be captured from the approved `1.0.0` release candidate, without debug overlays, development notifications, personal data, or third-party brand references.

## iPhone Capture Matrix

| Order | Surface | Required state | Suggested caption |
| --- | --- | --- | --- |
| 1 | Main App | Balanced short phrase, representative color, clock visible | 每天，留下一句 |
| 2 | Main App after long press | A clearly different phrase and color | 长按，换一句也换一色 |
| 3 | Home Screen | Small and Medium Widget visible together | 放在主屏，随时看见 |
| 4 | Lock Screen | Inline and Rectangular Widget legible | 锁屏也有今天的一句 |
| 5 | Main App | Location context enabled, no system permission sheet covering the UI | 让此刻更贴近所在之处 |

## iPad Capture Matrix

The project currently declares iPad support. Capture at least:

1. Main App in full-screen portrait, with phrase, mark, and clock fully visible.
2. Home Screen Widget composition in a supported iPad size.

Oraculo 1.0.0 declares a full-screen, portrait-only interface on both iPhone and iPad. Do not submit a landscape screenshot unless the supported-orientation configuration changes before Archive.

If iPad support is removed before submission, remove the iPad capture requirement and regenerate the Xcode project before the final Archive.

## Acceptance Criteria

- Use only production corpus entries cleared for the release candidate.
- Keep Chinese and English text fully visible and professionally spaced.
- Do not place marketing captions over the App UI if they obscure the actual product state.
- Use the current App Store Connect screenshot dimensions for the selected iPhone and iPad device classes.
- Check status bar time, battery, carrier, and notification content before export.
- If the simulator status bar time is overridden, make it match Oraculo's visible in-App clock exactly.
- Confirm every screenshot matches behavior available in build `1.0.0 (1)`.
