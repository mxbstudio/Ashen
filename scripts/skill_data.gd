## Beschreibung aller Skills: Name, Kurzname, Typ (Angriff/Modifikator), Element, Farbe, Abzweigungen.
## Cast-Zeiten und Schaden stehen in config.gd.
##
## v0.3 – mehr Tiefe:
## - Zustände & Kombos: Glut setzt in Brand, Glocke erschüttert, Bogen kann markieren.
##   Sichel × erschüttert = Zerschmettern, Glocke × brennend = Entfachen, Bogen × brennend = Flammenpfeil.
## - Lage zählt: Spiegel kopiert das Feld links davon, Schwur wirkt im letzten Feld auf die ganze Runde.
## - Abzweigungen: beim Aufstieg auf Stufe 3 wählt man für jeden Skill eine von zwei Regeln.
## - Dunkle Skills (nur bei Wahnsinn): nähren den Wahnsinn. Licht-Skills senken ihn.
##   Licht-Skills sind stärker, je wahnsinniger man ist („Stärker, je wahnsinniger du bist“),
##   dunkle Skills stärker, je klarer der Geist ist („Stärker, je klarer dein Geist ist“).
class_name SkillData
extends RefCounted

const ATTACK := "attack"
const MODIFIER := "modifier"

const DEFS := {
	"sickle": {"name": "Sichelhieb", "short": "Sichel", "type": ATTACK, "elem": "Klinge",
			"desc": "Nahkampf-Bogen vor dem Hüter. Gegen erschütterte Gegner doppelt (Zerschmettern)"},
	"bow": {"name": "Bogenschuss", "short": "Bogen", "type": ATTACK, "elem": "Klinge",
			"desc": "Pfeil auf den nächsten Gegner. Trifft er Brennende: Flammenpfeil (Explosion)"},
	"ember": {"name": "Glutwurf", "short": "Glut", "type": ATTACK, "elem": "Feuer",
			"desc": "Brennendes Geschoss, setzt in Brand"},
	"bell": {"name": "Glockenschlag", "short": "Glocke", "type": ATTACK, "elem": "Klang",
			"desc": "Schockwelle rundum, stößt zurück und erschüttert. Entfacht Brennende"},
	"mend": {"name": "Labung", "short": "Labung", "type": MODIFIER, "elem": "Licht",
			"desc": "Nächster Treffer heilt"},
	"echo": {"name": "Echo", "short": "Echo", "type": MODIFIER, "elem": "Klang",
			"desc": "Nächster Angriff zweimal, Cast länger"},
	"sacrifice": {"name": "Opferlicht", "short": "Opfer", "type": MODIFIER, "elem": "Licht",
			"desc": "Nächster Angriff viel stärker, kostet Laternenlicht"},
	"kindle": {"name": "Zündschnur", "short": "Zünder", "type": MODIFIER, "elem": "Feuer",
			"desc": "Nächster Angriff setzt alle Getroffenen in Brand (macht Kombos möglich)"},
	"mirror": {"name": "Spiegel", "short": "Spiegel", "type": MODIFIER, "elem": "Licht",
			"desc": "Löst das Feld davor (links) noch einmal aus – Angriff schwächer, Modifikator ganz"},
	"oath": {"name": "Schwur", "short": "Schwur", "type": MODIFIER, "elem": "Licht",
			"desc": "Im LETZTEN Feld: ganze nächste Runde stärker. Sonst nur der nächste Angriff etwas"},
	# --- Licht-Skills: senken den Wahnsinn, stärker mit klarem Geist ---
	"purge": {"name": "Läuterung", "short": "Läutern", "type": ATTACK, "elem": "Licht", "light": true,
			"desc": "Lichtwelle rundum. Senkt den Wahnsinn. Stärker, je wahnsinniger du bist"},
	"lance": {"name": "Lichtlanze", "short": "Lanze", "type": ATTACK, "elem": "Licht", "light": true,
			"desc": "Lichtstrahl auf den nächsten Gegner. Senkt den Wahnsinn. Stärker, je wahnsinniger du bist"},
	"vigil": {"name": "Andacht", "short": "Andacht", "type": MODIFIER, "elem": "Licht", "light": true,
			"desc": "Nächster Angriff senkt den Wahnsinn um 3"},
	# --- dunkle Skills (nur bei Wahnsinn ab 25 im Angebot) ---
	"rift": {"name": "Schattenriss", "short": "Riss", "type": ATTACK, "elem": "Schatten", "dark": true,
			"desc": "Schattenklinge trifft alles in einer Linie. Nährt den Wahnsinn. Stärker, je klarer dein Geist ist"},
	"scream": {"name": "Leerenschrei", "short": "Schrei", "type": ATTACK, "elem": "Schatten", "dark": true,
			"desc": "Gegner rundum fliehen voller Furcht. Nährt den Wahnsinn. Stärker, je klarer dein Geist ist"},
	"pact": {"name": "Schattenpakt", "short": "Pakt", "type": MODIFIER, "elem": "Schatten", "dark": true,
			"desc": "Nächster Angriff stärker. Nährt den Wahnsinn. Stärker, je klarer dein Geist ist"},
}

