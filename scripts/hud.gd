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


## Spielstand wurde gespeichert: kurz "gespeichert" einblenden.
var _saved_t := 0.0
func saved_flash() -> void:
	_saved_t = 1.5


## Flüstern des Wahns: violette Schrift an zufälliger Stelle, verblasst langsam.
var _whispers: Array = []   # [text, pos, restzeit]
func whisper(text: String) -> void:
	var colw := UiStyle.column(size)
	var pos := Vector2(colw.position.x + randf_range(40.0, maxf(60.0, colw.size.x - 420.0)), randf_range(size.y * 0.35, size.y * 0.6))
	_whispers.append([text, pos, 4.0])


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
	_saved_t = maxf(_saved_t - delta, 0.0)
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
	for w in _whispers:
		w[2] -= delta
	_whispers = _whispers.filter(func(w): return w[2] > 0.0)
	queue_redraw()


func _draw() -> void:
	if player == null:
		return
	var font := get_theme_default_font()
	var col := UiStyle.column(size)
	var x := col.end.x - BAR_W - MARGIN
	var y := MARGIN + 6.0
	_draw_player_bars(font)   # Leben, Laterne, Wahn direkt an der Spielfigur
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
		var parts := []
		for k in [["wood", "Holz"], ["food", "Nahr."], ["stone", "Stein"]]:
			if player.carry[k[0]] > 0:
				parts.append("%d %s" % [player.carry[k[0]], k[1]])
		load_txt += ": " + ", ".join(parts)
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
	if _saved_t > 0.0:
		var st := "gespeichert"
		var sw := font.get_string_size(st, HORIZONTAL_ALIGNMENT_CENTER, -1, 18).x
		draw_string(font, Vector2((size.x - sw) / 2.0 + 10.0, 80), st, HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
				Color(0.7, 1, 0.7, clampf(_saved_t, 0.0, 1.0) * 0.8))
	_draw_skill_bar(font, player.skill_bar)
	_draw_madness(font)
	_draw_hurt(player.hurt_flash)
	if not player.is_alive():
		_draw_death(font)


## Leben (links), Laterne und Wahn (rechts) als schmale Balken direkt neben der Spielfigur.
func _draw_player_bars(font: Font) -> void:
	if not player.is_alive():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var feet := cam.unproject_position(player.global_position)
	var head := cam.unproject_position(player.global_position + Vector3(0, 2.0, 0))
	var h := maxf(feet.y - head.y, 60.0)
	var top := head.y + h * 0.05
	var bh := h * 0.85
	var gap := maxf(h * 0.42, 34.0)
	# Leben links
	var hf: float = player.health / Config.player_max_health
	var hcol := Color(0.9, 0.22, 0.2)
	if hf < 0.25:
		hcol = hcol.lerp(Color(1, 0.6, 0.5), 0.5 + 0.5 * sin(_t * 9.0))
	_vbar(Rect2(feet.x - gap - 11, top, 11, bh), hf, hcol)
	var hs := str(ceili(player.health))
	var hw := font.get_string_size(hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string_outline(font, Vector2(feet.x - gap - 5 - hw / 2.0, top - 6), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(feet.x - gap - 5 - hw / 2.0, top - 6), hs, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.6, 0.55))
	# Laterne rechts (die Anzeige lügt manchmal im Wahn)
	var lf: float = player.lantern.fraction()
	if player.madness.lie_amount() > 0.0:
		lf = clampf(lf + sin(_t * 3.7) * 0.35, 0.02, 1.0)
	var lcol := Color(1.0, 0.72, 0.3)
	if lf < 0.2:
		lcol = lcol.lerp(Color(1, 0.2, 0.1), 0.5 + 0.5 * sin(_t * 8.0))
	if player.lantern.refilling:
		lcol = lcol.lightened(0.25 + 0.2 * sin(_t * 10.0))
	_vbar(Rect2(feet.x + gap, top, 11, bh), lf, lcol)
	# Wahn daneben (schmaler, violett, mit Stufen-Strichen)
	var mad: Node = player.madness
	var mcol := Color(0.6, 0.3, 0.95)
	if mad.value >= 75.0:
		mcol = mcol.lerp(Color(1, 0.3, 0.8), 0.5 + 0.5 * sin(_t * 6.0))
	var mr := Rect2(feet.x + gap + 15, top, 7, bh)
	_vbar(mr, mad.value / 100.0, mcol)
	for k in [0.25, 0.5, 0.75]:
		draw_line(Vector2(mr.position.x, mr.end.y - mr.size.y * k), Vector2(mr.end.x, mr.end.y - mr.size.y * k), Color(1, 1, 1, 0.35), 1.0)
	if mad.stage() > 0:
		var st: String = mad.stage_name()
		draw_string_outline(font, Vector2(feet.x + gap - 4, top + bh + 18), st, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(feet.x + gap - 4, top + bh + 18), st, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.55, 1.0))


