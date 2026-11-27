# Aschen – Fortschritt

**Stand: v0.3 „Tiefe“ zum Testen: Leiste als Puzzle (Kombos, Abzweigungen, Talismane), Bewohner mit Eigenleben, Wahnsinn.** v0.2 fertig bis auf Werte-Feinschliff. Prototyp v0.1 war fertig mit Build #14.

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
| Trage des Hüters | 15 | 6 | v0.2: Sammeln übernehmen die Bewohner |
| Sammeln des Hüters | 0,6 s pro Einheit | 1,2 s | v0.2: Sammeln übernehmen die Bewohner |
| Bewohner am Start | 5 | 7 | Max: „bräuchte mehr Dorfbewohner“ |
| Nahrung pro Bewohner | alle 60 s | alle 75 s | damit 7+ Bewohner satt werden |
| Holz-Fundstellen | 10 Holzhaufen à 5 Holz | jeder Baum im Wald fällbar (~190) à 25 Holz | Wunsch Max |
| Pilzstellen | 6 à 3 Nahrung, nachwachsen 150 s | 13 à 5 Nahrung, nachwachsen 120 s | Max: mehr Nahrung |
| Pilzkeller | 1 Nahrung / 40 s | 1 Nahrung / 30 s | Max: mehr Nahrung |
| Nahrung am Start | 15 | 25 | Max: mehr Nahrung |
| Bewohner-Leben | 25 | 40 | auf dem dunklen Weg zur Zone starben zu viele |
| Kriecher bemerken Bewohner ab | 10 m, Biss alle 2 s | 7 m, Biss alle 2,5 s | ebenso |
| Schaden an Bewohnern | voll | ×0,5 | Probelauf: Kriecher-Rudel vor dem Tor |
| Lichtfresser-Raubzug | alle 45 s, 8 s/s | alle 90 s, 5 s/s | Probelauf: Fackel-Nachlegen fraß mehr Holz als gehackt wurde |
| Arbeiter pro Gang | 2 | 3 | Probelauf: zu viel Lauferei |

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

## Für eine spätere Etappe gemerkt (Max)
- **Bewohner mit eigenständigem Leben**: Jeder hat Hunger und andere Bedürfnisse, die er sich selbst erfüllt.
  **Arbeitszeiten**, in denen fürs Lager gearbeitet wird; in der **Freizeit** z. B. selbst Holz hacken und ein
  **eigenes Haus bauen**, Nahrung für zu Hause sammeln, **sich paaren und Kinder bekommen**, **für den Kampf trainieren** usw.
  (Noch nicht umgesetzt – eigene Etappe.)

## Ideen für später (v0.2) – von Max beim Testen
- ~~**Wald** außerhalb der Festung~~ → in Etappe 7 umgesetzt.
- **Sicht nur, was der Hüter wirklich sieht** (Gegner hinter Bäumen/Mauern unsichtbar). Schießen nur mit freier Sicht gibt es schon.
- **Gebiete erhellen statt selbst sammeln**: Draußen Gebiete hell machen (z. B. per Leuchtfeuer), dann Bewohner als Holzfäller und Jäger/Sammler dorthin schicken.
- **Gebäude-Upgrades.**
- **Begehbarer Wachturm**: erhöht stehen und von dort schießen.

---

# Version v0.3 – Tiefe (zum Testen)

Max: „Es wirkt mir noch nicht deep genug.“ Diagnose: viele Systeme, aber fast jede Entscheidung war „mehr ist besser“.
v0.3 baut **Abwägungen** ein – in drei Teilen. Danach: echte Grafik → Meta-Fortschritt/Herkünfte/Story.

| Teil | Inhalt | Status |
|---|---|---|
| Sicht | Gegner nur bei freier Sicht, im Dunkeln nur Augen | zum Testen |
| 1 | Leiste als Puzzle: Zustände & Kombos, Lage zählt, Abzweigungen, Talismane | zum Testen |
| 2 | Bewohner mit Eigenleben: Namen, Eigenschaften, Stimmung, Trauer, Gräber, Ereignisse | zum Testen |
| 3 | Wahnsinn: steigt im Dunkeln, macht stärker, dunkle Skills, Trugbilder, Bewohner fürchten dich | zum Testen |

Automatisch geprüft (headless, Godot 4.7.2): alle Skripte laden fehlerfrei; Testlauf mit Kombos, Schwur, Sanduhr,
dunklen Skills, Schrein, Tod/Trauer/Grab, Rückkehr von der Suche, allen 7 Ereignissen, Speichern/Laden,
Abzweigungs-Karten; Dauerlauf 10 Spielminuten (8-fach) mit Belagerung ohne Laufzeitfehler. **Am Handy noch nicht getestet.**

## Teil 1 – Leiste als Puzzle
- **Zustände & Kombos** (Gegner verfärben sich):
  - Glockenschlag **erschüttert** 2 s (hellblau, Gegner nur 35 % so schnell).
  - Glut / Zündschnur / Glutkrone setzen **in Brand** (orange).
  - Bogen „Markieren“ **markiert** 4 s (violett): +35 % Schaden von allem (auch Turm und Bewohner).
  - **Zerschmettern**: Sichel trifft Erschütterte → doppelter Schaden. Reihenfolge Glocke → Sichel lohnt sich.
  - **Entfachen**: Glocke trifft Brennende → restlicher Brandschaden sofort ×1,5.
  - **Flammenpfeil**: Bogen trifft Brennende → Explosion (2,2 m), Nachbarn brennen mit.
  - Kombos stehen als gelber Schriftzug über dem Gegner.
- **Neue Modifikatoren, bei denen die Lage zählt:**
  - **Zündschnur**: nächster Angriff setzt alle Getroffenen in Brand – macht Kombos mit jedem Angriff möglich.
  - **Spiegel**: löst das Feld *davor* noch einmal aus (Angriff 70 %, Modifikator ganz).
  - **Schwur**: im *letzten* Feld → die ganze nächste Runde +25 % Schaden (Anzeige „Schwur +25 %“ über der Leiste).
    Anderswo nur der nächste Angriff +10 %.
