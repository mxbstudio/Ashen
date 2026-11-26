## Schwebende Schadenszahl über einem Getroffenen.
extends Label3D

var _t := 0.0


func setup(amount: float, col: Color) -> void:
	text = str(roundi(amount))
	modulate = col
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	fixed_size = true
	pixel_size = 0.0012
	font_size = 48
	outline_size = 12
	outline_modulate = Color(0, 0, 0, 0.9)


func _process(delta: float) -> void:
	_t += delta
	position.y += delta * 1.5
	modulate.a = clampf(1.5 - _t * 1.8, 0.0, 1.0)
	if _t > 0.8:
		queue_free()
