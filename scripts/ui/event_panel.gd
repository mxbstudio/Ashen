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
	if player.madness.value >= Config.madness_event_threshold:
		time_left *= 0.6   # der Wahn drängt öfter zu Entscheidungen
	var ev := _pick()
	if not ev.is_empty():
		_show(ev)


## Ein passendes Ereignis würfeln (nicht zweimal dasselbe hintereinander).
func _pick() -> Dictionary:
	var list := []
	var ids := ["stranger", "kin", "hunger", "quarrel", "relic", "heretic", "prayer"]
	if player.madness.value >= Config.madness_event_threshold:
		ids = MAD_EVENTS   # komplett wahnsinnig: nur noch die Entscheidungen des Wahns
	for id in ids:
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
	if id in MAD_EVENTS:
		return _build_mad(id)
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
	var mad: bool = ev.get("mad", false)
	for c in _box.get_children():
		c.queue_free()
	if mad:
		_box.add_child(UiStyle.label("Der Wahn spricht", 26, Color(0.8, 0.5, 1.0, 0.8)))
	_box.add_child(UiStyle.label(ev["title"], 44, Color(0.85, 0.45, 1.0) if mad else Color(1, 0.75, 0.45)))
	_box.add_child(UiStyle.label(ev["text"], 28, Color(1, 1, 1, 0.9)))
	for k in ["a", "b"]:
		var opt: Array = ev[k]
		var col := Color(0.9, 0.7, 0.45) if k == "a" else Color(0.6, 0.7, 0.9)
		if mad:
			col = Color(0.85, 0.2, 0.25) if k == "a" else Color(0.6, 0.15, 0.45)
		var btn := UiStyle.button("%s\n%s" % [opt[0], opt[1]], col, 26, Vector2(0, 170))
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



# --- Entscheidungen des Wahns (ab Config.madness_event_threshold) ---------------------
# Nur zwei Antworten – und beide sind schlecht. Das ist der Wahn des Hüters.

const MAD_EVENTS := ["mad_theft", "mad_stare", "mad_poison", "mad_sacrifice", "mad_whisper"]


func _build_mad(id: String) -> Dictionary:
	var r := _any(fortress.residents)
	if r == null:
		return {}
	match id:
		"mad_theft":
			return {"id": id, "mad": true, "title": "Der Dieb",
				"text": "%s hat Holz vom Feuer genommen. Du hast es gesehen. Ganz sicher." % r.res_name,
				"a": ["%s sofort töten" % r.res_name, "Still und schnell. Die anderen finden die Leiche am Morgen", _mad_kill.bind(r, false)],
				"b": ["Vor allen hinrichten", "Damit es jeder sieht. Die Angst sitzt tief", _mad_kill.bind(r, true)]}
		"mad_stare":
			return {"id": id, "mad": true, "title": "Der Blick",
				"text": "%s starrt dich an. %s weiß es. Weiß alles." % [r.res_name, r.res_name],
				"a": ["%s in die Dunkelheit jagen" % r.res_name, "Ohne Licht. Niemand kommt von dort zurück", _mad_banish.bind(r)],
				"b": ["Ohne Laterne Holz holen schicken", "Vielleicht kommt %s zurück. Vielleicht nicht" % r.res_name, _mad_errand.bind(r)]}
		"mad_poison":
			return {"id": id, "mad": true, "title": "Gift",
				"text": "Die Stimmen sagen: Etwas im Lager ist vergiftet. Du riechst es.",
				"a": ["Das Holz ins Dunkel werfen", "Die Hälfte des Holzes ist fort", _mad_poison.bind("wood")],
				"b": ["Die Nahrung verbrennen", "Die Hälfte der Nahrung ist fort", _mad_poison.bind("food")]}
		"mad_sacrifice":
			return {"id": id, "mad": true, "title": "Das Opfer",
				"text": "Die Dunkelheit verlangt Blut. Sie wird nicht schweigen, bis sie es bekommt.",
				"a": ["%s opfern" % r.res_name, "Ein Leben – dafür wird es kurz still in dir (−20 Wahnsinn)", _mad_sacrifice_res.bind(r)],
				"b": ["Dein eigenes Blut geben", "−15 maximales Leben, für immer", _mad_sacrifice_self]}
		"mad_whisper":
			var list: Array = fortress.residents.duplicate()
			if list.size() < 2:
				return {}
			list.shuffle()
			var a: Node3D = list[0]
			var b: Node3D = list[1]
			return {"id": id, "mad": true, "title": "Verschwörung",
				"text": "%s und %s flüstern miteinander. Über dich. Über das Feuer." % [a.res_name, b.res_name],
				"a": ["Beide einsperren, ohne Essen", "Sie werden es nicht vergessen – keiner wird es vergessen", _mad_lockup.bind(a, b)],
				"b": ["Einen von beiden töten", "Der andere wird schweigen. Für immer", _mad_kill.bind(a, true)]}
	return {}


func _mad_kill(r: Node3D, public: bool) -> void:
	if not is_instance_valid(r) or not fortress.residents.has(r):
		return
	if public:
		fortress.kill_resident("%s wurde vor allen hingerichtet.", r)
		fortress.mood_shock(-15.0)
	else:
		fortress.kill_resident("%s wurde im Schlaf getötet.", r)
		fortress.mood_shock(-6.0)
	_toast("Das Feuer knistert. Niemand sagt ein Wort.")


func _mad_banish(r: Node3D) -> void:
	if is_instance_valid(r) and fortress.residents.has(r):
		fortress.graves.append([r.res_name, "%s wurde in die Dunkelheit gejagt." % r.res_name])
		fortress.update_graves()
		fortress.remove_resident(r, "%s wurde in die Dunkelheit gejagt." % r.res_name, true)


func _mad_errand(r: Node3D) -> void:
	if is_instance_valid(r) and fortress.residents.has(r):
		r.mood = maxf(r.mood - 30.0, 0.0)
		if _rng.randf() < 0.6:
			fortress.graves.append([r.res_name, "%s kam ohne Laterne nicht zurück." % r.res_name])
			fortress.update_graves()
			fortress.remove_resident(r, "%s ist ohne Laterne in den Wald gegangen – und nicht zurückgekehrt." % r.res_name, true)
		else:
			r.hp = 1.0
			_toast("%s kommt zurück. Blutend. Mit leeren Händen." % r.res_name)


func _mad_poison(kind: String) -> void:
	if kind == "wood":
		fortress.wood = maxf(1.0, floorf(fortress.wood / 2.0))
		_toast("Das Holz verschwindet in der Dunkelheit.")
	else:
		fortress.food = floorf(fortress.food / 2.0)
		_toast("Der Gestank verbrannter Pilze hängt über der Festung.")
	fortress.mood_shock(-8.0)


func _mad_sacrifice_res(r: Node3D) -> void:
	if is_instance_valid(r) and fortress.residents.has(r):
		fortress.kill_resident("%s wurde der Dunkelheit geopfert.", r)
		fortress.mood_shock(-12.0)
		player.madness.add(-20.0)


func _mad_sacrifice_self() -> void:
	Config.player_max_health = maxf(Config.player_max_health - 15.0, 30.0)
	player.health = minf(player.health, Config.player_max_health)
	player.hurt_flash = 0.35
	_toast("Du schneidest tief. Die Stimmen trinken.")


func _mad_lockup(a: Node3D, b: Node3D) -> void:
	for r in [a, b]:
		if is_instance_valid(r):
			r.mood = 0.0
			r.hp = maxf(r.hp * 0.4, 1.0)
	fortress.mood_shock(-10.0)
	_toast("Hinter der Tür wird es irgendwann still.")
