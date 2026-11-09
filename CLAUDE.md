# Shardsight: working notes

- **Never build an APK unless the owner asks for one** ("build", "push and build", "пуш и билд").
  The workflow `.github/workflows/android-apk.yml` runs only on `workflow_dispatch`; start it on
  `main` when asked, and only then.
- "push" means: fast-forward `main` to the dev branch `claude/android-game-apk-init-3zkjp2`,
  without building.
- Play-tests: don't start extra play-test runs or schedule check-ins.
- Bump `config/version` in `project.godot` and add a CHANGELOG entry with each change.
- Experimental mode: new or risky ideas go in as experiments first. Add an entry to
  `Experiments.LIST` (`scripts/experiments.gd`) and gate the change with `Experiments.on("id")`;
  it is off in the ordinary game and switchable in Main Menu > Experiments. Experimental mode has
  its own save (`SaveGame.slot`).
