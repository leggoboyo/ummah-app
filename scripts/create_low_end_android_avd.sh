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
    if [[ -n "$candidate" ]] && [[ -d "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

ANDROID_SDK_ROOT_RESOLVED="${ANDROID_SDK_ROOT_RESOLVED:-$(resolve_android_sdk_root || true)}"
AVD_NAME="${AVD_NAME:-ummah_api24_low}"
DEVICE_ID="${DEVICE_ID:-pixel_3a}"
HOST_ARCH="$(uname -m)"
if [[ -z "${SYSTEM_IMAGE:-}" ]]; then
  if [[ "$HOST_ARCH" == "arm64" || "$HOST_ARCH" == "aarch64" ]]; then
    SYSTEM_IMAGE="system-images;android-24;default;arm64-v8a"
  else
    SYSTEM_IMAGE="system-images;android-24;default;x86"
  fi
else
  SYSTEM_IMAGE="$SYSTEM_IMAGE"
fi
RAM_MB="${RAM_MB:-1536}"
VM_HEAP_MB="${VM_HEAP_MB:-256}"
SKIN_NAME="${SKIN_NAME:-720x1280}"

AVDMANAGER_BIN="${AVDMANAGER:-$(command -v avdmanager || true)}"
SDKMANAGER_BIN="${SDKMANAGER:-$(command -v sdkmanager || true)}"

if [[ -z "$AVDMANAGER_BIN" ]] && [[ -n "$ANDROID_SDK_ROOT_RESOLVED" ]] && [[ -x "$ANDROID_SDK_ROOT_RESOLVED/cmdline-tools/latest/bin/avdmanager" ]]; then
  AVDMANAGER_BIN="$ANDROID_SDK_ROOT_RESOLVED/cmdline-tools/latest/bin/avdmanager"
fi

if [[ -z "$SDKMANAGER_BIN" ]] && [[ -n "$ANDROID_SDK_ROOT_RESOLVED" ]] && [[ -x "$ANDROID_SDK_ROOT_RESOLVED/cmdline-tools/latest/bin/sdkmanager" ]]; then
  SDKMANAGER_BIN="$ANDROID_SDK_ROOT_RESOLVED/cmdline-tools/latest/bin/sdkmanager"
fi

if [[ -z "$AVDMANAGER_BIN" ]]; then
  echo "avdmanager is required to create the low-end Android emulator profile." >&2
  exit 1
fi

if [[ -z "$SDKMANAGER_BIN" ]]; then
  echo "sdkmanager is required to install the system image for the low-end profile." >&2
  exit 1
fi

if "$AVDMANAGER_BIN" list avd | grep -q "Name: ${AVD_NAME}\$"; then
  echo "AVD ${AVD_NAME} already exists."
  exit 0
fi

{ yes "no" || true; } | "$SDKMANAGER_BIN" "$SYSTEM_IMAGE"
printf 'no\n' | "$AVDMANAGER_BIN" create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" -d "$DEVICE_ID"

AVD_CONFIG="${HOME}/.android/avd/${AVD_NAME}.avd/config.ini"
if [[ -f "$AVD_CONFIG" ]]; then
  {
    echo "hw.ramSize=${RAM_MB}"
    echo "vm.heapSize=${VM_HEAP_MB}"
    echo "skin.name=${SKIN_NAME}"
    echo "showDeviceFrame=no"
  } >> "$AVD_CONFIG"
fi

echo "Created low-end Android AVD ${AVD_NAME} (${SYSTEM_IMAGE}, ${RAM_MB}MB RAM)."
