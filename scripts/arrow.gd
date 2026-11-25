## Pfeil: fliegt zielsuchend auf einen Gegner und trifft ihn.
extends Node3D

var _target: Node3D
var _damage := 0.0
var _heal := {}
var _burning := false
var burn_dps := 0.0
var _combat: Node
var _dir := Vector3.FORWARD
var _travelled := 0.0


## Pfeil (burning = false) oder Glutwurf (burning = true).
func launch(target: Node3D, damage: float, heal: Dictionary, combat: Node, burning := false) -> void:
	_target = target
	_damage = damage
	_heal = heal
	_combat = combat
	_burning = burning
	var mesh := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if burning:
		var s := SphereMesh.new()
		s.radius = 0.2
		s.height = 0.4
		s.radial_segments = 8
		s.rings = 4
		mesh.mesh = s
		mat.albedo_color = Color(1.0, 0.45, 0.1)
	else:
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 0.06, 0.8)
		mesh.mesh = box
		mat.albedo_color = Color(1.0, 0.85, 0.55) if damage <= Config.bow_damage else Color(1, 0.4, 0.2)
	mesh.material_override = mat
	add_child(mesh)


func _physics_process(delta: float) -> void:
	if is_instance_valid(_target) and _target.is_alive():
		var aim := _target.global_position + Vector3(0, 1.0, 0)
		_dir = (aim - global_position).normalized()
		if global_position.distance_to(aim) < 0.6:
			_combat.hit(_target, _damage, _heal)
			if _burning and is_instance_valid(_target) and _target.is_alive():
				_target.ignite(burn_dps, Config.ember_burn_time)
			queue_free()
			return
	var step := (Config.ember_speed if _burning else Config.arrow_speed) * delta
	global_position += _dir * step
	_travelled += step
	look_at(global_position + _dir, Vector3.UP)
	if _travelled > Config.bow_range * 1.5:
		queue_free()
