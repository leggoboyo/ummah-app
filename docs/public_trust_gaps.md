# Public Trust Gaps

Date: 2026-03-15

This document tracks the difference between what an external reviewer could verify from the repo today and what still depends on manual dashboard or real-device confirmation.

## Claims that are now strong and credible

### Free-core launch posture

These claims are now backed by repo reality:

- the free-core launch path keeps billing lazy
- prayer, qibla, Hijri, and Quran Arabic remain local-first surfaces
- no analytics SDK is active in the current build
- optional Cloudflare/RevenueCat infrastructure remains outside the free-core bootstrap path

Why these are credible:

- `mobile/app/lib/src/bootstrap/app_controller.dart` now keeps billing off `initialize()`
- secure app-user-ID creation happens only when optional billing/pack flows need it
- workspace analysis and tests pass
- Android and iOS builds complete locally
- the privacy model and in-app privacy copy now match the code more closely

### Public proof surface

These claims are now backed by repo reality:

- the repo contains a tracked static trust site in `website/`
- the site is designed to link back to repo-backed docs rather than make free-floating claims
- the app-side Sources & Versions screen now exposes tappable verification links where URLs exist

## Claims that still require careful wording

### 1. “Launch-ready” across every public surface

Why it still needs care:

- the repo-side fixes are in place
- final launch confidence still depends on Cloudflare, Google Play, GitHub Pages, and possibly RevenueCat dashboard truth

Correction:

- say the app is repo-verified and local-build-verified
- do not say all live operational surfaces are confirmed until the Atlas checks return evidence

### 2. “Seamless older-phone support internationally”

Why it still needs care:

- the repo now has lean mode, split APK reporting, API 24 smoke tooling, and lazy startup improvements
- that is strong engineering evidence, but not the same as real device validation across the lowest-end Android hardware

Correction:

- say the app is explicitly optimized for Android 7+ and lower-end devices
- avoid claiming it is fully proven on real older hardware until a physical-device pass is done

## Claims that are now resolved

These previously overstated claims are no longer mismatched in repo code:

- “no hidden backend dependency on app launch”
- “location permission is only when needed” for iOS scope
- “the repo has no public trust site”

## Claims that remain under-proven

### Dashboard and store-console state

Current proof:

- repo env files, workflows, and docs describe the intended live posture

Gap:

- only the real consoles can prove secrets, bindings, tester access, Pages configuration, and Data Safety/store truth

### Full EN/AR/UR UX matrix

Current proof:

- runtime language contract is `en`, `ar`, and `ur`
- unsupported locale fallback resolves to English
- core code and tests back the language-selection contract

Gap:

- not every screen has dedicated RTL/LTR regression coverage yet

### Real-device lower-end Android behavior

Current proof:

- split APK coverage exists
- API 24 emulator smoke tooling exists
- build-size reporting now includes `armeabi-v7a` and `arm64-v8a`

Gap:

- still needs at least one real low-end Android validation pass

## Public-facing proof artifacts recommended next

The highest-value external proof set now is:

1. publish the GitHub Pages trust site
2. run the Atlas checks in `docs/atlas_readiness_checks.md`
3. update trust-site / README wording from the returned console truth
4. keep `docs/readiness_audit.md`, `docs/launch_blockers.md`, and `docs/release_readiness.md` as the internal proof spine

## Current narrative call

The project can now credibly present itself as:

- a serious privacy-first, offline-first Islamic app with repo-backed proof surfaces
- engineered to keep the free core local-first and optional cloud boundaries visible
- ready for continued Android internal testing and broader trust-surface review

It should still avoid presenting itself as:

- fully dashboard-verified across Cloudflare, Play Console, GitHub Pages, and RevenueCat before those checks are run
- fully proven on real low-end Android hardware worldwide without a physical-device pass
