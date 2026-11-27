## Ladekreis am Boden um den Baum / Felsen / die Pilzstelle, an der der Hüter gerade abbaut.
## Füllt sich, bis die nächste Einheit (Holz, Stein, Nahrung) fertig ist.
## Wird vom Hüter gesteuert: show_at(Ort, 0..1, Farbe) bzw. hide_ring().
extends MeshInstance3D

const WIDTH := 0.16
const SEGMENTS := 40

var _imesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()
var _radius := 1.0
var _last_update := 0              # ms – wird der Ring nicht mehr aktualisiert, blendet er sich aus


func _ready() -> void:
	mesh = _imesh
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = true
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


func show_at(pos: Vector3, frac: float, col: Color, radius := 1.0) -> void:
	visible = true
	_last_update = Time.get_ticks_msec()
	global_position = Vector3(pos.x, 0.06, pos.z)
	_radius = radius
	_imesh.clear_surfaces()
	_arc(1.0, Color(col, 0.2))
	_arc(clampf(frac, 0.0, 1.0), Color(col, 0.9))


func _process(_delta: float) -> void:
	if visible and Time.get_ticks_msec() - _last_update > 150:
		hide_ring()   # z. B. Hüter gestorben, auf dem Turm, Spiel pausiert


func hide_ring() -> void:
	if visible:
		visible = false
		_imesh.clear_surfaces()


## Ringstück von oben (12 Uhr) im Uhrzeigersinn, Anteil frac.
func _arc(frac: float, col: Color) -> void:
	var steps := maxi(2, int(SEGMENTS * frac))
	if frac <= 0.0:
		return
	_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in steps + 1:
		var a := -PI / 2.0 + TAU * frac * float(i) / steps
		var dir := Vector3(cos(a), 0, sin(a))
		_imesh.surface_set_color(col)
		_imesh.surface_add_vertex(dir * (_radius - WIDTH))
		_imesh.surface_set_color(col)
		_imesh.surface_add_vertex(dir * (_radius + WIDTH))
	_imesh.surface_end()
