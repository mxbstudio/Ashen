## Fackelpfahl: macht eine Zone draußen hell.
## Ablauf: leerer Platz -> Hüter errichtet ihn (kostet Holz) -> brennt mit eigenem Brennstoff.
## Holz nachlegen verlängert die Brenndauer. Lichtfresser können ihn leer saugen -> erlischt.
## Brennt er, meiden Kriecher die Zone (über Lights.fixed_source_at, wie beim Feuer).
extends Node3D

@export var zone_id := ""
@export var zone_name := "Zone"

var built := false                 # Pfahl steht schon
var tender: Node3D = null          # Bewohner, der gerade nebenbei Holz nachlegt
var fuel := 0.0                    # Sekunden Brenndauer übrig
var _attacked_t := 0.0             # > 0: ein Lichtfresser saugt gerade daran
var _warned_low := false
var _warn_cd := 0.0                # damit die Warnung nicht ständig kommt
var _label_t := 0.0
var _t := 0.0
var _pole: Node3D
var _flame: MeshInstance3D
var _light: OmniLight3D
var _ring: MeshInstance3D
var _plot: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group("torches")
	_build_visuals()
	Lights.register(self)
	_update_visuals()


func _exit_tree() -> void:
	Lights.unregister(self)


func is_burning() -> bool:
	return built and fuel > 0.0


# --- Werte je Art (Feuerstelle und kleine Fackel überschreiben sie) ---------------
func seconds_per_wood() -> float:
	return Config.torch_seconds_per_wood


func max_wood() -> int:
	return Config.torch_max_wood


func light_radius_full() -> float:
	return Config.torch_light_radius


## Größe der Flamme (Feuerstelle größer, kleine Fackel kleiner).
func flame_size() -> float:
	return 1.0


## Name in Meldungen, z. B. "Fackel Westsenke".
func title() -> String:
	return "Fackel " + zone_name


func max_fuel() -> float:
	return seconds_per_wood() * max_wood()


## Wie viel Holz passt gerade hinein (nur ganze Scheite)?
func wood_space() -> int:
	return int(floor((max_fuel() - fuel) / seconds_per_wood() + 0.001))


## Lichtradius: schrumpft in den letzten 30 Sekunden.
func get_light_radius() -> float:
	if not is_burning():
		return 0.0
	return light_radius_full() * lerpf(0.6, 1.0, clampf(fuel / 30.0, 0.0, 1.0))


## Feste Lichtquelle, füllt aber die Laterne nicht auf (das kann nur Feuer/Leuchtfeuer).
func can_refill_at(_pos: Vector3) -> bool:
	return false


func under_attack() -> bool:
	return _attacked_t > 0.0


## Errichten: Pfahl steht, brennt sofort mit voller Ladung.
func build() -> void:
	built = true
	fuel = max_fuel()
	_warned_low = false
	Sfx.play("ignite", 0.0, 0.0)
	_toast("%s brennt – die Zone ist hell" % title())
	_update_visuals()


## Holz nachlegen (auch zum Wieder-Entzünden, wenn sie erloschen ist).
func add_wood(n: int) -> void:
	var was_out := not is_burning()
	fuel = minf(fuel + n * seconds_per_wood(), max_fuel())
	_warned_low = false
	Sfx.play("ignite" if was_out else "pickup", 0.0, 0.0)
	if was_out:
		_toast("%s brennt wieder" % title())
	_update_visuals()


## Brennstoff abziehen (Lichtfresser).
func drain(seconds: float) -> void:
	if not is_burning():
		return
	_attacked_t = 0.5
	if _warn_cd <= 0.0:
		_warn_cd = 12.0
		_toast("Ein Lichtfresser frisst an: %s!" % title())
	_burn(seconds)


## Zeit vergehen lassen (normal jedes Bild; beim Tod des Hüters 60 s auf einmal).
func advance(dt: float) -> void:
	if is_burning():
		_burn(dt)


func _burn(seconds: float) -> void:
	fuel = maxf(fuel - seconds, 0.0)
	if fuel <= 0.0:
		_toast("%s ist erloschen" % title())
		Sfx.play("death", -8.0)
		_update_visuals()
	elif fuel < 30.0 and not _warned_low:
		_warned_low = true
		_toast("%s brennt bald aus" % title())


