# Aschen – Fortschritt Prototyp v0.1

Spielen im Handy-Browser: **https://mxbstudio.github.io/Ashen/**
Die Build-Nummer oben links im Spiel (z. B. `#5 (abc1234)`) zeigt, welcher Stand geladen ist.

Technik: Godot 4.7.2 · GDScript · Renderer „Compatibility“ · Web-Export ohne Threads.
Bei jedem Push baut `.github/workflows/web-export.yml` die Web-Version und legt sie in den Branch `gh-pages`.

## Etappen

| Etappe | Inhalt | Status |
|---|---|---|
| 0 | Repository, GitHub Action, GitHub Pages, Testszene | fertig, am Handy getestet (>60 FPS) |
| 1 | Kamera, Hüter bewegen und dashen, Testgelände | fertig – wartet auf Handy-Test |
| 2 | Licht: Laterne, Feuer, Auffüllen | offen |
| 3 | Skill-Leiste mit Sichelhieb und Bogenschuss | offen |
| 4 | Gegner, Schaden, Tod, Wiedererscheinen | offen |
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
- Touch: Joystick erscheint, wo der linke Daumen aufsetzt; Knöpfe „Dash“ und „Trank“ rechts unten.
- Tastatur: WASD/Pfeile, Leertaste = Dash, Q = Trank (Trank hat noch keine Wirkung).
- Testgelände 60 × 60 m mit Felsen, toten Bäumen und unsichtbarem Rand.
- Alle Spielwerte stehen zentral in `scripts/config.gd`.
- Neue Werte (nicht im Prompt vorgegeben, frei gewählt): Laufgeschwindigkeit 6 m/s, Dash 20 m/s für 0,18 s, Dash-Abklingzeit 0,6 s, Kameraausschnitt 18 m.

## Geänderte Werte
(noch keine – Startwerte laut Prompt)