- **Abzweigungen**: Beim Aufstieg eines Skills auf Stufe 3 wählt man eine von zwei Regeln (für immer). Beispiele:
  Sichel *Wirbel* (rundum, −20 %) oder *Ernte* (unter 25 % Leben → tot); Bogen *Salve* oder *Markieren*;
  Glut *Flächenbrand* oder *Funkentod*; Glocke *Sog* (zieht heran) oder *Lichtglocke* (+1 s Laterne pro Treffer);
  Echo *Nachhall* oder *Dreiklang*; Opferlicht *Blutopfer* (Leben statt Licht) oder *Wahnopfer* (Wahnsinn statt Licht) …
  Alle in `scripts/skill_data.gd` → `BRANCHES`. Die Abzweigung steht im Umbau-Menü unter dem Skill.
- **Talismane** (Ausrüstung, `scripts/talisman_data.gd`): 11 Stück, biegen Regeln um, z. B. *Pendel*
  (Leiste läuft hin und zurück), *Leerer Kelch* (leere Felder geben Laternenlicht), *Glockenseil* (jeder 3. Angriff doppelt),
  *Bleiche Hand* (Modifikatoren wirken zweimal), *Hast-Amulett* (schneller, aber verwundbarer), *Wahnstein* …
  - Höchstens **2 angelegt**; an-/ablegen im Menü „Leiste“ (unten, antippen) – inzwischen überall.
  - Fundorte: **6 Schreine** im Dunkeln (violettes Glühen, 1,5 s daneben stehen, +5 Wahnsinn), Verlorene (12 %),
    der Hauptmann, das Ereignis „Fund in den Trümmern“.
- Umbau-Menü scrollt jetzt (wegen der Talismane).

## Teil 2 – Bewohner mit Eigenleben
- Jeder Bewohner hat einen **Namen** und **1–2 Eigenschaften** (`scripts/fortress/resident_data.gd`):
  Flink, Kräftig, Zäh, Guter Schütze, Fleißig, Genügsam, Vielfraß, Prediger, Kränklich, Feuerhüter, Ängstlich –
  jede wirkt wirklich (Tempo, Tragen, Leben, Schaden, Essen, Feuerverbrauch …).
- Am Start sind zwei Paare **verbunden** (Geschwister / Paar). Stirbt einer, **trauert** der andere 4 min
  (arbeitet langsamer, Stimmung stark unten).
- **Stimmung** 0–100 strebt einem Zielwert zu: satt (+), Feuer sicher (+), Prediger (+), gekürzte Rationen (−),
  Hunger (−−), Wahn des Hüters (−). Sofort-Schocks: Tod (−12 für alle), Tor gefallen, Belagerung gehalten (+10).
  - zuversichtlich (≥ 75): +15 % Arbeitstempo · verzweifelt (< 25): halbes Tempo.
  - Unter 15 kann ein Bewohner die Festung **verlassen**. Ängstliche gehen bei schlechter Stimmung nicht hinaus.
- **Gräber** mit Namen an der Westmauer (innen). Meldungen nennen Namen („Hanna wurde draußen getötet.“).
- **Name über dem Kopf**, wenn der Hüter in der Nähe ist (Farbe = Stimmung).
- Menü „Bewohner einteilen“: neuer Abschnitt **Leute** (Name, Eigenschaften, Stimmung, Arbeit, Verbindung, Gräber).
  HUD: „Bewohner: 7 · gefasst“ (Farbe = Durchschnittsstimmung).
- **Ereignisse** (`scripts/ui/event_panel.gd`): etwa alle 3,5 min (nicht bei Belagerung/Vorzeichen), Spiel pausiert,
  zwei Antworten mit Preis: Fremder am Tor (krank – aufnehmen?), Die Suche (Verwandte suchen – vielleicht nie zurück),
  Leere Vorräte (Rationen kürzen?), Streit am Feuer, Fund in den Trümmern (Talisman oder Opfer), Prediger der Dunkelheit
  (verbannen?), Gebet für den Hüter (bei Wahn ≥ 50: −25 Wahnsinn gegen Nahrung).

## Teil 3 – Wahnsinn
- **Wahn-Balken** oben rechts unter der Laterne (Stufen: klar · unruhig 25 · gezeichnet 50 · verloren 75).
- **Steigt** draußen außerhalb fester Lichtquellen (0,15/s), schneller bei Laterne < 30 % (+0,35/s) und leer (+1/s),
  durch dunkle Skills, Schreine, Wahnopfer. **Sinkt** nur langsam am Feuer (0,3/s, Prediger helfen), beim Tod (−25),
  durch das Gebet-Ereignis.
- **Macht stärker**: +10 % Schaden je Stufe. Ab 25 bietet der Stufenaufstieg **dunkle Skills** an:
  *Schattenriss* (Linie, stärker mit Wahn), *Leerenschrei* (Gegner fliehen, Lichtfresser lassen los),
  *Schattenpakt* (Modifikator, Schaden mit dem Wahn). Sie nähren den Wahn.
- **Kostet**: violetter Bildschirmrand, **Flüstern** (violette Schrift), ab 50 **Trugbilder** (falsche Augen im Dunkeln),
  die Anzeige **lügt** kurz (Laterne, Bewohnerzahl), die **Bewohner fürchten dich** (Stimmung −12 / −25).
  Ab 75 springen Trugbilder dich an. Bei 100 zehrt der Wahn am Leben (2/s, tötet aber nicht).
- Verbindung der drei Teile: Wer draußen ins Risiko geht, wird stärker – belastet damit aber die Festung.

### Nach Max' Test von v0.3
- **Scrollen repariert**: In „Leiste umbauen“ konnte man am Handy nicht richtig nach unten scrollen – die großen Knöpfe
  (Felder, Talismane) haben das Wischen abgefangen. Jetzt geben Knöpfe in scrollbaren Menüs das Wischen an die Liste
  weiter (`UiStyle.pass_touch`); Antippen löst sie weiter aus, Wischen nicht. Gilt auch für „Bewohner einteilen“
  und das Werte-Menü.
