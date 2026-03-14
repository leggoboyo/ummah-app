# Privacy Review Checklist

- No account is required for the free core.
- No analytics SDK is present in dependencies.
- No telemetry or hidden background network calls occur on app launch.
- Manual city/manual coordinates remain functional without GPS permission.
- Location permission is requested only after explicit user action.
- Core prayer/qibla/Quran Arabic flows work with networking disabled.
- Logs do not persist raw coordinates, raw API keys, or passive billing identifiers.
- Support reports are redacted by default.
- Secure storage is used for BYOK secrets.
- Optional remote features are clearly labeled as optional and user-initiated.
- Settings copy accurately describes what is stored locally and what leaves the device.
- New dependencies are screened for analytics, ad-tech, or hidden telemetry behavior before adoption.
