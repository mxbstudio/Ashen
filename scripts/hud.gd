## HUD (Anzeige am Bildschirm). Wächst mit jeder Etappe.
## Oben rechts: Leben, Laterne, Tränke. Unten: Skill-Leiste (über den Touch-Knöpfen).
## Roter Bildschirmrand bei Treffern, Todesbildschirm.
extends Control

@export var player: Node3D
@export var fortress: Node3D
@export var siege: Node

var _bell_flash := 0.0

const BAR_W := 230.0
const BAR_H := 26.0
const MARGIN := 16.0

var _t := 0.0
var _slot_flash := {}      # Feld-Nummer -> Restzeit des Aufblitzens
var _popups: Array = []    # [text, farbe, restzeit] – Skillname, der beim Auslösen aufsteigt
var _toasts: Array = []    # [text, restzeit] – kurze Meldungen in der Bildschirmmitte
const FLASH_TIME := 0.3
const POPUP_TIME := 0.7


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("hud")
	if fortress:
		fortress.message.connect(toast)
	if player:
		player.skill_bar.skill_fired.connect(_on_skill_fired)


## Wird aufgerufen, sobald ein Skill ausgelöst wird (Feld war voll).
## Die Glocke läutet: kurzer heller Blitz über den ganzen Bildschirm.
func bell() -> void:
	_bell_flash = 1.0


## Kurze Meldung in der Bildschirmmitte (z. B. "Abgeladen: +5 Holz").
func toast(text: String, duration := 2.5) -> void:
	_toasts.append([text, duration])
	if _toasts.size() > 4:
		_toasts.pop_front()


func _on_skill_fired(id: String, slot: int) -> void:
	_slot_flash[slot] = FLASH_TIME
	_popups.append([SkillData.DEFS[id]["name"] + "!", SkillData.color(id), POPUP_TIME])


func _process(delta: float) -> void:
	_t += delta
	_bell_flash = maxf(_bell_flash - delta * 1.5, 0.0)
	for k in _slot_flash.keys():
		_slot_flash[k] -= delta
		if _slot_flash[k] <= 0.0:
			_slot_flash.erase(k)
	for p in _popups:
		p[2] -= delta
	_popups = _popups.filter(func(p): return p[2] > 0.0)
	for t in _toasts:
		t[1] -= delta
	_toasts = _toasts.filter(func(t): return t[1] > 0.0)
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var font := get_theme_default_font()
	var x := size.x - BAR_W - MARGIN
	var y := MARGIN + 6.0
	var lantern = player.lantern
	_draw_bar(font, x, y, "Leben  %d" % ceili(player.health),
			player.health / Config.player_max_health, Color(0.85, 0.2, 0.18))
	y += 62.0
	_draw_bar(font, x, y, "Laterne", lantern.fraction(), Color(1.0, 0.7, 0.3),
			lantern.refilling)
	y += 62.0
	draw_string(font, Vector2(x, y + 22), "Tränke: %d / %d" % [player.potions, Config.potions_start],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.6, 1.0, 0.6, 0.9))
	y += 34.0
	draw_string(font, Vector2(x, y + 22), "Stufe %d" % player.level,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.8, 1.0, 0.9))
	var xr := Rect2(x + 90, y + 8, BAR_W - 90, 14)
	draw_rect(xr, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(xr.position, Vector2(xr.size.x * float(player.xp) / player.xp_for_next_level(), xr.size.y)),
			Color(0.65, 0.6, 1.0))
	y += 34.0
	var load_txt := "Trage %d/%d" % [player.carry_total(), Config.carry_capacity]
	if player.carry_total() > 0:
		load_txt += ": %d Holz, %d Nahr." % [player.carry["wood"], player.carry["food"]]
	draw_string(font, Vector2(x - 40, y + 22), load_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 20,
			Color(1, 0.85, 0.6, 0.9) if player.carry_total() < Config.carry_capacity else Color(1, 0.5, 0.3))
	if not player.skill_bar.stash.is_empty():
		y += 34.0
		draw_string(font, Vector2(x, y + 22), "Vorrat: %d Skill(s)" % player.skill_bar.stash.size(),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.85, 0.5, 0.9))
	_draw_fortress(font)
	_draw_pointers(font)
	_draw_siege(font)
	_draw_boss(font)
	_draw_toasts(font)
	_draw_skill_bar(font, player.skill_bar)
	_draw_hurt(player.hurt_flash)
	if not player.is_alive():
		_draw_death(font)


