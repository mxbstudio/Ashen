## Führt die Angriffe des Hüters aus und wendet Modifikatoren an.
## Hängt als Kind am Hüter ("Combat").
extends Node

const ArrowScript := preload("res://scripts/arrow.gd")
const SlashScript := preload("res://scripts/slash_effect.gd")

@onready var player: Node3D = get_parent()


## Alle lebenden Gegner (alles in der Gruppe "enemies").
func enemies() -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_alive():
			out.append(e)
	return out


func nearest_enemy(max_range: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_range
	for e in enemies():
		var d := _flat_dist(e.global_position, player.global_position)
		if d <= best_d:
			best_d = d
			best = e
	return best


func enemy_near() -> bool:
	return nearest_enemy(Config.combat_range) != null


## Einen Angriff ausführen. mods = vorgemerkte Modifikatoren.
func perform(id: String, mods: Array) -> void:
	var repeats := 1 + mods.count("echo")
	var dmg_mult := 1.0
	for i in mods.count("sacrifice"):
		dmg_mult *= Config.sacrifice_multiplier
		player.lantern.drain(Config.sacrifice_lantern_cost)
	var heal := Config.mend_heal * mods.count("mend")
	for r in repeats:
		if r > 0:
			await get_tree().create_timer(0.18).timeout
		if not is_instance_valid(player):
			return
		match id:
			"sickle": _sickle(dmg_mult, heal)
			"bow": _bow(dmg_mult, heal)
			_: DebugOverlay.note("%s kommt in Etappe 5" % SkillData.DEFS[id]["name"])


## Treffer austeilen (+ ggf. Heilung durch Labung).
func hit(target: Node3D, amount: float, heal: float) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	target.take_damage(amount, player)
	if heal > 0.0 and player.has_method("heal"):
		player.heal(heal)


func _sickle(mult: float, heal: float) -> void:
	# Ohne Bewegung dreht sich der Hüter zum nächsten Gegner
	player.face_nearest_enemy()
	var fwd: Vector3 = player.facing
	var half := deg_to_rad(Config.sickle_angle) / 2.0
	for e in enemies():
		var to: Vector3 = e.global_position - player.global_position
		to.y = 0
		if to.length() > Config.sickle_range + e.hit_radius:
			continue
		if to.length() > 0.3 and fwd.angle_to(to.normalized()) > half:
			continue
		hit(e, Config.sickle_damage * mult, heal)
	var fx := MeshInstance3D.new()
	fx.set_script(SlashScript)
	fx.setup(Config.sickle_range, Config.sickle_angle, mult > 1.0)
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + Vector3(0, 0.7, 0)
	fx.rotation.y = atan2(fwd.x, fwd.z)


func _bow(mult: float, heal: float) -> void:
	var target := nearest_enemy(Config.bow_range)
	if target == null:
		return
	var arrow := Node3D.new()
	arrow.set_script(ArrowScript)
	player.get_parent().add_child(arrow)
	arrow.global_position = player.global_position + Vector3(0, 1.1, 0)
	arrow.launch(target, Config.bow_damage * mult, heal, self)


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
