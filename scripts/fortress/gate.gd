## Das Tor: lässt den Hüter durch, hält Gegner auf. Hat Leben (für Belagerungen in Etappe 7).
extends StaticBody3D

signal broken

var hp := 0.0
var _mat := StandardMaterial3D.new()
var _flash := 0.0
var _doors: Array[MeshInstance3D] = []


func _ready() -> void:
	hp = Config.gate_health
	add_to_group("gate")
	collision_layer = 16           # Ebene 5: nur Gegner stoßen dagegen
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 3.0, 0.6)
	shape.shape = box
	shape.position.y = 1.5
	add_child(shape)
	_mat.albedo_color = Color(0.3, 0.2, 0.12)
	for side in [-1, 1]:
		var d := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.9, 2.8, 0.25)
		d.mesh = bm
		d.material_override = _mat
		d.position = Vector3(side * 1.0, 1.4, 0)
		add_child(d)
		_doors.append(d)


func is_intact() -> bool:
	return hp > 0.0


func take_damage(amount: float) -> void:
	if hp <= 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	_flash = 0.1
	if hp <= 0.0:
		broken.emit()


func repair_full() -> void:
	hp = Config.gate_health


func _process(delta: float) -> void:
	_flash -= delta
	var broken_look := hp <= 0.0
	_mat.albedo_color = Color(1, 0.8, 0.7) if _flash > 0.0 else \
			(Color(0.15, 0.1, 0.07) if broken_look else Color(0.3, 0.2, 0.12))
	for d in _doors:
		d.rotation.x = 1.3 if broken_look else 0.0   # zerbrochen: Türflügel liegen am Boden
		d.position.y = 0.3 if broken_look else 1.4
