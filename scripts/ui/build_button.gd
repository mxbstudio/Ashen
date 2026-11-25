## Knopf "… bauen" – erscheint, wenn der Hüter auf einem freien Bauplatz steht.
extends Button

@export var player: Node3D
@export var fortress: Node3D

var _target: Node3D = null


func _ready() -> void:
	add_to_group("touch_blockers")
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(420, 90)
	add_theme_font_size_override("font_size", 24)
	add_theme_stylebox_override("normal", UiStyle.box(Color(0.9, 0.6, 0.25, 0.4), Color(1, 0.75, 0.4)))
	add_theme_stylebox_override("pressed", UiStyle.box(Color(0.9, 0.6, 0.25, 0.8), Color.WHITE, 3))
	add_theme_stylebox_override("hover", UiStyle.box(Color(0.9, 0.6, 0.25, 0.5), Color(1, 0.75, 0.4)))
	add_theme_stylebox_override("disabled", UiStyle.box(Color(0.3, 0.3, 0.3, 0.5), Color(0.6, 0.6, 0.6)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(_on_pressed)
	visible = false


func _process(_delta: float) -> void:
	_target = null
	if player.is_alive() and not get_tree().paused:
		for b in get_tree().get_nodes_in_group("buildings"):
			if not b.built and Vector2(b.global_position.x - player.global_position.x,
					b.global_position.z - player.global_position.z).length() < 2.2:
				_target = b
				break
	visible = _target != null
	if _target:
		var ok: bool = fortress.can_build(_target)
		disabled = not ok
		text = "%s bauen (%d Holz)\n%s" % [_target.display_name(), _target.cost(),
				_target.description() if ok else "Nicht genug Holz in der Festung"]
		var vp := get_viewport_rect().size
		size = custom_minimum_size
		position = Vector2((vp.x - size.x) / 2.0, vp.y - 580.0)


func _on_pressed() -> void:
	if _target:
		var b := _target
		fortress.build(b)
		if b.built:
			# Hüter vor das neue Gebäude stellen (nicht darin einsperren)
			player.global_position = b.work_spot() + (b.work_spot() - b.global_position).normalized() * 0.8
