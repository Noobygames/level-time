INSTALLER := tools/installer
ADDONTEST := tools/addontest
ARTWORK   := tools/artwork
RECORDS   := tools/records
FLIGHTS   := tools/flights
LOCALE    := tools/locale
EXTRACTOR := tools/extractor
MECHANICS := tools/mechanics
VERSION   := $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
RUN       := go -C $(INSTALLER) run . -src "$(CURDIR)" -version "$(VERSION)"

# Zusätzliche Flags, z.B. make install ARGS="-flavors retail -wow 'D:/Games/World of Warcraft'"
ARGS ?=

.PHONY: install update dry-run debuglog extract extract-check package artwork records flights locale mechanics test test-addon test-installer test-artwork test-records test-flights test-locale test-extractor test-mechanics test-site vet lint api-docs

# Interaktiver Wizard: Flavors wählen, Plan ansehen, bestätigen
install:
	$(RUN) $(ARGS)

# Ohne Rückfragen alle bereits installierten Flavors aktualisieren
update:
	$(RUN) -yes $(ARGS)

# Nur anzeigen, was passieren würde
dry-run:
	$(RUN) -dry-run -yes $(ARGS)

# ZIPs für CurseForge oder manuelle Installation: dist/LevelTimer-<version>.zip und dist/StreamGoal-<version>.zip
package:
	$(RUN) -addons LevelTimer,LevelTimer_Archive -package "$(CURDIR)/dist/LevelTimer-$(VERSION).zip"
	$(RUN) -addons StreamGoal -package "$(CURDIR)/dist/StreamGoal-$(VERSION).zip"

# Debug-Log von Level Time (/lt debug log, /lt debug check) aus den SavedVariables als JSON Lines ausgeben (nur lesen)
debuglog:
	$(RUN) -debuglog $(ARGS)

# Spieldaten des Data Extractors (LevelTimerExtractorDB) je Flavor nach dist/extractor/<flavor>.json, mit Übersicht
extract:
	go -C $(EXTRACTOR) run . -out "$(CURDIR)/dist/extractor" $(ARGS)

# Wie extract, dazu Abgleich der Forever-Daten mit dem Dungeonführer und dem Kampflog mit den Mechaniken, dazu NPCs/Beute/Quests mit der Dungeon-DB (nur Bericht)
extract-check:
	go -C $(EXTRACTOR) run . -out "$(CURDIR)/dist/extractor" -guide "$(CURDIR)/Assist/InstanceData/forever_guide.lua" -mechanics "$(CURDIR)/Assist/InstanceData/mechanics.lua" -dungeondb "$(CURDIR)/Assist/InstanceData/dungeon_db.lua" $(ARGS)

# CurseForge-Logo und Addon-Icon aus tools/artwork neu erzeugen
artwork:
	go -C $(ARTWORK) run . -logo "$(CURDIR)/curseforge/logo.png" -icon "$(CURDIR)/Media/Icon.tga" -goal-logo "$(CURDIR)/curseforge/streamgoal/logo.png" -goal-icon "$(CURDIR)/StreamGoal/Media/Icon.tga" -glint "$(CURDIR)/Media/Glint.tga" -bars "$(CURDIR)/Media" -wheel "$(CURDIR)/StreamGoal/Media" -sparkles "$(CURDIR)/Media"

# Speedrun-Rekorde von speedrun.com holen und Speedrun/SpeedrunRecords.lua neu schreiben (braucht Internet)
records:
	go -C $(RECORDS) run . -out "$(CURDIR)/Speedrun/SpeedrunRecords.lua"

# Selbst gemessene Flugzeiten aus den SavedVariables aller Flavors (nur lesen) nach Assist/FlightTimesData.lua und
# Flugstrecken aus den Spieldaten (wago.tools) nach Assist/FlightPathsData/<flavor>.lua,
# Flugpunkt-Namen aller Sprachen nach Assist/FlightNamesData/<flavor>.lua, Boss-Listen nach Assist/BossData/<flavor>.lua,
# z.B. make flights ARGS="-wow 'D:/Games/World of Warcraft'" (oder WOW_DIR)
flights:
	go -C $(FLIGHTS) run . -out "$(CURDIR)/Assist/FlightTimesData.lua" -paths "$(CURDIR)/Assist/FlightPathsData" -transports "$(CURDIR)/Assist/TransportData" -instances "$(CURDIR)/Assist/InstanceData" -mapcoords "$(CURDIR)/Assist/MapCoordsData" -names "$(CURDIR)/Assist/FlightNamesData" -bosses "$(CURDIR)/Assist/BossData" $(ARGS)

