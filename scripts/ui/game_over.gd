## Ende-Bildschirm (Niederlage, später auch Sieg) mit "Neu starten".
extends Control

@export var touch_controls: Control

var _title: Label
var _text: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("touch_blockers")
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 40
	box.offset_right = -40
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 30)
	add_child(box)
	_title = UiStyle.label("", 50, Color(1, 0.6, 0.35))
	box.add_child(_title)
	_text = UiStyle.label("", 28, Color(1, 1, 1, 0.8))
	box.add_child(_text)
	var b := UiStyle.button("Neu starten", Color(1, 0.7, 0.3), 34, Vector2(0, 110))
	b.pressed.connect(_restart)
	box.add_child(b)


func show_end(title: String, text: String) -> void:
	if visible:
		return
	touch_controls.reset()
	_title.text = title
	_text.text = text
	visible = true
	get_tree().paused = true


func _restart() -> void:
	Config.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()
