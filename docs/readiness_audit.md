# Readiness Audit

Date: 2026-03-15

## Scope

This audit covers:

- Flutter workspace health and build integrity
- mobile runtime safety for the free core and optional features
- privacy, security, and secret-handling posture
- Cloudflare Worker trust boundaries
- release, distribution, and CI coverage
- public-trust and licensing-facing repo surfaces

This is a findings-first audit. If a claim could not be proven from code, tests,
local builds, or manual console verification, it is treated as unproven.

## Verification performed

Commands run on merged `main` during the post-public refresh:

- `dart run melos exec -c 1 -- flutter analyze`
- `dart run melos exec -c 1 --dir-exists=test -- flutter test`
- `cd services/content-pack-worker && node --test`
- `make secret-scan`
- `flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json`
- `flutter build appbundle --release --dart-define-from-file=env/prod.json`
- `./scripts/report_build_sizes.sh`
- `flutter build ipa --no-codesign --dart-define-from-file=env/prod.json`
- `ADB_SERIAL=emulator-5554 APK_PATH=... ./scripts/android_smoke_test.sh`
- `ADB_SERIAL=emulator-5556 APK_PATH=... ./scripts/android_smoke_test.sh`
- `curl -I https://leggoboyo.github.io/ummah-app/`

Manual console verification already completed for:

- Cloudflare Worker, R2, KV, and secrets
- RevenueCat server-side secret-key path
- Google Play internal testing truth
- GitHub public-repo state, required checks, branch protection, and Pages

## Findings

### Medium

#### 1. One physical lower-end Android pass is still required before broader Android beta claims

What is already true:

- API 24 / Android 7+ remains the Android floor
- lean mode exists for older/lower-memory Android devices
- `armeabi-v7a` and `arm64-v8a` split APKs are built and tracked
- offline smoke now passes on both the modern emulator and the API 24 emulator

What is still missing:

- one real physical lower-end Android device signoff covering responsiveness,
  alarm behavior, airplane-mode flows, and Hadith source-link quality

Call:

- Android internal testing is healthy
- Android broader beta should wait for one physical low-end signoff

#### 2. iOS is code-healthy but still not ready for public-beta claims

What is already true:

- `flutter build ipa --no-codesign` passes
- placeholder icon and launch-image warnings were resolved
- the broader iOS location permission string was removed

What is still missing:

- signing and App Store Connect / TestFlight truth
- final distribution assets and listing surfaces

Call:

- iOS is no longer blocked by repo-side launch hygiene
- iOS should remain a secondary track until human distribution work is done

### Low

#### 3. RevenueCat remains Android-first in practice

What is already true:

- the server-side RevenueCat key path exists
- Cloudflare now holds `REVENUECAT_API_KEY`
- Android entitlements and offerings are configured

What is still incomplete:

- RevenueCat iOS app configuration is not present yet

Call:

- not a blocker for Android broader beta
- avoid implying the iOS paid-module path is already fully live

## Positive controls

The strongest current controls are:

- full workspace analysis passes
- full workspace tests pass
- Worker tests pass
- Android release, split APK, and AAB builds all pass locally
- iOS no-codesign archive builds successfully
- Android smoke passes on both a modern emulator and an API 24 emulator
- free-core bootstrap keeps billing off the launch path
- the app user identifier migrates into secure storage
- BYOK secrets remain in secure storage
- source verification links are tappable in the app where URLs exist
- the repo is public and `main` is protected by required checks and approvals
- the GitHub Pages trust site is live
- Cloudflare Worker bindings/secrets were manually verified
- RevenueCat server-side secret path was manually verified
- Google Play internal testing was manually verified

## Repo health scorecard

| Area | Status | Notes |
| --- | --- | --- |
| Build reproducibility | Green | Android release/split APK/AAB and iOS no-codesign archive all build locally. |
| Test reliability | Green | `flutter analyze`, `flutter test`, Worker tests, and emulator smoke all passed. |
| CI confidence | Green | Required checks are configured on `main` and the merged launch-readiness PR passed them. |
| Release artifact readiness | Green/Yellow | Android is strong for broader beta after one physical-device pass; iOS is still human-gated. |
| Documentation freshness | Green | Public docs and trust surfaces were refreshed after the repo went public and external checks completed. |

## Runtime reliability matrix

| Surface | Current status | Evidence basis | Remaining gap |
| --- | --- | --- | --- |
| Free-core launch without billing init | Pass | bootstrap refactor + tests | none repo-side |
| Onboarding after fresh install | Pass | emulator smoke + test coverage | physical-device pass still valuable |
| Quran Arabic offline | Pass | tests + smoke + lazy-load cleanup | more real-device QA always useful |
| Manual location and prayer setup | Pass | tests + privacy/runtime alignment | physical-device GPS choice QA still useful |
| Unsupported locale fallback to English | Pass | locale normalization in app shell | no current blocker |
| EN/AR/UR runtime contract | Pass | supported locale contract + tests | more screen-specific RTL tests would be a future improvement |
| Lower-end Android posture | Partial pass | lean mode + split APKs + API 24 smoke | one physical low-end phone still required |
| Hadith source labeling and verification | Pass | source-label cleanup + tappable links | upstream metadata quality can still vary |

## Release and distribution posture

Current local build truth:

- Android minimum SDK remains API 24
- the app builds split APKs for `armeabi-v7a` and `arm64-v8a`
- latest local AAB: about `51.07 MB`
- latest local fat release APK: about `61.29 MB`
- latest local `armeabi-v7a` split APK: about `20.63 MB`
- latest local `arm64-v8a` split APK: about `22.82 MB`

Current externally verified truth:

- GitHub repository is public
- GitHub Pages is live at `https://leggoboyo.github.io/ummah-app/`
- `main` requires PRs, one approval, and passing checks
- Google Play internal testing is active on `0.4.1 (7)`
- Cloudflare Worker secrets and bindings are present
- RevenueCat server-side secret path exists for Worker checks

Surface-level release call:

- Android internal testing: healthy
- Android broader external beta: reasonable after one physical low-end device pass
- iOS beta / store readiness: repo-side blockers resolved, publishing still human-gated
- free-core privacy/offline claims: strong and code-backed
- optional-cloud claims: verified and ready for careful public wording

## Threat-summary appendix

The most important realistic abuse or failure paths now are:

1. signed download URLs are still bearer-style tokens until expiry, even with short lifetimes and `no-store`
2. starter-pack daily budgeting is best-effort under KV concurrency and should not be treated as strict abuse prevention
3. a real low-end Android device could still expose responsiveness or alarm issues not seen on emulators
4. iOS store/distribution misconfiguration could still contradict repo truth if handled carelessly later

## Overall call

This codebase is now in a materially stronger state than the earlier private-repo
snapshot:

- the public proof story is real, not aspirational
- CI and branch protection are active
- the free-core launch posture is cleaner and more defensible
- optional-cloud boundaries are visible and verified

The main remaining risk is not hidden repo drift. It is the final operational
mile:

- one physical low-end Android pass
- final iOS publishing/signing truth
