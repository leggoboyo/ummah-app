#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_ID="com.zokorp.ummah"
MAIN_ACTIVITY="$APP_ID/.MainActivity"
ADB_BIN="${ADB_BIN:-adb}"
ADB_SERIAL="${ADB_SERIAL:-}"
APK_PATH="${APK_PATH:-}"
MONKEY_EVENTS="${MONKEY_EVENTS:-200}"

if ! command -v "$ADB_BIN" >/dev/null 2>&1; then
  for candidate in \
    "${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}/platform-tools/adb" \
    "${ANDROID_HOME:-$HOME/Library/Android/sdk}/platform-tools/adb"
  do
    if [[ -x "$candidate" ]]; then
      ADB_BIN="$candidate"
      break
    fi
  done
fi

if ! command -v "$ADB_BIN" >/dev/null 2>&1 && [[ ! -x "$ADB_BIN" ]]; then
  echo "adb not found. Set ADB_BIN or install Android platform-tools." >&2
  exit 1
fi

adb_cmd() {
  if [[ -n "$ADB_SERIAL" ]]; then
    "$ADB_BIN" -s "$ADB_SERIAL" "$@"
  else
    "$ADB_BIN" "$@"
  fi
}

echo "Using device: ${ADB_SERIAL:-default adb target}"

if [[ -n "$APK_PATH" ]]; then
  echo "Installing APK: $APK_PATH"
  adb_cmd install -r "$APK_PATH"
fi

echo "Waiting for device boot completion..."
adb_cmd wait-for-device
until [[ "$(adb_cmd shell getprop sys.boot_completed | tr -d '\r')" == "1" ]]; do
  sleep 2
done

echo "Clearing previous logs and app data..."
adb_cmd logcat -c || true
adb_cmd shell pm clear "$APP_ID" >/dev/null

echo "Disabling Wi-Fi and mobile data..."
adb_cmd shell svc wifi disable || true
adb_cmd shell svc data disable || true

echo "Launching app..."
adb_cmd shell am start -n "$MAIN_ACTIVITY" >/dev/null
sleep 6

echo "Checking foreground activity..."
adb_cmd shell dumpsys activity activities | grep -q "$MAIN_ACTIVITY"

echo "Running bounded Monkey smoke ($MONKEY_EVENTS events)..."
adb_cmd shell monkey -p "$APP_ID" --pct-syskeys 0 --pct-anyevent 0 --ignore-crashes --ignore-timeouts --monitor-native-crashes -v "$MONKEY_EVENTS" >/tmp/ummah_monkey.log 2>&1 || true

echo "Scanning logcat for fatal signals..."
LOGCAT_OUTPUT="$(adb_cmd logcat -d)"
if echo "$LOGCAT_OUTPUT" | grep -E "FATAL EXCEPTION| ANR in |Unhandled Exception|FlutterError" >/dev/null; then
  echo "Smoke test found fatal runtime signals." >&2
  echo "$LOGCAT_OUTPUT" | grep -E "FATAL EXCEPTION| ANR in |Unhandled Exception|FlutterError" >&2 || true
  exit 1
fi

echo "Smoke test passed."
