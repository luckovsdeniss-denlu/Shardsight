# Shardsight

Android game inspired by classic Ultima Online mechanics (stats, skills, open-world rules),
using the phone's compass, gyroscope, GPS and microphone.

- Native Kotlin, no third-party dependencies. minSdk 26, targetSdk 34.
- `core/Rules.kt`: stat/skill caps and combat formulas from the mechanics reference.
- `sensors/SensorHub.kt`: heading, gyro, GPS fix and mic loudness.
- `GameView.kt`: SurfaceView render loop (placeholder world + sensor HUD).

## Build

Needs the Android SDK and JDK 17.

    ./gradlew assembleDebug    # app/build/outputs/apk/debug/app-debug.apk

CI (`.github/workflows/android-apk.yml`) builds the debug APK on every push and uploads it
as the `shardsight-debug-apk` artifact.
