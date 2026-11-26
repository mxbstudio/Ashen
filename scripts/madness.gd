## Wahnsinn des Hüters (0–100).
## Steigt draußen außerhalb fester Lichter – schneller, je schwächer die Laterne ist.
## Sinkt in festem Licht (Fackel, Feuerstelle, Leuchtfeuer, Feuer), am Feuer/an Feuerstellen besonders schnell.
## Wirkung: ab 30 dunkler Rand + Flüstern, ab 50 Trugbilder (Augen, Schatten-Kriecher),
## ab 75 unzuverlässige Anzeige und falsche Warnungen, bei 100 zehrt er am Leben.
## Narben: Wer über 75 kommt, behält 10 Wahnsinn, der nicht mehr weggeht (bis zum Tod).
## Eine weitere Narbe gibt es erst, wenn man sich zwischendurch unter 60 erholt hat.
## Das HUD liest "value" und "level()" für Balken und Effekte.
extends Node

const PhantomScript := preload("res://scripts/phantom.gd")
const FAKE_WARNINGS := ["Das Feuer flackert unruhig …", "Etwas ist hinter dir.", "Die Glocke …?",
		"Fackel ist erloschen", "Ein Bewohner ruft um Hilfe!"]

@export var player: Node3D

var value := 0.0
var scar := 0.0                    # Narben: darunter sinkt der Wahnsinn nicht mehr
var _above := false                # gerade über der Narben-Schwelle (gegen mehrere Narben auf einmal)
var _whisper_t := 4.0
var _phantom_t := 3.0
var _fake_t := 20.0
var _hurt_t := 1.0


## 0 = klar, 1 = ab 30, 2 = ab 50, 3 = ab 75, 4 = bei 100
func level() -> int:
	if value >= 100.0: return 4
	if value >= 75.0: return 3
	if value >= 50.0: return 2
	if value >= 30.0: return 1
	return 0


func _ready() -> void:
	add_to_group("madness")
	player.respawned.connect(_on_respawn)


func _on_respawn() -> void:
	value = 0.0
	scar = 0.0
	_above = false


func _process(delta: float) -> void:
	if not player.is_alive():
		return
	_change(delta)
	if not Config.madness_enabled:
		value = 0.0
		scar = 0.0
		return
	var l := level()
	if l >= 1:
		_whisper_t -= delta
		if _whisper_t <= 0.0:
			_whisper_t = randf_range(5.0, 10.0) / l
			Sfx.play("whisper", -14.0 + l * 3.0, 0.25)
	if l >= 2:
		_phantom_t -= delta
		if _phantom_t <= 0.0:
			_phantom_t = randf_range(4.0, 8.0) / (l - 1)
			_spawn_phantom("rush" if randf() < 0.3 else "eyes")
	if l >= 3:
		_fake_t -= delta
		if _fake_t <= 0.0:
			_fake_t = randf_range(18.0, 35.0)
			get_tree().call_group("hud", "toast", FAKE_WARNINGS[randi() % FAKE_WARNINGS.size()])
	if l >= 4:
		_hurt_t -= delta
		if _hurt_t <= 0.0:
			_hurt_t = 1.0
			player.take_damage(Config.madness_damage, null)   # einmal pro Sekunde


## Steigen oder sinken je nach Licht.
func _change(delta: float) -> void:
	var pos: Vector3 = player.global_position
	if Lights.lantern_refill_at(pos) != null:
		value -= Config.madness_heal_fire * delta       # am Feuer, Leuchtfeuer, an Feuerstellen
	elif Lights.fixed_source_at(pos) != null or player.on_tower:
		value -= Config.madness_heal_light * delta      # im Licht einer Fackel usw. / auf dem Turm
	elif pos.z > -12.0:
		value -= Config.madness_heal_light * delta      # in der Festung
	else:
		var f: float = player.lantern.fraction()
		var rate: float = Config.madness_rise * (1.0 + 2.0 * (1.0 - f))
		if f <= 0.0:
			rate = Config.madness_rise_no_lantern
		value += rate * delta
	value = clampf(value, scar, 100.0)
	# Narbe, wenn er über 75 steigt
	if value >= Config.madness_scar_at and not _above:
		_above = true
		if scar < Config.madness_scar_max:
			scar = minf(scar + Config.madness_scar, Config.madness_scar_max)
			get_tree().call_group("hud", "toast", "Der Wahnsinn hinterlässt eine Narbe (%d)" % int(scar))
	elif value < Config.madness_scar_at - 15.0:
		_above = false


## Trugbild im Dunkeln um den Hüter herum.
func _spawn_phantom(kind: String) -> void:
	var p: Vector3 = player.global_position
	for attempt in 8:
		var a := randf() * TAU
		var at := p + Vector3(cos(a), 0, sin(a)) * randf_range(6.0, 11.0)
		if Lights.is_lit(at):
			continue
		var ph := Node3D.new()
		ph.set_script(PhantomScript)
		ph.kind = kind
		ph.target = player
		player.get_parent().add_child(ph)
		ph.global_position = at
		if kind == "rush":
			Sfx.play("whisper", -6.0, 0.3)
		return
