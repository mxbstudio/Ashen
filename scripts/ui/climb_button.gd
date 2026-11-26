## Knopf "Turm besteigen" (vor dem gebauten Wachturm) bzw. "Herabsteigen" (oben auf dem Turm).
## Oben schießt der Hüter erhöht über die Mauer und reicht weiter – laufen kann er dort nicht.
extends Button

@export var player: Node3D

var _tower: Node3D = null


func _ready() -> void:
	add_to_group("touch_blockers")
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(420, 80)
	add_theme_font_size_override("font_size", 24)
	add_theme_stylebox_override("normal", UiStyle.box(Color(0.6, 0.5, 0.9, 0.4), Color(0.8, 0.7, 1.0)))
	add_theme_stylebox_override("pressed", UiStyle.box(Color(0.6, 0.5, 0.9, 0.8), Color.WHITE, 3))
	add_theme_stylebox_override("hover", UiStyle.box(Color(0.6, 0.5, 0.9, 0.5), Color(0.8, 0.7, 1.0)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(_on_pressed)
	visible = false


## Wichtig: Sichtbarkeit nur ändern, wenn nötig – sonst geht ein Fingertipp verloren.
func _process(_delta: float) -> void:
	var show := false
	_tower = null
	if player.is_alive() and not get_tree().paused:
		if player.on_tower:
			text = "Herabsteigen"
			show = true
		else:
			for b in get_tree().get_nodes_in_group("buildings"):
				if b.kind == "tower" and b.built:
					var spot: Vector3 = b.work_spot()
					if Vector2(spot.x - player.global_position.x, spot.z - player.global_position.z).length() < 2.2:
						_tower = b
						text = "Turm besteigen (+%d m Reichweite)" % int(b.climb_range_bonus())
						show = true
	if show:
		var vp := get_viewport_rect().size
		size = custom_minimum_size
		position = Vector2((vp.x - size.x) / 2.0, vp.y - 680.0)
	if visible != show:
		visible = show


func _on_pressed() -> void:
	if player.on_tower:
		player.descend()
	elif _tower:
		player.climb(_tower)
		get_tree().call_group("hud", "toast", "Auf dem Turm: Schießen über die Mauer – Nahkampf reicht nicht hinaus")
