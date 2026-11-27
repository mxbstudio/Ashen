## Knopf „Leiste an/aus“ links über der Skill-Leiste (Taste E).
## Die Leiste läuft nur, wenn sie eingeschaltet ist – unabhängig davon, wie weit die Gegner weg sind.
extends Button

@export var player: Node3D


func _ready() -> void:
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


func _update() -> void:
	var on: bool = player.skill_bar.active
	text = "Leiste: AN" if on else "Leiste: AUS"
	var col := Color(0.4, 0.9, 0.45) if on else Color(0.75, 0.4, 0.35)
	add_theme_stylebox_override("normal", UiStyle.box(Color(col, 0.35), Color(col, 0.9), 3))
	add_theme_stylebox_override("hover", UiStyle.box(Color(col, 0.45), Color(col, 1.0), 3))
	add_theme_stylebox_override("pressed", UiStyle.box(Color(col, 0.7), Color.WHITE, 3))


## Wichtig: Sichtbarkeit nur ändern, wenn nötig – sonst geht ein Fingertipp verloren.
var _shown_on := false
func _process(_delta: float) -> void:
	var show: bool = player.is_alive() and not get_tree().paused
	if visible != show:
		visible = show
	var vp := get_viewport_rect().size
	size = custom_minimum_size
	position = Vector2(16, vp.y - 500)
	if _shown_on != player.skill_bar.active:
		_shown_on = player.skill_bar.active
		_update()
