## HUD (Anzeige am Bildschirm). Wächst mit jeder Etappe.
## Aktuell: Laternen-Balken oben rechts, Skill-Leiste unten (über den Touch-Knöpfen).
extends Control

@export var player: Node3D

const BAR_W := 230.0
const BAR_H := 26.0
const MARGIN := 16.0

var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var font := get_theme_default_font()
	var x := size.x - BAR_W - MARGIN
	var y := MARGIN + 6.0
	var lantern = player.lantern
	_draw_bar(font, x, y, "Laterne", lantern.fraction(), Color(1.0, 0.7, 0.3),
			lantern.refilling)
	_draw_skill_bar(font, player.skill_bar)


## Skill-Leiste: 3 Felder nebeneinander; ein Marker wandert während des Casts
## von links nach rechts über das aktuelle Feld.
func _draw_skill_bar(font: Font, bar: Node) -> void:
	var n: int = bar.slots.size()
	var slot_w := 130.0
	var slot_h := 100.0
	var gap := 14.0
	var total := n * slot_w + (n - 1) * gap
	var x0 := (size.x - total) / 2.0
	var y0 := size.y - 360.0
	var running: bool = bar.running

	# Hintergrund
	draw_rect(Rect2(x0 - 10, y0 - 10, total + 20, slot_h + 20), Color(0, 0, 0, 0.45))

	for i in n:
		var id: String = bar.slots[i]
		var r := Rect2(x0 + i * (slot_w + gap), y0, slot_w, slot_h)
		var col := SkillData.color(id)
		var is_current: bool = i == bar.index
		draw_rect(r, Color(col, 0.18 if id != "" else 0.06))
		if is_current and running and id != "":
			# Fortschritt des Casts als Füllung
			var fr: float = bar.fraction()
			draw_rect(Rect2(r.position, Vector2(r.size.x * fr, r.size.y)), Color(col, 0.45))
		var border := Color(1, 0.85, 0.5, 0.9) if is_current and running else Color(1, 1, 1, 0.25)
		draw_rect(r, border, false, 3.0 if is_current and running else 2.0)
		var label := SkillData.short_name(id) if id != "" else "leer"
		var fs := 26
		var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, r.position + Vector2((slot_w - ts.x) / 2.0, slot_h / 2.0 + 4),
				label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
				Color(1, 1, 1, 0.9 if id != "" else 0.35))
		if id != "":
			var ct := "%.1fs" % SkillData.cast_time(id)
			var cs := font.get_string_size(ct, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
			draw_string(font, r.position + Vector2((slot_w - cs.x) / 2.0, slot_h - 14), ct,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.5))

	# Marker: Dreieck über der Leiste
	var mx: float = x0 + bar.index * (slot_w + gap) + slot_w * (bar.fraction() if running else 0.0)
	var my := y0 - 14.0
	var mcol := Color(1, 0.85, 0.4) if running else Color(1, 1, 1, 0.3)
	draw_colored_polygon(PackedVector2Array([Vector2(mx - 11, my - 14), Vector2(mx + 11, my - 14),
			Vector2(mx, my + 2)]), mcol)
	draw_line(Vector2(mx, y0), Vector2(mx, y0 + slot_h), Color(mcol, 0.8 if running else 0.2), 3.0)

	# vorgemerkte Modifikatoren anzeigen
	if not bar.pending_mods.is_empty():
		var names := []
		for m in bar.pending_mods:
			names.append(SkillData.short_name(m))
		draw_string(font, Vector2(x0, y0 + slot_h + 34), "Vorgemerkt: " + ", ".join(names),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.7, 0.75, 1.0))
	elif not running:
		draw_string(font, Vector2(x0, y0 + slot_h + 34), "Leiste ruht – kein Gegner in der Nähe",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.4))


## Zeichnet einen beschrifteten Balken.
func _draw_bar(font: Font, x: float, y: float, label: String, frac: float, col: Color,
		pulse := false) -> void:
	draw_string(font, Vector2(x, y + 18), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(1, 1, 1, 0.8))
	var by := y + 26.0
	draw_rect(Rect2(x, by, BAR_W, BAR_H), Color(0, 0, 0, 0.6))
	var c := col
	if frac < 0.2:
		# fast leer: blinkt rot
		c = col.lerp(Color(1, 0.2, 0.1), 0.5 + 0.5 * sin(_t * 8.0))
	if pulse:
		c = c.lightened(0.25 + 0.2 * sin(_t * 10.0))
	draw_rect(Rect2(x + 2, by + 2, (BAR_W - 4) * frac, BAR_H - 4), c)
	draw_rect(Rect2(x, by, BAR_W, BAR_H), Color(1, 1, 1, 0.35), false, 2.0)
