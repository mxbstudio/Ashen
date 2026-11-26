## Fundstelle draußen: Holz (fällbarer Baum) oder Nahrung (leuchtende Pilze).
## Steht der Hüter daneben, hackt/sammelt er automatisch in die Trage. Bewohner arbeiten hier ebenso.
## Baum leer -> Stumpf, wächst später nach. Pilze leer -> wachsen später nach.
extends Node3D

@export var kind := "wood"         # "wood" oder "food"
@export var zone_id := ""          # zu welcher Zone die Fundstelle gehört ("" = keine)

var amount := 0
var _regrow := 0.0
var _visual: Node3D
var _stump: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group("resources")
	amount = _full_amount()
	_visual = Node3D.new()
	add_child(_visual)
	if kind == "wood":
		_build_tree()
	else:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(0.45, 0.85, 0.75)
		var stem := StandardMaterial3D.new()
		stem.albedo_color = Color(0.7, 0.7, 0.6)
		for i in 5:
			var a := TAU * i / 5.0
			var p := Vector3(cos(a), 0, sin(a)) * 0.45
			var cap := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.2 + 0.05 * (i % 2)
			sm.height = 0.2
			sm.radial_segments = 8
			sm.rings = 3
			cap.mesh = sm
			cap.material_override = mat
			cap.position = p + Vector3(0, 0.3, 0)
			_visual.add_child(cap)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0008
	_label.font_size = 30
	_label.outline_size = 8
	_label.position.y = 4.0 if kind == "wood" else 1.1
	_label.modulate = Color(1, 0.85, 0.6, 0.8) if kind == "wood" else Color(0.6, 1, 0.9, 0.8)
	add_child(_label)
	_update()


func _full_amount() -> int:
	return Config.tree_wood if kind == "wood" else Config.food_per_node


## Fällbarer Baum: etwas heller als der übrige Wald und leicht glimmend, damit man ihn erkennt.
## Darunter ein Stumpf, der nach dem Fällen stehen bleibt.
func _build_tree() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.29, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.17, 0.07)
	mat.emission_energy_multiplier = 0.35
	var trunk := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.1
	cm.bottom_radius = 0.32
	cm.height = 3.6
	cm.radial_segments = 6
	cm.rings = 1
	trunk.mesh = cm
	trunk.material_override = mat
	trunk.position.y = 1.8
	_visual.add_child(trunk)
	for i in 2:   # nur 2 Äste – spart Leistung im Browser
		var br := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.03
		bm.bottom_radius = 0.09
		bm.height = 1.3
		bm.radial_segments = 4
		bm.rings = 1
		br.mesh = bm
		br.material_override = mat
		var a := PI * i + 0.5
		br.position = Vector3(cos(a) * 0.35, 2.2 + i * 0.4, sin(a) * 0.35)
		br.rotation = Vector3(sin(a) * 0.9, 0, -cos(a) * 0.9)
		_visual.add_child(br)
	_stump = MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.3
	sm.bottom_radius = 0.36
	sm.height = 0.4
	sm.radial_segments = 6
	sm.rings = 1
	_stump.mesh = sm
	_stump.material_override = mat
	_stump.position.y = 0.2
	add_child(_stump)
	# Kollision: man läuft nicht durch den Baum
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.35
	cs.height = 2.0
	shape.shape = cs
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)


func is_available() -> bool:
	return amount > 0


## Eine Einheit entnehmen.
func take_one() -> bool:
	if amount <= 0:
		return false
	amount -= 1
	if amount <= 0:
		_regrow = Config.tree_regrow if kind == "wood" else Config.resource_regrow
	_update()
	return true


func _update() -> void:
	_visual.visible = amount > 0
	_label.visible = amount > 0
	_label.text = ("Baum: %d Holz" if kind == "wood" else "Nahrung %d") % amount


func _process(delta: float) -> void:
	if amount <= 0:
		_regrow -= delta
		if _regrow <= 0.0:
			amount = _full_amount()
			_update()
