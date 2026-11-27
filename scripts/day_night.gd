## Tag und Nacht sichtbar machen (v0.5).
## Liest die Uhr der Festung (fortress.night(): 0 = Tag, 1 = Nacht), meldet den Nacht-Anteil an Lights.night
## (Gegner, Nachschub, Wahnsinn richten sich danach) und blendet Umgebungslicht, Mond/Sonne und Hintergrund über.
## Der Tag bleibt ein fahler Aschetag – Feuer und Laterne sollen weiter zählen.
extends Node

@export var fortress: Node3D
@export var environment: Environment
@export var sky_light: DirectionalLight3D

# Tag: fahles, warmgraues Licht durch die Asche
const DAY_AMBIENT := Color(0.58, 0.55, 0.5)
const DAY_AMBIENT_ENERGY := 0.6
const DAY_SUN := Color(0.95, 0.86, 0.72)
const DAY_SUN_ENERGY := 0.55
const DAY_BG := Color(0.07, 0.065, 0.06)
# Dämmerung: ein Hauch Glut am Himmel (stärkste Tönung bei halber Nacht)
const DUSK_TINT := Color(0.75, 0.45, 0.35)
# Nacht: dunkler als bisher, kaltes Mondlicht
const NIGHT_AMBIENT := Color(0.25, 0.28, 0.45)
const NIGHT_AMBIENT_ENERGY := 0.2
const NIGHT_MOON := Color(0.5, 0.56, 0.82)
const NIGHT_MOON_ENERGY := 0.1
const NIGHT_BG := Color(0.005, 0.005, 0.01)

var _shown := -1.0   # angezeigter Nacht-Anteil (gleitet weich nach, z. B. nach dem Zeitsprung beim Tod)


func _process(delta: float) -> void:
	if fortress == null:
		return
	var target: float = fortress.night()
	if _shown < 0.0:
		_shown = target
	else:
		_shown = move_toward(_shown, target, delta * 0.5)   # höchstens ganz Tag → Nacht in 2 s
	Lights.night = target
	_apply(_shown)


func _apply(n: float) -> void:
	var dusk := 1.0 - absf(n - 0.5) * 2.0   # 0 am Tag und in der Nacht, 1 mitten in der Dämmerung
	if environment:
		var amb := DAY_AMBIENT.lerp(NIGHT_AMBIENT, n)
		environment.ambient_light_color = amb.lerp(amb * DUSK_TINT * 1.4, dusk * 0.5)
		environment.ambient_light_energy = lerpf(DAY_AMBIENT_ENERGY, NIGHT_AMBIENT_ENERGY, n)
		environment.background_color = DAY_BG.lerp(NIGHT_BG, n).lerp(Color(0.09, 0.04, 0.03), dusk * 0.6)
	if sky_light:
		sky_light.light_color = DAY_SUN.lerp(NIGHT_MOON, n).lerp(Color(1.0, 0.55, 0.35), dusk * 0.6)
		sky_light.light_energy = lerpf(DAY_SUN_ENERGY, NIGHT_MOON_ENERGY, n)
