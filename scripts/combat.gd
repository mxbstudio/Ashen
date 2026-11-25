## Führt die Angriffe des Hüters aus und wendet Modifikatoren an.
## Hängt als Kind am Hüter ("Combat").
extends Node

const ArrowScript := preload("res://scripts/arrow.gd")
const SlashScript := preload("res://scripts/slash_effect.gd")
const WaveScript := preload("res://scripts/bell_wave.gd")

@onready var player: Node3D = get_parent()


## Alle lebenden Gegner (alles in der Gruppe "enemies").
func enemies() -> Array:
	var out := []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_alive():
			out.append(e)
	return out


## Nächster Gegner in Reichweite, zu dem freie Sicht besteht.
func nearest_enemy(max_range: float) -> Node3D:
	var candidates := []
	for e in enemies():
		var d := _flat_dist(e.global_position, player.global_position)
		if d <= max_range:
			candidates.append([d, e])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	for c in candidates:
		if has_line_of_sight(c[1]):
			return c[1]
	return null


## Freie Sicht vom Hüter zum Gegner? (Welt und Tor blockieren, Gegner nicht)
func has_line_of_sight(e: Node3D) -> bool:
	var space := player.get_world_3d().direct_space_state
	var from: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	var to: Vector3 = e.global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 16)
	q.exclude = [player.get_rid()]
	return space.intersect_ray(q).is_empty()


func enemy_near() -> bool:
	return nearest_enemy(Config.combat_range) != null


func _lvl(id: String) -> int:
	return player.skill_bar.level_of(id)


## Einen Angriff ausführen. mods = vorgemerkte Modifikatoren.
func perform(id: String, mods: Array) -> void:
	var repeats := 1 + mods.count("echo")
	# Schaden wächst mit der Stufe des Angriffs
	var dmg_mult := 1.0 + Config.skill_damage_per_level * (_lvl(id) - 1)
	for i in mods.count("sacrifice"):
		dmg_mult *= Config.sacrifice_multiplier + Config.sacrifice_per_level * (_lvl("sacrifice") - 1)
		player.lantern.drain(Config.sacrifice_lantern_cost)
	for r in repeats:
		if r > 0:
			await get_tree().create_timer(0.18).timeout
		if not is_instance_valid(player) or not player.is_alive():
			return
		# Labung: der erste Treffer dieses Angriffs heilt (einmal pro Wiederholung)
		var mend_amount := Config.mend_heal + Config.mend_heal_per_level * (_lvl("mend") - 1)
		var heal := {"amount": mend_amount * mods.count("mend")}
		Sfx.play("swing" if id in ["sickle", "bell"] else "shoot")
		match id:
			"sickle": _sickle(dmg_mult, heal)
			"bow": _bow(dmg_mult, heal)
			"ember": _ember(dmg_mult, heal)
			"bell": _bell(dmg_mult, heal)


## Treffer austeilen. heal ist ein gemeinsamer "Heil-Gutschein" (Labung):
## der erste Treffer löst ihn ein, danach ist er leer.
func hit(target: Node3D, amount: float, heal: Dictionary) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	target.take_damage(amount, player)
	if heal.get("amount", 0.0) > 0.0:
		player.heal(heal["amount"])
		player.show_heal(heal["amount"])
		heal["amount"] = 0.0


func _sickle(mult: float, heal: Dictionary) -> void:
	# Ohne Bewegung dreht sich der Hüter zum nächsten Gegner
	player.face_nearest_enemy()
	var fwd: Vector3 = player.facing
	var half := deg_to_rad(Config.sickle_angle) / 2.0
	var reach := Config.sickle_range + Config.sickle_range_per_level * (_lvl("sickle") - 1)
	for e in enemies():
		var to: Vector3 = e.global_position - player.global_position
		to.y = 0
		if to.length() > reach + e.hit_radius or not has_line_of_sight(e):
			continue
		if to.length() > 0.3 and fwd.angle_to(to.normalized()) > half:
			continue
		hit(e, Config.sickle_damage * mult, heal)
	var fx := MeshInstance3D.new()
	fx.set_script(SlashScript)
	fx.setup(reach, Config.sickle_angle, mult > 1.0)
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + Vector3(0, 0.7, 0)
	fx.rotation.y = atan2(fwd.x, fwd.z)


func _bow(mult: float, heal: Dictionary) -> void:
	_shoot(Config.bow_damage * mult, heal, false)


func _ember(mult: float, heal: Dictionary) -> void:
	_shoot(Config.ember_damage * mult, heal, true)


## Geschoss auf den nächsten Gegner (Pfeil oder Glut).
func _shoot(damage: float, heal: Dictionary, burning: bool) -> void:
	var target := nearest_enemy(Config.bow_range)
	if target == null:
		return
	var arrow := Node3D.new()
	arrow.set_script(ArrowScript)
	player.get_parent().add_child(arrow)
	arrow.global_position = player.global_position + Vector3(0, 1.1, 0)
	arrow.launch(target, damage, heal, self, burning)
	if burning:
		arrow.burn_dps = Config.ember_burn_dps + Config.ember_burn_per_level * (_lvl("ember") - 1)


## Glockenschlag: Schockwelle rundum, stößt Gegner zurück.
func _bell(mult: float, heal: Dictionary) -> void:
	var radius := Config.bell_radius + Config.bell_radius_per_level * (_lvl("bell") - 1)
	for e in enemies():
		var to: Vector3 = e.global_position - player.global_position
		to.y = 0
		if to.length() > radius + e.hit_radius or not has_line_of_sight(e):
			continue
		hit(e, Config.bell_damage * mult, heal)
		var dir := to.normalized() if to.length() > 0.1 else Vector3(1, 0, 0)
		var falloff := 1.0 - clampf(to.length() / (radius + 1.0), 0.0, 0.7)
		e.knockback(dir * Config.bell_knockback * falloff)
	Sfx.play("slam", -4.0)
	var fx := MeshInstance3D.new()
	fx.set_script(WaveScript)
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + Vector3(0, 0.1, 0)
	fx.setup(radius, mult > 1.0)


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
