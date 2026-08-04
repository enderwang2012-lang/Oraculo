# Oraculo 1.0.0 Content Rights Review

`releaseStatus: resolved_by_account_holder`

This is an evidence inventory and decision record, not a legal opinion or substitute for retained authorization evidence.

On 2026-08-04, the Account Holder confirmed that the content-rights judgment for the 1.0.0 production corpus had been completed. The reviewed corpus, including the three individually flagged entries below, may remain in distribution under that decision.

## Reviewed 1.0.0 Corpus

The content-rights decision covered the 248 entries in the 1.0.0/v7 corpus ledger. Later lifecycle filtering may exclude reviewed entries from generated payloads without changing this historical review scope:

| Source group | Count | Repository evidence | Release concern |
| --- | ---: | --- | --- |
| Observed external campaign/order phrases (`S*`) | 218 | `starbucks_now_passphrases.csv` and `starbucks_now_sources.md` | Short-text copyright, campaign ownership, trademark context, and source terms require review |
| Generated/editorial phrases (`GEN*`) | 27 | Corpus notes and review artifacts | Confirm originality and absence of close copying |
| User-provided phrases (`USER`) | 3 | Corpus notes and review artifacts | All three require individual provenance review |

## Explicit High-Risk Entries

| Corpus ID | Phrase | Recorded provenance | Recorded decision |
| --- | --- | --- | --- |
| `2042` | 站在能分割世界的桥 | User-provided; notes record song-lyric inspiration | Review completed; retained |
| `2057` | 孤独海怪 | Truncated homage to《秦皇岛》; lyricist recorded as 姬赓 | Review completed; retained |
| `2059` | 囿于昼夜 | Truncated homage to《揪心的玩笑与漫长的白日梦》; lyricist recorded as 姬赓 | Review completed; retained |

## Customer-Facing Controls Already Applied

- App Store metadata, public pages, review notes, and screenshot requirements do not name or imply affiliation with any third-party coffee brand.
- The repository validator rejects those brand references in customer-facing metadata and public pages.
- Research/source files remain internal evidence and are not shipped as App Store marketing copy.

## Ongoing Boundary

The 2026-08-04 decision closes the recorded gate for the reviewed 1.0.0 corpus only. It does not automatically clear future additions, rewrites, source-policy changes, or newly discovered provenance information.

For future corpus releases, record source type and provenance during review, reopen this gate for any externally sourced or homage entry, and retain the supporting decision outside this repository where appropriate.
