## Bewohner einteilen – nur am Feuer.
## Pro Zone draußen: Holzfäller und Sammler mit − / + einteilen.
## Arbeiten können sie nur in hellen Zonen; die übrigen Bewohner besetzen die Gebäude.
## Pausiert das Spiel, solange es offen ist.
extends Control

@export var player: Node3D
@export var fortress: Node3D
@export var touch_controls: Control

var _open_button: Button
var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("touch_blockers")
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24
	scroll.offset_right = -24
	scroll.offset_top = 60
	scroll.offset_bottom = -150
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_box)
	var done := UiStyle.button("Fertig", Color(0.5, 0.9, 0.5), 32, Vector2(0, 100))
	done.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	done.offset_left = 24
	done.offset_right = -24
	done.offset_top = -130
	done.offset_bottom = -30
	done.pressed.connect(close)
	add_child(done)
	# Knopf am Feuer (über "Leiste umbauen")
	_open_button = UiStyle.button("Bewohner einteilen", Color(0.6, 0.9, 0.7), 26, Vector2(300, 70))
	_open_button.add_to_group("touch_blockers")
	_open_button.pressed.connect(open)
	_open_button.visible = false
	add_sibling.call_deferred(_open_button)


## Wichtig: Sichtbarkeit nur ändern, wenn nötig – sonst geht ein Fingertipp verloren.
func _process(_delta: float) -> void:
	var src := Lights.refill_source_at(player.global_position)
	var at_fire: bool = player.is_alive() and src != null and not src.is_in_group("beacon")
	var show := at_fire and not visible and not get_tree().paused
	if _open_button.visible != show:
		_open_button.visible = show
	if show:
		var vp := get_viewport_rect().size
		_open_button.position = Vector2((vp.x - _open_button.size.x) / 2.0, vp.y - 650.0)


func open() -> void:
	touch_controls.reset()
	get_tree().paused = true
	visible = true
	_rebuild()


func close() -> void:
	visible = false
	get_tree().paused = false


func _rebuild() -> void:
	for c in _box.get_children():
		c.queue_free()
	var total: int = fortress.residents.size()
	var outside: int = fortress.zone_workers_total()
	_box.add_child(UiStyle.label("Bewohner einteilen", 40, Color(0.7, 1, 0.8)))
	_box.add_child(UiStyle.label("Bewohner: %d · draußen eingeteilt: %d · in der Festung: %d" % [total, outside, total - outside],
			24, Color(1, 0.9, 0.7)))
	_box.add_child(UiStyle.label("Einteilen geht in jeder Zone – arbeiten können sie aber nur, solange die Zone hell ist "
			+ "(Fackel brennt bzw. Leuchtfeuer entzündet). Sonst warten sie am Feuer. Draußen im Dunkeln greifen "
			+ "Kriecher sie an. Bei Belagerung kommen alle heim. Die übrigen Bewohner besetzen die Gebäude.", 20, Color(1, 1, 1, 0.6)))
	var tree := get_tree()
	for z in ZoneDefs.ZONES:
		var lit := Zones.is_lit(tree, z["id"])
		var head := UiStyle.label("%s – %s" % [z["name"], Zones.status_text(tree, z["id"])], 26,
				Color(1, 0.85, 0.5) if lit else Color(0.6, 0.6, 0.7))
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_box.add_child(head)
		if not z["wood"].is_empty():
			_box.add_child(_row(z["id"], "wood", "Holzfäller", lit))
		if not z["food"].is_empty():
			_box.add_child(_row(z["id"], "food", "Sammler", lit))
	_box.add_child(UiStyle.label(_building_text(), 22, Color(0.9, 0.85, 0.8)))


func _row(zone_id: String, kind: String, title: String, lit: bool) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var n: int = fortress.zone_jobs.get("%s:%s" % [zone_id, kind], 0)
	var name := UiStyle.label("   " + title + ("\n   (wartet am Feuer)" if n > 0 and not lit else ""), 24)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var minus := UiStyle.button("−", Color(1, 0.6, 0.4), 34, Vector2(80, 70))
	minus.disabled = n <= 0
	minus.pressed.connect(_change.bind(zone_id, kind, -1))
	row.add_child(minus)
	var val := UiStyle.label(str(n), 28, Color(1, 0.9, 0.6))
	val.custom_minimum_size = Vector2(70, 0)
	row.add_child(val)
	var plus := UiStyle.button("+", Color(0.5, 0.9, 0.5), 34, Vector2(80, 70))
	plus.disabled = fortress.zone_workers_total() >= fortress.residents.size()
	plus.pressed.connect(_change.bind(zone_id, kind, 1))
	row.add_child(plus)
	return row


func _change(zone_id: String, kind: String, delta: int) -> void:
	fortress.change_zone_job(zone_id, kind, delta)
	_rebuild()


## Welche Gebäude sind besetzt?
func _building_text() -> String:
	var parts := []
	for b in fortress.buildings:
		if b.built and b.needs_worker():
			parts.append("%s: %d/%d" % [b.display_name(), b.workers.size(), b.capacity()])
	if parts.is_empty():
		return "Gebäude: noch keine mit Arbeitsplatz gebaut."
	return "Gebäude – " + ", ".join(parts)
