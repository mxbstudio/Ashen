## Touch-Steuerung fürs Handy:
## - untere Bildschirmhälfte: Joystick erscheint dort, wo der Daumen aufsetzt
## - rechts unten: großer Dash-Knopf, darüber der Trank-Knopf
## Die Eingaben werden als ganz normale "Aktionen" weitergegeben (wie Tasten),
## deshalb funktionieren Touch und Tastatur gleich.
extends Control

const IDLE_ALPHA := 0.35

var _joy_index := -1
var _joy_center := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _button_touch := {}     # Touch-Nummer -> Aktion ("dash"/"potion")
var _pressed := {"dash": false, "potion": false}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Mittelpunkt der Knöpfe (abhängig von der Bildschirmgröße).
func button_center(action: String) -> Vector2:
	var s := size
	var r := Config.button_radius
	match action:
		"dash":
			return Vector2(s.x - r - 40, s.y - r - 40)
		"potion":
			return Vector2(s.x - r - 40 - r * 2.0, s.y - r * 0.7 - 30)
	return Vector2.ZERO


func button_radius(action: String) -> float:
	return Config.button_radius * (1.0 if action == "dash" else 0.7)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_down(event.index, event.position)
		else:
			_on_touch_up(event.index)
	elif event is InputEventScreenDrag and event.index == _joy_index:
		_update_joystick(event.position)


## Alle gedrückten Eingaben loslassen (z. B. bevor ein Menü das Spiel pausiert).
func reset() -> void:
	for a in ["dash", "potion", "move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	_joy_index = -1
	_joy_vec = Vector2.ZERO
	_button_touch.clear()
	_pressed = {"dash": false, "potion": false}
	queue_redraw()


## Liegt die Stelle auf einem Knopf der Oberfläche (Gruppe "touch_blockers")?
func _blocked(pos: Vector2) -> bool:
	for c in get_tree().get_nodes_in_group("touch_blockers"):
		if c.is_visible_in_tree() and c.get_global_rect().has_point(pos):
			return true
	return false


func _on_touch_down(index: int, pos: Vector2) -> void:
	if _blocked(pos):
		return
	for action in ["dash", "potion"]:
		if pos.distance_to(button_center(action)) <= button_radius(action) * 1.2:
			_button_touch[index] = action
			_pressed[action] = true
			Input.action_press(action)
			get_viewport().set_input_as_handled()
			queue_redraw()
			return
	if pos.y > size.y * 0.45 and _joy_index == -1:
		_joy_index = index
		_joy_center = pos
		_joy_vec = Vector2.ZERO
		get_viewport().set_input_as_handled()
		queue_redraw()


func _on_touch_up(index: int) -> void:
	if _button_touch.has(index):
		var action: String = _button_touch[index]
		_button_touch.erase(index)
		_pressed[action] = false
		Input.action_release(action)
		queue_redraw()
	elif index == _joy_index:
		_joy_index = -1
		_joy_vec = Vector2.ZERO
		_apply_joystick()
		queue_redraw()


func _update_joystick(pos: Vector2) -> void:
	var r := Config.joystick_radius
	var d := pos - _joy_center
	# Zieht man weiter als den Rand, wandert der Joystick mit
	if d.length() > r:
		_joy_center = pos - d.normalized() * r
		d = pos - _joy_center
	_joy_vec = d / r
	_apply_joystick()
	get_viewport().set_input_as_handled()
	queue_redraw()


func _apply_joystick() -> void:
	var v := _joy_vec
	if v.length() < Config.joystick_deadzone:
		v = Vector2.ZERO
	elif not Config.joystick_analog:
		v = v.normalized()   # sofort volle Kraft
	_set_axis("move_right", maxf(v.x, 0.0))
	_set_axis("move_left", maxf(-v.x, 0.0))
	_set_axis("move_down", maxf(v.y, 0.0))
	_set_axis("move_up", maxf(-v.y, 0.0))


func _set_axis(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _draw() -> void:
	var r := Config.joystick_radius
	if _joy_index != -1:
		draw_circle(_joy_center, r, Color(1, 1, 1, 0.12))
		draw_arc(_joy_center, r, 0, TAU, 48, Color(1, 0.8, 0.5, 0.5), 3.0)
		draw_circle(_joy_center + _joy_vec * r, r * 0.42, Color(1, 0.8, 0.5, 0.55))
	else:
		# Hinweis, wo der Joystick ist
		var c := Vector2(40 + r, size.y - 40 - r)
		draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.12), 2.0)
		draw_circle(c, r * 0.42, Color(1, 1, 1, 0.08))

	var font := get_theme_default_font()
	for action in ["dash", "potion"]:
		var c := button_center(action)
		var br := button_radius(action)
		var a := 0.75 if _pressed[action] else IDLE_ALPHA
		var col := Color(1, 0.75, 0.4, a) if action == "dash" else Color(0.6, 0.9, 0.6, a)
		draw_circle(c, br, Color(col, a * 0.5))
		draw_arc(c, br, 0, TAU, 48, col, 3.0)
		var label := "Dash" if action == "dash" else "Trank"
		var fs := 30 if action == "dash" else 24
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, c + Vector2(-ts.x / 2.0, ts.y / 4.0), label,
				HORIZONTAL_ALIGNMENT_CENTER, -1, fs, Color(1, 1, 1, 0.85))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
