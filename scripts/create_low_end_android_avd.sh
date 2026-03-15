#!/usr/bin/env bash
set -euo pipefail

ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
CMDLINE_TOOLS="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin"
AVD_MANAGER="$CMDLINE_TOOLS/avdmanager"
SDK_MANAGER="$CMDLINE_TOOLS/sdkmanager"
AVD_NAME="${AVD_NAME:-ummah_low_end_api24}"
SYSTEM_IMAGE="${SYSTEM_IMAGE:-system-images;android-24;google_apis;arm64-v8a}"
DEVICE_ID="${DEVICE_ID:-pixel}"

if [[ ! -x "$AVD_MANAGER" || ! -x "$SDK_MANAGER" ]]; then
  echo "Android command-line tools not found under $CMDLINE_TOOLS" >&2
  exit 1
fi

echo "Installing $SYSTEM_IMAGE if needed..."
"$SDK_MANAGER" "$SYSTEM_IMAGE" >/dev/null

if [[ -d "$HOME/.android/avd/${AVD_NAME}.avd" ]]; then
  echo "AVD $AVD_NAME already exists."
else
  echo "Creating AVD $AVD_NAME..."
  printf 'no\n' | "$AVD_MANAGER" create avd \
    --force \
    --name "$AVD_NAME" \
    --package "$SYSTEM_IMAGE" \
    --device "$DEVICE_ID" >/dev/null
fi

CONFIG_PATH="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
if [[ -f "$CONFIG_PATH" ]]; then
  {
    echo "hw.ramSize=1536"
    echo "vm.heapSize=256"
    echo "disk.dataPartition.size=2048M"
  } >>"$CONFIG_PATH"
fi

echo "Ready: $AVD_NAME"
