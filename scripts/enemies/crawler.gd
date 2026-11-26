## Kriecher: schnell, schwach, im Schwarm. Meidet das Licht:
## lauert am Rand des Laternenlichts, springt dann kurz hinein, beißt und zieht sich zurück.
## In den Lichtkreis des Feuers wagt er sich nicht.
extends EnemyBase

enum State { LURK, ATTACK, RETREAT }

var _state := State.LURK
var _angle := 0.0
var _orbit_dir := 1.0
var _attack_cd := 2.0
var _retreat_t := 0.0


func _build() -> void:
	max_hp = Config.hp_crawler
	speed = Config.crawler_speed
	hit_radius = 0.4
	gate_dps = Config.gate_dps_crawler
	_gate_slot = randf_range(-1.7, 1.7)
	xp = Config.xp_crawler
	hunts_residents = true
	hunt_damage = Config.crawler_damage
	hunt_avoids_light = true
	hunt_interval = 2.5
	_angle = randf() * TAU
	_orbit_dir = 1.0 if randf() < 0.5 else -1.0
	_attack_cd = randf_range(Config.crawler_attack_pause.x, Config.crawler_attack_pause.y)
	var body := SphereMesh.new()
	body.radius = 0.4
	body.height = 0.45
	body.radial_segments = 8
	body.rings = 4
	add_mesh(body, make_mat(Color(0.08, 0.07, 0.08)), Vector3(0, 0.25, 0))
	# Beinchen
	var leg := BoxMesh.new()
	leg.size = Vector3(0.9, 0.05, 0.06)
	var leg_mat := make_mat(Color(0.05, 0.05, 0.05))
	for z in [-0.12, 0.0, 0.12]:
		add_mesh(leg, leg_mat, Vector3(0, 0.12, z))
	add_eyes(0.33, 0.33, 0.1, 0.05)
	add_collision(0.35, 0.5)


func _bar_height() -> float:
	return 0.9


func _think(delta: float) -> Vector3:
	if not player_available():
		return _flee_light(Vector3.ZERO)
	var to_p := flat_to_player()
	var d := to_p.length()
	var player_safe := Lights.fixed_source_at(player.global_position) != null

	match _state:
		State.LURK:
			_angle += delta * 0.5 * _orbit_dir
			var r: float = player.lantern.get_light_radius() + 1.2
			var target: Vector3 = player.global_position + Vector3(cos(_angle), 0, sin(_angle)) * r
			target = _push_out_of_fixed_light(target)
			_attack_cd -= delta
			if _attack_cd <= 0.0 and not player_safe:
				_state = State.ATTACK
			return _flee_light(_arrive(target, speed))
		State.ATTACK:
			if player_safe:
				_state = State.RETREAT
				_retreat_t = 0.6
			elif d < 0.9 + hit_radius:
				hurt_player(Config.crawler_damage)
				_state = State.RETREAT
				_retreat_t = 0.7
			return to_p.normalized() * speed * 1.4
		State.RETREAT:
			_retreat_t -= delta
			if _retreat_t <= 0.0:
				_state = State.LURK
				_attack_cd = randf_range(Config.crawler_attack_pause.x, Config.crawler_attack_pause.y)
			return -to_p.normalized() * speed
	return Vector3.ZERO


## Läuft auf ein Ziel zu und bremst kurz davor ab.
func _arrive(target: Vector3, max_speed: float) -> Vector3:
	var v := target - global_position
	v.y = 0
	var dist := v.length()
	if dist < 0.2:
		return Vector3.ZERO
	return v.normalized() * minf(max_speed, dist * 3.0)


## Liegt das Ziel im Feuerlicht, wird es an dessen Rand geschoben.
func _push_out_of_fixed_light(target: Vector3) -> Vector3:
	var src := Lights.fixed_source_at(target, 1.5)
	if src == null:
		return target
	var dir := target - src.global_position
	dir.y = 0
	if dir.length() < 0.1:
		dir = Vector3(1, 0, 0)
	return src.global_position + dir.normalized() * (src.get_light_radius() + 1.5)


## Steht der Kriecher selbst im Feuerlicht, flieht er hinaus.
func _flee_light(wanted: Vector3) -> Vector3:
	var src := Lights.fixed_source_at(global_position, 0.5)
	if src == null:
		return wanted
	var out := global_position - src.global_position
	out.y = 0
	return out.normalized() * speed
