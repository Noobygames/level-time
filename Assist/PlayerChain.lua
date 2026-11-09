-- Elite-Rahmen am Spieler (Reiter Komfort, Fenster; playerChain, Standard "off"): der Spielerrahmen zeigt den Drachen
-- eines Elite-, Rar- oder Rar-Elite-Gegners. Nur Classic-Rahmen (PlayerFrameTexture, Classic Era/Anniversary): eigene
-- Textur mit Blizzards Zielrahmen-Dateien (TargetFrame.lua: UI-TargetingFrame-Elite/-Rare/-Rare-Elite), gespiegelt;
-- Größe und Lage aus TargetFrame.xml (230x99, CENTER 18.5/-4, TexCoords 0.1015625-1.0 / 0.0078125-0.78125) auf die
-- Gegenseite übertragen. Blizzards PlayerFrameTexture bekommt solange Alpha 0 (umkehrbar, auch im Kampf erlaubt,
-- weil nur eine Textur). Retail/Forever nutzen Atlas-Rahmen ohne Spieler-Gegenstück und fehlen.
local _, ns = ...

ns.RegisterDefaults({
  settings = {
    playerChain = "off",
  },
})

local PlayerChain = {}
ns.PlayerChain = PlayerChain

PlayerChain.OFF = "off"
PlayerChain.TEXTURES = {
  elite = "Interface\\TargetingFrame\\UI-TargetingFrame-Elite",
  rare = "Interface\\TargetingFrame\\UI-TargetingFrame-Rare",
  rareelite = "Interface\\TargetingFrame\\UI-TargetingFrame-Rare-Elite",
}
PlayerChain.ORDER = { PlayerChain.OFF, "elite", "rare", "rareelite" }
PlayerChain.SIZE = { 230, 99 }
PlayerChain.OFFSET = { -18.5, -4 }
PlayerChain.TEX_COORDS = { 1, 0.1015625, 0.0078125, 0.78125 }  -- gespiegelt

local setAlpha = ns.Overrides.Alpha()
local chain

function PlayerChain.IsAvailable()
  return PlayerFrameTexture ~= nil and PlayerFrameTexture.GetParent ~= nil
end

function PlayerChain.Texture()
  return chain
end

local function create()
  local parent = PlayerFrameTexture:GetParent() or PlayerFrame
  chain = parent:CreateTexture(nil, "BORDER", nil, 1)  -- über Blizzards Rahmen derselben Schicht
  chain:SetSize(unpack(PlayerChain.SIZE))
  chain:SetPoint("CENTER", PlayerFrameTexture, "CENTER", unpack(PlayerChain.OFFSET))
  chain:SetTexCoord(unpack(PlayerChain.TEX_COORDS))
end

ns.RegisterApply(function(db)
  if not PlayerChain.IsAvailable() then return end
  local file = PlayerChain.TEXTURES[db.playerChain]
  if file and not chain then create() end
  if chain then
    if file then chain:SetTexture(file) end
    chain:SetShown(file ~= nil)
  end
  setAlpha(PlayerFrameTexture, file ~= nil, 0)
end)
