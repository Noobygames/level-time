-- Post-Helfer (Reiter Komfort, Automatik, mailAssist):
--   - "Alle öffnen"-Knopf am Posteingang: plündert Post von oben nach unten (ns.Every 0.25s)
--   - Überspringt Nachnahme (C.O.D.)
--   - Hält an, wenn Taschen voll sind
--   - Alt-Klick auf Gegenstände in den Taschen hängt sie an ausgehende Post an
--   - Knopf zum Durchschalten eigener bekannter Twinks auf demselben Realm
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    mailAssist = false,
  },
})

local L = ns.L

local Mail = {}
ns.Mail = Mail

local isOpening = false
local currentIndex = 0
local skippedCOD = false
local currentAltIndex = 0
local openAllButton
local altButton

function Mail.IsOpening()
  return isOpening
end

function Mail.StopOpenAll()
  if not isOpening then return end
  isOpening = false
  currentIndex = 0
  ns.RefreshTasks()
  if skippedCOD then
    ns.Print(L.MAIL_SKIPPED_COD)
    skippedCOD = false
  end
  ns.Debug("mail", "stop open all")
end

function Mail.StartOpenAll()
  if not ns.db or not ns.db.mailAssist then return end
  if isOpening then return end
  local count = GetInboxNumItems and GetInboxNumItems() or 0
  if count <= 0 then return end
  isOpening = true
  currentIndex = count
  skippedCOD = false
  ns.Debug("mail", "start open all with %s items", count)
  ns.RefreshTasks()
end

function Mail.StepOpenAll()
  if not isOpening then return end
  local numItems = GetInboxNumItems and GetInboxNumItems() or 0
  if numItems <= 0 or currentIndex < 1 then
    Mail.StopOpenAll()
    return
  end
  if currentIndex > numItems then
    currentIndex = numItems
  end

  while currentIndex >= 1 do
    local index = currentIndex
    currentIndex = currentIndex - 1
    local _, _, sender, subject, money, CODAmount, _, hasItem = GetInboxHeaderInfo(index)
    if CODAmount and CODAmount > 0 then
      skippedCOD = true
      ns.Debug("mail", "skipping COD mail at %s", index)
    else
      local hasMoney = money and money > 0
      local hasItems = hasItem and hasItem > 0
      if hasItems and ns.Bags and ns.Bags.GetFreeSlots() <= 0 then
        ns.Debug("mail", "bags full at index %s", index)
        Mail.StopOpenAll()
        ns.Print(L.MAIL_STOPPED_BAGS_FULL)
        return
      end
      if hasMoney or hasItems then
        ns.Debug("mail", "looting mail %s (money: %s, hasItem: %s)", index, money, hasItem)
        if AutoLootMailItem then
          AutoLootMailItem(index)
        else
          if hasMoney and TakeInboxMoney then TakeInboxMoney(index) end
          if hasItems and TakeInboxItem then TakeInboxItem(index) end
        end
        return
      end
    end
  end

  Mail.StopOpenAll()
end

local function onMailClosed()
  if isOpening then
    Mail.StopOpenAll()
  end
end

local function onErrorMessage(...)
  if not isOpening then return end
  local arg1, arg2 = ...
  if arg1 == ERR_INV_FULL or arg2 == ERR_INV_FULL then
    ns.Debug("mail", "bags full from error message")
    Mail.StopOpenAll()
    ns.Print(L.MAIL_STOPPED_BAGS_FULL)
  end
end

function Mail.TryAttachBagItem(bag, slot)
  if not ns.db or not ns.db.mailAssist then return false end
  if not (SendMailFrame and SendMailFrame:IsShown()) then return false end
  if not (IsAltKeyDown and IsAltKeyDown()) then return false end
  if not bag or not slot then return false end
  ns.Debug("mail", "attaching bag item %s, %s", bag, slot)
  ns.Bags.Pickup(bag, slot)
  if ClickSendMailItemButton then
    ClickSendMailItemButton()
  end
  return true
end


-- WoW Forever: Empfänger braucht Vor- und Nachname (Trenner wie Blizzard NameUtil.GetFullNameWithoutRealm)
local SURNAME_SEPARATOR = " "

local function recipientName(data, keyName)
  local name = data.name or keyName
  if not data.surname or not name then return name end
  local consts = Constants and Constants.CharacterNameSeparatorConsts
  local separator = consts and consts.CHARACTERNAME_SURNAME_SEPARATOR or SURNAME_SEPARATOR
  return name .. separator .. data.surname
end

