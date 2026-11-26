## Beschreibung aller Skills: Name, Kurzname, Typ (Angriff/Modifikator), Farbe.
## Cast-Zeiten und Schaden stehen in config.gd.
class_name SkillData
extends RefCounted

const ATTACK := "attack"
const MODIFIER := "modifier"

const DEFS := {
	"sickle": {"name": "Sichelhieb", "short": "Sichel", "type": ATTACK,
			"desc": "Nahkampf-Bogen vor dem Hüter"},
	"bow": {"name": "Bogenschuss", "short": "Bogen", "type": ATTACK,
			"desc": "Pfeil auf den nächsten Gegner"},
	"ember": {"name": "Glutwurf", "short": "Glut", "type": ATTACK,
			"desc": "Brennendes Geschoss, schneller Cast"},
	"bell": {"name": "Glockenschlag", "short": "Glocke", "type": ATTACK,
			"desc": "Schockwelle rundum, stößt zurück"},
	"mend": {"name": "Labung", "short": "Labung", "type": MODIFIER,
			"desc": "Nächster Treffer heilt"},
	"echo": {"name": "Echo", "short": "Echo", "type": MODIFIER,
			"desc": "Nächster Angriff zweimal, Cast länger"},
	"sacrifice": {"name": "Opferlicht", "short": "Opfer", "type": MODIFIER,
			"desc": "Nächster Angriff viel stärker, kostet Laternenlicht"},
}


static func is_attack(id: String) -> bool:
	return DEFS.has(id) and DEFS[id]["type"] == ATTACK


static func is_modifier(id: String) -> bool:
	return DEFS.has(id) and DEFS[id]["type"] == MODIFIER


static func short_name(id: String) -> String:
	return DEFS[id]["short"] if DEFS.has(id) else ""


## Grund-Cast-Zeit in Sekunden (aus config.gd).
static func cast_time(id: String) -> float:
	match id:
		"sickle": return Config.cast_sickle
		"bow": return Config.cast_bow
		"ember": return Config.cast_ember
		"bell": return Config.cast_bell
		"mend", "echo", "sacrifice": return Config.cast_modifier
	return 0.0


static func color(id: String) -> Color:
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
		"bow": return dmg
		"ember": return "%s, +%.1f Brand/s" % [dmg, Config.ember_burn_per_level]
		"bell": return "%s, +%.1f m Radius" % [dmg, Config.bell_radius_per_level]
		"mend": return "+%d Heilung" % int(Config.mend_heal_per_level)
		"echo": return "Angriff dauert weniger lang"
		"sacrifice": return "+%.1f× Schaden" % Config.sacrifice_per_level
	return ""
