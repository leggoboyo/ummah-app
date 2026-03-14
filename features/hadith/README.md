# Hadith Feature

This package powers the Sunni hadith library, offline cache, and local search.

Remote source:
- HadeethEnc.com API
- Content must remain verbatim
- Publisher attribution must remain visible
- The app tracks the source as `API/v1` locally because the public API docs expose an API version but do not expose a finer-grained content version field

Milestone 3 implementation details:
- Root categories are fetched from HadeethEnc and cached locally
- Category sync downloads hadith details for offline reading and search
- Search runs locally over cached hadith title, text, explanation, attribution, grade, and hints
- Shia hadith support uses a clean placeholder contract until licensed content is available