## Roter Rand, wenn der Hüter getroffen wird.
func _draw_hurt(v: float) -> void:
	if v <= 0.0:
		return
	var a := clampf(v / 0.35, 0.0, 1.0) * 0.45
	var t := 40.0
	var c := Color(0.8, 0.05, 0.02, a)
	draw_rect(Rect2(0, 0, size.x, t), c)
	draw_rect(Rect2(0, size.y - t, size.x, t), c)
	draw_rect(Rect2(0, 0, t, size.y), c)
	draw_rect(Rect2(size.x - t, 0, t, size.y), c)


func _draw_death(font: Font) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.7))
	var lines := ["Das Licht verlässt dich …", "%d Sekunden vergehen." % int(Config.death_time_loss),
			"Du erwachst am Feuer."]
	for i in lines.size():
		var fs := 40 if i == 0 else 28
		var ts := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, Vector2((size.x - ts.x) / 2.0, size.y * 0.42 + i * 56), lines[i],
				HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.7, 0.4, 0.95))


## Skill-Leiste: 3 Felder nebeneinander; ein Marker wandert während des Casts
## von links nach rechts über das aktuelle Feld.
func _draw_skill_bar(font: Font, bar: Node) -> void:
	var n: int = bar.slots.size()
	var gap := 12.0
	var slot_w := minf(130.0, (size.x - 40.0 - gap * (n - 1)) / n)
	var slot_h := 100.0
	var total := n * slot_w + (n - 1) * gap
	var x0 := (size.x - total) / 2.0
	var y0 := size.y - 360.0
	var running: bool = bar.running

	# Hintergrund
	draw_rect(Rect2(x0 - 10, y0 - 10, total + 20, slot_h + 20), Color(0, 0, 0, 0.45))

	for i in n:
		var id: String = bar.slots[i]
		var r := Rect2(x0 + i * (slot_w + gap), y0, slot_w, slot_h)
		var flash: float = _slot_flash.get(i, 0.0) / FLASH_TIME   # 1 -> 0
		if flash > 0.0:
			r = r.grow(10.0 * flash)   # Feld springt beim Auslösen kurz größer
		var col := SkillData.color(id)
		var is_current: bool = i == bar.index
		draw_rect(r, Color(col, 0.18 if id != "" else 0.06))
		if is_current and running and id != "":
			# Fortschritt des Casts als Füllung
			var fr: float = bar.fraction()
			draw_rect(Rect2(r.position, Vector2(r.size.x * fr, r.size.y)), Color(col, 0.45))
		if flash > 0.0:
			draw_rect(r, Color(1, 1, 1, 0.75 * flash))
		var border := Color(1, 0.85, 0.5, 0.9) if is_current and running else Color(1, 1, 1, 0.25)
		draw_rect(r, border, false, 3.0 if is_current and running else 2.0)
		var label := SkillData.short_with_level(id, bar.level_of(id)) if id != "" else "leer"
		var fs := 26 if slot_w >= 125.0 else 22
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

	# Skillname steigt beim Auslösen über der Leiste auf
	for p in _popups:
		var k: float = 1.0 - p[2] / POPUP_TIME
		var txt: String = p[0]
		var ps := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 34)
		draw_string_outline(font, Vector2((size.x - ps.x) / 2.0, y0 - 40 - k * 50), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 8, Color(0, 0, 0, 1.0 - k))
		draw_string(font, Vector2((size.x - ps.x) / 2.0, y0 - 40 - k * 50), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(p[1].lightened(0.3), 1.0 - k))

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


## Festung oben links: Holz im Feuer (mit Restzeit), Nahrung, Bewohner.
func _draw_fortress(font: Font) -> void:
	if fortress == null:
		return
	var x := MARGIN
	var y := 40.0
	draw_rect(Rect2(x - 6, y - 4, 300, 118), Color(0, 0, 0, 0.4))
	var secs := int(fortress.wood_seconds_left())
	var low_wood: bool = fortress.wood < 5
	var blink := 0.5 + 0.5 * sin(_t * 8.0)
	var wood_col := Color(1, 0.7, 0.35) if not low_wood else Color(1, 0.25, 0.15).lerp(Color(1, 0.7, 0.35), blink)
	var fire_txt := "Feuer: %d Holz  (%d:%02d)" % [int(fortress.wood), secs / 60, secs % 60]
	if siege and siege.omen_active():
		# Vorzeichen: Feuerzeile flackert unruhig (kein Countdown)
		fire_txt = "Feuer flackert …  %d Holz" % int(fortress.wood)
		var jitter := absf(sin(_t * 13.0) * sin(_t * 5.0))
		wood_col = Color(1, 0.45, 0.15, 0.35 + 0.65 * jitter)
	draw_string(font, Vector2(x, y + 24), fire_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, wood_col)
	var low_food: bool = fortress.food < 3
	var food_col := Color(0.6, 1, 0.85) if not low_food else Color(1, 0.25, 0.15).lerp(Color(0.6, 1, 0.85), blink)
	draw_string(font, Vector2(x, y + 60), "Nahrung: %d / %d" % [int(fortress.food), fortress.food_cap()],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, food_col)
	draw_string(font, Vector2(x, y + 96), "Bewohner: %d" % fortress.residents.size(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.9, 0.85, 0.8))


