## Feuerstelle: vom Hüter überall draußen gebaut (kostet Stein, siehe ui/place_buttons.gd).
## Wie ein Fackelpfahl (Brennstoff, Holz nachlegen, Lichtfresser), aber:
## - größerer Lichtkreis, fasst mehr Holz
## - die Laterne füllt sich hier auf
## - Bewohner bringen von selbst Holz, wenn sie bald ausgeht (siehe fortress.gd / resident.gd)
extends "res://scripts/zones/torch_post.gd"

var courier: Node3D = null         # Bewohner, der gerade Holz hierher bringt


func _ready() -> void:
	zone_name = "Feuerstelle"
	super._ready()
	remove_from_group("torches")   # zählt nicht als Zonen-Fackel
	add_to_group("fire_pits")


func seconds_per_wood() -> float:
	return Config.firepit_seconds_per_wood


func max_wood() -> int:
	return Config.firepit_max_wood


func light_radius_full() -> float:
	return Config.firepit_light_radius


func flame_size() -> float:
	return 1.6


func title() -> String:
	return "Feuerstelle"


## Bald leer? Dann holen Bewohner Holz.
func needs_wood() -> bool:
	return built and fuel < max_fuel() * Config.firepit_refill_below


## Laterne auffüllen (nur, solange sie brennt und man nah genug ist).
func refills_lantern_at(pos: Vector3) -> bool:
	return is_burning() and Vector2(pos.x - global_position.x, pos.z - global_position.z).length() <= 2.8


## Aussehen: Steinkreis mit Holzscheiten statt Pfahl.
func _build_visuals() -> void:
	super._build_visuals()
	for c in _pole.get_children():
		c.queue_free()
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.34, 0.32, 0.31)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.25, 0.15, 0.1)
	for i in 7:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.4, 0.28, 0.32)
		m.mesh = bm
		m.material_override = stone
		var a := TAU * i / 7.0
		m.position = Vector3(cos(a) * 0.85, 0.14, sin(a) * 0.85)
		m.rotation.y = -a
		_pole.add_child(m)
	for i in 2:
		var l := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.1
		cm.bottom_radius = 0.1
		cm.height = 1.1
		cm.radial_segments = 6
		l.mesh = cm
		l.material_override = wood
		l.rotation = Vector3(PI / 2.0, i * PI / 2.0, 0)
		l.position.y = 0.18
		_pole.add_child(l)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.8
	cs.height = 1.0
	shape.shape = cs
	shape.position.y = 0.5
	body.add_child(shape)
	_pole.add_child(body)
	_flame.position.y = 0.75
	_light.position.y = 2.4
	_label.position.y = 2.2
