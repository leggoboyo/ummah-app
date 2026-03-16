# Launch Blockers

Date: 2026-03-15

This file only lists items that should block broader external testing or launch-facing claims after the current remediation wave.

## Current blockers

### 1. External dashboard truth is still unverified

Why it blocks:

- the repo now proves the code-side launch posture more cleanly
- public launch claims still depend on external systems the repo cannot inspect directly
- those systems must be checked before broader public claims or paid-pack activation claims

Manual truth still required for:

- Cloudflare Worker bindings and secrets
- Google Play internal-track artifact truth and Data Safety posture
- GitHub Pages / branch-protection / required-check truth
- RevenueCat entitlement/product truth if paid-pack activation is expected soon

Evidence:

- `docs/atlas_readiness_checks.md`
- `docs/release_readiness.md`

Blocks:

- broader external launch claims
- confident statements that paid remote-pack infrastructure is fully live
- final trust-site and store-listing claims

### 2. Real-device validation is still needed before strong “older-phone ready” claims

Why it blocks:

- the repo now has API 24 build coverage, lean-mode support, split APK reporting, and emulator smoke tooling
- emulator coverage is not a full substitute for real low-end Android hardware
- the remaining uncertainty is around true device-level behavior: compass, alarms, memory pressure, and general responsiveness

Evidence:

- `docs/manual_qa_checklist.md`
- `scripts/android_smoke_test.sh`
- `scripts/report_build_sizes.sh`

Blocks:

- strong public claims about seamless older-phone behavior internationally
- any claim that exact low-end Android behavior is fully proven

## No longer repo-side blockers

These were addressed in the remediation wave and should no longer be treated as open blockers:

- RevenueCat is no longer initialized during free-core bootstrap
- the iOS placeholder app icon and launch assets were replaced
- the iOS always-and-when-in-use location permission string was removed
- the app user identifier now migrates into secure storage
- signed Worker download responses now use `Cache-Control: no-store`

## Non-blocking but still important

- publish the GitHub Pages trust site and verify the live URL
- finish store-signing, listing, and screenshot work
- keep the trust-site copy aligned with future code changes