func _draw_toasts(font: Font) -> void:
	var y := size.y * 0.3
	for t in _toasts:
		var a := clampf(t[1], 0.0, 1.0)
		var txt: String = t[0]
		var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
		var px := (size.x - ts.x) / 2.0
		draw_rect(Rect2(px - 14, y - 30, ts.x + 28, 42), Color(0, 0, 0, 0.55 * a))
		draw_string(font, Vector2(px, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1, 0.9, 0.7, a))
		y += 50.0


## Während der Belagerung: Torleben und verbleibende Angreifer (oben Mitte).
func _draw_siege(font: Font) -> void:
	if _bell_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.85, 0.6, 0.35 * _bell_flash))
	if siege == null or not siege.active:
		return
	var gate: Node3D = siege.gate
	var w := 360.0
	var x := (size.x - w) / 2.0
	var y := 300.0
	var title := "LETZTE BELAGERUNG" if siege.is_final else "BELAGERUNG"
	var ts := font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
	draw_string(font, Vector2((size.x - ts.x) / 2.0, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 28,
			Color(1, 0.35, 0.25).lerp(Color(1, 0.8, 0.5), 0.5 + 0.5 * sin(_t * 5.0)))
	_draw_bar_at(font, x, y + 10, w, "Tor  %d / %d" % [ceili(gate.hp), int(Config.gate_health)],
			gate.hp / Config.gate_health, Color(0.75, 0.5, 0.3))
	draw_string(font, Vector2(x, y + 82), "Angreifer: %d" % siege.attackers_left(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.8))


## Lebensbalken des Bosses, sobald er kämpft.
func _draw_boss(font: Font) -> void:
	var boss := get_tree().get_first_node_in_group("boss")
	if boss == null or not boss.is_engaged():
		return
	var w := size.x - 80.0
	_draw_bar_at(font, 40.0, 280.0, w, "Der verwandelte Hauptmann",
			boss.hp / boss.max_hp, Color(0.7, 0.15, 0.2))


func _draw_bar_at(font: Font, x: float, y: float, w: float, label: String, frac: float, col: Color) -> void:
	draw_string(font, Vector2(x, y + 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.85))
	var by := y + 28.0
	draw_rect(Rect2(x, by, w, 22), Color(0, 0, 0, 0.65))
	draw_rect(Rect2(x + 2, by + 2, (w - 4) * clampf(frac, 0.0, 1.0), 18), col)
	draw_rect(Rect2(x, by, w, 22), Color(1, 1, 1, 0.35), false, 2.0)


## Wegweiser am Bildschirmrand: zum Tor (orange) und zum Leuchtfeuer (blau),
## wenn sie gerade nicht im Bild sind und der Hüter draußen ist.
func _draw_pointers(font: Font) -> void:
	if not player.is_alive() or player.global_position.z > -11.0:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	_pointer(font, cam, Vector3(0, 0, -12), "Tor", Color(1, 0.7, 0.3))
	var beacon := get_tree().get_first_node_in_group("beacon")
	if beacon and beacon.lit:
		_pointer(font, cam, beacon.global_position, "Leuchtfeuer", Color(0.6, 0.8, 1.0))


func _pointer(font: Font, cam: Camera3D, world: Vector3, label: String, col: Color) -> void:
	var p := cam.unproject_position(world)
	var inner := Rect2(Vector2(70, 230), size - Vector2(140, 230 + 420))
	if inner.grow(60).has_point(p):
		return   # sichtbar genug, kein Pfeil nötig
	var center := size / 2.0
	var dir := (p - center).normalized()
	# Schnittpunkt mit dem inneren Rechteck
	var t := INF
	if dir.x != 0.0:
		t = minf(t, ((inner.end.x if dir.x > 0 else inner.position.x) - center.x) / dir.x)
	if dir.y != 0.0:
		t = minf(t, ((inner.end.y if dir.y > 0 else inner.position.y) - center.y) / dir.y)
	var at := center + dir * t
	var side := Vector2(-dir.y, dir.x)
	var pts := PackedVector2Array([at + dir * 26.0, at - dir * 10.0 + side * 18.0, at - dir * 10.0 - side * 18.0])
	draw_colored_polygon(pts, Color(col, 0.85))
	var ts := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
	var lp := at - dir * 40.0 - Vector2(ts.x / 2.0, -6)
	draw_string_outline(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 6, Color(0, 0, 0, 0.8))
	draw_string(font, lp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
