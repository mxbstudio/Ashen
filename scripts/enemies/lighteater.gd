## Lichtfresser: greift nicht den Hüter an, sondern saugt an der Laterne.
## Wird vom Licht angezogen. Während er saugt, sieht man einen hellen Faden zur Laterne.
extends EnemyBase

var _sucking := false
var _beam: MeshInstance3D
var _beam_mat: StandardMaterial3D
var _t := 0.0
var _wings: Array[MeshInstance3D] = []


func _build() -> void:
	max_hp = Config.hp_lighteater
	speed = Config.lighteater_speed
	hit_radius = 0.5
	xp = Config.xp_lighteater
	_t = randf() * 10.0
	var body := SphereMesh.new()
	body.radius = 0.3
	body.height = 0.9
	body.radial_segments = 8
	body.rings = 4
	var pale := make_mat(Color(0.55, 0.58, 0.68))
	var b := add_mesh(body, pale, Vector3(0, 1.3, 0))
	b.rotation.x = PI / 2.0
	var wing := BoxMesh.new()
	wing.size = Vector3(0.9, 0.03, 0.5)
	var wing_mat := make_mat(Color(0.4, 0.42, 0.5))
	for side in [-1, 1]:
		var w := add_mesh(wing, wing_mat, Vector3(side * 0.5, 1.4, 0))
		_wings.append(w)
	add_eyes(1.45, 0.38, 0.1, 0.06)
	add_collision(0.4, 1.6)
	# Saug-Faden zur Laterne
	_beam = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.04
	cyl.bottom_radius = 0.04
	cyl.height = 1.0
	cyl.radial_segments = 4
	_beam.mesh = cyl
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.albedo_color = Color(1, 0.85, 0.5, 0.6)
	_beam.material_override = _beam_mat
	_beam.top_level = true
	_beam.visible = false
	add_child(_beam)


func _bar_height() -> float:
	return 2.0


func _think(delta: float) -> Vector3:
	_t += delta
	# Flügelschlag
	for i in _wings.size():
		_wings[i].rotation.z = sin(_t * 14.0) * 0.5 * (1 if i == 0 else -1)
	model.position.y = sin(_t * 3.0) * 0.12
	if not player_available():
		_set_sucking(false)
		return Vector3.ZERO
	var to_p := flat_to_player()
	var d := to_p.length()
	if d > 1.8:
		_set_sucking(false)
		return to_p.normalized() * speed
	# nah genug: saugen und leicht um den Hüter kreisen
	_set_sucking(player.lantern.fuel > 0.0)
	if _sucking:
		player.lantern.drain(Config.lighteater_drain * delta)
		_update_beam()
	return to_p.normalized().cross(Vector3.UP) * 0.8


func _set_sucking(on: bool) -> void:
	_sucking = on
	_beam.visible = on


func _update_beam() -> void:
	var a := global_position + Vector3(0, 1.3 + model.position.y, 0)
	var b: Vector3 = player.lantern.global_position + Vector3(0.35, 1.0, 0.25).rotated(Vector3.UP, player.model.rotation.y)
	var mid := (a + b) / 2.0
	var len := a.distance_to(b)
	# Zylinder zeigt entlang Y -> auf die Verbindungslinie ausrichten und strecken
	var up := (b - a).normalized()
	var helper := Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var side := up.cross(helper).normalized()
	var fwd := side.cross(up)
	_beam.global_transform = Transform3D(Basis(side, up * len, fwd), mid)
	_beam_mat.albedo_color.a = 0.4 + 0.3 * sin(_t * 20.0)
