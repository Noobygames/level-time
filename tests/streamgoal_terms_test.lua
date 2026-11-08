-- Level Time Goals, UX-Review Paket 2 (Begriffe und Erklärungen): eine Sprache für gespeicherte Ziele (Vorlagen),
-- Ziel-Karten und laufende Ziele; jeder Artenreiter und jedes Formularfeld erklärt sich im Tooltip, in allen Sprachen.
local Goals = streamGoal.Goals
local Manager = streamGoal.Manager
local GoalForm = streamGoal.GoalForm
local L = streamGoal.L
local texts = streamGoal.locales

wow.login({ level = 10, zone = "Orgrimmar" })
SlashCmdList.STREAMGOAL("")

-- Schlüssel in jeder Sprache vorhanden und nicht leer
local function inAllLanguages(what, key)
  for _, language in ipairs(addon.languages) do
    local text = texts[language.code] and texts[language.code][key]
    expectTrue(language.code .. " " .. what .. " " .. key, type(text) == "string" and text ~= "")
  end
end

---------------------------------------------------------------------------
-- Artenreiter: Erklärung zuerst, Chatbefehl gedämpft darunter
---------------------------------------------------------------------------
for _, kind in ipairs(Goals.KindOrder()) do
  local def = Goals.GetKind(kind)
  inAllLanguages("Erklärung der Art", def.label .. "_TIP")
  local lines = Manager.KindTipLines(kind)
  expect(kind .. ": Erklärung zuerst", lines[1].text, L[def.label .. "_TIP"])
  expect(kind .. ": Erklärung nicht gedämpft", lines[1].muted, nil)
  if def.usage then
    expect(kind .. ": Befehl als zweite Zeile", lines[2].text, string.format(L.SG_KIND_TAB_TIP, L[def.usage]))
    expect(kind .. ": Befehl gedämpft", lines[2].muted, true)
  end
end

---------------------------------------------------------------------------
-- Formularfelder: jede Zeile jeder Art und der Zusätze hat eine Erklärung, Auswahlen zusätzlich den Klick-Hinweis
---------------------------------------------------------------------------
local function checkForm(name, form)
  expectTrue(name .. ": Formular", form ~= nil)
  for index, row in ipairs(form.rows) do
    local key = GoalForm.TipKey(row)
    inAllLanguages(name .. " Zeile " .. index, key)
    local lines = GoalForm.TipLines(row)
    expect(name .. " Zeile " .. index .. ": Erklärung", lines[1].text, L[key])
    if row.field and row.field.type == "choice" then
      expect(name .. " Zeile " .. index .. ": Klick-Hinweis", lines[2] and lines[2].text, L.SG_FORM_CHOICE_TIP)
      expect(name .. " Zeile " .. index .. ": Klick-Hinweis gedämpft", lines[2] and lines[2].muted, true)
    end
  end
end
for _, kind in ipairs(Goals.KindOrder()) do checkForm(kind, Manager.Form(kind)) end
checkForm("Zusätze", Manager.ExtrasForm())
-- Gleiche Beschriftung, andere Bedeutung: Besitz erklärt seine Anzahl anders als Kills
expectTrue("Besitz: eigene Erklärung der Anzahl",
  GoalForm.TipKey(Manager.Form("owned").rows[1]) ~= GoalForm.TipKey(Manager.Form("kills").rows[1]))
-- Beispiele stehen im Tooltip, nicht in der Beschriftung (schmale Beschriftungsspalte)
expectTrue("Frist ohne Beispiele in der Beschriftung", not L.SG_FORM_DEADLINE:find("1h30m", 1, true))
expectTrue("Frist-Beispiele im Tooltip", L.SG_FORM_DEADLINE_TIP:find("1h30m", 1, true) ~= nil)