function Mail.GetKnownAlts()
  local result = {}
  local stats = LevelTimerStatsDB and LevelTimerStatsDB.characters
  if not stats then return result end

  local currentKey = ns.characterKey
  local currentRealm = (ns.character and ns.character.realm) or (GetRealmName and GetRealmName())
  if not currentRealm and currentKey then
    currentRealm = currentKey:match("^[^-]+%-(.+)$")
  end

  for key, data in pairs(stats) do
    if key ~= currentKey then
      local name, realm = key:match("^([^-]+)%-(.+)$")
      local charRealm = data.realm or realm
      if currentRealm and charRealm and charRealm:lower() == currentRealm:lower() then
        table.insert(result, {
          name = recipientName(data, name),
          key = key,
          class = data.class,
        })
      end
    end
  end

  table.sort(result, function(a, b)
    return (a.name or "") < (b.name or "")
  end)

  return result
end

function Mail.FillRecipient(name)
  if not name or name == "" then return end
  if SendMailNameEditBox and SendMailNameEditBox.SetText then
    SendMailNameEditBox:SetText(name)
    if SendMailNameEditBox.HighlightText then
      SendMailNameEditBox:HighlightText()
    end
    ns.Debug("mail", "filled recipient: %s", name)
  end
end

local function updateButtons()
  if not ns.db or not ns.db.mailAssist then
    if openAllButton then openAllButton:Hide() end
    if altButton then altButton:Hide() end
    return
  end

  local inboxParent = InboxFrame or MailFrame
  if inboxParent and not openAllButton then
    openAllButton = CreateFrame("Button", "LevelTimerMailOpenAllButton", inboxParent, "UIPanelButtonTemplate")
    openAllButton:SetSize(100, 22)
    openAllButton:SetPoint("TOPRIGHT", inboxParent, "TOPRIGHT", -60, -30)
    openAllButton:SetText(L.MAIL_OPEN_ALL)
    openAllButton:SetScript("OnClick", function()
      if Mail.IsOpening() then
        Mail.StopOpenAll()
        return
      end
      if IsShiftKeyDown and IsShiftKeyDown() then return end
      Mail.StartOpenAll()
    end)
    openAllButton:SetScript("OnEnter", function(self)
      if GameTooltip and L.MAIL_OPEN_ALL_TIP then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.MAIL_OPEN_ALL, 1, 1, 1)
        GameTooltip:AddLine(L.MAIL_OPEN_ALL_TIP, nil, nil, nil, true)
        GameTooltip:Show()
      end
    end)
    openAllButton:SetScript("OnLeave", function()
      if GameTooltip then GameTooltip:Hide() end
    end)
  end
  if openAllButton then
    openAllButton:Show()
  end

  if SendMailNameEditBox and not altButton then
    local sendParent = SendMailFrame or MailFrame or inboxParent
    altButton = CreateFrame("Button", "LevelTimerMailAltButton", sendParent, "UIPanelButtonTemplate")
    altButton:SetSize(40, 20)
    altButton:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", 4, 0)
    altButton:SetText(L.MAIL_RECIPIENTS_ALTS or "Alts")
    altButton:SetScript("OnClick", function()
      local alts = Mail.GetKnownAlts()
      if #alts == 0 then return end
      currentAltIndex = (currentAltIndex % #alts) + 1
      local alt = alts[currentAltIndex]
      if alt and alt.name then
        Mail.FillRecipient(alt.name)
      end
    end)
    altButton:SetScript("OnEnter", function(self)
      if GameTooltip and L.MAIL_RECIPIENTS_ALTS then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.MAIL_RECIPIENTS_ALTS, 1, 1, 1)
        GameTooltip:Show()
      end
    end)
    altButton:SetScript("OnLeave", function()
      if GameTooltip then GameTooltip:Hide() end
    end)
  end
  if altButton then
    altButton:Show()
  end
end

function Mail.Apply()
  if not ns.db or not ns.db.mailAssist then
    if openAllButton then openAllButton:Hide() end
    if altButton then altButton:Hide() end
    if isOpening then Mail.StopOpenAll() end
  else
    if (MailFrame and MailFrame:IsShown()) or (InboxFrame and InboxFrame:IsShown()) or (SendMailFrame and SendMailFrame:IsShown()) then
      updateButtons()
    end
  end
end

ns.RegisterApply(Mail.Apply)
ns.Every(0.25, Mail.StepOpenAll, Mail.IsOpening)
ns.RegisterEvent("MAIL_SHOW", updateButtons)
ns.RegisterEvent("MAIL_INBOX_UPDATE", updateButtons)
ns.RegisterEvent("MAIL_CLOSED", onMailClosed)
ns.RegisterEvent("UI_ERROR_MESSAGE", onErrorMessage)

ns.Bags.OnModifiedClick(function(bag, slot) Mail.TryAttachBagItem(bag, slot) end)
