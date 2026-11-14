// Test der Auswertungs-Seite: lädt das Skript aus index.html ohne Browser und liest die Testdaten, die
// tests/site_fixtures_test.lua mit dem echten Lua-Code (Serializer, Export.ToCsv) erzeugt und prüft.
// Aufruf: node docs/site/site.test.js (make test-site)
"use strict";
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const html = fs.readFileSync(path.join(__dirname, "index.html"), "utf8");
const script = html.match(/<script>([\s\S]*)<\/script>/)[1];
const page = { TextDecoder };
vm.createContext(page);
// "const"-Namen landen nicht im Kontext-Objekt; daher die geprüften Funktionen am Ende ausgeben
const site = vm.runInContext(script + "\n;({ lt1Decode, parseRuns, cumulativeTimes, parseCsv, csvCharts, parseCell })", page);
const fixture = name => fs.readFileSync(path.join(__dirname, "testdata", name), "utf8");
const plain = value => JSON.parse(JSON.stringify(value));

// LT1: Läufe aus dem Lua-Serializer
const runs = site.parseRuns(fixture("runs.lt1"));
assert.deepEqual(plain(runs), [
  { name: "Zwergö", realm: "Die Aldor", times: [[1, 120], [2, 300.5], [3, 480], [4, 610]] },
  { name: "Elfe | 100% {x=1}", realm: null, times: [[1, 100], [2, 350], [3, 420]] },
]);
const decoded = site.lt1Decode("runs", fixture("runs.lt1"));
assert.equal(decoded[1].coverage, 0.95);
assert.equal(decoded[1].category, "solo");
assert.deepEqual(plain(site.cumulativeTimes(runs[0].times)), [[2, 120], [3, 420.5], [4, 900.5], [5, 1510.5]]);
assert.deepEqual(plain(site.cumulativeTimes([[1, 10], [3, 20]])), [[2, 10]], "Lücke beendet die Summe");

// LT1: Regeln wie Serializer.Decode
const sample = fixture("runs.lt1");
assert.equal(site.lt1Decode("runs", sample.slice(0, 20) + "\n \t" + sample.slice(20))[1].name, "Zwergö");
assert.equal(site.lt1Decode("run", sample), null, "andere Datenart");
assert.equal(site.lt1Decode("runs", sample + "x"), null, "Rest nach dem Wert");
assert.equal(site.lt1Decode("test", "LT1:test:os.exit()"), null);
assert.equal(site.lt1Decode("test", "LT1:test:n1-2"), null, "keine Zahl");
assert.equal(site.lt1Decode("test", "LT1:test:sa%2"), "a%2", "einzelnes % bleibt");
assert.equal(site.lt1Decode("test", "LT1:test:b0"), false);
assert.equal(site.lt1Decode("test", "LT1:test:n1e3"), 1000);
const nested = depth => "LT1:t:" + "{s1=".repeat(depth - 1) + "{}" + "}".repeat(depth - 1);
assert.notEqual(site.lt1Decode("t", nested(20)), null, "20 Ebenen erlaubt");
assert.equal(site.lt1Decode("t", nested(21)), null, "21 Ebenen abgelehnt");
assert.equal(Object.getPrototypeOf(site.lt1Decode("t", "LT1:t:{s__proto__=n1}")), null, "kein Prototyp");
assert.equal(site.parseRuns("LT1:run:{sname=sX,stimes={n101=n5}}"), null, "Level über MAX_LEVEL");
assert.equal(site.parseRuns("LT1:run:{sname=sX,stimes={n1=n0}}"), null, "Zeit 0");

// CSV aus Export.ToCsv mit Format.lua-Zellen, beide Trennzeichen
for (const file of ["levels_semicolon.csv", "levels_comma.csv"]) {
  const rows = site.parseCsv(fixture(file));
  assert.equal(rows.length, 4, file);
  assert.equal(rows[1][4], "Kalimdor; Teldrassil");
  assert.equal(rows[2][4], 'Zone "Nord"');
  const charts = plain(site.csvCharts(rows));
  assert.deepEqual(charts.map(c => c.title), ["Zeit", "XP/h", "Gold"], file);
  assert.deepEqual(charts[0], { title: "Zeit", xLabel: "Level", duration: true,
    series: [{ name: "Zeit", points: [[1, 95], [2, 3720], [3, 183600]] }] });
  assert.deepEqual(charts[1].series[0].points, [[1, 850], [2, 12300], [3, 2500000]]);
  assert.deepEqual(charts[2].series[0].points, [[1, 0], [2, 56], [3, 0]]);
}
assert.deepEqual(plain(site.parseCell("12.345")), { value: 12345, duration: false }, "Tausender-Trennzeichen");
assert.deepEqual(plain(site.parseCell("1j 2h")), { value: 93600, duration: true });
assert.equal(site.parseCell("Durotar"), null);

console.log("site.test.js: ok");
