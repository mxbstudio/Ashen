## Debug-Anzeige (läuft immer, als "Autoload").
## - oben links: Build-Version, FPS und frei setzbare Werte (DebugOverlay.watch("Name", wert))
## - darunter: die letzten Fehlermeldungen in Rot
## - "Bitte Handy drehen", wenn das Handy quer gehalten wird (nur auf Touch-Geräten)
## Antippen der Info-Zeile blendet die Details ein/aus.
extends CanvasLayer

const MAX_ERRORS := 6

var _catcher := ErrorCatcher.new()
var _info: Label
var _errors: Label
var _rotate: ColorRect
var _watched := {}
var _error_lines: Array[String] = []
var _error_count := 0
var _details := true
var _build := "lokal"


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	OS.add_logger(_catcher)
	_build = _read_build_info()
	_build_ui()


## Merkt sich einen Wert, der in der Anzeige erscheinen soll.
func watch(key: String, value) -> void:
	_watched[key] = value


## Eigene Meldung in die Fehlerliste schreiben (z. B. für Hinweise beim Testen).
func note(text: String) -> void:
	_add_error_line("Info: " + text, false)


func _read_build_info() -> String:
	var f := FileAccess.open("res://build_info.txt", FileAccess.READ)
	if f == null:
		return "lokal"
	return f.get_as_text().strip_edges()


func _build_ui() -> void:
	var font_size := 22

	_info = Label.new()
	_info.position = Vector2(8, 4)
	_info.add_theme_font_size_override("font_size", font_size)
	_info.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8, 0.85))
	_info.add_theme_color_override("font_outline_color", Color.BLACK)
	_info.add_theme_constant_override("outline_size", 6)
	_info.mouse_filter = Control.MOUSE_FILTER_STOP
	_info.gui_input.connect(_on_info_input)
	add_child(_info)

	_errors = Label.new()
	_errors.position = Vector2(8, 34)
	_errors.add_theme_font_size_override("font_size", 18)
	_errors.add_theme_color_override("font_color", Color(1, 0.35, 0.3))
	_errors.add_theme_color_override("font_outline_color", Color.BLACK)
	_errors.add_theme_constant_override("outline_size", 5)
	_errors.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_errors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_errors)

	# Vollflächiger Hinweis bei Hochformat
	_rotate = ColorRect.new()
	_rotate.color = Color(0, 0, 0, 0.95)
	_rotate.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rotate.mouse_filter = Control.MOUSE_FILTER_STOP
	var lbl := Label.new()
	lbl.text = "Bitte Handy drehen\n(Hochformat)"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.add_theme_color_override("font_color", Color(1, 0.75, 0.4))
	_rotate.add_child(lbl)
	_rotate.visible = false
	add_child(_rotate)


func _on_info_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.pressed:
		_details = not _details


func _add_error_line(text: String, is_error := true) -> void:
	if is_error:
		_error_count += 1
	_error_lines.append(text)
	while _error_lines.size() > MAX_ERRORS:
		_error_lines.pop_front()


func _process(_delta: float) -> void:
	for e in _catcher.take():
		_add_error_line(e)

	var size := get_viewport().get_visible_rect().size
	_rotate.visible = size.x > size.y and DisplayServer.is_touchscreen_available()

	var txt := "Aschen %s · %d FPS" % [_build, Engine.get_frames_per_second()]
	if _error_count > 0:
		txt += " · %d Fehler" % _error_count
	if _details:
		for k in _watched:
			txt += "\n%s: %s" % [k, str(_watched[k])]
	_info.text = txt

	_errors.visible = _details and not _error_lines.is_empty()
	_errors.position.y = _info.position.y + _info.size.y + 4
	_errors.size.x = size.x * 0.6
	_errors.text = "\n".join(_error_lines)
