## Bewohner mit Eigenleben (v0.3): Namen, Eigenschaften, Stimmung (nur Daten und kleine Helfer).
class_name ResidentData
extends RefCounted

const NAMES := ["Hanna", "Jorin", "Mara", "Tilo", "Greta", "Anselm", "Wiebke", "Konrad", "Ilse", "Bertram",
		"Liesel", "Ruprecht", "Agnes", "Veit", "Frieda", "Gunther", "Elsa", "Oswin", "Marthe", "Utz",
		"Brigitte", "Lorenz", "Hilde", "Matthis", "Odila", "Kaspar", "Rike", "Albrecht", "Wendel", "Imke",
		"Ottilie", "Ruben", "Gesa", "Florin", "Thea", "Ewald"]

## Eigenschaften: [Name, Wirkung]
const TRAITS := {
	"flink": ["Flink", "läuft draußen 30 % schneller"],
	"kraeftig": ["Kräftig", "trägt 2 mehr pro Gang"],
	"zaeh": ["Zäh", "+50 % Leben"],
	"schuetze": ["Guter Schütze", "Bogen und Mauer: doppelter Schaden"],
	"fleissig": ["Fleißig", "arbeitet 25 % schneller"],
	"genuegsam": ["Genügsam", "isst nur halb so viel"],
	"vielfrass": ["Vielfraß", "isst doppelt so viel"],
	"prediger": ["Prediger", "hebt die Stimmung aller, beruhigt den Hüter am Feuer"],
	"kraenklich": ["Kränklich", "−25 % Leben, heilt langsam"],
	"feuerhueter": ["Feuerhüter", "das Feuer braucht 10 % weniger Holz"],
	"aengstlich": ["Ängstlich", "geht bei schlechter Stimmung nicht hinaus"],
}

## Häufigkeit beim Würfeln (gute und schlechte Eigenschaften gemischt)
const WEIGHTS := {"flink": 3, "kraeftig": 3, "zaeh": 3, "schuetze": 3, "fleissig": 3, "genuegsam": 2,
		"vielfrass": 2, "prediger": 1, "kraenklich": 2, "feuerhueter": 1, "aengstlich": 2}

const OPPOSITES := [["genuegsam", "vielfrass"], ["zaeh", "kraenklich"]]


static func trait_name(t: String) -> String:
	return TRAITS[t][0] if TRAITS.has(t) else t


static func trait_desc(t: String) -> String:
	return TRAITS[t][1] if TRAITS.has(t) else ""


## Ein Name, der in der Festung noch nicht vergeben ist.
static func pick_name(rng: RandomNumberGenerator, taken: Array) -> String:
	var free := NAMES.filter(func(n): return not taken.has(n))
	if free.is_empty():
		return NAMES[rng.randi() % NAMES.size()] + " II"
	return free[rng.randi() % free.size()]


## 1 Eigenschaft, manchmal 2 (nie zwei gegensätzliche).
static func roll_traits(rng: RandomNumberGenerator) -> Array:
	var out := [_weighted(rng)]
	if rng.randf() < 0.35:
		var second := _weighted(rng)
		var clash: bool = second == out[0]
		for pair in OPPOSITES:
			if pair.has(second) and pair.has(out[0]):
				clash = true
		if not clash:
			out.append(second)
	return out


static func _weighted(rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in WEIGHTS:
		total += WEIGHTS[k]
	var r := rng.randi() % total
	for k in WEIGHTS:
		r -= WEIGHTS[k]
		if r < 0:
			return k
	return "flink"


static func mood_word(mood: float) -> String:
	if mood >= 75.0:
		return "zuversichtlich"
	if mood >= 45.0:
		return "gefasst"
	if mood >= 25.0:
		return "bedrückt"
	return "verzweifelt"


static func mood_color(mood: float) -> Color:
	if mood >= 75.0:
		return Color(0.6, 1, 0.6)
	if mood >= 45.0:
		return Color(0.95, 0.9, 0.8)
	if mood >= 25.0:
		return Color(1, 0.75, 0.45)
	return Color(1, 0.35, 0.3)
