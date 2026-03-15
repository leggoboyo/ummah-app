# Developer Guide

## Daily commands
- `make bootstrap` — install workspace dependencies with Melos
- `make analyze` — run Flutter analyze across the workspace
- `make test` — run Flutter tests across packages with tests
- `make format-check` — fail if Dart formatting is dirty
- `make repo-reality-report` — regenerate endpoint/dependency/permission/workflow inventories
- `make workflow-lint` — run `actionlint` against every GitHub Actions workflow
- `make worker-test` — run the Cloudflare Worker node tests
- `make worker-upload-packs` — upload generated Hadith pack objects and manifests to Cloudflare R2
- `make worker-deploy` — deploy the Cloudflare Worker with Wrangler
- `make cost-report` — print the current Cloudflare free-tier breakpoint estimate for remote Hadith packs
- `make quality` — bootstrap, format check, analyze, tests, and Worker tests
- `make size-report` — print current build artifact sizes if artifacts already exist

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
- `docs/repo_reality_report.md` is the source of truth for current network surfaces and permissions.

## Hadith remote pack workflow
- generate pack artifacts from `features/hadith/tool`
- run `npx wrangler login` once on this machine before the first upload/deploy
- upload generated objects and manifests to the remote R2 bucket with `make worker-upload-packs`
- set Worker secrets in `services/content-pack-worker`:
  - `npx wrangler secret put DOWNLOAD_SIGNING_SECRET`
  - `npx wrangler secret put REVENUECAT_API_KEY`
- deploy the Worker in `services/content-pack-worker` with `make worker-deploy`
- configure `apiBaseUrl` only after the Worker URL is live
- review `docs/cloudflare_cost_model.md` and `make cost-report` before raising daily starter-pack budgets

## Offline-core verification
- `mobile/app/test/app_controller_offline_contract_test.dart` proves the free core boot path does not initialize billing during startup.
- `features/quran/test/quran_repository_test.dart` proves bundled Quran Arabic reading works without any translation sync.
- `make test` is the default acceptance sweep before claiming the free core is still offline-safe.

## Secret rotation and Worker safety
- Cloudflare Worker secrets must stay in Wrangler/Cloudflare secrets, never in mobile env files.
- Rotate `DOWNLOAD_SIGNING_SECRET` immediately if signed Hadith pack URLs leak.
- Rotate `REVENUECAT_API_KEY` immediately if the Worker secret is exposed or copied into logs by mistake.
- Keep `PACK_DOWNLOAD_TTL_SECONDS` short and `STARTER_CLAIMS_DAILY_BUDGET` conservative until real demand is understood.

## Support and diagnostics workflow
- use the redacted support report first
- only ask a user for the detailed report if identifiers are needed for billing or pack-access debugging

## Cloudflare cost guardrails
- Keep the Hadith Worker optional and isolated from the free core.
- Watch the Cloudflare notification for R2 growth and keep the starter-claim budget below the free KV write ceiling.
- Re-run `make cost-report` whenever pack sizes, claim rates, or Worker request patterns change materially.

## Solo-founder automation
- rely on CI for format/analyze/test/build validation
- use Dependabot for dependency review
- review build-size reports before shipping heavier content changes
