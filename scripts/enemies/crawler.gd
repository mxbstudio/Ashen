## Kriecher: schnell, schwach, im Schwarm. Lichtscheu, aber nicht lichtdicht:
## lauert am Rand des Laternenlichts und schleicht sich HINTER den Hüter, springt dann hinein, beißt
## und zieht sich zurück. Licht ist ihnen unangenehm (sie verweilen nicht darin und laufen dort langsamer),
## aber sie laufen hindurch und greifen manchmal auch im Licht von Fackeln und Feuerstellen an.
## Hinter die Mauer zum Feuer der Festung kommen sie nicht.
extends EnemyBase

enum State { LURK, ATTACK, RETREAT }

var _state := State.LURK
var _angle := 0.0
var _orbit_dir := 1.0
var _attack_cd := 2.0
var _retreat_t := 0.0
var _slot_offset := 0.0           # jeder Kriecher lauert etwas versetzt hinter dem Hüter
var _roam_target := Vector3.INF
var _roam_t := 0.0


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
	_slot_offset = randf_range(-0.7, 0.7)
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
		return _shy(Vector3.ZERO)
	var to_p := flat_to_player()
	var d := to_p.length()
	var in_fort: bool = player.global_position.z > -12.0     # am Feuer der Festung: unerreichbar
	var player_lit := Lights.fixed_source_at(player.global_position) != null   # Fackel, Feuerstelle …

	match _state:
		State.LURK:
			if in_fort and d > 8.0:
				return _shy(_roam(delta))   # Hüter sitzt sicher in der Festung: durch den Wald streifen
			# auf dem Kreis um den Hüter langsam nach hinten wandern (jeder etwas versetzt)
			var behind := atan2(-player.facing.z, -player.facing.x) + _slot_offset
			_angle = lerp_angle(_angle, behind, 1.0 - exp(-1.6 * delta))
			var r: float = player.lantern.get_light_radius() + 1.2
			var target: Vector3 = player.global_position + Vector3(cos(_angle), 0, sin(_angle)) * r
			target = _push_out_of_fixed_light(target)   # lauern lieber am Rand des Lichts
			_attack_cd -= delta
			if _attack_cd <= 0.0 and not in_fort:
				var me := -to_p   # vom Hüter zu mir
				var behind_now := absf(angle_difference(atan2(me.z, me.x), behind - _slot_offset)) < 1.0
				# im Licht einer Fackel trauen sie sich seltener – aber sie trauen sich
				var brave := not player_lit or randf() < Config.crawler_light_courage
				if brave and (behind_now or _attack_cd < -8.0):
					_state = State.ATTACK
				elif not brave:
					_attack_cd = randf_range(0.8, 1.6)
			return _shy(_arrive(target, speed))
		State.ATTACK:
			if in_fort:
				_state = State.RETREAT
				_retreat_t = 0.6
			elif d < 0.9 + hit_radius:
				hurt_player(Config.crawler_damage)
				_state = State.RETREAT
				_retreat_t = 0.7
			# von hinten anspringen: auf einen Punkt knapp hinter dem Hüter zielen
			var aim: Vector3 = player.global_position - player.facing * minf(d * 0.5, 1.2)
			if to_p.dot(player.facing) < -0.3 and d > 2.0:
				# ich bin vor ihm: seitlich herum statt frontal
				var side: Vector3 = player.facing.cross(Vector3.UP) * (1.0 if _orbit_dir > 0 else -1.0)
				aim = player.global_position + side * 2.0 - player.facing * 1.0
			var v := aim - global_position
			v.y = 0
			return v.normalized() * speed * 1.4 * _light_slow()
		State.RETREAT:
			_retreat_t -= delta
			if _retreat_t <= 0.0:
				_state = State.LURK
				_attack_cd = randf_range(Config.crawler_attack_pause.x, Config.crawler_attack_pause.y)
			return -to_p.normalized() * speed
	return Vector3.ZERO


## Im Licht einer festen Quelle laufen sie langsamer.
func _light_slow() -> float:
	return 0.75 if Lights.fixed_source_at(global_position) != null else 1.0


## Lichtscheu: wer beim Lauern/Streifen im Licht steht, zieht es sanft hinaus – kein hartes Wegstoßen.
func _shy(wanted: Vector3) -> Vector3:
	var src := Lights.fixed_source_at(global_position)
	if src == null:
		return wanted
	var out := global_position - src.global_position
	out.y = 0
	var v := wanted + out.normalized() * speed * 0.5
	return v.limit_length(speed) * _light_slow()


## Ziellos durch den Wald streifen (statt vor der Mauer zu lauern).
func _roam(delta: float) -> Vector3:
	_roam_t -= delta
	if _roam_t <= 0.0 or _roam_target == Vector3.INF:
		_roam_t = randf_range(4.0, 7.0)
		var p := global_position + Vector3(randf_range(-10, 10), 0, randf_range(-12, 4))
		p.x = clampf(p.x, -27.0, 27.0)
		p.z = clampf(p.z, -88.0, -20.0)
		_roam_target = _push_out_of_fixed_light(p)
	return _arrive(_roam_target, speed * 0.5)


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
