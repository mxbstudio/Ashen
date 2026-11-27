## Werte-Menü: wichtige Spielwerte im Spiel mit − / + verändern und sofort ausprobieren.
## "Änderungen anzeigen" listet alles auf, was vom Standard abweicht – zum Abschreiben
## oder Kopieren, damit wir die Werte danach fest in config.gd übernehmen.
## Pausiert das Spiel, solange es offen ist. Gilt bis zum Schließen des Browsers
## (auch "Neu starten" behält die eingestellten Werte).
extends Control

@export var touch_controls: Control

## [Anzeigename, Wert in Config (oder "sfx"), Minimum, Maximum, Schritt, Hinweis]
## Einträge mit nur einem Text sind Überschriften.
const ENTRIES := [
	["Feuer & Vorräte"],
	["Holz am Start", "fire_wood_start", 5, 60, 5, "ab Neustart"],
	["Nahrung am Start", "food_start", 5, 60, 5, "ab Neustart"],
	["Feuer: Sekunden pro Holz", "fire_seconds_per_wood", 5, 60, 5, ""],
	["Nahrung: Sekunden pro Bewohner", "food_seconds_per_person", 20, 180, 5, ""],
	["Lager: Holz ohne Vorratslager", "wood_cap", 10, 100, 5, ""],
	["Lager: Nahrung ohne Vorratslager", "food_cap", 10, 100, 5, ""],
	["Bewohner"],
	["Bewohner am Start", "residents_start", 1, 12, 1, "ab Neustart"],
	["Neuer Bewohner alle … s", "survivor_interval", 60, 900, 30, ""],
	["Bewohner höchstens", "residents_max", 3, 20, 1, ""],
	["Bewohner: Leben", "resident_hp", 5, 100, 5, ""],
	["Schaden an Bewohnern ×", "resident_damage_factor", 0.0, 2.0, 0.1, "0 = harmlos"],
	["Arbeiter: Einheiten pro Gang", "worker_carry", 1, 8, 1, ""],
	["Arbeiter: Sekunden pro Einheit", "worker_gather_seconds", 1, 15, 0.5, ""],
	["Arbeiter: Tempo m/s", "worker_speed", 1, 6, 0.2, ""],
	["Draußen: Holz & Pilze"],
	["Holz pro Baum", "tree_wood", 5, 100, 5, "neue Bäume"],
	["Baum wächst nach … s", "tree_regrow", 60, 1200, 30, ""],
	["Nahrung pro Pilzstelle", "food_per_node", 1, 20, 1, "nach Nachwachsen"],
	["Pilze wachsen nach … s", "resource_regrow", 30, 600, 15, ""],
	["Stein pro Felsen", "rock_stone", 2, 50, 1, "nach Nachwachsen"],
	["Hüter: Trage", "carry_capacity", 0, 30, 1, ""],
	["Fackeln"],
	["Kleine Fackel: Brenndauer s", "small_torch_seconds", 30, 600, 15, "neue Fackeln"],
	["Kleine Fackel: Lichtradius m", "small_torch_radius", 2, 10, 0.5, ""],
	["Feuerstelle: Stein", "firepit_stone_cost", 1, 30, 1, ""],
	["Feuerstelle: Lichtradius m", "firepit_light_radius", 4, 15, 1, ""],
	["Feuerstelle: Sekunden pro Holz", "firepit_seconds_per_wood", 20, 300, 10, ""],
	["Fackel: Holz zum Errichten", "torch_build_cost", 1, 15, 1, ""],
	["Fackel: Sekunden pro Holz", "torch_seconds_per_wood", 20, 300, 10, ""],
	["Fackel: Lichtradius m", "torch_light_radius", 4, 14, 1, ""],
	["Lichtfresser-Raubzug alle … s", "torch_raid_interval", 15, 240, 15, ""],
	["Gebäude"],
	["Pilzkeller: Sekunden pro Nahrung", "mushroom_seconds_per_food", 10, 120, 5, ""],
	["Trümmerhof: Sekunden pro Holz", "scrapyard_seconds_per_wood", 10, 120, 5, ""],
	["Werkstatt: Sekunden pro Bogen", "bow_craft_seconds", 10, 300, 10, ""],
	["Bogen: Holz", "bow_wood_cost", 1, 20, 1, ""],
	["Bewohner-Bogen: Schaden", "resident_bow_damage", 1, 30, 1, ""],
	["Gebäude Stufe 2: Holz", "upgrade_cost_2", 2, 40, 1, ""],
	["Gebäude Stufe 3: Holz", "upgrade_cost_3", 2, 60, 1, ""],
	["Belagerung"],
	["Belagerung alle … s", "siege_interval", 60, 900, 30, "ab der nächsten"],
	["Angreifer pro Belagerung", "siege_size", 4, 50, 2, ""],
	["Torleben", "gate_health", 50, 600, 25, "ab der nächsten Reparatur"],
	["Gegner & Kampf"],
	["Max. Gegner gleichzeitig", "max_enemies", 4, 30, 2, "Leistung!"],
	["Nachschub alle … s", "spawn_interval", 1.0, 10.0, 0.5, ""],
	["Kriecher-Schaden", "crawler_damage", 1, 20, 1, "neue Gegner"],
	["Verlorener-Schaden", "lost_damage", 5, 60, 1, "neue Gegner"],
	["Boss-Leben", "hp_boss", 200, 3000, 100, "ab Neustart"],
	["Sichelhieb-Schaden", "sickle_damage", 4, 40, 1, ""],
	["Bogenschuss-Schaden", "bow_damage", 3, 30, 1, ""],
	["EP für Stufe 2", "xp_first_level", 2, 40, 1, ""],
	["EP mehr pro Stufe", "xp_level_step", 0, 30, 1, ""],
	["Leiste & Talismane (v0.3)"],
	["Erschüttert: Dauer s", "stagger_time", 0.5, 6, 0.5, ""],
	["Zerschmettern: Schaden ×", "combo_shatter", 1.0, 4.0, 0.25, ""],
	["Markiert: +Schaden", "mark_bonus", 0.0, 1.5, 0.05, "0,35 = +35 %"],
	["Schwur: Runden-Bonus", "oath_bonus", 0.0, 1.0, 0.05, ""],
	["Spiegel: Kopie-Schaden", "mirror_copy", 0.2, 1.0, 0.05, ""],
	["Talisman von Verlorenen: Chance", "lost_talisman_chance", 0.0, 1.0, 0.01, ""],
	["Wahnsinn (v0.3)"],
	["Wahn pro s im Dunkeln", "madness_dark_rate", 0.0, 1.0, 0.05, ""],
	["Wahn extra bei schwacher Laterne", "madness_low_lantern_rate", 0.0, 2.0, 0.05, ""],
	["Wahn sinkt am Feuer pro s", "madness_fire_recover", 0.0, 3.0, 0.1, ""],
	["Schaden je Wahn-Stufe", "madness_damage_per_stage", 0.0, 0.5, 0.05, ""],
	["Dunkle Skills ab Wahn", "madness_dark_offer", 0, 100, 5, ""],
	["Bewohner-Stimmung (v0.3)"],
	["Stimmung: Tempo pro s", "mood_rate", 0.02, 1.0, 0.02, ""],
	["Stimmung: Verlust bei Tod", "mood_on_death", 0, 40, 2, ""],
	["Verlassen unter Stimmung", "desert_mood", 0, 50, 5, "0 = nie"],
	["Ereignis alle … s", "event_interval", 60, 900, 30, ""],
	["Sicht"],
	["Sicht an (1) / aus (0)", "sight_enabled", 0, 1, 1, "0 = alle Gegner sichtbar"],
	["Im Dunkeln ganz sichtbar bis m", "sight_near", 0, 10, 0.5, ""],
	["Hüter & Technik"],
	["Laterne: Brenndauer s", "lantern_burn_time", 60, 480, 20, ""],
	["Laufgeschwindigkeit", "player_speed", 3.0, 10.0, 0.5, ""],
	["Kamera-Breite m", "camera_width", 8, 26, 1, ""],
	["Lautstärke dB", "sfx", -30, 6, 2, ""],
]

