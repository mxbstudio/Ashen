# Aschen – Design-Zusammenfassung (v0.1 bis v0.3)

> Hinweis: Das ausführliche Design-Dokument heißt `aschen-gdd.md` und gehört in diesen Ordner (`docs/`).
> Diese Datei fasst nur zusammen, was für den Prototyp galt und was beim Testen entschieden wurde.

## Idee
Extrem düsteres, isometrisches 2,5D-Action-RPG mit Festungsaufbau. Eine Dunkelheit saugt Licht und Wärme aus der Welt.
Der Spieler ist der **Hüter** eines der letzten Feuer: Er verlässt als Einziger die Festung, kämpft mit einer
**automatischen Skill-Leiste** gegen Horden, sammelt Holz und Nahrung und muss zurück sein, bevor seine Laterne
erlischt, die Belagerung beginnt oder das Feuer ausgeht.

## Was der Prototyp beweisen sollte
Die Schleife *aufbrechen → kämpfen und sammeln → zurückkehren → Feuer nähren und Festung versorgen → Belagerung überstehen*
macht Spaß. Vor allem: Fühlt sich die Skill-Leiste gut an, und erzeugt das schwindende Licht Druck?

## Kernsysteme (wie gebaut)
- **Skill-Leiste**: 3 Felder (+1 bei Hüter-Stufe 6 und 11), läuft automatisch links → rechts im Kreis. Keine Cooldowns,
  nur Cast-Zeiten (erst ausholen, dann auslösen). Angriffe wirken selbst; Modifikatoren verändern den nächsten Angriff
  rechts davon (stapeln sich, wirken über das Ende der Leiste auf den ersten). Ohne Angriff passiert nichts.
  Jeder Skill nur einmal, dafür Skill-Stufen 1–5. Stufenaufstieg: 1 aus 3 (neuer Skill oder Verbesserung).
  Umbau der Leiste nur am Feuer. Angriffe brauchen freie Sicht.
  - Angriffe: Sichelhieb, Bogenschuss, Glutwurf, Glockenschlag
  - Modifikatoren: Labung, Echo, Opferlicht
- **Licht**: Laterne (Lichtradius schrumpft mit der Brenndauer), Feuer und Leuchtfeuer füllen sie auf.
  Gegner außerhalb des Lichts machen mehr Schaden.
- **Gegner**: Kriecher (meiden Licht, Schwarm), Lichtfresser (saugen an der Laterne), Verlorener (langsam, groß,
  ignoriert Licht), Boss „Der verwandelte Hauptmann“ (Flächenangriff mit Vorwarnung).
- **Festung**: Feuer verbraucht Holz (aus → Niederlage), 5 Bewohner essen Nahrung (ohne Nahrung stirbt einer),
  Gebäude: Vorratslager, Trümmerhof, Pilzkeller, Wachturm. Tor lässt nur den Hüter durch.
- **Belagerung**: alle 8 min, Vorzeichen (Feuer flackert, Grollen), dann Glocke. Nur das Tor nimmt Schaden;
  Bewohner und Wachturm verteidigen. Tor fällt → ein Bewohner stirbt.
- **Sieg**: Boss besiegen, danach die letzte Belagerung halten.
- **Steuerung**: Hochformat. Touch-Joystick (untere Hälfte), Dash (unterbricht Cast, unverwundbar), Trank.
  Tastatur: WASD, Leertaste, Q.

## Technik
Godot 4.7.2, GDScript, Renderer „Compatibility“, Web-Export ohne Threads, GitHub Action → GitHub Pages.
Alle Spielwerte zentral in `scripts/config.gd`; im Spiel zusätzlich über das Werte-Menü einstellbar.
Platzhalter-Grafik aus einfachen Formen, Platzhalter-Sound im Code erzeugt (kein FMOD).

## Bewusst NICHT im Prototyp
Wahnsinn und Realitäts-Check, Bewohner-Simulation mit eigenem Leben, Herstellung, Ausrüstung und Inventar,
Meta-Fortschritt, Herkünfte, dunkle Fähigkeiten, Ultimate, Fackel, Dämmerung als Uhr, Story, echte Grafik,
Speicherstände.

## Ideen für v0.2 (von Max beim Testen)
Siehe `FORTSCHRITT.md` → „Ideen für später (v0.2)“.

---

## Was in v0.2 dazukam: Licht erobern statt selbst sammeln
Der Hüter macht draußen Gebiete hell; in hellen Gebieten arbeiten Bewohner. Licht, Erkundung und Festung sind ein System.
- **Zonen** (Westsenke, Osthain, Leuchtfeuer, Pilzmoor, Nordwald) mit Fackelpfahl (Brennstoff Holz). Kriecher meiden
  festes Licht; Lichtfresser-Raubzüge löschen Fackeln. Torfeuer vor dem Tor.
- **Rohstoffe**: Holz (jeder Baum im Wald fällbar, 25 Holz), Nahrung (Pilzstellen), Stein (Felsen).
  Der Hüter sammelt nur im Stehen und wenig (Trage 6) – sammeln sollen die Bewohner.
- **Bewohner**: Max teilt ein (Gebäude, Holzfäller/Sammler/Steinbrecher je Zone, Bögen) – **nie automatisch umsetzen**,
  „+“ nur mit freien Bewohnern. Freie Bewohner helfen selbstständig nach Lagerbedarf (zählen weiter als frei);
  Gebäude ruhen bei vollem Lager. Bewohner legen nebenbei Holz nach (< 50 %), bringen Holz zu Feuerstellen.
  Draußen in Gefahr (Kriecher im Dunkeln, Verlorene), mit Bogen wehren sie sich. Überlebende kommen dazu.
- **Gebäude** mit 3 Stufen; **Werkstatt** (Bögen, Ausrüstung); **begehbarer Wachturm** (erhöht schießen).
- **Kleine Fackeln** (kurz, nicht nachfüllbar) und **Feuerstellen** (Stein, nachfüllbar, Laterne füllt sich) frei platzierbar.
- **Speicherstand** im Browser.

## Was in v0.3 dazukam
- **Sicht**: Gegner im Dunkeln nur als glühende Augen, hinter Hindernissen unsichtbar; im Licht fester Feuer immer sichtbar.
- **Ausrüstung**: Klinge (Schaden), Rüstung (Leben, Schutz), Laterne (Brenndauer, Licht) – je 3 Stufen, Holz + Stein,
  Stufe n braucht Werkstatt-Stufe n.
- **Wahnsinn**: steigt im Dunkeln (schneller bei schwacher Laterne), sinkt langsam im Licht. Ab 30 Flüstern/dunkler Rand,
  ab 50 Trugbilder, ab 75 lügende Anzeige + falsche Warnungen, bei 100 Schaden. **Narben**: über 75 bleibt 10 (bis zum Tod).

## Vorlieben von Max (beim Testen gelernt)
- Er will **selbst entscheiden** (Einteilen), aber Bewohner sollen **mitdenken**, wo er nichts festgelegt hat.
- Er mag es **schwerer**, wenn etwas „zu einfach“ ist (Belagerung, Wahnsinn) – lieber spürbare Folgen.
- Viele Bäume, viel zu tun für Bewohner; Anzeigen nur, wenn sie gebraucht werden (z. B. Holz nur beim Hacken).
- Spielt am Handy (Hochformat), manchmal am PC.

## Weiterhin offen (spätere Versionen)
Meta-Fortschritt, Herkünfte, Story, echte Grafik.

