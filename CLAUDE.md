# Hinweise für Claude

- Nach jedem Push, der das Spiel verändert: warten, bis der Web-Build (GitHub Action „Web-Export“) durchgelaufen ist,
  und Max **immer den Link zum Spiel schicken**: https://mxbstudio.github.io/Ashen/
  (mit der Build-Nummer, die oben links im Spiel stehen sollte, z. B. `#38`).
- Antworten auf Deutsch. Fortschritt und geänderte Werte in `FORTSCHRITT.md` festhalten.
- Ideen, die Max „für später“ nennt, unter „Für eine spätere Etappe gemerkt“ in `FORTSCHRITT.md` eintragen und bei der
  Planung neuer Etappen ansprechen.

## Neuer Chat (Wunsch Max)
- Von selbst Bescheid sagen, **wann sich ein neuer Chat lohnt** – vor allem wegen der Kontext-Grenze/Limits von Claude:
  z. B. nach einer abgeschlossenen Etappe, wenn der Chat sehr lang geworden ist (viele Umbauten, lange Ausgaben),
  oder bevor eine große neue Etappe beginnt. Kurz begründen.
- **Jedes Mal, wenn ein neuer Chat empfohlen wird, alles dafür vorbereiten:**
  1. alles committen und pushen, Web-Build abwarten, Link schicken,
  2. `FORTSCHRITT.md` aktualisieren (Stand oben, Abschnitt „Nächster Chat“ mit dem geplanten nächsten Schritt),
  3. einen Pull Request nach `main` öffnen, den Max mergt (dann startet der neue Chat vom aktuellen Stand),
  4. Max einen **fertigen Text zum Kopieren** für den neuen Chat geben (in einem Codeblock).
