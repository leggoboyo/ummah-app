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
  - intended for store-ready builds after credentials are wired

Environment files live in:

- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/dev.json`
- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/staging.json`
- `/Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/env/prod.json`

## Current Release Position

- Core free experience is offline-first and ad-free.
- Premium modules are gated locally and safe to demo in preview billing mode.
- The app now includes dedicated privacy, sources, and diagnostics surfaces.
- CI builds staging app artifacts, not dev artifacts.
- Atlas prompts for external account setup are ready in `/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/atlas_runbooks.md`.

## Remaining Human-Gated Work

- App Store Connect API key creation for RevenueCat
- Google Play service-account JSON for RevenueCat
- Store product creation and pricing
- Final store listing assets and screenshots
- Apple/Google signing and publishing credentials

## Recommended Order

1. Finish internal alpha device QA using the checklist in `/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/manual_qa_checklist.md`.
2. Run the Atlas prompts for Apple and Google billing credentials.
3. Let Codex wire the live RevenueCat keys and validate entitlement flows.
4. Prepare store screenshots and privacy copy.
5. Do a final staging pass before the first external beta.
