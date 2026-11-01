# Shardsight

Android game inspired by classic Ultima Online mechanics (stats, skills, open-world rules).
Built with Godot 4.3 (GDScript, GL Compatibility renderer).

- `scripts/rules.gd`: stat/skill caps and combat formulas from the mechanics reference.
- `scripts/hero.gd`: 3 stats, skills 0..100, no classes or levels.
- `scripts/main.gd`: placeholder world, a tile grid where you tap to move.
- `export_presets.cfg`: Android preset (arm64, debug-signed).

## Run / build

Open the folder in Godot 4.3 and press Play. For Android, install the export templates
and the Android SDK, then Project > Export > Android.

CI (`.github/workflows/android-apk.yml`) exports a debug APK on every push and uploads it
as the `shardsight-debug-apk` artifact.
