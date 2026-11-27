## Ein Gebäude in der Festung mit Stufen (0 = nur Bauplatz, 1–3 = gebaut/verbessert).
## Vor dem Bau: Umriss am Boden mit Namen und Kosten. Nach dem Bau: einfaches Haus,
## jede Stufe bekommt ein kleines Fähnchen mehr.
## Stufen: Vorratslager mehr Lagerplatz · Trümmerhof/Pilzkeller mehr Arbeitsplätze ·
## Wachturm mehr Schaden, Reichweite und Tempo.
extends Node3D

const ArrowScript := preload("res://scripts/arrow.gd")
const MAX_LEVEL := 3

@export var kind := "storehouse"   # storehouse, scrapyard, mushroom, tower, workshop, carts, tavern

var level := 0                     # 0 = noch nicht gebaut
var built := false                 # = level >= 1
var workers: Array[Node3D] = []    # zugeteilte Bewohner
var wanted := 0                    # so viele sollen hier arbeiten (Einteilen-Menü; beim Bauen = alle Plätze)
var resting := false               # wird gerade nicht gebraucht (Lager voll / genug Bögen) -> Arbeiter helfen woanders
var _timer := 0.0
var _label: Label3D
var _house: Node3D
var _plot: MeshInstance3D
var _flags: Array[MeshInstance3D] = []

const NAMES := {"storehouse": "Vorratslager", "scrapyard": "Trümmerhof",
		"mushroom": "Pilzkeller", "tower": "Wachturm", "workshop": "Werkstatt", "carts": "Karrenschuppen", "tavern": "Gasthaus"}


func display_name() -> String:
	return NAMES[kind]


## Baukosten (Stufe 1).
func cost() -> int:
	match kind:
		"storehouse": return Config.cost_storehouse
		"scrapyard": return Config.cost_scrapyard
		"mushroom": return Config.cost_mushroom
		"tower": return Config.cost_tower
		"workshop": return Config.cost_workshop
		"carts": return Config.cost_carts
		"tavern": return Config.cost_tavern
	return 0


## Kosten für den nächsten Schritt (Bauen oder Verbessern).
func next_cost() -> int:
	match level:
		0: return cost()
		1: return Config.upgrade_cost_2
	return Config.upgrade_cost_3


func can_improve() -> bool:
	return level < MAX_LEVEL


func needs_worker() -> bool:
	return kind != "storehouse" and kind != "tavern"


## Wie viele Bewohner können hier arbeiten?
## Wird das Gebäude gerade gebraucht? (mit etwas Abstand, damit es nicht ständig hin und her springt)
## Gibt true zurück, wenn sich etwas geändert hat.
func update_need(fort: Node) -> bool:
	var was := resting
	match kind:
		"scrapyard":
			resting = fort.wood >= fort.wood_cap() - 1 if not resting else fort.wood >= fort.wood_cap() * 0.85
		"mushroom":
			resting = fort.food >= fort.food_cap() - 1 if not resting else fort.food >= fort.food_cap() * 0.85
		"workshop":
			resting = fort.bows_total() >= fort.residents.size()
		_:
			resting = false
	if resting != was:
		_update_label()
	return resting != was


## Warum ruht es? (für Menü und Schild)
func rest_reason() -> String:
	match kind:
		"workshop": return "genug Bögen"
		"scrapyard": return "Holzlager voll"
		"mushroom": return "Nahrungslager voll"
	return ""


func wanted_workers() -> int:
	return mini(wanted, capacity())


func capacity(at_level := -1) -> int:
	var l := level if at_level < 0 else at_level
	if l <= 0 or not needs_worker():
		return 0
	return 1 if kind == "tower" else l


# --- Wachturm-Werte je Stufe ----------------------------------------------------
func tower_damage(l := -1) -> float:
	return Config.tower_damage * (1.0 + Config.tower_damage_per_level * ((level if l < 0 else l) - 1))


func tower_range(l := -1) -> float:
	return Config.tower_range + Config.tower_range_per_level * ((level if l < 0 else l) - 1)


