#!/usr/bin/env bash
set -euo pipefail

resolve_android_sdk_root() {
  local candidates=(
    "${ANDROID_HOME:-}"
    "${ANDROID_SDK_ROOT:-}"
    "/opt/homebrew/share/android-commandlinetools"
    "${HOME}/Library/Android/sdk"
    "${HOME}/Android/Sdk"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" ]] && [[ -x "$candidate/platform-tools/adb" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

ANDROID_SDK_ROOT_RESOLVED="${ANDROID_SDK_ROOT_RESOLVED:-$(resolve_android_sdk_root || true)}"
ADB_BIN="${ADB:-$(command -v adb || true)}"
PACKAGE_NAME="${PACKAGE_NAME:-com.zokorp.ummah}"
MAIN_ACTIVITY="${MAIN_ACTIVITY:-com.zokorp.ummah/.MainActivity}"
MONKEY_EVENTS="${MONKEY_EVENTS:-250}"
LOG_DIR="${LOG_DIR:-$(pwd)/build/android-smoke}"
EXPECT_ONBOARDING_TEXT="${EXPECT_ONBOARDING_TEXT:-Welcome to Ummah App}"
ADB_SERIAL="${ADB_SERIAL:-${ANDROID_SERIAL:-}}"
APK_PATH="${APK_PATH:-}"

if [[ -z "$ADB_BIN" ]] && [[ -n "$ANDROID_SDK_ROOT_RESOLVED" ]]; then
  ADB_BIN="$ANDROID_SDK_ROOT_RESOLVED/platform-tools/adb"
fi

if [[ -z "$ADB_BIN" ]]; then
  echo "adb is required for android_smoke_test.sh. Set ADB or ANDROID_HOME/ANDROID_SDK_ROOT, or install the Android SDK." >&2
  exit 1
fi

ADB_ARGS=("$ADB_BIN")
if [[ -n "$ADB_SERIAL" ]]; then
  ADB_ARGS+=(-s "$ADB_SERIAL")
fi

mkdir -p "$LOG_DIR"

if [[ -n "$APK_PATH" ]]; then
  echo "Installing APK from $APK_PATH"
  "${ADB_ARGS[@]}" install -r "$APK_PATH" >/dev/null
fi

echo "Clearing app data for $PACKAGE_NAME"
"${ADB_ARGS[@]}" shell pm clear "$PACKAGE_NAME" >/dev/null

echo "Disabling Wi-Fi and mobile data"
"${ADB_ARGS[@]}" shell svc wifi disable || true
"${ADB_ARGS[@]}" shell svc data disable || true

echo "Clearing logcat"
"${ADB_ARGS[@]}" logcat -c

echo "Launching $MAIN_ACTIVITY"
"${ADB_ARGS[@]}" shell am start -W -n "$MAIN_ACTIVITY" | tee "$LOG_DIR/launch.txt"
sleep 4

echo "Capturing UI dump"
UI_DUMP="$("${ADB_ARGS[@]}" exec-out uiautomator dump /dev/tty 2>/dev/null || true)"
printf '%s\n' "$UI_DUMP" > "$LOG_DIR/ui-dump.xml"

if [[ -n "$EXPECT_ONBOARDING_TEXT" ]] && [[ "$UI_DUMP" != *"$EXPECT_ONBOARDING_TEXT"* ]]; then
  echo "Warning: expected onboarding text \"$EXPECT_ONBOARDING_TEXT\" was not found in the UI dump." \
    | tee "$LOG_DIR/onboarding-warning.txt"
fi

echo "Running Monkey smoke with $MONKEY_EVENTS events"
"${ADB_ARGS[@]}" shell monkey \
  -p "$PACKAGE_NAME" \
  --ignore-crashes \
  --ignore-timeouts \
  --ignore-security-exceptions \
  -v "$MONKEY_EVENTS" | tee "$LOG_DIR/monkey.txt"

echo "Collecting logcat"
"${ADB_ARGS[@]}" logcat -d > "$LOG_DIR/logcat.txt"

if grep -E "FATAL EXCEPTION|ANR in ${PACKAGE_NAME}|Process ${PACKAGE_NAME} .*has died|Force finishing activity .*${PACKAGE_NAME}|Fatal signal .*${PACKAGE_NAME}|Unhandled Exception|E/flutter" \
  "$LOG_DIR/logcat.txt"; then
  echo "Android smoke test found a fatal runtime signal. See $LOG_DIR/logcat.txt" >&2
  exit 1
fi

echo "Android smoke test passed. Logs saved to $LOG_DIR"
