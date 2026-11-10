# Notizen: Beute, Wuerfe, Leuchteffekte

Wortgetreu aus CLAUDE.md ausgelagert. Vor dem Aendern eines Moduls hier nach dem Dateinamen suchen und nur den passenden Abschnitt lesen.

### Loot sparkles (roadmap 330)

- `Assist/LootTarget.lua` classifies the soft-interact target (cursor via `SetUnitCursorTexture` into a probe texture, `CanLootUnit`, `UnitIsInInteractRange` Forever-only, quest objects via `UnitIsRelatedToActiveQuest`/tooltip/objective names); debug check `lootSparkles.target` logs raw cursor file ID/path/atlas.
- `UI/LootSparkle.lua`: AnimationGroups only (no OnUpdate), `Media/Glint.tga` from `tools/artwork -glint`.
- `Assist/LootSparkles.lua`: settings `lootSparkleQuestItems` (Forever CVar `outlineModeShowLootEffectWhenDisabled`, off needs a restart), `lootSparkleOre/Herbs/QuestObjects/Corpses`, `lootSparkleScale`; CVars via CVars.lua (`SoftTargetNameplateInteract` Override = open / Restore = player value; "once" CVars guarded with `CVars.IsOverridden`); no CVar writes in combat lockdown; inert while ForeverLootSparkles or Lueur is loaded.

### Loot rolls (roadmap 364)

- `Tracking/LootRolls.lua`: sources old (Era/TBC) or new (Retail/Forever, drop field `lootListID`/`lootListKey`) `C_LootHistory`, then `CHAT_MSG_LOOT` lines; history data replaces chat-derived state. `LootRolls.ParseChat`, `ArgumentRoles` (link number after `lootHistory:`, `%d` = roll), `Counts`, `NamesOf(roll, kind|"waiting")`, `ClassOf`, `OnChange`/`OnComplete`.
- `UI/LootRollDisplay.lua` (counter row under `GroupLootFrame1..4` via HookScript, `RowOf`, `CountsLine`, `IconText`; fallback card frame id `lootRolls`, preview = sample rolls), `Assist/LootRollReport.lua` (`SummaryText`, `ColoredName`, `KindLabel`), `Journal.SetLootRoll` (lootLog fields `rollChoice, roll, rollNeed, rollGreed, rollPass, rollDisenchant, rollTransmog`). Settings `lootRollCounts/Names/Summary/Journal` (Comfort > System).
- `hideBlizzardXpBar`/`hideBlizzardRepBar` (`HideFrames.ApplyStatusBars`): all flavors use `StatusTrackingBarManager` (two containers, one bar per kind in `container.bars[BarsEnum]`). Only alpha 0 + mouse off on bars, `ExhaustionTick` and container art (only while the container shows a hidden kind); never the container (Blizzard animates its alpha). Re-apply via `hooksecurefunc(container, "ApplyPendingBarToShow")`, out of combat; Forever re-applies on ADDON_LOADED `Blizzard_StatusTrackingBar`. Legacy fallback `MainMenuExpBar`/`ReputationWatchBar`. Edit mode toolbar `xpBarCheck`. Check `365.blizzardXpBar`.

### Sparkle styles (roadmap 456)

- `UI/LootSparkle.lua`: layers `halo`, `ring1`/`ring2`, `arcs`, `beam`, `sigil`, `flash` plus a dark `BLEND` shade; `lootSparkleStyle` (`aura`, `beam`, `sigil`, `ripple`, `sparkle`, `subtle`) picks the active layers (`STYLE_LAYERS`, `ActiveLayerNames`), colors per category (`ColorFor`), `SetState` far (alpha 0.5) / ready (flash) / locked (grey, arcs/sigil/ring2 frozen). Chooser in Comfort > World. A running preview survives settings changes (`LootSparkles` release skips while `LootSparkle.IsPreviewing()`).
