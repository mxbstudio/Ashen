## Ein Bewohner: läuft zu seinem Arbeitsplatz oder bummelt ums Feuer.
extends Node3D

var job: Node3D = null             # Gebäude, in dem er arbeitet (oder null)
var _target := Vector3.ZERO
var _wait := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.45, 0.38)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.28
	cm.height = 1.2
	cm.radial_segments = 8
	cm.rings = 2
	body.mesh = cm
	body.material_override = mat
	body.position.y = 0.6
	add_child(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	sm.radial_segments = 8
	sm.rings = 4
	head.mesh = sm
	head.material_override = mat
	head.position.y = 1.35
	add_child(head)
	_pick_target()


func _pick_target() -> void:
	if job:
		_target = job.work_spot() + Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.6, 0.6))
	else:
		var a := _rng.randf() * TAU
		_target = Vector3(cos(a), 0, sin(a)) * _rng.randf_range(2.5, 4.5)
	_wait = _rng.randf_range(2.0, 5.0)


func _process(delta: float) -> void:
	var to := _target - global_position
	to.y = 0
	if to.length() > 0.2:
		global_position += to.normalized() * minf(1.6 * delta, to.length())
		rotation.y = atan2(to.x, to.z)
	else:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()


func assign(building: Node3D) -> void:
	job = building
	_pick_target()
