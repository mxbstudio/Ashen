## Die Skill-Leiste (Kern des Kampfes).
## Ablauf pro Feld: erst ausholen (Cast-Zeit, Feld füllt sich) -> wenn voll: Skill wird ausgelöst.
## - Felder werden automatisch von links nach rechts abgearbeitet, dann wieder links (Kreis).
##   Mit dem Talisman „Pendel“ läuft sie links -> rechts -> zurück: mittlere Felder kommen doppelt so oft dran.
## - Kein Cooldown: jeder Skill hat eine Cast-Zeit, danach ist das nächste Feld dran.
## - Angriffe wirken selbst. Modifikatoren werden "vorgemerkt" und verändern den
##   nächsten Angriff (auch über das Ende der Leiste hinweg auf das erste Feld).
## - Lage zählt (v0.3): Spiegel kopiert das Feld davor, Schwur im letzten Feld stärkt die ganze nächste Runde.
## - Ohne Angriff in der Leiste passiert nichts.
## - Die Leiste läuft nur, wenn ein Gegner in der Nähe ist.
## - Ein Dash unterbricht den aktuellen Cast (Fortschritt geht verloren).
extends Node

signal skill_fired(id: String, slot: int)

var slots: Array[String] = ["sickle", "bow", ""]
var index := 0                     # aktueller Slot
var progress := 0.0                # Sekunden, die der aktuelle Cast schon läuft
var pending_mods: Array[String] = []   # vorgemerkte Modifikatoren
var running := false
var stash: Array[String] = []          # Vorrat: besessene Skills, die nicht in der Leiste sind
var levels := {"sickle": 1, "bow": 1}  # jeder Skill nur einmal – dafür mit Stufe
var branches := {}                     # gewählte Abzweigung je Skill: "a" oder "b" (ab Stufe 3)

var round_bonus := 0.0             # Schwur: Schadensbonus für die laufende Runde
var _oath_pending := 0.0           # Schwur: Bonus für die nächste Runde
var _carry_mods: Array[String] = []    # Bleiche Hand: Modifikatoren wirken noch einmal
var _attack_count := 0             # Glockenseil: jeder 3. Angriff doppelt
var _pdir := 1                     # Pendel: aktuelle Laufrichtung (+1 rechts, −1 zurück)
var _last_index := -1              # zuletzt ausgelöstes Feld (für den Spiegel)

@onready var player: Node3D = get_parent()


func has_attack() -> bool:
	for s in slots:
		if SkillData.is_attack(s):
			return true
	return false


func has_branch(id: String, b: String) -> bool:
	return branches.get(id, "") == b


func _talisman(id: String) -> bool:
	return player.has_talisman(id)


func pendulum() -> bool:
	return _talisman("pendulum")


## Aktuelle Laufrichtung: +1 = nach rechts, −1 = zurück (nur mit dem Pendel).
func direction() -> int:
	return _pdir if pendulum() else 1


func _start_index() -> int:
	return 0


## Cast-Zeit des aktuellen Slots (Echo verlängert den Angriff, Talismane verändern das Tempo).
func current_cast_time() -> float:
	var id := slots[index]
	if id == "":
		return 0.4 if _talisman("chalice") else 0.0
	var t := SkillData.cast_time(id)
	if SkillData.is_attack(id) and pending_mods.has("echo") and not has_branch("echo", "a"):
		t *= echo_multiplier() + (0.6 if has_branch("echo", "b") else 0.0)
	if _talisman("haste"):
		t *= 0.75
	if _talisman("wick"):
		t *= 1.15
	return t


## 0..1 Fortschritt des aktuellen Casts (für die HUD-Anzeige).
func fraction() -> float:
	var t := current_cast_time()
	return clampf(progress / t, 0.0, 1.0) if t > 0.0 else 0.0


func interrupt() -> void:
	progress = 0.0


## Totenglocke: ein getöteter Gegner lädt den laufenden Cast auf.
func on_kill() -> void:
	if running and _talisman("deathbell"):
		progress = minf(progress + current_cast_time() * 0.3, current_cast_time() * 0.95)


func _physics_process(delta: float) -> void:
	running = has_attack() and player.is_alive() and player.combat.enemy_near()
	if not running:
		progress = 0.0
		return
	index = clampi(index, 0, slots.size() - 1)
	# leere Slots überspringen (mit dem Leeren Kelch nicht)
	if not _talisman("chalice"):
		var guard := 0
		while slots[index] == "" and guard < slots.size():
			_advance_index()
			guard += 1
	progress += delta
	if progress >= current_cast_time():
		progress = 0.0
		var id := slots[index]
		if id == "":
			player.lantern.fuel = minf(player.lantern.fuel + 3.0, Config.lantern_burn_time)   # Leerer Kelch
		else:
			_execute(id)
		_advance_index()


## Zum nächsten Feld (in Laufrichtung). Beim Rundenwechsel greift ein vorgemerkter Schwur.
## Pendel: am rechten bzw. linken Ende kehrt die Richtung um; eine Runde ist einmal hin und zurück.
func _advance_index() -> void:
	if pendulum() and slots.size() > 1:
		var next := index + _pdir
		if next < 0 or next >= slots.size():
			_pdir = -_pdir
			next = index + _pdir
		index = next
	else:
		_pdir = 1
		index = wrapi(index + 1, 0, slots.size())
	if index == _start_index():
		round_bonus = _oath_pending
		_oath_pending = 0.0
		if round_bonus > 0.0 and has_branch("oath", "b"):
			player.take_damage(3.0, null, true)   # Blutschwur


