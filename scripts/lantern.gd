## Die Laterne des Hüters.
## Brennstoff sinkt mit der Zeit -> Lichtradius schrumpft von max bis min.
## Am Feuer (später auch am Leuchtfeuer) füllt sie sich wieder auf.
extends Node3D

signal refilling_changed(active: bool)

var fuel := 0.0                    # Sekunden Brenndauer übrig
var refilling := false
var omen := false                  # Vorzeichen der Belagerung: Laterne zuckt mit
var _light: OmniLight3D
var _glow: MeshInstance3D
var _t := 0.0


func _ready() -> void:
	fuel = Config.lantern_burn_time
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.72, 0.4)
	_light.omni_attenuation = 0.6       # flacher Abfall -> klarer Lichtkreis
	_light.shadow_enabled = false       # spart Leistung
	_light.position = Vector3(0, 2.4, 0)
	add_child(_light)
	# kleines leuchtendes Glas
	_glow = MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = 0.14
	m.height = 0.28
	m.radial_segments = 8
	m.rings = 4
	_glow.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.8, 0.45)
	_glow.material_override = mat
	_glow.position = Vector3(0.35, 1.0, 0.25)
	add_child(_glow)
	Lights.register(self)


func _exit_tree() -> void:
	Lights.unregister(self)


## Anteil Brennstoff 0..1
func fraction() -> float:
	return clampf(fuel / Config.lantern_burn_time, 0.0, 1.0)


## Aktueller Lichtradius in Metern (für Gegner, HUD usw.)
func get_light_radius() -> float:
	return lerpf(Config.lantern_radius_min, Config.lantern_radius_max, fraction())


## Brennstoff abziehen (z. B. später durch Lichtfresser oder Opferlicht).
func drain(seconds: float) -> void:
	fuel = maxf(fuel - seconds, 0.0)


func _process(delta: float) -> void:
	_t += delta
	var source := Lights.refill_source_at(global_position)
	var now_refilling := source != null and fuel < Config.lantern_burn_time
	if source != null:
		fuel = minf(fuel + Config.lantern_burn_time / Config.lantern_refill_seconds * delta,
				Config.lantern_burn_time)
	else:
		fuel = maxf(fuel - delta, 0.0)
	if now_refilling != refilling:
		refilling = now_refilling
		refilling_changed.emit(refilling)

	# Flackern: stärker, wenn wenig Brennstoff übrig ist
	var f := fraction()
	var flicker_amount := 0.04 + (0.25 if f < 0.2 else 0.0) + (0.3 * absf(sin(_t * 2.3)) if omen else 0.0)
	var flicker := 1.0 + (sin(_t * 11.0) * 0.6 + sin(_t * 27.0) * 0.4) * flicker_amount
	var r := get_light_radius()
	_light.omni_range = r * 1.3 * flicker
	_light.light_energy = lerpf(0.9, 1.6, f) * flicker
	_glow.scale = Vector3.ONE * lerpf(0.6, 1.1, f) * flicker

	DebugOverlay.watch("Laterne", "%d s · Radius %.1f m%s" % [int(fuel), r, " · füllt auf" if refilling else ""])
