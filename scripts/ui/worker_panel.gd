## Bewohner einteilen – überall über den Knopf „Bewohner“ oben links (Spiel pausiert solange).
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
	UiStyle.keep_in_column(scroll, 24)
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
	UiStyle.keep_in_column(done, 24)
	done.offset_top = -130
	done.offset_bottom = -30
	done.pressed.connect(close)
	add_child(done)
	# Knopf "Bewohner" oben links neben "Leiste" – überall erreichbar
	_open_button = UiStyle.button("Bewohner" + UiStyle.key_hint("B"), Color(0.6, 0.9, 0.7), 22, Vector2(150, 58))
	_open_button.add_to_group("touch_blockers")
	_open_button.pressed.connect(open)
	_open_button.visible = false
	add_sibling.call_deferred(_open_button)


## Wichtig: Sichtbarkeit nur ändern, wenn nötig – sonst geht ein Fingertipp verloren.
func _process(_delta: float) -> void:
	var show: bool = player.is_alive() and not visible and not get_tree().paused
	if _open_button.visible != show:
		_open_button.visible = show
	_open_button.position = Vector2(UiStyle.column(get_viewport_rect().size).position.x + 150, 236)


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
	var free: int = fortress.free_count()
	_box.add_child(UiStyle.label("Bewohner einteilen", 40, Color(0.7, 1, 0.8)))
	_box.add_child(UiStyle.label("Bewohner: %d · frei: %d" % [total, free], 28,
			Color(0.6, 1, 0.6) if free > 0 else Color(1, 0.9, 0.7)))
	var h: Dictionary = fortress.helpers()
	if not h.is_empty():
		var parts := []
		for k in h:
			parts.append("%d %s" % [h[k], {"wood": "Holz", "food": "Nahrung", "stone": "Stein"}[k]])
		_box.add_child(UiStyle.label("davon helfen selbstständig: " + ", ".join(parts), 22, Color(0.7, 0.95, 0.7)))
	_box.add_child(UiStyle.label("Einteilen geht nur mit freien Bewohnern – mit „−“ machst du jemanden frei. "
			+ "Freie Bewohner besetzen neue Gebäudeplätze von selbst. Zonen: Arbeit nur, solange die Zone hell ist, "
			+ "sonst warten sie am Feuer. Draußen im Dunkeln greifen Kriecher an – mit Bogen wehren sie sich. "
			+ "Bei Belagerung kommen alle heim. Freie Bewohner helfen selbstständig, wo das Lager etwas braucht; "
			+ "Gebäude ruhen, solange ihr Lager voll ist (ihre Arbeiter helfen dann woanders).", 20, Color(1, 1, 1, 0.6)))
	_box.add_child(_bow_row())
	_box.add_child(_tools())
	_box.add_child(_people())
	_box.add_child(_section("Gebäude"))
	var any := false
	for b in fortress.buildings:
		if b.built and b.needs_worker():
			any = true
			_box.add_child(_building_row(b, free))
	if not any:
		_box.add_child(UiStyle.label("Noch keine Gebäude mit Arbeitsplätzen gebaut.", 22, Color(1, 1, 1, 0.5)))
	_box.add_child(_section("Zonen draußen"))
	var tree := get_tree()
	for z in ZoneDefs.ZONES:
		var lit := Zones.is_lit(tree, z["id"])
		var head := UiStyle.label("%s – %s" % [z["name"], Zones.status_text(tree, z["id"])], 26,
				Color(1, 0.85, 0.5) if lit else Color(0.6, 0.6, 0.7))
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_box.add_child(head)
		if z["trees"] > 0:
			_box.add_child(_row(z["id"], "wood", "Holzfäller", lit))
		if not z["food"].is_empty():
			_box.add_child(_row(z["id"], "food", "Sammler", lit))
		if z.get("rocks", 0) > 0:
			_box.add_child(_row(z["id"], "stone", "Steinbrecher", lit))
	UiStyle.pass_touch(_box)


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
	plus.disabled = fortress.free_count() <= 0
	plus.pressed.connect(_change.bind(zone_id, kind, 1))
	row.add_child(plus)
	return row


func _change(zone_id: String, kind: String, delta: int) -> void:
	fortress.change_zone_job(zone_id, kind, delta)
	_rebuild()


func _section(text: String) -> Label:
	var l := UiStyle.label(text, 30, Color(1, 0.75, 0.4))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


