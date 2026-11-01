# Shardsight

Android game inspired by classic Ultima Online mechanics (stats, skills, open-world rules).
3D game built with Godot 4.3 (GDScript, GL Compatibility renderer).

- `scripts/rules.gd`: stat/skill caps and combat formulas from the mechanics reference.
- `scripts/entity.gd`: every creature (hero, players, NPCs, monsters): AI, movement, combat.
- `scripts/gear.gd`: weapons and armor.
- `scripts/corpse.gd`, `scripts/items.gd`: looting.
- `scripts/spells.gd`: Magery spell table.
- `scripts/bestiary.gd`: stat blocks.
- `scripts/hero.gd`: 3 stats, skills 0..100, no classes or levels.
- `scripts/world.gd`: ASCII tile map (grass, wall, water, tree): collision lookup, A* pathfinding, 3D mesh building.
- `scripts/main.gd`: third-person camera; spawns the world; the hero acts on its own (Auto button toggles); tap the ground to walk, tap a monster to attack.
- `export_presets.cfg`: Android preset (arm64, debug-signed).

## Run / build

Open the folder in Godot 4.3 and press Play. For Android, install the export templates
and the Android SDK, then Project > Export > Android.

CI (`.github/workflows/android-apk.yml`) exports a debug APK on every push and uploads it
as `shardsight-v<version>`. The version is `application/config/version` in `project.godot`; see CHANGELOG.md.