- **Leiste und Bewohner überall verwalten** (Wunsch Max): Zwei Knöpfe oben links unter der Festungsanzeige,
  **„Leiste“** (Leiste umbauen, Vorrat, Talismane) und **„Bewohner“** (einteilen, Leute) – nicht mehr nur am Feuer.
  Das Spiel pausiert, solange ein Menü offen ist. Die großen Knöpfe am Feuer gibt es dafür nicht mehr.

### Nach Max' Test von v0.3: Feinschliff
- **Ladekreis beim Abbauen**: Steht der Hüter an einem Baum, Felsen oder einer Pilzstelle, füllt sich ein Ring am Boden
  darum, bis die nächste Einheit fertig ist (`scripts/gather_ring.gd`).
- **Bögen holen sie sich selbst**: Jeder Bogen im Lager geht automatisch an einen Bewohner ohne Bogen (wer draußen
  arbeitet, zuerst); wer einen hat, behält ihn. Das − / + im Menü ist weg (dort steht nur noch „x von y“).
- **Der Bogner ruft**, wenn ein Bogen fertig ist: Sprechblase über ihm („Ein Bogen ist fertig!“), Ruf-Klang, Meldung mit
  Namen – danach „Hanna holt sich den neuen Bogen.“
- **Pendel statt Umgekehrter Sanduhr** (die ergab wenig Sinn – man kann die Felder ja umordnen): Die Leiste läuft
  links → rechts → zurück → … Bei 5 Feldern: 1 2 3 4 5 4 3 2 1 2 … – die mittleren Felder kommen doppelt so oft dran
  wie die äußeren. Der Spiegel kopiert das zuletzt gelaufene Feld (auf dem Rückweg also das rechte).
  Alte Spielstände: die Sanduhr wird zum Pendel.
- **Werkzeuge** (Menü „Bewohner“ → „Werkzeuge“): Axt (Holz), Spitzhacke (Stein), Sammelkorb (Nahrung), je 3 Stufen,
  jede Stufe +35 % schneller – für den Hüter und die Bewohner. Kosten 6/10/16 Holz + 4/8/14 Stein.
  Stellt die Werkstatt her: Werkzeug-Stufe höchstens so hoch wie die Werkstatt-Stufe.
- **Weniger Talismane**: nur noch 3 Schreine (statt 6), Verlorene lassen nur noch selten einen fallen (3 % statt 12 %),
  das Ereignis „Fund in den Trümmern“ nur, solange man weniger als 3 Talismane hat.
- **Kriecher greifen von hinten an**: Sie wandern auf ihrem Kreis hinter den Hüter (jeder etwas versetzt) und springen
  erst an, wenn sie hinten bzw. seitlich sind; wer vorne steht, läuft seitlich herum. Achtung: Steht der Hüter still,
  dreht er sich zum nächsten Gegner – „hinten“ ist dann der Rücken zu diesem. Messung: die Hälfte der Angriffe beginnt
  hinter ihm, fast alle anderen seitlich.
- **Kriecher sind lichtscheu, aber nicht lichtdicht**: Kein hartes Wegstoßen mehr aus dem Licht. Sie lauern lieber am
  Rand, laufen im Licht langsamer, laufen aber hindurch und greifen auch im Licht von Fackeln/Feuerstellen an
  (mit 35 % Mut je Anlauf). In die Festung kommen sie weiter nicht.
- **Angeschaut weichen sie zurück** (Max): Steht ein Kriecher im Blickkegel des Hüters (50° zu jeder Seite), lauert er
  3 m weiter draußen und greift nicht an; ein laufender Anlauf wird abgebrochen (außer er ist schon näher als 1,8 m).
  Nur hinter dem Rücken trauen sie sich heran. Messung mit fester Blickrichtung: 21 von 21 Bissen kamen von hinten.
  Werte-Menü: „Kriecher: Blickkegel Grad“ (0 = weichen nie zurück), „Kriecher: Mut im Fackellicht“.
- Neue Werte: `crawler_gaze_angle` (50°), `crawler_gaze_backoff` (3 m), `crawler_light_courage` (0,35), `tool_speed_per_level` (0,35), `tool_cost_wood`, `tool_cost_stone`;
  `lost_talisman_chance` 0,12 → 0,03.

### Karren, sekundengenauer Feuer-Timer, Reserve (Wunsch Max)
- **Lagerplätze** an jeder Fackel (und am Leuchtfeuer) (`scripts/zones/depot.gd`): kleine Stapel mit Schild
  („Lager: 11 Holz · 6 Nahrung“), je Rohstoff höchstens 20.
- **Karrenschuppen** (neuer Bauplatz rechts vom Feuer, 10 Holz, 3 Stufen = 1/2/3 Karren, je ein Bewohner als Fahrer).
  - Gibt es einen Karren mit Fahrer, legen Holzfäller, Sammler und Steinbrecher ihre volle Ladung **an der Fackel ab**
    und arbeiten sofort weiter (kein Weg zum Feuer mehr). Ist der Stapel voll, tragen sie selbst heim wie bisher.
  - **Karrenfahrer** fahren zum hellsten/vollsten Lagerplatz (nur helle Zonen, ab 4 Einheiten, nie zwei zum selben),
    laden 2 s auf (bis 15, das Dringendste zuerst, nur was in der Festung noch Platz hat) und bringen alles zum Feuer.
    Mit Karren sind sie langsamer (2,2 m/s). Getroffen -> Flucht heim, die Ladung kommt mit. Bei Belagerung: alle heim.
  - Probelauf (Westsenke, 2 Holzfäller, 1 Sammler, 1 Karren, 5 min): 24-mal an der Fackel abgelegt, 5 Karrenfahrten,
    Holzlager der Festung durchgehend fast voll.
  - Gespeichert: Vorrat der Lagerplätze. (Was gerade auf einem Karren liegt, geht beim Laden verloren.)
