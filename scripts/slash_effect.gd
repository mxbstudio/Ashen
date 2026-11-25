## Kurz sichtbarer Bogen für den Sichelhieb (fächerförmige Fläche, verblasst schnell).
extends MeshInstance3D

const LIFETIME := 0.18
var _t := 0.0
var _mat: StandardMaterial3D


func setup(radius: float, angle_deg: float, strong: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := deg_to_rad(angle_deg) / 2.0
	var steps := 10
	for i in steps:
		var a0 := -half + (2.0 * half) * i / steps
		var a1 := -half + (2.0 * half) * (i + 1) / steps
		# innerer und äußerer Rand -> Ring-Segment
		var r0 := radius * 0.35
		st.add_vertex(Vector3(sin(a0) * r0, 0, cos(a0) * r0))
		st.add_vertex(Vector3(sin(a0) * radius, 0, cos(a0) * radius))
		st.add_vertex(Vector3(sin(a1) * radius, 0, cos(a1) * radius))
		st.add_vertex(Vector3(sin(a0) * r0, 0, cos(a0) * r0))
		st.add_vertex(Vector3(sin(a1) * radius, 0, cos(a1) * radius))
		st.add_vertex(Vector3(sin(a1) * r0, 0, cos(a1) * r0))
	mesh = st.commit()
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.albedo_color = Color(1, 0.4, 0.2, 0.7) if strong else Color(0.9, 0.85, 0.75, 0.55)
	material_override = _mat


func _process(delta: float) -> void:
	_t += delta
	var k := _t / LIFETIME
	_mat.albedo_color.a = 0.6 * (1.0 - k)
	scale = Vector3.ONE * (0.85 + 0.15 * k)
	if _t >= LIFETIME:
		queue_free()
