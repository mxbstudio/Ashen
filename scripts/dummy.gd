## Übungspuppe: steht still, nimmt Schaden, fällt um und steht nach kurzer Zeit wieder auf.
## Dient zum Testen der Skill-Leiste, bis echte Gegner da sind.
extends StaticBody3D

const DamageNumber := preload("res://scripts/damage_number.gd")

var hit_radius := 0.5
var hp := 0.0
var _respawn := 0.0
var _flash := 0.0
var _model: Node3D
var _mat: StandardMaterial3D
var _hp_label: Label3D


func _ready() -> void:
	add_to_group("enemies")
	hp = Config.dummy_hp
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.45, 0.38, 0.28)
	_model = Node3D.new()
	add_child(_model)
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = 0.25
	cm.height = 1.6
	cm.radial_segments = 8
	post.mesh = cm
	post.material_override = _mat
	post.position.y = 0.8
	_model.add_child(post)
	var arms := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 0.15, 0.15)
	arms.mesh = bm
	arms.material_override = _mat
	arms.position.y = 1.25
	_model.add_child(arms)
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.35
	cs.height = 1.8
	shape.shape = cs
	shape.position.y = 0.9
	add_child(shape)
	_hp_label = Label3D.new()
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.fixed_size = true
	_hp_label.pixel_size = 0.0008
	_hp_label.font_size = 40
	_hp_label.outline_size = 10
	_hp_label.position.y = 2.1
	add_child(_hp_label)
	_update_label()


func is_alive() -> bool:
	return hp > 0.0


func take_damage(amount: float, _from: Node3D = null) -> void:
	if not is_alive():
		return
	hp -= amount
	_flash = 0.12
	var num := Label3D.new()
	num.set_script(DamageNumber)
	num.setup(amount, Color(1, 0.9, 0.6))
	get_parent().add_child(num)
	num.global_position = global_position + Vector3(randf_range(-0.4, 0.4), 2.6, 0)
	if hp <= 0.0:
		hp = 0.0
		_respawn = Config.dummy_respawn
		_model.rotation.x = PI / 2.0   # umfallen
		_model.position.y = 0.3
	_update_label()


func _update_label() -> void:
	_hp_label.text = "Puppe %d" % ceili(hp) if hp > 0.0 else "…"


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		_mat.albedo_color = Color(1, 1, 1) if _flash > 0.0 else Color(0.45, 0.38, 0.28)
	if not is_alive():
		_respawn -= delta
		if _respawn <= 0.0:
			hp = Config.dummy_hp
			_model.rotation.x = 0.0
			_model.position.y = 0.0
			_update_label()
