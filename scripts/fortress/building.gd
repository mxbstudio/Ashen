## Ein Gebäude-Bauplatz in der Festung. Vor dem Bau: Umriss am Boden mit Namen und Kosten.
## Nach dem Bau: einfaches Haus. Produziert nur, wenn ein Bewohner darin arbeitet.
extends Node3D

const ArrowScript := preload("res://scripts/arrow.gd")

@export var kind := "storehouse"   # storehouse, scrapyard, mushroom, tower

var built := false
var worker: Node3D = null          # zugeteilter Bewohner
var _timer := 0.0
var _label: Label3D
var _house: Node3D
var _plot: MeshInstance3D

const NAMES := {"storehouse": "Vorratslager", "scrapyard": "Trümmerhof",
		"mushroom": "Pilzkeller", "tower": "Wachturm"}


func display_name() -> String:
	return NAMES[kind]


func cost() -> int:
	match kind:
		"storehouse": return Config.cost_storehouse
		"scrapyard": return Config.cost_scrapyard
		"mushroom": return Config.cost_mushroom
		"tower": return Config.cost_tower
	return 0


func needs_worker() -> bool:
	return kind != "storehouse"


func description() -> String:
	match kind:
		"storehouse": return "+%d Lagerplatz für Holz und Nahrung" % Config.storehouse_bonus
		"scrapyard": return "+1 Holz alle %d s (braucht Bewohner)" % int(Config.scrapyard_seconds_per_wood)
		"mushroom": return "+1 Nahrung alle %d s (braucht Bewohner)" % int(Config.mushroom_seconds_per_food)
		"tower": return "schießt auf Gegner vor dem Tor (braucht Bewohner)"
	return ""


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


func _update_label() -> void:
	if built:
		_label.text = display_name() + ("" if worker or not needs_worker() else "\n(kein Bewohner)")
		_label.position.y = 4.2 if kind == "tower" else 3.0
	else:
		_label.text = "%s\nBauen: %d Holz" % [display_name(), cost()]


## Bauen (Kosten werden von der Festung abgezogen).
func build() -> void:
	built = true
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
		var r := _add_box(Vector3(3.8, 0.3, 3.4), Vector3(0, 2.2, 0), roof)
		r.rotation.x = 0.0
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
	_update_label()


func _add_box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = pos
	_house.add_child(m)
	return m


## Stelle, an der der Bewohner arbeitet (vor dem Gebäude, Richtung Feuer).
func work_spot() -> Vector3:
	var to_center := -global_position
	to_center.y = 0
	return global_position + to_center.normalized() * 2.4


func set_worker(w: Node3D) -> void:
	worker = w
	_update_label()


## Läuft pro Sekunde in der Festung (auch beim "Zeitsprung" nach dem Tod).
## Gibt zurück, was produziert wurde: {"wood": n, "food": n}
func advance(dt: float) -> Dictionary:
	var out := {"wood": 0, "food": 0}
	if not built or (needs_worker() and worker == null):
		return out
	match kind:
		"scrapyard":
			_timer += dt
			while _timer >= Config.scrapyard_seconds_per_wood:
				_timer -= Config.scrapyard_seconds_per_wood
				out["wood"] += 1
		"mushroom":
			_timer += dt
			while _timer >= Config.mushroom_seconds_per_food:
				_timer -= Config.mushroom_seconds_per_food
				out["food"] += 1
	return out


## Wachturm: schießt auf den nächsten Gegner in Reichweite.
func _process(delta: float) -> void:
	if kind != "tower" or not built or worker == null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var best: Node3D = null
	var best_d := Config.tower_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_alive():
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	if best == null:
		return
	_timer = Config.tower_interval
	var arrow := Node3D.new()
	arrow.set_script(ArrowScript)
	get_parent().add_child(arrow)
	arrow.global_position = global_position + Vector3(0, 4.5, 0)
	arrow.launch(best, Config.tower_damage, {}, self)


## Wird vom Pfeil aufgerufen (wie beim Hüter).
func hit(target: Node3D, amount: float, _heal: Dictionary) -> void:
	if is_instance_valid(target) and target.is_alive():
		target.take_damage(amount, self)
