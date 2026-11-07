-- Questtext-Größe (questTextResize/questTextSize): Quest-Schriften in der Reglergröße, Überschriften etwas größer,
-- Schrift und Kontur bleiben; aus = Blizzards Größe
QuestFont:SetFont("Fonts\\FRIZQT__.TTF", 13, "")
QuestTitleFont:SetFont("Fonts\\MORPHEUS.TTF", 18, "OUTLINE")

wow.login()
addon.Set("questTextSize", 18)
expect("Schalter aus: Blizzards Größe", select(2, QuestFont:GetFont()), 13)
addon.Set("questTextResize", true)
expect("Text in Reglergröße", select(2, QuestFont:GetFont()), 18)
expect("Ziele auch", select(2, QuestFontNormalSmall:GetFont()), 18)
expect("Überschrift größer", select(2, QuestTitleFont:GetFont()), 18 + addon.QuestTextSize.TITLE_EXTRA)
expect("Schrift bleibt", (QuestTitleFont:GetFont()), "Fonts\\MORPHEUS.TTF")
expect("Kontur bleibt", select(3, QuestTitleFont:GetFont()), "OUTLINE")
addon.Set("questTextSize", 12)
expect("Regler wirkt sofort", select(2, QuestFont:GetFont()), 12)
addon.Set("questTextResize", false)
expect("aus: Text zurück", select(2, QuestFont:GetFont()), 13)
expect("aus: Überschrift zurück", select(2, QuestTitleFont:GetFont()), 18)
