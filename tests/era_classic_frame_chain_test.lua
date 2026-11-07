-- Elite-Rahmen am Spieler (playerChain, Classic-Rahmen): eigene gespiegelte Textur, Blizzards Rahmen unsichtbar
local Chain = addon.PlayerChain
PlayerFrameTexture:SetAlpha(1)
wow.login()
expectTrue("im Classic-Rahmen verfügbar", Chain.IsAvailable())
expect("aus: keine Textur", Chain.Texture(), nil)

addon.Set("playerChain", "elite")
expectTrue("Drache sichtbar", Chain.Texture():IsShown())
expect("Elite-Datei", Chain.Texture():GetTexture(), Chain.TEXTURES.elite)
expect("Blizzards Rahmen unsichtbar", PlayerFrameTexture:GetAlpha(), 0)
addon.Set("playerChain", "rare")
expect("Rar-Datei", Chain.Texture():GetTexture(), Chain.TEXTURES.rare)
addon.Set("playerChain", "off")
expect("aus: Drache weg", Chain.Texture():IsShown(), false)
expect("aus: Blizzards Rahmen zurück", PlayerFrameTexture:GetAlpha(), 1)
