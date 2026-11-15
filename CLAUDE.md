# Shardsight: working notes

- **Never build an APK unless the owner asks for one** ("build", "push and build", "пуш и билд").
  The workflow `.github/workflows/android-apk.yml` runs only on `workflow_dispatch`; start it on
  `main` when asked, and only then.
- Whenever a build is started or checked, give the APK's download link straight away, without
  being asked: the APK is published to Releases,
  `https://github.com/luckovsdeniss-denlu/Shardsight/releases/tag/v<version>`. Don't give the
  Actions run page link.
- Test builds: when the owner asks to build from another branch (e.g. "build from trailers"), start
  the workflow on that branch; it publishes a pre-release `v<version>-<branch>`
  (`.../releases/tag/v<version>-trailers`), separate from the normal one.
- "push" means: fast-forward `main` to the dev branch `claude/android-game-apk-init-3zkjp2`,
  without building.
- Play-tests: don't start extra play-test runs or schedule check-ins.
- Bump `config/version` in `project.godot` and add a CHANGELOG entry with each change.
- Experimental mode: new or risky ideas go in as experiments first. Add an entry to
  `Experiments.LIST` (`scripts/experiments.gd`) and gate the change with `Experiments.on("id")`;
  it is off in the ordinary game and switchable in Main Menu > Experiments. Experimental mode has
  its own save (`SaveGame.slot`).
- Branches: the trailers have their own branch, `trailers`. Changes to the trailers (`movie.gd`,
  `movie_flight.gd`, `title3d.gd`, the trailer camera, words, music and recording) go there;
  everything else goes to the dev branch. "merge trailers" means: bring `trailers` into the dev
  branch, then fast-forward `main` to it. APKs are built from `main` only, so trailer changes
  reach the phone after a merge. Not `trailer`: that name is the release tag holding the videos.
- Trailer videos: "Record trailer video" (`trailer-video.yml`) records trailer 1, 2 or both, from
  `main` or from any branch or commit given as `source` (e.g. `trailers`). Each trailer replaces
  only its own videos in the `trailer` release.
- Checks: don't run the game or any checks before committing unless the owner asks; the build has
  no tests either.