- **Feuer-Timer sekundengenau**: zählt jetzt jede Sekunde herunter (vorher in 20-s-Schritten, weil nur ganze Scheite zählten).
- **Reserve 5**: Holz und Nahrung im Lager dürfen nicht unter 5 fallen, wenn etwas *verbraucht* wird – Bauen,
  Verbessern, Werkzeuge, Fackeln, Feuerstellen, Bögen, Nachlegen und Holz-Botengänge der Bewohner, Ereignisse.
  Nur das Feuer und das Essen dürfen die letzten 5 nehmen. Holz aus der Trage des Hüters darf er weiter frei verwenden.
  Knöpfe zeigen dann „Nicht genug Holz – 5 bleiben fürs Feuer“.
- Neue Werte: `vital_reserve` (5), `cost_carts` (10), `cart_capacity` (15), `cart_speed` (2,2), `cart_min_load` (4),
  `depot_cap` (20 je Rohstoff).

### Wahn-Entscheidungen, Talismane und Licht gegen den Wahn, Angriffe nur in Reichweite (Wunsch Max)
- **Entscheidungen des Wahns**: Ab Wahnsinn 75 („verloren“) gibt es nur noch diese Ereignisse – und öfter (×0,6 Abstand).
  Violetter Titel „Der Wahn spricht“, zwei rote Knöpfe, **beide Antworten schlecht**:
  *Der Dieb* (sofort töten / vor allen hinrichten), *Der Blick* (in die Dunkelheit jagen / ohne Laterne Holz holen
  schicken), *Gift* (halbes Holz / halbe Nahrung wegwerfen), *Das Opfer* (einen Bewohner opfern, −20 Wahnsinn /
  eigenes Blut: −15 maximales Leben für immer), *Verschwörung* (zwei einsperren ohne Essen / einen töten).
  Wert: `madness_event_threshold` (75).
- **Talismane gegen den Wahn**: *Herdstein* – am Feuer der Festung sinkt der Wahnsinn dreimal so schnell;
  *Glutamulett* – der Wahnsinn sinkt auch an Fackeln, Feuerstellen und am Leuchtfeuer.
- **Licht-Skills** (gelb, im Stufenaufstieg „LICHT:“, immer im Angebot): senken den Wahnsinn und sind stärker, je klarer
  der Geist ist (×1,3 bei Wahn 0 bis ×0,7 bei Wahn 100) – das Gegenstück zu den dunklen Skills.
  - *Läuterung* (Angriff, 1,0 s): Lichtwelle rundum 4 m, 8 Schaden, −1,5 Wahnsinn.
    Abzweigung: *Heilige Flamme* (Getroffene brennen) oder *Reinigung* (doppelt Wahn weg, halber Schaden).
  - *Lichtlanze* (Angriff, 0,9 s): Strahl auf den nächsten Gegner, 12 Schaden, −0,8 Wahnsinn.
    Abzweigung: *Durchbohren* (alle auf der Linie) oder *Blenden* (2 s erschüttert → Sichel zerschmettert).
  - *Andacht* (Modifikator): nächster Angriff senkt den Wahnsinn um 3.
    Abzweigung: *Tiefe Andacht* (doppelt) oder *Lichtsegen* (+20 % Schaden).
- **Leiste: wie vorher, plus AUS-Knopf** (Max): Die Leiste ist standardmäßig **an** und lädt, sobald irgendein
  Angriff der Leiste einen Gegner in Reichweite hat (+2 m Puffer, `bar_range_margin`). Mit dem Knopf
  **„Leiste: AN/AUS“** (links über der Leiste, Taste **R**) lässt sie sich ganz abschalten.
- **„Bitte Handy drehen“ am PC repariert**: Die Meldung kam, sobald das Fenster quer war und der Browser einen
  Touch-Bildschirm meldete – das tun auch viele PC-Browser. Jetzt nur noch auf Android/iOS. Zusätzlich hat die Meldung
  einen Knopf „Trotzdem spielen“.

### Feinschliff nach Max' Test (PC, 21:9)
- **Neue Felder bleiben leer**: Ein neues Feld (Stufe 6/11) bleibt leer, und neue Skills aus dem Stufenaufstieg kommen
  immer in den **Vorrat** – einsetzen im Menü „Leiste“.
- **Lichtlanze**: jetzt *stärker, je wahnsinniger* (×0,7 bei Wahn 0 bis ×1,3 bei Wahn 100). Läuterung bleibt
  stärker mit klarem Geist.
- **Tasten am PC** (stehen auch auf den Knöpfen, am Handy nicht): **E** Bauen/Verbessern/Fackel, **F** Turm
  besteigen/herabsteigen/Schnellreise, **L** Menü „Leiste“, **B** Menü „Bewohner“ (nochmal drücken schließt),
  **R** Leiste an/aus. Dazu WASD, Leertaste (Dash). (Neuere Belegung siehe unten: Q Leiste, 1 Trank, G Abladen.)
- **Breitbild (z. B. 21:9)**: Alle Anzeigen und Menüs stehen in einer mittigen Spalte (höchstens 3:4 der Höhe breit)
  statt an den Bildschirmrändern (`UiStyle.column`).
- **Leben, Laterne, Wahn an der Spielfigur**: links ein roter Balken (Leben, mit Zahl), rechts ein oranger
  (Laterne) und ein schmaler violetter mit Stufen-Strichen (Wahn, darunter die Stufe). Oben rechts stehen nur noch
  Tränke, Stufe/EP, Trage, Vorrat.
- **Belagerung: keine schießende Mauer mehr.** Die Bewohner steigen auf den **Wachturm** und schießen sichtbar von
  oben (Plätze: Stufe 1: 4, Stufe 2: 6, Stufe 3: 8). Wer später heimkommt, steigt nach. Bewaffnete schießen mit dem
  Bogen (5 Schaden), Unbewaffnete 2, gute Schützen doppelt. **Ohne Wachturm schießt niemand** – der Turm wird damit
  wichtig. Nach der Belagerung steigen alle wieder herunter.
- Talisman **Pendel**: Beschreibung nur noch „Die Leiste pendelt: links → rechts → zurück“.

