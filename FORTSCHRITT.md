# Aschen – Fortschritt

**Stand: v0.2 in Arbeit – Etappe 1 (Gebiete erhellen) zum Testen.** Prototyp v0.1 war fertig mit Build #14.

Spielen im Handy-Browser: **https://mxbstudio.github.io/Ashen/**
Die Build-Nummer oben links im Spiel (z. B. `#5 (abc1234)`) zeigt, welcher Stand geladen ist.

Technik: Godot 4.7.2 · GDScript · Renderer „Compatibility“ · Web-Export ohne Threads.
Bei jedem Push baut `.github/workflows/web-export.yml` die Web-Version und legt sie in den Branch `gh-pages`.

## Etappen

| Etappe | Inhalt | Status |
|---|---|---|
| 0 | Repository, GitHub Action, GitHub Pages, Testszene | fertig, am Handy getestet (>60 FPS) |
| 1 | Kamera, Hüter bewegen und dashen, Testgelände | fertig, am Handy getestet (70–120 FPS) |
| 2 | Licht: Laterne, Feuer, Auffüllen | fertig, am Handy getestet (60–120 FPS) |
| 3 | Skill-Leiste mit Sichelhieb und Bogenschuss | fertig, am Handy getestet |
| 4 | Gegner, Schaden, Tod, Wiedererscheinen | fertig, am Handy getestet |
| 5 | Modifikatoren, weitere Skills, Level-up, Leiste umbauen | fertig, am Handy getestet |
| 6 | Festung, Ressourcen, Gebäude, Bewohner | fertig, am Handy getestet |
| 7 | Belagerung, Leuchtfeuer, Boss, Sieg/Niederlage | fertig, am Handy getestet |
| 8 | HUD fertig, Werte einstellen | fertig – Werte vorerst so belassen |

## Etappe 0 – fertig
- Testszene: sich drehender Würfel im flackernden Feuerschein.
- Debug-Anzeige oben links (immer aktiv): Build-Nummer, FPS, beobachtete Werte, Fehlermeldungen in Rot. Antippen blendet Details ein/aus.
- Hinweis „Bitte Handy drehen“ im Hochformat.

## Etappe 1 – fertig
- Isometrische Kamera (orthografisch, 45° gedreht), folgt dem Hüter sanft.
- Hüter läuft (6 m/s) und dasht (kurzer Sprint in Blickrichtung, 0,6 s Abklingzeit).
- **Hochformat** (auf Wunsch von Max, statt Querformat). Hinweis „Bitte Handy drehen“ erscheint jetzt, wenn das Handy quer gehalten wird.
- Touch: Joystick erscheint, wo der Daumen in der unteren Bildschirmhälfte aufsetzt; Knöpfe „Dash“ und „Trank“ rechts unten.
- Direkte Steuerung: sofort volle Geschwindigkeit, Kamera klebt am Hüter, Figur dreht sich sofort.
- Tastatur: WASD/Pfeile, Leertaste = Dash, Q = Trank (Trank hat noch keine Wirkung).
- Testgelände 60 × 60 m mit Felsen, toten Bäumen und unsichtbarem Rand.
- Alle Spielwerte stehen zentral in `scripts/config.gd`.
- Neue Werte (nicht im Prompt vorgegeben, frei gewählt): Laufgeschwindigkeit 6 m/s, Dash 20 m/s für 0,18 s, Dash-Abklingzeit 0,6 s, Kameraausschnitt 14 m in der Breite.

## Etappe 2 – fertig
- Laterne am Hüter: 180 s Brenndauer, Lichtradius schrumpft von 8 m auf 2 m. Unter 20 % flackert sie stark und der Balken blinkt rot.
- Feuer in der Mitte des Testgeländes: großer warmer Lichtkreis (10 m). Im Ring um das Feuer (3,5 m) füllt sich die Laterne in 3 s ganz auf.
- Licht-Verwaltung (`scripts/light_system.gd`): kann für jede Stelle sagen, ob sie im Licht liegt (für die Gegner in Etappe 4).
- HUD oben rechts: Laternen-Balken.
- Debug-Anzeige: Fehler rot, Hinweise gelb.
- Welt dunkler gemacht (Umgebungslicht, Mond), damit das Licht wirkt.
- Neue Werte (frei gewählt): Auffüllen 3 s, Feuer-Lichtradius 10 m, Auffüll-Abstand 3,5 m.

