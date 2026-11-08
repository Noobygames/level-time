# Level Time Goals

Set goals for your stream and show them as cards on screen. Viewers see at a glance what you are working on and how far along you are; when a goal is reached you get a big on-screen alert.

**Requires [Level Time](https://www.curseforge.com/wow/addons/level-time).** Level Time Goals builds on its cards, alerts, themes and tables, so install both.

## Goal types

- **Reach a level**: "Level 30 today"
- **Kill enemies**: N kills, all, PvE only or PvP only, optionally only in battlegrounds
- **Loot an item** or **own an item**: N looted, or N in your bags (optionally with the bank)
- **Gold**: earn N gold or own N gold
- **Quests**: turn in N quests, one specific quest or a chain in order (quest IDs or links)
- **Profession**: reach a skill rank
- **Exploration**: discover N areas or reach a zone
- **Bosses**: defeat N bosses, a named boss or bosses in one instance
- **Reputation**: gain N reputation or reach a standing with a faction
- **Achievement** (clients with achievements) and **honor**
- **Win battlegrounds**: N wins, optionally for one battleground
- **Rules that can fail**: no death, no trade/mail/auction house, no flight paths, naked, no healing potions, until a level or a deadline
- **Checklists** with your own items and other goals as sub-goals
- **Bingo**: 3×3 or 5×5 cards whose fields tick themselves, BINGO alert and optional group announcement. Fill the fields yourself (built-in or own goals, or type a text) or let empty fields fill at random
- **Free text**: anything you like, with or without a counter you click up yourself

## Extras for every goal

- **Deadline** in real time or played time, countdown on the card, "failed" when it runs out
- **Daily or weekly** goals that renew themselves, with a streak
- **Reward text and points**, shown on the card and in the alert, total points in the history
- **Own goals**: save any goal from the form as your own, reuse it on bingo cards and the wheel
- **Packs**: built-in sets (Hardcore start, Self-found, Dungeon tour, Explorer), save your running goals as a pack
- **Collection**: packs and own goals in one place, share them as text and import with one button
- **Wheel of fortune**: a real spinning wheel picks your next goal; choose which built-in and own goals are on it, limited rerolls, optionally on every level-up, animation can be turned off

## Features

- **Live cards** in the look of your Level Time theme, stacked in one tracker; move and scale them in Level Time's edit mode, right-click for settings
- **Settings window** (`/sg options`) with search: number of cards, card colors, size, sound, alert, chat line, own pages for bingo and the wheel, clean-up of goals from deleted characters
- **Minimap button**: left click opens the window, Shift+left the history, right click the settings, Shift+right edit mode; the tooltip lists your running goals. Turn it off under Settings > Tracker or with `/sg minimap`
- **History**: every finished, cancelled or failed goal in a table you can filter, sort and export as CSV
- **Window** (`/sg`): tabs Goals (form for every goal type, extras behind "More options", active goals), Bingo, Wheel, Collection and History
- Languages follow Level Time: English, German, French, Spanish
- Works with the same game versions as Level Time

## Commands

| Command                                          | Effect                                          |
| ------------------------------------------------ | ----------------------------------------------- |
| `/sg`                                            | Open the window                                 |
| `/sg options`                                    | Open the settings                               |
| `/sg help`                                       | List all commands and goal types                |
| `/sg add level 20`                               | Goal: reach level 20                            |
| `/sg add kills 50 pve`                           | Goal: 50 PvE kills                              |
| `/sg add gold 100 [own]`                         | Goal: earn (or own) 100 gold                    |
| `/sg add quest 10` / `/sg add quest <links>`     | Goal: 10 quests, or these quests in order       |
| `/sg add rule nodeath 30`                        | Rule: no death until level 30                   |
| `/sg bingo 3` / `/sg bingo edit`                 | Random bingo card / fill a card yourself        |
| `/sg wheel` / `/sg wheel edit`                   | Spin the wheel / choose its entries             |
| `/sg own add <text>` / `/sg own share`           | Add an own goal / share your own goals          |
| `/sg import` / `/sg collection`                  | Import a pack or own goals / open the collection|
| `/sg deadline <Nr> 2h [played]`                  | Add a deadline to a goal                        |
| `/sg repeat <Nr> daily`                          | Renew a goal every day                          |
| `/sg pack hardcore`                              | Add a built-in pack                             |
| `/sg list` / `/sg cancel <Nr>` / `/sg history`   | List active goals, cancel one, show the history |
| `/sg tracker` / `/sg move` / `/sg scale <0.5-2>` | Show or hide, move and resize the cards         |
| `/sg minimap`                                    | Show or hide the minimap button                 |

`/streamgoal` works as an alias for `/sg`.

## Good to know

- Goals belong to the character that was active when you created them; only that character progresses them.
- Up to six goals run at once per character (bingo fields don't count).

## Feedback

Bugs and ideas: [GitHub issues](https://github.com/Noobygames/wow-statistics/issues)
