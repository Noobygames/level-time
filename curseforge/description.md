# Level Time — The Ultimate Leveling, Statistics, Speedrun & QoL Suite

**Level Time** is far more than an XP tracker. It combines a highly customizable **Live HUD**, an account-wide **Character Chronicle & Charting Engine**, a built-in **LiveSplit-style Speedrun Timer**, smart **Quest & Hardcore Alerts**, and a complete **Quality-of-Life (Comfort) Suite** — all in a single, lightweight addon with zero external libraries.

Whether you are casually leveling an alt, pushing Hardcore survival, optimizing dungeon grinds, speedrunning to max level, or streaming your journey: **Level Time** adapts to your playstyle.

> **One Download for All Versions:** Works seamlessly on **Retail, Classic Era, TBC Anniversary, and WoW Forever**. Client-specific features activate automatically and stay quietly out of your way where unsupported[cite: 1].  
> **Languages:** English, German, French, Spanish[cite: 1].

---

## Why Level Time Stands Out (Core Pillars)

- **📊 Live HUD & 7 Display Layouts:** Track `/played`-synced level time, session time, and instance runs[cite: 1]. Switch between Table, Info Bar, Compact, Text-Only (OBS), Clock, Slim XP Bar, and Tiles[cite: 1]. Move, scale, and snap everything in a dedicated **Edit Mode** — and even hide native Blizzard UI elements with a click[cite: 1].
- **📖 Account-Wide History & Visual Charts:** Browse every character from anywhere[cite: 1]. Inspect detailed logs of every level, session, dungeon run, mob kill, death cause, rare loot drop, zone efficiency, and gold flow — backed by 9 interactive charts and heatmaps[cite: 1].
- **⏱️ Built-in Speedrun Splits & Records:** Native LiveSplit-style split panel with gold splits, PB/best-per-level comparisons, bracket forecasts, quest splits, SSF verification, `.lss` export, and built-in speedrun.com Classic records[cite: 1].
- **🧭 Smart Quest Assistant (Zero Bloat):** Displays quest levels, objective progress on nameplates, XP on your bar, and a dynamic Quest Item & Target button[cite: 1]. Dynamically learns quest mobs, items, and NPC map pins across your account as you play[cite: 1].
- **🛠️ Modular Comfort & UI Suite:** Over 70 optional quality-of-life tweaks inspired by Leatrix Plus (100% custom code, **all off by default**, fully reversible)[cite: 1]. Automates repairs, junk selling, and quests; enhances chat, tooltips, frames, and group loot roll tracking[cite: 1].
- **🔔 Alerts, Healer Callouts & Hardcore Safety:** Custom level-up windows showing newly available trainer skills, buff/food reminders, low-health emergency highlights, bag/durability warnings, and automatic healer mana/CC callouts[cite: 1].
- **🎥 Streamer-Ready Out of the Box:** One-command Stream Mode (`/lt stream`), built-in green/magenta Chroma Key backgrounds for OBS, character/realm name anonymization, and live Session Recap Cards[cite: 1].

---

## 📊 Live Window & Real-Time Statistics

A sleek, movable window tracks one scope at a time via quick tabs: **Level N | Session | Instance** (optionally auto-switching when you enter a dungeon or raid)[cite: 1]. A session persists across `/reload` and short disconnects up to 5 minutes[cite: 1].

### What You Can Track (Every Row Toggleable & Reorderable)

- **Time & Breakdown:** Exact time on current level (synced with server `/played`, accurate even if installed mid-level) and session time, broken down into combat, flight paths, AFK, and resting[cite: 1].
- **Experience & Pacing:** XP/h (overall and rolling last 15 min), gained XP, time to level, time to max level, kills to level, quests to level, and unsubmitted quest log XP[cite: 1].
- **Enhanced XP Bar:** Shows rested bonus and optional yellow preview for completed quests in your log[cite: 1]. Hover for exact values (current/needed XP, missing XP, rested & quest XP)[cite: 1].
- **XP Sources & Locations:** Breakdown by kills, quests, exploration, and gathering — plus location splits (open world, dungeon, raid, battleground) and rested XP gained/remaining[cite: 1].
- **Combat & Hardcore Metrics:** PvE kills (XP-yielding kills incl. group kills), kills/h, 15-min kill rate, PvP honorable kills, elite/rare kills, deaths with time spent dead, K/D ratio, **near deaths**, and **time survived without dying**[cite: 1].
- **Loot & Economy:** Items looted (stacked by quantity, excluding vendor purchases), items/h, 15-min loot rate[cite: 1]. Detailed income (loot, quests, vendors, mail, AH, trade) with Gold/h, plus expenses (repairs, vendors, flights, trainers) and Reputation/h[cite: 1].
- **Instance & Lockout Tracker:** Live duration and XP of the active run (pauses/resumes if you zone out and re-enter), daily instance count, and an **hourly realm instance lockout tracker** showing exactly when the next slot frees up[cite: 1].
- **Goals & Splits:** Live split delta against your comparison and custom target level forecast (`/lt goal 30`)[cite: 1].

