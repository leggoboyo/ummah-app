# Security Model

## Trust boundaries
- Mobile client: trusted for local core religious utilities and secure local storage decisions.
- Optional content-pack Worker: trusted only for manifest delivery and gated download grants for remote Hadith packs.
- RevenueCat: optional billing authority for paid entitlements.
- OpenAI: optional BYOK endpoint for AI assistant only.

## Sensitive assets
- BYOK OpenAI API key
- local app user identifier used for RevenueCat/content-pack access
- remote pack integrity hashes and signed access grants
- local offline religious corpora and user setup state

## Storage policy
- BYOK secrets go into `flutter_secure_storage`.
- general settings go into shared preferences.
- offline corpora and indexes live in local SQLite databases.
- no server-side profile store exists for the free core.

## Permission model
- location: only when the user explicitly selects device location
- notifications: only when the user finishes onboarding or explicitly refreshes notification access
- exact alarm: requested only when the user asks for precise Android alarms
- internet: present because optional features exist, but core features must continue to work without it

## Logging and diagnostics
- diagnostics logs are local-only
- persisted logs are redacted before storage
- passive UI avoids exposing app identifiers
- support reports come in redacted and detailed forms

## Remote Hadith pack security
- pack manifests are environment-scoped
- access grants are signed and short-lived
- download signatures now bind pack id, object key, app user id, and expiry
- download requests re-check the manifest/object mapping before reading from R2
- starter-pack claims are idempotent and keyed by app user id
- paid-pack access should fail as unavailable when billing-side configuration is missing

## Security review rules for future changes
- no secret API keys in mobile env files
- no new server dependency for the free prayer core
- any new remote service must have explicit docs for purpose, failure mode, and privacy impact
- any new dependency must be checked for maintenance posture and telemetry behavior
- any new support surface must default to redaction

## Incident response basics
- rotate Worker secrets if download signing or RevenueCat credentials are exposed
- invalidate/update remote pack manifests if corrupted artifacts are published
- cut a redacted support report first before asking a user for detailed diagnostics
