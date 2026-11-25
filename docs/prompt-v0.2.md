# Prompt: Aschen – Version v0.2

Diesen Text in eine neue Claude-Code-Sitzung mit dem Repository `mxbstudio/Ashen` einfügen.

---

Du hilfst mir, Max, mein Spiel *Aschen* in Godot weiterzuentwickeln. Ich kann nicht programmieren und arbeite
ausschließlich am Handy – ich habe keinen PC. Du schreibst den gesamten Code und erklärst mir in einfachen Worten,
was du tust. Ich teste jeden Stand im Handy-Browser und melde zurück, was ich sehe.

## Bevor du anfängst
1. Lies `FORTSCHRITT.md` (Stand, Entscheidungen, geänderte Werte, Ideen), `docs/design-prototyp.md` und – falls
   vorhanden – `docs/aschen-gdd.md`. Verschaff dir dann einen Überblick über den Code (`scripts/`, `scenes/`).
2. Prototyp v0.1 ist fertig und läuft. Mach nichts kaputt: Jede Änderung muss im Handy-Browser weiter flüssig laufen.
3. Gib mir eine kurze Aufwandseinschätzung für v0.2 und jede Etappe (klein/mittel/groß) und stelle Rückfragen nur,
   wenn etwas wirklich unklar ist.

## So bleibt es wie bisher
- Godot 4.7.2, GDScript, Renderer „Compatibility“, Web-Export ohne Threads. Hochformat.
- Jeder Push baut per GitHub Action automatisch die Web-Version und veröffentlicht sie auf GitHub Pages:
  https://mxbstudio.github.io/Ashen/ – die Build-Nummer steht oben links im Spiel. Nenne mir nach jedem Push die
  Build-Nummer und sag, worauf ich achten soll.
- Teste selbst vorher im Browser (Godot und Playwright lassen sich in der Sitzung einrichten), bevor du mir etwas schickst.
- Alle Spielwerte zentral in `scripts/config.gd`; neue wichtige Werte auch ins Werte-Menü (`scripts/ui/tuning_panel.gd`).
- Kurze, kommentierte Skripte, eine Sache pro Skript. Fehler zeigt die Debug-Anzeige im Spiel (ich habe keine Konsole).
- Kleine Schritte, nach jeder Etappe etwas Spielbares. Halte Fortschritt und geänderte Werte in `FORTSCHRITT.md` fest.
- Erkläre ohne Fachchinesisch. Wenn etwas nicht klappt, frag mich, was ich auf dem Bildschirm sehe.

## Ziel von v0.2: Licht erobern statt selbst sammeln
Der Hüter macht draußen Gebiete hell; in erhellten Gebieten können Bewohner arbeiten. Dadurch werden Licht,
Erkundung und Festung zu einem System.

## Etappen (Vorschlag – sag mir, wenn du eine bessere Reihenfolge siehst)
1. **Gebiete erhellen**: Das Gebiet draußen ist in Zonen aufgeteilt. Der Hüter kann in einer Zone eine Lichtquelle
   errichten bzw. entzünden (z. B. Fackelpfahl oder Leuchtfeuer, kostet Holz). Erhellte Zonen sind sicherer
   (Kriecher meiden sie), brauchen aber selbst Brennstoff und können von Gegnern gelöscht werden.
2. **Bewohner hinschicken**: In erhellten Zonen mit Holz oder Nahrung kann man Bewohner als Holzfäller oder
   Jäger/Sammler einteilen (am Feuer per Antippen). Sie laufen hin, arbeiten, bringen Ressourcen zurück – und sind
   draußen in Gefahr. Das eigene Sammeln des Hüters wird dadurch ersetzt oder stark reduziert.
3. **Gebäude-Upgrades**: Jedes Gebäude hat 2–3 Stufen (mehr Arbeiter, mehr Ertrag, Wachturm stärker).
4. **Begehbarer Wachturm**: Der Hüter kann den Turm besteigen und von dort erhöht über die Mauer schießen.
5. **Speicherstand**: Das Spiel merkt sich den Stand im Browser, damit ich eine Runde unterbrechen und später
   weiterspielen kann.
6. **Werte einstellen** gemeinsam mit mir über das Werte-Menü.

## Weiterhin NICHT (erst später)
Echte Sicht/Nebel des Krieges, Wahnsinn, Herkünfte, Ausrüstung, Meta-Fortschritt, Story, echte Grafik.
