# Oraculo App Store Repository Preparation Plan

**Goal:** Complete every App Store launch artifact that can be prepared and verified inside the repository before account-bound signing, upload, and submission.

**Non-goals:** This work does not activate Apple membership, accept App Store Connect agreements, decide legal ownership of third-party source material, deploy the static site, create the App Store Connect record, capture final device screenshots, upload a build, or submit for review.

## Settled Decisions

- Launch Chinese-first and free.
- Keep the current iPhone and iPad target declaration; final iPad screenshots and device QA remain a release gate.
- Use `1.0.0 (1)` for the first release candidate.
- Preserve the detected paid-team identifier by moving it into `ios/project.yml`, the XcodeGen source of truth.
- Disclose optional coarse location conservatively as App Functionality, not linked to the user, and not used for tracking.
- Publish support and privacy content from the existing Vercel static site after repository review.
- Keep third-party brands out of customer-facing metadata and screenshots.

## Files And Responsibilities

- `ios/project.yml`: canonical version, build, Xcode, signing-team, bundle, and target settings.
- `ios/Oraculo/PrivacyInfo.xcprivacy`: required-reason API and coarse-location disclosure for the main app.
- `public/privacy/index.html`: deployable privacy policy.
- `public/support/index.html`: deployable support page.
- `public/assets/site.css`: shared static-page presentation.
- `app-store/metadata/zh-Hans.json`: structured Simplified Chinese App Store copy and URLs.
- `app-store/review-notes.zh-Hans.md`: reviewer-facing behavior and test instructions.
- `app-store/screenshots/README.md`: capture matrix and acceptance criteria.
- `scripts/validate_app_store_assets.py`: deterministic validation for metadata, pages, privacy, versioning, signing configuration, and icon dimensions.
- `tests/test_validate_app_store_assets.py`: behavioral coverage for the new validator.
- `docs/APP_STORE_READINESS.md`: one release runbook with repository, TestFlight, and account-bound gates.

## Implementation Order

1. Add failing validator tests covering metadata limits, prohibited customer-facing brand references, release version/team configuration, public pages, coarse-location disclosure, and the 1024-pixel icon.
2. Implement `validate_app_store_assets.py` and make the tests pass.
3. Set `1.0.0 (1)`, the detected Team ID, and Xcode 26.5 settings in `ios/project.yml`; regenerate the Xcode project without dropping the current automatic-upgrade settings.
4. Add coarse-location disclosure to the main app privacy manifest and align the policy wording.
5. Add deployable support/privacy pages and structured App Store metadata, review notes, and screenshot requirements.
6. Update the repository release runbook and product version references.
7. Run all repository validators, Python tests, Swift tests, XcodeGen drift checks, and an unsigned Release device build.

## Validation

Expected success signals:

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

- Every command exits zero.
- The Release build ends with `BUILD SUCCEEDED`.
- `git diff --check` emits no output.
- Regenerating the Xcode project from `ios/project.yml` produces no semantic configuration drift.

## Remaining External Gates

- Apple Developer Program membership must be active and the detected Team ID must belong to that paid team.
- The static pages must be deployed before their URLs are entered in App Store Connect.
- Content rights, seller copyright text, mainland-China filing, age rating, and App Privacy answers require account-holder confirmation.
- Final iPhone and iPad screenshots must be captured from the approved release candidate.
- A signed Archive, App Store validation, TestFlight QA, upload, and final submission require Apple-account access.

## Rollback

All repository changes are local and reviewable. Reverting the release-preparation files restores the previous `0.1.0` configuration; no production deployment or App Store state is changed by this plan.