func _toast(text: String) -> void:
	get_tree().call_group("hud", "toast", text)


func _process(delta: float) -> void:
	_t += delta
	_attacked_t -= delta
	_warn_cd -= delta
	advance(delta)
	if is_burning():
		var f := sin(_t * 10.0) * 0.08 + sin(_t * 23.0) * 0.05
		if under_attack():
			f += sin(_t * 31.0) * 0.25   # zuckt, wenn daran gesaugt wird
		var r := get_light_radius()
		_light.omni_range = r * 1.25 * (1.0 + f * 0.3)
		_light.light_energy = 1.7 * (1.0 + f)
		_flame.scale = Vector3(1, 1.0 + f * 2.0, 1) * (r / light_radius_full()) * flame_size()
		_ring.scale = Vector3(r, 1, r)
	# Beschriftung nur 2× pro Sekunde erneuern (spart Leistung)
	_label_t -= delta
	if _label_t <= 0.0:
		_label_t = 0.5
		_update_label()


func _update_visuals() -> void:
	_pole.visible = built
	_plot.visible = not built
	_flame.visible = is_burning()
	_light.visible = is_burning()
	_ring.visible = is_burning()
	_update_label()


func _update_label() -> void:
	if not built:
		_label.text = "%s\nFackelpfahl: %d Holz" % [zone_name, Config.torch_build_cost]
		_label.modulate = Color(1, 0.8, 0.5, 0.75)
	elif is_burning():
		var s := int(fuel)
		_label.text = "%s\n%d:%02d" % [title(), s / 60, s % 60]
		_label.modulate = Color(1, 0.4, 0.3, 0.95) if under_attack() or fuel < 30.0 else Color(1, 0.85, 0.55, 0.85)
	else:
		_label.text = "%s\nerloschen" % title()
		_label.modulate = Color(0.7, 0.7, 0.8, 0.8)


func _build_visuals() -> void:
	# Bauplatz: schwacher Kreis am Boden
	_plot = MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 1.2
	pm.bottom_radius = 1.2
	pm.height = 0.02
	pm.radial_segments = 16
	_plot.mesh = pm
	var plot_mat := StandardMaterial3D.new()
	plot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plot_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plot_mat.albedo_color = Color(1, 0.8, 0.5, 0.15)
	_plot.material_override = plot_mat
	_plot.position.y = 0.02
	add_child(_plot)
	# Pfahl mit Schale
	_pole = Node3D.new()
	add_child(_pole)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.3, 0.2, 0.13)
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.1
	cm.bottom_radius = 0.16
	cm.height = 2.4
	cm.radial_segments = 6
	post.mesh = cm
	post.material_override = wood
	post.position.y = 1.2
	_pole.add_child(post)
	var bowl := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.32
	bm.bottom_radius = 0.15
	bm.height = 0.25
	bm.radial_segments = 6
	bowl.mesh = bm
	bowl.material_override = wood
	bowl.position.y = 2.45
	_pole.add_child(bowl)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.3
	cs.height = 2.0
	shape.shape = cs
	shape.position.y = 1.0
	body.add_child(shape)
	_pole.add_child(body)
	# Flamme
	_flame = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.28
	cone.height = 0.7
	cone.radial_segments = 6
	_flame.mesh = cone
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1, 0.6, 0.2)
	_flame.material_override = fm
	_flame.position.y = 2.9
	add_child(_flame)
	# Licht (ohne Schatten, spart Leistung)
	_light = OmniLight3D.new()
	_light.light_color = Color(1, 0.62, 0.32)
	_light.omni_attenuation = 0.7
	_light.shadow_enabled = false
	_light.position.y = 3.2
	add_child(_light)
	# Rand der hellen Zone als schwacher Ring (Größe = 1 m, wird skaliert)
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.985
	torus.outer_radius = 1.0
	torus.rings = 40
	torus.ring_segments = 3
	_ring.mesh = torus
	var ring_mat := StandardMaterial3D.new()
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.albedo_color = Color(1, 0.6, 0.25, 0.25)
	_ring.material_override = ring_mat
	_ring.position.y = 0.03
	add_child(_ring)
	# Beschriftung
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0009
	_label.font_size = 30
	_label.outline_size = 10
	_label.position.y = 3.6
	add_child(_label)
