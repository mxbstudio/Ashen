## Etappe 0: leere Testszene. Zeigt nur einen sich drehenden Würfel im Feuerschein,
## damit wir sehen, dass der Weg GitHub → Web-Export → Handy-Browser funktioniert.
extends Node3D

@onready var cube: MeshInstance3D = $Cube
@onready var fire_light: OmniLight3D = $FireLight
var _t := 0.0
var _taps := 0


func _process(delta: float) -> void:
	_t += delta
	cube.rotate_y(delta * 0.8)
	# leichtes Flackern wie ein Feuer
	fire_light.light_energy = 2.0 + sin(_t * 9.0) * 0.15 + sin(_t * 23.0) * 0.1
	DebugOverlay.watch("Antipper", _taps)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_taps += 1
