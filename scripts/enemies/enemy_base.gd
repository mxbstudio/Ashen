## Grundlage für alle Gegner: Leben, Schaden nehmen/austeilen, Rückstoß, Sterben.
## Die einzelnen Gegnerarten (Kriecher, Lichtfresser, Verlorener) bauen darauf auf
## und entscheiden in _think(), wohin sie wollen.
class_name EnemyBase
extends CharacterBody3D

signal died(enemy: EnemyBase)

const DamageNumber := preload("res://scripts/damage_number.gd")
const HpBar := preload("res://scripts/hp_bar.gd")

var player: Node3D                 # wird vom Spawner gesetzt
var max_hp := 10.0
var hp := 10.0
var speed := 3.0
var hit_radius := 0.5              # Körperradius (für Treffer)
var xp := 1
var model: Node3D                  # dreht sich in Laufrichtung

var _knock := Vector3.ZERO
var _flash := 0.0
var _dying := -1.0
var _mats: Array[StandardMaterial3D] = []
var _base_colors: Array[Color] = []
var _eye_mats: Array[StandardMaterial3D] = []
var _hp_bar: Node3D
var _burn_time := 0.0
var _burn_dps := 0.0
var _burn_tick := 0.0


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4            # Ebene 3: Gegner
	collision_mask = 1 | 4         # stoßen an Welt und aneinander, nicht am Hüter
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	model = Node3D.new()
	add_child(model)
	_build()
	hp = max_hp
	_hp_bar = Node3D.new()
	_hp_bar.set_script(HpBar)
	add_child(_hp_bar)
	_hp_bar.setup(clampf(hit_radius * 1.6, 0.7, 2.0))
	_hp_bar.position.y = _bar_height()


## Von Unterklassen überschrieben: Aussehen bauen (Meshes in `model`, Kollisionsform).
func _build() -> void:
	pass


## Von Unterklassen überschrieben: gewünschte Bewegung (Geschwindigkeit) zurückgeben.
func _think(_delta: float) -> Vector3:
	return Vector3.ZERO


func _bar_height() -> float:
	return 1.6


func is_alive() -> bool:
	return hp > 0.0 and _dying < 0.0


func take_damage(amount: float, _from: Node3D = null) -> void:
	if not is_alive():
		return
	hp -= amount
	_flash = 0.1
	var num := Label3D.new()
	num.set_script(DamageNumber)
	num.setup(amount, Color(1, 0.9, 0.6))
	get_parent().add_child(num)
	num.global_position = global_position + Vector3(randf_range(-0.3, 0.3), _bar_height() + 0.4, 0)
	_hp_bar.set_fraction(hp / max_hp)
	if hp <= 0.0:
		_die()


## In Brand setzen (Glutwurf): Schaden über Zeit.
func ignite(dps: float, duration: float) -> void:
	_burn_dps = maxf(_burn_dps, dps)
	_burn_time = maxf(_burn_time, duration)


func knockback(impulse: Vector3) -> void:
	_knock += impulse


func _die() -> void:
	_dying = 0.35
	remove_from_group("enemies")
	collision_layer = 0
	collision_mask = 0
	_hp_bar.visible = false
	if player and player.has_method("gain_xp"):
		player.gain_xp(xp)
	died.emit(self)


## Steht dieser Gegner gerade im Dunkeln? Dann teilt er mehr Schaden aus.
func in_darkness() -> bool:
	return not Lights.is_lit(global_position)


## Schaden am Hüter – im Dunkeln um den Dunkelheits-Bonus erhöht.
func hurt_player(base_damage: float) -> void:
	var amount := base_damage
	if in_darkness():
		amount *= 1.0 + Config.dark_damage_bonus
	player.take_damage(amount, self)


func flat_to_player() -> Vector3:
	var v := player.global_position - global_position
	v.y = 0
	return v


func player_available() -> bool:
	return is_instance_valid(player) and player.is_alive()


func _physics_process(delta: float) -> void:
	if _dying >= 0.0:
		_dying -= delta
		model.scale = Vector3.ONE * maxf(_dying / 0.35, 0.01)
		if _dying <= 0.0:
			queue_free()
		return
	if _burn_time > 0.0:
		_burn_time -= delta
		_burn_tick += delta
		if _burn_tick >= 0.5:
			_burn_tick = 0.0
			take_damage(_burn_dps * 0.5)
			if not is_alive():
				return
	var desired := _think(delta)
	velocity = desired + _knock
	_knock = _knock.move_toward(Vector3.ZERO, 25.0 * delta)
	move_and_slide()
	global_position.y = 0.0
	if desired.length() > 0.2:
		var a := atan2(desired.x, desired.z)
		model.rotation.y = lerp_angle(model.rotation.y, a, 1.0 - exp(-12.0 * delta))
	_update_visuals(delta)


func _update_visuals(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
	var white := _flash > 0.0
	var burn := _burn_time > 0.0
	for i in _mats.size():
		if white:
			_mats[i].albedo_color = Color.WHITE
		elif burn:
			_mats[i].albedo_color = _base_colors[i].lerp(Color(1, 0.4, 0.05), 0.5 + 0.2 * sin(_burn_time * 20.0))
		else:
			_mats[i].albedo_color = _base_colors[i]
	# Augen: im Dunkeln grell rot (= stärker), im Licht matter
	var dark := in_darkness()
	for m in _eye_mats:
		m.albedo_color = Color(1.0, 0.15, 0.1) if dark else Color(0.7, 0.35, 0.2)


# --- Hilfen zum Bauen ------------------------------------------------------

func make_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	_mats.append(m)
	_base_colors.append(col)
	return m


func add_mesh(mesh: Mesh, mat: Material, pos: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	(parent if parent else model).add_child(mi)
	return mi


func add_eyes(height: float, forward: float, spread: float, size: float) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 0.2, 0.1)
	_eye_mats.append(m)
	var s := SphereMesh.new()
	s.radius = size
	s.height = size * 2.0
	s.radial_segments = 6
	s.rings = 3
	for side in [-1, 1]:
		add_mesh(s, m, Vector3(side * spread, height, forward))


func add_collision(radius: float, height: float) -> void:
	var shape := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = radius
	c.height = height
	shape.shape = c
	shape.position.y = height / 2.0
	add_child(shape)
