## Licht-Verwaltung (Autoload "Lights").
## Jede Lichtquelle (Laterne, Feuer, später Leuchtfeuer) meldet sich hier an.
## Andere Teile des Spiels fragen hier: "Ist diese Stelle hell?" (z. B. Gegner).
extends Node

var _sources: Array[Node3D] = []


func register(source: Node3D) -> void:
	if not _sources.has(source):
		_sources.append(source)


func unregister(source: Node3D) -> void:
	_sources.erase(source)


## Wie hell ist es hier? 0 = völlig dunkel, 1 = mitten im Licht.
func light_level(pos: Vector3) -> float:
	var best := 0.0
	for s in _sources:
		var r: float = s.get_light_radius()
		if r <= 0.0:
			continue
		var d := Vector2(pos.x - s.global_position.x, pos.z - s.global_position.z).length()
		best = maxf(best, clampf(1.0 - d / r, 0.0, 1.0))
	return best


## Liegt die Stelle innerhalb irgendeines Lichtkreises?
func is_lit(pos: Vector3) -> bool:
	return light_level(pos) > 0.0


## Gibt die Lichtquelle zurück, an der man die Laterne auffüllen kann (oder null).
func refill_source_at(pos: Vector3) -> Node3D:
	for s in _sources:
		if s.has_method("can_refill_at") and s.can_refill_at(pos):
			return s
	return null
