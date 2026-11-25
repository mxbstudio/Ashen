## Die Skill-Leiste (Kern des Kampfes).
## Ablauf pro Feld: erst ausholen (Cast-Zeit, Feld füllt sich) -> wenn voll: Skill wird ausgelöst.
## - 3 Slots, werden automatisch von links nach rechts abgearbeitet, dann wieder links (Kreis).
## - Kein Cooldown: jeder Skill hat eine Cast-Zeit, danach ist der nächste Slot dran.
## - Angriffe wirken selbst. Modifikatoren werden "vorgemerkt" und verändern den
##   nächsten Angriff (auch über das Ende der Leiste hinweg auf den ersten Slot).
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

@onready var player: Node3D = get_parent()


func has_attack() -> bool:
	for s in slots:
		if SkillData.is_attack(s):
			return true
	return false


## Cast-Zeit des aktuellen Slots (Echo verlängert den Angriff).
func current_cast_time() -> float:
	var id := slots[index]
	var t := SkillData.cast_time(id)
	if SkillData.is_attack(id) and pending_mods.has("echo"):
		t *= Config.echo_cast_multiplier
	return t


## 0..1 Fortschritt des aktuellen Casts (für die HUD-Anzeige).
func fraction() -> float:
	var t := current_cast_time()
	return clampf(progress / t, 0.0, 1.0) if t > 0.0 else 0.0


func interrupt() -> void:
	progress = 0.0


func _physics_process(delta: float) -> void:
	running = has_attack() and player.is_alive() and player.combat.enemy_near()
	if not running:
		progress = 0.0
		return
	# leere Slots überspringen
	var guard := 0
	while slots[index] == "" and guard < slots.size():
		index = (index + 1) % slots.size()
		guard += 1
	progress += delta
	if progress >= current_cast_time():
		progress = 0.0
		_execute(slots[index])
		index = (index + 1) % slots.size()


func _execute(id: String) -> void:
	if SkillData.is_modifier(id):
		pending_mods.append(id)
	else:
		player.combat.perform(id, pending_mods.duplicate())
		pending_mods.clear()
	skill_fired.emit(id, index)


# --- Besitz & Umbau --------------------------------------------------------

## Wie oft besitzt der Hüter diesen Skill (Leiste + Vorrat)?
func owned_count(id: String) -> int:
	return slots.count(id) + stash.count(id)


## Neuen Skill bekommen: in ein freies Feld, sonst in den Vorrat.
## Gibt true zurück, wenn er direkt in der Leiste gelandet ist.
func add_skill(id: String) -> bool:
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


## Nach einem Umbau beginnt die Leiste wieder links, ohne Vormerkungen.
func _reset_cycle() -> void:
	index = 0
	progress = 0.0
	pending_mods.clear()
