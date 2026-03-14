# Hardening Report

## Architecture improvements
- split bootstrap concerns with dedicated location resolution, notification sync, and support-report builder helpers
- removed startup Hadith manifest dependency from onboarding/content-pack planning
- kept the Worker optional and isolated to remote Hadith pack delivery

## Privacy improvements
- added explicit repository audit, privacy model, and privacy review checklist
- removed passive analytics-toggle posture from settings and replaced it with an explicit “no analytics SDK” statement
- redacted diagnostics persistence and support reports by default

## Security improvements
- hid RevenueCat app user identifiers from passive diagnostics UI
- tightened Worker download signatures to bind app user id, pack id, object key, and expiry
- revalidated manifest/object mapping on Worker download
- made paid-pack misconfiguration fail as unavailable rather than silently resembling a normal denial

## Performance and older-device improvements
- kept onboarding pack planning local and lightweight
- preserved the small-install path and optional remote pack downloads
- added the foundation for build-size monitoring in automation

## Automation improvements
- broadened CI expectations to include formatting, dependency review, Worker validation, and build-size reporting
- documented local developer commands for a solo-founder workflow

## Remaining Atlas-dependent work
- Cloudflare login, R2/KV/Worker secret setup, and deploy verification
- store-console or RevenueCat dashboard tasks that require browser auth
