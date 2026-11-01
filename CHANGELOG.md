# Changelog

Version lives in `project.godot` (`application/config/version`). Bump it there; CI stamps it
into the Android `version/name` and uses the workflow run number as `version/code`.

## 0.2.0
- Now 3D: tile map built from 3D meshes (ground, walls, water, trees), third-person camera,
  tap/drag on the ground picks a tile, A* routes around obstacles.

## 0.1.0
- Godot 4.3 project, Android debug export via GitHub Actions.
- Stats/skills model and classic UO combat formulas (`Rules`, `Hero`).
- ASCII tile map with collisions and A* tap-to-move.
