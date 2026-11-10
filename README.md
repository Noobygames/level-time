# Level Time

Useful WoW addon (compatible with WoW Forever) to show statistics.

## Level Time

Shows statistics in a small, movable window, either for your **current level** or your **current session** (switch with the "Level | Session" tabs at the top):

- **Play time**: on this level synced with the server (`/played`), for the session since login; both counted up live.
- **XP bar** with the rested bonus shown as a lighter segment (can be turned off).
- **XP per hour**, the estimated play time until the next level and an estimate until max level (based on your recent levels). Optionally without AFK time.
- **Current XP/h** (optional row): XP per hour over the last 15 minutes, so slow phases show right away.
- **Kills/quests to level** (optional row): how many kills or quests are left at this level's average XP.
- **Time breakdown** (optional row): play time in combat, on flight paths, AFK and the rest.
- **Kills**, split into:
  - **PvE**: every kill that granted experience, including group kills. Grey mobs and kills at max level don't count.
  - **PvP**: honorable kills.
  - **Elite and rare** kills (optional rows): enemies are classified when you target, hover or see their nameplate.
- **Deaths**, with time spent dead or as a ghost and kills per death.
- **Near deaths** (optional row): health dropped below 10 % and you survived (counted once health is back above 30 %).
- **XP sources**: share of XP from kills, quests and other sources (exploration, professions, ...).
- **Rested XP**: bonus XP gained from rest and its share of the XP; optionally the rested XP still left.
- **Level-up summary** in chat: how long the level took, kills, deaths and XP/h (can be turned off).
- **Quests** turned in.
- **Income**: money earned (loot, quests, sales, mail); spending is not subtracted.
- **Spending** (optional row): repairs, merchants, flights, trainers and other, plus income from sold junk.

The window shows them as a table, label on the left and value on the right. Every value can be switched on or off on its own (e.g. PvE and PvP kills separately). Level statistics restart on level-up. A session runs from login to logout; a `/reload` or a short break (up to 5 minutes) continues it.

Statistics are recorded separately for every character. They are stored account-wide, so you can look at all your characters from any of them. Use "Delete data" in the history window to remove a character's statistics (e.g. after deleting the character).

### History and evaluation

The history window shows, per character:

- **Levels**: play time, XP/h, kills, deaths, quests and income of every finished level, saved on level-up.
- **Time split**: time in combat, flying, AFK, dead and the rest for every level.
- **Timeline**: when each level was reached, with total /played at that moment and how long the level took.
- **Sessions**: start, duration, level range, XP/h, kills, deaths, quests and income of every past session.
- **Kills**: every killed creature and player with time, name, PvE/PvP, level and zone (newest 5000).
- **Deaths**: every death with time, cause, level and zone (newest 1000). The cause is the last hit before dying: enemy and spell, or falling, drowning, lava and so on. Retail hides the combat log from addons, so there the cause stays "Unknown".
- **Quests**: every quest turned in with time, name, XP, gold, level and zone (newest 2000).
- **Near deaths**: time, lowest health, cause, level and zone of every close call.
- **Loot**: rare and better items you received, with time, quantity and likely source (the enemy you just killed or the quest you just turned in).
- **Instances**: every dungeon, raid and scenario run with duration, XP, kills and deaths, plus totals; a `/reload` inside continues the run.
- **Zones**: play time, XP, XP/h, kills and deaths per zone, best XP/h first, so you see where leveling pays off.
- **Compare**: all characters side by side (level, levels gained, average time per level, XP/h, kills, deaths, gold), fastest leveler first.
- **Charts**: time per level, XP/h per level, kills per day (last 30 days, kept as daily totals even when old journal entries are dropped), top enemies, death causes, XP/h per zone, play time per day and week, and the XP timeline of the session (5-minute steps, breaks show as gaps). Hover a column for the exact value.

