-- Addon-Liste alphabetisch (Reiter Komfort, System; sortAddonList, Standard aus). Blizzards AddonList_Update
-- (Blizzard_AddOnList, in Retail, Classic Era, TBC und Forever gleich) baut einen Baum (CreateTreeDataProvider) und
-- sortiert ihn nach Ordnernummer. Wir hängen uns mit hooksecurefunc dahinter und geben demselben Baum nur einen
-- anderen Vergleich (TreeDataProviderMixin:SetSortComparator, auch für Kinder): Kategorien wie bei Blizzard zuerst,
-- dann Addons nach Titel ohne Farbcodes, ohne Groß-/Kleinschreibung. Kein Ersetzen von Blizzards Funktionen; die
-- Addon-Liste ist kein geschützter Rahmen. Ausgeschaltet baut Blizzard die Liste beim nächsten Update selbst neu.
local _, ns = ...

local AddonListSort = {}
ns.AddonListSort = AddonListSort

local BLIZZARD_ADDON = "Blizzard_AddOnList"

local function plainTitle(index)
  local title = C_AddOns.GetAddOnTitle(index) or C_AddOns.GetAddOnName(index) or ""
  title = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", "")
  return strtrim(title):lower()
end

-- Kategorien zuerst (nach Name), dann Addons nach Titel; gleicher Titel nach Ordnernummer
function AddonListSort.Compare(aNode, bNode)
  local a, b = aNode:GetData(), bNode:GetData()
  if a.category and b.category then return a.category:lower() < b.category:lower() end
  if a.category or b.category then return a.category ~= nil end
  local titleA, titleB = plainTitle(a.addonIndex), plainTitle(b.addonIndex)
  if titleA ~= titleB then return titleA < titleB end
  return a.addonIndex < b.addonIndex
end

local function isEnabled()
  return ns.db ~= nil and ns.db.sortAddonList == true
end

local function sortList()
  if not isEnabled() then return end
  local provider = AddonList and AddonList.ScrollBox and AddonList.ScrollBox:GetDataProvider()
  if provider and provider.SetSortComparator then
    provider:SetSortComparator(AddonListSort.Compare, true)
  end
end

local hooked = false
local function hook()
  if hooked or type(AddonList_Update) ~= "function" then return end
  hooksecurefunc("AddonList_Update", sortList)
  hooked = true
end

function AddonListSort.IsAvailable()
  return hooked
end

hook()
ns.RegisterEvent("ADDON_LOADED", function(name)
  if name == BLIZZARD_ADDON then hook() end
end)

-- Umschalten bei offener Liste: Blizzard baut sie neu, der Hook sortiert danach wieder, wenn eingeschaltet
local applied = false
ns.RegisterApply(function()
  if isEnabled() == applied then return end
  applied = isEnabled()
  if hooked and AddonList and AddonList:IsShown() then AddonList_Update() end
end)
