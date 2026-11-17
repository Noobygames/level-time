-- Level-Time-Ergänzungen im Tooltip der Gruppensuche (Einstellung lfgTooltip, an; nur WoW Forever, andere Clients hängen
-- nichts ein): Mitglieder mit Klasse/Rolle/Level/Zone, Level-Spanne und Passung, offene Rollen, besiegte Bosse,
-- Freunde/Gilde, aufgelöst, offene Dungeonquests mit Machbarkeit, Warnung bei 13 Level Abstand (keine Erfahrung).
-- Die Trefferliste bekommt zusätzlich Markierungen (UpdateEntryMarks, gleiche Einstellung).
-- Die Daten liefert Assist/LFGData.lua. Welche Gruppensuche Forever lädt, ist offen (Debug-Prüfung LT271.lfg.finder):
-- beide Varianten werden eingehängt, sobald ihre Funktion existiert. Nur Post-Hooks, kein Taint:
--   Retail-Stil: hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", tooltip, resultID), Tooltip ist GameTooltip.
--   Classic-Stil (Blizzard_GroupFinder_VanillaStyle, lädt bei Bedarf): hooksecurefunc
--     ("LFGBrowseSearchEntryTooltip_UpdateAndShow", self, resultID). Der eigene Rahmen LFGBrowseSearchEntryTooltip
--     zeigt Mitglieder, Bosse und "aufgelöst" selbst: wir ergänzen die Zone je Mitgliedszeile und unseren Block
--     (ohne Doppelungen) im Rahmen und vergrößern ihn.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    lfgTooltip = true,
  },
})

local L = ns.L
local LFGData = ns.LFGData

local LFGTooltip = {}
ns.LFGTooltip = LFGTooltip

-- Große Raidgruppen nicht als Wand aus Zeilen
local MAX_MEMBER_ROWS = 10
local MAX_QUEST_ROWS = 6
local FIT_COLORS = { [LFGData.FITS] = "good", [LFGData.ABOVE] = "warning", [LFGData.BELOW] = "warning" }
local FIT_TEXTS = { [LFGData.FITS] = "LFG_FIT_OK", [LFGData.ABOVE] = "LFG_FIT_ABOVE", [LFGData.BELOW] = "LFG_FIT_BELOW" }
local QUEST_STATE_TEXTS = { [LFGData.DOABLE] = "LFG_QUEST_DOABLE", [LFGData.BOSS_DEAD] = "LFG_QUEST_BOSS_DEAD",
  [LFGData.UNKNOWN] = "LFG_QUEST_UNKNOWN" }
local QUEST_STATE_COLORS = { [LFGData.DOABLE] = "good", [LFGData.BOSS_DEAD] = "bad", [LFGData.UNKNOWN] = "muted" }
local ROLE_TEXTS = { TANK = "LFG_ROLE_TANK", HEALER = "LFG_ROLE_HEALER", DAMAGER = "LFG_ROLE_DAMAGER" }
local OPEN_ROLE_ORDER = { "TANK", "HEALER", "DAMAGER" }
-- Texte und Farben auch für das Gruppensuche-Fenster (UI/LFGWindow.lua)
LFGTooltip.FIT_COLORS, LFGTooltip.FIT_TEXTS, LFGTooltip.ROLE_TEXTS = FIT_COLORS, FIT_TEXTS, ROLE_TEXTS
LFGTooltip.QUEST_STATE_TEXTS, LFGTooltip.QUEST_STATE_COLORS = QUEST_STATE_TEXTS, QUEST_STATE_COLORS

function LFGTooltip.IsEnabled()
  return ns.db ~= nil and ns.db.lfgTooltip and LFGData.IsAvailable()
end

local function memberLine(tooltip, member)
  local role = ROLE_TEXTS[member.role] and L[ROLE_TEXTS[member.role]]
  local name = (member.name or "?") .. (role and (" - " .. role) or "")
  local info = (member.level and tostring(member.level) or "?") .. (member.area and (" · " .. member.area) or "")
  local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[member.class] or { r = 1, g = 1, b = 1 }
  tooltip:AddDoubleLine(name, info, color.r, color.g, color.b, ns.Theme.RGB("muted"))
end

