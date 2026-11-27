## Haus eines Bewohners (v0.4): kleiner Bauplatz an der Mauer. Bewohner hacken in ihrer Freizeit selbst Holz
## und bauen es. Darin schlafen sie besser, haben einen eigenen Nahrungsvorrat, und Paare bekommen hier Kinder.
extends Node3D

var built := false
var claimed_by: Node3D = null      # wer gerade dafür Holz sammelt
var residents: Array = []          # wer hier wohnt (Paar, Kinder)
var _label: Label3D
var _house: Node3D
var _plot: MeshInstance3D


func _ready() -> void:
	add_to_group("huts")
	_plot = MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1.7, 1.7)
	_plot.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 0.85, 0.6, 0.07)
	_plot.material_override = mat
	_plot.position.y = 0.02
	add_child(_plot)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0007
	_label.font_size = 24
	_label.outline_size = 6
	_label.modulate = Color(1, 0.85, 0.65, 0.8)
	_label.position.y = 2.2
	add_child(_label)
	update_label()


func is_free() -> bool:
	return not built and (claimed_by == null or not is_instance_valid(claimed_by))


## Hier schläft man (vor dem Haus, Richtung Festungsmitte).
func bed_pos() -> Vector3:
	var to_center := -global_position
	to_center.y = 0
	return global_position + to_center.normalized() * 1.1


func build_for(r: Node3D) -> void:
	built = true
	claimed_by = null
	if not residents.has(r):
		residents.append(r)
	_build_visual()
	update_label()


func move_in(r: Node3D) -> void:
	if not residents.has(r):
		residents.append(r)
	update_label()


func move_out(r: Node3D) -> void:
	residents.erase(r)
	update_label()


func update_label() -> void:
	if _label == null:
		return
	if not built:
		_label.text = ""
		return
	var names := []
	for r in residents:
		if is_instance_valid(r) and not r.is_child():
			names.append(r.res_name)
	_label.text = "Haus von " + " & ".join(names) if not names.is_empty() else "leeres Haus"


func _build_visual() -> void:
	if _house:
		return
	_plot.visible = false
	_house = Node3D.new()
	add_child(_house)
	var wall := StandardMaterial3D.new()
	wall.albedo_color = Color(0.36, 0.29, 0.22)
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Color(0.22, 0.16, 0.12)
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.5, 1.2, 1.5)
	body.mesh = bm
	body.material_override = wall
	body.position.y = 0.6
	_house.add_child(body)
	var top := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(1.8, 0.7, 1.8)
	top.mesh = pm
	top.material_override = roof
	top.position.y = 1.55
	_house.add_child(top)
	# kleines warmes Fenster
	var win := MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(0.3, 0.3, 0.05)
	win.mesh = wm
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1, 0.7, 0.35)
	win.material_override = glow
	var to_center := -global_position
	to_center.y = 0
	var d := to_center.normalized()
	win.position = Vector3(d.x * 0.77, 0.7, d.z * 0.77)
	win.rotation.y = atan2(d.x, d.z)
	_house.add_child(win)