---------------------------------------------------------------------------
-- Begriffe: keine alten Namen mehr in den Texten (Befehlswörter wie "tracker" und "own" bleiben)
---------------------------------------------------------------------------
local OLD_TERMS = {
  deDE = { "[Ee]igene[snm]? Ziel", "Aktive", "aktive", "Tracker", "Anzeige an", "Anzeige aus", "Eigener Text" },
  enUS = { "%f[%a][Oo]wn goals?%f[%A]", "[Aa]ctive goal", "Tracker", "Display on", "Display off", "Own text" },
  frFR = { "[Oo]bjectifs? perso", "actif", "Suivi", "Texte perso" },
  esES = { "[Mm]etas? propias?", "%f[%a]metas? activas?%f[%A]", "Seguimiento", "Texto propio" },
}
for language, patterns in pairs(OLD_TERMS) do
  for key, text in pairs(texts[language]) do
    for _, pattern in ipairs(patterns) do
      expectTrue(language .. " " .. key .. " ohne alten Begriff " .. pattern, not text:find(pattern))
    end
  end
end
-- Vorlagen, Pakete und die Zielart Freitext heißen verschieden
expectTrue("Vorlage ist nicht Freitext", L.SG_POOL_OWN ~= L.SG_KIND_CUSTOM)
expectTrue("Vorlagen sind keine Pakete", L.SG_SECTION_OWN ~= L.SG_SECTION_PACKS)
-- Ziel-Karten: Fußzeile, Einstellungsseite, Edit-Modus und Chat nennen dieselbe Anzeige
expectTrue("Seite heißt wie im Edit-Modus", L.SG_OPTIONS_PAGE_TRACKER == L.SG_EDIT_FRAME)
expectTrue("Fußzeile nennt die Ziel-Karten", L.SG_SHOW_TRACKER:find(L.SG_EDIT_FRAME, 1, true) ~= nil)
SlashCmdList.STREAMGOAL("tracker")
expect("Chat nennt die Ziel-Karten", wow.printed[#wow.printed]:find(L.SG_EDIT_FRAME, 1, true) ~= nil, true)
SlashCmdList.STREAMGOAL("tracker")

---------------------------------------------------------------------------
-- Laufende Ziele: Tooltip der Zeile mit Stand, Kartenzeilen und Bedienhinweis
---------------------------------------------------------------------------
local counted = Goals.Create("custom", { text = "Fünf Zuschauerwünsche erfüllen" }, 5, { reward = "Tanz" })
local lines = Manager.ActiveTipLines(counted)
expect("Stand zuerst", lines[1].text, Goals.CountText(counted))
expectTrue("Kartenzeile mit Belohnung", lines[2].text:find("Tanz", 1, true) ~= nil)
expect("Bedienhinweis gedämpft", lines[#lines].text, L.SG_ACTIVE_TIP_COUNT)
local kills = Goals.Create("kills", {}, 10)
local killLines = Manager.ActiveTipLines(kills)
expect("automatisch gezählt: nur Stand", #killLines, 1)
Goals.Cancel(counted.id)
Goals.Cancel(kills.id)

---------------------------------------------------------------------------
-- Regel ohne Level und ohne Frist sagt, dass sie bis zum Abbruch läuft
---------------------------------------------------------------------------
local open = Goals.Create("rule", { rule = "nodeath" })
expect("offene Regel", Goals.Body(open), L.SG_RULE_BODY_OPEN)
local untilLevel = Goals.Create("rule", { rule = "notaxi" }, 20)
expect("Regel bis Level", Goals.Body(untilLevel), L.SG_RULE_BODY)
Goals.Cancel(open.id)
Goals.Cancel(untilLevel.id)

---------------------------------------------------------------------------
-- /sg scale ohne Zahl: aktuelle Größe und Bereich statt Stille
---------------------------------------------------------------------------
local before = #wow.printed
SlashCmdList.STREAMGOAL("scale")
expect("scale ohne Zahl antwortet", #wow.printed, before + 1)
expectTrue("nennt den Bereich", wow.printed[#wow.printed]:find("0.5", 1, true) ~= nil)
