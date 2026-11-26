## Trugbild (Wahnsinn): etwas, das nicht da ist.
## - "eyes": zwei rote Augen im Dunkeln, blinzeln und verschwinden nach ein paar Sekunden
## - "rush": ein Schatten-Kriecher stürzt auf den Hüter zu und verpufft kurz vor ihm (kein Schaden)
## Gehört NICHT zu den Gegnern: die Skill-Leiste und die Bewohner ignorieren es.
extends Node3D

var kind := "eyes"
var target: Node3D
var _life := 3.0
var _t := 0.0
var _eye_mat := StandardMaterial3D.new()
var _body: MeshInstance3D


func _ready() -> void:
	_eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_eye_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_eye_mat.albedo_color = Color(1, 0.15, 0.1, 0.0)
	var s := SphereMesh.new()
	s.radius = 0.1
	s.height = 0.2
	s.radial_segments = 6
	s.rings = 3
	var h := 0.35 if kind == "rush" else 0.6
	for side in [-1, 1]:
		var e := MeshInstance3D.new()
		e.mesh = s
		e.material_override = _eye_mat
		e.position = Vector3(side * 0.13, h, 0.3)
		add_child(e)
	if kind == "rush":
		_body = MeshInstance3D.new()
		var b := SphereMesh.new()
		b.radius = 0.45
		b.height = 0.5
		b.radial_segments = 8
		b.rings = 4
		_body.mesh = b
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.03, 0.02, 0.04)
		_body.material_override = m
		_body.position.y = 0.25
		add_child(_body)
		_life = 4.0
	else:
		_life = randf_range(2.0, 4.0)


func _process(delta: float) -> void:
	_t += delta
	var a := clampf(_t * 3.0, 0.0, 1.0) * clampf((_life - _t) * 2.0, 0.0, 1.0)
	if kind == "eyes" and fmod(_t, 1.3) < 0.12:
		a = 0.0   # blinzeln
	_eye_mat.albedo_color.a = a
	if kind == "rush" and is_instance_valid(target):
		var to := target.global_position - global_position
		to.y = 0
		if to.length() < 1.5:
			Sfx.play("whisper", -4.0, 0.2)
			queue_free()   # verpufft kurz vor dem Hüter
			return
		global_position += to.normalized() * 7.0 * delta
		rotation.y = atan2(to.x, to.z)
	if _t >= _life:
		queue_free()
