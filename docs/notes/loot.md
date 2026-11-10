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

### Sparkle styles v2 (roadmap 466, 471, 474, 475; ground styles below)

- Daten statt Code: `UI/LootSparkleStyles.lua` (`STYLES` = Schichten/`glints`/`shade`/`group` je Stil, `ORDER`, `DEFAULT` = `finder`, `LAYERS` = Texturen mit `size/sizes/point/blend/animation/readyAnimation/states/color/whiten/alpha/freezeLocked`, `SymbolCoords`), `UI/LootSparkleAnimations.lua` (Fabriken je Name: halo, ring, arcs, bob, hop, snap, glowPulse, shadowArrow...), `UI/LootSparkle.lua` = Engine (`applyLayers`, `syncGlints`, `playReadyAnimations`). Neuer Stil = Eintrag in `STYLES`+`ORDER` (+ neue `LAYERS`/Animation/Locale `LOOT_SPARKLE_STYLE_<ID>`).
- Stile: `finder` (Standard, Klammern weit 84 px / bereit 56 px mit Überschwingen / gesperrt gestrichelt), `arrow`, `glitter` (nur Funken), `symbol` (Atlas 4x2, Zelle je Kategorie), Gruppe "classic" = die Stile aus 456 (Anzeige "Klassisch: %s"). Funken (`glints`) und Bodenschatten (`shade`) nur, wo der Stil sie verlangt.
- Aufbau für Tiefe: flacher Kontaktschatten (halo, BLEND, schwarz), dunkler weicher Rand (BLEND), Leuchtrand (ADD), Körper (BLEND, `whiten` zu Weiß). Boden-Ellipsen in der Höhe gestaucht (ring1/ring2/shadow); aufrechte Teile bleiben aufrecht.
- Texturen (`tools/artwork/sparkle_shapes.go`): 4x-Supersampling, `blurAlpha` für Leuchtränder, Symbole eigene Zeichnung (keine Blizzard-Atlanten wegen Flavor-Unterschieden). `go -C tools/artwork run . -sparkle-preview Datei.png` = Kontaktbogen auf Gras/Schnee/Sand (Werte in `sparkle_preview.go` spiegeln die Lua-Daten, von Hand nachziehen).
- Einstellungs-Migration v8: gespeichertes `lootSparkleStyle == "aura"` (alter Standard) -> `finder` (auch Profile); Auswahl = `addCycle` (Zyklus-Button) in `ComfortWorld.lua`.
- Polish (Kontaktbogen-Review): Körper-Texturen tragen Licht/Schatten im Grauwert (`sparkle_shading.go`: `bevelLight`, `morph`, `blur`), dazu je Form `*Outline` (BLEND schwarz), `*Glow` (ADD), `BracketCore`; Boden (`shadow`, `groundRing`, `groundArrow/Symbol`) am Fuß y -24, Pfeil = Kristall mit `trail`, Symbol auf `badge`; Glitzer-Sterne mit `glintRim` (dunkler Umriss + weißer Kern als `glint.extras`, gleiche Zeiten wie der Stern). Vorschau hat vier Hintergründe (Gras, Schnee, Sand, Höhle).

### Sparkle ground styles (roadmap 467, 468, 476)

- Stile `clock`, `progress`, `pillar` (Gruppe shapes), Texturen aus `tools/artwork/sparkle_ground.go`. Kreise liegen in quadratischen Texturen und werden per Schichtgröße auf 100 x 40 gestaucht (Bodenellipse am Fuß, `GROUND_ELLIPSE`); `clock`/`progress` sitzen auf `shadowWide`.
- Erzeugte Schichten: `GROUND_LAYERS` in `LootSparkleStyles.lua` (Zeigerstellungen `clockHand1..16`, Segmente `progressSeg1..16`, `pillarRing1..3`, `pillarMote1..5`), vor `flash` einsortiert. Atlas-Zellen: `cell = i` + `Styles.CellCoords` (4 x 4), Parameter `index/delay/rise/drift` gehen an die Animationsfabrik.
- Neue Engine-Felder: `stateAlpha` (Grunddeckkraft je Zustand, in `applyLayers`), `animStates` (Dauer-Animation nur in diesen Zuständen), `cell`. Fabriken geben bei Bedarf `nil` zurück (Segmente 11 bis 16 in "weit").
- Zeiger kriecht per Überblenden von 16 Stellungen (Rotation + Stauchung ohne OnUpdate nicht möglich); Schleifenlängen sind über Pausen-Animationen für alle Schichten gleich (`alphaSequence`, `lightRing`, `mote`), damit versetzte Starts nicht driften.
- Fortschritt ohne Cooldown-Frame (SetSwipeTexture je Flavor nicht belegbar, OmniCC hängt Zahlen an): "weit" füllt zehn Segmente in Schleife, "bereit" ist voll (Pop-Welle). Es wird kein Abstand gemessen.
- Kontaktbogen: `-sparkle-preview` zeigt die drei Stile (Spiegel der Werte von Hand pflegen).

### Sparkle scene styles (roadmap 469, 470, 472, 473)

- Ziel der "Eigene Sparkle-Stile": eigene Formsprache statt Glow (456 erinnerte zu sehr an Lueur); Standard `finder`, Glow-Stile bleiben unter "Klassisch". Zustände `far` / `ready` / `locked`, Farbe je Kategorie (`ColorFor`).
- Stile `fireflies`, `treasure`, `pixels`, `constellation`; Animationen in `UI/LootSparkleSceneAnimations.lua` (nutzt `Animations.helpers` aus `LootSparkleAnimations.lua`), Schichten als Generatoren in `LootSparkleStyles.lua` (in `GROUND_LAYERS`), Texturen `sparkle_firefly.go`, `sparkle_map.go`, `sparkle_sprite.go`, `sparkle_constellation.go`.
- Engine-Felder neu genutzt: `peak` (Höchstdeckkraft der Animation, Schatten blasser), `delay/steps/closing/fromX/fromY/dirX/dirY/half/pop` als Fabrikparameter. Animationen ohne OnUpdate: Translation-Orders summieren sich (Wegstücke, Sprung + Halt bei Pixeln mit `NONE`), Pfade schließen sich (Summe 0) oder erlöschen am Ende.
- Glühwürmchen: weit-Schichten (`fireflyShade/Glow/Core`) und bereit-Schichten (`fireflyReady*`) sind getrennt; `fireflyGather` springt unsichtbar (0.01 s) zum alten Ort und fliegt zum Anker, weil eine Einmal-Animation nicht an einer anderen Position starten kann.
- Schatzkarte: Tinte und Rand liegen im Grauwert (dunkel/hell) in einer BLEND-Textur, `SetVertexColor` färbt nur den Rand; Atlas 4 X-Stücke, 4 Pfadstriche, 8 Kreisstücke (Kreis mit Überstand), Bodenellipse 120 x 48.
- Pixel: harte Kanten (`spriteImage`, dreistufige Schattierung + eingebackener weicher Schatten, 32-Texel-Block); Sternbild: Sternpositionen stehen in `sparkle_constellation.go` UND `LootSparkleStyles.lua` (müssen übereinstimmen), Atlas Zelle i = Linie, Zelle 8 + i = Schatten.
- Kontaktbogen: `SPARKLE_PREVIEW_STYLES=gluehwuermchen,schatzkarte,pixel-pop,sternbild` filtert die Stile (Spiegel in `sparkle_preview_scenes.go`, von Hand pflegen).