The running level or session is highlighted at the top, a **Total** row at the bottom sums everything up. Click a column header to sort (again to reverse), type in the filter box to search all columns; the total row then covers the filtered rows only. "Export" shows the visible rows as CSV, already selected: press Ctrl+C and paste them into a spreadsheet. Long lists scroll smoothly with the mouse wheel, only the visible rows are drawn. Switch characters with the arrows. Open it with Shift-left-click on the minimap button, the button in the settings, or `/lt history`.

Works across several game versions (Retail, Classic Era, Anniversary, ...) from a single `.toc`. Features a client doesn't support stay off silently. Available in English, German, French and Spanish.

### Minimap button and settings

- Left-click the minimap button (pocket watch) to open the settings, Shift-left-click for the history, right-click to show or hide the window, drag to move it around the minimap.
- On Retail, Level Time also shows up in the addon compartment menu.
- **Data text** for Titan Panel, ElvUI, Bazooka and other LibDataBroker displays: play time and XP/h, tooltip with all enabled values, same clicks as the minimap button. Works when one of those addons is installed (Level Time does not bundle the library).
- Resize the window by dragging its bottom right corner; text and everything else scale with it. Right-click the window to open the settings.
- **Compact mode** (`/lt compact` or settings): only play time, XP bar and XP/h.
- **Horizontal bar** (`/lt bar` or settings): the window as a slim info bar, all values in one line; combines with compact mode.
- **Stream view** (settings): solid green or magenta background without border for chroma keying in OBS.
- **Splits** (settings): running level time against the fastest time of your other characters for that level, plus the total difference, green when ahead and red when behind.
- **Level-up announcement** (settings): post the level summary to your party or guild.
- **Comfort** (settings, each off by default, hold Shift to skip once): repair automatically (optionally from the guild bank), sell gray items, accept and turn in quests (gray quests are skipped, several reward choices stay manual unless you let it pick the most valuable), accept shared quests, skip gossip with a single option and decline trades, group and guild invites and duels.
- **Warnings** (settings): bags almost full, low durability, new spells at the trainer on even levels and low ammo for hunters (the last two not in Retail).
- **Food and camp reminders** (settings): remind you when you are not Well Fed (in WoW Forever food gives 5% more kill XP) or have no camp benefits while leveling.
- **Speedrun records**: compare your /played time at level 10, 20 and 60 with the fastest runs on speedrun.com (WoW Classic: Leveling, SSF Softcore), overall or for your class, in the split list and in History > Speedrun. Data: [speedrun.com](https://www.speedrun.com/wowclassicera).
- **Alerts** (settings): big on-screen messages for level up, rare and elite kills, epic loot and near deaths, each optional. No elite alerts in dungeons and raids, no loot alerts in raids.
- **Hide names** (settings): history shows no realm and lists other characters only as "Character 2, 3, ...".
- Settings, grouped into Window, Statistics and General: size, background opacity, show/lock window, reset position & size, one toggle per statistic, language (English, Deutsch, Français, Español) and the minimap button.

### Chat commands

| Command | Effect |
|---|---|
| `/lt` or `/lt config` | Open settings |
| `/lt history` | Open the history |
| `/lt lock` / `/lt unlock` | Lock or unlock the window position and size |
| `/lt reset` | Reset window position and size |
| `/lt compact` | Toggle compact mode (play time, XP bar and XP/h only) |
| `/lt bar` | Toggle horizontal bar layout (everything in one line, like an info bar) |
| `/lt newsession` | Archive the running session and start a new one (also a button in the settings) |
| `/lt stream` | Stream mode: alerts on, names hidden (window size and transparency unchanged); again restores your settings |
| `/lt splits` | Show or hide the split list (last levels with time and difference) |
| `/lt profile` | List profiles; `/lt profile Name` switches, `save Name`, `delete Name`, `export`, `import` (also in Settings > Profiles) |
| `/lt runs backup` / `/lt runs import` | Copy all runs as text, or paste runs shared by others (also buttons in History > Speedrun) |
| `/lt compare pb` | Splits against your personal best run (`best` = best time per level, or a character name) |
| `/lt recap` | Session summary card: time, levels, XP, kills, deaths, best loot, most dangerous enemy |
| `/lt goal 30` | Set a goal level with progress and forecast in the window; `/lt goal` shows it, `/lt goal off` removes it |
| `/lt show` / `/lt hide` | Show or hide the window |
| `/lt sync` | Re-sync play time with the server |
| `/lt minimap` | Toggle the minimap button |
| `/lt debug` | Extended logging in chat until /reload; `/lt debug help` lists test commands (state, levelup, alert, remind, death, splits) |

`/leveltimer` works as an alias for `/lt`.

## Level Time Goals

A second addon in this repository for streamers: set goals and show them as cards on screen, with a history. Goal types: reach a level, kill N enemies (all, PvE or PvP, optionally only in battlegrounds), loot an item, win N battlegrounds. It reuses the building blocks of Level Time (cards, alerts, tables), so **Level Time must be installed too**. Open it with `/sg`; `/sg help` lists the commands (for example `/sg add level 20`, `/sg add item <link> 3`, `/sg add bgwin 3 Arathi`).

## Installation

Requirements: [Go](https://go.dev/) 1.23+ and `make`.

```sh
make install    # interactive wizard
```

The wizard finds your WoW folder, lists the installed game versions, shows what it will copy, update or remove, and asks for confirmation. It only writes to `Interface/AddOns/LevelTimer` and `Interface/AddOns/StreamGoal` (pass `ARGS="-addons LevelTimer"` to skip Level Time Goals). Your settings (`WTF/` SavedVariables) are never touched. Older manual installs are migrated automatically.

Other targets:

```sh
make update     # update every game version that already has the addon, no prompts
make dry-run    # only show what would happen
make package    # build dist/LevelTimer-<version>.zip
make test       # run all tests (addon scenarios + installer)
```

Extra options go through `ARGS`, e.g. `make install ARGS="-flavors retail,classic_era"` or `ARGS="-wow 'D:/Games/World of Warcraft'"`. You can also set `WOW_DIR`.

After installing: restart the WoW client if the addon is new or its file list changed, otherwise `/reload` is enough.

Manual install: run `make package` (or download a release) and unzip it into `<WoW>/_<version>_/Interface/AddOns/`. The zip contains the `LevelTimer` folder; the folder must keep that name.

## Development

```sh
make test         # addon scenarios + installer tests
make test-addon   # only the addon scenarios
make artwork      # regenerate logo (curseforge/logo.png) and icon (Media/Icon.tga)
```

The addon tests run without the game: `tests/wow_stub.lua` fakes the parts of the WoW API the addon uses, and each `tests/*_test.lua` plays through one scenario (login, kills, deaths, level-up, ...) in a fresh Lua 5.1 state. They check the logic, not the rendering, so a quick check in game is still worthwhile.

## Releasing

Push a version tag, everything else runs automatically:

```sh
git tag v1.0.0
git push origin v1.0.0
```

The GitHub Action `.github/workflows/release.yml` runs all tests, then the [BigWigs packager](https://github.com/BigWigsMods/packager) builds the zip (version from the tag, files per `.pkgmeta`), creates a GitHub release with a changelog and uploads the file to CurseForge.

One-time setup for the CurseForge upload:

1. Add the project ID from the CurseForge project page to `LevelTimer.toc`: `## X-Curse-Project-ID: 123456`
2. Create an API token at <https://legacy.curseforge.com/account/api-tokens> and save it in the GitHub repository as secret `CF_API_KEY` (Settings → Secrets and variables → Actions).

Level Time Goals has its own CurseForge project (ID in `StreamGoal/StreamGoal.toc`, config in `StreamGoal/.pkgmeta`) and is packaged by a second packager step from a clone whose root is `StreamGoal/` (history split with `git filter-branch`, packager `-t sg-repo`) on the same tag, using the same `CF_API_KEY`.

Without these, the action still creates the GitHub release with the zip.