## Senkrechter Balken, füllt sich von unten.
func _vbar(r: Rect2, frac: float, col: Color) -> void:
	frac = clampf(frac, 0.0, 1.0)
	draw_rect(r.grow(2), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(r.position.x, r.end.y - r.size.y * frac, r.size.x, r.size.y * frac), col)
	draw_rect(r.grow(2), Color(1, 1, 1, 0.3), false, 1.5)


## Wahnsinn: violetter Rand (stärker mit dem Wahn), Flüstern.
func _draw_madness(font: Font) -> void:
	var v: float = player.madness.value / 100.0
	if v > 0.2:
		var a := (v - 0.2) * 0.45 * (0.85 + 0.15 * sin(_t * 1.7))
		var t := 30.0 + 60.0 * v
		var c := Color(0.35, 0.05, 0.5, a)
		draw_rect(Rect2(0, 0, size.x, t), c)
		draw_rect(Rect2(0, size.y - t, size.x, t), c)
		draw_rect(Rect2(0, 0, t, size.y), c)
		draw_rect(Rect2(size.x - t, 0, t, size.y), c)
	for w in _whispers:
		var a: float = clampf(w[2] / 1.5, 0.0, 1.0) * clampf((4.0 - w[2]) * 2.0, 0.0, 1.0)
		var p: Vector2 = w[1] + Vector2(sin(_t * 2.0 + w[1].x) * 6.0, 0)
		draw_string_outline(font, p, w[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, 6, Color(0, 0, 0, 0.7 * a))
		draw_string(font, p, w[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.8, 0.55, 1.0, a))


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
	if bar.round_bonus > 0.0:
		draw_string(font, Vector2(x0 + total - 170, y0 - 22), "Schwur +%d %%" % roundi(bar.round_bonus * 100),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 0.85, 0.4))
	if not bar.pending_mods.is_empty():
		var names := []
		for m in bar.pending_mods:
			names.append(SkillData.short_name(m))
		draw_string(font, Vector2(x0, y0 + slot_h + 34), "Vorgemerkt: " + ", ".join(names),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.7, 0.75, 1.0))
	elif not bar.active:
		draw_string(font, Vector2(x0, y0 + slot_h + 34), "Leiste aus – „Leiste: AN“ drücken%s" % UiStyle.key_hint("R"),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1, 1, 1, 0.45))
	elif not running or bar.waiting:
		draw_string(font, Vector2(x0, y0 + slot_h + 34), "Leiste ruht – kein Gegner in Reichweite",
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
	var x := UiStyle.column(size).position.x + MARGIN
	var y := 40.0
	draw_rect(Rect2(x - 6, y - 4, 360, 222), Color(0, 0, 0, 0.4))
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
	var outside: int = fortress.residents_outside()
	var shown_res: int = fortress.residents.size()
	if player.madness.lie_amount() > 0.0:
		shown_res = maxi(0, shown_res + (1 if sin(_t * 2.3) > 0.0 else -2))
	var avg: float = fortress.average_mood()
	draw_string(font, Vector2(x, y + 96), "Bewohner: %d%s · %s" % [shown_res,
			" (%d drau.)" % outside if outside > 0 else "", ResidentData.mood_word(avg)],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ResidentData.mood_color(avg) if fortress.residents.size() > 0 else Color(0.9, 0.85, 0.8))
	# Fackeln draußen: wie viele brennen? Rot blinkend, wenn eine angegriffen wird.
	var burning := 0
	var total := 0
	var attacked := false
	for t in get_tree().get_nodes_in_group("torches"):
		total += 1
		if t.is_burning():
			burning += 1
			attacked = attacked or t.under_attack()
	var torch_col := Color(1, 0.8, 0.5) if not attacked else Color(1, 0.25, 0.15).lerp(Color(1, 0.8, 0.5), blink)
	draw_string(font, Vector2(x, y + 132), "Fackeln: %d / %d brennen%s" % [burning, total, "  !" if attacked else ""],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, torch_col)
	draw_string(font, Vector2(x, y + 168), "Stein: %d   Bögen: %d" % [int(fortress.stone), fortress.bows_total()],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.82, 0.82, 0.92))
	# Uhr: Tag, Phase, Restzeit der Phase
	var left := int(fortress.phase_left())
	var pcol: Color = {"work": Color(1, 0.9, 0.6), "free": Color(0.6, 0.9, 1.0), "night": Color(0.7, 0.7, 1.0)}[fortress.phase()]
	var clock_txt := "Tag %d · %s %d:%02d" % [fortress.day, fortress.phase_name(), left / 60, left % 60]
	draw_string(font, Vector2(x, y + 204), clock_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, pcol)
	# Sonne/Mond hinter der Uhr
	var n: float = Lights.night
	var icon := Vector2(x + font.get_string_size(clock_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 20, y + 196)
	if n < 0.5:
		draw_circle(icon, 9.0, Color(1.0, 0.82, 0.45, 1.0 - n))
	else:
		draw_circle(icon, 9.0, Color(0.8, 0.84, 1.0, n))
		draw_circle(icon + Vector2(4, -3), 8.0, Color(0.02, 0.02, 0.03, n))


func _draw_toasts(font: Font) -> void:
	var y := size.y * 0.3
	for t in _toasts:
		var a := clampf(t[1], 0.0, 1.0)
		var txt: String = t[0]
		var fs := 28
		var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		while ts.x > size.x - 48.0 and fs > 16:   # lange Meldungen kleiner schreiben
			fs -= 2
			ts = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		var px := (size.x - ts.x) / 2.0
		draw_rect(Rect2(px - 14, y - 30, ts.x + 28, 42), Color(0, 0, 0, 0.55 * a))
		draw_string(font, Vector2(px, y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.9, 0.7, a))
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
	var col := UiStyle.column(size)
	var w := col.size.x - 80.0
	_draw_bar_at(font, col.position.x + 40.0, 280.0, w, "Der verwandelte Hauptmann",
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
	if not player.is_alive():
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	# Belagerung fast vorbei: Wegweiser zu den letzten Angreifern (auch von drinnen)
	if siege and siege.active and siege.attackers_left() <= 3:
		for e in siege._enemies:
			if is_instance_valid(e) and e.is_alive():
				_pointer(font, cam, e.global_position, "Angreifer", Color(1, 0.3, 0.3))
	if player.global_position.z > -11.0:
		return
	_pointer(font, cam, Vector3(0, 0, -12), "Tor", Color(1, 0.7, 0.3))
	var beacon := get_tree().get_first_node_in_group("beacon")
	if beacon and beacon.lit:
		_pointer(font, cam, beacon.global_position, "Leuchtfeuer", Color(0.6, 0.8, 1.0))
	for t in get_tree().get_nodes_in_group("torches"):
		if t.under_attack():
			_pointer(font, cam, t.global_position, "Fackel!", Color(1, 0.35, 0.25))



func _pointer(font: Font, cam: Camera3D, world: Vector3, label: String, col: Color) -> void:
	var p := cam.unproject_position(world)
	var colr := UiStyle.column(size)
	var inner := Rect2(Vector2(colr.position.x + 70, 230), Vector2(colr.size.x - 140, size.y - 230 - 420))
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
