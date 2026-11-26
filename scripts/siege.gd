## Belagerungen: alle paar Minuten. Ablauf:
##   1. Vorzeichen (30 s vorher): das Feuer flackert unruhig – kein Countdown.
##   2. Die Glocke läutet: Gegner erscheinen vor dem Tor und schlagen darauf ein.
##   3. Bewohner (von der Mauer) und Wachturm schießen mit. Der Hüter kann draußen mitkämpfen.
##   4. Ende: alle Angreifer tot -> überstanden. Tor fällt -> ein Bewohner stirbt, Angreifer ziehen ab.
## Nach dem Boss folgt die letzte Belagerung: hält das Tor, ist das Spiel gewonnen.
extends Node

signal siege_started(final: bool)
signal siege_ended(held: bool, final: bool)

const ArrowScript := preload("res://scripts/arrow.gd")
const Crawler := preload("res://scripts/enemies/crawler.gd")
const LightEater := preload("res://scripts/enemies/lighteater.gd")
const Lost := preload("res://scripts/enemies/lost.gd")

@export var fortress: Node3D
@export var fire: Node3D
@export var gate: Node3D
@export var spawner: Node3D
@export var player: Node3D

var time_to_bell := 0.0            # Sekunden bis zur nächsten Glocke (nur intern, kein Countdown im HUD)
var active := false
var final_pending := false         # Boss besiegt -> nächste Belagerung ist die letzte
var is_final := false
var count := 0                     # wie viele Belagerungen schon waren
var _to_spawn := 0
var _spawn_t := 0.0
var _enemies: Array[Node3D] = []
var _defense_t := 0.0
var _omen_announced := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("siege")
	_rng.randomize()
	time_to_bell = Config.siege_interval
	gate.broken.connect(_on_gate_broken)


func omen_active() -> bool:
	return not active and time_to_bell <= Config.siege_warning


var _rumble_t := 0.0


func _process(delta: float) -> void:
	if not fortress.is_fire_burning():
		return
	advance(delta)
	if omen_active():
		_rumble_t -= delta
		if _rumble_t <= 0.0:
			_rumble_t = 7.0
			Sfx.play("omen", -2.0, 0.1)
	if active:
		_spawn_step(delta)
		_defend(delta)
		_check_end()


## Zeit vergehen lassen (auch beim Zeitsprung nach dem Tod).
func advance(dt: float) -> void:
	if active:
		return
	time_to_bell -= dt
	var omen := omen_active()
	fire.omen = omen
	player.lantern.omen = omen
	if omen and not _omen_announced:
		_omen_announced = true
		get_tree().call_group("hud", "toast", "Das Feuer flackert unruhig …")
		if fortress.zone_workers_total() > 0:
			get_tree().call_group("hud", "toast", "Die Bewohner draußen kehren heim.")
		Sfx.play("omen", 0.0, 0.0)
	if time_to_bell <= 0.0:
		_start()


## Boss besiegt: die letzte Belagerung kommt bald.
func boss_defeated() -> void:
	final_pending = true
	if not active:
		time_to_bell = Config.siege_warning + 5.0
		_omen_announced = false


func _start() -> void:
	active = true
	fire.omen = false
	is_final = final_pending
	count += 1
	_to_spawn = Config.final_siege_size if is_final else Config.siege_size + Config.siege_growth * (count - 1)
	_spawn_t = 0.0
	_enemies.clear()
	spawner.enabled = false
	get_tree().call_group("hud", "bell")
	Sfx.play("bell", 2.0, 0.0)
	get_tree().call_group("hud", "toast",
			"Die Glocke läutet – letzte Belagerung!" if is_final else "Die Glocke läutet – Belagerung!")
	siege_started.emit(is_final)


func _spawn_step(delta: float) -> void:
	if _to_spawn <= 0:
		return
	_spawn_t -= delta
	if _spawn_t > 0.0:
		return
	_spawn_t = Config.siege_batch_interval
	var room := Config.max_enemies - get_tree().get_nodes_in_group("enemies").size()
	var n := mini(mini(Config.siege_batch, _to_spawn), room)
	for i in n:
		var roll := _rng.randf()
		var script: Script = Crawler if roll < 0.6 else (LightEater if roll < 0.8 else Lost)
		var e: EnemyBase = script.new()
		e.player = player
		e.siege_gate = gate
		spawner.add_child(e)
		e.global_position = Vector3(_rng.randf_range(-8, 8), 0, _rng.randf_range(-34, -28))
		_enemies.append(e)
		_to_spawn -= 1


## Bewohner schießen von der Mauer auf Angreifer in Tornähe.
func _defend(delta: float) -> void:
	# Bewohner mit Bogen zählen doppelt
	var n: int = fortress.residents.size() + fortress.armed_count() + fortress.trait_count("schuetze")
	if n == 0:
		return
	_defense_t -= delta
	if _defense_t > 0.0:
		return
	_defense_t = Config.resident_defense_interval / n
	var best: Node3D = null
	var best_d := 9.0
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			var d := e.global_position.distance_to(gate.global_position)
			if d < best_d:
				best_d = d
				best = e
	if best == null:
		return
	var arrow := Node3D.new()
	arrow.set_script(ArrowScript)
	fortress.add_child(arrow)
	arrow.global_position = gate.global_position + Vector3(_rng.randf_range(-4, 4), 3.2, 0.3)
	arrow.launch(best, Config.resident_defense_damage, {}, self)


## Wird vom Pfeil der Bewohner aufgerufen.
func hit(target: Node3D, amount: float, _heal: Dictionary) -> void:
	if is_instance_valid(target) and target.is_alive():
		target.take_damage(amount, null)


func _check_end() -> void:
	if _to_spawn > 0:
		return
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			return
	_end(true)


func _on_gate_broken() -> void:
	if not active:
		return
	fortress.kill_resident("Das Tor ist gefallen – %s ist tot.")
	fortress.mood_shock(-8.0)
	# Angreifer ziehen ab
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			e.queue_free()
	_end(false)


func _end(held: bool) -> void:
	active = false
	_to_spawn = 0
	spawner.enabled = true
	gate.repair_full()
	_omen_announced = false
	var was_final := is_final
	if was_final and held:
		final_pending = false
	elif was_final:
		time_to_bell = Config.siege_retry_delay + Config.siege_warning
	else:
		time_to_bell = Config.siege_interval
	if held:
		get_tree().call_group("hud", "toast", "Belagerung überstanden!")
	siege_ended.emit(held, was_final)


## Lebende Angreifer (für das HUD).
func attackers_left() -> int:
	var n := _to_spawn
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			n += 1
	return n