var _box: VBoxContainer
var _value_labels := {}
var _changes_label: Label
var _menu_button: Button


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
	_box.add_child(UiStyle.label("Werte einstellen", 40, Color(1, 0.8, 0.45)))
	_box.add_child(UiStyle.label("Mit − / + ändern, dann „Weiter“ und ausprobieren.", 22, Color(1, 1, 1, 0.6)))
	for e in ENTRIES:
		if e.size() == 1:
			var h := UiStyle.label(e[0], 30, Color(1, 0.75, 0.4))
			h.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_box.add_child(h)
		else:
			_box.add_child(_row(e))
	var show := UiStyle.button("Änderungen anzeigen / kopieren", Color(0.5, 0.7, 1.0), 24, Vector2(0, 80))
	show.pressed.connect(_show_changes)
	_box.add_child(show)
	_changes_label = UiStyle.label("", 22, Color(0.8, 0.9, 1.0))
	_box.add_child(_changes_label)
	var reset := UiStyle.button("Alles auf Standard", Color(0.7, 0.7, 0.7), 24, Vector2(0, 80))
	reset.pressed.connect(_reset_all)
	_box.add_child(reset)
	UiStyle.pass_touch(_box)
	# fester "Weiter"-Knopf unten
	var done := UiStyle.button("Weiter", Color(0.5, 0.9, 0.5), 32, Vector2(0, 100))
	done.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	done.offset_left = 24
	done.offset_right = -24
	done.offset_top = -130
	done.offset_bottom = -30
	done.pressed.connect(close)
	add_child(done)
	# kleiner Knopf oben in der Mitte zum Öffnen
	_menu_button = UiStyle.button("Werte", Color(0.7, 0.7, 0.8), 20, Vector2(110, 54))
	_menu_button.add_to_group("touch_blockers")
	_menu_button.pressed.connect(open)
	add_sibling.call_deferred(_menu_button)