## Abzweigungen ab Stufe 3: [Name, Regel]
const BRANCHES := {
	"sickle": {"a": ["Wirbel", "Trifft rundum, aber −20 % Schaden"],
			"b": ["Ernte", "Gegner unter 25 % Leben sterben sofort"]},
	"bow": {"a": ["Salve", "3 Pfeile auf 3 Gegner, je 50 % Schaden"],
			"b": ["Markieren", "Getroffene sind 4 s markiert: +35 % Schaden von allem"]},
	"ember": {"a": ["Flächenbrand", "Aufprall setzt alle in 2,5 m in Brand"],
			"b": ["Funkentod", "Brennende Gegner explodieren beim Tod"]},
	"bell": {"a": ["Sog", "Zieht Gegner heran statt wegzustoßen"],
			"b": ["Lichtglocke", "Jeder getroffene Gegner gibt 1 s Laternenlicht"]},
	"mend": {"a": ["Lebensband", "Jeder Treffer heilt, aber nur 40 %"],
			"b": ["Überfluss", "Heilung über das Maximum füllt die Laterne"]},
	"echo": {"a": ["Nachhall", "Kein längerer Cast, Wiederholung nur 60 %"],
			"b": ["Dreiklang", "Dreimal statt zweimal, Cast ×2,2"]},
	"sacrifice": {"a": ["Blutopfer", "Kostet 6 Leben statt Laternenlicht"],
			"b": ["Wahnopfer", "Kostet nichts – nährt aber den Wahn (+5)"]},
	"kindle": {"a": ["Ölbrand", "Brand doppelt so stark"],
			"b": ["Schwelbrand", "Brand dauert dreimal so lange"]},
	"mirror": {"a": ["Klarer Spiegel", "Kopierter Angriff mit vollem Schaden"],
			"b": ["Dunkler Spiegel", "Kopiert Modifikatoren doppelt, Angriffe gar nicht"]},
	"oath": {"a": ["Ewiger Schwur", "Wirkt in jedem Feld als Runden-Bonus, aber nur +15 %"],
			"b": ["Blutschwur", "Im letzten Feld +50 %, kostet 3 Leben pro Runde"]},
	"purge": {"a": ["Heilige Flamme", "Getroffene brennen"],
			"b": ["Reinigung", "Senkt den Wahnsinn doppelt, halber Schaden"]},
	"lance": {"a": ["Durchbohren", "Trifft alle Gegner auf der Linie"],
			"b": ["Blenden", "Ziel ist 2 s erschüttert (Sichel zerschmettert)"]},
	"vigil": {"a": ["Tiefe Andacht", "Senkt den Wahnsinn doppelt"],
			"b": ["Lichtsegen", "Nächster Angriff zusätzlich +20 % Schaden"]},
	"rift": {"a": ["Schlund", "Linie doppelt so lang"],
			"b": ["Blutriss", "Heilt um 20 % des Schadens"]},
	"scream": {"a": ["Grauen", "Furcht doppelt so lange"],
			"b": ["Seelenraub", "Jeder Getroffene gibt 2 s Laternenlicht"]},
	"pact": {"a": ["Tiefer Pakt", "Doppelte Wirkung, doppelter Wahn"],
			"b": ["Stiller Pakt", "Nährt den Wahn nicht, halbe Wirkung"]},
}


