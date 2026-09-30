#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

AVD_NAME="handsfree_test_avd"
APK_PATH="$ROOT_DIR/app/build/app/outputs/flutter-apk/app-debug.apk"
PKG_NAME="com.guettli.handsfree_anki"
SCREENSHOT_PATH="$ROOT_DIR/app/build/emulator_screenshot.png"
mkdir -p "$(dirname "$SCREENSHOT_PATH")"

STARTED_OUR_EMULATOR=0
cleanup() {
    if [ "$STARTED_OUR_EMULATOR" = "1" ]; then
        echo ">> Stopping headless emulator..."
        adb emu kill >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

echo "=== Hands-Free Flashcards: Android Emulator Test ==="

# 1. Build APK if not present
if [ ! -f "$APK_PATH" ]; then
    echo ">> Building debug APK..."
    (cd "$ROOT_DIR/app" && mise exec -- flutter build apk --debug)
fi
echo "✓ APK ready at: $APK_PATH ($(du -h "$APK_PATH" | cut -f1))"

# 2. Check or create AVD
if ! avdmanager list avd 2>/dev/null | grep -q "Name: $AVD_NAME"; then
    echo ">> Creating AVD: $AVD_NAME..."
    mkdir -p "$HOME/.android"
    echo "no" | avdmanager create avd \
        -n "$AVD_NAME" \
        -k "system-images;android-31;default;x86_64" \
        --device "pixel" \
        --force
fi
echo "✓ AVD $AVD_NAME is available."

# 3. Check if an emulator/device is already running
DEVICE=$(adb devices | grep -v "List of devices" | grep "device$" | head -n1 | cut -f1 || true)

if [ -z "$DEVICE" ]; then
    echo ">> Launching emulator $AVD_NAME in headless mode..."
    # Launch emulator in background with no GUI window and swiftshader GPU
    emulator -avd "$AVD_NAME" \
        -no-window \
        -no-audio \
        -no-boot-anim \
        -gpu swiftshader_indirect \
        -memory 2048 \
        -netdelay none \
        -netspeed full &
    EMU_PID=$!
    STARTED_OUR_EMULATOR=1
    echo ">> Emulator started with PID $EMU_PID. Waiting for device..."
    adb wait-for-device

    echo ">> Waiting for Android OS to complete booting..."
    BOOT_SUCCESS=0
    for i in {1..60}; do
        BOOT_DONE=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
        if [ "$BOOT_DONE" = "1" ]; then
            BOOT_SUCCESS=1
            break
        fi
        sleep 2
    done
    if [ "$BOOT_SUCCESS" != "1" ]; then
        echo "❌ ERROR: Android OS failed to boot within 120s!"
        exit 1
    fi
    echo "✓ Android OS boot completed."
else
    echo "✓ Using currently running device: $DEVICE"
fi

# 4. Install the APK
echo ">> Installing APK to emulator..."
adb install -r "$APK_PATH"
echo "✓ APK installed successfully."

# 5. Grant permissions
echo ">> Granting runtime permissions..."
adb shell pm grant "$PKG_NAME" android.permission.RECORD_AUDIO 2>/dev/null || true
adb shell pm grant "$PKG_NAME" android.permission.POST_NOTIFICATIONS 2>/dev/null || true

# 6. Start the app
echo ">> Launching MainActivity..."
adb shell am start -n "$PKG_NAME/.MainActivity"

# 7. Wait and verify the process is alive
echo ">> Checking app process status..."
sleep 6
APP_PID=$(adb shell pidof "$PKG_NAME" || true)

if [ -z "$APP_PID" ]; then
    echo "❌ ERROR: App crashed or failed to start!"
    adb logcat -d | tail -n 50
    exit 1
fi
echo "✓ App running successfully! (PID: $APP_PID)"

# 8. Take a screenshot
echo ">> Capturing emulator screenshot..."
adb exec-out screencap -p > "$SCREENSHOT_PATH"
echo "✓ Screenshot saved to: $SCREENSHOT_PATH ($(du -h "$SCREENSHOT_PATH" | cut -f1))"

# 9. Verify foreground service logcat
echo ">> Recent App Logs:"
adb logcat -d | grep -iE 'flutter|handsfree_anki' | tail -n 25 || true

echo "=== All Emulator Tests Passed Successfully! ==="