### Licht stärker mit Wahn, Tasten, räumlicher Klang, Haufen draußen (Wunsch Max)
- **Alle Licht-Skills sind stärker, je wahnsinniger man ist** (wie die dunklen): ×0,7 bei Wahn 0 bis ×1,3 bei
  Wahn 100. Einheitliche Beschreibung bei allen: „… Stärker, je wahnsinniger du bist“ bzw. „Nährt / Senkt den
  Wahnsinn“.
- **Tasten neu**: **Q** Menü „Leiste“ (vorher L), **1** Trank (vorher Q), **G** Trage als Haufen abladen.
  Übrige: E Bauen/Fackel, F Turm/Schnellreise, B Bewohner, R Leiste an/aus, WASD, Leertaste Dash.
  Unter Dash/Trank steht am PC die Taste.
- **Räumlicher Klang** (`Sfx.play_at`): Treffer, Schläge, Bewohner, Turm-Schützen, Fackeln, Bauen, Bogner-Ruf …
  kommen vom Ort des Geschehens: leiser mit der Entfernung zum Hüter, links/rechts verteilt, ab 34 m gar nicht,
  die Festungsmauer dämpft um 14 dB. Den **Bogner hört man draußen nicht** – und dann gibt es auch keine Meldung.
  Glocke und Grollen der Belagerung bleiben überall hörbar.
- **Am Leuchtfeuer wird nicht mehr in die Festung abgeladen** (nur noch am Feuer der Festung).
- **Haufen draußen**: An jedem Lagerplatz draußen – an den Fackeln, am Leuchtfeuer und **neu an jeder Feuerstelle** –
  erscheint der Knopf **„Abladen (Haufen)“** (Taste G): die Trage kommt auf den Haufen, die Karren holen ihn ab,
  solange das Feuer dort brennt. Feuerstellen-Haufen werden mitgespeichert.

### Ziehen und Ablegen, Belagerungs-Fehler (Max)
- **Menü „Leiste“ per Ziehen und Ablegen** (Finger oder Maus): Feld auf Feld = tauschen · Vorrat-Skill auf ein Feld =
  einsetzen (ein Skill, der dort war, wandert in den Vorrat) · Feld in den Bereich „Vorrat“ = herausnehmen.
  Antippen funktioniert weiter wie bisher. Die Skill-Knöpfe scrollen das Menü dabei nicht mit.
- **Fehler behoben: „1 Angreifer“, aber keiner zu sehen.** Ursache: Angreifer erschienen nur, solange unter der
  Höchstzahl gleichzeitiger Gegner (16) Platz war – mitgezählt wurden aber auch der Hauptmann und umherstreifende
  Gegner. War das voll, erschien der letzte Angreifer nie und die Belagerung blieb offen. Jetzt:
  - es zählen nur die Angreifer selbst,
  - beim Glockenschlag ziehen sich Streuner weit weg vom Hüter (> 20 m) zurück,
  - ein Angreifer, der 5 s nicht näher ans Tor kommt (Baum, Fels), springt auf den Platz vor dem Tor,
  - bei höchstens 3 übrigen Angreifern zeigen rote Wegweiser „Angreifer“ zu ihnen (auch von drinnen).

### Bewohner stehen nicht mehr untätig an der Fackel (Max)
- **Ursache**: War im Fackellicht ihrer Zone nichts mehr zu holen (Bäume gefällt – wachsen erst nach 6 min nach –,
  Pilze leer), blieben Holzfäller/Sammler/Steinbrecher einfach an der Fackel stehen. Selbstständige Helfer blieben
  sogar, solange es *irgendwo anders* noch etwas gab.
- **Jetzt: Ausweich-Arbeit.** Ist die eigene Zone leer, fragt der Bewohner, was das Lager am dringendsten braucht
  (Holz, Nahrung, Stein – nur, was nicht schon fast voll ist), und arbeitet dort: zuerst in der eigenen Zone, sonst
  in der nächsten hellen Zone („hilft bei: Holz“). Alle 10 s schaut er, ob es in seiner Zone wieder etwas gibt, und
  kehrt dann zurück („zurück zur eigenen Arbeit“). Wird die Ausweich-Zone dunkel, gilt wieder die eigene.
  Gibt es nirgends etwas Sinnvolles, geht er heim ans Feuer und ruht ~25 s („nichts zu tun – ruht am Feuer“).
  Im Menü bleibt er weiter seiner Zone zugeteilt.
- Probelauf (Westsenke abgeholzt, 3 Holzfäller): sie holen Holz in Osthain und bringen es heim, statt zu warten.

### Dunkle Skills stärker mit klarem Geist (Max)
- Gegenstück zu den Licht-Skills: **alle dunklen Skills sind stärker, je klarer der Geist ist** (×1,3 bei Wahn 0 bis
  ×0,7 bei Wahn 100) – Schattenriss, Leerenschrei (macht jetzt auch so Schaden-Unterschiede) und Schattenpakt
  (Bonus ×3 bei Wahn 0 bis ×1 bei Wahn 100, vorher genau umgekehrt). Einheitlicher Text:
  „Nährt den Wahnsinn. Stärker, je klarer dein Geist ist“. Damit: Dunkel ist stark, solange man klar ist – und
  macht wahnsinnig; Licht wird stark, wenn man wahnsinnig ist – und macht wieder klar.


## Neue Werte (frei gewählt)
Abschnitte „Leiste mit Tiefe“, „Wahnsinn“, „Bewohner mit Eigenleben“ in `scripts/config.gd`.
Im Werte-Menü neue Gruppen: „Leiste & Talismane“, „Wahnsinn“, „Bewohner-Stimmung“.
Speicherstand Version 2 (alte Stände laden weiter; Bewohner bekommen dann neue Namen).

## Sicht (zum Testen)
- Jeder Gegner bekommt `scripts/enemies/enemy_sight.gd` (prüft ~7× pro Sekunde, versetzt):
  - **voll sichtbar**: freie Sicht vom Hüter und der Gegner steht im Licht (Laterne, Feuer …) oder ist näher als 3,5 m –
    oder er steht im Licht eines Feuers/einer Fackel/Feuerstelle/des Torfeuers (dort wachen die Bewohner; so sieht man
    die Belagerung auch von drinnen).
  - **nur Augen**: freie Sicht, aber im Dunkeln → nur die roten Augen leuchten (doppelt so groß).
  - **unsichtbar**: Baum, Fels oder Mauer im Weg, oder weiter als 24 m.
