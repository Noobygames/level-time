-- Tooltips in den Einstellungen: Titel = Beschriftung, Text aus L["<LABEL>_TIP"].
local L = addon.L

wow.login()
SlashCmdList.LEVELTIMER("config")

local function hover(frame)
  frame._scripts.OnEnter(frame)
  return GameTooltip:GetText(), (GameTooltip._lines or {})[1]
end

local function clickable(text)
  return wow.findFrame(function(frame)
    local label = rawget(frame, "label")
    return ((label and label._text == text) or frame._text == text) and frame._scripts.OnEnter ~= nil
  end)
end

-- Schalter, Button unten, Auswahl-Reiter
local title, body = hover(clickable(L.AUTO_INSTANCE_TAB))
expect("Schalter: Titel", title, L.AUTO_INSTANCE_TAB)
expect("Schalter: Text", body, L.AUTO_INSTANCE_TAB_TIP)

title, body = hover(clickable(L.HISTORY))
expect("Button: Text", body, L.HISTORY_TIP)

title, body = hover(clickable("Deutsch"))
expect("Auswahl: Titel", title, L.LANGUAGE)
expect("Auswahl: Text", body, L.LANGUAGE_TIP)

-- Regler: Tooltip am Schieber
local sizeSlider = wow.findFrame(function(frame)
  local label = rawget(frame, "label")
  return label and label._text == L.WINDOW_SIZE and rawget(frame, "slider") ~= nil
end)
title, body = hover(sizeSlider.slider)
expect("Regler: Text", body, L.WINDOW_SIZE_TIP)

-- Jede Statistik hat einen Tooltip-Text in jeder Sprache
for _, language in ipairs(addon.languages) do
  addon.Set("language", language.code)
  for _, line in ipairs(addon.STAT_LINES) do
    local key = line.label .. "_TIP"
    expectTrue(language.code .. ": Tooltip für " .. line.label, L[key] ~= key)
  end
end
addon.Set("language", "deDE")

-- Verlassen schließt den Tooltip
local checkbox = clickable(L.AUTO_INSTANCE_TAB)
hover(checkbox)
checkbox._scripts.OnLeave(checkbox)
expect("Tooltip zu", GameTooltip:IsShown(), false)