# Texte in alle vier Sprachdateien schreiben/entfernen, ohne sie zu lesen: make locale ARGS="-file texts.json" oder ARGS="-remove KEY"
locale:
	go -C $(LOCALE) run . -dir "$(CURDIR)/Locales" $(ARGS)

# Boss- und Trash-Mechaniken aus der Guide-Recherche (docs/research/mechanics/*.json) nach Assist/InstanceData/mechanics.lua
mechanics:
	go -C $(MECHANICS) run . -dir "$(CURDIR)/docs/research/mechanics" -lua "$(CURDIR)/Assist/InstanceData/mechanics.lua" $(ARGS)

test: test-addon test-installer test-artwork test-records test-flights test-locale test-extractor test-mechanics test-site

# Lua-Szenarien aus tests/ gegen eine nachgebaute WoW-API.
# -count=1: Go kennt die Lua-Dateien nicht und würde sonst veraltete Ergebnisse aus dem Cache zeigen.
test-addon:
	go -C $(ADDONTEST) test -count=1 -timeout 30m ./...

test-installer:
	go -C $(INSTALLER) test ./...

test-artwork:
	go -C $(ARTWORK) test ./...

test-records:
	go -C $(RECORDS) test ./...

test-flights:
	go -C $(FLIGHTS) test ./...

test-locale:
	go -C $(LOCALE) test ./...

test-extractor:
	go -C $(EXTRACTOR) test ./...

test-mechanics:
	go -C $(MECHANICS) test ./...

# Auswertungs-Seite (docs/site): LT1-Decoder und CSV-Lesen gegen die Testdaten aus tests/site_fixtures_test.lua
test-site:
	node docs/site/site.test.js

vet:
	go -C $(INSTALLER) vet ./...
	go -C $(ADDONTEST) vet ./...
	go -C $(ARTWORK) vet ./...
	go -C $(RECORDS) vet ./...
	go -C $(FLIGHTS) vet ./...
	go -C $(LOCALE) vet ./...
	go -C $(EXTRACTOR) vet ./...
	go -C $(MECHANICS) vet ./...

# Blizzards UI-Code samt generierter API-Doku (Interface/AddOns/Blizzard_APIDocumentationGenerated) je Client
# aus Gethe/wow-ui-source nach .cache/wow-ui-source/<Branch>; flach und nur Interface/, erneuter Aufruf aktualisiert
API_BRANCHES := forever classic_era live
API_DIR      := .cache/wow-ui-source
api-docs:
	@for b in $(API_BRANCHES); do \
	  d="$(API_DIR)/$$b"; \
	  if [ -d "$$d/.git" ]; then \
	    git -C "$$d" fetch -q --depth 1 origin "$$b" && git -C "$$d" reset -q --hard FETCH_HEAD; \
	  else \
	    git clone -q --depth 1 --branch "$$b" --filter=blob:none --sparse https://github.com/Gethe/wow-ui-source.git "$$d" && \
	    git -C "$$d" sparse-checkout set Interface; \
	  fi; \
	  echo "$$b: $$(git -C "$$d" log -1 --format='%s (%cs)')"; \
	done

# Statische Prüfung aller Lua-Dateien mit luacheck 0.23.0 (Regeln in .luacheckrc)
lint:
	luacheck . -q

code-graph-build:
	code-review-graph build 			# parse the codebase

code-graph-install:
	code-review-graph install              # set up the AI coding tools found on this machine

code-graph-changes:
	code-review-graph detect-changes --brief  # see what your last change touches

code-graph-update:
	code-review-graph update  # update the code graph with the latest changes