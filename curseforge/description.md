# Level Time

See how your leveling is really going. Level Time tracks play time, XP per hour, kills, deaths, quests and gold for your **current level**, your **current session** and the **instance** you are in, and keeps a history of every level, session and run for all of your characters. On top come speedrun splits, alerts and reminders, and a set of optional quality-of-life features.

**Works on Retail, Classic Era, TBC Anniversary and WoW Forever** from one download. Features a game version cannot provide stay off quietly. Available in English, German, French and Spanish.

## Highlights

- Live window with play time synced to `/played`, XP bar, XP/h, kills/h, items/h, time to level and max level, kills, deaths and more; every row can be switched on or off
- Seven layouts (table, bar, compact, text only, clock, XP bar, tiles), themes, fonts and an edit mode to place every display with grid and snapping
- Hide any Blizzard HUD element right from the edit mode
- History for every character: levels, sessions, kills, deaths with cause, quests, loot, instances, zones, reputation, money, personal records
- Charts: time and XP/h per level, kills per day, top enemies, death causes, play time per day/week, when you play (heatmap), progress curve
- Speedrun splits like LiveSplit: gold splits, PB and best-per-level comparison, bracket forecast, own splits, quest splits, speedrun.com records, LiveSplit export
- Level-up window with stat gains and the new abilities from your class trainer
- Alerts and reminders: rare/elite kills, epic loot, near deaths, missing food/class buffs, full bags, low durability, breath, breaks, instance limit
- Healer callouts to your group: low mana, crowd control, aggro
- Comfort features in the spirit of Leatrix Plus (own code, all off by default): automation, social, chat, interface, frames, system, loot roll counters, flight times
- Easy to start: simple mode for new players ("Show all options" shows everything), tooltips on every option, value and column, greyed-out options that depend on another, short `/lt help` (`/lt help all` for everything)
- Settings with a sidebar per tab, a search box, reset per page, a welcome card on first start and an entry under Options > AddOns; right-click any display to open its settings
- Quest helpers: quest levels, progress on quest markers, learned quest mobs and NPCs with map pins, quest item and target buttons, quest XP on the XP bar, reward hints, loot sparkles
- Stream-friendly: stream mode, chroma-key background for OBS, hidden names, session recap card

## Live window and statistics

A small, movable window shows one scope at a time: **Level N | Session | Instance** (tabs; optionally switches to Instance automatically when you enter one).