### Customization, Layouts & Integration

- **7 Layouts:** Table, Info Bar (single line), Compact (time, XP bar + up to 3 metrics), Text Only (outlined, background-free for OBS), Clock (large timer), Slim XP Bar (text always/hover/never), and Tiles Grid[cite: 1].
- **4 Quick Presets:** _Minimal, Leveling, Dungeon,_ and _Farming_ (with undo support)[cite: 1].
- **Smart Calculation:** Automatically exclude AFK time or zero-XP idle periods from XP/h; adjustable rolling window for kills/quests to level[cite: 1].
- **Themes & Styling:** _Classic, Flat, Minimal,_ and _Colorblind_ themes[cite: 1]. Customize accent colors, fonts, outlines, bar textures (built-in, Blizzard, or LibSharedMedia), and dynamic value coloring (e.g., XP/h colored relative to your average)[cite: 1].
- **Smart Visibility Rules:** Show always, out of combat, in combat, in instances only, on mouseover, or hide at max level — with smooth fade-to-transparency instead of abrupt hiding[cite: 1].
- **Interactive Edit Mode (`/lt edit`):** View all displays with sample data simultaneously[cite: 1]. Drag, mouse-wheel scale, arrow-key nudge, align with grid & snapping, or configure via right-click[cite: 1].
- **Chat & Broker Integration:** Login recap of your last session + estimated alts that reached full rested XP; level-up chat summaries (with optional party/guild announce); native **LibDataBroker (LDB)** feed for Titan Panel, ElvUI, and Bazooka[cite: 1].

---

## 📖 Account-Wide History, Journal & Charts

Open via `/lt history` or `Shift + Left-Click` on the minimap button[cite: 1]. Inspect, sort, filter, and compare all characters across your account across **7 dedicated tabs**[cite: 1]:

1. **Levels:** Complete table of every level (time, XP/h, kills, deaths, quests, gold), exact timestamp & `/played` timeline, activity breakdown (combat/flight/AFK/dead), XP sources, and personal records[cite: 1].
2. **Sessions:** Full log of every play session with start time, duration, level range, XP/h, kills, deaths, quests, and gold[cite: 1].
3. **The Chronicle (Journal):**
   - **Kills:** Every creature and player with timestamp, type (PvE/PvP, Elite, Rare), level, and zone[cite: 1].
   - **Deaths:** Timestamp, level, zone, and exact cause (attacker + spell, falling, drowning, etc. — pulled directly from the Death Recap on Retail & WoW Forever)[cite: 1].
   - **Quests & Loot:** Every completed quest and rare+ item drop (with likely source) and interactive game tooltips on hover[cite: 1].
   - **Instances:** Every dungeon, raid, and scenario run with duration, XP, XP/h, kills, deaths, and reputation[cite: 1].
   - **Group Loot Rolls:** Complete history of every group roll (winner, item, roll value, choice, and dungeon)[cite: 1].
   - **Near Deaths:** Logged survival calls (Classic Era & TBC)[cite: 1].
4. **Analysis (Zones, Rep & Gold):** Best leveling zones ranked by XP/h, kills, and deaths; faction reputation gains; daily, weekly, and monthly gold balance[cite: 1]. Plus quest turn-in efficiency (XP/min) and reward value hints[cite: 1].
5. **9 Interactive Charts:** Time per level, XP/h per level, kills per day, top enemies, death causes, XP/h by zone, daily/weekly play time, session XP timeline, **Playtime Heatmap** (weekday × hour), and multi-character progress curves[cite: 1].
6. **Speedrun & Records:** All-time personal records across characters (best 60-min XP, peak session XP/h, biggest single XP drop, fastest level, best dungeon run) with optional on-screen record alerts[cite: 1].
7. **Character Compare:** Side-by-side comparison of all alts sorted by leveling speed, including tracking coverage percentage and live rested XP estimates[cite: 1].