func tower_interval(l := -1) -> float:
	return Config.tower_interval * pow(Config.tower_interval_per_level, (level if l < 0 else l) - 1)


## Beschreibung der Stufe l (für den Bau-/Verbessern-Knopf).
func description(l := 1) -> String:
	match kind:
		"storehouse": return "+%d Lagerplatz für Holz und Nahrung" % (Config.storehouse_bonus * l)
		"scrapyard": return "%s, je +1 Holz alle %d s" % [_places(l), int(Config.scrapyard_seconds_per_wood)]
		"mushroom": return "%s, je +1 Nahrung alle %d s" % [_places(l), int(Config.mushroom_seconds_per_food)]
		"tavern": return "Bewohner essen hier: 1 Nahrung sättigt +%d %%, Stimmung +%d" % [
				roundi(Config.tavern_satiety_per_level * l * 100), roundi(Config.tavern_mood * l)]
		"carts": return "%d Karren – holen Holz, Nahrung, Stein von den Lagerplätzen an den Fackeln (je %d)" % [
				capacity(l), Config.cart_capacity]
		"workshop": return "%s, je 1 Bogen alle %d s (%d Holz pro Bogen)" % [_places(l),
				int(Config.bow_craft_seconds), Config.bow_wood_cost]
		"tower": return "Schaden %d · Reichweite %d m · alle %.1f s (braucht Bewohner)" % [
				roundi(tower_damage(l)), roundi(tower_range(l)), tower_interval(l)]
	return ""


func _places(l: int) -> String:
	var n := capacity(l)
	return "1 Arbeitsplatz" if n == 1 else "%d Arbeitsplätze" % n


func _ready() -> void:
	add_to_group("buildings")
	_plot = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(4, 4)
	_plot.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 0.8, 0.5, 0.12)
	_plot.material_override = mat
	_plot.position.y = 0.02
	add_child(_plot)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0009
	_label.font_size = 34
	_label.outline_size = 10
	_label.position.y = 1.2
	_label.modulate = Color(1, 0.85, 0.6, 0.85)
	add_child(_label)
	_update_label()


func update_label() -> void:
	_update_label()


func _update_label() -> void:
	if not built:
		_label.text = "%s\nBauen: %d Holz" % [display_name(), cost()]
		return
	var t := display_name() + (" (St. %d)" % level if level > 1 else "")
	if needs_worker() and resting:
		t += "\n(ruht – %s)" % rest_reason()
	elif needs_worker():
		if workers.is_empty():
			t += "\n(kein Bewohner)"
		elif capacity() > 1:
			t += "\n%d/%d Bewohner" % [workers.size(), capacity()]
	_label.text = t
	_label.position.y = 4.4 if kind == "tower" else 3.2


## Bauen bzw. eine Stufe verbessern (Kosten zieht die Festung ab).
func improve() -> void:
	if level == 0:
		_build_house()
	level += 1
	built = true
	Sfx.play_at("gate", global_position, 0.0, 0.0)
	_add_flag()
	_update_label()


func _build_house() -> void:
	_plot.visible = false
	_house = Node3D.new()
	add_child(_house)
	var wall := StandardMaterial3D.new()
	wall.albedo_color = Color(0.32, 0.27, 0.22)
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Color(0.2, 0.15, 0.12)
	if kind == "tower":
		_add_box(Vector3(2, 4, 2), Vector3(0, 2, 0), wall)
		_add_box(Vector3(2.6, 0.4, 2.6), Vector3(0, 4.2, 0), roof)
	else:
		_add_box(Vector3(3.4, 2.0, 3.0), Vector3(0, 1.0, 0), wall)
		_add_box(Vector3(3.8, 0.3, 3.4), Vector3(0, 2.2, 0), roof)
		if kind == "mushroom":
			# leuchtende Pilze vor dem Keller
			var glow := StandardMaterial3D.new()
			glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			glow.albedo_color = Color(0.5, 0.9, 0.8)
			for i in 3:
				var s := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.18
				sm.height = 0.2
				s.mesh = sm
				s.material_override = glow
				s.position = Vector3(-0.8 + i * 0.6, 0.15, 1.8)
				_house.add_child(s)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 3, 2.2) if kind == "tower" else Vector3(3.4, 3, 3.0)
	shape.shape = box
	shape.position.y = 1.5
	body.add_child(shape)
	_house.add_child(body)