- Lebensbalken nur bei voll sichtbaren Gegnern. Warnkreise (Verlorener, Boss) bleiben immer sichtbar.
- Werte-Menü, Gruppe „Sicht“: Sicht an/aus (zum Vergleichen), „Im Dunkeln ganz sichtbar bis m“.
- Neue Werte: `sight_enabled`, `sight_near` (3,5 m), `sight_range` (24 m).

---

# Version v0.2 – Licht erobern statt selbst sammeln

Ziel: Der Hüter macht draußen Gebiete hell; in erhellten Gebieten arbeiten Bewohner.

| Etappe | Inhalt | Aufwand | Status |
|---|---|---|---|
| 1 | Gebiete erhellen: Zonen, Fackelpfähle, Brennstoff, Lichtfresser löschen | mittel | fertig, am Handy getestet (Build #17) |
| 2 | Bewohner als Holzfäller / Sammler in helle Zonen schicken | groß | fertig, am Handy getestet |
| 3 | Gebäude-Upgrades (3 Stufen) | mittel | fertig, am Handy getestet |
| 4 | Begehbarer Wachturm | mittel | fertig, am Handy getestet |
| 5 | Speicherstand im Browser | mittel | fertig, am Handy getestet |
| 6 | Werte einstellen mit Max | klein | läuft |
| 7 | Wunsch Max: Stein, Bögen für Bewohner, kleine Fackeln, Feuerstellen | groß | zum Testen |

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

## Etappe 2 – Bewohner hinschicken
- **Knopf „Bewohner einteilen“** am Feuer (über „Leiste umbauen“). Menü pausiert das Spiel.
  Pro Zone: Holzfäller (wenn es dort Holz gibt) und Sammler (wenn es dort Nahrung gibt) mit − / +.
  „+“ geht nur bei heller Zone und solange noch Bewohner übrig sind.
- **Ablauf**: Bewohner läuft durchs Tor zur Zone, sucht die nächste volle Fundstelle seiner Art, sammelt
  2 Einheiten (4 s pro Einheit), bringt sie zum Feuer („+2 Holz“ über dem Kopf), kurze Pause, wieder los.
  Trägt er etwas, sieht man ein Bündel auf dem Rücken.
- **Nur in hellen Zonen**: Erlischt die Fackel, kommen die Arbeiter heim und warten am Feuer. Brennt sie wieder,
  gehen sie von selbst los. Bei Belagerung (schon beim Vorzeichen) kommen alle heim.
- **Gefahr draußen**: Bewohner haben 25 Leben. Kriecher greifen Bewohner draußen im Dunkeln an (im Licht einer Fackel
  sind sie vor Kriechern sicher), Verlorene überall. Getroffen → Lebensbalken, Flucht in die Festung, am Feuer
  heilen sie (3/s) und gehen erst ab 60 % Leben wieder raus. Stirbt einer, fällt sein Arbeitsplatz weg.
  Gegner erscheinen nicht direkt neben Bewohnern.
- **Gebäude** bekommen die Bewohner, die nicht draußen eingeteilt sind (Pilzkeller, Trümmerhof, Wachturm).
  Wer schon in einem Gebäude arbeitet, bleibt dort, solange es geht.
- **Hüter sammelt weniger**: Trage 6 statt 15, 1,2 s statt 0,6 s pro Einheit.
- HUD: „Bewohner: 5 (2 draußen)“.
- Werte-Menü: Bewohner-Leben, Einheiten pro Gang, Sekunden pro Einheit, Arbeiter-Tempo, Trage des Hüters.
- Neue Werte (frei gewählt): siehe Abschnitt „Bewohner draußen“ in `scripts/config.gd`.

### Nach Max' Test von Etappe 2
- **Einteilen ging nicht**: Am Anfang ist keine Zone hell, deshalb waren alle „+“ gesperrt – und gesperrte Knöpfe sahen
  kaum anders aus. Jetzt kann man **jederzeit in jede Zone** einteilen; ist sie dunkel, warten die Bewohner am Feuer
  („wartet am Feuer“) und gehen los, sobald sie hell ist. Gesperrte Knöpfe sind jetzt deutlich grau.

## Etappe 3 – Gebäude-Upgrades
- Jedes Gebäude hat **3 Stufen**. Stufe 2 kostet 10 Holz, Stufe 3 16 Holz (das letzte Holz bleibt fürs Feuer).
- **Verbessern**: vor das Gebäude stellen (Seite zum Feuer) → Knopf „… verbessern → Stufe 2 (10 Holz)“ mit Vorschau.
  Nach dem Tippen verschwindet der Knopf, bis man einmal weggeht (gegen Doppeltippen).
- Vorratslager: +30 / +60 / +90 Lagerplatz.
- Trümmerhof und Pilzkeller: 1 / 2 / 3 Arbeitsplätze, jeder Bewohner produziert für sich.
- Wachturm: je Stufe +50 % Schaden, +3 m Reichweite, Schussabstand ×0,8 (Stufe 3: 12 Schaden, 20 m, alle ~1 s).
- Pro Stufe ein Fähnchen auf dem Dach; Schild zeigt „(St. 2)“ und „2/3 Bewohner“.
- Bewohner-Verteilung: Pilzkeller, Trümmerhof, Wachturm; wer schon in einem Gebäude arbeitet, bleibt dort.
- Werte-Menü: Kosten Stufe 2 und Stufe 3.

### Nach Max' Test von Etappe 3: mehr Bewohner
- Start mit **7 Bewohnern** (statt 5).
- **Überlebende**: alle 4 min findet ein Überlebender das Licht und kommt durchs Tor (+1 Bewohner, Meldung),
  höchstens 12 Bewohner und nur, wenn mindestens 3 Nahrung da sind.
- Jeder Bewohner isst 1 Nahrung alle 75 s (statt 60 s).
- Werte-Menü: Bewohner am Start, neuer Bewohner alle … s, Bewohner höchstens.

## Etappe 4 – Begehbarer Wachturm
- Vor dem gebauten Wachturm (Seite zum Feuer) → Knopf **„Turm besteigen (+5 m Reichweite)“**.
- Oben: Der Hüter steht erhöht (4,4 m) und schießt über die Mauer. Reichweite +5 m (+2 m je Turmstufe über 1),
  freie Sicht wird von oben berechnet – Gegner direkt an der Mauer sind verdeckt.
- Oben kann er nicht laufen und nicht dashen; Sichelhieb und Glockenschlag reichen nicht hinaus (Bogen und Glut schon).
  Gegner draußen erreichen ihn dort nicht.
- Die Kamera schwenkt oben nach draußen und zoomt etwas heraus.
- Knopf **„Herabsteigen“** → steht wieder vor dem Turm. Beim Tod steigt er automatisch ab.
- Der Bewohner im Turm schießt weiter mit.
- Neue Werte: `tower_climb_range` (5 m), `tower_climb_range_per_level` (2 m) in `scripts/config.gd`.

### Nach Max' Test von Etappe 4: Bäume fällen, mehr Pilze
- **Keine Holzhaufen mehr**: Holz kommt von **fällbaren Bäumen** (je 25 Holz). Sie sind etwas heller als der übrige
  Wald und glimmen leicht, Schild „Baum: 25 Holz“. Hacken dauert so lange wie früher das Sammeln
  (Hüter 1,2 s, Bewohner 4 s pro Holz). Leer → Stumpf, nach 6 min wächst der Baum nach.
- **6 Bäume um jede Zone** (im Fackellicht, 4,5–6,5 m von der Mitte), dazu 3 einzelne im Dunkeln für den Hüter.
- **Mehr Pilze**: 13 statt 6 Pilzstellen – jede Zone 2–3, dazu 2 einzelne im Dunkeln.
- Werte-Menü: Holz pro Baum, Baum wächst nach … s.

### Nach Max' Test: der ganze Wald ist fällbar, mehr Nahrung
- **Jeder Baum im Wald ist fällbar** (~190 Bäume, je 25 Holz). Gefällt → Stumpf, nach 6 min wächst er nach.
  Technik: kein eigenes Objekt pro Baum – `scripts/forest.gd` merkt sich Ort und Holz in Listen und zeichnet
  alle Stämme in einem Rutsch (wichtig für die Leistung im Browser).
- Die **Holz-Anzeige** („Baum: 17 Holz“) erscheint nur über einem Baum, an dem gerade gehackt wird, und
  verschwindet 3 s nach dem letzten Hieb.
- Der **Hüter hackt nur, wenn er stehen bleibt** (sonst würde er beim Durchlaufen des Waldes ständig hacken).
- **Holzfäller** nehmen nur Bäume, die sicher im Licht ihrer Zone stehen. Rund um jede Zone stehen weiterhin
  6 extra gepflanzte Bäume.
- **Mehr Nahrung**: Pilzstellen 5 statt 3 Nahrung und wachsen schneller nach, Pilzkeller schneller, 25 Nahrung am Start.
- **Weniger Tote draußen**: Bewohner 40 Leben, Kriecher bemerken sie später und beißen seltener, Fliehende rennen schneller.

## Etappe 5 – Speicherstand
- **Automatisch speichern** alle 20 s und beim Verlassen des Browser-Tabs (`scripts/save_game.gd`).
  Kurz erscheint oben „gespeichert“. Nicht während einer Belagerung, nicht während der Hüter tot ist.
- **Startfenster** (`scripts/ui/continue_panel.gd`): Gibt es einen Stand → „Weiterspielen“ (mit Spielzeit, Stufe,
  Bewohnern, Holz) oder „Neues Spiel“ (löscht den Stand). Ohne Stand startet das Spiel direkt.
- **Gespeichert wird**: Hüter (Ort, Leben, Tränke, Stufe/EP, Trage, Laterne, Leiste, Vorrat, Skill-Stufen),
  Festung (Holz, Nahrung, Bewohner mit Leben, Zonen-Einteilung, Gebäudestufen), Fackeln (gebaut, Brennstoff),
  Leuchtfeuer, jeder Baum im Wald, Pilzstellen, Zeit bis zur Belagerung, Anzahl Belagerungen, Boss besiegt, Spielzeit.
- **Nicht gespeichert**: Gegner (erscheinen neu). Stand auf dem Turm → man steht danach davor.
  Belagerung kommt nach dem Laden frühestens nach 45 s (Vorzeichen bleibt erhalten).
- **Niederlage oder Sieg** löschen den Stand; „Neu starten“ ebenso.
- **Werte-Menü-Einstellungen** (auch Lautstärke) werden jetzt im Browser gemerkt und gelten auch nach dem Schließen
  (`user://einstellungen.json`). „Alles auf Standard“ setzt sie zurück.
- Neuer Wert: `autosave_interval` (20 s) in `scripts/config.gd`.

## Etappe 6 – Werte einstellen
### Vorbereitung (ohne Max)
- **Werte-Menü** nach Gruppen sortiert (Feuer & Vorräte, Bewohner, Draußen, Fackeln, Gebäude, Belagerung,
  Gegner & Kampf, Hüter & Technik) und um Startvorräte, Lagergrenzen, Pilz- und Gebäudewerte sowie
  „Schaden an Bewohnern ×“ erweitert.
- **Automatischer Probelauf** (15 min, Hüter bleibt am Feuer, Fackel Westsenke, 3 Holzfäller + 2 Sammler, Pilzkeller):
  - Zuerst starben 5 von 7 Bewohnern in der ersten Minute: Sitzt der Hüter am Feuer, lauerten die Kriecher
    genau vor dem Tor. → **Torfeuer** (zwei Feuerschalen vor dem Tor, 6 m Licht, `scripts/fortress/gate_lamp.gd`),
    **Kriecher streifen durch den Wald**, solange der Hüter sicher am Feuer ist, statt vor der Mauer zu lauern,
    und es sind dann **nur halb so viele Gegner** unterwegs. Gegner machen Bewohnern halben Schaden.
  - Danach ging das Feuer trotzdem aus: Lichtfresser fraßen die Fackel ständig leer. → Raubzug seltener und schwächer,
    Arbeiter tragen 3 statt 2.
  - Ergebnis jetzt: keine Toten, Holzlager nach 3 min voll, Nahrung stabil, Überlebende kommen dazu.

## Etappe 7 – Stein, Bögen, kleine Fackeln, Feuerstellen (Wunsch Max)
- **Stein** (neuer Rohstoff): Die Felsen draußen sind abbaubar (je 10 Stein, schrumpfen, nach 10 min wieder da;
  Anzeige nur beim Abbauen). Um jede Zone liegen 2 extra Felsen (`ZoneDefs.rock_spots`). Der Hüter baut im Stehen ab,
  Bewohner als **Steinbrecher** (neue Zeile im Einteilen-Menü). Lager: 40 Stein (+30 je Vorratslager-Stufe).
  HUD: neue Zeile „Stein: x Bögen: y“. Skript: `scripts/rock_node.gd`.
- **Werkstatt** (neuer Bauplatz unten in der Festung, 8 Holz, 3 Stufen = 1/2/3 Arbeitsplätze): baut Bögen
  (60 s pro Bogen und Arbeiter, 4 Holz pro Bogen). Hört auf, wenn jeder Bewohner einen Bogen haben könnte.
- **Bögen verteilen**: im Einteilen-Menü „Bewohner mit Bogen“ − / +. Wer draußen arbeitet, bekommt zuerst einen
  (Bogen auf dem Rücken sichtbar). Bewaffnete schießen draußen auf Gegner im Umkreis von 10 m (5 Schaden alle 1,8 s)
  und zählen bei der Belagerungs-Verteidigung doppelt. Stirbt ein Bewaffneter, ist sein Bogen weg.
- **Kleine Fackel** (Knopf rechts über der Leiste, nur draußen, 1 Holz): steckt vor dem Hüter in den Boden,
  4,5 m Licht (Kriecher meiden es), brennt 2 min und verschwindet dann. Höchstens 6. Skript: `scripts/zones/small_torch.gd`.
- **Feuerstelle** (Knopf darüber, nur draußen, 5 Stein + 1 Holz): 9 m Licht, fasst 6 Holz à 90 s, Holz nachlegen
  wie bei der Fackel, **die Laterne füllt sich dort auf**. Höchstens 4, mind. 4 m Abstand zu anderen Feuern.
  Lichtfresser-Raubzüge gehen auch auf Feuerstellen. Skript: `scripts/zones/fire_pit.gd`.
- **Bewohner bringen Holz**: Hat eine Feuerstelle weniger als 35 %, schickt die Festung einen freien Bewohner mit
  3 Holz aus dem Lager hin. Holzfäller, die mit voller Ladung in der Nähe (15 m) sind, bringen ihr Holz direkt hin
  und arbeiten danach weiter. Bei Belagerung oder Verletzung brechen sie ab (das Holz geht zurück ins Lager).
- Bezahlt wird immer zuerst aus der Trage, dann aus dem Lager.
- Alles wird im Speicherstand gemerkt (Stein, Bögen, Bewaffnete, Feuerstellen, kleine Fackeln, Felsen).
- Werte-Menü: neue Regler für kleine Fackel, Feuerstelle, Stein pro Felsen, Werkstatt, Bogen-Holz, Bewohner-Bogen-Schaden.

### Nach Max' Test von Etappe 7: Einteilen nur durch Max, nebenbei nachlegen
- **Einteilen nur noch über das Menü**: Niemand wird mehr automatisch aus einem Gebäude oder einer Zone abgezogen.
  „+“ (Zone oder Gebäude) geht nur, wenn ein Bewohner **frei** ist; „−“ macht jemanden frei. Oben im Menü: „frei: n“.
  Gebäude haben jetzt eigene − / + Zeilen. **Freie Bewohner** besetzen offene Plätze von selbst (z. B. beim Bauen
  oder Verbessern eines Gebäudes). Nimmt Max jemanden aus einem Gebäude, bleibt der Platz leer.
  Holzträger für Feuerstellen sind nur noch freie Bewohner.
- **Nebenbei nachlegen**: Ist ein Bewohner draußen im Lichtkreis einer Fackel oder Feuerstelle, die unter 50 % ist,
  geht er kurz hin, legt 1 Holz nach (aus seiner Ladung, sonst aus dem Lager) und macht dann weiter, wo er war.
  Pro Fackel immer nur einer gleichzeitig, derselbe Bewohner frühestens nach 15 s wieder.
- Neue Werte: `tend_below` (0,5), `tend_cooldown` (15 s).

### Schlaue Bewohner (Wunsch Max)
- **Gebäude ruhen**, wenn sie nicht gebraucht werden: Werkstatt bei genug Bögen für alle, Trümmerhof bei vollem
  Holzlager, Pilzkeller bei vollem Nahrungslager (wieder an unter 85 %). Ihr Platz bleibt eingeteilt; die Arbeiter
  sind solange frei. Schild und Menü zeigen „ruht – Holzlager voll“ usw.
- **Freie Bewohner helfen selbstständig**: alle 5 s schauen sie, was das Lager braucht (Holz dringend, wenn das Feuer
  < 3 min reicht; Nahrung dringend unter 2 pro Bewohner; Stein weniger wichtig) und arbeiten in einer hellen Zone,
  in der es das gibt. Sie verteilen sich (jeder Helfer senkt den Bedarf). Ist alles fast voll, bleiben sie am Feuer.
  Sie zählen weiter als **frei** – Max kann sie jederzeit einteilen. Menü: „davon helfen selbstständig: 2 Holz, 1 Stein“.
- Neue Werte: `smart_interval` (5 s), `smart_min_need` (0,15), `smart_need_per_helper` (0,25).
