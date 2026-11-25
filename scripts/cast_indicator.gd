## Ring am Boden um den Hüter: füllt sich während des Ausholens (Cast).
## Ist er voll, wird der Skill ausgelöst – der Ring "platzt" dann sichtbar auf.
extends MeshInstance3D

const RADIUS := 0.95
const WIDTH := 0.14
const SEGMENTS := 40

var _imesh := ImmediateMesh.new()
var _mat := StandardMaterial3D.new()
var _burst := 0.0          # Restzeit des Aufplatz-Effekts
var _burst_color := Color.WHITE
var bar: Node


func _ready() -> void:
	mesh = _imesh
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat.vertex_color_use_as_albedo = true
	material_override = _mat
	position.y = 0.04
	bar = get_parent().get_node("SkillBar")
	bar.skill_fired.connect(_on_fired)


func _on_fired(id: String, _slot: int) -> void:
	_burst = 0.25
	_burst_color = SkillData.color(id)


func _process(delta: float) -> void:
	_imesh.clear_surfaces()
	var drew := false
	if bar.running and bar.slots[bar.index] != "":
		var col := SkillData.color(bar.slots[bar.index])
		# schwacher Vollkreis als Hintergrund
		_arc(RADIUS, WIDTH * 0.5, 1.0, Color(col, 0.15))
		# gefüllter Anteil
		_arc(RADIUS, WIDTH, bar.fraction(), Color(col, 0.85))
		drew = true
	if _burst > 0.0:
		_burst -= delta
		var k := 1.0 - _burst / 0.25
		_arc(RADIUS + k * 0.9, WIDTH * (1.0 - k) + 0.03, 1.0, Color(_burst_color.lightened(0.4), 1.0 - k))
		drew = true
	visible = drew


## Zeichnet einen Ringbogen (Anteil 0..1 eines Vollkreises), beginnend oben.
func _arc(r: float, w: float, frac: float, col: Color) -> void:
	if frac <= 0.0:
		return
	var n := maxi(2, int(SEGMENTS * frac))
	_imesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in n + 1:
		var a := PI + TAU * frac * float(i) / float(n)
		var dir := Vector3(sin(a), 0, cos(a))
		_imesh.surface_set_color(col)
		_imesh.surface_add_vertex(dir * (r - w / 2.0))
		_imesh.surface_set_color(col)
		_imesh.surface_add_vertex(dir * (r + w / 2.0))
	_imesh.surface_end()
