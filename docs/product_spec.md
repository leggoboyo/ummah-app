# Product Spec

## Positioning

Ummah App is a privacy-first, offline-first Muslim companion for iOS and Android. The free tier must always provide reliable prayer times, local adhan notifications, a minimal qibla view, and a Hijri date without ads or required accounts.

## Product Guardrails

- Never force a single school of thought; always let the user choose a fiqh profile and override calculation settings.
- Never present the app as a mufti; rulings are sourced views with escalation to qualified scholars for context-heavy cases.
- Keep core essentials offline and free.
- Keep ongoing server cost at zero for the free tier.
- Keep heavyweight content optional and downloadable on demand.

## Primary Screens

1. Onboarding
2. Home dashboard
3. Prayer times
4. Qibla
5. Quran reader
6. Hadith library
7. Fiqh checklists and disputed issues
8. AI assistant
9. Sources and versions
10. Data and privacy
11. Subscription and module management

## Module Matrix

### Free

- Prayer times with local calculation
- Local adhan notifications and silent/vibrate options
- Manual or GPS-based location
- Minimal qibla
- Hijri date summary
- Fiqh profile selection and calculation method controls
- Local error log export

### Paid or Add-On

- `quran_plus`: advanced tafsir packs, audio downloads, memorization planner
- `hadith_plus`: full Sunni hadith library with offline search
- `ai_quran`: AI Q&A limited to Quran corpus with citations
- `ai_hadith`: AI Q&A over hadith corpus with citations
- `scholar_feed`: scholar, article, and fatwa feed
- `mega_bundle`: unlocks all paid modules

## Entitlements

- `core_free`
- `quran_plus`
- `hadith_plus`
- `ai_quran`
- `ai_hadith`
- `scholar_feed`
- `mega_bundle`

## Core User Flows

### Onboarding

1. Choose app language
2. Choose fiqh profile: Sunni or Shia, then school
3. Review default calculation method and override if desired
4. Choose location mode: GPS or manual
5. Choose notification mode and preferred adhan sound

### Daily Use

1. Home shows current date, next prayer, countdown, and notification health
2. Prayer page shows today’s schedule, method, school, and manual overrides
3. Qibla page offers bearing mode and compass mode with calibration warning
4. Offline banner appears when sync-dependent modules are stale or unavailable

### Safety-Sensitive Knowledge

1. Fiqh views show classification, school applicability, evidence references, and notes
2. AI answers must show verbatim sources first, commentary second
3. High-risk topics trigger a stronger disclaimer and scholar consultation prompt

## Notification Reliability Rules

### Android

- Default to battery-optimized local notifications
- Offer precise adhan alarms as an opt-in
- Ask for exact alarm permission only when the user enables precision mode
- Fall back gracefully if permission is denied

### iOS

- Keep a local queue for the next 60 days
- Schedule only the next rolling window below the pending notification cap
- Replenish on app open and background refresh when available
- Show a visible health indicator and explain that iOS may require occasional app opens

## Accessibility and Privacy

- Large text support
- Low-motion mode
- Clear offline and sync-state indicators
- Privacy page must explicitly list local storage, secure secrets, and any network calls

## v1 Non-Goals

- No social layer
- No user account requirement
- No cloud sync for the free tier
- No unlicensed Shia hadith scraping
- No AR qibla mode in Milestone 1
