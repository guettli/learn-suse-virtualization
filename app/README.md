# Hands-Free Flashcards for Android

A hands-free, voice-controlled flashcard application built with Flutter for the **SUSE Cloud-Native & Virtualization** learning decks.

Designed specifically to be used **on the go** (walking, cycling, commuting, exercising, cooking) with headphones and the phone in your pocket or screen turned off.

---

## Hands-Free Voice Workflow

```
       +---------------------------------------------+
       |           1. App Speaks Question            |
       |                (via TTS)                    |
       +---------------------------------------------+
                              |
                              v
       +---------------------------------------------+
       |   2. App Listens for "OK" or "NEXT"         |
       |              (Microphone on)                |
       +---------------------------------------------+
                              |
                              v
       +---------------------------------------------+
       |            3. App Speaks Answer             |
       |                (via TTS)                    |
       +---------------------------------------------+
                              |
                              v
       +---------------------------------------------+
       |    4. App Listens for Rating:               |
       |     "SIMPLE", "MEDIUM", or "HARD"           |
       +---------------------------------------------+
                              |
                              v
       +---------------------------------------------+
       | 5. SM-2 Spaced Repetition updates interval  |
       |            and advances to next card        |
       +---------------------------------------------+
```

---

## Spoken Commands

| Phase | Voice Command | Action |
|---|---|---|
| **Question** | `"next"`, `"ok"`, `"okay"`, `"show"`, `"answer"` | Reveals and speaks the answer |
| **Answer** | `"simple"`, `"easy"`, `"good"` | Perfect recall (increases interval & ease factor) |
| **Answer** | `"medium"`, `"okay"`, `"normal"` | Moderate effort recall (advances interval) |
| **Answer** | `"hard"`, `"difficult"`, `"again"` | Failed/difficult recall (resets interval, re-queues card) |
| **Anytime** | `"repeat"` | Re-reads current question or answer aloud |
| **Anytime** | `"pause"` / `"stop"` | Pauses speech and microphone |
| **Anytime** | `"resume"` | Resumes study session |

> **Touch Fallback:** All actions also have large, accessible on-screen buttons so you can switch between voice and touch seamlessly.

---

## Screen-Off / In-Pocket Mode

When starting a study session, the app initiates an **Android Foreground Service** with `microphone` service type and a persistent notification (`Studying: SUSE Virtualization...`).
- Holds a partial wake lock to prevent CPU sleep.
- Keeps microphone recognition active even when the screen turns off or the phone is in your pocket.
- Stops cleanly when navigating back from the study session.

---

## Headset / Bluetooth Button Controls

When your phone is in your pocket or screen is off, you can also control the study session using your wired or Bluetooth headphone buttons (or smartwatch media controls):

| Headset Button / Gesture | During Question Phase | During Answer Phase | During Speech |
|---|---|---|---|
| **Play / Pause** (Single click / tap) | Reveals answer | Repeats answer audio | Pauses / Resumes session |
| **Next Track** (Double tap on earbuds / Next button) | Reveals answer | Rates as **Simple** (advances) | - |
| **Previous Track** (Triple tap on earbuds / Prev button) | Repeats question audio | Repeats answer audio | - |

> **Note:** Bluetooth earbuds (AirPods, Galaxy Buds, Sony, etc.) translate double/triple taps into native Next/Previous track events. Single-button wired headsets emit Play/Pause on single click. Devices with dedicated Next/Previous hardware buttons or smartwatch media controls are also fully supported.

---

## Spaced Repetition (SM-2)

The app implements the standard SuperMemo-2 (SM-2) algorithm used by Anki:
- **Repetitions count:** tracks consecutive successful recalls.
- **Ease Factor (EF):** starts at 2.5, dynamically adjusts according to difficulty.
- **Interval:** expands exponentially on repeated recall (`interval * EF`).
- **Due queue:** filters cards due today and prioritizes them before introducing new cards.
- **Local Persistence:** progress is saved locally using `SharedPreferences`.

---

## Development Setup with mise

1. **Install tools using mise:**
   ```bash
   mise install
   ```

2. **Generate / Update Cards JSON Asset:**
   ```bash
   python build.py
   # Or directly:
   python scripts/export_cards_json.py
   ```

3. **Run the Flutter App:**
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

4. **Build Android APK:**
   ```bash
   cd app
   flutter build apk --release
   ```
