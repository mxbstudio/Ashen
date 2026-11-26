## Die Zonen draußen (nur Daten, keine Logik).
## Jede Zone hat einen Platz für einen Fackelpfahl und ein paar Fundstellen in seinem Lichtkreis.
## Die Zone "Leuchtfeuer" nutzt das vorhandene Leuchtfeuer statt eines Fackelpfahls.
## Später (Etappe 2) arbeiten Bewohner nur in Zonen, die hell sind.
class_name ZoneDefs
extends RefCounted

## name: Anzeigename · torch: Platz des Fackelpfahls (null = Leuchtfeuer-Zone)
## center: Mitte der Zone · trees/rocks: so viele Bäume/Felsen liegen zusätzlich rund um die Mitte · food: Pilzstellen
const ZONES := [
	{"id": "west", "name": "Westsenke", "torch": Vector3(-17, 0, -25), "center": Vector3(-17, 0, -25),
		"trees": 6, "rocks": 2, "food": [Vector3(-15, 0, -20), Vector3(-21, 0, -21)]},
	{"id": "east", "name": "Osthain", "torch": Vector3(18, 0, -27), "center": Vector3(18, 0, -27),
		"trees": 6, "rocks": 2, "food": [Vector3(22, 0, -23), Vector3(14, 0, -23)]},
	{"id": "beacon", "name": "Leuchtfeuer", "torch": null, "center": Vector3(0, 0, -50),
		"trees": 6, "rocks": 2, "food": [Vector3(-6, 0, -54), Vector3(-5, 0, -46)]},
	{"id": "moor", "name": "Pilzmoor", "torch": Vector3(-20, 0, -62), "center": Vector3(-20, 0, -62),
		"trees": 6, "rocks": 2, "food": [Vector3(-23, 0, -66), Vector3(-16, 0, -65), Vector3(-24, 0, -59)]},
	{"id": "north", "name": "Nordwald", "torch": Vector3(19, 0, -60), "center": Vector3(19, 0, -60),
		"trees": 6, "rocks": 2, "food": [Vector3(15, 0, -56), Vector3(23, 0, -64)]},
]

## Pilzstellen, die zu keiner Zone gehören (liegen im Dunkeln – für den Hüter selbst).
## Holz gibt es überall: jeder Baum im Wald ist fällbar.
const LOOSE_FOOD := [Vector3(9, 0, -40), Vector3(-12, 0, -44)]


## Plätze der fällbaren Bäume einer Zone: im Kreis um die Mitte (4,5–6,5 m, also im Fackellicht),
## nicht auf Pilzstellen, nicht auf dem Weg nach Norden und nicht am Kartenrand.
static func tree_spots(z: Dictionary) -> Array:
	var out := []
	var c: Vector3 = z["center"]
	var offset := float(c.x * 0.37 + c.z * 0.11)   # jede Zone etwas anders gedreht
	for i in 12:
		if out.size() >= z["trees"]:
			break
		var a := offset + TAU * i / 12.0
		var r := 4.5 if i % 2 == 0 else 6.5
		var p := c + Vector3(cos(a), 0, sin(a)) * r
		if absf(p.x) > 27.0 or p.z > -15.0 or p.z < -89.0:
			continue
		if absf(p.x - path_x(p.z)) < 2.5:
			continue
		var free := true
		for f in z["food"]:
			if p.distance_to(f) < 2.5:
				free = false
		if free:
			out.append(p)
	return out


## Plätze der extra Felsen einer Zone (Stein): zwischen den Bäumen, 5,5 m von der Mitte.
static func rock_spots(z: Dictionary) -> Array:
	var out := []
	var c: Vector3 = z["center"]
	var offset := float(c.x * 0.37 + c.z * 0.11) + TAU / 24.0
	var taken: Array = tree_spots(z) + z["food"]
	for i in 12:
		if out.size() >= z.get("rocks", 0):
			break
		var a := offset + TAU * (i * 5 % 12) / 12.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 5.5
		if absf(p.x) > 27.0 or p.z > -15.0 or p.z < -89.0 or absf(p.x - path_x(p.z)) < 2.5:
			continue
		var free := true
		for q in taken + out:
			if p.distance_to(q) < 2.2:
				free = false
		if free:
			out.append(p)
	return out


## Der Weg vom Tor nach Norden schlängelt sich leicht (gleiche Formel wie in world.gd).
static func path_x(z: float) -> float:
	return sin(z * 0.08) * 5.0 if z < -37.0 else 0.0


## Alle Fackelplätze (für die Lichtungen im Wald).
static func torch_spots() -> Array:
	var out := []
	for z in ZONES:
		if z["torch"] != null:
			out.append(z["torch"])
	return out