## Ist dieses Feld das letzte belegte (ganz rechts)? Mit dem Pendel: der Umkehrpunkt rechts.
func _is_last_filled(i: int) -> bool:
	for j in range(i + 1, slots.size()):
		if slots[j] != "":
			return false
	return true


func _execute(id: String) -> void:
	match id:
		"oath":
			_oath(index)
		"mirror":
			_mirror(index)
		_:
			if SkillData.is_modifier(id):
				pending_mods.append(id)
			else:
				_fire_attack(id, 1.0)
	_last_index = index
	skill_fired.emit(id, index)


func _fire_attack(id: String, mult: float) -> void:
	var mods := pending_mods.duplicate()
	mods.append_array(_carry_mods)
	_carry_mods.clear()
	if _talisman("palehand") and not pending_mods.is_empty():
		_carry_mods = pending_mods.duplicate()   # wirken beim nächsten Angriff noch einmal
	pending_mods.clear()
	_attack_count += 1
	var extra := 1 if _talisman("bellrope") and _attack_count % 3 == 0 else 0
	player.combat.perform(id, mods, mult, extra)


## Schwur: im letzten Feld (oder mit „Ewiger Schwur“ überall) -> Bonus für die ganze nächste Runde.
func _oath(i: int) -> void:
	var lvl := level_of("oath") - 1
	if has_branch("oath", "a"):
		_oath_pending = maxf(_oath_pending, 0.15 + Config.oath_per_level * lvl)
	elif _is_last_filled(i):
		var base := 0.5 if has_branch("oath", "b") else Config.oath_bonus
		_oath_pending = maxf(_oath_pending, base + Config.oath_per_level * lvl)
	else:
		pending_mods.append("oath")


## Spiegel: das zuvor gelaufene Feld wird noch einmal ausgelöst (links davon, beim Pendel-Rückweg rechts).
func _mirror(_i: int) -> void:
	var prev := _last_index
	if prev < 0 or prev >= slots.size():
		return
	var left := slots[prev]
	if left == "" or left == "mirror":
		return
	if SkillData.is_modifier(left):
		var times := 2 if has_branch("mirror", "b") else 1
		for t in times:
			if left == "oath":
				_oath(prev)
			else:
				pending_mods.append(left)
	elif not has_branch("mirror", "b"):
		var m := 1.0 if has_branch("mirror", "a") else Config.mirror_copy + Config.mirror_per_level * (level_of("mirror") - 1)
		_fire_attack(left, minf(m, 1.0))


# --- Besitz, Stufen & Umbau -----------------------------------------------

func owns(id: String) -> bool:
	return levels.has(id)


func level_of(id: String) -> int:
	return levels.get(id, 1)


## Echo: Cast-Verlängerung (sinkt mit der Echo-Stufe).
func echo_multiplier() -> float:
	return maxf(1.05, Config.echo_cast_multiplier - Config.echo_cast_per_level * (level_of("echo") - 1))


func upgrade(id: String) -> void:
	levels[id] = mini(level_of(id) + 1, Config.max_skill_level)


func choose_branch(id: String, b: String) -> void:
	branches[id] = b


## Muss bei der nächsten Stufe eine Abzweigung gewählt werden?
func needs_branch(id: String) -> bool:
	return level_of(id) + 1 >= Config.branch_level and not branches.has(id) and SkillData.BRANCHES.has(id)


## Ein weiteres Feld rechts anhängen; ein Skill aus dem Vorrat rückt direkt nach.
func add_slot() -> void:
	slots.append("")
	if not stash.is_empty():
		slots[slots.size() - 1] = stash.pop_front()
	_reset_cycle()


## Neuen Skill bekommen: in ein freies Feld, sonst in den Vorrat.
## Gibt true zurück, wenn er direkt in der Leiste gelandet ist.
func add_skill(id: String) -> bool:
	levels[id] = 1
	var empty := slots.find("")
	if empty != -1:
		slots[empty] = id
		_reset_cycle()
		return true
	stash.append(id)
	return false


## Feld mit einem Skill aus dem Vorrat belegen (der alte wandert in den Vorrat).
func put_from_stash(slot: int, stash_index: int) -> void:
	var incoming := stash[stash_index]
	stash.remove_at(stash_index)
	if slots[slot] != "":
		stash.append(slots[slot])
	slots[slot] = incoming
	_reset_cycle()


## Feld leeren (Skill wandert in den Vorrat).
func clear_slot(slot: int) -> void:
	if slots[slot] != "":
		stash.append(slots[slot])
		slots[slot] = ""
	_reset_cycle()


func swap_slots(a: int, b: int) -> void:
	var t := slots[a]
	slots[a] = slots[b]
	slots[b] = t
	_reset_cycle()


## Nach einem Umbau beginnt die Leiste wieder am Anfang, ohne Vormerkungen.
func _reset_cycle() -> void:
	index = _start_index()
	_pdir = 1
	_last_index = -1
	progress = 0.0
	pending_mods.clear()
	_carry_mods.clear()
	round_bonus = 0.0
	_oath_pending = 0.0


func reset_cycle() -> void:
	_reset_cycle()