_Note: Unlimited history without memory bloat — older journal entries automatically offload into the included load-on-demand archive module (`LevelTimer_Archive`)[cite: 1]. Every table supports text search, column sorting, and **CSV Export**[cite: 1]._

---

## ⏱️ Speedrunning & Splits

Turn WoW into a competitive speedrun environment via the **Speedrun** tab and `/lt splits`[cite: 1]:

- **LiveSplit-Style Panel:** Dedicated movable window showing your active level, the last 3–15 levels, total time, and server `/played`[cite: 1].
- **Flexible Comparisons:** Race against your best time per level across alts, your Personal Best (PB) run (all classes or same-class only), or any imported run (`/lt compare <name>`)[cite: 1].
- **Gold Splits & Forecasts:** Purple highlights, sound, and chat lines for record splits (with optional yellow tolerance band)[cite: 1]. Live pacing forecasts for 1–10, 1–20, and 1–60 brackets against your PB, Sum of Best, and world records[cite: 1].
- **Built-In Speedrun.com Records:** Offline snapshot of official _WoW Classic Leveling SSF Softcore_ records (overall and class-specific) compared directly against your `/played`[cite: 1].
- **Custom & Quest Splits:** Trigger custom splits via `/lt split [name]` or keybind (saveable as templates for new characters), plus automatic **Quest Splits** measuring exact time from quest accept to turn-in[cite: 1].
- **Verification, Integrity & LiveSplit Export:** Automatic run categorization (_SSF, Solo, Group, Boosted_), tracking coverage verification (partial levels never pollute best times), tamper-check codes (`/lt runs verify`), text sharing, and native **`.lss` export for LiveSplit** (`/lt runs lss`)[cite: 1].
- **Multiplayer Racing & SSF Helper:** Optional real-time split exchange with party members or inspected players[cite: 1]. Dedicated **SSF Rule Helper** displaying rested XP, logout counts, hourly instances, a VOD clock, and warnings if Trade, Mail, or AH windows open[cite: 1].
- **Auto-Screenshots:** Optional milestone captures every 5 levels, at max level, first dungeon entry, or epic loot drops[cite: 1].

---

## 🔔 Smart Alerts, Timers & Healer Callouts

All visual notifications share a clean, movable card queue with customizable icons, size, duration, and banner/text styling[cite: 1]:

- **Custom Level-Up Window:** Replaces Blizzard's banner with a detailed breakdown of HP, Mana, and stat gains (`Before -> After`), new talent points, and **newly unlockable skills waiting at your class trainer** (Classic/TBC/Forever)[cite: 1]. Includes _Modern, Alliance,_ and _Horde_ themes[cite: 1].
- **Buff, Rest & Flight Timers:**
  - Countdown for eating (_Well Fed_), plus **WoW Forever** exclusives: Campfire timer, Cozy Sleeping Bag `/sleep` rest countdown (with notifications per _Well Rested_ stack), and Skyborne charge reminders[cite: 1].
  - **Flight Path Timer:** Accurate countdowns using your recorded flights, built-in database, reverse-route calculation, or distance estimation (`~`), plus flight durations directly on flight map tooltips[cite: 1].
  - **Smart Buff Reminders:** Periodic out-of-combat reminders (every 1–30 min) for missing food buffs or class buffs (armors, Fortitude/Intellect, shields, weapon enchants, poisons, pets, aspects)[cite: 1].
- **Survival & Maintenance Warnings:** Almost full bags, low gear durability, trainer visit reminders on even levels, low hunter ammo, approaching instance lockouts, breath/fatigue timers, break reminders, and a **Low-Health Emergency Highlight** (flashes screen edges and glows healing potions, healthstones, and defensive spells on Classic Era/TBC)[cite: 1].
- **Group Reports & Healer Callouts:**
  - Automatic or manual (`/lt report`) dungeon summary on exit (duration, XP, kills, loot money) and clickable quest progress updates[cite: 1].
  - **Healer Protection:** Automatic party/raid warnings for low mana, active Crowd Control on you (with CC type and duration + "all clear" message when broken), and aggro alerts[cite: 1].