func _process(_delta: float) -> void:
	if _menu_button.is_inside_tree():
		var vp := get_viewport_rect().size
		_menu_button.position = Vector2((vp.x - _menu_button.size.x) / 2.0 + 10.0, 6)
		var show := not get_tree().paused
		if _menu_button.visible != show:
			_menu_button.visible = show


func _row(e: Array) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var name := UiStyle.label(e[0] + ("\n(%s)" % e[5] if e[5] != "" else ""), 22)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name)
	var minus := UiStyle.button("−", Color(1, 0.6, 0.4), 34, Vector2(80, 70))
	minus.pressed.connect(_step.bind(e, -1))
	row.add_child(minus)
	var val := UiStyle.label(_fmt(_read_value(e[1])), 26, Color(1, 0.9, 0.6))
	val.custom_minimum_size = Vector2(110, 0)
	row.add_child(val)
	_value_labels[e[1]] = val
	var plus := UiStyle.button("+", Color(0.5, 0.9, 0.5), 34, Vector2(80, 70))
	plus.pressed.connect(_step.bind(e, 1))
	row.add_child(plus)
	return row


func _read_value(key: String) -> float:
	return Sfx.volume_db if key == "sfx" else float(Config.get(key))


func _write_value(key: String, v: float) -> void:
	if key == "sfx":
		Sfx.volume_db = v
		Sfx.play("pickup", 0.0, 0.0)
		return
	var old = Config.get(key)
	if typeof(old) == TYPE_BOOL:
		Config.set(key, v > 0.5)
	else:
		Config.set(key, int(v) if typeof(old) == TYPE_INT else v)
	Config.keep_as_default(key)


func _fmt(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v


func _step(e: Array, dir: int) -> void:
	var v := clampf(_read_value(e[1]) + e[4] * dir, e[2], e[3])
	_write_value(e[1], v)
	_value_labels[e[1]].text = _fmt(_read_value(e[1]))
	_changes_label.text = ""


func open() -> void:
	touch_controls.reset()
	get_tree().paused = true
	visible = true
	for e in ENTRIES:
		if e.size() > 1:
			_value_labels[e[1]].text = _fmt(_read_value(e[1]))


func close() -> void:
	visible = false
	get_tree().paused = false
	Config.save_settings({"sfx": Sfx.volume_db})   # Werte im Browser merken


## Alles auflisten, was vom ursprünglichen Standard abweicht.
func _show_changes() -> void:
	var lines := []
	for e in ENTRIES:
		if e.size() == 1:
			continue
		var now := _read_value(e[1])
		var orig: float = -6.0 if e[1] == "sfx" else float(Config.original(e[1]))
		if not is_equal_approx(now, orig):
			lines.append("%s: %s → %s" % [e[0], _fmt(orig), _fmt(now)])
	var text := "Keine Änderungen." if lines.is_empty() else "\n".join(lines)
	_changes_label.text = text.replace("→", "->")
	DisplayServer.clipboard_set("Aschen Werte:\n" + text)
	if not lines.is_empty():
		_changes_label.text += "\n(in die Zwischenablage kopiert)"


func _reset_all() -> void:
	for e in ENTRIES:
		if e.size() == 1:
			continue
		if e[1] == "sfx":
			Sfx.volume_db = -6.0
		else:
			Config.set(e[1], Config.original(e[1]))
			Config.keep_as_default(e[1])
		_value_labels[e[1]].text = _fmt(_read_value(e[1]))
	_changes_label.text = "Auf Standard zurückgesetzt."
	Config.save_settings()
