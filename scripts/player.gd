## Der Hüter: läuft, dasht, trägt die Laterne und kämpft über die Skill-Leiste.
extends CharacterBody3D

signal dashed
signal died
signal respawned

@export var camera_rig: Node3D
@export var respawn_point: Node3D      # das Feuer – hier erscheint er nach dem Tod

@onready var model: Node3D = $Model
@onready var lantern: Node3D = $Model/Lantern
@onready var combat: Node = $Combat
@onready var skill_bar: Node = $SkillBar

var facing := Vector3(0, 0, 1)     # Blickrichtung auf dem Boden
var _dash_time := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector3.ZERO

var health := 0.0
var potions := 0
var xp := 0
var hurt_flash := 0.0              # für die rote Anzeige am Bildschirmrand
var dead_timer := 0.0              # > 0 solange er tot ist
var protect_timer := 0.0           # > 0: unverwundbar (nach dem Wiedererscheinen)


func _ready() -> void:
	health = Config.player_max_health
	potions = Config.potions_start
	collision_layer = 2            # Ebene 2: Hüter (Gegner laufen nicht gegen ihn)
	collision_mask = 1             # stößt nur an die Welt


func is_alive() -> bool:
	return dead_timer <= 0.0


func is_dashing() -> bool:
	return _dash_time > 0.0


func take_damage(amount: float, _from: Node3D = null) -> void:
	if not is_alive() or is_dashing() or protect_timer > 0.0:
		return   # während des Dashs und kurz nach dem Wiedererscheinen unverwundbar
	if _from:
		DebugOverlay.watch("Letzter Treffer", "%s (%d)" % [_from.get_script().resource_path.get_file().get_basename(), int(amount)])
	health -= amount
	hurt_flash = 0.35
	_spawn_number(amount, Color(1, 0.3, 0.25))
	if health <= 0.0:
		_die()


func heal(amount: float) -> void:
	if not is_alive():
		return
	health = minf(health + amount, Config.player_max_health)


func gain_xp(amount: int) -> void:
	xp += amount


func drink_potion() -> void:
	if not is_alive() or potions <= 0 or health >= Config.player_max_health:
		return
	potions -= 1
	heal(Config.potion_heal)
	_spawn_number(Config.potion_heal, Color(0.4, 1, 0.5), "+")


func _spawn_number(amount: float, col: Color, prefix := "") -> void:
	var num := Label3D.new()
	num.set_script(preload("res://scripts/damage_number.gd"))
	num.setup(amount, col)
	num.text = prefix + num.text
	get_parent().add_child(num)
	num.global_position = global_position + Vector3(0, 2.4, 0)


func _die() -> void:
	health = 0.0
	dead_timer = Config.respawn_delay
	model.visible = false
	skill_bar.interrupt()
	died.emit()


func _respawn() -> void:
	health = Config.player_max_health
	potions = Config.potions_start
	lantern.fuel = Config.lantern_burn_time
	model.visible = true
	protect_timer = Config.respawn_protection
	if respawn_point:
		global_position = respawn_point.global_position + Vector3(0, 0, 2.5)
	respawned.emit()


func _physics_process(delta: float) -> void:
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	hurt_flash = maxf(hurt_flash - delta, 0.0)
	if protect_timer > 0.0:
		protect_timer -= delta
		model.visible = fmod(protect_timer, 0.2) > 0.1 or protect_timer <= 0.0   # blinkt
	if not is_alive():
		dead_timer -= delta
		if dead_timer <= 0.0:
			_respawn()
		return

	# Am Feuer: langsam heilen, Tränke auffüllen
	if Lights.refill_source_at(global_position) != null:
		heal(Config.fire_heal_per_second * delta)
		if Config.potions_refill_at_fire:
			potions = Config.potions_start
	if Input.is_action_just_pressed("potion"):
		drink_potion()

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move := Vector3.ZERO
	if input.length() > 0.05 and camera_rig:
		move = camera_rig.screen_to_ground(input)
		if move.length() > 1.0 or not Config.joystick_analog:
			move = move.normalized()
		facing = move.normalized()
	elif _dash_time <= 0.0:
		face_nearest_enemy()   # steht er still, schaut er zum nächsten Gegner

	if Input.is_action_just_pressed("dash"):
		try_dash()

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_dir * Config.dash_speed
	else:
		velocity = move * Config.player_speed

	move_and_slide()
	global_position.y = 0.0

	# Figur in Blickrichtung drehen
	var target_angle := atan2(facing.x, facing.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_angle, 1.0 - exp(-40.0 * delta))
	# kleiner Effekt: beim Dash flacher/länger
	var s := 1.0 if _dash_time <= 0.0 else 0.8
	model.scale = model.scale.lerp(Vector3(1, s, 1), 0.4)

	DebugOverlay.watch("Pos", "%.1f / %.1f" % [global_position.x, global_position.z])
	DebugOverlay.watch("EP", xp)


func try_dash() -> void:
	if _dash_cd > 0.0 or _dash_time > 0.0:
		return
	_dash_dir = facing
	skill_bar.interrupt()   # Dash unterbricht den aktuellen Cast
	_dash_time = Config.dash_duration
	_dash_cd = Config.dash_cooldown
	dashed.emit()


## Dreht den Hüter zum nächsten Gegner, falls einer in Kampfreichweite ist.
func face_nearest_enemy() -> void:
	var e: Node3D = combat.nearest_enemy(Config.combat_range)
	if e:
		var to := e.global_position - global_position
		to.y = 0
		if to.length() > 0.1:
			facing = to.normalized()
