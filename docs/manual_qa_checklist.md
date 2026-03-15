# Manual QA Checklist

## Android QA Matrix

- Primary Android smoke profile: latest emulator or tester device, default density, current release candidate build.
- Low-end Android target: API 24 or 26, host-compatible emulator image (`arm64-v8a` on Apple Silicon, `x86` on Intel), about `1.5 GB` RAM, `720x1280`, English UI. Keep the `armeabi-v7a` split APK in the release build for real older phones.
- RTL target: Arabic UI on Android with a manual city in an Arabic-speaking time zone.
- Urdu target: Urdu UI on Android with a manual city in Pakistan.

## Core Free

- Complete onboarding with default Sunni profile and confirm prayer dashboard loads.
- Repeat onboarding with a Ja'fari profile and confirm prayer times still calculate.
- Switch between manual coordinates and device GPS and confirm qibla and prayer times update.
- Deny location permission and confirm the app falls back cleanly to manual coordinates with a clear message.
- Use an unsupported device locale and confirm the app falls back to English without broken layout.
- Confirm prayer times still load in airplane mode.
- Confirm qibla bearing view still loads in airplane mode.
- Confirm a fresh install still reaches onboarding with Wi‑Fi and mobile data disabled.

## Notifications

- On iPhone, enable notifications and confirm the health card explains the rolling scheduling window.
- On iPhone, leave the app closed for multiple days, reopen it, and confirm the health card and scheduled window recover.
- On Android 14+, enable precise adhan alarms and confirm the app handles exact-alarm permission correctly.
- On Android 14+, deny exact alarms and confirm fallback messaging is clear and non-breaking.
- Confirm silent and default adhan sound modes both schedule correctly.

## Quran

- Confirm bundled Arabic text loads offline on first launch.
- Refresh the translation catalog online and confirm the selected translation shows QuranEnc attribution and version.
- Download a translation for a surah, switch to airplane mode, and confirm translated verses still display.
- Search Arabic and English terms and confirm results return quickly on an older test device.
- Confirm the app does not preload Quran translations or sync work until the Quran screen is opened.

## Hadith

- Open the locked Hadith module without entitlement and confirm the user is routed to Plans & Unlocks.
- Unlock Hadith Plus in preview mode and confirm the library opens.
- Refresh categories, download one category, switch to airplane mode, and confirm offline search still works.
- Confirm search results never show placeholder labels like `en` where a source or title should appear.
- Confirm the Shia placeholder messaging remains respectful and clearly marked as not yet licensed.

## Fiqh

- Open the Fiqh Guide and confirm side-by-side comparison appears for disputed topics.
- Confirm evidence references appear for every bundled topic.
- Mark checklist items complete, relaunch the app, and confirm progress persists locally.

## Scholar Feed

- Open the locked Scholar Feed module without entitlement and confirm routing to Plans & Unlocks.
- Unlock Scholar Feed in preview mode and confirm the feed screen loads.
- Refresh followed sources online, then relaunch offline and confirm cached metadata still appears.
- Toggle source follows and confirm the source directory updates cleanly.

## AI Assistant

- Open AI Assistant without an API key and confirm BYOK messaging is clear.
- Save a test API key, ask a low-risk question, and confirm sources are quoted before commentary.
- Ask a high-risk question and confirm the extra safety disclaimer appears.
- Clear the API key and confirm the app no longer reports BYOK as configured.

## Settings, Privacy, and Diagnostics

- Open Data & Privacy and confirm analytics are off by default.
- Open Settings and confirm performance mode can be left on Auto or forced to Lean without breaking the UI.
- Open Sources & Versions and confirm Quran, hadith, fiqh, and scholar feed metadata are shown without app crashes.
- Open Diagnostics & Support and confirm the support report copies to the clipboard.
- Clear local logs and confirm the diagnostics history is empty afterward.

## Accessibility and Polish

- Increase system font size and confirm key screens remain readable.
- Confirm app behavior on a slower or older test phone remains responsive.
- Confirm the lean UI mode reduces animation weight and heavy visual treatment on older Android devices.
- Confirm the non-production banner appears only in dev and staging builds.
