## Pilzstelle draußen (Nahrung). Holz kommt seit v0.2 von den Bäumen des Waldes (forest.gd).
## Bleibt der Hüter daneben stehen, sammelt er automatisch in die Trage. Sammler arbeiten hier ebenso.
## Leer -> wächst später nach.
extends Node3D

@export var kind := "food"         # nur noch "food"
@export var zone_id := ""          # zu welcher Zone die Fundstelle gehört ("" = keine)

var amount := 0
var _regrow := 0.0
var _visual: Node3D
var _label: Label3D


func _ready() -> void:
	add_to_group("resources")
	amount = _full_amount()
	_visual = Node3D.new()
	add_child(_visual)
	# leuchtende Pilze
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
	_label.position.y = 1.1
	_label.modulate = Color(1, 0.85, 0.6, 0.8) if kind == "wood" else Color(0.6, 1, 0.9, 0.8)
	add_child(_label)
	_update()


func _full_amount() -> int:
	return Config.food_per_node


func is_available() -> bool:
	return amount > 0


## Eine Einheit entnehmen.
func take_one() -> bool:
	if amount <= 0:
		return false
	amount -= 1
	if amount <= 0:
		_regrow = Config.resource_regrow
	_update()
	return true


func _update() -> void:
	_visual.visible = amount > 0
	_label.visible = amount > 0
	_label.text = "Nahrung %d" % amount


func _process(delta: float) -> void:
	if amount <= 0:
		_regrow -= delta
		if _regrow <= 0.0:
			amount = _full_amount()
			_update()