## Pro Stufe ein Fähnchen auf dem Dach (man sieht die Stufe von Weitem).
func _add_flag() -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.85, 0.45, 0.2)
	var top := 4.4 if kind == "tower" else 2.35
	var x := -0.7 + 0.7 * _flags.size()
	var pole := _add_box(Vector3(0.06, 0.9, 0.06), Vector3(x, top + 0.45, 0), m)
	var flag := _add_box(Vector3(0.4, 0.25, 0.04), Vector3(x + 0.2, top + 0.75, 0), m)
	_flags.append(pole)
	_flags.append(flag)


func _add_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = pos
	_house.add_child(m)
	return m


## Wachturm: Standplatz oben auf dem Dach (für den Hüter).
func top_position() -> Vector3:
	return global_position + Vector3(0, 4.4, 0)


## Wachturm: so viel weiter reicht der Hüter, wenn er oben steht.
func climb_range_bonus() -> float:
	return Config.tower_climb_range + Config.tower_climb_range_per_level * (level - 1)


## Stelle, an der Bewohner arbeiten und der Hüter verbessern kann (vor dem Gebäude, Richtung Feuer).
func work_spot() -> Vector3:
	var to_center := -global_position
	to_center.y = 0
	return global_position + to_center.normalized() * 2.4


func set_workers(list: Array[Node3D]) -> void:
	workers = list
	_update_label()


## Läuft pro Sekunde in der Festung (auch beim "Zeitsprung" nach dem Tod).
## Jeder Bewohner hier arbeitet für sich. Gibt zurück, was produziert wurde: {"wood": n, "food": n}
func advance(dt: float) -> Dictionary:
	var out := {"wood": 0, "food": 0, "bows": 0}
	if not built or workers.is_empty():
		return out
	var work := 0.0                # Arbeitskraft: jeder Bewohner nach Stimmung und Fleiß (v0.3)
	for w in workers:
		work += w.efficiency() if is_instance_valid(w) else 0.0
	match kind:
		"scrapyard":
			_timer += dt * work
			while _timer >= Config.scrapyard_seconds_per_wood:
				_timer -= Config.scrapyard_seconds_per_wood
				out["wood"] += 1
		"mushroom":
			_timer += dt * work
			while _timer >= Config.mushroom_seconds_per_food:
				_timer -= Config.mushroom_seconds_per_food
				out["food"] += 1
		"workshop":
			# Bögen bauen: kostet Holz; hört auf, wenn jeder Bewohner einen Bogen haben könnte
			var fort := get_parent()
			_timer += dt * work
			while _timer >= Config.bow_craft_seconds:
				if fort.bows_total() + out["bows"] >= fort.residents.size() \
						or fort.wood + out["wood"] - Config.bow_wood_cost < Config.vital_reserve:
					_timer = Config.bow_craft_seconds   # wartet auf Holz bzw. Bedarf
					break
				_timer -= Config.bow_craft_seconds
				out["wood"] -= Config.bow_wood_cost
				out["bows"] += 1
	return out


## Wachturm: schießt auf den nächsten Gegner in Reichweite.
func _process(delta: float) -> void:
	if kind != "tower" or not built or workers.is_empty():
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var best: Node3D = null
	var best_d := tower_range()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_alive():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return
	_timer = tower_interval()
	var arrow := Node3D.new()
	arrow.set_script(ArrowScript)
	get_parent().add_child(arrow)
	arrow.global_position = global_position + Vector3(0, 4.5, 0)
	var sharp: bool = workers.any(func(w): return is_instance_valid(w) and w.has_trait("schuetze"))
	arrow.launch(best, tower_damage() * (1.5 if sharp else 1.0), {}, self)


## Wird vom Pfeil aufgerufen (wie beim Hüter).
func hit(target: Node3D, amount: float, _heal: Dictionary) -> void:
	if is_instance_valid(target) and target.is_alive():
		target.take_damage(amount, self)
