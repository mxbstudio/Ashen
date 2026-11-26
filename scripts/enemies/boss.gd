## Boss: der verwandelte Hauptmann. Groß, langsam, viel Leben.
## - Nahkampfschlag mit kurzer Vorwarnung
## - Flächenangriff: roter Kreis an der Stelle des Hüters, nach 1,4 s schlägt es dort ein
## Wartet in seiner Arena. Entfernt sich der Hüter zu weit (oder stirbt), kehrt er zurück und heilt.
extends EnemyBase

signal defeated

enum State { IDLE, CHASE, MELEE, AREA, RECOVER }

var home := Vector3.ZERO
var _state := State.IDLE
var _t := 0.0
var _area_cd := 3.0
var _warn: MeshInstance3D
var _warn_mat: StandardMaterial3D
var _strike_pos := Vector3.ZERO
var _strike_radius := 1.0
var _strike_damage := 0.0
var _windup := 1.0


func _build() -> void:
	max_hp = Config.hp_boss
	speed = Config.boss_speed
	hit_radius = 1.3
	xp = Config.xp_boss
	add_to_group("boss")
	var armor := make_mat(Color(0.22, 0.22, 0.25))
	var flesh := make_mat(Color(0.3, 0.22, 0.24))
	var body := CapsuleMesh.new()
	body.radius = 1.2
	body.height = 3.6
	body.radial_segments = 10
	body.rings = 3
	add_mesh(body, armor, Vector3(0, 1.8, 0))
	# Schulterplatten
	var plate := BoxMesh.new()
	plate.size = Vector3(1.0, 0.4, 1.2)
	for side in [-1, 1]:
		add_mesh(plate, armor, Vector3(side * 1.35, 3.1, 0))
	# Arme, einer davon zu einer Klinge verwachsen
	var arm := CapsuleMesh.new()
	arm.radius = 0.35
	arm.height = 2.6
	add_mesh(arm, flesh, Vector3(-1.5, 1.8, 0.3))
	var blade := BoxMesh.new()
	blade.size = Vector3(0.15, 3.0, 0.5)
	var b := add_mesh(blade, make_mat(Color(0.4, 0.38, 0.36)), Vector3(1.6, 1.6, 0.8))
	b.rotation.x = 0.5
	# Helm mit Federbusch-Stumpf
	var helm := SphereMesh.new()
	helm.radius = 0.55
	helm.height = 1.0
	add_mesh(helm, armor, Vector3(0, 3.9, 0.1))
	add_eyes(3.95, 0.5, 0.2, 0.09)
	add_collision(1.2, 3.6)
	_warn = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 32
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
	return 4.8


func is_engaged() -> bool:
	return _state != State.IDLE and is_alive()


func _die() -> void:
	_warn.visible = false
	super._die()
	defeated.emit()


func _think(delta: float) -> Vector3:
	var to_home := home - global_position
	to_home.y = 0
	var have_player := player_available()
	var to_p := flat_to_player() if have_player else Vector3.ZERO
	var d := to_p.length()
	# Leine: zu weit weg oder Hüter tot -> zurück und heilen
	if not have_player or (player.global_position - home).length() > Config.boss_leash:
		_warn.visible = false
		_state = State.IDLE
		if to_home.length() > 0.5:
			return to_home.normalized() * speed * 1.5
		hp = minf(hp + max_hp * 0.2 * delta, max_hp)
		_hp_bar.set_fraction(hp / max_hp)
		return Vector3.ZERO

	match _state:
		State.IDLE:
			if d < Config.boss_aggro_range:
				_state = State.CHASE
				get_tree().call_group("hud", "toast", "Der verwandelte Hauptmann erhebt sich!")
			return Vector3.ZERO
		State.CHASE:
			_area_cd -= delta
			if _area_cd <= 0.0:
				_area_cd = Config.boss_area_interval
				_begin_strike(player.global_position, Config.boss_area_radius,
						Config.boss_area_damage, Config.boss_area_windup)
				_state = State.AREA
				return Vector3.ZERO
			if d < Config.boss_melee_reach:
				_begin_strike(global_position + to_p.normalized() * 2.0, 2.0,
						Config.boss_melee_damage, Config.boss_melee_windup)
				_state = State.MELEE
				return Vector3.ZERO
			return to_p.normalized() * speed
		State.MELEE, State.AREA:
			_t -= delta
			var k := 1.0 - _t / _windup
			_warn.global_position = _strike_pos + Vector3(0, 0.04, 0)
			_warn.scale = Vector3(_strike_radius, 1, _strike_radius) * (0.3 + 0.7 * k)
			_warn_mat.albedo_color.a = 0.2 + 0.45 * k
			model.rotation.x = -0.2 * k
			if _t <= 0.0:
				_strike()
				_state = State.RECOVER
				_t = 0.9
			return Vector3.ZERO
		State.RECOVER:
			_t -= delta
			model.rotation.x = lerpf(model.rotation.x, 0.0, 0.1)
			if _t <= 0.0:
				_state = State.CHASE
			return Vector3.ZERO
	return Vector3.ZERO


func _begin_strike(pos: Vector3, radius: float, damage: float, windup: float) -> void:
	_strike_pos = Vector3(pos.x, 0, pos.z)
	_strike_radius = radius
	_strike_damage = damage
	_windup = windup
	_t = windup
	_warn.visible = true


func _strike() -> void:
	_warn.visible = false
	Sfx.play("slam", 2.0)
	model.rotation.x = 0.35
	var pd := Vector2(player.global_position.x - _strike_pos.x, player.global_position.z - _strike_pos.z).length()
	if pd < _strike_radius:
		hurt_player(_strike_damage)
