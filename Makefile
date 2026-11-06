INSTALLER := tools/installer
ADDONTEST := tools/addontest
ARTWORK   := tools/artwork
RECORDS   := tools/records
VERSION   := $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
RUN       := go -C $(INSTALLER) run . -src "$(CURDIR)" -version "$(VERSION)"

# Zusätzliche Flags, z.B. make install ARGS="-flavors retail -wow 'D:/Games/World of Warcraft'"
ARGS ?=

.PHONY: install update dry-run debuglog package artwork records test test-addon test-installer test-artwork test-records vet

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

# CurseForge-Logo und Addon-Icon aus tools/artwork neu erzeugen
artwork:
	go -C $(ARTWORK) run . -logo "$(CURDIR)/curseforge/logo.png" -icon "$(CURDIR)/Media/Icon.tga" -goal-logo "$(CURDIR)/curseforge/streamgoal/logo.png" -goal-icon "$(CURDIR)/StreamGoal/Media/Icon.tga"

# Speedrun-Rekorde von speedrun.com holen und Speedrun/SpeedrunRecords.lua neu schreiben (braucht Internet)
records:
	go -C $(RECORDS) run . -out "$(CURDIR)/Speedrun/SpeedrunRecords.lua"

test: test-addon test-installer test-artwork test-records

# Lua-Szenarien aus tests/ gegen eine nachgebaute WoW-API.
# -count=1: Go kennt die Lua-Dateien nicht und würde sonst veraltete Ergebnisse aus dem Cache zeigen.
test-addon:
	go -C $(ADDONTEST) test -count=1 ./...

test-installer:
	go -C $(INSTALLER) test ./...

test-artwork:
	go -C $(ARTWORK) test ./...

test-records:
	go -C $(RECORDS) test ./...

vet:
	go -C $(INSTALLER) vet ./...
	go -C $(ADDONTEST) vet ./...
	go -C $(ARTWORK) vet ./...
	go -C $(RECORDS) vet ./...
