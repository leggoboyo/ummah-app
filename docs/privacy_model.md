# Privacy Model

## Product posture
Ummah App is designed so the free core does not require an account, cloud sync, analytics, or telemetry. Prayer times, adhan reminders, qibla bearing, Hijri date, and Quran Arabic reading are intended to work fully offline.

## What is stored locally
### Shared preferences
- language choice
- fiqh profile and prayer calculation method
- location mode and manual city/coordinates
- adhan and notification preferences
- startup pack plan, deferred packs, Wi-Fi-only, and storage-saver preferences
- diagnostics log entries
- scholar-feed follow choices
- preview billing state when preview mode is used

### Secure OS storage
- BYOK OpenAI API key, if the user enables AI assistant BYOK mode

### Local databases
- Quran Arabic corpus
- Quran translation metadata and downloaded translation verses
- installed Sunni Hadith packs and Hadith finder search index
- fiqh bundled reference content and progress state

## What leaves the device, and only when
- QuranEnc requests: only when the user refreshes the translation catalog or downloads Quran translations
- Hadith content-pack requests: only when the user installs or updates Sunni Hadith packs
- IslamHouse RSS requests: only when the user refreshes scholar feeds
- OpenAI requests: only when the user submits an AI assistant question in BYOK mode
- RevenueCat requests: only for optional paid billing state and entitlement restoration

## What does not leave the device for the free core
- prayer calculations
- qibla math
- notification scheduling
- manual location choice
- Quran Arabic reading
- app profile and setup choices

## Location policy
- GPS is optional.
- manual city/manual coordinates are first-class and remain on-device.
- location permission is requested only when the user explicitly selects device location.
- manual location mode does not transmit coordinates to remote services.

## Diagnostics policy
- local diagnostics logs are stored on-device only.
- logs are redacted before persistence.
- support reports are redacted by default.
- identifiers and precise coordinates are only included when the user explicitly exports a detailed support report.

## Analytics policy
- no analytics or telemetry SDK is connected in the current app build.
- analytics remain disabled by default and are not part of the current runtime contract.

## Offline contract
### Always offline
- prayer times
- adhan reminders after scheduling
- qibla bearing
- Hijri date
- Quran Arabic text

### Offline after user download
- Quran translations
- Sunni Hadith finder packs

### Optional online
- AI assistant
- scholar feed refresh
- paid entitlement checks

## Founder checklist
- keep remote services optional
- do not add telemetry without explicit consent design, docs, and code review
- do not add background location or hidden refresh behavior
- avoid logging raw religious queries, coordinates, or billing identifiers
