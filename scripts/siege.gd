## Belagerungen kommen nachts (v0.6): in Nacht 2, 4, 6, 8 … und immer in der letzten Nacht (Config.nights_to_win).
## Ablauf:
##   1. Vorzeichen (30 s vor der Nachtruhe): das Feuer flackert unruhig.
##   2. Mit der Nachtruhe läutet die Glocke: Gegner erscheinen vor dem Tor und schlagen darauf ein.
##   3. Bewohner steigen auf den Wachturm und schießen von dort (ohne Turm: niemand). Der Hüter kann draußen mitkämpfen.
##   4. Ende: alle Angreifer tot -> überstanden. Tor fällt -> ein Bewohner stirbt, Angreifer ziehen ab.
## Hält das Tor in der letzten Nacht, ist das Spiel gewonnen. Fällt es, kommen sie in der nächsten Nacht wieder.
## Wer vorher den Hauptmann besiegt, hat es im letzten Sturm leichter.
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

var active := false
var won := false                   # letzter Sturm gehalten
var last_night := 0                # in dieser Nacht (= Tag) gab es zuletzt eine Belagerung
var is_final := false
var count := 0                     # wie viele Belagerungen schon waren
var _to_spawn := 0
var _spawn_t := 0.0
var _enemies: Array[Node3D] = []
var _defense_t := 0.0
var _omen_announced := false
var _announced_day := 1            # für die Morgen-Meldung „Heute Nacht: Belagerung!“
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("siege")
	_rng.randomize()
	gate.broken.connect(_on_gate_broken)


## Kommt in Nacht n eine Belagerung? Die letzte Nacht (und jede danach, falls das Tor fiel) immer.
func is_siege_night(n: int) -> bool:
	if n >= Config.nights_to_win:
		return true
	return n >= Config.siege_first_night and (n - Config.siege_first_night) % maxi(Config.siege_every, 1) == 0


## Kommt heute Nacht noch eine Belagerung?
func siege_tonight() -> bool:
	return not won and is_siege_night(fortress.day) and last_night < fortress.day


func is_final_night() -> bool:
	return fortress.day >= Config.nights_to_win


func omen_active() -> bool:
	return not active and siege_tonight() and fortress.phase() == "free" \
			and fortress.phase_left() <= Config.siege_warning


var _rumble_t := 0.0


func _process(delta: float) -> void:
	if not fortress.is_fire_burning():
		return
	_update_omen()
	if fortress.day != _announced_day:
		_announced_day = fortress.day
		if siege_tonight():
			get_tree().call_group("hud", "toast", "Die letzte Nacht – der letzte Sturm kommt!" if is_final_night()
					else "Heute Nacht: Belagerung!")
	if not active and siege_tonight() and fortress.phase() == "night":
		_start()
	if omen_active():
		_rumble_t -= delta
		if _rumble_t <= 0.0:
			_rumble_t = 7.0
			Sfx.play("omen", -2.0, 0.1)
	if active:
		_spawn_step(delta)
		_defend(delta)
		_check_end()


func _update_omen() -> void:
	var omen := omen_active()
	fire.omen = omen
	player.lantern.omen = omen
	if omen and not _omen_announced:
		_omen_announced = true
		get_tree().call_group("hud", "toast", "Das Feuer flackert unruhig …")
		if fortress.zone_workers_total() > 0:
			get_tree().call_group("hud", "toast", "Die Bewohner draußen kehren heim.")
		Sfx.play("omen", 0.0, 0.0)


func _start() -> void:
	active = true
	fire.omen = false
	is_final = is_final_night()
	last_night = fortress.day
	count += 1
	if is_final:
		_to_spawn = Config.final_siege_size_boss if get_parent().get("boss_defeated") else Config.final_siege_size
	else:
		_to_spawn = Config.siege_size + Config.siege_growth * (count - 1)
	_spawn_t = 0.0
	_enemies.clear()
	spawner.enabled = false
	# herumstreifende Gegner weit weg vom Hüter ziehen sich zurück – die Dunkelheit sammelt sich zum Sturm
	for e in get_tree().get_nodes_in_group("enemies"):
		if not e.is_in_group("boss") and e.siege_gate == null and e.global_position.distance_to(player.global_position) > 20.0:
			e.queue_free()
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
	# Platz: nur Angreifer zählen (nicht der Hauptmann, nicht herumstreifende Gegner) – sonst konnte der
	# letzte Angreifer nie erscheinen und die Anzeige blieb bei „1 Angreifer“ stehen.
	var room := Config.max_enemies - attackers_alive()
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


## Bewohner steigen auf den Wachturm und schießen von oben (nicht mehr unsichtbar „von der Mauer“).
## Ohne Wachturm schießt niemand – je höher der Turm, desto mehr Plätze (4 / 6 / 8).
func _defend(delta: float) -> void:
	fortress.update_defense()   # wer heimkommt, steigt hinauf
	var shooters: Array = fortress.defenders()
	if shooters.is_empty():
		return
	# Bewohner mit Bogen und gute Schützen zählen doppelt
	var n: int = shooters.size()
	for r in shooters:
		n += (1 if r.has_bow else 0) + (1 if r.has_trait("schuetze") else 0)
	_defense_t -= delta
	if _defense_t > 0.0:
		return
	_defense_t = Config.resident_defense_interval / n
	var shooter: Node3D = shooters[_rng.randi() % shooters.size()]
	var best: Node3D = null
	var best_d := 20.0
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			var d: float = e.global_position.distance_to(shooter.global_position)
			if d < best_d:
				best_d = d
				best = e
	if best == null:
		return
	var dmg := Config.resident_bow_damage if shooter.has_bow else Config.resident_defense_damage
	if shooter.has_trait("schuetze"):
		dmg *= 2.0
	dmg *= shooter.combat_factor()   # Kampftraining (v0.4)
	var arrow := Node3D.new()
	arrow.set_script(ArrowScript)
	fortress.add_child(arrow)
	arrow.global_position = shooter.global_position + Vector3(0, 1.2, 0)
	arrow.launch(best, dmg, {}, self)
	Sfx.play_at("shoot", shooter.global_position, -10.0)


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
	fortress.end_defense()   # alle steigen vom Turm
	_to_spawn = 0
	spawner.enabled = true
	gate.repair_full()
	_omen_announced = false
	var was_final := is_final
	if was_final and held:
		won = true
	if held:
		get_tree().call_group("hud", "toast", "Belagerung überstanden!")
	siege_ended.emit(held, was_final)


## Angreifer, die gerade leben (ohne die noch nicht erschienenen).
func attackers_alive() -> int:
	var n := 0
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			n += 1
	return n


## Lebende Angreifer (für das HUD).
func attackers_left() -> int:
	var n := _to_spawn
	for e in _enemies:
		if is_instance_valid(e) and e.is_alive():
			n += 1
	return n
