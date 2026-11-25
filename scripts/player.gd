## Der Hüter: läuft, dasht, trägt die Laterne und kämpft über die Skill-Leiste.
extends CharacterBody3D

signal dashed

@export var camera_rig: Node3D

@onready var model: Node3D = $Model
@onready var lantern: Node3D = $Model/Lantern
@onready var combat: Node = $Combat
@onready var skill_bar: Node = $SkillBar

var facing := Vector3(0, 0, 1)     # Blickrichtung auf dem Boden
var _dash_time := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector3.ZERO


func _physics_process(delta: float) -> void:
	_dash_cd = maxf(_dash_cd - delta, 0.0)

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
	DebugOverlay.watch("Dash bereit", "ja" if _dash_cd <= 0.0 else "%.1fs" % _dash_cd)


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
