# Prompt: Aschen – weiter mit v0.3 (Meta-Fortschritt)

Diesen Text in eine neue Claude-Code-Sitzung mit dem Repository `mxbstudio/Ashen` einfügen.

---

Du hilfst mir, Max, mein Spiel *Aschen* in Godot weiterzuentwickeln. Ich kann nicht programmieren und arbeite
ausschließlich am Handy (manchmal am PC). Du schreibst den gesamten Code und erklärst mir in einfachen Worten,
was du tust. Ich teste jeden Stand im Browser und melde zurück, was ich sehe.

## Bevor du anfängst
1. Lies `FORTSCHRITT.md` – ganz oben stehen Stand, Überblick, nächste Schritte und unsere Arbeitsweise; darunter
   die ganze Geschichte mit allen Entscheidungen und der Tabelle „Geänderte Werte“.
2. Lies `docs/design-prototyp.md` (Design-Zusammenfassung v0.1–v0.3 und meine Vorlieben).
3. Verschaff dir einen Überblick über den Code (`scripts/`, `scenes/main.tscn`). Alles wird im Code erzeugt.
4. Arbeite auf deinem Sitzungs-Branch, der von `main` ausgeht (dort liegt der aktuelle Stand).
5. Gib mir eine kurze Aufwandseinschätzung und einen Vorschlag für den Meta-Fortschritt; Rückfragen nur,
   wenn etwas wirklich unklar ist.

## So bleibt es wie bisher
- Godot 4.7.2, GDScript, Renderer „Compatibility“, Web-Export ohne Threads. Hochformat (am PC Querformat).
- Jeder Push baut per GitHub Action automatisch die Web-Version und veröffentlicht sie auf GitHub Pages.
  **Nenne mir nach jedem Push die Build-Nummer UND den Link https://mxbstudio.github.io/Ashen/** und sag,
  worauf ich achten soll. Die Build-Nummer steht oben links im Spiel.
- Teste selbst vorher (siehe „Technische Tipps“), bevor du mir etwas schickst.
- Alle Spielwerte zentral in `scripts/config.gd`; wichtige auch ins Werte-Menü (`scripts/ui/tuning_panel.gd`,
  nach Gruppen sortiert).
- Kurze, kommentierte Skripte, eine Sache pro Skript. Fehler zeigt die Debug-Anzeige im Spiel.
- Neue Dinge, die gespeichert werden müssen, in `scripts/save_game.gd` aufnehmen (alte Spielstände sollen ladbar bleiben).
- Kleine Schritte, nach jedem Schritt etwas Spielbares. `FORTSCHRITT.md` pflegen (Stand oben, Abschnitt pro Schritt,
  Tabelle „Geänderte Werte“).
- Erkläre ohne Fachchinesisch. Wenn etwas nicht klappt, frag mich, was ich auf dem Bildschirm sehe.
- Code kommt per Pull Request nach `main`, wenn ein Abschnitt fertig ist; ich bestätige ihn am Handy.
  Nie force-pushen. Nach einem Merge `main` normal in den Arbeitszweig zusammenführen.

## Ziel jetzt: Meta-Fortschritt
Etwas soll zwischen Runden erhalten bleiben (nach Sieg oder Niederlage), damit jede Runde etwas bringt.
Mein Gedanke (mach gern einen besseren Vorschlag):
- Am Ende einer Runde gibt es eine Belohnung (z. B. „Glut“ oder „Erinnerungen“), abhängig davon, wie weit man kam
  (überstandene Belagerungen, Boss besiegt, Spielzeit, Bewohner am Leben).
- Vor einer neuen Runde kann man damit dauerhafte Verbesserungen freischalten (z. B. mehr Bewohner oder Holz am Start,
  bessere Startausrüstung, ein zusätzlicher Startskill, langsamerer Wahnsinn).
- Getrennt vom Spielstand speichern (eigene Datei im Browser), auch „Neues Spiel“ löscht ihn nicht.

Danach (spätere Schritte): Herkünfte (verschiedene Hüter), Story, echte Grafik (eigener Chat – leistungskritisch).

## Weiterhin nicht (erst später)
Echte Grafik, Mehrspieler.

---

## Technische Tipps (aus der letzten Sitzung – für Claude)
- **Godot einrichten** (Linux-Container):
  `curl -fsSL -o godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`,
  entpacken; Export-Vorlagen: `Godot_v4.7.2-stable_export_templates.tpz`, daraus nur `templates/web_nothreads_*` nach
  `~/.local/share/godot/export_templates/4.7.2.stable/` (groß – im Hintergrund laden).
- **Fehler prüfen**: `echo "#lokal" > build_info.txt` (wird von der Action erzeugt, nicht committen!), dann
  `godot --headless --path . --import` und `godot --headless --path . --quit-after 300`.
- **Automatische Tests**: Testskript `extends SceneTree`, in `_initialize()` `scenes/main.tscn` instanziieren, in
  `_process()` Bilder zählen und prüfen; starten mit `godot --headless --path . -s pfad/test.gd --fixed-fps 60`.
  Autoloads im Testskript über `root.get_node("Config")` (nicht `Config.` – das kompiliert dort nicht).
  `get_tree().current_scene` ist im Testskript null → Knoten über Gruppen finden (z. B. Gruppe `world`).
  Testskripte nur vorübergehend ins Projekt legen und danach löschen. Den Spielstand vorher/nachher löschen:
  `~/.local/share/godot/app_userdata/Aschen/*.json`.
- **Browser-Test**: `godot --headless --path . --export-release "Web" <ordner>/index.html`, im Ordner
  `python3 -m http.server`, Playwright-Chromium mit
  `args: ['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']`, Kontext 390×844 mit
  `hasTouch: true, isMobile: true`, ~9 s warten, Bildschirmfotos ansehen. FPS sind dort niedrig (Software) – nicht
  aussagekräftig. Klickpositionen: Spiel-Einheiten (720 breit) × 0,5417 = Bildpunkte bei 390 Breite;
  sichtbare Höhe in Spiel-Einheiten ≈ 1558.
- Für Test-Varianten (z. B. Hüter woanders starten lassen) Dateien vorher sichern und danach wiederherstellen –
  `git status` prüfen, dass nichts Test-Spezifisches committet wird.
- **Leistung am Handy**: viele Lichtquellen (OmniLight) sind teuer → Obergrenzen (kleine Fackeln 6, Feuerstellen 4).
  Viele gleiche Objekte gesammelt zeichnen (MultiMesh, siehe `scripts/forest.gd`). Neue Arten von Oberflächen beim
  Start in `scripts/shader_warmup.gd` aufnehmen (sonst ruckelt es beim ersten Anzeigen).
- **Knöpfe**: Sichtbarkeit nur ändern, wenn sie sich wirklich ändert (sonst gehen Fingertipps verloren);
  Knöpfe in Gruppe `touch_blockers`, damit der Joystick sie nicht schluckt.
- Build-Nummer: `mcp__github__actions_list` → `list_workflow_runs` für `web-export.yml` (run_number).