- **Play time** on this level (from the server's `/played`, correct even if you install mid-level) or in this session, counted up live
- **XP bar** with rested bonus; optionally the XP of quests ready to turn in as a yellow part. Hover it for exact numbers: current/required XP, XP missing, rested XP and quest XP
- **Experience**: XP per hour, current XP/h (last 15 minutes), gained XP, time to level up, time to max level, kills to level, quests to level, quest XP in your quest log
- **Progress**: splits against your comparison, goal level with progress and forecast (`/lt goal 30`)
- **Combat**: PvE kills (every kill that gave XP, group kills included), kills per hour, kills in the last 15 minutes and their rate, PvP honorable kills, elite and rare kills, deaths with time spent dead, kills per death, near deaths, time without death (for hardcore)
- **XP sources**: kills, quests, exploring, gathering and other; XP by location (world, dungeon, raid, battleground); rested XP gained and rested XP left
- **Loot**: items looted (all qualities, stacks by quantity, purchases excluded), items per hour, items in the last 15 minutes
- **Time, quests and money**: time breakdown (combat, flight paths, AFK, rest), quests turned in, income, income by kind (loot, quests, merchants, mail, auction house, trade) with gold per hour, spending (repairs, merchants, flights, trainers), reputation and reputation per hour
- **Instance**: time and XP of the running dungeon or raid visit (leaving and coming back continues it), instance limit (new instances in the last hour per realm and when the next slot frees up), instances today
- **Presets** Minimal, Leveling, Dungeon and Farming, with undo; free row order
- **Calculation**: XP/h without AFK time, idle time without XP can be left out (off by default), average for kills/quests to level adjustable
- **Layouts**: table, info bar (one line), compact (time, XP bar and up to 3 values you choose), text only (no background, outlined, great for OBS), clock (big play time), slim XP bar with text always/on hover/never, tiles grid
- **Visibility rules** for the window and the split list: always, out of combat, in combat, in instances only, hidden at max level, on mouseover; fade to any transparency instead of hiding
- **Look**: themes Classic, Flat, Minimal and Colorblind, accent color, font, size, outline, minimum font size, bar textures (own, Blizzard or LibSharedMedia) and optional value colors (XP/h against your average) for every Level Time display
- **Edit mode** (`/lt edit`, Shift-right-click on the minimap button): all displays at once with sample data; drag, mouse wheel to scale, arrow keys to nudge, grid and snapping, right-click menu. `/lt reset` and lock apply to every display
- **Level-up summary** in chat (on by default), optional announcement to party or guild
- At login (on by default): a chat line about your last session, and which alts have become fully rested (estimated)
- **Data text** for Titan Panel, ElvUI, Bazooka and other LibDataBroker displays, when one of them is installed
- **Minimap button**: left-click settings, Shift-left-click history, right-click show/hide window. On Retail also in the addon compartment

A session runs from login to logout. A `/reload` or a short break (up to 5 minutes) continues it.

## History and charts

Open with `/lt history`, Shift-click on the minimap button or the button in the settings. Browse all your characters from any character. Seven tabs: Levels, Sessions, Journal, Analysis, Charts, Speedrun & Records, Compare.

- **Levels**: overview (time, XP/h, kills, deaths, quests, gold per level), timeline (when each level was reached, with `/played`), time split (combat, flying, AFK, dead), XP sources, personal records
- **Sessions**: start, duration, level range, XP/h, kills, deaths, quests and gold of every session
- **Journal**:
  - Kills: every creature and player with time, kind (PvE/PvP, elite, rare), level and zone
  - Deaths: time, cause (enemy and spell, falling, drowning, ...), level and zone. On Retail and WoW Forever the cause comes from the death recap
  - Quests and loot (rare and better, with likely source), with game tooltips on hover
  - Instances: every dungeon, raid and scenario run with duration, XP, XP/h, kills, deaths and reputation
  - Near deaths (Classic Era and TBC only, other clients keep health secret)
- **Zones** (XP/h, kills, deaths per zone, best first), **Reputation** per faction, **Money** per day, week and month
- **Compare**: all characters side by side, fastest leveler first, with tracking coverage and estimated rested XP
- **Charts**: time per level, XP/h per level, kills per day, top enemies, death causes, XP/h per zone, play time per day and per week, XP timeline of the session, when you play (weekday x hour heatmap), progress curve of all characters
- **Personal records** across all characters (most XP in 60 minutes, best session XP/h, biggest XP gain, best instance run, fastest level), optionally announced when you beat one
- Sort by any column, filter by text, **Total** row, smooth scrolling, **CSV export** of the visible rows
- **Delete data** removes a character's statistics

The journal has no fixed limit: older entries move into a small load-on-demand archive addon (`LevelTimer_Archive`, included).

## Speedrun and splits

Settings tab "Speedrun" and History > Speedrun & Records.

- **Split list** (`/lt splits`): a separate panel like LiveSplit with the running level and the last levels (3-15), total row and `/played` row
- **Comparison**: best time per level of your other characters, your personal best run (optionally same class only) or a chosen run (`/lt compare <name>`)
- **Gold splits** in purple with an optional chat line and sound, optional tolerance band (yellow)
- **Forecast** of the next bracket (1-10, 1-20, 1-60) against your PB, sum of best and the speedrun record
- **Speedrun records** from speedrun.com (WoW Classic, Leveling SSF softcore, overall or your class) compared with your `/played` at the bracket level. The addon has no internet access, so records ship as a snapshot with each update
- **Own splits** (`/lt split [name]`, undo, key binding under AddOns, template for new characters)
- **Quest splits**: time from accepting to turning in each quest, best time across characters, optional chat line
- **Runs**: your characters plus imported runs, favorites, share as text, back up all, import (`/lt runs import`)
- **Check code** per run against edited data (`/lt runs verify`), **coverage** (share of `/played` the addon actually recorded; partial levels never count as best times), **run category** detected automatically (SSF, solo, group, boosted)
- **LiveSplit export** as `.lss` (`/lt runs lss`)
- **Race against friends**: level times exchanged with other Level Time users in your group or when inspecting (off by default, nothing is sent while off)
- **SSF rule helper**: rested XP bars, logouts, instances per hour and a clock for your VOD; warns when trade, mail or the auction house opens (display only)
- **Milestone screenshots**: every 5 levels and at max level, first dungeon, epic loot (off by default)

## Notifications and warnings

Alerts and warnings appear as cards with icon, sharing one queue, size, duration and position (movable, banner or text style).

- **Alerts** (off by default): level up, rare kill, elite kill (not in dungeons/raids), epic loot (not in raids), near death (Classic Era/TBC)
- **Level-up window** (on by default): health, mana and stats before -> after, new talent points and the abilities your class trainer offers at the new level (learned once you visit the trainer; not on Retail). Themes Modern, Alliance and Horde, compact view, size, duration, sound; hides Blizzard's banner while on
- **Timers** (on by default where available): eating countdown until Well Fed, campfire countdown and hint (WoW Forever), sleeping bag rest countdown after /sleep with a notice for every Well Rested stack (WoW Forever), flight times with a countdown (flight timer off by default): your own measurements, times shipped with Level Time, the reverse direction or an estimate from the distance (marked with ~); the flight map tooltip shows the time for every destination
- **Leveling reminders** (off by default, repeat every 1-30 minutes, not in combat or rest areas): not Well Fed, no camp benefits (WoW Forever), rest in your Cozy Sleeping Bag for the XP bonus (WoW Forever), Skyborne charge missing (WoW Forever), class buffs of your own class (armor, intellect/fortitude buffs, shields, weapon enchants, poisons, pets, aspects, ...)
- **Break reminder** after a set play time (off by default)
- **Warnings** (off by default): bags almost full, low durability, visit trainer on even levels (not Retail), low ammo for hunters (adjustable thresholds and repeat), instance limit, aggro in a group, breath and fatigue running out, emergency highlight at low health (Classic Era/TBC: glows potion, healthstone and emergency spell buttons, red screen edge)
- **Group messages** (off by default, never while Blizzard locks the chat): quest progress with clickable quest links, instance report when you leave (duration, XP, kills, money), or any time with `/lt report`
- **Healer callouts** (off by default, healer role in dungeons and raids): low mana, crowd control (with kind and duration where the client tells it), all clear after CC, aggro on you. WoW Forever hides mana and CC details from addons, so there only "out of mana" and "can't heal" are possible

## Comfort

Settings tab "Comfort" with a sidebar like Leatrix Plus (all settings tabs have sidebars now, plus a search box). Everything is off by default; hold Shift to skip an automation once.

- **Automation**: repair automatically (guild bank first where available), sell junk, "Train all" button at trainers (not Retail); accept quests, accept shared quests, turn in quests, pick the most valuable reward, skip single-option gossip, own "never automatic" list (gray, PvP, repeatable and paid quests stay manual); accept summons (after 10 s), accept resurrections, release in battlegrounds
- **Social**: community members count as friends; decline trades, group invites, guild invites, duels and shared quests, block Battle.net friend requests; accept groups from friends and guild, invites with details in chat, invite on a whispered keyword
- **Chat**: copy button on every chat window (or `/lt copy`), chat font size for all windows, chat windows up to the screen edge, keep chat after `/reload`, hide drunk messages, hide spell links in combat, one group color; hide combat log tab, hide chat buttons, input box at the top, arrow keys without Alt, no chat fade
- **Interface**: black screen borders, quest text size; hide error messages and zone text; hide keybind and macro text, red when out of range; hide boss banner, event toasts, alerts, stance bar, rest animation and portrait numbers (where the client has them); move and scale Blizzard windows (Ctrl+mouse wheel); kill-quest markers on nameplates; loot sparkles; quest levels, quest item button, quest mob target button
- **Frames**: undress and tabard buttons in the dressing room, durability and volume slider in the character frame, square minimap, tooltip at the cursor, tooltip size, guild rank in tooltips, info card with ID and Wowhead link, class color, elite/rare dragon and druid mana bar on the Classic player frame, class colors on target and focus, tooltip with class colors and the unit's target, hide tooltips in combat, kills to level in the tooltip, minimap wheel zoom and hidden zoom/calendar buttons, coordinates and your deaths on the world map
- **Hide Blizzard UI**: player, target, focus, party, pet, boss and arena frames, cast bar, minimap, buffs, quest tracker, chat windows, action bars, micro menu, bag bar, XP and reputation bar and more. Toggle each one right on the element in edit mode or in the list; only made invisible and unclickable (no taint), never in combat
- **Loot rolls**: counters for Need, Greed, Pass (and Disenchant/Transmog) plus still deciding under Blizzard's roll frames, names in the tooltip; after you choose, the roll stays on a card with the item until the winner is known; optional result line in chat and in the loot journal; **roll history** of every group roll (who won what, with roll, choice and dungeon) under History > Journal > Rolls
- **System**: time left for ready checks and battleground invitations, faster looting, loot without confirmation, delete without typing, skip movies quickly, zoom out further, no drunken haze, no screen effects, weather density, silence emotes while resting, mute spell fizzle / city bells / mechanostriders, nameplates only in combat, remove raid restrictions, alphabetical addon list

Every change to game settings (CVars, chat colors, Blizzard frames) is reversible: turning a feature off restores your previous value.

## Quests

- **Quest levels** in the quest log, gossip and greeting lists, and the quest tracker on Classic: `[12]`, group quests `[12+]`
- **Quest item button** for the usable item of the nearest quest (Retail/WoW Forever by distance, Classic the most recently accepted), also items from your bags that belong to an open quest (handed over on accept or named in an objective), plus a **target button** for quest mobs on nameplates (also mobs you only loot from); framed as "Targets & items", drag it anywhere; optionally only for quests in your current zone
- **Kill-quest markers**: icon next to the nameplate of enemies and NPCs that belong to an active quest
- **Quest XP**: XP of quests in your log (ready and open), whether turning in is enough to level, optionally shown on the XP bar
- **Progress on markers** ("3/8") next to quest mobs, read from the game's tooltip
- **Learns quest mobs, items and quest NPCs** as you play (account-wide, no shipped database): markers on Classic where the game has no quest info for units, quest item line in item tooltips, quest givers and turn-ins as pins on the world map
- **Target button** with learned names and an optional skull marker (secure macro, changed only out of combat)
- **Alerts** when a quest or an objective is complete, **rare mob** alert with optional screen flash
- **Quest log helpers**: remove gray quests with one click (always asks first), notice when the log is almost full, leftover quest items in your bags
- **History > Analysis**: turn-in overview with XP, quest efficiency (XP per minute from quest splits); reward recommendation by sell value and item level
- **Corpse arrow** with distance while you are a ghost
- **Quest progress to group** with quest links, **quest splits** (see Speedrun), quest automation (see Comfort)
- **Loot sparkles**: quest items keep the game's sparkle even after a graphics preset (WoW Forever); ore veins, herbs, quest objects and corpses with loot glint as you approach (dim out of reach, bright in reach, grey when your skill is too low). Uses the game's soft targeting; corpses only after combat. Stays off while ForeverLootSparkles or Lueur is loaded

## Streaming

- **Stream mode** (`/lt stream`): turns on the big alerts and hidden names at once; turning it off restores your previous settings
- **Chroma background**: solid green or magenta without border for keying out the window in OBS
- **Hide names**: no realm, other characters only as "Character 2, 3, ..." (also in exports)
- **Deaths in red** (on by default), hide the minimap button
- **Session summary card** (`/lt recap`): time, levels, XP, kills, deaths, best loot and most dangerous enemy; updates while open and follows the chroma background
- **Start new session** (button or `/lt newsession`), e.g. at the start of a stream

## Profiles, import and export

- Named **profiles** for all settings, chosen per character; save, switch, delete
- **Export/import** profiles and runs as text (copy with Ctrl+C, paste into the import window), e.g. between clients or accounts
- **CSV export** of every history table, LiveSplit `.lss` export

Addons cannot write files, so copying text is the only way out of the game.

## Commands

`/leveltimer` works as an alias for `/lt`.

| Command | Effect |
|---|---|
| `/lt` or `/lt config` | Open the settings |
| `/lt help` | List all commands |
| `/lt show` / `/lt hide` | Show or hide the window |
| `/lt lock` / `/lt unlock` | Lock or unlock window position and size |
| `/lt edit` | Edit mode: move, scale and hide all displays and Blizzard UI elements |
| `/lt welcome` | Show the welcome card again |
| `/lt reset` | Reset position and size of every display |
| `/lt compact` | Switch between the compact and the table layout |
| `/lt bar` | Switch between the bar and the table layout |
| `/lt splits` | Show or hide the split list |
| `/lt stream` | Toggle stream mode |
| `/lt history` | Open the history |
| `/lt recap` | Session summary card |
| `/lt newsession` | Archive the running session and start a new one |
| `/lt resetinstance` | Reset the data of the running instance visit (not the game's instance reset) |
| `/lt goal 30` | Set a goal level; `/lt goal` shows it, `/lt goal off` removes it |
| `/lt compare best` / `pb` / `<name>` | Splits against best per level, your personal best or a chosen run |
| `/lt split [name]` / `undo` / `template` | Set an own split, undo the last one, save this character's splits as template |
| `/lt runs import` / `backup` / `verify` / `lss` | Import runs, copy all runs, recompute check codes, LiveSplit export |
| `/lt profile` | List profiles; `/lt profile <name>` switches, `save <name>`, `delete <name>`, `export`, `import` |
| `/lt copy` | Copy the lines of the current chat window |
| `/lt sync` | Request `/played` from the server again |
| `/lt minimap` | Toggle the minimap button |
| `/lt debug` | Extended chat logging until `/reload`; `/lt debug help` lists test commands, `/lt debug log` keeps a persistent log for bug reports, `/lt debug check` runs all client checks, `/lt debug perf` measures the addon's CPU time |

## Good to know

- Statistics are recorded per character and stored account-wide, so the history can show and compare all of your characters.
- Play time and XP/h use the server's values, so the current level is right from the start. Kills, deaths and quests count from the moment the addon is installed.
- PvE kills are kills that gave you experience; gray mobs and kills at max level don't count.
- Retail and WoW Forever hide some values from addons ("secret values"), e.g. health, mana, combat log and some chat messages in combat. Level Time works around this where possible (e.g. death cause from the death recap, kill XP from XP changes) and turns features off where it cannot, such as near deaths and the emergency highlight.
- Some features exist only on some clients: campfire and sleeping bag timers and the Skyborne reminder on WoW Forever, trainer features and ammo warnings outside Retail, time-to-max-level from the XP table on Classic clients (Retail uses your recent level times).
- No libraries are bundled. The data text appears when another addon provides LibDataBroker.
- Sister addon for streamers: [Level Time Goals](https://www.curseforge.com/wow/addons/streamer-goals) shows goals (reach a level, kill N enemies, loot items, win battlegrounds, custom goals) as cards on screen. Needs Level Time.

## Feedback

Bugs and ideas: [GitHub issues](https://github.com/Noobygames/level-time/issues). For bug reports, `/lt debug log` followed by a `/reload` writes a log to your SavedVariables that helps a lot.
