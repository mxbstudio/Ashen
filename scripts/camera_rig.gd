## Isometrische Kamera: orthografisch, schräg von oben (45° gedreht, ~35° geneigt).
## Folgt sanft dem Ziel (dem Hüter).
extends Node3D

@export var target: Node3D

const PITCH_DEG := -35.264   # klassischer Iso-Winkel
const YAW_DEG := 45.0
const DISTANCE := 40.0

var camera: Camera3D


func _ready() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_update_size()
	camera.near = 1.0
	camera.far = 100.0
	camera.rotation_degrees = Vector3(PITCH_DEG, YAW_DEG, 0)
	# Kamera entlang ihrer Blickrichtung nach hinten versetzen
	camera.position = camera.transform.basis.z * DISTANCE
	add_child(camera)
	camera.current = true
	if target:
		global_position = target.global_position


var _tower_k := 0.0                # 0 = normal, 1 = Hüter auf dem Turm (Kamera schaut nach draußen)


func _process(delta: float) -> void:
	var on_tower: bool = target != null and "on_tower" in target and target.on_tower != null
	_tower_k = move_toward(_tower_k, 1.0 if on_tower else 0.0, delta * 3.0)
	_update_size()
	if target:
		# auf dem Turm: Blick über die Mauer nach Norden (Turmhöhe ausgleichen)
		var goal: Vector3 = target.global_position + Vector3(0, -target.global_position.y, -7.0 * _tower_k)
		if Config.camera_follow <= 0.0:
			global_position = goal
		else:
			var w := 1.0 - exp(-Config.camera_follow * delta)
			global_position = global_position.lerp(goal, w)


## Hochformat: feste Breite in Metern. Querformat (z. B. PC): gleiche Zahl als Höhe.
func _update_size() -> void:
	var vp := get_viewport().get_visible_rect().size
	if vp.y >= vp.x:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = Config.camera_width + 5.0 * _tower_k   # auf dem Turm etwas weiter herauszoomen


## Wandelt eine Bildschirm-Richtung (x rechts, y unten) in eine Bodenrichtung um.
func screen_to_ground(dir: Vector2) -> Vector3:
	var right := camera.global_transform.basis.x
	var up := -camera.global_transform.basis.z   # Blickrichtung
	right.y = 0
	up.y = 0
	return (right.normalized() * dir.x - up.normalized() * dir.y)
