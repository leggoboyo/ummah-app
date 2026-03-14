# Build Plan

## Milestone 1

Goal: ship an offline-first free core with prayer times, qibla, and local notification planning.

Acceptance criteria:

- local prayer time engine with method presets, high latitude rules, and fiqh profile defaults
- qibla bearing calculation and compass-ready models
- iOS rolling notification planner modeled around the pending notification cap
- Android exact-vs-fallback scheduling policy
- onboarding for language, fiqh profile, calculation method, and notification preferences
- unit tests for prayer logic, qibla, and notification windows

## Milestone 2

Goal: offline Quran reader with translation caching and search.

Acceptance criteria:

- offline Arabic mushaf asset integration
- SQLite-backed search over Arabic and cached translations
- QuranEnc version-aware caching and attribution UI

## Milestone 3

Goal: Sunni hadith library with clean room support for future Shia provider integration.

Acceptance criteria:

- HadeethEnc caching and verbatim display
- offline search
- placeholder Shia content pack contract and UI messaging

## Milestone 4

Goal: data-driven fiqh checklist engine and disputed-issues browser.

Acceptance criteria:

- structured fiqh knowledge model
- side-by-side school comparison UI
- checklist flows for daily obligations

## Milestone 5

Goal: paid module gating and entitlement plumbing.

Acceptance criteria:

- provider strategy for RevenueCat or native IAP
- entitlement-aware routes and feature cards
- restore purchases and offline entitlement cache

## Milestone 6

Goal: BYOK-first Islamic RAG assistant.

Acceptance criteria:

- secure BYOK storage
- retrieval restricted to indexed Quran and hadith corpora
- source-first answer formatting
- strong disclaimers for high-risk topics

## Milestone 7

Goal: curated scholar and article feed.

Acceptance criteria:

- source directory
- feed caching and last-sync timestamps
- verbatim metadata display with link-outs

## Cross-Cutting Work

- CI and release automation
- accessibility hardening
- performance budget tracking
- privacy and attribution review
