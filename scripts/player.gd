## Der Hüter: läuft, dasht, trägt die Laterne und kämpft über die Skill-Leiste.
extends CharacterBody3D

signal dashed
signal died
signal respawned
signal leveled_up(level: int)

@export var camera_rig: Node3D
@export var respawn_point: Node3D      # das Feuer – hier erscheint er nach dem Tod

@onready var model: Node3D = $Model
@onready var lantern: Node3D = $Model/Lantern
@onready var combat: Node = $Combat
@onready var skill_bar: Node = $SkillBar

const MadnessScript := preload("res://scripts/madness.gd")
var madness: Node                  # Wahnsinn (v0.3), siehe madness.gd
var talismans: Array[String] = []  # gefundene Talismane
var equipped: Array[String] = []   # angelegte Talismane (höchstens Config.talisman_slots)

var facing := Vector3(0, 0, 1)     # Blickrichtung auf dem Boden
var _dash_time := 0.0
var _dash_cd := 0.0
var _dash_dir := Vector3.ZERO

var health := 0.0
var potions := 0
var xp := 0
var level := 1
var hurt_flash := 0.0              # für die rote Anzeige am Bildschirmrand
var dead_timer := 0.0              # > 0 solange er tot ist
var protect_timer := 0.0           # > 0: unverwundbar (nach dem Wiedererscheinen)
var carry := {"wood": 0, "food": 0, "stone": 0}   # Inhalt der Trage
var _gather_t := 0.0
var _full_warned := false
var on_tower: Node3D = null        # Wachturm, auf dem er gerade steht (oder null)


func _ready() -> void:
	add_to_group("player")
	health = Config.player_max_health
	potions = Config.potions_start
	collision_layer = 2            # Ebene 2: Hüter (Gegner laufen nicht gegen ihn)
	collision_mask = 1             # stößt nur an die Welt
	madness = MadnessScript.new()
	madness.name = "Madness"
	add_child(madness)


func is_alive() -> bool:
	return dead_timer <= 0.0


func is_dashing() -> bool:
	return _dash_time > 0.0


## self_inflicted: Blutopfer/Blutschwur/Wahn – wirkt auch im Dash, tötet aber nicht.
func take_damage(amount: float, _from: Node3D = null, self_inflicted := false) -> void:
	if not is_alive():
		return
	if self_inflicted:
		health = maxf(health - amount, 1.0)
		hurt_flash = maxf(hurt_flash, 0.15)
		_spawn_number(amount, Color(0.8, 0.3, 0.9))
		return
	if is_dashing() or protect_timer > 0.0:
		return   # während des Dashs und kurz nach dem Wiedererscheinen unverwundbar
	if has_talisman("haste"):
		amount *= 1.2
	if _from:
		DebugOverlay.watch("Letzter Treffer", "%s (%d)" % [_from.get_script().resource_path.get_file().get_basename(), int(amount)])
	health -= amount
	hurt_flash = 0.35
	Sfx.play("hurt")
	_spawn_number(amount, Color(1, 0.3, 0.25))
	if health <= 0.0:
		_die()


func heal(amount: float) -> void:
	if not is_alive():
		return
	health = minf(health + amount, Config.player_max_health)


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_for_next_level():
		xp -= xp_for_next_level()
		level += 1
		Sfx.play("levelup", 0.0, 0.0)
		leveled_up.emit(level)


## EP, die für die nächste Stufe nötig sind.
func xp_for_next_level() -> int:
	return Config.xp_first_level + Config.xp_level_step * (level - 1)


func show_heal(amount: float) -> void:
	_spawn_number(amount, Color(0.4, 1, 0.5), "+")


func drink_potion() -> void:
	if not is_alive() or potions <= 0 or health >= Config.player_max_health:
		return
	potions -= 1
	heal(Config.potion_heal)
	Sfx.play("pickup", 0.0, 0.0)
	_spawn_number(Config.potion_heal, Color(0.4, 1, 0.5), "+")


func _spawn_number(amount: float, col: Color, prefix := "") -> void:
	var num := Label3D.new()
	num.set_script(preload("res://scripts/damage_number.gd"))
	num.setup(amount, col)
	num.text = prefix + num.text
	get_parent().add_child(num)
	num.global_position = global_position + Vector3(0, 2.4, 0)


# --- Talismane (v0.3) ------------------------------------------------------------

func has_talisman(id: String) -> bool:
	return equipped.has(id)


