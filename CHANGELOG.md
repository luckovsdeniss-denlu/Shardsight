# Changelog

Version lives in `project.godot` (`application/config/version`). Bump it there; CI stamps it
into the Android `version/name` and uses the workflow run number as `version/code`.

## 0.4.0
- Population: the hero, two computer-played players, two NPCs (healer, merchant) and
  monsters (rats, wolf, orcs), all built on one `Entity` class (`scripts/entity.gd`).
- Combat uses the reference formulas: hit chance, swing speed, Tactics/Strength/Anatomy damage,
  armor soak. Tap a monster to attack it.
- Skills rise by use; dying resurrects at spawn with -10% skills (never below starting values).
- Monsters aggro on players, chase, give up past their leash and respawn. Hurt players retreat to
  the healer, who heals everyone nearby. Stat blocks live in `scripts/bestiary.gd`.
- HUD shows skills; on-screen event log; floating damage numbers.

## 0.3.0
- Character acts on its own: idles, then wanders to random reachable tiles nearby.
  Tapping takes over for a few seconds; an on-screen button toggles Auto mode.

## 0.2.0
- Now 3D: tile map built from 3D meshes (ground, walls, water, trees), third-person camera,
  tap/drag on the ground picks a tile, A* routes around obstacles.

## 0.1.0
- Godot 4.3 project, Android debug export via GitHub Actions.
- Stats/skills model and classic UO combat formulas (`Rules`, `Hero`).
- ASCII tile map with collisions and A* tap-to-move.
