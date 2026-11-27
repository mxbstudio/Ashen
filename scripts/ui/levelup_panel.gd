## Stufenaufstieg: Spiel pausiert, 3 Karten zur Auswahl, eine antippen.
## Angebote: neue Skills (jeden Skill gibt es nur einmal) oder eine Stufe mehr für einen
## Skill, den man schon hat. Neue Skills landen im Vorrat (einsetzen im Menü „Leiste“).
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
	UiStyle.keep_in_column(_box, 36)
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
	if level in Config.extra_slot_levels:
		player.skill_bar.add_slot()
		get_tree().call_group("hud", "toast", "Neues leeres Feld in der Skill-Leiste – im Menü „Leiste“ füllen")
	touch_controls.reset()
	get_tree().paused = true
	visible = true
	for c in _box.get_children():
		c.queue_free()
	_box.add_child(UiStyle.label("Stufe %d erreicht!" % level, 46, Color(1, 0.8, 0.45)))
	_box.add_child(UiStyle.label("Wähle eine Fähigkeit", 28, Color(1, 1, 1, 0.7)))
	for id in _pick_options():
		_box.add_child(_card(id))


## 3 verschiedene Angebote: "new:<id>" (neuer Skill) oder "up:<id>" (Verbesserung); sonst Boni.
func _pick_options() -> Array[String]:
	var pool: Array[String] = []
	var bar: Node = player.skill_bar
	var dark_ok: bool = player.madness.value >= Config.madness_dark_offer
	for id in SkillData.DEFS:
		if SkillData.is_dark(id) and not dark_ok and not bar.owns(id):
			continue   # dunkle Skills nur bei Wahnsinn
		if not bar.owns(id):
			pool.append("new:" + id)
		elif bar.level_of(id) < Config.max_skill_level:
			pool.append("up:" + id)
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
	elif id.begins_with("new:"):
		var sid := id.substr(4)
		text = ("DUNKEL: " if SkillData.is_dark(sid) else ("LICHT: " if SkillData.is_light(sid) else "NEU: ")) + UiStyle.skill_text(sid)
		col = SkillData.color(sid)
	else:
		var sid := id.substr(3)
		var next: int = player.skill_bar.level_of(sid) + 1
		if player.skill_bar.needs_branch(sid):
			var br: Dictionary = SkillData.BRANCHES[sid]
			text = "%s – Stufe %d\nAbzweigung wählen: %s oder %s" % [SkillData.DEFS[sid]["name"], next,
					br["a"][0], br["b"][0]]
		else:
			text = "%s – Stufe %d\n%s" % [SkillData.DEFS[sid]["name"], next, SkillData.upgrade_text(sid)]
		col = SkillData.color(sid).lerp(Color(1, 1, 0.6), 0.3)
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
			if id.begins_with("up:"):
				var sid := id.substr(3)
				if player.skill_bar.needs_branch(sid):
					_show_branches(sid)
					return
				player.skill_bar.upgrade(sid)
			else:
				var sid := id.substr(4)
				var in_bar: bool = player.skill_bar.add_skill(sid)
				if not in_bar:
					get_tree().call_group("hud", "toast", "%s liegt im Vorrat – im Menü „Leiste“ einsetzen"
							% SkillData.DEFS[sid]["name"])
	_open_next()


## Abzweigung wählen: zwei Karten mit den beiden Regeln des Skills.
func _show_branches(sid: String) -> void:
	for c in _box.get_children():
		c.queue_free()
	_box.add_child(UiStyle.label("%s – Stufe %d" % [SkillData.DEFS[sid]["name"], player.skill_bar.level_of(sid) + 1],
			40, Color(1, 0.8, 0.45)))
	_box.add_child(UiStyle.label("Wähle eine Abzweigung – sie gilt für immer", 26, Color(1, 1, 1, 0.7)))
	for b in ["a", "b"]:
		var br: Array = SkillData.BRANCHES[sid][b]
		var btn := UiStyle.button("%s\n%s" % [br[0], br[1]], SkillData.color(sid).lerp(Color(1, 1, 0.6), 0.2),
				28, Vector2(0, 220))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_choose_branch.bind(sid, b))
		_box.add_child(btn)


func _choose_branch(sid: String, b: String) -> void:
	player.skill_bar.choose_branch(sid, b)
	player.skill_bar.upgrade(sid)
	get_tree().call_group("hud", "toast", "%s: %s" % [SkillData.DEFS[sid]["name"], SkillData.branch_name(sid, b)])
	_open_next()
