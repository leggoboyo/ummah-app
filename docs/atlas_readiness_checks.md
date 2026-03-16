# Atlas Readiness Checks

Date: 2026-03-15

Use these prompts in Atlas agentic mode. Each prompt is narrow, evidence-returning, and should stop only for required login, 2FA, or unavoidable approval.

## Current verification snapshot

These checks were already completed successfully on 2026-03-15:

- Cloudflare Worker, R2, KV, and both required secrets were verified
- RevenueCat server-side secret path was created and verified
- Google Play internal testing was verified on `0.4.1 (7)`
- GitHub repo visibility, branch protection, required checks, and Pages were verified

Use the prompts below as rerun checklists when dashboard state changes or before a
future launch milestone.

## 1. Cloudflare readiness check

```text
Audit the live Cloudflare configuration for Ummah App’s optional Hadith-pack infrastructure and return evidence, not guesses.

Context:
- Repo path:
  /Users/zohaibkhawaja/Documents/Codex/ummah-app
- Worker project path:
  /Users/zohaibkhawaja/Documents/Codex/ummah-app/services/content-pack-worker
- Expected Worker URL in app env files:
  https://ummah-content-pack-worker.zkhawaja721.workers.dev
- Expected products:
  - one Worker for remote pack access
  - one R2 bucket for pack objects
  - one KV namespace for starter-pack claims
- Secret names expected by code:
  - DOWNLOAD_SIGNING_SECRET
  - REVENUECAT_API_KEY

Your job:
1. Open Cloudflare and confirm which account is authenticated.
2. Open the Worker used for Ummah App and confirm:
   - Worker name
   - current deployment state
   - current worker.dev URL
3. Verify the Worker has the expected bindings:
   - PACKS_BUCKET
   - STARTER_CLAIMS
4. Verify the Worker secrets exist by name:
   - DOWNLOAD_SIGNING_SECRET
   - REVENUECAT_API_KEY
5. Confirm whether any unexpected billable Cloudflare products are enabled for this project beyond Worker, R2, and KV.
6. If possible, inspect the R2 bucket and confirm the manifest/object layout exists for the pack flow.
7. Return a clean summary containing:
   - account name
   - Worker name
   - deployed URL
   - bucket name
   - KV namespace name/id
   - whether each expected secret exists
   - whether any unexpected billable product/settings were found
   - anything blocked or missing
8. Stop only for required login, 2FA, or an unavoidable account confirmation.

Preferred behavior:
- Be autonomous
- Do not reveal secret values
- Focus on configuration truth, not deployment changes
```

## 2. Google Play internal-testing and Data Safety check

```text
Audit the Google Play Console state for Ummah App and return the current truth for internal testing and store-facing safety disclosures.

Context:
- App name: Ummah App
- Android package: com.zokorp.ummah
- Developer account: ZoKorp Games
- This repo’s current app version is 0.4.1+7
- Latest known local AAB path:
  /Users/zohaibkhawaja/Documents/Codex/ummah-app/mobile/app/build/app/outputs/bundle/release/app-release.aab

Your job:
1. Open Google Play Console for Ummah App.
2. Go to Testing > Internal testing and verify:
   - whether the track is active
   - which version code/version name is currently active
   - whether testers remain configured
   - whether there are any review or rollout warnings
3. Verify the current tester access flow:
   - tester group/list status
   - test link truth
4. Review the app’s Data Safety / privacy disclosure area if available and compare it at a high level to the app’s current posture:
   - no analytics SDK
   - optional billing
   - optional remote content packs
   - location only when chosen
5. Return a clean summary containing:
   - current active internal-test version
   - whether the track is healthy
   - whether tester access looks healthy
   - current tester link
   - whether the Data Safety posture appears aligned or mismatched
   - anything blocked
6. Stop only for required login, 2FA, or unavoidable Play Console confirmation.

Preferred behavior:
- Be autonomous
- Do not create a new release unless explicitly necessary
- Report current truth first
```

## 3. GitHub readiness check

```text
Audit GitHub configuration for Ummah App and return the current readiness truth for branch protection, required checks, and any public-site posture.

Context:
- Repository:
  https://github.com/leggoboyo/ummah-app
- Base branch:
  main
- The repo currently has CI workflows for Mobile CI, Build Size Report, and Dependency Audit
- The local repo now contains a tracked static site in `website/` plus a Pages workflow at `.github/workflows/public_site.yml`

Your job:
1. Open the GitHub repository settings and inspect branch protection for `main`.
2. Confirm:
   - whether branch protection is enabled
   - whether required status checks are configured
   - whether direct pushes are restricted
   - whether review requirements are enabled
3. Check Actions and confirm whether the main workflows currently exist and are healthy:
   - Mobile CI
   - Build Size Report
   - Dependency Audit
4. Check whether GitHub Pages is configured for this repo.
5. If Pages is configured, report:
   - source branch/folder
   - whether the Pages workflow appears to be the active publication path
   - current public URL
   - whether it appears live
6. If Pages is not configured, report that clearly instead of trying to create it.
7. Return a clean summary containing:
   - branch-protection truth
   - required-check truth
   - whether Pages is configured
   - current public Pages URL if it exists
   - anything blocked or surprising
8. Stop only for required login, 2FA, or unavoidable owner-level approval.

Preferred behavior:
- Be autonomous
- Report the current state, do not modify protections unless explicitly asked
```

## 4. RevenueCat product and entitlement truth check

Run this only if paid packs or store billing are expected to be turned on soon.

```text
Audit the current RevenueCat project state for Ummah App and return what is actually configured.

Context:
- App/package ID: com.zokorp.ummah
- The mobile app uses RevenueCat public SDK keys in production config
- The Cloudflare Worker expects REVENUECAT_API_KEY for paid pack entitlement checks

Your job:
1. Open RevenueCat and locate the Ummah App project if it exists.
2. Confirm:
   - project name/id
   - Android app configured
   - iOS app configured
   - public SDK keys present
3. Inspect current entitlements and offerings.
4. Verify whether the product IDs expected by code appear to exist and be mapped.
5. Return a clean summary containing:
   - project truth
   - platform-app truth
   - entitlement truth
   - offering truth
   - whether anything appears incomplete or ambiguous for live paid-pack checks
6. Stop only for required login or unavoidable approval.

Preferred behavior:
- Be autonomous
- Report what exists; do not invent pricing or create products unless explicitly asked
```