local function openRolesText(open)
  local parts = {}
  for _, role in ipairs(OPEN_ROLE_ORDER) do
    if open[role] and open[role] > 0 then table.insert(parts, string.format("%d %s", open[role], L[ROLE_TEXTS[role]])) end
  end
  if #parts == 0 and open.free > 0 then table.insert(parts, string.format(L.LFG_OPEN_SLOTS, open.free)) end
  return table.concat(parts, ", ")
end

LFGTooltip.OpenRolesText = openRolesText

local function addQuestLines(tooltip, quests)
  tooltip:AddLine(string.format(L.LFG_QUESTS, #quests), ns.Theme.RGB("info"))
  for index = 1, math.min(#quests, MAX_QUEST_ROWS) do
    local quest = quests[index]
    local state = L[QUEST_STATE_TEXTS[quest.state]]
    tooltip:AddDoubleLine(quest.title or tostring(quest.questID),
      quest.takeable and state or (state .. ", " .. L.LFG_QUEST_NOT_TAKEABLE), 1, 1, 1, ns.Theme.RGB(QUEST_STATE_COLORS[quest.state]))
  end
end

local function addLevelLine(tooltip, data)
  local range = data.levelLow == data.levelHigh and tostring(data.levelLow) or (data.levelLow .. "-" .. data.levelHigh)
  tooltip:AddDoubleLine(string.format(L.LFG_LEVELS, range), data.fit and string.format(L[FIT_TEXTS[data.fit]], data.ownLevel) or "",
    1, 1, 1, ns.Theme.RGB(FIT_COLORS[data.fit] or "muted"))
  if data.noXpLow then tooltip:AddLine(string.format(L.LFG_NO_XP, data.noXpLow, data.noXpHigh), ns.Theme.RGB("bad")) end
end

-- Fügt den Block an; false = nichts zu zeigen. inline = Classic-Stil: Blizzards Rahmen zeigt Mitglieder, besiegte
-- Bosse und "aufgelöst" schon selbst, darum fehlen sie hier.
local function addBlock(tooltip, resultID, inline)
  if not LFGTooltip.IsEnabled() then return false end
  local data = LFGData.Summary(resultID)
  if not data or (#data.members == 0 and not data.delisted) then return false end
  tooltip:AddLine(" ")
  tooltip:AddLine(ns.DISPLAY_NAME, ns.Theme.RGB("info"))
  if not inline then
    for index = 1, math.min(#data.members, MAX_MEMBER_ROWS) do memberLine(tooltip, data.members[index]) end
  end
  if data.levelLow then addLevelLine(tooltip, data) end
  local open = data.open and openRolesText(data.open)
  if open and open ~= "" then tooltip:AddLine(string.format(L.LFG_OPEN, open), 1, 1, 1) end
  if #data.killedBosses > 0 and not inline then
    tooltip:AddLine(string.format(L.LFG_BOSSES_KILLED, table.concat(data.killedBosses, ", ")), ns.Theme.RGB("muted"))
  end
  if data.friends + data.guild > 0 then
    tooltip:AddLine(string.format(L.LFG_SOCIAL, data.friends, data.guild), ns.Theme.RGB("success"))
  end
  if data.delisted and not inline then tooltip:AddLine(L.LFG_DELISTED, ns.Theme.RGB("bad")) end
  if #data.quests > 0 then addQuestLines(tooltip, data.quests) end
  return true, data
end

local retailHooked = false
local function hookRetail()
  if retailHooked or not (hooksecurefunc and LFGListUtil_SetSearchEntryTooltip) then return end
  retailHooked = true
  hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
    if tooltip and addBlock(tooltip, resultID) then tooltip:Show() end
  end)
end

-- Classic-Stil: Blizzards Rahmen bekommt die Zone je Mitgliedszeile und unten unseren Block (eigene Zeilen in
-- einem Kindrahmen, Rahmenhöhe/-breite wachsen mit). Blizzard berechnet Größe und Zeilen bei jedem Aufruf neu, der
-- Post-Hook setzt darauf auf und ist darum wiederholbar.
local ZONE_GAP, BLOCK_GAP, BLOCK_BOTTOM_PAD, LINE_HEIGHT, SIDE_PAD = 6, 6, 12, 13, 11

-- Sammelt Tooltip-Zeilen als { Text } (Doppelzeile: rechter Teil farbig angehängt)
local function lineCollector()
  local lines = {}
  local function hex(r, g, b) return string.format("|cff%02x%02x%02x", (r or 1) * 255, (g or 1) * 255, (b or 1) * 255) end
  return {
    AddLine = function(_, text, r, g, b) table.insert(lines, { text = text, r = r, g = g, b = b }) end,
    AddDoubleLine = function(_, left, right, lr, lg, lb, rr, rg, rb)
      local text = right ~= "" and (left .. "  " .. hex(rr, rg, rb) .. right .. "|r") or left
      table.insert(lines, { text = text, r = lr, g = lg, b = lb })
    end,
  }, lines
end

local blockByFrame = setmetatable({}, { __mode = "k" })
local function blockOf(frame)
  if blockByFrame[frame] then return blockByFrame[frame] end
  local block = CreateFrame("Frame", nil, frame)
  block.lines = {}
  blockByFrame[frame] = block
  return block
end

-- Für Tests: Zeilentexte des Blocks
function LFGTooltip.BlockTexts(frame)
  local block, texts = blockByFrame[frame], {}
  for _, line in ipairs(block and block:IsShown() and block.lines or {}) do
    if line:IsShown() then table.insert(texts, line:GetText()) end
  end
  return texts
end

local function blockLine(block, index)
  if not block.lines[index] then
    local line = block:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    line:SetJustifyH("LEFT")
    line:SetPoint("TOPLEFT", block, "TOPLEFT", 0, -(index - 1) * LINE_HEIGHT)
    block.lines[index] = line
  end
  return block.lines[index]
end

-- Breite von Level und Rollen-Symbolen hinter dem Namen (wie Blizzards GetMemberRowLevelAndRoleWidth)
local function levelAndRoleWidth(row)
  local width = row.Level and row.Level:GetWidth() or 0
  for _, icon in ipairs(row.Roles or {}) do
    if icon:IsShown() then width = width + icon:GetWidth() end
  end
  return width + 4
end

local zoneByRow = setmetatable({}, { __mode = "k" })
-- Zone je Mitgliedszeile (Pool-Rahmen werden wiederverwendet: einmal anlegen, bei jedem Aufruf neu setzen), als
-- Spalte hinter Name, Level und Rollen derselben Zeile (offset ab dem Namen). Gibt die Zonenbreite zurück.
local function setRowZone(row, area, offset)
  local zone = zoneByRow[row]
  if not zone and not area then return 0 end
  if not zone then
    zone = row:CreateFontString(nil, "ARTWORK", "GameFontDisableSmallLeft")
    zone:SetJustifyH("LEFT")
    zoneByRow[row] = zone
  end
  zone:ClearAllPoints()
  zone:SetPoint("LEFT", row.Name, "RIGHT", offset, 0)
  zone:SetText(area or "")
  zone:SetShown(area ~= nil)
  return area and zone:GetStringWidth() or 0
end

function LFGTooltip.RowZone(row) return zoneByRow[row] end

local function memberAreas(data)
  local areas = {}
  for _, member in ipairs(data and data.members or {}) do
    if member.name and member.area then areas[member.name] = member.area end
  end
  return areas
end

local function updateClassicFrame(frame, resultID)
  local collector, lines = lineCollector()
  local ok, data = addBlock(collector, resultID, true)
  local areas = memberAreas(ok and data or nil)
  local zoneWidth = 0
  local rows = { frame.Leader }
  if frame.memberPool then
    for row in frame.memberPool:EnumerateActive() do table.insert(rows, row) end
  end
  local offset = 0
  for _, row in ipairs(rows) do
    if row:IsShown() then offset = math.max(offset, levelAndRoleWidth(row)) end
  end
  offset = offset + ZONE_GAP
  for _, row in ipairs(rows) do
    local name = row.Name and row.Name:GetText()
    zoneWidth = math.max(zoneWidth, setRowZone(row, row:IsShown() and areas[name] or nil, offset))
  end
  local block = blockOf(frame)
  block:Hide()
  if not ok or #lines <= 2 then return end -- nur Leerzeile und Überschrift: nichts zu ergänzen
  local height, width = frame:GetHeight(), frame:GetWidth()
  for index, entry in ipairs(lines) do
    local line = blockLine(block, index)
    line:SetText(entry.text)
    line:SetTextColor(entry.r or 1, entry.g or 1, entry.b or 1)
    line:Show()
    width = math.max(width, line:GetStringWidth() + 2 * SIDE_PAD)
  end
  for index = #lines + 1, #block.lines do block.lines[index]:Hide() end
  if zoneWidth > 0 then width = math.max(width, frame:GetWidth() + zoneWidth + ZONE_GAP) end
  block:ClearAllPoints()
  block:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_PAD, -(height - BLOCK_BOTTOM_PAD + BLOCK_GAP))
  block:SetSize(width - 2 * SIDE_PAD, #lines * LINE_HEIGHT)
  block:Show()
  frame:SetHeight(height - BLOCK_BOTTOM_PAD + BLOCK_GAP + #lines * LINE_HEIGHT + BLOCK_BOTTOM_PAD)
  frame:SetWidth(width)
end

local classicHooked = false
local function hookClassic()
  if classicHooked or not (hooksecurefunc and LFGBrowseSearchEntryTooltip_UpdateAndShow and LFGBrowseSearchEntryTooltip) then return end
  classicHooked = true
  hooksecurefunc("LFGBrowseSearchEntryTooltip_UpdateAndShow", updateClassicFrame)
end

-- Markierungen in der Trefferliste (Classic-Stil): Level-Spanne, grüner Punkt bei Freunden/Gilde, abgedunkelt bei
-- aufgelösten Gruppen. Nur eigene Kindelemente der Zeile (Post-Hook auf LFGBrowseSearchEntry_Update, kein Taint).
local MARK_DOT_SIZE = 10
local entryMarksByFrame = setmetatable({}, { __mode = "k" })
local function entryMarks(entry)
  if entryMarksByFrame[entry] then return entryMarksByFrame[entry] end
  local marks = {
    range = entry:CreateFontString(nil, "ARTWORK", "GameFontDisableSmallLeft"),
    dot = entry:CreateTexture(nil, "OVERLAY"),
    dim = entry:CreateTexture(nil, "OVERLAY"),
  }
  marks.range:SetPoint("LEFT", entry.ActivityName, "RIGHT", 6, 0)
  marks.dot:SetTexture("Interface\\Common\\Indicator-Green")
  marks.dot:SetSize(MARK_DOT_SIZE, MARK_DOT_SIZE)
  marks.dot:SetPoint("TOPLEFT", entry, "TOPLEFT", 0, -3)
  marks.dim:SetColorTexture(0, 0, 0, 0.5)
  marks.dim:SetAllPoints(entry)
  entryMarksByFrame[entry] = marks
  return marks
end

-- Für Tests: vorhandene Markierungen einer Zeile
function LFGTooltip.EntryMarks(entry) return entryMarksByFrame[entry] end

-- Spanne nur bei mehreren Mitgliedern mit unterschiedlichem Level: Blizzard zeigt die Stufe sonst schon neben dem Namen
local function entryRangeText(data)
  if not data or not data.levelLow or (data.numMembers or 0) <= 1 or data.levelLow == data.levelHigh then return "" end
  return data.levelLow .. "–" .. data.levelHigh
end

function LFGTooltip.UpdateEntryMarks(entry)
  if not entry or not entry.ActivityName then return end
  local data = LFGTooltip.IsEnabled() and LFGData.Summary(entry.resultID)
  if not data and not entryMarksByFrame[entry] then return end
  local marks = entryMarks(entry)
  marks.range:SetText(entryRangeText(data))
  marks.dot:SetShown(data and data.friends + data.guild > 0 or false)
  marks.dim:SetShown(data and data.delisted or false)
end

local entryHooked = false
local function hookEntries()
  if entryHooked or not (hooksecurefunc and LFGBrowseSearchEntry_Update) then return end
  entryHooked = true
  hooksecurefunc("LFGBrowseSearchEntry_Update", LFGTooltip.UpdateEntryMarks)
end

local function hookAll()
  if not ns.Client.IsForever() then return end
  hookRetail()
  hookClassic()
  hookEntries()
end

hookAll()
ns.RegisterEvent("ADDON_LOADED", hookAll)
