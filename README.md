# Ummah App

Privacy-first, offline-first Flutter application for iOS and Android focused on reliable Islamic essentials first: prayer times, adhan alarms, qibla, and a respectful multi-school knowledge model that can grow into Quran, hadith, fiqh, and AI modules.

## Current Status

The repository now contains:

- product and technical specs in [`docs/product_spec.md`](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/product_spec.md), [`docs/technical_spec.md`](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/technical_spec.md), and [`docs/build_plan.md`](/Users/zohaibkhawaja/Documents/Codex/ummah-app/docs/build_plan.md)
- a Flutter-oriented monorepo scaffold with `packages/core`, `features/*`, and `mobile/app`
- Milestone 1 domain logic for prayer calculation, qibla direction, and notification window planning

## Workspace Layout

- `mobile/app`: Flutter application shell and widget tests
- `packages/core`: shared models, storage interfaces, settings, logging, and entitlements
- `features/prayer`: prayer domain models, fiqh profiles, local calculation engine, and notification planning
- `features/qibla`: qibla bearing math and presentation-friendly models
- `features/quran`: placeholder package for Milestone 2
- `features/hadith`: placeholder package for Milestone 3
- `features/fiqh`: placeholder package for Milestone 4
- `features/ai_assistant`: placeholder package for Milestone 6
- `features/subscriptions`: placeholder package for Milestone 5

## Tooling Status

The machine now has Flutter, Android tooling, Xcode, CocoaPods, and an iOS Simulator runtime installed. `flutter doctor -v` is clean, the workspace bootstraps successfully, `flutter analyze` passes across packages, and the current test suite passes.

## Next Recommended Step

To validate the workspace locally, run:

```bash
dart pub get
dart run melos bootstrap
dart run melos exec -c 1 -- flutter analyze
dart run melos exec -c 1 --dir-exists=test -- flutter test
```
