# Ummah App

Ummah App is a public, privacy-first, offline-first Flutter application for iOS
and Android. The project is being built around a narrow promise: keep the free
worship core useful without an app account, without analytics by default, and
without turning the app into a backend-heavy product.

Public trust site:

- https://leggoboyo.github.io/ummah-app/

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

- `mobile/app` - Flutter app shell
- `packages/core` - shared models, storage ports, entitlements, and common runtime contracts
- `features/prayer` - prayer calculations, notification planning, fiqh prayer settings
- `features/qibla` - qibla math and presentation models
- `features/quran` - bundled Quran Arabic plus translation sync/cache logic
- `features/hadith` - Sunni Hadith Finder, pack ingestion, and local search
- `features/fiqh` - fiqh guide and bundled reference content
- `features/scholar_feed` - optional public-source feed metadata
- `features/ai_assistant` - optional BYOK assistant
- `features/subscriptions` - local preview billing and RevenueCat integration
- `services/content-pack-worker` - optional Cloudflare Worker for remote hadith pack manifests and signed downloads
- `website` - GitHub Pages trust site

## Current engineering posture

- Android support floor: API 24 / Android 7+
- Supported runtime UI languages: English, Arabic, Urdu
- Free-core bootstrap stays backend-optional
- Billing is lazy-loaded only when a user opens Plans & Unlocks, restore purchases, or a paid-gated optional module
- No analytics or telemetry SDK is active in the current build
- The repository is public, `main` is protected, and required CI checks are enforced

## Verified external state

As of 2026-03-15:

- GitHub repository is public and the trust site is live on GitHub Pages
- Cloudflare Worker, R2, and KV bindings were manually verified
- Cloudflare Worker now has both expected secrets:
  - `DOWNLOAD_SIGNING_SECRET`
  - `REVENUECAT_API_KEY`
- RevenueCat has a server-side secret API key configured for the Worker path
- Google Play internal testing is active on version `0.4.1` / code `7`

Remaining human-gated work:

- one physical lower-end Android validation pass before stronger broader-beta claims
- final iOS signing, TestFlight/App Store Connect, and listing/screenshot work

## Key docs

- [Trust site](https://leggoboyo.github.io/ummah-app/)
- [Privacy model](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/privacy_model.md)
- [Security model](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/security_model.md)
- [Release readiness](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/release_readiness.md)
- [Readiness audit](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/readiness_audit.md)
- [Launch blockers](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/launch_blockers.md)
- [Public trust gaps](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/public_trust_gaps.md)
- [Beta launch checklist](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/beta_launch_checklist.md)
- [Tester instructions](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/tester_instructions.md)
- [Manual QA checklist](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/manual_qa_checklist.md)
- [Atlas readiness checks](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/atlas_readiness_checks.md)
- [Developer guide](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/developer_guide.md)
- [Contributing](/Users/zohaibkhawaja/Documents/Codex/ummah-app/CONTRIBUTING.md)
- [Security policy](/Users/zohaibkhawaja/Documents/Codex/ummah-app/SECURITY.md)

## Local commands

```bash
make bootstrap
make analyze
make test
make worker-test
make secret-scan
make size-report
make android-smoke
make site-preview
```

## Public trust surface

The repository includes a tracked static trust site in `website/` and deploys
it with GitHub Pages. The site is intentionally evidence-driven rather than
marketing-driven and links directly to repo docs that back up public claims.