static func is_attack(id: String) -> bool:
	return DEFS.has(id) and DEFS[id]["type"] == ATTACK


static func is_modifier(id: String) -> bool:
	return DEFS.has(id) and DEFS[id]["type"] == MODIFIER


static func is_dark(id: String) -> bool:
	return DEFS.has(id) and DEFS[id].get("dark", false)


static func is_light(id: String) -> bool:
	return DEFS.has(id) and DEFS[id].get("light", false)


static func short_name(id: String) -> String:
	return DEFS[id]["short"] if DEFS.has(id) else ""


static func branch_name(id: String, b: String) -> String:
	if not BRANCHES.has(id) or not BRANCHES[id].has(b):
		return ""
	return BRANCHES[id][b][0]


## Grund-Cast-Zeit in Sekunden (aus config.gd).
static func cast_time(id: String) -> float:
	match id:
		"sickle": return Config.cast_sickle
		"bow": return Config.cast_bow
		"ember": return Config.cast_ember
		"bell": return Config.cast_bell
		"rift": return Config.cast_rift
		"scream": return Config.cast_scream
		"purge": return Config.cast_purge
		"lance": return Config.cast_lance
	if is_modifier(id):
		return Config.cast_modifier
	return 0.0


static func color(id: String) -> Color:
	if is_dark(id):
		return Color(0.7, 0.35, 0.95)
	if is_light(id):
		return Color(1.0, 0.9, 0.45)
	if is_attack(id):
		return Color(0.95, 0.5, 0.25)
	if is_modifier(id):
		return Color(0.55, 0.6, 1.0)
	return Color(0.4, 0.4, 0.4)


const ROMAN := ["", "I", "II", "III", "IV", "V", "VI"]


## Kurzname mit Stufe, z. B. "Sichel II".
static func short_with_level(id: String, level: int) -> String:
	if id == "":
		return ""
	return short_name(id) + (" " + ROMAN[level] if level > 1 else "")


## Was bringt die nächste Stufe? (Text für die Level-up-Karte)
static func upgrade_text(id: String) -> String:
	var dmg := "+%d %% Schaden" % int(Config.skill_damage_per_level * 100)
	match id:
		"sickle": return "%s, +%.1f m Reichweite" % [dmg, Config.sickle_range_per_level]
		"bow", "rift", "scream", "purge", "lance": return dmg
		"vigil": return "senkt den Wahnsinn um 1 mehr"
		"ember": return "%s, +%.1f Brand/s" % [dmg, Config.ember_burn_per_level]
		"bell": return "%s, +%.1f m Radius" % [dmg, Config.bell_radius_per_level]
		"mend": return "+%d Heilung" % int(Config.mend_heal_per_level)
		"echo": return "Angriff dauert weniger lang"
		"sacrifice": return "+%.1f× Schaden" % Config.sacrifice_per_level
		"kindle": return "+%.1f Brand/s" % Config.kindle_per_level
		"mirror": return "Kopie +%d %% Schaden" % int(Config.mirror_per_level * 100)
		"oath": return "Runden-Bonus +%d %%" % int(Config.oath_per_level * 100)
		"pact": return "+10 % Wirkung"
	return ""
