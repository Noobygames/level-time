-- Bausteine in Lib/Widgets.lua (LT-291): Fensterkopf, Primärbutton, Chip, Listenzeile, Label-Wert, Badge, Balken.
local Widgets, Theme = addon.Widgets, addon.Theme
wow.login()
local parent = CreateFrame("Frame")

local panel = CreateFrame("Frame")
local header = Widgets.CreateWindowHeader(panel, "Titel", { onClose = function() panel.closed = true end })
expect("Kopfhöhe", header:GetHeight(), 40)
expect("Titel", header.title:GetText(), "Titel")
expect("Close 24", header.close:GetWidth(), 24)
header.close:GetScript("OnClick")(header.close)
expectTrue("onClose", panel.closed)
header:SetTitle("Neu")
expect("Titel neu", header.title:GetText(), "Neu")
-- Mindestbreite: Rand 16 + Titel + 8 + Close 24 + 8; Aktionen und Symbol kommen dazu
expect("Mindestbreite", header:MinWidth(), 16 + header.title:GetStringWidth() + 8 + 24 + 8)
header.actions:SetWidth(100)
header:SetIcon("Interface\\Icons\\INV_Misc_Key_05")
expect("Mindestbreite mit Aktion und Symbol", header:MinWidth(), 16 + 26 + header.title:GetStringWidth() + 8 + 108 + 24 + 8)

local button = Widgets.CreateButton(parent, 80, 28, function() end)
button:SetPrimary(true)
expectTrue("primär", button.primary)
button:SetPrimary(false)
expect("nicht primär", button.primary, false)

local toggled
local chip = Widgets.CreateChip(parent, "Filter", function(on) toggled = on end)
expect("Chip aus", chip:IsOn(), false)
chip:GetScript("OnClick")(chip)
expect("Chip an", chip:IsOn(), true)
expect("Callback an", toggled, true)
chip:SetOn(false)
expect("Chip wieder aus", chip:IsOn(), false)

local row = Widgets.CreateListRow(parent)
expect("Zeilenhöhe", row:GetHeight(), 32)
row:SetSelected(true)
expectTrue("gewählt", row:IsSelected())
row:SetSelected(false)
expect("nicht gewählt", row:IsSelected(), false)
expect("eigene Höhe", Widgets.CreateListRow(parent, 30):GetHeight(), 30)

local line = Widgets.CreateLabelValue(parent)
line:SetValues("Zeit", "1:00", "good")
expect("Label", line.label:GetText(), "Zeit")
expect("Wert", line.value:GetText(), "1:00")

local badge = Widgets.CreateBadge(parent, "Offen", "info")
badge:SetStatus("good", "Fertig")
expect("Badge-Text", badge.text:GetText(), "Fertig")
expectTrue("Statuspunkt", Widgets.CreateStatusDot(parent, "bad") ~= nil)

expect("Balken klein", Widgets.CreateProgressBar(parent, "small"):GetHeight(), 6)
expect("Balken mittel", Widgets.CreateProgressBar(parent):GetHeight(), 12)
local bar = Widgets.CreateProgressBar(parent, "large")
expect("Balken groß", bar:GetHeight(), 24)
bar:SetProgress(1.5, "good")
expect("Fortschritt begrenzt", bar:GetProgress(), 1)

expectTrue("Rolle note", Theme.Font("note") ~= nil and _G[Theme.Font("note")] ~= nil)
expectTrue("Notizfarbe", Theme.COLORS.note[1] > 0.5 and Theme.COLORS.note[1] < 0.6)
