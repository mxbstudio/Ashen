## Ereignisse mit Entscheidungen (v0.3).
## Alle paar Minuten (nicht während Belagerung oder Vorzeichen) geschieht etwas in der Festung:
## ein kranker Fremder vor dem Tor, ein Streit, ein Bewohner will Verwandte suchen …
## Das Spiel pausiert, zwei Antworten stehen zur Wahl – jede hat ihren Preis.
extends Control

@export var player: Node3D
@export var fortress: Node3D
@export var siege: Node
@export var touch_controls: Control

var time_left := 0.0               # s bis zum nächsten Ereignis (wird gespeichert)
var _box: VBoxContainer
var _rng := RandomNumberGenerator.new()
var _last := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("touch_blockers")
	add_to_group("events")
	visible = false
	_rng.randomize()
	time_left = Config.event_first
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.88)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_box = VBoxContainer.new()
	_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_box.offset_left = 36
	_box.offset_right = -36
	_box.offset_top = 200
	_box.offset_bottom = -60
	_box.add_theme_constant_override("separation", 26)
	add_child(_box)


func _process(delta: float) -> void:
	if get_tree().paused or visible:
		return
	if not player.is_alive() or not fortress.is_fire_burning() or siege.active or siege.omen_active():
		return
	if fortress.residents.is_empty():
		return
	time_left -= delta
	if time_left > 0.0:
		return
	time_left = Config.event_interval * _rng.randf_range(0.8, 1.25)
	var ev := _pick()
	if not ev.is_empty():
		_show(ev)


## Ein passendes Ereignis würfeln (nicht zweimal dasselbe hintereinander).
func _pick() -> Dictionary:
	var list := []
	for id in ["stranger", "kin", "hunger", "quarrel", "relic", "heretic", "prayer"]:
		if id == _last:
			continue
		var ev := _build(id)
		if not ev.is_empty():
			list.append(ev)
	if list.is_empty():
		return {}
	var ev: Dictionary = list[_rng.randi() % list.size()]
	_last = ev["id"]
	return ev


func _home_residents() -> Array:
	return fortress.residents.filter(func(r): return r.state == 0)


func _any(arr: Array) -> Node3D:
	return arr[_rng.randi() % arr.size()] if not arr.is_empty() else null


## Ereignis zusammenbauen: Titel, Text, zwei Antworten [Knopf, Hinweis, Folge].
func _build(id: String) -> Dictionary:
	var home := _home_residents()
	match id:
		"stranger":
			if fortress.residents.size() >= Config.residents_max:
				return {}
			return {"id": id, "title": "Ein Fremder am Tor",
				"text": "Ein ausgemergelter Mann klopft ans Tor. Er hustet Blut in seinen Ärmel.",
				"a": ["Aufnehmen", "+1 Bewohner (kränklich) – vielleicht steckt er andere an", _stranger_in],
				"b": ["Abweisen", "Die Bewohner sehen zu. Die Stimmung sinkt", _stranger_out]}
		"kin":
			var r := _any(home)
			if r == null:
				return {}
			return {"id": id, "title": "Die Suche",
				"text": "%s glaubt, die Schwester lebt noch – irgendwo im Wald – und will allein nach ihr suchen." % r.res_name,
				"a": ["Ziehen lassen", "Ungewiss: mit Begleitung zurück, allein – oder nie", _kin_go.bind(r)],
				"b": ["Verbieten", "%s verliert jede Hoffnung (Stimmung stark runter)" % r.res_name, _kin_stay.bind(r)]}
		"hunger":
			if fortress.food >= fortress.residents.size() * 1.5:
				return {}
			return {"id": id, "title": "Leere Vorräte",
				"text": "Die Vorräte reichen kaum noch. Die Bewohner schauen dich an.",
				"a": ["Rationen kürzen", "3 Minuten halber Verbrauch – alle hungern", _ration],
				"b": ["Gerecht weiter teilen", "Nahrung wird knapper, aber die Leute danken es dir", _share]}
		"quarrel":
			if home.size() < 2:
				return {}
			home.shuffle()
			var a: Node3D = home[0]
			var b: Node3D = home[1]
			return {"id": id, "title": "Streit am Feuer",
				"text": "%s wirft %s vor, Holz für sich beiseitegeschafft zu haben. Alle warten auf dein Wort." % [a.res_name, b.res_name],
				"a": ["%s recht geben" % a.res_name, "%s freut sich, %s ist gekränkt" % [a.res_name, b.res_name], _side.bind(a, b)],
				"b": ["Beide zurechtweisen", "Beide verärgert, die anderen schätzen die Ordnung", _scold.bind(a, b)]}
		"relic":
			if player.talismans.size() >= 3:   # Talismane sollen selten bleiben
				return {}
			var r := _any(fortress.residents)
			return {"id": id, "title": "Ein Fund in den Trümmern",
				"text": "%s hat ein seltsames Amulett gefunden. Es ist kalt – und es flüstert." % r.res_name,
				"a": ["Behalten", "Du bekommst einen Talisman. Den Bewohnern ist es unheimlich", _relic_keep],
				"b": ["Im Feuer opfern", "Die Bewohner atmen auf (Stimmung hoch)", _relic_burn]}
		"heretic":
			var cands: Array = fortress.residents.filter(func(x): return not x.has_trait("prediger"))
			var r := _any(cands)
			if r == null or fortress.residents.size() < 4:
				return {}
			return {"id": id, "title": "Ein Prediger der Dunkelheit",
				"text": "%s flüstert am Feuer: Die Dunkelheit verschone, wer das Feuer klein hält. Manche hören zu." % r.res_name,
				"a": ["%s verbannen" % r.res_name, "−1 Bewohner, die anderen erschrecken", _banish.bind(r)],
				"b": ["Gewähren lassen", "Zweifel breiten sich aus – auch in dir (+10 Wahnsinn)", _tolerate]}
		"prayer":
			if player.madness.value < 50.0 or fortress.spendable("food") < 5:
				return {}
			return {"id": id, "title": "Ein Gebet für den Hüter",
				"text": "Die Bewohner haben deine Augen gesehen. Sie wollen für dich beten – und Nahrung opfern.",
				"a": ["Annehmen", "−25 Wahnsinn, −5 Nahrung", _pray],
				"b": ["Ablehnen", "Sie fühlen sich zurückgewiesen (Stimmung runter)", _refuse_prayer]}
	return {}


