## Lässt im Gelände immer wieder Gegner erscheinen – im Dunkeln, außer Sichtweite des Hüters.
## Höchstens Config.max_enemies gleichzeitig (Leistung im Handy-Browser).
## Brennen draußen Fackeln, schickt die Dunkelheit ab und zu einen Lichtfresser los, der eine löschen will.
extends Node3D

const Crawler := preload("res://scripts/enemies/crawler.gd")
const LightEater := preload("res://scripts/enemies/lighteater.gd")
const Lost := preload("res://scripts/enemies/lost.gd")
const WorldScript := preload("res://scripts/world.gd")

@export var player: Node3D
@export var enabled := true

var _timer := 1.0
var _raid_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_raid_timer = Config.torch_raid_interval


func alive_count() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


func _process(delta: float) -> void:
	if not enabled or player == null:
		return
	_raid_step(delta)
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = Config.spawn_interval
	# Sitzt der Hüter sicher am Feuer, streifen nur halb so viele Gegner umher
	var limit := Config.max_enemies
	if Lights.fixed_source_at(player.global_position) != null:
		limit = Config.max_enemies / 2
	var free_slots := limit - alive_count()
	if free_slots <= 0:
		return
	# Mischung: meist Kriecher-Rudel, manchmal Lichtfresser oder ein Verlorener
	var roll := _rng.randf()
	if roll < 0.55:
		_spawn_group(Crawler, mini(_rng.randi_range(3, 4), free_slots))
	elif roll < 0.8:
		_spawn_group(LightEater, 1)
	else:
		_spawn_group(Lost, 1)


func _spawn_group(script: Script, count: int) -> void:
	var center := _find_spawn_point()
	if center == Vector3.INF:
		return
	for i in count:
		var e: EnemyBase = script.new()
		e.player = player
		add_child(e)
		e.global_position = center + Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(-1.5, 1.5))


## Sucht eine dunkle Stelle mit genug Abstand zum Hüter und zum Feuer.
func _find_spawn_point() -> Vector3:
	for attempt in 20:
		var p := Vector3(_rng.randf_range(-27, 27), 0, _rng.randf_range(-89, -20))
		if absf(p.x) < 8.0 and p.z > -24.0:
			continue   # nicht direkt vor dem Tor
		if p.distance_to(player.global_position) < Config.spawn_min_distance:
			continue
		if _near_resident(p):
			continue
		if Lights.fixed_source_at(p, 3.0) != null:
			continue
		if p.distance_to(Vector3(0, 0, -80)) < 14.0:
			continue   # nicht in der Boss-Arena
		return p
	return Vector3.INF


## Raubzug: ein Lichtfresser fliegt zu einer zufälligen brennenden Fackel.
func _raid_step(delta: float) -> void:
	_raid_timer -= delta
	if _raid_timer > 0.0:
		return
	_raid_timer = Config.torch_raid_interval
	if alive_count() >= Config.max_enemies:
		return
	var lit := []
	for t in get_tree().get_nodes_in_group("torches") + get_tree().get_nodes_in_group("fire_pits"):
		if t.is_burning():
			lit.append(t)
	if lit.is_empty():
		return
	var torch: Node3D = lit[_rng.randi() % lit.size()]
	# Startpunkt: im Dunkeln, ein Stück von der Fackel entfernt, nicht direkt beim Hüter
	for attempt in 20:
		var a := _rng.randf() * TAU
		var p := torch.global_position + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(16.0, 24.0)
		if not WorldScript.is_outside(p, 2.0) or (absf(p.x) < 8.0 and p.z > -24.0):
			continue
		if p.distance_to(player.global_position) < Config.spawn_min_distance:
			continue
		if Lights.fixed_source_at(p, 2.0) != null:
			continue
		var e: EnemyBase = LightEater.new()
		e.player = player
		e.torch_target = torch
		add_child(e)
		e.global_position = p
		return



## Steht ein Bewohner draußen in der Nähe? (Dort sollen keine Gegner aus dem Nichts erscheinen.)
func _near_resident(p: Vector3) -> bool:
	for r in get_tree().get_nodes_in_group("residents"):
		if r.is_exposed() and p.distance_to(r.global_position) < 12.0:
			return true
	return false
