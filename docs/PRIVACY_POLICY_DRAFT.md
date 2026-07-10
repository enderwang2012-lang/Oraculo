# Oraculo Privacy Policy Draft

Last updated: 2026-07-10

Oraculo is a minimal daily phrase and color app. It does not require an account, does not show ads, and does not use third-party analytics or tracking SDKs.

## Data Oraculo Stores On Device

Oraculo stores small pieces of app state on your device so the main app and widgets can show the same daily phrase and color. This includes:

- The current daily phrase and color
- The installed corpus version
- A random installation identifier used only to vary phrase/color selection on this device
- Recent phrase exposure history used to avoid repetition
- Optional location context, if you enable location-enhanced daily context

This data is stored locally in the app's shared container for the main app and widget. It is not used to identify you across apps or websites.

## Optional Location Context

Location context is off by default.

If you enable location-enhanced daily context, Oraculo asks iOS for when-in-use location access. Oraculo uses your approximate area, weather, and elevation band to choose a phrase that better matches the day. Coordinates are rounded before being cached and before weather/elevation requests are made.

Oraculo may send rounded latitude and longitude to Open-Meteo to retrieve current weather and elevation. Open-Meteo is used only for this weather/elevation lookup. Oraculo does not sell location data, does not use it for advertising, and does not use it for tracking.

You can disable location context at any time in the app. When you disable it, Oraculo stops weather and elevation requests, deletes cached coordinates and location-derived weather, region, altitude, and geo-cell values, and returns to locale-only context. You can also revoke location permission in iOS Settings.

## Network Requests

Oraculo may request:

- Static corpus update files from `https://oraculo-corpus.vercel.app/oraculo/`
- Weather and elevation data from `https://api.open-meteo.com/` if location context is enabled

If network requests fail, Oraculo continues to work with bundled offline data.

## Tracking

Oraculo does not track you across apps or websites. Oraculo does not use IDFA, advertising SDKs, analytics SDKs, or crash reporting SDKs.

## Contact

For privacy questions, contact: enderwang2012@gmail.com
