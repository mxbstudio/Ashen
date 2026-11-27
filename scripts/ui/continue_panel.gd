## Startfenster: Gibt es einen Spielstand, fragt es "Weiterspielen" oder "Neues Spiel".
## Ohne Spielstand startet das Spiel sofort neu. Erst nach der Wahl wird automatisch gespeichert.
extends Control

@export var save_game: Node
@export var touch_controls: Control

var _data := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("touch_blockers")
	visible = false
	_data = save_game.read()
	if _data.is_empty():
		save_game.delete_save()   # kaputter oder alter Stand -> weg damit
		save_game.enabled = true
		return
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 40
	box.offset_right = -40
	UiStyle.keep_in_column(box, 40)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 30)
	add_child(box)
	box.add_child(UiStyle.label("Aschen", 56, Color(1, 0.7, 0.35)))
	box.add_child(UiStyle.label("Gespeicherter Stand:\n" + save_game.summary(_data), 26, Color(1, 1, 1, 0.85)))
	var go := UiStyle.button("Weiterspielen", Color(0.5, 0.9, 0.5), 34, Vector2(0, 110))
	go.pressed.connect(_continue)
	box.add_child(go)
	var fresh := UiStyle.button("Neues Spiel\n(gespeicherter Stand wird gelöscht)", Color(1, 0.6, 0.4), 24, Vector2(0, 110))
	fresh.pressed.connect(_new_game)
	box.add_child(fresh)
	visible = true
	get_tree().paused = true


func _continue() -> void:
	save_game.apply(_data)
	get_tree().call_group("hud", "toast", "Spielstand geladen")
	_close()


func _new_game() -> void:
	save_game.delete_save()
	_close()


func _close() -> void:
	touch_controls.reset()
	visible = false
	get_tree().paused = false
	save_game.enabled = true
