# Public Trust Gaps

Date: 2026-03-15

This document tracks the difference between what an external reviewer can now
verify from the public repo and live surfaces, and what still depends on manual
signoff or later publishing work.

## Claims that are now strong and credible

### Public proof posture

These claims are now backed by visible evidence:

- the repo is public
- the trust site is live on GitHub Pages
- `main` is protected with required checks and approvals
- the trust site links back to repo docs rather than making floating claims

Why these are credible:

- the repository is publicly visible on GitHub
- the site is live at `https://leggoboyo.github.io/ummah-app/`
- GitHub branch protection and required checks were manually verified

### Free-core launch and privacy posture

These claims are now backed by code and verification:

- the free-core launch path keeps billing lazy
- prayer, qibla, Hijri, and Quran Arabic remain local-first surfaces
- no analytics SDK is active in the current build
- optional Cloudflare and RevenueCat infrastructure remains outside the free-core
  bootstrap path

### Optional-cloud boundary

These claims are now backed by external verification:

- the live Cloudflare Worker exists at the expected URL
- the Worker has the expected R2 and KV bindings
- the Worker has both `DOWNLOAD_SIGNING_SECRET` and `REVENUECAT_API_KEY`
- Google Play internal testing is active on `0.4.1 (7)`
- the RevenueCat server-side secret path exists for paid pack checks

## Claims that still require careful wording

### 1. “Ready for broader Android beta right now”

Why it still needs care:

- emulator and build proof are strong
- one real lower-end Android device pass is still missing

Better wording:

- say Android broader beta is close and pending one physical low-end signoff

### 2. “iOS public beta or store-ready”

Why it still needs care:

- repo-side iOS blockers were resolved
- distribution, signing, TestFlight/App Store Connect, and store surfaces are
  still human-gated

Better wording:

- say iOS build hygiene is improved, but publishing is still a separate final step

### 3. “Paid optional modules are equally ready on Android and iOS”

Why it still needs care:

- Android-side Worker and RevenueCat server-secret path are verified
- RevenueCat iOS app configuration is still absent

Better wording:

- say optional paid-path infrastructure is verified for the current Android-first
  beta posture

## Claims intentionally kept out of public surfaces

These should remain non-public even though the repo is public:

- the Google Play internal test invite link
- private operational-only dashboard details that do not improve user trust
- any secret values or account-only identifiers beyond what is necessary for proof

## Remaining public-proof gap

The main remaining external gap is now narrow:

- one physical lower-end Android validation pass
- final iOS publishing truth

That is a much smaller gap than the earlier pre-public state, where Cloudflare,
RevenueCat, Play, GitHub Pages, and branch-protection truth were still pending.

## Recommended public proof set

The strongest current public proof bundle is:

1. the live GitHub repository
2. the live trust site
3. `docs/readiness_audit.md`
4. `docs/launch_blockers.md`
5. `docs/release_readiness.md`
6. `docs/privacy_model.md`
7. `docs/security_model.md`

## Current narrative call

The project can now credibly present itself as:

- a public, inspectable privacy-first and offline-first Islamic app
- engineered to keep the free core local-first and the cloud visibly optional
- backed by live CI, protected mainline workflow, and a public trust site

It should still avoid presenting itself as:

- fully proven on real low-end Android hardware before that final device pass
- already distributed and store-ready on iOS