## Einen zufälligen, noch nicht gefundenen Talisman finden. source: wer ihn gebracht hat (für die Meldung).
## Gibt die id zurück ("" = alle schon gefunden -> stattdessen EP).
func find_talisman(source: String) -> String:
	var pool := []
	for id in TalismanData.DEFS:
		if not talismans.has(id):
			pool.append(id)
	if pool.is_empty():
		gain_xp(8)
		get_tree().call_group("hud", "toast", "Nichts Neues – aber Erfahrung (+8 EP)")
		return ""
	var id: String = pool[randi() % pool.size()]
	gain_talisman(id)
	get_tree().call_group("hud", "toast", "Talisman: %s (von %s)" % [TalismanData.name_of(id), source], 4.0)
	return id


func gain_talisman(id: String) -> void:
	if talismans.has(id):
		return
	talismans.append(id)
	Sfx.play("levelup", -4.0, 0.0)
	if equipped.size() < Config.talisman_slots:
		equipped.append(id)
		skill_bar.reset_cycle()
		get_tree().call_group("hud", "toast", "Angelegt: " + TalismanData.name_of(id), 4.0)
	else:
		get_tree().call_group("hud", "toast", "Am Feuer unter „Leiste umbauen“ anlegen", 4.0)


## Talisman an- oder ablegen (nur am Feuer). Gibt false zurück, wenn kein Platz frei ist.
func toggle_talisman(id: String) -> bool:
	if equipped.has(id):
		equipped.erase(id)
	elif equipped.size() < Config.talisman_slots:
		equipped.append(id)
	else:
		return false
	skill_bar.reset_cycle()
	return true


## Turm besteigen: oben stehen, nicht laufen, mit mehr Reichweite schießen.
func climb(tower: Node3D) -> void:
	on_tower = tower
	skill_bar.interrupt()
	velocity = Vector3.ZERO
	global_position = tower.top_position()
	Sfx.play("gate", -4.0)


## Vom Turm herabsteigen: unten vor dem Turm abstellen.
func descend() -> void:
	if on_tower == null:
		return
	var spot: Vector3 = on_tower.work_spot()
	on_tower = null
	skill_bar.interrupt()
	global_position = spot
	Sfx.play("gate", -4.0)


## Zusätzliche Reichweite (auf dem Turm).
func range_bonus() -> float:
	return on_tower.climb_range_bonus() if on_tower else 0.0


func _die() -> void:
	on_tower = null
	health = 0.0
	dead_timer = Config.respawn_delay
	Sfx.play("death", 0.0, 0.0)
	model.visible = false
	skill_bar.interrupt()
	died.emit()


func _respawn() -> void:
	on_tower = null
	madness.add(-Config.madness_death_relief)   # der Tod klärt den Geist etwas
	health = Config.player_max_health
	potions = Config.potions_start
	lantern.fuel = Config.lantern_burn_time
	model.visible = true
	protect_timer = Config.respawn_protection
	if respawn_point:
		global_position = respawn_point.global_position + Vector3(0, 0, 2.5)
	respawned.emit()


func _physics_process(delta: float) -> void:
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	hurt_flash = maxf(hurt_flash - delta, 0.0)
	if protect_timer > 0.0:
		protect_timer -= delta
		model.visible = fmod(protect_timer, 0.2) > 0.1 or protect_timer <= 0.0   # blinkt
	if not is_alive():
		dead_timer -= delta
		if dead_timer <= 0.0:
			_respawn()
		return

	# Am Feuer: langsam heilen, Tränke auffüllen, Trage abladen
	if Lights.refill_source_at(global_position) != null:
		heal(Config.fire_heal_per_second * delta)
		if Config.potions_refill_at_fire:
			potions = Config.potions_start
		_unload()
	if Input.is_action_just_pressed("potion"):
		drink_potion()
	if on_tower:
		_tower_step(delta)
		return
	_gather(delta)

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move := Vector3.ZERO
	if input.length() > 0.05 and camera_rig:
		move = camera_rig.screen_to_ground(input)
		if move.length() > 1.0 or not Config.joystick_analog:
			move = move.normalized()
		facing = move.normalized()
	elif _dash_time <= 0.0:
		face_nearest_enemy()   # steht er still, schaut er zum nächsten Gegner

	if Input.is_action_just_pressed("dash"):
		try_dash()

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = _dash_dir * Config.dash_speed
	else:
		velocity = move * Config.player_speed

	move_and_slide()
	global_position.y = 0.0

	# Figur in Blickrichtung drehen
	var target_angle := atan2(facing.x, facing.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_angle, 1.0 - exp(-40.0 * delta))
	# kleiner Effekt: beim Dash flacher/länger
	var s := 1.0 if _dash_time <= 0.0 else 0.8
	model.scale = model.scale.lerp(Vector3(1, s, 1), 0.4)

	DebugOverlay.watch("Pos", "%.1f / %.1f" % [global_position.x, global_position.z])
	DebugOverlay.watch("Stufe", "%d (EP %d/%d)" % [level, xp, xp_for_next_level()])


