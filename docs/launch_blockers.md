# Launch Blockers

Date: 2026-03-15

This file only lists items that should still block broader external testing or
launch-facing claims after the public-repo remediation wave.

## Current blockers

### 1. One physical lower-end Android pass is still required before broader Android beta claims

Why it blocks:

- emulator smoke now passes on both a modern emulator and the API 24 emulator
- split APKs and lean mode exist for older Android devices
- that is strong engineering evidence, but it is not the same as a real low-end
  phone under real memory pressure, alarm behavior, and sensor conditions

Blocks:

- strong public claims about seamless older-phone behavior
- calling the Android broader beta fully ready without a real-device signoff

Evidence:

- `docs/manual_qa_checklist.md`
- `docs/beta_launch_checklist.md`
- `scripts/android_smoke_test.sh`

### 2. iOS publishing and store-surface truth is still human-gated

Why it blocks:

- the repo-side iOS blockers were fixed
- real iOS beta or store claims still depend on signing, App Store Connect /
  TestFlight setup, screenshots, listing assets, and final human review

Blocks:

- iOS public-beta claims
- iOS launch-facing claims beyond local build readiness

Evidence:

- `docs/release_readiness.md`
- `docs/readiness_audit.md`

## No longer blockers

These were previously open and are now verified:

- repo visibility and public trust-site publication
- GitHub Pages live status
- `main` branch protection and required checks
- Cloudflare Worker bindings and required secrets
- RevenueCat server-side secret path for Worker entitlement checks
- Google Play internal-testing health on `0.4.1 (7)`
- free-core bootstrap keeping billing off the launch path

## Non-blocking but still important

- keep the trust site and docs aligned with future code changes
- do not publish the internal Play testing link in public surfaces
- configure RevenueCat iOS app state before claiming iOS paid-module readiness
