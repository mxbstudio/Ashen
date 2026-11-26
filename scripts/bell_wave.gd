## Sichtbare Schockwelle des Glockenschlags: ein Ring, der sich ausdehnt und verblasst.
extends MeshInstance3D

const LIFETIME := 0.35
var _t := 0.0
var _radius := 4.0
var _mat := StandardMaterial3D.new()


func setup(radius: float, strong: bool) -> void:
	_radius = radius
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	torus.rings = 32
	torus.ring_segments = 4
	mesh = torus
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(1, 0.45, 0.2, 0.8) if strong else Color(0.95, 0.85, 0.55, 0.8)
	material_override = _mat
	scale = Vector3(0.3, 0.3, 0.3)


func _process(delta: float) -> void:
	_t += delta
	var k := _t / LIFETIME
	var s := lerpf(0.3, _radius, sqrt(k))
	scale = Vector3(s, 0.4, s)
	_mat.albedo_color.a = 0.8 * (1.0 - k)
	if _t >= LIFETIME:
		queue_free()
