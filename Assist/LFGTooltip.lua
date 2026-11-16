-- Level-Time-Block im Tooltip der Gruppensuche (Einstellung lfgTooltip, an; nur WoW Forever, andere Clients hängen
-- nichts ein): Mitglieder mit Klasse/Rolle/Level/Zone, Level-Spanne und Passung, offene Rollen, besiegte Bosse,
-- Freunde/Gilde, aufgelöst, offene Dungeonquests mit Machbarkeit, Warnung bei 13 Level Abstand (keine Erfahrung).
-- Die Trefferliste bekommt zusätzlich Markierungen (UpdateEntryMarks, gleiche Einstellung).
-- Die Daten liefert Assist/LFGData.lua. Welche Gruppensuche Forever lädt, ist offen (Debug-Prüfung LT271.lfg.finder):
-- beide Varianten werden eingehängt, sobald ihre Funktion existiert. Nur Post-Hooks, kein Taint:
--   Retail-Stil: hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", tooltip, resultID), Tooltip ist GameTooltip.
--   Classic-Stil (Blizzard_GroupFinder_VanillaStyle, lädt bei Bedarf): hooksecurefunc
--     ("LFGBrowseSearchEntryTooltip_UpdateAndShow", self, resultID). Der eigene Rahmen LFGBrowseSearchEntryTooltip
--     berechnet seine Höhe von Hand, darum steht der Block in GameTooltip direkt darunter und verschwindet mit ihm.
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

-- Fügt den Block an; false = nichts zu zeigen
local function addBlock(tooltip, resultID)
  if not LFGTooltip.IsEnabled() then return false end
  local data = LFGData.Summary(resultID)
  if not data or (#data.members == 0 and not data.delisted) then return false end
  tooltip:AddLine(" ")
  tooltip:AddLine(ns.DISPLAY_NAME, ns.Theme.RGB("info"))
  for index = 1, math.min(#data.members, MAX_MEMBER_ROWS) do memberLine(tooltip, data.members[index]) end
  if data.levelLow then addLevelLine(tooltip, data) end
  local open = data.open and openRolesText(data.open)
  if open and open ~= "" then tooltip:AddLine(string.format(L.LFG_OPEN, open), 1, 1, 1) end
  if #data.killedBosses > 0 then
    tooltip:AddLine(string.format(L.LFG_BOSSES_KILLED, table.concat(data.killedBosses, ", ")), ns.Theme.RGB("muted"))
  end
  if data.friends + data.guild > 0 then
    tooltip:AddLine(string.format(L.LFG_SOCIAL, data.friends, data.guild), ns.Theme.RGB("success"))
  end
  if data.delisted then tooltip:AddLine(L.LFG_DELISTED, ns.Theme.RGB("bad")) end
  if #data.quests > 0 then addQuestLines(tooltip, data.quests) end
  return true
end

local retailHooked = false
local function hookRetail()
  if retailHooked or not (hooksecurefunc and LFGListUtil_SetSearchEntryTooltip) then return end
  retailHooked = true
  hooksecurefunc("LFGListUtil_SetSearchEntryTooltip", function(tooltip, resultID)
    if tooltip and addBlock(tooltip, resultID) then tooltip:Show() end
  end)
end

local classicHooked = false
local function hookClassic()
  if classicHooked or not (hooksecurefunc and LFGBrowseSearchEntryTooltip_UpdateAndShow and LFGBrowseSearchEntryTooltip) then return end
  classicHooked = true
  hooksecurefunc("LFGBrowseSearchEntryTooltip_UpdateAndShow", function(frame, resultID)
    GameTooltip:SetOwner(frame, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
    if addBlock(GameTooltip, resultID) then GameTooltip:Show() else GameTooltip:Hide() end
  end)
  LFGBrowseSearchEntryTooltip:HookScript("OnHide", function(frame)
    if GameTooltip:IsOwned(frame) then GameTooltip:Hide() end
  end)
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

function LFGTooltip.UpdateEntryMarks(entry)
  if not entry or not entry.ActivityName then return end
  local data = LFGTooltip.IsEnabled() and LFGData.Summary(entry.resultID)
  if not data and not entryMarksByFrame[entry] then return end
  local marks = entryMarks(entry)
  local range = data and data.levelLow and (data.levelLow == data.levelHigh and tostring(data.levelLow)
    or (data.levelLow .. "-" .. data.levelHigh)) or ""
  marks.range:SetText(range)
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
