# Developer Guide

## Daily commands
- `make bootstrap` — install workspace dependencies with Melos
- `make analyze` — run Flutter analyze across the workspace
- `make test` — run Flutter tests across packages with tests
- `make format-check` — fail if Dart formatting is dirty
- `make worker-test` — run the Cloudflare Worker node tests
- `make worker-upload-packs` — upload generated Hadith pack objects and manifests to Cloudflare R2
- `make worker-deploy` — deploy the Cloudflare Worker with Wrangler
- `make cost-report` — print the current Cloudflare free-tier breakpoint estimate for remote Hadith packs
- `make secret-scan` — fail if tracked secret-like files or high-confidence secret material appear in git
- `make quality` — bootstrap, format check, analyze, tests, and Worker tests
- `make size-report` — print current build artifact sizes if artifacts already exist
- `make site-preview` — serve the public trust site locally on port `4173`

## Core principles when developing
- do not introduce an account requirement for the free core
- keep prayer, qibla, notifications, and Quran Arabic offline-first
- do not add telemetry or analytics casually
- keep optional infrastructure optional
- prefer explicit docs and acceptance tests over clever hidden behavior

## Build notes
- Android/iOS build validation is performed in GitHub Actions.
- staging/prod runtime behavior comes from `mobile/app/env/*.json`.
- `apiBaseUrl` must remain optional; an empty value must not break the free core.
- RevenueCat and store billing must remain off the free-core startup path.
- lower-end Android devices can fall back to lean UI mode automatically or by user override.

## Hadith remote pack workflow
- generate pack artifacts from `features/hadith/tool`
- run `npx wrangler login` once on this machine before the first upload/deploy
- upload generated objects and manifests to the remote R2 bucket with `make worker-upload-packs`
- set Worker secrets in `services/content-pack-worker`:
  - `npx wrangler secret put DOWNLOAD_SIGNING_SECRET`
  - `npx wrangler secret put REVENUECAT_API_KEY`
- deploy the Worker in `services/content-pack-worker` with `make worker-deploy`
- `apiBaseUrl` is already pointed at the live Worker URL in the current env files; keep it optional and verify dashboard truth before public claims
- review `docs/cloudflare_cost_model.md` and `make cost-report` before raising daily starter-pack budgets
- remember that starter-pack budget enforcement is a best-effort cost guardrail, not a strongly consistent abuse counter

## Support and diagnostics workflow
- use the redacted support report first
- only ask a user for the detailed report if identifiers are needed for billing or pack-access debugging

## Solo-founder automation
- rely on CI for format/analyze/test/build validation
- use Dependabot for dependency review
- review build-size reports before shipping heavier content changes
- keep the Pages trust site current when public-facing claims change
