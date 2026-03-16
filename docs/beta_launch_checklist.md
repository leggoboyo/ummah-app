# Beta Launch Checklist

Date: 2026-03-15

This checklist is for the founder/operator before opening a broader Android beta.

## Android-first release gate

- `flutter analyze` passes on `main`
- `flutter test` passes on `main`
- Worker tests pass
- secret scan passes
- Android release APK, split APKs, and AAB build successfully
- size report is refreshed and reviewed
- GitHub required checks are green on the release PR

## Real-device signoff required

Record one physical lower-end Android device before calling the app ready for a
broader external beta.

Required signoff fields:

- device model
- Android version
- locale
- whether lean mode was active
- network state used during testing
- date and tester name

Required physical-device checks:

- onboarding works cleanly from fresh install
- airplane-mode onboarding still reaches prayer/qibla/Quran Arabic without a crash
- older-phone responsiveness is acceptable on the prayer dashboard and Hadith Finder
- exact and inexact alarm behavior is understandable and non-breaking
- Hadith source labels and public verification links remain human-readable

## Trust and public-proof sync

- README matches current repo truth
- `docs/readiness_audit.md` matches the current verified state
- `docs/launch_blockers.md` lists only real blockers
- `docs/public_trust_gaps.md` reflects current public claims accurately
- the trust site at `https://leggoboyo.github.io/ummah-app/` matches current truth

## Android broader beta go / no-go

Proceed only if:

- the physical lower-end Android signoff is complete
- no high-severity privacy, security, or startup issues are open
- Play internal testing still shows the expected active build
- the trust site and public docs do not overclaim beyond current proof

## Escalation path

If a low-end Android regression appears:

1. stop broader beta expansion
2. capture a bug report with device model, OS version, locale, and network state
3. reproduce on emulator if possible
4. update `docs/launch_blockers.md` if the issue changes the public risk posture

## iOS note

iOS remains a secondary track until signing, TestFlight/App Store Connect setup,
and final listing assets are ready. Do not treat iOS as a public-beta gate for
this Android-first wave.
