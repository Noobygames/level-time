-- Chat bis an den Rand (unclampChat): Klemm-Abstände 0, nach Blizzards Neuanordnen nachgezogen, aus = zurück
local chat1, chat2 = ChatFrame1, ChatFrame2

-- Classic setzt die Abstände nach dem Neuanordnen des Hintergrunds neu
function FloatingChatFrame_UpdateBackgroundAnchors(chatFrame) chatFrame:SetClampRectInsets(-35, 45, 38, -50) end

wow.login()

expect("aus: Blizzards Abstand", (chat1:GetClampRectInsets()), -35)
addon.Set("unclampChat", true)
expect("an: kein Abstand links", (chat1:GetClampRectInsets()), 0)
expect("an: kein Abstand unten", select(4, chat2:GetClampRectInsets()), 0)
FloatingChatFrame_UpdateBackgroundAnchors(chat1)
expect("nach Blizzards Neuanordnen wieder 0", select(2, chat1:GetClampRectInsets()), 0)
addon.Set("unclampChat", false)
expect("aus: Abstand zurück", (chat1:GetClampRectInsets()), -35)
expect("aus: Fenster 2 zurück", select(3, chat2:GetClampRectInsets()), 26)
FloatingChatFrame_UpdateBackgroundAnchors(chat1)
expect("aus: Hook lässt Blizzard gewähren", select(2, chat1:GetClampRectInsets()), 45)
