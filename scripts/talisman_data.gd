## Talismane (Ausrüstung): biegen die Regeln der Skill-Leiste um.
## Fundorte: Schreine draußen im Dunkeln, Verlorene (selten), der Hauptmann, manche Ereignisse.
## Der Hüter trägt höchstens Config.talisman_slots gleichzeitig; anlegen im Menü „Leiste“ (überall).
class_name TalismanData
extends RefCounted

const DEFS := {
	"pendulum": {"name": "Pendel",
			"desc": "Die Leiste pendelt: links → rechts → zurück. Mittlere Felder laufen doppelt so oft"},
	"chalice": {"name": "Leerer Kelch",
			"desc": "Leere Felder werden nicht übersprungen: kurze Pause, +3 s Laternenlicht"},
	"bellrope": {"name": "Glockenseil",
			"desc": "Jeder 3. Angriff wird doppelt ausgelöst"},
	"ashheart": {"name": "Aschenherz",
			"desc": "+40 % Schaden, solange die Laterne unter 30 % ist"},
	"crown": {"name": "Glutkrone",
			"desc": "Alle Angriffe setzen leicht in Brand (2/s)"},
	"palehand": {"name": "Bleiche Hand",
			"desc": "Modifikatoren wirken auf die nächsten ZWEI Angriffe"},
	"wick": {"name": "Stiller Docht",
			"desc": "Laterne brennt 30 % langsamer, aber die Leiste läuft 15 % langsamer"},
	"haste": {"name": "Hast-Amulett",
			"desc": "Casts 25 % schneller, aber du nimmst 20 % mehr Schaden"},
	"lens": {"name": "Splitterlinse",
			"desc": "Bogen, Glut und Riss treffen einen Gegner mehr"},
	"deathbell": {"name": "Totenglocke",
			"desc": "Jeder getötete Gegner lädt den laufenden Cast um 30 % auf"},
	"hearthstone": {"name": "Herdstein",
			"desc": "Am Feuer der Festung sinkt der Wahnsinn dreimal so schnell"},
	"embercharm": {"name": "Glutamulett",
			"desc": "Auch an Fackeln, Feuerstellen und am Leuchtfeuer sinkt der Wahnsinn"},
	"madstone": {"name": "Wahnstein",
			"desc": "Dunkle Skills +50 % Schaden, aber der Wahn steigt doppelt so schnell"},
}


static func name_of(id: String) -> String:
	return DEFS[id]["name"] if DEFS.has(id) else id


static func desc_of(id: String) -> String:
	return DEFS[id]["desc"] if DEFS.has(id) else ""
