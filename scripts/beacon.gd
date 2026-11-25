## Leuchtfeuer draußen im Gebiet. Einmal entzünden (kurz daneben stehen), dann:
## - eigener Lichtkreis (Kriecher meiden ihn, Laterne füllt sich hier auf)
## - Schnellreise zwischen Leuchtfeuer und Tor
extends Node3D

signal lit_up

var lit := false
var _progress := 0.0
var _light: OmniLight3D
var _flame: MeshInstance3D
var _label: Label3D
var _t := 0.0


func _ready() -> void:
	add_to_group("beacon")
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.35, 0.33, 0.3)
	# Sockel und Schale
	var base := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.8
	cm.height = 1.4
	cm.radial_segments = 8
	base.mesh = cm
	base.material_override = stone
	base.position.y = 0.7
	add_child(base)
	var bowl := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.9
	bm.bottom_radius = 0.5
	bm.height = 0.4
	bm.radial_segments = 8
	bowl.mesh = bm
	bowl.material_override = stone
	bowl.position.y = 1.6
	add_child(bowl)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.8
	cs.height = 2.0
	shape.shape = cs
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)
	_flame = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.55
	cone.height = 1.4
	cone.radial_segments = 6
	_flame.mesh = cone
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1, 0.6, 0.2)
	_flame.material_override = fm
	_flame.position.y = 2.4
	_flame.visible = false
	add_child(_flame)
	_light = OmniLight3D.new()
	_light.light_color = Color(1, 0.65, 0.35)
	_light.omni_attenuation = 0.7
	_light.shadow_enabled = false
	_light.position.y = 3.0
	_light.visible = false
	add_child(_light)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0009
	_label.font_size = 32
	_label.outline_size = 10
	_label.position.y = 3.2
	_label.modulate = Color(1, 0.8, 0.5, 0.85)
	_label.text = "Leuchtfeuer\n(daneben stehen zum Entzünden)"
	add_child(_label)
	Lights.register(self)


func _exit_tree() -> void:
	Lights.unregister(self)


func get_light_radius() -> float:
	return Config.beacon_light_radius if lit else 0.0


func can_refill_at(pos: Vector3) -> bool:
	return lit and _flat(pos).distance_to(_flat(global_position)) <= Config.beacon_refill_range


## Fortschritt fürs Entzünden (vom Hüter aufgerufen, solange er daneben steht).
func _process(delta: float) -> void:
	_t += delta
	if lit:
		var f := sin(_t * 9.0) * 0.08 + sin(_t * 21.0) * 0.05
		_light.light_energy = 2.0 * (1.0 + f)
		_light.omni_range = Config.beacon_light_radius * 1.2
		_flame.scale = Vector3(1, 1.0 + f * 2.0, 1)
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and player.is_alive() and _flat(player.global_position).distance_to(_flat(global_position)) < 2.6:
		_progress += delta
		_label.text = "Entzünden … %d %%" % int(100.0 * _progress / Config.beacon_light_time)
		if _progress >= Config.beacon_light_time:
			_light_up()
	else:
		_progress = 0.0
		_label.text = "Leuchtfeuer\n(daneben stehen zum Entzünden)"


func _light_up() -> void:
	lit = true
	Sfx.play("ignite", 0.0, 0.0)
	_flame.visible = true
	_light.visible = true
	_label.text = "Leuchtfeuer"
	get_tree().call_group("hud", "toast", "Leuchtfeuer entzündet – Schnellreise zum Tor möglich")
	get_tree().call_group("hud", "toast", "Weiter im Norden wartet der Hauptmann …")
	lit_up.emit()


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
