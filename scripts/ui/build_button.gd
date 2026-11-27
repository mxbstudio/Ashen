## Knopf "… bauen" bzw. "… verbessern".
## Bauen: auf dem freien Bauplatz stehen. Verbessern: vor dem Gebäude stehen (Seite zum Feuer).
## Nach dem Drücken verschwindet der Knopf, bis der Hüter einmal weggeht –
## so wird nicht aus Versehen doppelt getippt.
extends Button

@export var player: Node3D
@export var fortress: Node3D

var _target: Node3D = null
var _locked: Node3D = null         # gerade benutzt: erst wieder zeigen, wenn der Hüter weggeht


func _ready() -> void:
	add_to_group("touch_blockers")
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(460, 90)
	add_theme_font_size_override("font_size", 22)
	add_theme_stylebox_override("normal", UiStyle.box(Color(0.9, 0.6, 0.25, 0.4), Color(1, 0.75, 0.4)))
	add_theme_stylebox_override("pressed", UiStyle.box(Color(0.9, 0.6, 0.25, 0.8), Color.WHITE, 3))
	add_theme_stylebox_override("hover", UiStyle.box(Color(0.9, 0.6, 0.25, 0.5), Color(1, 0.75, 0.4)))
	add_theme_stylebox_override("disabled", UiStyle.box(Color(0.3, 0.3, 0.3, 0.5), Color(0.6, 0.6, 0.6)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(_on_pressed)
	visible = false


## Steht der Hüter am Bauplatz bzw. vor dem Gebäude?
func _near(b: Node3D) -> bool:
	var spot: Vector3 = b.work_spot() if b.built else b.global_position
	return Vector2(spot.x - player.global_position.x, spot.z - player.global_position.z).length() < 2.2


## Wichtig: Sichtbarkeit nur ändern, wenn nötig – sonst geht ein Fingertipp verloren.
func _process(_delta: float) -> void:
	_target = null
	if _locked and not _near(_locked):
		_locked = null
	if player.is_alive() and not get_tree().paused:
		for b in get_tree().get_nodes_in_group("buildings"):
			if b.can_improve() and b != _locked and _near(b):
				_target = b
				break
	var show := _target != null
	if _target:
		var ok: bool = fortress.can_build(_target)
		disabled = not ok
		var c: int = _target.next_cost()
		if not _target.built:
			text = "%s bauen (%d Holz)\n%s" % [_target.display_name(), c,
					_target.description(1) if ok else "Nicht genug Holz – %d bleiben fürs Feuer" % Config.vital_reserve]
		else:
			var nl: int = _target.level + 1
			text = "%s verbessern → Stufe %d (%d Holz)\n%s" % [_target.display_name(), nl, c,
					_target.description(nl) if ok else "Nicht genug Holz – %d bleiben fürs Feuer" % Config.vital_reserve]
		var vp := get_viewport_rect().size
		size = custom_minimum_size
		position = Vector2((vp.x - size.x) / 2.0, vp.y - 580.0)
	if visible != show:
		visible = show


func _on_pressed() -> void:
	if _target == null:
		return
	var b := _target
	var was_built: bool = b.built
	fortress.build(b)
	_locked = b
	if b.built and not was_built:
		# Hüter vor das neue Gebäude stellen (nicht darin einsperren)
		player.global_position = b.work_spot() + (b.work_spot() - b.global_position).normalized() * 0.8
