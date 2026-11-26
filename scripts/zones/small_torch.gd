## Kleine Fackel: vom Hüter überall draußen in den Boden gesteckt (kostet 1 Holz, siehe ui/place_buttons.gd).
## Kleiner Lichtkreis (Kriecher meiden ihn), brennt nur kurz, kann nicht nachgelegt werden
## und verschwindet, wenn sie ausgebrannt ist.
extends "res://scripts/zones/torch_post.gd"


func _ready() -> void:
	zone_name = "Kleine Fackel"
	super._ready()
	remove_from_group("torches")   # zählt nicht als Zonen-Fackel, kein Nachlegen
	add_to_group("small_torches")


func seconds_per_wood() -> float:
	return Config.small_torch_seconds


func max_wood() -> int:
	return 1


func light_radius_full() -> float:
	return Config.small_torch_radius


func flame_size() -> float:
	return 0.7


func title() -> String:
	return "Kleine Fackel"


## Ausgebrannt -> verschwinden (ohne Meldung, das wäre bei vielen Fackeln zu viel).
func _burn(seconds: float) -> void:
	fuel = maxf(fuel - seconds, 0.0)
	if fuel <= 0.0:
		queue_free()


## Aussehen: kleiner, schräger Stecken, keine Beschriftung.
func _build_visuals() -> void:
	super._build_visuals()
	_pole.scale = Vector3(0.7, 0.55, 0.7)
	_pole.rotation.z = 0.12
	_flame.position.y = 1.65
	_light.position.y = 2.2
	_label.visible = false


func _update_label() -> void:
	_label.text = ""
