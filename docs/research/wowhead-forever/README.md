# Wowhead WoW Forever research (2026-11-17)

Raw findings per dungeon, extracted from https://www.wowhead.com/forever/guide/dungeons-overview-locations-details (guide 34783), each dungeon guide (`/forever/guide=<id>`) and each dungeon-journal page (`/forever/dungeon-journal/<slug>`). Each file: journal data (levels, quests with levels, bosses with NPC ids, abilities with spell ids and descriptions, loot, Forever changes vs classic), full guide text (strategy, trash, quests, prerequisites), and a comparison against `Assist/InstanceData/mechanics.lua` and `dungeon_db.lua` questInfo.

- `_overview.md` level table and Forever-only dungeons without guide (Krol'dok Stronghold, Blackmaw Hold, Shaper's Terrace)
- `_quest-pages.md` single quest pages (about 35 quests) and spell/NPC findings
- Method: guide pages carry their text in a `<noscript>` block and the journal in a JSON script tag (plain HTTP GET works; `/npc=` and `/quest=` return CloudFront 403 to curl).
- Wowhead text is third-party; reformulate in own words before shipping, update `sources.md`.
- `krol-dok-stronghold.md` guide 35346 (found via search, not linked from overview)
- Round 3 (guide index, all-dungeon-quest list, transport, roadmap, systems, camping): `_round3-findings.md` and files listed there
