# Oraculo App Store Package

This directory contains repository-owned submission material for the Chinese-first, free 1.0.0 launch.

## Ready In Repository

- Simplified Chinese metadata: `metadata/zh-Hans.json`
- Reviewer instructions: `review-notes.zh-Hans.md`
- Privacy questionnaire recommendation: `APP_PRIVACY_ANSWERS.md`
- Screenshot capture matrix: `screenshots/README.md`
- Content rights evidence and the Account Holder's completed decision record: `CONTENT_RIGHTS_REVIEW.md`
- Deployable privacy and support pages: `../public/privacy/` and `../public/support/`

Validate the package with:

```bash
python3 scripts/validate_app_store_assets.py
```

## App Store Connect Record

- Primary locale: Simplified Chinese (`zh-Hans`)
- Bundle ID: `ai.oraculo.app`
- SKU: `oraculo-ios-001`
- Version: `1.0.0`
- Build: `3`
- Price: Free
- Primary category: Lifestyle
- Secondary category: Utilities
- Support URL: `https://oraculo-corpus.vercel.app/support/`
- Privacy Policy URL: `https://oraculo-corpus.vercel.app/privacy/`
- Marketing URL: `https://oraculo-corpus.vercel.app/`

The URLs are submission-ready only after the `public/` directory has been deployed and read back over HTTPS.

## Account-Bound Fields

The Account Holder must supply or confirm:

- Developer membership and App Store Connect access
- Seller/copyright name exactly matching the legal account
- App name availability in App Store Connect
- Agreements, tax/banking status if later required, and team roles
- Mainland China filing information if that storefront is selected
- Current age-rating questionnaire
- Export-compliance answer shown for the uploaded build
- Final App Privacy attestation and any future Content Rights changes
- Availability territories and release timing

## Upload Boundary

The 1.0.0 content-rights gate is recorded as resolved. Before any future upload, reopen it if the corpus or provenance changes, verify the public URLs, use final screenshots, and pass Xcode Archive validation.
