## Die Zonen draußen (nur Daten, keine Logik).
## Jede Zone hat einen Platz für einen Fackelpfahl und ein paar Fundstellen in seinem Lichtkreis.
## Die Zone "Leuchtfeuer" nutzt das vorhandene Leuchtfeuer statt eines Fackelpfahls.
## Später (Etappe 2) arbeiten Bewohner nur in Zonen, die hell sind.
class_name ZoneDefs
extends RefCounted

## name: Anzeigename · torch: Platz des Fackelpfahls (null = Leuchtfeuer-Zone)
## wood / food: Fundstellen in dieser Zone
const ZONES := [
	{"id": "west", "name": "Westsenke", "torch": Vector3(-17, 0, -25),
		"wood": [Vector3(-20, 0, -29), Vector3(-12, 0, -28)], "food": [Vector3(-15, 0, -20)]},
	{"id": "east", "name": "Osthain", "torch": Vector3(18, 0, -27),
		"wood": [Vector3(21, 0, -31), Vector3(14, 0, -31)], "food": [Vector3(22, 0, -23)]},
	{"id": "beacon", "name": "Leuchtfeuer", "torch": null,
		"wood": [Vector3(-5, 0, -45), Vector3(5, 0, -55)], "food": [Vector3(-6, 0, -54)]},
	{"id": "moor", "name": "Pilzmoor", "torch": Vector3(-20, 0, -62),
		"wood": [Vector3(-22, 0, -57)], "food": [Vector3(-23, 0, -66), Vector3(-16, 0, -65)]},
	{"id": "north", "name": "Nordwald", "torch": Vector3(19, 0, -60),
		"wood": [Vector3(16, 0, -64), Vector3(22, 0, -56)], "food": [Vector3(15, 0, -56)]},
]

## Fundstellen, die zu keiner Zone gehören (liegen im Dunkeln, z. B. vor dem Tor).
const LOOSE_WOOD := [Vector3(-8, 0, -20)]
const LOOSE_FOOD := []


## Alle Fundstellen-Positionen (für die Lichtungen im Wald).
static func all_spots() -> Array:
	var out := LOOSE_WOOD + LOOSE_FOOD
	for z in ZONES:
		out += z["wood"] + z["food"]
	return out


## Alle Fackelplätze (für die Lichtungen im Wald).
static func torch_spots() -> Array:
	var out := []
	for z in ZONES:
		if z["torch"] != null:
			out.append(z["torch"])
	return out
