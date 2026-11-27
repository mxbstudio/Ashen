## Schrein draußen im Dunkeln (v0.3): birgt einen Talisman.
## 1,5 s daneben stehen -> der Hüter nimmt den Talisman. Der Schrein flüstert dabei (+5 Wahnsinn).
## Danach ist er leer (bleibt im Speicherstand leer).
extends Node3D

const SPOTS := [Vector3(26, 0, -44), Vector3(-8, 0, -64), Vector3(-26, 0, -84)]   # nur 3 – Talismane sollen selten sein

var opened := false
var _t := 0.0
var _glow: OmniLight3D
var _gem_mat := StandardMaterial3D.new()
var _label: Label3D


func _ready() -> void:
	add_to_group("shrines")
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.25, 0.23, 0.27)
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 0.4, 1.2)
	base.mesh = bm
	base.material_override = stone
	base.position.y = 0.2
	add_child(base)
	var pillar := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.5, 1.6, 0.5)
	pillar.mesh = pm
	pillar.material_override = stone
	pillar.position.y = 1.2
	add_child(pillar)
	_gem_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_gem_mat.albedo_color = Color(0.75, 0.4, 1.0)
	var gem := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	sm.radial_segments = 8
	sm.rings = 4
	gem.mesh = sm
	gem.material_override = _gem_mat
	gem.position.y = 2.2
	add_child(gem)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(0.6, 0.3, 0.9)
	_glow.light_energy = 0.8
	_glow.omni_range = 3.5
	_glow.shadow_enabled = false
	_glow.position.y = 2.2
	add_child(_glow)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 2.0, 1.0)
	shape.shape = box
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0009
	_label.font_size = 30
	_label.outline_size = 8
	_label.modulate = Color(0.85, 0.65, 1.0, 0.9)
	_label.position.y = 3.0
	_label.text = "Schrein"
	add_child(_label)
	set_opened(opened)


func set_opened(v: bool) -> void:
	opened = v
	if _glow == null:
		return
	_glow.visible = not opened
	_gem_mat.albedo_color = Color(0.3, 0.25, 0.32) if opened else Color(0.75, 0.4, 1.0)
	_label.text = "Schrein (leer)" if opened else "Schrein"


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var d := Vector2(player.global_position.x - global_position.x, player.global_position.z - global_position.z).length()
	_label.visible = d < 12.0
	if opened:
		return
	_glow.light_energy = 0.8 + 0.3 * sin(Time.get_ticks_msec() / 300.0)
	if d < 2.2 and player.is_alive():
		_t += delta
		_label.text = "Schrein … %d %%" % int(minf(_t / Config.shrine_time, 1.0) * 100)
		if _t >= Config.shrine_time:
			set_opened(true)
			player.madness.add(5.0)
			get_tree().call_group("hud", "whisper", "… nimm es … es gehört ohnehin uns …")
			player.find_talisman("einem Schrein")
	elif _t > 0.0:
		_t = 0.0
		_label.text = "Schrein"
