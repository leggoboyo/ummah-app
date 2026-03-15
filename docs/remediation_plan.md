# Remediation Plan

Date: 2026-03-15

This document now tracks the remaining post-remediation follow-up, not the fixes that were already completed in the current wave.

## Completed in this remediation wave

- free-core bootstrap no longer initializes RevenueCat by default
- billing and app-user-ID creation now load lazily on demand
- the app user identifier migrates from shared preferences into secure storage
- the home shell no longer eagerly initializes Quran on startup
- whole-shell timer-driven rebuild pressure was reduced by isolating live-clock updates
- Worker signed download responses now use `Cache-Control: no-store`
- iOS placeholder icon and launch assets were replaced with sober interim branded assets
- iOS always-and-when-in-use location permission copy was removed
- build-size reporting now includes AAB, fat APK, and split APKs
- repo hygiene workflows now cover workflow linting and tracked-secret scanning
- the repo now includes a tracked GitHub Pages trust site

## Remaining follow-up sequence

### Phase 1: Verify live dashboards and store truth

Goals:

- confirm the real operational state matches the repo-backed assumptions
- remove the last major trust gap between local proof and live-system truth

Actions:

- run the Atlas prompts in `docs/atlas_readiness_checks.md`
- confirm Cloudflare bindings, secrets, and no unexpected billable products
- confirm Google Play internal-test and Data Safety truth
- confirm GitHub Pages and branch-protection truth
- confirm RevenueCat only if paid-pack activation is expected soon

Success condition:

- the repo docs and public trust site can cite real dashboard truth instead of assumptions

### Phase 2: Real-device lower-end Android validation

Goals:

- prove the new lean-mode and lazy-startup posture on real hardware
- validate compass, alarms, and general responsiveness outside the emulator

Actions:

- use `scripts/android_smoke_test.sh` plus the manual QA checklist on at least one older Android phone
- record any memory, jank, or alarm-delivery issues

Success condition:

- older-phone readiness claims are backed by at least one physical-device pass

### Phase 3: Public-proof tightening

Goals:

- ensure the public trust site and README only state what is currently proven
- keep the trust surface aligned as the product changes

Actions:

- publish the GitHub Pages site
- update any public copy after Atlas verification returns
- keep source/version links and repo-backed evidence pages current

Success condition:

- an external reviewer can verify the project’s mission, sourcing, privacy posture, and optional-cloud boundary without reading deep implementation code

## Priority summary

Highest priority:

- Atlas verification of Cloudflare / Play / GitHub / RevenueCat truth
- one real lower-end Android device pass

Next priority:

- publish the Pages trust site
- tighten any trust-site copy once live-console truth is known

Then:

- continue iterative UX polish and device QA
