# Shardsight

Android game inspired by classic Ultima Online mechanics (stats, skills, open-world rules).

- Native Kotlin, no third-party dependencies. minSdk 26, targetSdk 34.
- `core/Rules.kt`: stat/skill caps and combat formulas from the mechanics reference.
- `GameView.kt`: SurfaceView render loop (tile grid, tap to move).

## Build

Needs the Android SDK and JDK 17.

    ./gradlew assembleDebug    # app/build/outputs/apk/debug/app-debug.apk

CI (`.github/workflows/android-apk.yml`) builds the debug APK on every push and uploads it
as the `shardsight-debug-apk` artifact.
