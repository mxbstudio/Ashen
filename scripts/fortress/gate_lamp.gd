## Torfeuer: zwei Feuerschalen draußen vor dem Tor. Sie erhellen den Platz vor dem Tor,
## damit Bewohner beim Hinausgehen nicht direkt in ein Kriecher-Rudel laufen.
## Brennt, solange das Hauptfeuer der Festung brennt. Füllt die Laterne nicht auf.
extends Node3D

var _light: OmniLight3D
var _flames: Array[MeshInstance3D] = []
var _fort: Node
var _t := 0.0


func _ready() -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.33, 0.31, 0.29)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1, 0.6, 0.2)
	for side in [-1, 1]:
		var bowl := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.4
		cm.bottom_radius = 0.2
		cm.height = 0.9
		cm.radial_segments = 6
		bowl.mesh = cm
		bowl.material_override = stone
		bowl.position = Vector3(side * 3.2, 0.45, 0)
		add_child(bowl)
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.3
		cone.height = 0.7
		cone.radial_segments = 6
		flame.mesh = cone
		flame.material_override = fm
		flame.position = Vector3(side * 3.2, 1.25, 0)
		add_child(flame)
		_flames.append(flame)
	_light = OmniLight3D.new()
	_light.light_color = Color(1, 0.62, 0.32)
	_light.omni_attenuation = 0.7
	_light.shadow_enabled = false
	_light.position.y = 2.5
	add_child(_light)
	Lights.register(self)


func _exit_tree() -> void:
	Lights.unregister(self)


func get_light_radius() -> float:
	if _fort and not _fort.is_fire_burning():
		return 0.0
	return Config.gate_light_radius


## Feste Lichtquelle (Kriecher meiden sie), füllt aber die Laterne nicht auf.
func can_refill_at(_pos: Vector3) -> bool:
	return false


func _process(delta: float) -> void:
	if _fort == null:
		_fort = get_tree().get_first_node_in_group("fortress")
	_t += delta
	var r := get_light_radius()
	_light.visible = r > 0.0
	for f in _flames:
		f.visible = r > 0.0
	if r > 0.0:
		var flick := sin(_t * 9.0) * 0.08 + sin(_t * 17.0) * 0.05
		_light.omni_range = r * 1.25
		_light.light_energy = 1.5 * (1.0 + flick)
		for f in _flames:
			f.scale.y = 1.0 + flick * 2.0
