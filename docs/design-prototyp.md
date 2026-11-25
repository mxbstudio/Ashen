# Aschen – Design-Zusammenfassung (Prototyp v0.1)

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
