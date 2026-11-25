## Stufenaufstieg: Spiel pausiert, 3 Karten zur Auswahl, eine antippen.
## Neue Skills landen in einem freien Feld der Leiste, sonst im Vorrat (am Feuer einsetzen).
extends Control

@export var player: Node3D
@export var touch_controls: Control

## Kleine Boni, falls kaum noch Skills übrig sind.
const BONI := {
	"b_health": {"name": "Zähigkeit", "desc": "+15 maximales Leben"},
	"b_wick": {"name": "Langer Docht", "desc": "+20 s Laternen-Brenndauer"},
	"b_flask": {"name": "Feldflasche", "desc": "+1 Trank"},
}

var _queue: Array[int] = []      # noch offene Stufenaufstiege
var _box: VBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	add_to_group("touch_blockers")
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.82)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.offset_left = 36
	_box.offset_right = -36
	_box.offset_top = 210
	_box.offset_bottom = -60
	_box.add_theme_constant_override("separation", 22)
	add_child(_box)
	player.leveled_up.connect(_on_leveled_up)


func _on_leveled_up(level: int) -> void:
	_queue.append(level)
	if not visible:
		_open_next()


func _open_next() -> void:
	if _queue.is_empty():
		visible = false
		get_tree().paused = false
		return
	var level: int = _queue.pop_front()
	touch_controls.reset()
	get_tree().paused = true
	visible = true
	for c in _box.get_children():
		c.queue_free()
	_box.add_child(UiStyle.label("Stufe %d erreicht!" % level, 46, Color(1, 0.8, 0.45)))
	_box.add_child(UiStyle.label("Wähle eine Fähigkeit", 28, Color(1, 1, 1, 0.7)))
	for id in _pick_options():
		_box.add_child(_card(id))


## 3 verschiedene Angebote: Skills, die man noch nicht zu oft hat; sonst Boni.
func _pick_options() -> Array[String]:
	var pool: Array[String] = []
	for id in SkillData.DEFS:
		if player.skill_bar.owned_count(id) < Config.max_skill_copies:
			pool.append(id)
	pool.shuffle()
	var out: Array[String] = []
	for id in pool:
		if out.size() < 3:
			out.append(id)
	var boni := BONI.keys()
	boni.shuffle()
	for b in boni:
		if out.size() < 3:
			out.append(b)
	return out


func _card(id: String) -> Button:
	var text: String
	var col: Color
	if BONI.has(id):
		text = "%s\nBonus\n%s" % [BONI[id]["name"], BONI[id]["desc"]]
		col = Color(0.6, 0.9, 0.6)
	else:
		text = UiStyle.skill_text(id)
		var owned: int = player.skill_bar.owned_count(id)
		if owned > 0:
			text += "\n(besitzt du schon %d×)" % owned
		col = SkillData.color(id)
	var b := UiStyle.button(text, col, 28, Vector2(0, 200))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(_choose.bind(id))
	return b


func _choose(id: String) -> void:
	match id:
		"b_health":
			Config.player_max_health += 15.0
			player.heal(15.0)
		"b_wick":
			Config.lantern_burn_time += 20.0
			player.lantern.fuel += 20.0
		"b_flask":
			Config.potions_start += 1
			player.potions += 1
		_:
			var in_bar: bool = player.skill_bar.add_skill(id)
			if not in_bar:
				DebugOverlay.note("%s liegt im Vorrat – am Feuer in die Leiste einsetzen"
						% SkillData.DEFS[id]["name"])
	_open_next()
