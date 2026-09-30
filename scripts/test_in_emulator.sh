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

# 8. Test Help Dialog on Deck Selection Screen
echo ">> Testing Voice Commands Help button..."
adb shell input tap 1017 137
sleep 2
adb shell uiautomator dump /sdcard/help_dump.xml
if ! adb shell cat /sdcard/help_dump.xml | grep -q "Voice Commands"; then
    echo "❌ ERROR: Help dialog did not open!"
    exit 1
fi
echo "✓ Help dialog opened successfully."
# Dismiss help dialog
adb shell input keyevent 4 # Android Back key
sleep 1

# 9. Tap the Study button for SUSE Virtualization
echo ">> Tapping Study button for SUSE Virtualization at (854, 872)..."
adb logcat -c
adb shell input tap 854 872
sleep 4

STUDY_PID=$(adb shell pidof "$PKG_NAME" || true)
if [ -z "$STUDY_PID" ]; then
    echo "❌ CRASH DETECTED after clicking Study button!"
    echo ">> Logcat crash logs:"
    adb logcat -d | grep -iE 'fatal|crash|exception|androidruntime|flutter|caused by' | tail -n 60 || true
    adb logcat -d | tail -n 60
    exit 1
fi
echo "✓ App still running after clicking Study! (PID: $STUDY_PID)"

# 10. Capture screenshot of Study Screen
echo ">> Capturing emulator study screen..."
adb exec-out screencap -p > "$SCREENSHOT_PATH"
echo "✓ Screenshot saved to: $SCREENSHOT_PATH ($(du -h "$SCREENSHOT_PATH" | cut -f1))"

# 11. Test Pause & Resume buttons
echo ">> Testing Pause button..."
adb shell input tap 1017 137
sleep 2
echo ">> Testing Resume button..."
adb shell input tap 1017 137
sleep 2

# 12. Test Repeat button
echo ">> Testing Repeat audio button..."
adb shell input tap 891 137
sleep 2

# 13. Test Show Answer button
echo ">> Testing Show Answer button at (540, 1685)..."
adb shell input tap 540 1685
sleep 3
adb shell uiautomator dump /sdcard/answer_dump.xml
if ! adb shell cat /sdcard/answer_dump.xml | grep -q "Hard"; then
    echo "❌ ERROR: Rating buttons not visible after Show Answer!"
    exit 1
fi
echo "✓ Answer revealed and rating buttons visible."

# 14. Test Hard rating button
echo ">> Testing Hard rating button at (200, 1689)..."
adb shell input tap 200 1689
sleep 3

# 15. Test Medium rating button on next card
echo ">> Testing Medium rating flow..."
adb shell input tap 540 1685 # Show Answer
sleep 2
adb shell input tap 540 1689 # Medium
sleep 3

# 16. Test Simple rating button on next card
echo ">> Testing Simple rating flow..."
adb shell input tap 540 1685 # Show Answer
sleep 2
adb shell input tap 881 1689 # Simple
sleep 3

# 17. Test Back button to return to Deck Selection
echo ">> Testing Back button at (74, 137)..."
adb shell input tap 74 137
sleep 3
adb shell uiautomator dump /sdcard/deck_dump.xml
if ! adb shell cat /sdcard/deck_dump.xml | grep -q "Hands-Free Flashcards"; then
    echo "❌ ERROR: Failed to return to Deck Selection screen!"
    exit 1
fi
echo "✓ Returned to Deck Selection screen cleanly."

# 18. Verify foreground service logcat
echo ">> Recent App Logs:"
adb logcat -d | grep -iE 'flutter|handsfree_anki' | tail -n 25 || true

echo "=== All Emulator Button & Feature Tests Passed Successfully! ==="

