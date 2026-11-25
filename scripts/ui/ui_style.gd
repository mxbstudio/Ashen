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
	b.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	b.add_theme_color_override("font_pressed_color", Color.WHITE)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.focus_mode = Control.FOCUS_NONE
	return b


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
	return "%s\n%s · %.1f s\n%s" % [d["name"], kind, SkillData.cast_time(id), d["desc"]]
