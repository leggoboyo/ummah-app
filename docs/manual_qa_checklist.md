# Manual QA Checklist

## Core Free

- Complete onboarding with default Sunni profile and confirm prayer dashboard loads.
- Repeat onboarding with a Ja'fari profile and confirm prayer times still calculate.
- Switch between manual coordinates and device GPS and confirm qibla and prayer times update.
- Deny location permission and confirm the app falls back cleanly to manual coordinates with a clear message.
- Confirm prayer times still load in airplane mode.
- Confirm qibla bearing view still loads in airplane mode.
- Run the API 24 / low-end emulator smoke script and confirm onboarding starts without a crash:
  - `make create-low-end-avd`
  - `make android-smoke`

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

## Hadith

- Open the locked Hadith module without entitlement and confirm the user is routed to Plans & Unlocks.
- Unlock Hadith Plus in preview mode and confirm the library opens.
- Refresh categories, download one category, switch to airplane mode, and confirm offline search still works.
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
- Confirm the page says billing network requests happen only when Plans & Unlocks, restore purchases, or a paid-gated module is opened.
- Toggle privacy analytics on and off and confirm the preference persists after relaunch.
- Open Sources & Versions and confirm Quran, hadith, fiqh, and scholar feed metadata are shown without app crashes.
- Confirm provider homepage/docs links open correctly from Sources & Versions.
- Open Diagnostics & Support and confirm the support report copies to the clipboard.
- Clear local logs and confirm the diagnostics history is empty afterward.

## Accessibility and Polish

- Increase system font size and confirm key screens remain readable.
- Confirm app behavior on a slower or older test phone remains responsive.
- Confirm the lean performance mode can be forced from Settings and the UI remains usable.
- Confirm the non-production banner appears only in dev and staging builds.
