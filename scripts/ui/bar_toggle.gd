## Knopf „Leiste an/aus“ links über der Skill-Leiste (Taste R).
## Außerdem hier: die übrigen Tasten für den PC – E Bauen/Fackel, F Turm/Schnellreise, L Menü „Leiste“, B „Bewohner“.
## Die Leiste läuft nur, wenn sie eingeschaltet ist – unabhängig davon, wie weit die Gegner weg sind.
extends Button

@export var player: Node3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # L/B schließen die Menüs auch im Pausenzustand
	add_to_group("touch_blockers")
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(190, 62)
	add_theme_font_size_override("font_size", 24)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(_on_pressed)
	_update()


func _on_pressed() -> void:
	player.skill_bar.toggle()
	_update()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("bar_toggle") and not get_tree().paused:
		_on_pressed()
	elif event.is_action_pressed("interact") and not get_tree().paused:
		_press_first(["TorchButton", "BuildButton"])
	elif event.is_action_pressed("interact2") and not get_tree().paused:
		_press_first(["ClimbButton", "TravelButton"])
	elif event.is_action_pressed("menu_bar"):
		_toggle_menu("BarEditor")
	elif event.is_action_pressed("menu_people"):
		_toggle_menu("Workers")


## Den ersten sichtbaren, nicht gesperrten Knopf auslösen.
func _press_first(names: Array) -> void:
	for n in names:
		var b := get_parent().get_node_or_null(n) as Button
		if b and b.visible and not b.disabled:
			b.pressed.emit()
			get_viewport().set_input_as_handled()
			return


## Menü öffnen bzw. (nochmal drücken) schließen.
func _toggle_menu(n: String) -> void:
	var m := get_parent().get_node_or_null(n)
	if m == null:
		return
	if m.visible:
		m.close()
	elif not get_tree().paused and player.is_alive():
		m.open()
	get_viewport().set_input_as_handled()


func _update() -> void:
	var on: bool = player.skill_bar.active
	text = ("Leiste: AN" if on else "Leiste: AUS") + UiStyle.key_hint("R")
	var col := Color(0.4, 0.9, 0.45) if on else Color(0.75, 0.4, 0.35)
	add_theme_stylebox_override("normal", UiStyle.box(Color(col, 0.35), Color(col, 0.9), 3))
	add_theme_stylebox_override("hover", UiStyle.box(Color(col, 0.45), Color(col, 1.0), 3))
	add_theme_stylebox_override("pressed", UiStyle.box(Color(col, 0.7), Color.WHITE, 3))


## Wichtig: Sichtbarkeit nur ändern, wenn nötig – sonst geht ein Fingertipp verloren.
var _shown_on := false
func _process(_delta: float) -> void:
	UiStyle.update_columns(get_tree())   # Menüs auf Breitbild-Monitoren mittig halten
	var show: bool = player.is_alive() and not get_tree().paused
	if visible != show:
		visible = show
	var vp := get_viewport_rect().size
	size = custom_minimum_size
	position = Vector2(UiStyle.column(vp).position.x + 16, vp.y - 500)
	if _shown_on != player.skill_bar.active:
		_shown_on = player.skill_bar.active
		_update()
