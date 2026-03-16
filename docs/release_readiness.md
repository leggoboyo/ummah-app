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
  - intended for store-ready builds after the remaining dashboard truth checks are complete

Environment files live in:

- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/dev.json`
- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/staging.json`
- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/prod.json`

## Current Release Position

- Core free experience is offline-first and ad-free.
- Billing is lazy-loaded and should not be part of the free-core launch path.
- The app includes privacy, sources, and diagnostics surfaces.
- CI builds staging artifacts and tracks Android size outputs for AAB + release APKs.
- Hadith language packs use the remote pack delivery path and no longer need to ship inside the base mobile bundle.
- The public trust site now lives in `website/` and is intended for GitHub Pages deployment.
- `apiBaseUrl` already points to the live Worker URL in all three environment JSON files.

## Remaining Human-Gated Work

- Cloudflare truth check:
  - confirm Worker secrets and bindings are present in the live account
  - confirm there are no unintended billable products/settings enabled
- RevenueCat truth check:
  - confirm product and entitlement dashboard state matches the repo assumptions
- Google Play truth check:
  - confirm internal-testing artifact/version, tester access, and Data Safety posture
- GitHub truth check:
  - confirm Pages config and branch-protection / required-check posture
- Apple / Google signing and publishing credentials
- Final store listing assets and screenshots

## Recommended Order

1. Finish internal device QA using `/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/manual_qa_checklist.md`.
2. Run the narrow Atlas checks in `/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/atlas_readiness_checks.md`.
3. Confirm Cloudflare Worker secret truth before enabling paid extra-language hadith packs publicly.
4. Confirm Google Play internal-testing truth and Data Safety truth.
5. Confirm GitHub Pages / branch-protection truth.
6. Prepare final store screenshots and listing copy.
7. Do one final staging pass before the first broader beta.

## Current local verification snapshot

- `flutter analyze` passes
- `flutter test` passes
- Worker tests pass
- Android debug, release, split APK, and AAB builds pass locally
- iOS no-codesign archive builds successfully after the latest asset refresh, with the earlier placeholder-asset warnings removed
