# Level Time Goals

Set goals for your stream and show them as cards on screen. Viewers see at a glance what you are working on and how far along you are; when a goal is reached you get a big on-screen alert.

**Requires [Level Time](https://www.curseforge.com/wow/addons/level-time).** Level Time Goals builds on its cards, alerts and tables, so install both.

## Goal types

- **Reach a level**: "Level 30 today"
- **Kill enemies**: N kills, all, PvE only or PvP only, optionally only in battlegrounds
- **Loot an item**: paste an item link or ID, set an amount, add a note such as the boss or source
- **Win battlegrounds**: N wins, optionally for one battleground (counted once per match; losses, draws and arenas don't count)

## Features

- **Live cards**: title, progress ("3 / 5") and a bar for every active goal, stacked in one movable tracker
- **Goal reached**: alert in the style of Level Time plus a chat line
- **History**: every finished or cancelled goal in a table you can filter, sort and export as CSV
- **Window** (`/sg`): form to create goals, list of active goals, history
- Languages follow Level Time: English, German, French, Spanish
- Works with the same game versions as Level Time

## Commands

| Command                                          | Effect                                          |
| ------------------------------------------------ | ----------------------------------------------- |
| `/sg`                                            | Open the window                                 |
| `/sg help`                                       | List all commands                               |
| `/sg add level 20`                               | Goal: reach level 20                            |
| `/sg add kills 50 pve`                           | Goal: 50 PvE kills                              |
| `/sg add item <link> 3`                          | Goal: loot an item three times                  |
| `/sg add bgwin 3 Arathi`                         | Goal: win 3 Arathi Basin battlegrounds          |
| `/sg list` / `/sg cancel <Nr>` / `/sg history`   | List active goals, cancel one, show the history |
| `/sg tracker` / `/sg move` / `/sg scale <0.5-2>` | Show or hide, move and resize the cards         |

`/streamgoal` works as an alias for `/sg`.

## Good to know

- Goals belong to the character that was active when you created them; only that character progresses them.
- Bosses at max level give no XP, so kills of them are not seen by the kill counter yet.

## Feedback

Bugs and ideas: [GitHub issues](https://github.com/Noobygames/wow-statistics/issues)
