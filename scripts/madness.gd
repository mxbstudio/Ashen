## Wahnsinn des Hüters (v0.3). Hängt als Kind am Hüter ("Madness").
## - Steigt draußen in der Dunkelheit (außerhalb von Feuer, Fackeln, Feuerstellen, Leuchtfeuer),
##   schneller bei schwacher oder leerer Laterne – und durch dunkle Skills.
## - Sinkt nur langsam am Feuer (Ruhe kostet Zeit), etwas durch den Tod, manche Ereignisse und Licht-Skills.
##   Talismane: Herdstein (am Feuer ×3), Glutamulett (auch an Fackeln, Feuerstellen, Leuchtfeuer).
## - Stufen: 25 unruhig · 50 gezeichnet · 75 verloren. Jede Stufe +10 % Schaden.
##   Ab 25: Flüstern, dunkle Skills im Stufenaufstieg. Ab 50: Trugbilder (falsche Augen im Dunkeln),
##   die Anzeige lügt manchmal, die Bewohner fürchten dich. Ab 75: Trugbilder springen dich an.
##   Bei 100: der Wahn zehrt am Leben.
extends Node

const WorldScript := preload("res://scripts/world.gd")

const STAGE_NAMES := ["klar", "unruhig", "gezeichnet", "verloren"]
const WHISPERS := [
	"… lass es ausgehen …",
	"… sie wollen das Feuer für sich …",
	"… niemand dankt dir …",
	"… die Dunkelheit war immer gütig …",
	"… hörst du sie kratzen? …",
	"… einer von ihnen lügt …",
	"… du bist schon lange tot …",
	"… nur noch ein Schritt hinaus …",
	"… das Licht brennt dich …",
	"… sie flüstern über dich am Feuer …",
]

var value := 0.0
var _whisper_t := 25.0
var _phantom_t := 6.0
var _lie_t := 20.0
var _lie_left := 0.0
var _rng := RandomNumberGenerator.new()
var _last_stage := 0

@onready var player: Node3D = get_parent()


func _ready() -> void:
	_rng.randomize()


## Wahnsinn ändern (positiv = mehr). Der Wahnstein verdoppelt jeden Zuwachs.
func add(amount: float) -> void:
	if amount > 0.0 and player.has_talisman("madstone"):
		amount *= 2.0
	value = clampf(value + amount, 0.0, 100.0)


## 0 klar, 1 unruhig (25), 2 gezeichnet (50), 3 verloren (75)
func stage() -> int:
	return clampi(int(value / 25.0), 0, 3)


func stage_name() -> String:
	return STAGE_NAMES[stage()]


func damage_bonus() -> float:
	return Config.madness_damage_per_stage * stage()


## Lügt die Anzeige gerade? 0 = nein, sonst Stärke (für hud.gd).
func lie_amount() -> float:
	return 1.0 if _lie_left > 0.0 else 0.0


func _process(delta: float) -> void:
	if get_tree().paused or not player.is_alive():
		return
	_update_value(delta)
	var st := stage()
	if st != _last_stage:
		if st > _last_stage:
			get_tree().call_group("hud", "toast", "Wahnsinn: %s" % STAGE_NAMES[st], 3.0)
		_last_stage = st
	if st >= 1:
		_whisper_t -= delta
		if _whisper_t <= 0.0:
			_whisper_t = _rng.randf_range(18.0, 34.0) / st
			get_tree().call_group("hud", "whisper", WHISPERS[_rng.randi() % WHISPERS.size()])
			Sfx.play("omen", -14.0, 0.4)
	if st >= 2:
		_lie_left -= delta
		_lie_t -= delta
		if _lie_t <= 0.0:
			_lie_t = _rng.randf_range(14.0, 26.0)
			_lie_left = 3.0
		_phantom_t -= delta
		if _phantom_t <= 0.0 and player.global_position.z < -13.0:
			_phantom_t = _rng.randf_range(3.0, 7.0) if st == 2 else _rng.randf_range(2.0, 4.5)
			_spawn_phantom(st >= 3 and _rng.randf() < 0.45)
	else:
		_lie_left = 0.0
	if value >= 100.0:
		player.take_damage(Config.madness_full_drain * delta, null, true)
	DebugOverlay.watch("Wahnsinn", "%d (%s)" % [int(value), stage_name()])


func _update_value(delta: float) -> void:
	var pos: Vector3 = player.global_position
	var src := Lights.fixed_source_at(pos)
	if src != null:
		# am Feuer der Festung (nicht am Leuchtfeuer) kommt der Geist langsam zur Ruhe
		if Lights.refill_source_at(pos) != null and not src.is_in_group("beacon"):
			var preachers := 0
			var fort := get_tree().get_first_node_in_group("fortress")
			if fort:
				preachers = fort.trait_count("prediger")
			var rate := Config.madness_fire_recover + 0.15 * preachers
			if player.has_talisman("hearthstone"):
				rate *= 3.0   # Herdstein
			add(-rate * delta)
		elif player.has_talisman("embercharm"):
			add(-Config.madness_fire_recover * delta)   # Glutamulett: auch an kleineren Feuern
		return
	if pos.z > -12.0:
		return   # in der Festung, aber nicht am Feuer: nichts
	var rate := Config.madness_dark_rate
	var f: float = player.lantern.fraction()
	if f <= 0.0:
		rate += Config.madness_empty_rate
	elif f < 0.3:
		rate += Config.madness_low_lantern_rate
	add(rate * delta)


## Trugbild: ein Paar glühender Augen im Dunkeln. rushing = springt auf den Hüter zu (ab Stufe 3).
func _spawn_phantom(rushing: bool) -> void:
	for attempt in 8:
		var a := _rng.randf() * TAU
		var p: Vector3 = player.global_position + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(8.0, 13.0)
		if not WorldScript.is_outside(p, 1.0) or Lights.is_lit(p):
			continue
		var ph := Phantom.new()
		ph.player = player
		ph.rushing = rushing
		player.get_parent().add_child(ph)
		ph.global_position = p
		return


## Trugbild (nur Bild, kein echter Gegner). Verschwindet, wenn man nahe kommt.
class Phantom extends Node3D:
	var player: Node3D
	var rushing := false
	var _t := 0.0
	var _mat := StandardMaterial3D.new()

	func _ready() -> void:
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(1, 0.15, 0.1, 0.0)
		var s := SphereMesh.new()
		s.radius = 0.11
		s.height = 0.22
		s.radial_segments = 6
		s.rings = 3
		for side in [-1, 1]:
			var m := MeshInstance3D.new()
			m.mesh = s
			m.material_override = _mat
			m.position = Vector3(side * 0.2, 0.6, 0)
			add_child(m)

	func _process(delta: float) -> void:
		_t += delta
		if not is_instance_valid(player):
			queue_free()
			return
		var to := player.global_position - global_position
		to.y = 0
		look_at(global_position - to, Vector3.UP)
		var fade_in := clampf(_t / 0.8, 0.0, 1.0)
		var alpha := fade_in
		if rushing and _t > 1.2:
			global_position += to.normalized() * 9.0 * delta
			if to.length() < 0.8:
				# springt hinein – und ist nicht da. Nur der Schreck bleibt.
				player.hurt_flash = 0.35
				Sfx.play("hurt", -6.0)
				queue_free()
				return
		elif to.length() < 4.0 or _t > 6.0:
			alpha = maxf(0.0, 1.0 - (_t - 6.0)) if _t > 6.0 else 0.0
			if alpha <= 0.0:
				queue_free()
				return
		_mat.albedo_color.a = alpha * (0.8 + 0.2 * sin(_t * 9.0))
