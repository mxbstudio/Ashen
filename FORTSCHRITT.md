# Aschen – Fortschritt Prototyp v0.1

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
| 4 | Gegner, Schaden, Tod, Wiedererscheinen | fertig – wartet auf Handy-Test |
| 5 | Modifikatoren, weitere Skills, Level-up, Leiste umbauen | offen |
| 6 | Festung, Ressourcen, Gebäude, Bewohner | offen |
| 7 | Belagerung, Leuchtfeuer, Boss, Sieg/Niederlage | offen |
| 8 | HUD fertig, Werte einstellen | offen |

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

## Geänderte Werte
| Wert | vorher | jetzt | Grund |
|---|---|---|---|
| Bildschirm | Querformat | Hochformat | Wunsch Max |
| Joystick | analog (halb geschoben = halb so schnell) | sofort volle Geschwindigkeit (`joystick_analog = false`) | fühlte sich weich/langsam an |
| Kamera-Folgen | weich (8) | direkt (0) | fühlte sich weich an |
