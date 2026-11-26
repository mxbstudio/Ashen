## Kleiner Lebensbalken über Gegnern (nur sichtbar, wenn sie verletzt sind).
extends Node3D

const W := 1.0
const H := 0.12
var _fill: MeshInstance3D
var _bg: MeshInstance3D
var _cam_right := Vector3(0.7071, 0, -0.7071)   # Iso-Kamera: "rechts" auf dem Bildschirm


func setup(width_scale: float) -> void:
	scale = Vector3.ONE * width_scale
	_bg = _quad(Color(0, 0, 0, 0.7), W + 0.06, H + 0.06)
	_fill = _quad(Color(0.85, 0.2, 0.15), W, H)
	_fill.sorting_offset = 1.0
	visible = false


func _quad(col: Color, w: float, h: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.no_depth_test = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	mat.render_priority = 1 if col.a >= 1.0 else 0
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	return m


func set_fraction(f: float) -> void:
	visible = f < 0.999 and f > 0.0
	f = clampf(f, 0.0, 1.0)
	_fill.scale = Vector3(maxf(f, 0.001), 1, 1)
	# links ausrichten: Füllung nach links schieben (in Bildschirm-Richtung)
	_fill.position = _cam_right * (-(1.0 - f) * W / 2.0)
