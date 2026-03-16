# Tester Instructions

Date: 2026-03-15

Thank you for helping test Ummah App.

## What this app is

Ummah App is a privacy-first, offline-first Muslim app. The main goal of this
beta is to verify that the free worship core stays reliable, clear, and light on
real devices.

The free core includes:

- prayer times
- adhan reminders
- qibla
- Hijri date
- Quran Arabic reading

Optional features such as hadith packs, billing, scholar feed, and BYOK AI
exist, but the core beta focus is stability and trustworthiness.

## What to test first

Please start with:

1. fresh install and onboarding
2. prayer dashboard
3. qibla
4. Quran Arabic reading in airplane mode
5. Hadith Finder source labels and links

If you are using an older or slower Android phone, that is especially valuable.

## Helpful test scenarios

- Use the app in airplane mode after onboarding.
- Deny location permission and confirm manual location still works.
- Try English, Arabic, or Urdu if your device uses one of those languages.
- Check whether the app feels responsive on your phone.
- If you use Hadith Finder, try opening cited hadith and source links.

## How to report bugs

Use the public GitHub bug report form:

- https://github.com/leggoboyo/ummah-app/issues/new/choose

Please include:

- your device model
- Android or iOS version
- app version/build
- device language
- whether you were online, offline, or in airplane mode
- clear steps to reproduce

If the issue involves a security problem, do not file a public issue. Follow the
private reporting instructions in `SECURITY.md`.

## Known current limitations

- The Android beta still needs final confirmation on at least one real lower-end
  device before stronger older-phone claims are made.
- iOS distribution is not the main beta target yet.
- Some optional online features depend on external services and are not the main
  test priority for this wave.

## Privacy and support expectations

- The app does not require an account for the free core.
- No analytics SDK is active in the current build.
- Optional billing and optional online features only matter when you enter those
  surfaces.
- Support and diagnostics should be shared in redacted form first unless more
  detail is clearly needed.
