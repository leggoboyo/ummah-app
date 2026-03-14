# Quran Feature

This package powers the offline Quran reader, local search, and QuranEnc translation caching.

Bundled Arabic source:
- Tanzil Project Uthmani text
- Version: 1.1
- Terms: verbatim reuse allowed with source attribution and a link to `tanzil.net`

Remote translation source:
- QuranEnc API
- Translation metadata is cached with the provider version number
- Downloaded translation text is stored verbatim without modification

Milestone 2 implementation details:
- Arabic mushaf is bundled offline and seeded into SQLite on first use
- Search uses local SQLite FTS with Arabic normalization for more forgiving matches
- Translation catalog refresh and per-surah downloads are optional and work on-demand
