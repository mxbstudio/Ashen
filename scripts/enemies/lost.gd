## Verlorener: langsam, groß, viel Leben. Ignoriert das Licht.
## Holt sichtbar aus (roter Kreis am Boden) und schlägt dann hart zu – rechtzeitig wegdashen!
extends EnemyBase

enum State { WALK, WINDUP, RECOVER }

var _state := State.WALK
var _t := 0.0
var _warn: MeshInstance3D
var _warn_mat: StandardMaterial3D
var _strike_pos := Vector3.ZERO


func _build() -> void:
	max_hp = Config.hp_lost
	speed = Config.lost_speed
	hit_radius = 0.9
	gate_dps = Config.gate_dps_lost
	_gate_slot = randf_range(-1.7, 1.7)
	xp = Config.xp_lost
	hunts_residents = true
	hunt_damage = Config.lost_damage
	hunt_interval = 2.5
	var body := CapsuleMesh.new()
	body.radius = 0.75
	body.height = 2.6
	body.radial_segments = 10
	body.rings = 3
	add_mesh(body, make_mat(Color(0.28, 0.3, 0.26)), Vector3(0, 1.3, 0))
	var arm := CapsuleMesh.new()
	arm.radius = 0.22
	arm.height = 1.8
	var arm_mat := make_mat(Color(0.24, 0.26, 0.22))
	for side in [-1, 1]:
		var a := add_mesh(arm, arm_mat, Vector3(side * 0.85, 1.2, 0.2))
		a.rotation.x = 0.3
	add_eyes(2.2, 0.62, 0.2, 0.07)
	add_collision(0.75, 2.6)
	# Vorwarnung: roter Kreis am Boden, wo der Schlag landet
	_warn = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 24
	_warn.mesh = disc
	_warn_mat = StandardMaterial3D.new()
	_warn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_warn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warn_mat.albedo_color = Color(1, 0.1, 0.05, 0.35)
	_warn.material_override = _warn_mat
	_warn.top_level = true
	_warn.visible = false
	add_child(_warn)


func _bar_height() -> float:
	return 3.1


func _die() -> void:
	_warn.visible = false
	super._die()


func _think(delta: float) -> Vector3:
	if not player_available():
		_warn.visible = false
		_state = State.WALK
		return Vector3.ZERO
	var to_p := flat_to_player()
	var d := to_p.length()
	match _state:
		State.WALK:
			if d < Config.lost_reach:
				_state = State.WINDUP
				_t = Config.lost_windup
				_strike_pos = global_position + to_p.normalized() * minf(d, 1.6)
				_warn.visible = true
			return to_p.normalized() * speed
		State.WINDUP:
			_t -= delta
			var k := 1.0 - _t / Config.lost_windup
			_warn.global_position = _strike_pos + Vector3(0, 0.03, 0)
			_warn.scale = Vector3.ONE * (0.4 + 0.8 * k) * 1.1
			_warn_mat.albedo_color.a = 0.2 + 0.4 * k
			model.rotation.x = -0.25 * k   # holt aus (lehnt sich zurück)
			if _t <= 0.0:
				_warn.visible = false
				model.rotation.x = 0.35       # schlägt zu
				Sfx.play("slam", -6.0)
				var pd := Vector2(player.global_position.x - _strike_pos.x,
						player.global_position.z - _strike_pos.z).length()
				if pd < 1.3:
					hurt_player(Config.lost_damage)
				_state = State.RECOVER
				_t = 0.8
			return Vector3.ZERO
		State.RECOVER:
			_t -= delta
			model.rotation.x = lerpf(model.rotation.x, 0.0, 0.1)
			if _t <= 0.0:
				_state = State.WALK
			return Vector3.ZERO
	return Vector3.ZERO