## Auf dem Turm: steht oben fest, dreht sich zum nächsten Gegner.
func _tower_step(delta: float) -> void:
	velocity = Vector3.ZERO
	global_position = on_tower.top_position()
	face_nearest_enemy()
	var target_angle := atan2(facing.x, facing.z)
	model.rotation.y = lerp_angle(model.rotation.y, target_angle, 1.0 - exp(-40.0 * delta))


func try_dash() -> void:
	if on_tower:
		return   # auf dem Turm kein Dash
	if _dash_cd > 0.0 or _dash_time > 0.0:
		return
	_dash_dir = facing
	skill_bar.interrupt()   # Dash unterbricht den aktuellen Cast
	_dash_time = Config.dash_duration
	_dash_cd = Config.dash_cooldown
	dashed.emit()


## Dreht den Hüter zum nächsten Gegner, falls einer in Kampfreichweite ist.
func face_nearest_enemy() -> void:
	var e: Node3D = combat.nearest_enemy(Config.combat_range + range_bonus())
	if e:
		var to := e.global_position - global_position
		to.y = 0
		if to.length() > 0.1:
			facing = to.normalized()


func carry_total() -> int:
	return carry["wood"] + carry["food"] + carry["stone"]


## Bleibt der Hüter neben einer Pilzstelle oder einem Baum stehen, sammelt bzw. hackt er automatisch.
## Im Laufen nicht – sonst würde er beim Durchqueren des Waldes ständig nebenbei hacken.
var _gather_key := ""

func _gather(delta: float) -> void:
	var node: Node3D = null
	var tree := -1
	var forest := get_tree().get_first_node_in_group("forest")
	if velocity.length() < 0.1:
		for r in get_tree().get_nodes_in_group("resources"):
			if r.is_available() and _flat(r.global_position).distance_to(_flat(global_position)) < Config.gather_range:
				node = r
				break
		if node == null:
			for r in get_tree().get_nodes_in_group("rocks"):
				if r.is_available() and _flat(r.global_position).distance_to(_flat(global_position)) < r.reach():
					node = r
					break
		if node == null and forest:
			tree = forest.nearest(global_position, Config.gather_range)
	var key := str(node.get_instance_id()) if node else ("tree%d" % tree if tree >= 0 else "")
	if key != _gather_key:
		_gather_key = key
		_gather_t = 0.0
	if key == "":
		_full_warned = false
		return
	if carry_total() >= Config.carry_capacity:
		if not _full_warned:
			_full_warned = true
			get_tree().call_group("hud", "toast", "Trage voll (%d)" % Config.carry_capacity)
		return
	_gather_t += delta
	if _gather_t >= Config.gather_seconds:
		_gather_t = 0.0
		var kind: String = ("stone" if node.is_in_group("rocks") else node.kind) if node else "wood"
		var ok: bool = node.take_one() if node else forest.take_one(tree)
		if ok:
			carry[kind] += 1
			Sfx.play("pickup" if kind == "food" else "hit", -6.0)
			var col: Color = {"wood": Color(1, 0.75, 0.45), "food": Color(0.5, 1, 0.85), "stone": Color(0.8, 0.8, 0.9)}[kind]
			var num := Label3D.new()
			num.set_script(preload("res://scripts/damage_number.gd"))
			num.setup(1, col)
			num.text = "+1 " + {"wood": "Holz", "food": "Nahrung", "stone": "Stein"}[kind]
			get_parent().add_child(num)
			num.global_position = global_position + Vector3(0, 2.4, 0)


## Am Feuer: Trage in die Festung abladen.
func _unload() -> void:
	if carry_total() == 0:
		return
	var fort := get_tree().get_first_node_in_group("fortress")
	if fort == null:
		return
	var gave: Dictionary = fort.deposit(carry)
	var parts := []
	if gave["wood"] > 0:
		parts.append("+%d Holz" % gave["wood"])
	if gave["food"] > 0:
		parts.append("+%d Nahrung" % gave["food"])
	if gave["stone"] > 0:
		parts.append("+%d Stein" % gave["stone"])
	if not parts.is_empty():
		get_tree().call_group("hud", "toast", "Abgeladen: " + ", ".join(parts))
	elif carry_total() > 0 and not _full_warned:
		_full_warned = true
		get_tree().call_group("hud", "toast", "Lager voll – Vorratslager bauen!")


func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)
