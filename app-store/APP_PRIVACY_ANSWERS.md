# App Store Connect Privacy Answers

This file records the conservative repository-backed answers for Oraculo 1.0.0. The Account Holder must verify the final answers against the App Store Connect wording shown at submission time.

## Tracking

- Tracking: **No**
- Data used to track users across apps or websites: **None**
- Advertising or advertising measurement: **None**
- Third-party analytics: **None**

## Data Collection

Declare **Approximate Location** because the optional location context sends rounded latitude and longitude to Open-Meteo when the user enables the feature.

- Data type: Approximate Location
- Purpose: App Functionality
- Linked to the user's identity: No
- Used for tracking: No
- Required: No; the feature is optional and off by default

No account, name, email address, phone number, contacts, photos, payment data, health data, advertising identifier, diagnostics SDK data, or user-generated content is collected by the App.

## Permission Behavior

- Permission: Location When In Use
- First launch prompt: No
- Trigger: The user taps the location control, sees an in-app explanation, and chooses to continue
- Denial behavior: Core App and Widget functions remain available
- Disable behavior: Location, weather, region, altitude, and geo-cell caches are removed locally

## Privacy Manifest

- Required-reason API: UserDefaults, reason `CA92.1`
- Collected data disclosure: Coarse Location
- Purpose: App Functionality
- Linked: False
- Tracking: False

## Account-Holder Verification

Before submission, confirm that Open-Meteo's current service terms and request-retention practices do not require a broader disclosure. If the shipped network behavior changes, update this file, the privacy manifest, the public privacy policy, and App Store Connect together.
