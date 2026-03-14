# Repository Audit

## Non-negotiables
- No account is required for prayer times, adhan notifications, qibla, Hijri date, or Quran Arabic reading.
- No analytics or telemetry SDK is enabled by default.
- The free prayer core must keep working fully offline.
- Remote infrastructure is optional and must never become a hard dependency for core religious utilities.

## Architecture Overview
- `mobile/app`: Flutter shell, onboarding, settings, platform integrations, billing integration, and feature composition.
- `features/prayer`: local prayer calculation engine, notification queue planning, iOS windowing, and Android alarm policy.
- `features/qibla`: local qibla bearing calculation. Sensor-based compass remains a client-only enhancement.
- `features/quran`: local Arabic corpus, SQLite/FTS search, optional remote translation catalog and translation downloads.
- `features/hadith`: offline SQLite/FTS Hadith finder, remote pack manifest/access/download flow, and optional legacy HadeethEnc sync helpers.
- `features/fiqh`: bundled local knowledge pack and checklist engine.
- `features/ai_assistant`: optional BYOK OpenAI integration, strictly non-core.
- `features/scholar_feed`: optional RSS sync and local metadata cache.
- `features/subscriptions`: entitlement abstraction with preview and RevenueCat providers.
- `packages/core`: shared storage interfaces, entitlements, coordinates, source version metadata, and logging primitives.
- `services/content-pack-worker`: optional Cloudflare Worker for remote Hadith pack delivery.

## Data Flows
### Local-first core
- Prayer calculations are performed locally from coordinates, fiqh profile, and calculation method.
- Notification schedules are generated locally and handed to `flutter_local_notifications`.
- Qibla bearing is calculated locally from coordinates and Mecca bearing math.
- Quran Arabic is seeded from bundled assets into SQLite.

### Optional network surfaces
- Quran translations use QuranEnc only when the user refreshes or downloads them.
- Sunni Hadith packs use the optional content-pack Worker only when the user installs or refreshes them.
- Scholar Feed refreshes public RSS only when the user chooses to refresh.
- AI assistant sends requests to OpenAI only in BYOK mode after explicit user action.
- RevenueCat is used only for optional billing state and optional paid pack checks.

## Storage Surfaces
- `SharedPreferencesAsync`: app profile, startup pack choices, diagnostics log, followed feed choices, preview billing state.
- `flutter_secure_storage`: BYOK OpenAI API key.
- local SQLite databases:
  - Quran corpus and translation cache
  - Hadith offline finder corpus and pack install registry
- no cloud sync layer exists for core user state.

## Network Surfaces
- `https://quranenc.com/api/v1/`
- `https://hadeethenc.com/api/v1/`
- configured `apiBaseUrl` for the optional Hadith content-pack Worker
- `https://api.openai.com/v1/responses`
- IslamHouse RSS feeds
- RevenueCat customer lookup from the Worker and RevenueCat SDK from the mobile app

## Main Risk Areas Before This Hardening Pass
- `AppController` had accumulated too many orchestration responsibilities.
- diagnostics/support UI exposed identifiers too casually.
- onboarding/startup content-pack planning could consult remote Hadith metadata even before the user opened Hadith.
- privacy/security docs were missing.
- CI covered analyze/test/build but not format enforcement, dependency review, JS-side checks, or size reporting.
- optional infrastructure existed without enough contract documentation and regression coverage.

## Risk Register
### Privacy
- raw location coordinates and app identifiers could appear in local diagnostics and support surfaces.
- an exposed analytics toggle implied future tracking normalization despite no analytics SDK being installed.

### Security
- Worker download grants were not bound tightly enough to app user identity and environment.
- paid-pack misconfiguration could degrade like a normal entitlement denial instead of a service-unavailable condition.

### Reliability
- optional remote pack discovery was too close to onboarding/startup.
- foldable/resume regression coverage was weak.

### Maintainability
- bootstrap orchestration lived in one controller.
- docs for privacy, security, and developer workflows were missing.

## Dependency Inventory Notes
- no Firebase, Sentry, or analytics SDK is installed.
- mobile depends on `geolocator`, `flutter_local_notifications`, `flutter_secure_storage`, `purchases_flutter`, and `flutter_compass`.
- Quran and Hadith both depend on `sqlite3` and `sqlite3_flutter_libs`.
- the Worker has a single JS runtime dependency footprint via `wrangler`.

## Hardening Direction
- keep the optional Worker because it reduces installer size materially without touching the free prayer core.
- make diagnostics redacted by default and support exports explicit.
- keep core startup flows remote-free.
- broaden CI and documentation so a solo founder can reason about the repo safely.
