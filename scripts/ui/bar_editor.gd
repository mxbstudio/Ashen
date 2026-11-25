## Skill-Leiste umbauen – nur am Feuer.
## Bedienung: ein Feld antippen (wird markiert), dann
##  - ein anderes Feld antippen  -> die beiden tauschen
##  - einen Skill im Vorrat antippen -> kommt in das Feld
##  - "Feld leeren" -> Skill wandert in den Vorrat
extends Control

@export var player: Node3D
@export var touch_controls: Control

var _open_button: Button
var _selected := -1
var _box: VBoxContainer
var _info: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_to_group("touch_blockers")
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.offset_left = 30
	_box.offset_right = -30
	_box.offset_top = 170
	_box.offset_bottom = -40
	_box.add_theme_constant_override("separation", 18)
	add_child(_box)
	# Knopf "Leiste umbauen" – erscheint über der Skill-Leiste, wenn der Hüter am Feuer steht
	_open_button = UiStyle.button("Leiste umbauen", Color(1, 0.7, 0.3), 26, Vector2(300, 70))
	_open_button.add_to_group("touch_blockers")
	_open_button.pressed.connect(open)
	_open_button.visible = false
	add_sibling.call_deferred(_open_button)


func _process(_delta: float) -> void:
	var at_fire: bool = player.is_alive() and Lights.refill_source_at(player.global_position) != null
	_open_button.visible = at_fire and not visible and not get_tree().paused
	var vp := get_viewport_rect().size
	_open_button.position = Vector2((vp.x - _open_button.size.x) / 2.0, vp.y - 560.0)


func open() -> void:
	touch_controls.reset()
	get_tree().paused = true
	visible = true
	_selected = -1
	_rebuild()


func close() -> void:
	visible = false
	get_tree().paused = false


func _rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()
	var bar: Node = player.skill_bar
	_box.add_child(UiStyle.label("Skill-Leiste umbauen", 42, Color(1, 0.8, 0.45)))
	_box.add_child(UiStyle.label("Läuft von links nach rechts im Kreis. Modifikatoren wirken auf den nächsten Angriff rechts davon.", 22, Color(1, 1, 1, 0.6)))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in bar.slots.size():
		var id: String = bar.slots[i]
		var text := SkillData.short_with_level(id, bar.level_of(id)) if id != "" else "leer"
		var b := UiStyle.button("%d\n%s" % [i + 1, text], SkillData.color(id), 24, Vector2(0, 130))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == _selected:
			b.add_theme_stylebox_override("normal", UiStyle.box(Color(1, 0.8, 0.4, 0.5), Color.WHITE, 5))
		b.pressed.connect(_on_slot.bind(i))
		row.add_child(b)
	_box.add_child(row)

	_info = UiStyle.label(_info_text(), 24, Color(1, 0.9, 0.7))
	_info.custom_minimum_size = Vector2(0, 120)
	_box.add_child(_info)

	_box.add_child(UiStyle.label("Vorrat", 30, Color(1, 1, 1, 0.8)))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	if bar.stash.is_empty():
		_box.add_child(UiStyle.label("(leer – neue Skills gibt es beim Stufenaufstieg)", 22, Color(1, 1, 1, 0.4)))
	for j in bar.stash.size():
		var sid: String = bar.stash[j]
		var sb := UiStyle.button(SkillData.short_with_level(sid, bar.level_of(sid)), SkillData.color(sid), 26, Vector2(200, 90))
		sb.pressed.connect(_on_stash.bind(j))
		grid.add_child(sb)
	_box.add_child(grid)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box.add_child(spacer)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	var clear := UiStyle.button("Feld leeren", Color(0.7, 0.7, 0.7), 28, Vector2(0, 100))
	clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear.disabled = _selected == -1
	clear.pressed.connect(_on_clear)
	bottom.add_child(clear)
	var done := UiStyle.button("Fertig", Color(0.5, 0.9, 0.5), 32, Vector2(0, 100))
	done.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	done.pressed.connect(close)
	bottom.add_child(done)
	_box.add_child(bottom)


func _info_text() -> String:
	if _selected == -1:
		return "Tippe ein Feld an."
	var id: String = player.skill_bar.slots[_selected]
	var head := "Feld %d gewählt.\n" % (_selected + 1)
	if id != "":
		head += "Stufe %d · " % player.skill_bar.level_of(id) + UiStyle.skill_text(id).replace("\n", " · ") + "\n"
	return head + "Jetzt: anderes Feld (tauschen) oder Skill aus dem Vorrat antippen."


func _on_slot(i: int) -> void:
	if _selected == -1:
		_selected = i
	elif _selected == i:
		_selected = -1
	else:
		player.skill_bar.swap_slots(_selected, i)
		_selected = -1
	_rebuild()


func _on_stash(j: int) -> void:
	if _selected == -1:
		_info.text = "Erst ein Feld oben antippen, dann den Skill aus dem Vorrat."
		return
	player.skill_bar.put_from_stash(_selected, j)
	_selected = -1
	_rebuild()


func _on_clear() -> void:
	if _selected != -1:
		player.skill_bar.clear_slot(_selected)
		_selected = -1
		_rebuild()
