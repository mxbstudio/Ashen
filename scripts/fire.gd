## Das Feuer: großes warmes Licht. In seiner Nähe füllt sich die Laterne auf.
## Brennt nur, solange die Festung Holz hat. Wenig Holz -> kleinerer Lichtkreis.
## omen = true lässt es unruhig flackern (Vorzeichen einer Belagerung, Etappe 7).
extends Node3D

@export var light_radius := 10.0      # so weit reicht der Lichtkreis
@export var refill_range := 3.5       # so nah muss der Hüter ran, um aufzufüllen

var _light: OmniLight3D
var _flames: Array[MeshInstance3D] = []
var _ring: MeshInstance3D
var _t := 0.0
var omen := false
var _fort: Node


func _ready() -> void:
	light_radius = Config.fire_light_radius
	refill_range = Config.fire_refill_range
	_build()
	Lights.register(self)


func _exit_tree() -> void:
	Lights.unregister(self)


func get_light_radius() -> float:
	if _fort == null:
		return light_radius
	if not _fort.is_fire_burning():
		return 0.0
	# unter 5 Holz schrumpft der Lichtkreis
	return light_radius * lerpf(0.55, 1.0, clampf(_fort.wood / 5.0, 0.0, 1.0))


func can_refill_at(pos: Vector3) -> bool:
	if _fort and not _fort.is_fire_burning():
		return false
	return Vector2(pos.x - global_position.x, pos.z - global_position.z).length() <= refill_range


func _build() -> void:
	# Kollision, damit man nicht durchs Feuer läuft
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.9
	cyl.height = 2.0
	shape.shape = cyl
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)

	# Steinkreis
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.3, 0.28, 0.27)
	for i in 8:
		var stone := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.45, 0.3, 0.35)
		stone.mesh = bm
		stone.material_override = stone_mat
		var a := TAU * i / 8.0
		stone.position = Vector3(cos(a) * 1.0, 0.15, sin(a) * 1.0)
		stone.rotation.y = -a
		add_child(stone)

	# Holzscheite
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.25, 0.15, 0.1)
	for i in 3:
		var wood_log := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.12
		cm.bottom_radius = 0.12
		cm.height = 1.3
		cm.radial_segments = 6
		wood_log.mesh = cm
		wood_log.material_override = wood_mat
		wood_log.rotation = Vector3(PI / 2.0, i * PI / 3.0, 0)
		wood_log.position.y = 0.2
		add_child(wood_log)

	# Flammen: leuchtende Kegel, die tanzen
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(1.0, 0.55, 0.15)
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = Color(1.0, 0.85, 0.4)
	for i in 3:
		var flame := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.35 if i == 0 else 0.22
		cone.height = 1.3 if i == 0 else 0.8
		cone.radial_segments = 6
		flame.mesh = cone
		flame.material_override = flame_mat if i == 0 else core_mat
		flame.position = Vector3((i - 1) * 0.18, 0.2 + cone.height / 2.0, 0)
		add_child(flame)
		_flames.append(flame)

	# Auffüll-Bereich als schwacher Ring am Boden
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = refill_range - 0.06
	torus.outer_radius = refill_range
	torus.rings = 32
	torus.ring_segments = 3
	_ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.albedo_color = Color(1, 0.6, 0.25, 0.35)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring.material_override = ring_mat
	_ring.position.y = 0.03
	_ring.scale.y = 0.1
	add_child(_ring)

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.3)
	_light.omni_range = light_radius * 1.2
	_light.omni_attenuation = 0.7
	_light.light_energy = 2.2
	_light.shadow_enabled = false
	_light.position.y = 2.5
	add_child(_light)


func _process(delta: float) -> void:
	if _fort == null:
		_fort = get_tree().get_first_node_in_group("fortress")
	_t += delta
	var r := get_light_radius()
	if r <= 0.0:
		_light.visible = false
		for f in _flames:
			f.visible = false
		_ring.visible = false
		return
	var flicker := sin(_t * 8.0) * 0.08 + sin(_t * 19.0) * 0.05 + sin(_t * 31.0) * 0.03
	if omen:
		# unruhiges Flackern: Vorzeichen der Belagerung
		flicker += (sin(_t * 5.3) * sin(_t * 13.1)) * 0.45
	var size_k := r / light_radius
	_light.light_energy = 2.2 * (1.0 + flicker) * lerpf(0.6, 1.0, size_k)
	_light.omni_range = r * 1.2 * (1.0 + flicker * 0.3)
	for i in _flames.size():
		var f := _flames[i]
		f.scale = Vector3(size_k, size_k * (1.0 + sin(_t * (9.0 + i * 3.0) + i) * 0.18 + flicker), size_k)
		f.rotation.y += delta * (1.5 + i)
