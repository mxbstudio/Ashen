## HUD (Anzeige am Bildschirm). Wächst mit jeder Etappe.
## Aktuell: Laternen-Balken oben rechts.
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