func _show(ev: Dictionary) -> void:
	touch_controls.reset()
	get_tree().paused = true
	visible = true
	for c in _box.get_children():
		c.queue_free()
	_box.add_child(UiStyle.label(ev["title"], 44, Color(1, 0.75, 0.45)))
	_box.add_child(UiStyle.label(ev["text"], 28, Color(1, 1, 1, 0.9)))
	for k in ["a", "b"]:
		var opt: Array = ev[k]
		var btn := UiStyle.button("%s\n%s" % [opt[0], opt[1]], Color(0.9, 0.7, 0.45) if k == "a" else Color(0.6, 0.7, 0.9),
				26, Vector2(0, 170))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_answer.bind(opt[2]))
		_box.add_child(btn)


func _answer(effect: Callable) -> void:
	visible = false
	get_tree().paused = false
	effect.call()
	fortress._assign_jobs()


func _toast(t: String) -> void:
	get_tree().call_group("hud", "toast", t, 4.0)


# --- Folgen ---------------------------------------------------------------------

func _stranger_in() -> void:
	var r: Node3D = fortress._add_resident(Vector3(0, 0, -9.5), fortress.new_identity(["kraenklich"]))
	_toast("%s ist jetzt einer von euch." % r.res_name)
	if _rng.randf() < 0.3:
		var others: Array = fortress.residents.filter(func(x): return x != r)
		others.shuffle()
		for o in others.slice(0, 2):
			o.hp *= 0.5
			o.mood = maxf(o.mood - 10.0, 0.0)
		_toast("Der Husten breitet sich aus …")


func _stranger_out() -> void:
	fortress.mood_shock(-8.0)
	for r in fortress.residents:
		if r.has_trait("prediger"):
			r.mood = maxf(r.mood - 10.0, 0.0)
	_toast("Das Klopfen verstummt irgendwann.")


func _kin_go(r: Node3D) -> void:
	if is_instance_valid(r) and fortress.residents.has(r):
		fortress.send_away(r, 90.0)


func _kin_stay(r: Node3D) -> void:
	if is_instance_valid(r):
		r.mood = maxf(r.mood - 30.0, 0.0)
		_toast("%s starrt stumm ins Feuer." % r.res_name)


func _ration() -> void:
	fortress.ration_t = 180.0
	fortress.mood_shock(-5.0)
	_toast("Die Schüsseln bleiben halb leer.")


func _share() -> void:
	fortress.mood_shock(4.0)
	_toast("Niemand wird bevorzugt.")


func _side(a: Node3D, b: Node3D) -> void:
	if is_instance_valid(a):
		a.mood = minf(a.mood + 10.0, 100.0)
	if is_instance_valid(b):
		b.mood = maxf(b.mood - 25.0, 0.0)


func _scold(a: Node3D, b: Node3D) -> void:
	for r in fortress.residents:
		if r == a or r == b:
			r.mood = maxf(r.mood - 10.0, 0.0)
		else:
			r.mood = minf(r.mood + 3.0, 100.0)


func _relic_keep() -> void:
	player.find_talisman("den Bewohnern")
	fortress.mood_shock(-5.0)


func _relic_burn() -> void:
	fortress.mood_shock(10.0)
	_toast("Das Amulett zerspringt im Feuer. Ein Schrei – dann Stille.")


func _banish(r: Node3D) -> void:
	if is_instance_valid(r) and fortress.residents.has(r):
		fortress.remove_resident(r, "%s wurde in die Dunkelheit verbannt." % r.res_name)
		fortress.mood_shock(-5.0)


func _tolerate() -> void:
	var list: Array = fortress.residents.duplicate()
	list.shuffle()
	for r in list.slice(0, 3):
		r.mood = maxf(r.mood - 15.0, 0.0)
	player.madness.add(10.0)


func _pray() -> void:
	player.madness.add(-25.0)
	fortress.food = maxf(fortress.food - 5.0, 0.0)
	_toast("Ihr Gesang beruhigt dich.")


func _refuse_prayer() -> void:
	fortress.mood_shock(-5.0)
