#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/mobile/app"
AAB="$APP_DIR/build/app/outputs/bundle/release/app-release.aab"
DEBUG_APK="$APP_DIR/build/app/outputs/apk/debug/app-debug.apk"
RELEASE_APK="$APP_DIR/build/app/outputs/flutter-apk/app-release.apk"
ARMV7_APK="$APP_DIR/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
ARM64_APK="$APP_DIR/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
IOS_APP="$APP_DIR/build/ios/iphonesimulator/Runner.app"
REPORT_DIR="$ROOT_DIR/build"
REPORT_PATH="$REPORT_DIR/build-size-report.md"

mkdir -p "$REPORT_DIR"

size_bytes() {
  stat -f%z "$1"
}

human_size() {
  local bytes="$1"
  awk -v bytes="$bytes" 'function human(x) {
    split("B KB MB GB", units, " ");
    idx = 1;
    while (x >= 1024 && idx < 4) {
      x /= 1024;
      idx++;
    }
    return sprintf("%.2f %s", x, units[idx]);
  } BEGIN { print human(bytes) }'
}

{
  echo "# Build Size Report"
  echo
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo

  for artifact in "$AAB" "$DEBUG_APK" "$RELEASE_APK" "$ARMV7_APK" "$ARM64_APK" "$IOS_APP"; do
    if [[ -e "$artifact" ]]; then
      bytes="$(size_bytes "$artifact")"
      echo "- $(basename "$artifact"): $(human_size "$bytes") ($bytes bytes)"
    else
      echo "- $(basename "$artifact"): not present"
    fi
  done
} | tee "$REPORT_PATH"