## Etappe 3 – fertig
- Skill-Leiste mit 3 Slots, läuft automatisch links → rechts im Kreis. Keine Cooldowns, nur Cast-Zeiten.
- Start: Sichelhieb (0,8 s, Bogen vor dem Hüter), Bogenschuss (0,6 s, Pfeil auf den nächsten Gegner), dritter Slot leer (wird übersprungen).
- Die Leiste läuft nur, wenn ein Gegner in 14 m Nähe ist („Leiste ruht“ sonst).
- Dash unterbricht den aktuellen Cast (Fortschritt geht verloren, der gleiche Skill beginnt neu).
- Steht der Hüter still, dreht er sich automatisch zum nächsten Gegner.
- Modifikator-Logik ist schon eingebaut (wird in Etappe 5 freigeschaltet).
- HUD: Leiste über den Touch-Knöpfen, Marker wandert über das aktive Feld, Füllung zeigt den Cast-Fortschritt.
- Rückmeldung beim Auslösen (nach Max' Test: unklar, wann ein Skill auslöst): Ablauf ist *erst ausholen (Feld füllt sich), dann auslösen*. Beim Auslösen blitzt das Feld auf, der Skillname steigt auf, und ein Ring am Boden um den Hüter füllt sich während des Ausholens und platzt beim Auslösen auf. Sichelhieb-Bogen länger sichtbar (0,28 s).
- 4 Übungspuppen (60 Leben, stehen nach 3 s wieder auf) mit Schadenszahlen.
- Neue Werte (frei gewählt): Sichelhieb 12 Schaden / 2,8 m / 150°, Bogenschuss 9 Schaden / 14 m, Kampfreichweite 14 m.

## Etappe 4 – fertig
- **Kriecher** (10 Leben, 5 Schaden, schnell, im Rudel von 3–4): lauern knapp außerhalb des Laternenlichts, kreisen, springen dann hinein, beißen und ziehen sich zurück. Ins Feuerlicht trauen sie sich nicht – am Feuer greifen sie nicht an.
- **Lichtfresser** (20 Leben): fliegen auf die Laterne zu und saugen daran (6 s Laternenlicht pro Sekunde), sichtbar als heller Faden. Verletzen den Hüter nicht.
- **Verlorener** (80 Leben, 18 Schaden, langsam, groß): ignoriert das Licht, holt 0,9 s lang aus (roter Kreis am Boden), dann Schlag – wegdashen!
- **Dunkelheit**: Steht ein Gegner außerhalb jedes Lichtkreises (auch außerhalb der Laterne), macht er +50 % Schaden. Erkennbar an grell roten Augen. Wird die Laterne klein, stehen angreifende Gegner eher im Dunkeln.
- Bis zu 16 Gegner gleichzeitig; neue erscheinen alle 3 s im Dunkeln, mindestens 14 m vom Hüter entfernt.
- **Hüter**: 100 Leben, 3 Tränke (+40). Während des Dashs unverwundbar. Am Feuer: heilt 10/s, Tränke werden aufgefüllt.
- **Tod**: Todesbildschirm 2,5 s, dann erscheint er am Feuer (volles Leben, volle Laterne, 3 s Schutz, blinkt). Die 60 s Zeitverlust wirken ab Etappe 6 auf die Festung.
- Erfahrungspunkte (EP) werden schon gezählt (Kriecher 1, Lichtfresser 2, Verlorener 5) – für die Level-ups in Etappe 5.
- HUD: Leben, Laterne, Tränke oben rechts; roter Bildschirmrand bei Treffern; Lebensbalken über verletzten Gegnern.
- Übungspuppen abgeschaltet.
- Neue Werte (frei gewählt): siehe Abschnitt „Gegner“ in `scripts/config.gd`.

## Etappe 5 – fertig
- **Glutwurf** (Angriff, 0,5 s): brennende Kugel auf den nächsten Gegner, 6 Schaden + 4 Schaden/s für 3 s (Gegner glühen orange).
- **Glockenschlag** (Angriff, 1,6 s): Schockwelle 4,5 m rundum, 10 Schaden, stößt Gegner weg.
- **Labung** (Modifikator): der erste Treffer des nächsten Angriffs heilt 8 Leben (bei Echo: pro Wiederholung einmal).
- **Echo** (Modifikator): nächster Angriff zweimal, Cast ×1,6.
- **Opferlicht** (Modifikator): nächster Angriff ×2,5 Schaden, kostet 15 s Laternenlicht.
- Modifikatoren stapeln sich; ein Modifikator im letzten Feld wirkt auf den ersten Angriff der nächsten Runde.
- **Stufenaufstieg**: Stufe 2 bei 8 EP, jede weitere +6 EP mehr. Spiel pausiert, 1 aus 3 Karten. Jeden Skill höchstens 2×. Sind kaum noch Skills übrig, gibt es Boni (+15 Leben, +20 s Laterne, +1 Trank).
- Neuer Skill landet im ersten freien Feld, sonst im **Vorrat**.
- **Leiste umbauen** am Feuer (Knopf über der Leiste): Feld antippen → anderes Feld (tauschen) oder Vorrat-Skill (einsetzen) oder „Feld leeren“. Nach dem Umbau beginnt die Leiste wieder links.
- HUD: Stufe mit EP-Balken, Hinweis auf Skills im Vorrat.

## Etappe 6 – fertig
- **Karte**: Festung 24 × 24 m (Feuer in der Mitte, Tor in der Nordmauer), davor das dunkle Gebiet (60 × 80 m). Hintere Mauern hoch, vordere niedrig (Kamerasicht). Testgelände entfernt.
- **Tor**: lässt nur den Hüter durch; Gegner kommen nicht in die Festung. Hat 200 Leben (für Etappe 7).
- **Feuer**: verbrennt 1 Holz / 20 s (Start 20). Unter 5 Holz wird der Lichtkreis kleiner. Bei 0 Holz: **Niederlage** („Das Feuer ist erloschen“, Knopf „Neu starten“ setzt alles zurück).
- **Holz** ist ein gemeinsamer Vorrat: Feuer und Gebäude zehren davon. Lagergrenze 30 Holz / 25 Nahrung.
- **Fundstellen** draußen: 10 Holzhaufen (je 5), 6 leuchtende Pilzstellen (je 3 Nahrung). Daneben stehen = automatisch sammeln (0,6 s pro Einheit). Leer → wachsen nach 150 s nach.
- **Trage**: 15 Einheiten. Im Feuerring wird automatisch abgeladen.
- **Gebäude** (Bauplatz betreten → Knopf „… bauen“): Vorratslager 5 Holz (+30 Lagerplatz), Trümmerhof 8 Holz (+1 Holz/45 s), Pilzkeller 8 Holz (+1 Nahrung/40 s), Wachturm 10 Holz (schießt auf Gegner vor dem Tor, 6 Schaden alle 1,5 s). Das letzte Holz bleibt immer fürs Feuer.
- **Bewohner** (5): arbeiten in Pilzkeller, Trümmerhof, Wachturm (in dieser Reihenfolge), die übrigen stehen am Feuer. Jeder isst 1 Nahrung / 60 s. Ohne Nahrung stirbt alle 30 s einer.
- **Tod des Hüters**: 60 s Festungszeit vergehen sofort (Holz brennt, Bewohner essen, Gebäude produzieren).
- HUD: Festung oben links (Holz mit Restzeit, Nahrung, Bewohner – blinkt rot, wenn knapp), Trage oben rechts, kurze Meldungen in der Mitte. Debug-Zeile ist jetzt eingeklappt (antippen zum Aufklappen).
- Neue Werte (frei gewählt): siehe Abschnitte „Feuer & Festung“ und „Sammeln“ in `scripts/config.gd`.

## Nach Max' Test von Etappe 6
- Gelbe Hinweise verdecken die Festungsanzeige nicht mehr (stehen darunter) und verschwinden nach 6 s.
- **Freie Sicht nötig**: Angriffe treffen nur Gegner, zu denen nichts im Weg ist (Mauern, Tor, Gebäude, Felsen, Bäume). Aus der Festung heraus kann man nicht mehr schießen. Idee für später: begehbarer Wachturm (erhöht schießen).
- **Jeder Skill nur einmal.** Beim Stufenaufstieg gibt es neue Skills („NEU“) oder eine Stufe mehr für einen vorhandenen Skill (bis Stufe 5): Angriffe +30 % Schaden je Stufe (Sichel +0,3 m Reichweite, Glut +1,5 Brand/s, Glocke +0,5 m Radius), Labung +4 Heilung, Echo −0,15 Cast-Verlängerung, Opferlicht +0,5× Schaden. Stufe steht im Feld (z. B. „Sichel III“).
- **Mehr Felder**: bei Hüter-Stufe 6 und 11 (zuerst 4 und 7) je ein weiteres Feld (max. 5). Liegt ein Skill im Vorrat, rückt er direkt ins neue Feld.

## Geänderte Werte
| Wert | vorher | jetzt | Grund |
|---|---|---|---|
| Bildschirm | Querformat | Hochformat | Wunsch Max |
| Joystick | analog (halb geschoben = halb so schnell) | sofort volle Geschwindigkeit (`joystick_analog = false`) | fühlte sich weich/langsam an |
| Kamera-Folgen | weich (8) | direkt (0) | fühlte sich weich an |
| Skills besitzen | bis zu 2× derselbe Skill | jeder Skill 1×, dafür Skill-Stufen 1–5 | Wunsch Max |
| Skill-Felder | immer 3 | 3, +1 bei Stufe 4 und 7 | Wunsch Max |
| Extra-Felder | bei Stufe 4 und 7 | bei Stufe 6 und 11 | kamen zu schnell |
| Opferlicht-Kosten | 15 s Laterne | 4 s Laterne | zog viel zu viel Licht |
| Belagerung Größe | 12 (+4), letzte 22 | 18 (+6), letzte 30 | zu leicht |
| Torschaden pro Sekunde | Kriecher 0,8 / Lichtfresser 0,5 / Verlorener 2,5 | 1,6 / 1,0 / 5,0 | zu leicht |
| Bewohner-Verteidigung | 3 Schaden, 2,5 s | 2 Schaden, 3,5 s | zu leicht |

## Etappe 7 – fertig
- **Belagerung** alle 8 min: 30 s vorher flackert das Feuer unruhig („Das Feuer flackert unruhig …“, kein Countdown). Dann läutet die Glocke (heller Blitz), Angreifer erscheinen in Gruppen vor dem Tor (12, jede weitere +4) und schlagen aufs Tor (Anzeige „BELAGERUNG“ mit Torleben und Angreifern). Normale Gegner erscheinen währenddessen nicht.
- Belagerer greifen nur das Tor an – den Hüter nur, wenn er näher als 3 m steht.
- **Verteidigung**: Bewohner schießen von der Mauer (je mehr Bewohner, desto öfter), Wachturm schießt mit.
- **Tor fällt** → ein Bewohner stirbt, Angreifer ziehen ab, Tor wird repariert.
- **Leuchtfeuer** in der Mitte des Gebiets: 1,5 s daneben stehen → entzündet. Eigener Lichtkreis (7 m), füllt die Laterne auf, Kriecher meiden es. **Schnellreise**: Knopf am Leuchtfeuer („zum Tor“) und innen am Tor („zum Leuchtfeuer“).
- **Boss** „Der verwandelte Hauptmann“ (800 Leben) in der Arena hinten (Steinkreis): greift ab 15 m an. Nahkampfschlag (20, 0,8 s Vorwarnung) und alle 6 s Flächenangriff auf die Position des Hüters (30 Schaden, 3,5 m, 1,4 s roter Kreis). Entfernt man sich > 30 m oder stirbt, kehrt er zurück und heilt. Boss-Lebensbalken oben.
- **Sieg**: Boss besiegt → letzte Belagerung (22 Angreifer) kommt nach ~35 s. Hält das Tor → „Das Feuer brennt weiter – Sieg!“. Fällt es, gibt es nach 60 s einen neuen Anlauf.
- **Niederlage**: Feuer erlischt (wie bisher).
- **Wald**: dichter Wald aus toten Bäumen (alle Stämme in einem Rutsch gezeichnet für gute Leistung), freier, leicht geschlängelter Weg vom Tor über das Leuchtfeuer zur Boss-Arena; Lichtung vor dem Tor für Belagerungen.
- Tod verschiebt auch die nächste Belagerung um 60 s nach vorn.
- „Leiste umbauen“ nur am Feuer, nicht am Leuchtfeuer.

## Nach Max' Test von Etappe 7
- **Schnellreise-Knopf repariert**: Er schaltete sich jedes Bild kurz unsichtbar → Fingertipp ging verloren (am PC fiel das nicht auf).
- **Belagerung härter**: 18 Angreifer (+6 je weitere), letzte 30; Torschaden verdoppelt; Bewohner schießen schwächer (2 Schaden, alle 3,5 s geteilt durch Anzahl).
- **Vorzeichen deutlicher** (war draußen nicht zu bemerken): Feuer-Zeile im HUD flackert („Feuer flackert …“), Laterne zuckt mit, alle 7 s ein dumpfes Grollen.
- **Platzhalter-Sound** (im Code erzeugt, kein FMOD, keine Dateien): Glocke, Grollen, Treffer, Schwung, Schuss, Schlag, Verletzung, Tod, Aufsammeln, Level-up, Entzünden. Lautstärke: `volume_db` in `scripts/sfx.gd`.
- **Boss leichter zu finden**: rotes Glühen über der Arena, Schild „Arena des Hauptmanns“, Hinweis nach dem Entzünden des Leuchtfeuers.

## Etappe 8 – HUD fertig
- **Werte-Menü** (Knopf „Werte“ oben Mitte): 18 wichtige Werte mit − / + im Spiel verändern (Belagerung, Tor, Feuer, Nahrung, Laterne, Gegnerzahl/-schaden, Boss, Skill-Schaden, EP, Tempo, Kamera, Lautstärke). Spiel pausiert solange. Werte gelten bis zum Schließen des Browsers, auch nach „Neu starten“. „Änderungen anzeigen / kopieren“ listet die Abweichungen vom Standard und kopiert sie in die Zwischenablage → an Claude schicken, dann werden sie fest in `config.gd` übernommen.
- **Wegweiser** am Bildschirmrand: Pfeil zum Tor (orange) und zum entzündeten Leuchtfeuer (blau), wenn sie nicht im Bild sind und der Hüter draußen ist.
- **Ziel-Hinweis** beim Start (3 Zeilen, 6 s).
- HUD-Übersicht: oben links Festung (Feuer/Holz mit Restzeit bzw. „Feuer flackert …“ als Vorzeichen, Nahrung, Bewohner); oben rechts Leben, Laterne, Tränke, Stufe/EP, Trage, Vorrat; oben Mitte Belagerung/Boss; Mitte kurze Meldungen; unten Skill-Leiste mit Marker über Joystick/Dash/Trank.

## Ideen für später (v0.2) – von Max beim Testen
- ~~**Wald** außerhalb der Festung~~ → in Etappe 7 umgesetzt.
- **Sicht nur, was der Hüter wirklich sieht** (Gegner hinter Bäumen/Mauern unsichtbar). Schießen nur mit freier Sicht gibt es schon.
- **Gebiete erhellen statt selbst sammeln**: Draußen Gebiete hell machen (z. B. per Leuchtfeuer), dann Bewohner als Holzfäller und Jäger/Sammler dorthin schicken.
- **Gebäude-Upgrades.**
- **Begehbarer Wachturm**: erhöht stehen und von dort schießen.

---

# Version v0.2 – Licht erobern statt selbst sammeln

Ziel: Der Hüter macht draußen Gebiete hell; in erhellten Gebieten arbeiten Bewohner.

| Etappe | Inhalt | Aufwand | Status |
|---|---|---|---|
| 1 | Gebiete erhellen: Zonen, Fackelpfähle, Brennstoff, Lichtfresser löschen | mittel | zum Testen |
| 2 | Bewohner als Holzfäller / Sammler in helle Zonen schicken | groß | offen |
| 3 | Gebäude-Upgrades (2–3 Stufen) | mittel | offen |
| 4 | Begehbarer Wachturm | mittel | offen |
| 5 | Speicherstand im Browser | mittel | offen |
| 6 | Werte einstellen mit Max | klein | offen |

## Etappe 1 – Gebiete erhellen
- **5 Zonen** draußen (Daten in `scripts/zones/zone_defs.gd`): Westsenke, Osthain, Leuchtfeuer, Pilzmoor, Nordwald.
  Jede Zone hat 3 Fundstellen. Eine einzelne Holzstelle vor dem Tor gehört zu keiner Zone.
- **Fackelpfahl** (`scripts/zones/torch_post.gd`): In 4 Zonen gibt es einen Fackelplatz (heller Kreis am Boden mit Namen).
  Daneben stehen → Knopf „Fackelpfahl errichten (4 Holz)“. Holz kommt zuerst aus der Trage, der Rest aus dem
  Lager der Festung (das letzte Holz bleibt fürs Feuer).
- **Brennstoff**: Eine Fackel fasst 4 Holz, jedes brennt 90 s (voll = 6 min). Knopf „Holz nachlegen (1 Holz)“.
  Unter 30 s wird der Lichtkreis kleiner und es kommt eine Warnung. Erloschen → „Fackel entzünden (1 Holz)“,
  der Pfahl bleibt stehen.
- **Sicherer**: Kriecher meiden den Lichtkreis (8 m) wie beim Feuer, und dort erscheinen keine neuen Gegner.
  Die Laterne füllt sich an Fackeln *nicht* auf (das können nur Feuer und Leuchtfeuer).
- **Gelöscht werden**: Alle 45 s schickt die Dunkelheit einen Lichtfresser zu einer zufälligen brennenden Fackel.
  Er frisst 8 s Brenndauer pro Sekunde (volle Fackel in ~45 s leer). Meldung „Ein Lichtfresser frisst an der Fackel …!“,
  die Fackel zuckt, ihre Schrift wird rot und ein roter Wegweiser „Fackel!“ zeigt die Richtung.
- Die Leuchtfeuer-Zone braucht keinen Fackelpfahl – das Leuchtfeuer macht sie hell (wie bisher, ohne Brennstoff).
- Beim Tod des Hüters brennen auch die Fackeln 60 s weiter herunter.
- HUD: neue Zeile „Fackeln: x / 4 brennen“ (blinkt rot bei Angriff). Gelbe Hinweise stehen jetzt etwas tiefer.
- Werte-Menü: Fackel-Kosten, Sekunden pro Holz, Lichtradius, Raubzug-Abstand.
- Neue Werte (frei gewählt): siehe Abschnitt „Zonen & Fackelpfähle“ in `scripts/config.gd`.
- Das eigene Sammeln des Hüters bleibt in Etappe 1 noch wie bisher (wird in Etappe 2 ersetzt).
