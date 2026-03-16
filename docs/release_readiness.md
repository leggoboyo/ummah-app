# Release Readiness

## Build Flavors

- `dev`
  - local preview billing enabled
  - hosted AI disabled
  - intended for day-to-day engineering work
- `staging`
  - local preview billing enabled
  - hosted AI disabled
  - intended for CI and internal QA
- `prod`
  - RevenueCat billing path selected
  - hosted AI disabled until backend work exists
  - remote Hadith pack delivery points at the live Worker URL in `apiBaseUrl`
  - intended for store-ready builds after final human-gated release work

Environment files live in:

- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/dev.json`
- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/staging.json`
- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/prod.json`

## Current Release Position

- The repository is public and the trust site is live on GitHub Pages.
- `main` is protected by PR requirements, one approval, and passing required checks.
- The free core is offline-first and billing is lazy-loaded.
- The app includes privacy, sources, and diagnostics surfaces.
- Android size reporting now tracks AAB, fat APK, and split APKs for older-phone coverage.
- Hadith language packs use the remote delivery path and no longer need to ship inside the base mobile bundle.
- `apiBaseUrl` points to the live Worker URL in all three environment JSON files.

## Verified External State

The following external truths have now been manually verified:

- Cloudflare:
  - Worker `ummah-content-pack-worker` is live
  - expected R2 and KV bindings are present
  - both required Worker secrets are present:
    - `DOWNLOAD_SIGNING_SECRET`
    - `REVENUECAT_API_KEY`
- RevenueCat:
  - project exists for Ummah
  - Android app/offering/entitlement posture exists
  - server-side secret API key path now exists for Worker checks
- Google Play:
  - internal testing is active
  - active version is `0.4.1` / code `7`
- GitHub:
  - repo is public
  - Pages is live
  - `main` branch protection and required checks are active

## Remaining Human-Gated Work

- one physical lower-end Android signoff before stronger broader-beta claims
- Apple signing, TestFlight/App Store Connect, screenshots, and listing assets
- RevenueCat iOS app configuration if iOS paid modules are expected soon

## Recommended Order

1. Complete one physical lower-end Android pass using `docs/manual_qa_checklist.md`.
2. Record signoff in `docs/beta_launch_checklist.md`.
3. Keep trust-site and README wording aligned with the current verified truth.
4. Finish final iOS signing and store-surface work if iOS beta is still planned.
5. Do one last release-candidate pass before broader external beta.

## Current local verification snapshot

- `flutter analyze` passes
- `flutter test` passes
- Worker tests pass
- secret scan passes
- Android split APKs and AAB build successfully
- iOS no-codesign archive builds successfully
- Android smoke passes on both the modern emulator and the API 24 emulator
- GitHub Pages trust site is live at `https://leggoboyo.github.io/ummah-app/`
