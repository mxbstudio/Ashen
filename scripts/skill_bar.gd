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
