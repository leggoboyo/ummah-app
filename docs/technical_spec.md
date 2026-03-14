# Technical Spec

## Stack

- Flutter application in `mobile/app`
- Dart packages for shared core and feature modules
- Local-first data model with no required backend for the free tier

## Repository Structure

- `packages/core`
- `features/prayer`
- `features/qibla`
- `features/quran`
- `features/hadith`
- `features/fiqh`
- `features/ai_assistant`
- `features/subscriptions`
- `mobile/app`

## Architectural Style

- Clean architecture with feature-first boundaries
- Pure Dart domain logic where possible for easy testing
- Flutter UI kept in the app layer until feature widgets stabilize
- Explicit ports/adapters for storage, secure storage, networking, location, sensors, and notifications

## Core Package Responsibilities

- logging and exportable local logs
- settings and user profile models
- entitlement definitions and feature gating helpers
- storage abstractions for key-value, secure storage, and SQLite-backed repositories
- source metadata and attribution models

## Data Model Highlights

### User Profile

- language code
- fiqh tradition
- school of thought
- prayer calculation method
- manual parameter overrides
- location mode
- manual coordinates
- timezone offset minutes
- notification preferences
- analytics opt-in

### Prayer Settings

- method preset
- fajr angle
- isha rule: angle or minutes
- maghrib rule: sunset, angle, or minutes
- asr method
- high latitude rule
- per-prayer minute offsets

### Fiqh Knowledge Record

- topic id
- classification
- school applicability
- evidence references
- notes
- contextual cautions

### Source Metadata

- provider key
- content key
- language
- version
- last synced at
- attribution text

## Storage Plan

- SQLite: searchable Quran, hadith, fiqh knowledge, cached feed metadata, local exportable error logs
- secure storage: BYOK API keys and future auth tokens
- key-value store: settings, lightweight flags, onboarding completion, notification health cache

## Notification Architecture

### Domain

- generate a 60-day local queue of upcoming prayer events
- iOS planner schedules a safe rolling subset below the pending notification ceiling
- Android policy chooses exact or inexact delivery based on user preference and platform permission state

### Platform Adapters

- iOS adapter: local notifications, queue replenishment on app launch, background refresh best effort
- Android adapter: exact alarms only after explicit opt-in and permission grant; otherwise inexact local notifications

## Qibla Architecture

- great-circle bearing math done locally
- bearing mode requires no sensors
- compass mode consumes heading data from sensor adapters and warns about calibration error

## Quran and Hadith Strategy

- Quran Arabic text shipped offline in app assets
- Quran translations fetched from QuranEnc, cached verbatim, tagged with version and language
- Sunni hadith fetched from HadeethEnc, cached verbatim with attribution
- Shia hadith kept behind a licensed provider interface until a vetted source exists

## AI Assistant Strategy

- BYOK first: OpenAI key stored in secure storage
- hosted mode deferred behind a network adapter and entitlement check
- retrieval pipeline restricted to local indexed corpora and explicitly whitelisted feeds
- answer formatter always separates verbatim sources from commentary

## Suggested Production Dependencies

- Flutter SDK
- `flutter_local_notifications`
- `geolocator`
- `flutter_compass` or a custom sensor adapter
- `sqflite` or `sqlite3_flutter_libs` backed access
- `flutter_secure_storage`
- `shared_preferences`
- `in_app_purchase` or `purchases_flutter` if RevenueCat is adopted

## Observability

- no analytics by default
- local logs only unless user opts into diagnostics
- exportable logs for support

## Release Engineering

- GitHub Actions for analyze, unit tests, widget tests, Android build, and iOS archive
- environment flavors: `dev`, `staging`, `prod`
- compile-time environment variables for API endpoints, hosted AI toggle, and entitlement provider selection
