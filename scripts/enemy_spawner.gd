## Lässt im Gelände immer wieder Gegner erscheinen – im Dunkeln, außer Sichtweite des Hüters.
## Höchstens Config.max_enemies gleichzeitig (Leistung im Handy-Browser).
extends Node3D

const Crawler := preload("res://scripts/enemies/crawler.gd")
const LightEater := preload("res://scripts/enemies/lighteater.gd")
const Lost := preload("res://scripts/enemies/lost.gd")

@export var player: Node3D
@export var enabled := true

var _timer := 1.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


func alive_count() -> int:
	return get_tree().get_nodes_in_group("enemies").size()


func _process(delta: float) -> void:
	if not enabled or player == null:
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = Config.spawn_interval
	var free_slots := Config.max_enemies - alive_count()
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
		if Lights.fixed_source_at(p, 3.0) != null:
			continue
		return p
	return Vector3.INF
