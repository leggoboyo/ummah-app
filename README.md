# Ummah App

Ummah App is a privacy-first, offline-first Flutter application for iOS and Android. The project is being built around a narrow promise: keep the free worship core useful without an app account, without analytics by default, and without turning the app into a backend-heavy product.

## Current product shape

- Free core:
  - prayer times
  - adhan reminders
  - qibla
  - Hijri date
  - Quran Arabic reading
- Optional modules:
  - Quran translations cached locally after user download
  - Sunni Hadith Finder with optional language packs
  - scholar feed refresh
  - BYOK AI assistant
  - paid billing for optional modules

## Repo layout

- `mobile/app` — Flutter app shell
- `packages/core` — shared models, storage ports, entitlements, and common runtime contracts
- `features/prayer` — prayer calculations, notification planning, fiqh prayer settings
- `features/qibla` — qibla math and presentation models
- `features/quran` — bundled Quran Arabic plus translation sync/cache logic
- `features/hadith` — Sunni Hadith Finder, pack ingestion, and local search
- `features/fiqh` — fiqh guide and bundled reference content
- `features/scholar_feed` — optional public-source feed metadata
- `features/ai_assistant` — optional BYOK assistant
- `features/subscriptions` — local preview billing and RevenueCat integration
- `services/content-pack-worker` — optional Cloudflare Worker for remote hadith pack manifests and signed downloads
- `website` — GitHub Pages trust site

## Current engineering posture

- Android support floor: API 24 / Android 7+
- Supported runtime UI languages: English, Arabic, Urdu
- Free-core bootstrap is intended to stay backend-optional
- Billing is lazy-loaded only when a user opens Plans & Unlocks, restore purchases, or a paid-gated optional module
- No analytics or telemetry SDK is active in the current build

## Key docs

- [Privacy model](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/privacy_model.md)
- [Security model](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/security_model.md)
- [Release readiness](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/release_readiness.md)
- [Readiness audit](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/readiness_audit.md)
- [Launch blockers](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/launch_blockers.md)
- [Public trust gaps](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/public_trust_gaps.md)
- [Developer guide](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/developer_guide.md)
- [Manual QA checklist](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/manual_qa_checklist.md)
- [Atlas readiness checks](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/atlas_readiness_checks.md)

## Local commands

```bash
make bootstrap
make analyze
make test
make worker-test
make secret-scan
make size-report
make site-preview
```

## Public trust site

The repository includes a tracked static trust site in `website/` for GitHub Pages. It is meant to be evidence-driven rather than marketing-driven and links directly to the repo docs that back up public claims.
