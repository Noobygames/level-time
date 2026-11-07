# CurseForge listing: Level Time Goals

Values for the CurseForge project form.

## General

- **Project name:** Level Time Goals
- **Logo:** `logo.png` (512x512, own artwork, no Blizzard assets; regenerate with `make artwork`)
- **Summary:** Set goals for your stream (level, kills, loot, battleground wins) and show them as live cards on screen, with a history. Needs Level Time.
- **Class:** Addons
- **Primary category:** Miscellaneous
- **Additional categories:** Quests & Leveling, PvP

## Description

Content of `description.md`.

## Relations

- **Required dependency:** `level-time` (set via `required-dependencies` in `StreamGoal/.pkgmeta`; matches `## Dependencies: LevelTimer` in `StreamGoal.toc`).

## License

Apache License 2.0 (same as `LICENSE` in the repository).

## Game versions

Pick the versions listed under `## Interface:` in `StreamGoal/StreamGoal.toc`.

## After approval

Uploads run on `v*` tags (second packager step in `.github/workflows/release.yml`, config `StreamGoal/.pkgmeta`). The project ID is already in `StreamGoal.toc`. For a manual first upload use `make package` and upload `dist/StreamGoal-<version>.zip` by hand.