---

## 🧭 Dynamic Quest Assistant

Built-in questing enhancements that learn organically as you play — **no heavy static database required**[cite: 1]:

- **Actionable Quest HUD:** Movable _"Targets & Items"_ bar featuring a button for the nearest usable quest item (including items in your bags required for active objectives) and a **Quest Target Button** with optional Skull marker macro[cite: 1].
- **Nameplate & Tracker Upgrades:** Quest levels `[12]` / `[12+]` in logs, gossip, and trackers; kill-quest icons and live objective counters (`3/8`) right next to enemy nameplates[cite: 1].
- **Account-Wide Self-Learning:** Automatically records quest mobs, items, and quest givers/turn-ins across your characters — adding unit tooltips on Classic and placing quest pins on your World Map[cite: 1].
- **Loot Sparkles & Soft-Target Glint:** Keeps quest item sparkles active regardless of graphics presets (WoW Forever) and adds proximity glints to ore veins, herbs, quest objects, and lootable corpses (bright in range, dim out of range, grey if skill is too low)[cite: 1].
- **Log & Ghost Utilities:** One-click removal for gray quests (with confirmation), full-log warnings, leftover quest item detection, smart reward advisor (highest sell value / item level), and a **Corpse Arrow** with distance while dead[cite: 1].

---

## 🛠️ Comfort Suite (70+ Optional QoL Tweaks)

Located in the **Comfort** tab with a searchable sidebar[cite: 1]. **Every single option is disabled by default**, runs on 100% native code, and cleanly restores your previous CVars/settings if turned off[cite: 1]. _(Hold `Shift` anytime to bypass automations on the fly[cite: 1])._

- **Automation:** Auto-repair (guild bank support), auto-sell junk, _"Train All"_ button at class trainers; auto-accept/turn-in quests, smart reward selection, single-option gossip skip, and custom exclusion lists (ignores gray, PvP, repeatable, and paid quests); auto-accept summons (after 10s), resurrections, and BG spirit release[cite: 1].
- **Group Loot Roll Tracker:** Live counters for _Need, Greed, Pass, Disenchant,_ and _Transmog_ (plus undecided players) directly under Blizzard's roll frames[cite: 1]. Keeps a compact tracking card on screen after you roll until the winner is decided[cite: 1].
- **Chat Enhancements:** One-click Copy Chat button (`/lt copy`), global font sizing, edge-to-edge placement, persistent chat history across `/reload`, top input box, arrow-key navigation without `Alt`, and filters for drunk messages, combat spell links, chat buttons, or fade[cite: 1].
- **Interface & Frames:** Move and scale any Blizzard window (`Ctrl + Wheel`), square minimap with wheel zoom, coordinates & death pins on the world map, durability & volume sliders on the character sheet, undress/tabard buttons in the dressing room, and an instant **ID & Wowhead Link Card**[cite: 1].
- **Classic Frame Polish:** Class colors, elite/rare dragon borders, and Druid mana bars on the default player/target frames; cursor tooltips, class-colored tooltips, and "kills to level" directly in mob tooltips[cite: 1].
- **Hide Any Blizzard UI Element:** Taint-free hiding of player, target, focus, party, pet, boss, and arena frames, cast bars, minimap, buffs, quest tracker, chat, action bars, micro menu, bag bar, and XP/rep bars — toggleable directly inside `/lt edit`[cite: 1].
- **Social & System:** Auto-invite via whisper keyword, auto-accept friend/guild invites, block duels/trades/shared quests/BNet spam[cite: 1]. Faster auto-loot, bypass loot/delete confirmations, instant movie skip, extended camera zoom, mute annoying sounds (mechanostriders, city bells, spell fizzle, resting emotes), and ready-check/BG queue timers[cite: 1].

---

## 🎥 Streamer Tools & Profiles

- **One-Click Stream Mode (`/lt stream`):** Instantly enables large broadcast alerts and anonymizes character/realm names (restores normal settings when toggled off)[cite: 1].
- **OBS Chroma Keying:** Solid green or magenta borderless backgrounds for clean window keying[cite: 1].
- **Live Session Recap Card (`/lt recap`):** Broadcast-ready summary card showing session duration, levels gained, XP, kills, deaths, best drop, and deadliest enemy[cite: 1].
- **Profiles & Data Portability:** Save, switch, and export/import named settings profiles and speedrun records via text strings, plus `.csv` table exports and `.lss` LiveSplit files[cite: 1].

