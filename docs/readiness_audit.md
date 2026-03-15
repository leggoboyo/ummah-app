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

This is a findings-first audit. If a claim could not be proven from code, tests, local builds, or a manual console check, it is treated as unproven.

## Verification performed

Commands run during the audit and remediation wave:

- `dart run melos exec -c 1 -- flutter analyze`
- `dart run melos exec -c 1 --dir-exists=test -- flutter test`
- `cd services/content-pack-worker && node --test`
- `make secret-scan`
- `flutter build apk --debug --dart-define-from-file=env/dev.json`
- `flutter build apk --release --dart-define-from-file=env/prod.json`
- `flutter build apk --release --split-per-abi --dart-define-from-file=env/prod.json`
- `flutter build appbundle --release --dart-define-from-file=env/prod.json`
- `./scripts/report_build_sizes.sh`
- `flutter build ipa --no-codesign --dart-define-from-file=env/prod.json`
- local trust-site preview via `curl http://127.0.0.1:4173`

## Findings

### High

#### 1. Manual dashboard truth still remains the main launch-risk gap

The repo now proves much more than it did before this remediation wave, but public launch confidence still depends on systems outside the repository:

- Cloudflare Worker bindings and secrets
- Google Play internal-track artifact truth and Data Safety posture
- GitHub Pages / branch-protection / required-check truth
- RevenueCat product and entitlement truth if paid-pack activation is expected soon

Impact:

- the code can now credibly support public claims
- the remaining risk is operational drift between code assumptions and live dashboards

Call:

- not a repo-code failure
- still a real launch blocker until the Atlas checks in `docs/atlas_readiness_checks.md` are run

### Medium

#### 2. Older-phone readiness is materially stronger, but still under-proven without a physical device

The repo now has:

- Android 7+ / API 24 build support
- `armeabi-v7a` and `arm64-v8a` split APK reporting
- lean UI mode for lower-end devices
- lazy billing bootstrap
- lazy Quran initialization
- reduced timer-driven whole-shell rebuild pressure

Impact:

- the engineering posture is much stronger for lower-end Android devices
- the remaining uncertainty is real-device behavior: compass, alarms, and responsiveness on genuine low-end hardware

Call:

- safe for continued emulator-based Android internal testing
- not yet fully proven for strong “works seamlessly on older phones” public claims

#### 3. iOS is structurally healthier, but still needs human distribution truth

The iOS repo-side blockers were resolved:

- placeholder icon and launch assets were replaced
- always-and-when-in-use location scope was removed
- no-codesign archive builds successfully

Impact:

- the codebase is no longer blocked by the earlier iOS asset/privacy issues
- real distribution still depends on signing, screenshots, listing assets, and store-console truth

Call:

- repo-side iOS blocker resolved
- human publishing truth still required before launch-facing claims

### Low

#### 4. Android smoke tooling is ready, but `adb` was not discoverable in the current shell environment

The repo now contains a reusable smoke script in `scripts/android_smoke_test.sh` and a low-end emulator helper in `scripts/create_low_end_android_avd.sh`. In this shell session, `adb` could not be located under the expected SDK paths, so the script could not be rerun from the terminal even though emulator-driven validation had already been performed earlier in the project.

Impact:

- this is an environment/tooling visibility issue, not a product-code flaw
- the runbook is still useful, but the local machine should expose Android platform-tools consistently

Call:

- low-severity local tooling issue
- does not block code readiness, but should be cleaned up for repeatable founder QA

## Positive controls

The strongest current controls are:

- full workspace analysis passes
- full workspace tests pass
- Worker tests pass
- Android debug, release, split APK, and AAB builds all pass locally
- iOS no-codesign archive builds successfully after the asset refresh
- the Android app still supports API 24 and split APK coverage for older phones
- free-core bootstrap now keeps RevenueCat off the launch path
- the app user identifier now migrates into secure storage
- BYOK secrets remain in secure storage
- the privacy screen now accurately describes optional billing/network behavior
- source verification URLs are tappable in the app where URLs exist
- a tracked GitHub Pages trust site now exists in `website/`
- repo hygiene workflows now cover workflow linting and secret scanning

## Repo health scorecard

| Area | Status | Notes |
| --- | --- | --- |
| Build reproducibility | Green | Android debug/release/split APK/AAB and iOS no-codesign archive all build locally. |
| Test reliability | Green | `flutter analyze`, `flutter test`, and Worker tests passed. |
| CI confidence | Green/Yellow | Core CI is now stronger with workflow linting, secret scanning, and broader Android artifact tracking; live GitHub required-check truth is still external. |
| Release artifact readiness | Yellow | Android is repo-verified and test-ready; iOS repo blockers are fixed, but store/signing truth is still human-gated. |
| Documentation freshness | Green/Yellow | Core docs are now much closer to repo truth; final public trust wording still depends on Atlas console verification. |

## Runtime reliability matrix

| Surface | Current repo-backed status | Evidence basis | Remaining gap |
| --- | --- | --- | --- |
| Free-core launch without billing init | Pass | `AppController` bootstrap refactor + tests | none repo-side |
| Onboarding entry after fresh install | Pass | local validation + existing test coverage | full branch-by-branch device walkthrough still useful |
| Quran Arabic offline | Pass | workspace tests + lazy-load cleanup | more manual device QA always useful |
| Manual location and prayer setup | Pass | existing tests + privacy/runtime docs alignment | more real-device GPS choice QA useful |
| Unsupported locale fallback to English | Pass | app locale normalization in `UmmahApp` | wider widget-level locale coverage still possible later |
| EN/AR/UR runtime contract | Pass | app language layer + current supported locales | not every screen has dedicated RTL regression tests |
| Lower-end Android posture | Partial pass | lean mode + split APKs + API 24 support | still needs one physical-device pass |
| Hadith source labeling and verification | Pass | human-readable source cleanup + tappable links | source metadata quality still depends on upstream records in some cases |

## Release and distribution posture

Current local build truth:

- Android minimum SDK remains API 24
- the app still builds split APKs for `armeabi-v7a` and `arm64-v8a`
- latest local AAB measured during this wave: about `51.07 MB`
- latest local fat release APK measured during this wave: about `61.29 MB`
- latest local `armeabi-v7a` split APK: about `20.63 MB`
- latest local `arm64-v8a` split APK: about `22.82 MB`

Surface-level release call:

- Android internal testing: safe to continue
- Android broader external beta: reasonable after manual dashboard truth checks and at least one physical-device pass
- iOS beta / store readiness: repo-side blockers resolved, but final publishing remains human-gated
- Free core privacy/offline claims: now materially stronger and code-backed
- Remote Hadith starter-pack flow: safe to keep testing
- Remote paid-pack flow: do not call fully live until Cloudflare and RevenueCat dashboard truth is confirmed

## Threat-summary appendix

The most important realistic abuse/failure paths now are:

1. Dashboard drift between repo assumptions and live Cloudflare / Play / RevenueCat / GitHub state.
2. Signed download URLs remain bearer-style tokens even with short-lived signing and `no-store`; leakage still matters until expiry.
3. Starter-pack daily budgeting is best-effort under KV concurrency and should not be treated as strict abuse prevention.
4. Lower-end Android regressions can still appear on real hardware even when emulator/API 24 coverage is clean.

## Overall call

This repo is now in materially better shape than the earlier audit snapshot:

- safe for continued Android internal testing
- structurally stronger for privacy/offline claims
- materially stronger for older-phone readiness
- materially stronger for public trust and proof surfaces

The remaining launch risk is now less about code quality and more about:

- external dashboard truth
- real-device validation
- final publishing and store-surface alignment
