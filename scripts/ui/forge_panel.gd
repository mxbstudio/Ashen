## Ausrüstung schmieden – an der Werkstatt.
## Knopf "Ausrüstung schmieden" erscheint vor der gebauten Werkstatt; das Menü pausiert das Spiel.
## Drei Teile mit je 3 Stufen: Klinge (Schaden), Rüstung (Leben, Schutz), Laterne (Brenndauer, Lichtkreis).
## Kosten: Holz + Stein (zuerst aus der Trage, dann aus dem Lager). Stufe n braucht Werkstatt-Stufe n.
extends Control

const MAX_LEVEL := 3
const SLOTS := [
	["weapon", "Klinge"],
	["armor", "Rüstung"],
	["lantern", "Laterne"],
]

@export var player: Node3D
@export var fortress: Node3D
@export var touch_controls: Control

var _open_button: Button
var _box: VBoxContainer
var _workshop: Node3D


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
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.offset_left = 30
	_box.offset_right = -30
	_box.offset_top = 90
	_box.offset_bottom = -150
	_box.add_theme_constant_override("separation", 22)
	add_child(_box)
	var done := UiStyle.button("Fertig", Color(0.5, 0.9, 0.5), 32, Vector2(0, 100))
	done.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	done.offset_left = 24
	done.offset_right = -24
	done.offset_top = -130
	done.offset_bottom = -30
	done.pressed.connect(close)
	add_child(done)
	_open_button = UiStyle.button("Ausrüstung schmieden", Color(0.85, 0.7, 0.5), 26, Vector2(380, 74))
	_open_button.add_to_group("touch_blockers")
	_open_button.pressed.connect(open)
	_open_button.visible = false
	add_sibling.call_deferred(_open_button)


## Steht der Hüter vor der gebauten Werkstatt?
func _process(_delta: float) -> void:
	_workshop = null
	for b in fortress.buildings:
		if b.kind == "workshop" and b.built:
			_workshop = b
	var show := false
	if _workshop and player.is_alive() and not visible and not get_tree().paused:
		var spot: Vector3 = _workshop.work_spot()
		show = Vector2(spot.x - player.global_position.x, spot.z - player.global_position.z).length() < 2.2
	if _open_button.visible != show:
		_open_button.visible = show
	if show:
		var vp := get_viewport_rect().size
		_open_button.position = Vector2((vp.x - _open_button.size.x) / 2.0, vp.y - 680.0)


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
	_box.add_child(UiStyle.label("Ausrüstung schmieden", 40, Color(1, 0.8, 0.5)))
	_box.add_child(UiStyle.label("Vorrat: %d Holz, %d Stein (Trage + Lager) · Werkstatt Stufe %d" % [
			fortress.available("wood", player.carry), fortress.available("stone", player.carry),
			_workshop.level if _workshop else 0], 22, Color(1, 1, 1, 0.7)))
	for s in SLOTS:
		_box.add_child(_row(s[0], s[1]))


func _row(slot: String, title: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var lvl: int = player.equip[slot]
	var head := UiStyle.label("%s – Stufe %d / %d" % [title, lvl, MAX_LEVEL], 30, Color(1, 0.85, 0.55))
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(head)
	var now := UiStyle.label("jetzt: " + _effect(slot, lvl), 22, Color(1, 1, 1, 0.75))
	now.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(now)
	if lvl >= MAX_LEVEL:
		col.add_child(UiStyle.label("Höchste Stufe erreicht", 22, Color(0.6, 1, 0.6)))
		return col
	var wood: int = Config.equip_wood[lvl]
	var stone: int = Config.equip_stone[lvl]
	var ws_ok: bool = _workshop != null and _workshop.level >= lvl + 1
	var have_ok: bool = fortress.available("wood", player.carry) >= wood \
			and fortress.available("stone", player.carry) >= stone
	var txt := "Stufe %d schmieden: %d Holz, %d Stein\n%s" % [lvl + 1, wood, stone, _effect(slot, lvl + 1)]
	if not ws_ok:
		txt += "\n(braucht Werkstatt Stufe %d)" % (lvl + 1)
	elif not have_ok:
		txt += "\n(nicht genug Holz/Stein)"
	var b := UiStyle.button(txt, Color(0.85, 0.6, 0.35), 22, Vector2(0, 120))
	b.disabled = not ws_ok or not have_ok
	b.pressed.connect(_forge.bind(slot, wood, stone))
	col.add_child(b)
	return col


## Was bringt das Teil auf Stufe l?
func _effect(slot: String, l: int) -> String:
	match slot:
		"weapon":
			return "+%d %% Schaden" % int(Config.weapon_damage_per_level * 100 * l) if l > 0 else "einfache Klinge"
		"armor":
			return "+%d Leben, −%d %% Schaden" % [int(Config.armor_health_per_level * l),
					int(Config.armor_reduction_per_level * 100 * l)] if l > 0 else "keine Rüstung"
		"lantern":
			return "+%d s Brenndauer, +%d m Licht" % [int(Config.lantern_time_per_level * l),
					int(Config.lantern_radius_per_level * l)] if l > 0 else "einfache Laterne"
	return ""


func _forge(slot: String, wood: int, stone: int) -> void:
	fortress.pay("wood", wood, player.carry)
	fortress.pay("stone", stone, player.carry)
	player.set_equip(slot, player.equip[slot] + 1)
	Sfx.play("levelup", 0.0, 0.0)
	_rebuild()