---

## ⌨️ Slash Commands

Use `/lt` or `/leveltimer`[cite: 1]. _(Tip: Every UI window can also be configured via Right-Click, or moved via `/lt edit`[cite: 1])._

<details>
<summary><strong>Click to expand all Slash Commands</strong></summary>

| Command                                            | Description                                                                           |
| :------------------------------------------------- | :------------------------------------------------------------------------------------ |
| `/lt` or `/lt config`                              | Open the settings menu (with search bar & per-page reset)[cite: 1]                    |
| `/lt edit`                                         | **Edit Mode:** Move, scale, snap, and hide Level Time & Blizzard UI elements[cite: 1] |
| `/lt history`                                      | Open the 7-tab Character Chronicle, Charts & Records window[cite: 1]                  |
| `/lt splits`                                       | Toggle the LiveSplit speedrun panel[cite: 1]                                          |
| `/lt recap`                                        | Open the live Session Summary Card[cite: 1]                                           |
| `/lt stream`                                       | Toggle Stream Mode (anonymize names + big alerts)[cite: 1]                            |
| `/lt show` / `/lt hide`                            | Show or hide the live statistics window[cite: 1]                                      |
| `/lt lock` / `/lt unlock`                          | Lock or unlock display positions[cite: 1]                                             |
| `/lt compact` / `/lt bar`                          | Quickly toggle between Table, Compact, and Info Bar layouts[cite: 1]                  |
| `/lt newsession`                                   | Archive the current session and start a fresh timer[cite: 1]                          |
| `/lt resetinstance`                                | Reset the active instance tracker (does not reset the game instance)[cite: 1]         |
| `/lt goal <level\|off>`                            | Set, view, or clear your target level forecast (e.g., `/lt goal 30`)[cite: 1]         |
| `/lt compare <best\|pb\|name>`                     | Set split comparison to best-per-level, PB, or a specific run[cite: 1]                |
| `/lt split [name\|undo\|template]`                 | Trigger a custom split, undo the last split, or save as template[cite: 1]             |
| `/lt runs <import\|backup\|verify\|lss>`           | Manage speedrun data, verify check codes, or export to LiveSplit[cite: 1]             |
| `/lt profile [name\|save\|delete\|export\|import]` | Manage and share settings profiles[cite: 1]                                           |
| `/lt copy`                                         | Copy text from the active chat window[cite: 1]                                        |
| `/lt report`                                       | Post an instance summary to your party chat[cite: 1]                                  |
| `/lt sync`                                         | Force a manual `/played` sync with the server[cite: 1]                                |
| `/lt minimap`                                      | Toggle the minimap button[cite: 1]                                                    |
| `/lt reset` / `/lt welcome`                        | Reset all display positions or reopen the welcome guide[cite: 1]                      |
| `/lt help` / `/lt debug`                           | Show command help or run diagnostics (`check`, `perf`, `log`)[cite: 1]                |

</details>

---

## 💡 Good to Know & Ecosystem

- **Account-Wide Intelligence:** Statistics are recorded per character and stored account-wide so you can compare alts at any time[cite: 1].
- **Instant Accuracy:** Level time and XP/h sync directly with the server's `/played` data, meaning your current level metrics are accurate even if you install the addon mid-level[cite: 1].
- **Client API Differences:** Retail and WoW Forever restrict certain combat values ("secret values" like enemy health/mana or combat log events)[cite: 1]. Level Time automatically uses smart fallbacks (like reading the native Death Recap or XP diffs) and cleanly hides unsupported metrics (like Near Deaths on Retail)[cite: 1].
- **Sister Addon for Streamers:** Pair with **[Level Time Goals](https://www.curseforge.com/wow/addons/streamer-goals)** to display interactive on-screen goal cards (reach level X, kill N mobs, loot items, win BGs, or custom challenges)[cite: 1].
- **Feedback & Bug Reports:** Found a bug or have a feature request? Visit [GitHub Issues](https://github.com/Noobygames/wow-statistics/issues)[cite: 1]. Running `/lt debug log` followed by `/reload` saves a diagnostic log to your `SavedVariables` to help resolve issues quickly[cite: 1].
