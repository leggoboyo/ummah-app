# Advancement Roadmap

This roadmap turns the app's current feature set into an explicit module and
pack platform. It is the product/engineering contract for what is core,
optional, free, paid, offline-only, or network-optional.

## Core modules

| Module | Release | Gating | Pack dependencies | Network posture | Sourcing obligations |
| --- | --- | --- | --- | --- | --- |
| Onboarding | Available | Free | None | Offline-only | Explain privacy posture, module choices, and starter downloads clearly. |
| Prayer & Adhan | Available | Free | `core_prayer` | Offline-only | No server dependency for calculation or scheduling. |
| Qibla | Available | Free | `core_prayer` | Offline-only | Device sensors and coordinates remain local. |
| Hijri Date | Available | Free | `core_prayer` | Offline-only | Local calculation only. |
| Quran Reader | Available | Free | `quran_arabic` | Offline-only | Arabic text stays verbatim with Tanzil attribution and version. |

## Free optional modules

| Module | Release | Gating | Pack dependencies | Network posture | Sourcing obligations |
| --- | --- | --- | --- | --- | --- |
| Hadith Finder | Available | Free | Any `hadith_pack:*` | Offline after install | HadeethEnc attribution, version, and no-modify posture must stay visible. |
| Smart Quran Search | Coming soon | Free | `quran_search:smart` | Offline after install | Search indexes may normalize text internally, but displayed Quran/translation strings stay verbatim. |
| Basics of Islam | Coming soon | Free | `learning_pack:basics_islam` | Offline after install | Lesson prose must be original; citations and references remain explicit. |
| Dua & Dhikr | Coming soon | Free | `dua_dhikr:starter` | Offline after install | Every entry must show source references and attribution. |
| Quran Audio | Blocked | Free / later premium mix | `quran_audio:starter` | Network-optional | Blocked until audio streaming/offline-download licensing is verified. |

## Paid optional modules

| Module | Release | Gating | Pack dependencies | Network posture | Sourcing obligations |
| --- | --- | --- | --- | --- | --- |
| Quran Assistant | Available | `ai_quran` | `quran_arabic` plus optional local translations | Network-optional | BYOK-first, grounded answers only, citations required, never authoritative fatwas. |
| Hadith Assistant | Available | `ai_hadith` | Any `hadith_pack:*` | Network-optional | BYOK-first, grounded answers only, citations required, never authoritative fatwas. |
| Scholar Sources & Opinions | Available | `scholar_feed` | None | Network-optional | Curated source directory, links first, summaries clearly labeled as summaries. |

## Dynamic source-backed content that is not a true pack yet

- Quran translations:
  - Current delivery remains QuranEnc API sync for selected translations.
  - They are still optional, locally cached, version-tagged, and visible in
    Sources & Licenses, but they are not migrated to pack artifacts in this wave.
- Scholar feed refresh:
  - Public source metadata and RSS refresh remain network-optional.
  - Local caching is allowed only for metadata and explicitly permitted excerpts.

## Privacy and network contract

- App boot, prayer, qibla, Hijri date, and Quran Arabic reading must never
  require network.
- Billing, Hadith pack delivery, scholar feeds, and BYOK AI remain lazy and
  optional.
- No app-level account is introduced.
- No analytics or crash reporting are enabled by default.

## Source transparency rules

- Every republished Quran/hadith/translation surface must show attribution and
  version metadata.
- Canonical Quran Arabic and downloaded translations remain verbatim on display.
- Derived indexes, normalized tokens, and fuzzy-search helpers are internal
  search artifacts only.
- If licensing is unclear, the feature stays blocked rather than shipping with
  ambiguous rights.
