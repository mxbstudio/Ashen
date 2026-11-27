## Gemeinsame Hilfen für große, handyfreundliche Knöpfe und Texte.
class_name UiStyle
extends RefCounted


static func box(col: Color, border := Color(1, 1, 1, 0.25), width := 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	return sb


static func button(text: String, col: Color, font_size := 28, min_size := Vector2(0, 90)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_stylebox_override("normal", box(Color(col, 0.35), Color(col, 0.8)))
	b.add_theme_stylebox_override("hover", box(Color(col, 0.45), Color(col, 1.0)))
	b.add_theme_stylebox_override("pressed", box(Color(col, 0.7), Color.WHITE, 3))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("disabled", box(Color(0.25, 0.25, 0.25, 0.35), Color(0.5, 0.5, 0.5, 0.4)))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.25))
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.focus_mode = Control.FOCUS_NONE
	return b


## Spalte für Anzeigen und Menüs: höchstens so breit wie ein Hochformat-Bildschirm (3:4 der Höhe), mittig.
## Auf Breitbild-Monitoren (z. B. 21:9) rückt so alles zusammen statt an die Ränder.
static func column(vp: Vector2) -> Rect2:
	var w := minf(vp.x, vp.y * 0.75)
	return Rect2((vp.x - w) / 2.0, 0.0, w, vp.y)


## Vollbild-Menü auf die Spalte begrenzen: linker/rechter Abstand = Rand der Spalte + margin.
static func fit_column(ctrl: Control, margin: float) -> void:
	var col := column(ctrl.get_viewport_rect().size)
	ctrl.offset_left = col.position.x + margin
	ctrl.offset_right = -(col.position.x + margin)


## Menü-Inhalt dauerhaft auf die Spalte begrenzen (wird laufend angepasst, auch bei Größenänderung).
static func keep_in_column(ctrl: Control, margin: float) -> void:
	ctrl.set_meta("col_margin", margin)
	ctrl.add_to_group("column_fit")


## Alle Menü-Inhalte an die Spalte anpassen (läuft jedes Bild, auch im Pausenzustand – siehe bar_toggle.gd).
static func update_columns(tree: SceneTree) -> void:
	for c in tree.get_nodes_in_group("column_fit"):
		if c.is_inside_tree():
			fit_column(c, c.get_meta("col_margin"))


## Echtes Handy/Tablet? (Dann keine Tasten-Hinweise.)
static func is_phone() -> bool:
	return OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("android") or OS.has_feature("ios")


## Tasten-Hinweis für den PC, z. B. "  [E]" (am Handy leer).
static func key_hint(key: String) -> String:
	return "" if is_phone() else "  [%s]" % key


## In scrollbaren Menüs: Knöpfe lassen das Wischen an die Scroll-Liste durch (sonst scrollt man am Handy nur
## über die schmale Leiste). Ein normales Antippen löst den Knopf weiter aus. Nach jedem Neuaufbau aufrufen.
static func pass_touch(root: Node) -> void:
	for b in root.find_children("*", "BaseButton", true, false):
		b.mouse_filter = Control.MOUSE_FILTER_PASS


static func label(text: String, font_size := 26, col := Color(1, 1, 1, 0.9)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Kurzbeschreibung eines Skills für Karten/Details.
static func skill_text(id: String) -> String:
	var d: Dictionary = SkillData.DEFS[id]
	var kind := "Angriff" if d["type"] == SkillData.ATTACK else "Modifikator"
	return "%s\n%s · %s · %.1f s\n%s" % [d["name"], kind, d.get("elem", ""), SkillData.cast_time(id), d["desc"]]