## Gebäude: Arbeiter mit − / + (höchstens so viele, wie es Plätze gibt).
func _building_row(b: Node3D, free: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var places := "1 Platz" if b.capacity() == 1 else "%d Plätze" % b.capacity()
	var title := "   %s (%s)" % [b.display_name(), places]
	if b.resting:
		title += "\n   ruht – %s" % b.rest_reason()
	var name := UiStyle.label(title, 24)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var minus := UiStyle.button("−", Color(1, 0.6, 0.4), 34, Vector2(80, 70))
	var count: int = b.wanted_workers() if b.resting else b.workers.size()
	minus.disabled = count <= 0
	minus.pressed.connect(func(): fortress.change_building_workers(b, -1); _rebuild())
	row.add_child(minus)
	var val := UiStyle.label(str(count), 28, Color(1, 0.9, 0.6) if not b.resting else Color(0.6, 0.6, 0.7))
	val.custom_minimum_size = Vector2(70, 0)
	row.add_child(val)
	var plus := UiStyle.button("+", Color(0.5, 0.9, 0.5), 34, Vector2(80, 70))
	plus.disabled = free <= 0 or count >= b.capacity()
	plus.pressed.connect(func(): fortress.change_building_workers(b, 1); _rebuild())
	row.add_child(plus)
	return row


## Bögen verteilen: wie viele Bewohner tragen einen (wer draußen arbeitet, zuerst)?
func _bow_row() -> Control:
	var col := VBoxContainer.new()
	var total: int = fortress.bows_total()
	var head := UiStyle.label("Bögen: %d gebaut – %s" % [total,
			"Werkstatt baut weitere" if _has_workshop() else "Werkstatt bauen, um Bögen herzustellen"], 24, Color(0.9, 0.8, 1.0))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(head)
	var info := UiStyle.label("   Bewohner mit Bogen: %d von %d – freie Bögen holen sie sich selbst (wer draußen arbeitet, zuerst)"
			% [fortress.armed_count(), fortress.residents.size()], 22)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(info)
	return col


func _has_workshop() -> bool:
	for b in fortress.buildings:
		if b.kind == "workshop" and b.built:
			return true
	return false


## Die Leute: Name, Eigenschaften, Stimmung, Arbeit, Verbindungen (v0.3).
func _people() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	col.add_child(_section("Leute – Stimmung Ø %d (%s)" % [roundi(fortress.average_mood()),
			ResidentData.mood_word(fortress.average_mood())]))
	for r in fortress.residents:
		var traits := []
		for t in r.traits:
			traits.append("%s (%s)" % [ResidentData.trait_name(t), ResidentData.trait_desc(t)])
		var line := "%s · %s %d" % [r.res_name, ResidentData.mood_word(r.mood), roundi(r.mood)]
		var extra := []
		extra.append(_job_text(r))
		if r.bond_name != "":
			extra.append("%s mit %s" % [r.bond_kind, r.bond_name])
		if r.grief > 0.0:
			extra.append("trauert")
		if r.refuses():
			extra.append("hat Angst, hinauszugehen")
		var l := UiStyle.label("%s\n   %s\n   %s" % [line, ", ".join(traits), " · ".join(extra)], 20,
				ResidentData.mood_color(r.mood))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(l)
	for a in fortress.away:
		var l := UiStyle.label("%s · unterwegs in der Dunkelheit …" % a[0].get("name", "?"), 20, Color(0.7, 0.7, 0.85))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(l)
	if not fortress.graves.is_empty():
		var names: Array = fortress.graves.map(func(g): return str(g[0]))
		var l := UiStyle.label("Gräber (%d): %s" % [names.size(), ", ".join(names)], 20, Color(0.7, 0.7, 0.75))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(l)
	col.add_child(UiStyle.label("Stimmung: satt, sicheres Feuer und Prediger heben sie; Hunger, Tote und der Wahn des Hüters "
			+ "drücken sie. Zuversichtliche arbeiten schneller, Verzweifelte langsamer – und verlassen vielleicht die Festung.",
			18, Color(1, 1, 1, 0.5)))
	return col


func _job_text(r: Node3D) -> String:
	if r.job:
		return r.job.display_name()
	if r.has_zone_job():
		var k: String = {"wood": "Holzfäller", "food": "Sammler", "stone": "Steinbrecher"}.get(r.zone_kind, "")
		return "%s %s%s" % [k, Zones.zone_name(r.zone_id), " (selbstständig)" if r.auto_job else ""]
	return "frei"


## Werkzeuge: schneller abbauen (Hüter und Bewohner). Stellt die Werkstatt her – höchstens bis zu ihrer Stufe.
func _tools() -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.add_child(_section("Werkzeuge (aus der Werkstatt)"))
	for kind in ["wood", "stone", "food"]:
		var lvl: int = fortress.tools[kind]
		var name: String = fortress.TOOL_NAMES[kind]
		var verb: String = fortress.TOOL_VERBS[kind]
		var now := "%s Stufe %d" % [name, lvl] if lvl > 0 else "%s: keine" % name
		var text: String
		var block: String = fortress.tool_blocker(kind)
		if lvl >= 3:
			text = "%s – %s %d %% schneller (höchste Stufe)" % [now, verb, roundi((1.0 / fortress.tool_factor(kind) - 1.0) * 100)]
		else:
			var faster := roundi(Config.tool_speed_per_level * (lvl + 1) * 100)
			text = "%s → Stufe %d: %s %d %% schneller\n%d Holz, %d Stein%s" % [now, lvl + 1, verb, faster,
					Config.tool_cost_wood[lvl], Config.tool_cost_stone[lvl], "" if block == "" else "  (" + block + ")"]
		var b := UiStyle.button(text, Color(0.85, 0.75, 0.5), 20, Vector2(0, 84))
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = block != ""
		b.pressed.connect(func(): fortress.upgrade_tool(kind); _rebuild())
		col.add_child(b)
	return col
