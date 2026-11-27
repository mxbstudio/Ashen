## Führt die Angriffe des Hüters aus und wendet Modifikatoren an.
## Hängt als Kind am Hüter ("Combat").
##
## v0.3: Zustände & Kombos, Abzweigungen, Talismane, Wahnsinn und dunkle Skills.
## Jeder Angriff trägt einen "ctx" (Kontext) mit sich: welcher Skill, Heilung (Labung), Brand (Zündschnur) …
## Der Pfeil gibt ihn beim Aufprall an hit() zurück.
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
	var list := nearest_enemies(max_range, 1)
	return list[0] if not list.is_empty() else null


## Die n nächsten Gegner in Reichweite mit freier Sicht.
func nearest_enemies(max_range: float, n: int) -> Array:
	var candidates := []
	for e in enemies():
		var d := _flat_dist(e.global_position, player.global_position)
		if d <= max_range:
			candidates.append([d, e])
	candidates.sort_custom(func(a, b): return a[0] < b[0])
	var out := []
	for c in candidates:
		if out.size() >= n:
			break
		if has_line_of_sight(c[1]):
			out.append(c[1])
	return out


## Freie Sicht vom Hüter zum Gegner? (Welt und Tor blockieren, Gegner nicht)
func has_line_of_sight(e: Node3D) -> bool:
	var space := player.get_world_3d().direct_space_state
	var from: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	var to: Vector3 = e.global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 16)
	q.exclude = [player.get_rid()]
	return space.intersect_ray(q).is_empty()


## Reichweite eines Angriffs (m) – erst wenn ein Gegner so nah ist, lädt das Feld.
func skill_range(id: String) -> float:
	match id:
		"sickle": return Config.sickle_range + Config.sickle_range_per_level * (_lvl("sickle") - 1) + 0.6
		"bow", "ember", "lance": return Config.bow_range + player.range_bonus()
		"bell": return Config.bell_radius + Config.bell_radius_per_level * (_lvl("bell") - 1) + 0.5
		"rift": return Config.rift_length * (2.0 if _br("rift", "a") else 1.0)
		"scream": return Config.scream_radius + 0.5
		"purge": return Config.purge_radius + 0.5
	return Config.combat_range + player.range_bonus()


func in_range(id: String) -> bool:
	return nearest_enemy(skill_range(id)) != null


## Hat irgendein Angriff der Leiste einen Gegner in Reichweite (+ Config.bar_range_margin)?
func bar_in_range() -> bool:
	var best := 0.0
	for id in player.skill_bar.slots:
		if SkillData.is_attack(id):
			best = maxf(best, skill_range(id))
	return best > 0.0 and nearest_enemy(best + Config.bar_range_margin) != null


func enemy_near() -> bool:
	return nearest_enemy(Config.combat_range + player.range_bonus()) != null


func _lvl(id: String) -> int:
	return player.skill_bar.level_of(id)


func _br(id: String, b: String) -> bool:
	return player.skill_bar.has_branch(id, b)


func _tal(id: String) -> bool:
	return player.has_talisman(id)


## Einen Angriff ausführen. mods = vorgemerkte Modifikatoren, mult = zusätzlicher Faktor (Spiegel),
## extra = zusätzliche Wiederholungen (Glockenseil).
func perform(id: String, mods: Array, mult := 1.0, extra := 0) -> void:
	var echoes := mods.count("echo") * (2 if _br("echo", "b") else 1)
	var repeats := 1 + echoes + extra
	# Schaden wächst mit der Stufe des Angriffs
	var dmg_mult := mult * (1.0 + Config.skill_damage_per_level * (_lvl(id) - 1))
	for i in mods.count("sacrifice"):
		dmg_mult *= Config.sacrifice_multiplier + Config.sacrifice_per_level * (_lvl("sacrifice") - 1)
		if _br("sacrifice", "a"):
			player.take_damage(6.0, null, true)
		elif _br("sacrifice", "b"):
			player.madness.add(5.0)
		else:
			player.lantern.drain(Config.sacrifice_lantern_cost)
	for i in mods.count("pact"):
		var strength := 1.0 + 0.1 * (_lvl("pact") - 1)
		if _br("pact", "a"):
			strength *= 2.0
		elif _br("pact", "b"):
			strength *= 0.5
		dmg_mult *= 1.0 + (100.0 - player.madness.value) / 50.0 * strength   # klarer Geist: stärker
		if not _br("pact", "b"):
			player.madness.add(Config.pact_madness * (2.0 if _br("pact", "a") else 1.0))
	dmg_mult *= 1.0 + Config.oath_next * mods.count("oath")
	dmg_mult *= 1.0 + player.skill_bar.round_bonus
	dmg_mult *= 1.0 + player.madness.damage_bonus()
	if _tal("ashheart") and player.lantern.fraction() < 0.3:
		dmg_mult *= 1.4
	if SkillData.is_light(id):
		dmg_mult *= 0.7 + 0.6 * player.madness.value / 100.0   # Licht-Skills: je wahnsinniger, desto stärker
		var calm := Config.purge_madness if id == "purge" else Config.lance_madness
		if id == "purge" and _br("purge", "b"):
			calm *= 2.0
			dmg_mult *= 0.5
		player.madness.add(-calm)
	for i in mods.count("vigil"):
		var v := Config.vigil_madness + (_lvl("vigil") - 1)
		player.madness.add(-v * (2.0 if _br("vigil", "a") else 1.0))
		if _br("vigil", "b"):
			dmg_mult *= 1.2
	if SkillData.is_dark(id):
		dmg_mult *= 1.3 - 0.6 * player.madness.value / 100.0   # Dunkel-Skills: je klarer der Geist, desto stärker
		if _tal("madstone"):
			dmg_mult *= 1.5
		player.madness.add(Config.rift_madness if id == "rift" else Config.scream_madness)
	# Brand aus Zündschnur oder Glutkrone
	var burn_dps := 0.0
	var burn_time := Config.ember_burn_time
	if mods.has("kindle"):
		burn_dps = (Config.kindle_burn_dps + Config.kindle_per_level * (_lvl("kindle") - 1)) * mods.count("kindle")
		if _br("kindle", "a"):
			burn_dps *= 2.0
		if _br("kindle", "b"):
			burn_time *= 3.0
	if _tal("crown"):
		burn_dps = maxf(burn_dps, 2.0)
	if id == "purge" and _br("purge", "a"):
		burn_dps = maxf(burn_dps, 3.0)   # Heilige Flamme
	for r in repeats:
		if r > 0:
			await get_tree().create_timer(0.18).timeout
		if not is_instance_valid(player) or not player.is_alive():
			return
		var rep_mult := dmg_mult
		if r > 0 and r <= echoes and _br("echo", "a"):
			rep_mult *= 0.6   # Nachhall
		# Labung: der erste Treffer dieses Angriffs heilt (einmal pro Wiederholung)
		var mend_amount := Config.mend_heal + Config.mend_heal_per_level * (_lvl("mend") - 1)
		var ctx := {"heal": mend_amount * mods.count("mend"), "skill": id,
				"burn": burn_dps, "burn_time": burn_time}
		Sfx.play("swing" if id in ["sickle", "bell", "rift", "purge"] else "shoot")
		match id:
			"sickle": _sickle(rep_mult, ctx)
			"bow": _bow(rep_mult, ctx)
			"ember": _ember(rep_mult, ctx)
			"bell": _bell(rep_mult, ctx)
			"rift": _rift(rep_mult, ctx)
			"scream": _scream(rep_mult, ctx)
			"purge": _purge(rep_mult, ctx)
			"lance": _lance(rep_mult, ctx)


## Treffer austeilen. ctx["heal"] ist ein gemeinsamer "Heil-Gutschein" (Labung):
## der erste Treffer löst ihn ein, danach ist er leer (mit „Lebensband“ heilt jeder Treffer etwas).
## Hier passieren auch die Kombos.
func hit(target: Node3D, amount: float, ctx: Dictionary) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	var skill: String = ctx.get("skill", "")
	var boss: bool = target.is_in_group("boss")
	# --- Kombos ---
	if skill == "sickle" and target.is_staggered():
		amount *= Config.combo_shatter
		_combo(target, "Zerschmettern!")
	if skill == "bell" and target.is_burning():
		var burst: float = target.burn_left() * Config.combo_kindle
		target.extinguish()
		amount += burst
		_combo(target, "Entfachen!")
	if skill == "bow" and target.is_burning():
		_combo(target, "Flammenpfeil!")
		_explode(target.global_position, Config.combo_flamearrow_radius, amount * 0.5, target, 3.0)
	if skill == "sickle" and _br("sickle", "b"):
		var limit: float = target.max_hp * (0.1 if boss else 0.25)
		if target.hp - amount <= limit:
			amount = target.hp   # Ernte
			if not boss:
				_combo(target, "Ernte")
	var dealt: float = minf(amount, target.hp)
	target.take_damage(amount, player)
	# --- Heilung ---
	var h: float = ctx.get("heal", 0.0)
	if h > 0.0:
		var give := h * 0.4 if _br("mend", "a") else h
		_heal(give)
		if not _br("mend", "a"):
			ctx["heal"] = 0.0
	if skill == "rift" and _br("rift", "b"):
		_heal(dealt * 0.2)
	# --- Zustände ---
	if target.is_alive():
		if ctx.get("burn", 0.0) > 0.0:
			target.ignite(ctx["burn"], ctx.get("burn_time", Config.ember_burn_time))
		if skill == "bow" and _br("bow", "b"):
			target.mark(Config.mark_time)
	if skill == "bell" and _br("bell", "b"):
		_lantern(1.0)
	if skill == "scream" and _br("scream", "b"):
		_lantern(2.0)


func _heal(amount: float) -> void:
	if amount <= 0.0:
		return
	var over: float = player.health + amount - Config.player_max_health
	player.heal(amount)
	player.show_heal(amount)
	if over > 0.0 and _br("mend", "b"):
		_lantern(over)   # Überfluss


func _lantern(seconds: float) -> void:
	player.lantern.fuel = minf(player.lantern.fuel + seconds, Config.lantern_burn_time)


## Kombo-Schriftzug über dem Gegner.
func _combo(target: Node3D, text: String) -> void:
	var num := Label3D.new()
	num.set_script(preload("res://scripts/damage_number.gd"))
	num.setup(0, Color(1, 0.95, 0.4))
	num.text = text
	num.font_size = 40
	player.get_parent().add_child(num)
	num.global_position = target.global_position + Vector3(0, 2.6, 0)


## Explosion: Schaden (und Brand) an allen Gegnern im Umkreis außer except.
func _explode(pos: Vector3, radius: float, dmg: float, except: Node3D, burn: float) -> void:
	for e in enemies():
		if e == except:
			continue
		if _flat_dist(e.global_position, pos) <= radius + e.hit_radius:
			e.take_damage(dmg, player)
			if burn > 0.0 and e.is_alive():
				e.ignite(burn, Config.ember_burn_time)
	var fx := MeshInstance3D.new()
	fx.set_script(WaveScript)
	player.get_parent().add_child(fx)
	fx.global_position = pos + Vector3(0, 0.3, 0)
	fx.setup(radius, true)


## Ein Gegner ist gestorben (vom Gegner gemeldet).
func on_enemy_died(e: Node3D, was_burning: bool) -> void:
	player.skill_bar.on_kill()
	if was_burning and _br("ember", "b"):
		_combo(e, "Funkentod!")
		_explode(e.global_position, 3.0, 8.0 * (1.0 + Config.skill_damage_per_level * (_lvl("ember") - 1)),
				e, Config.ember_burn_dps)
	if e.is_in_group("boss"):
		player.find_talisman("dem Hauptmann")
	elif e.get("is_lost") and randf() < Config.lost_talisman_chance:
		player.find_talisman("einem Verlorenen")


func _sickle(mult: float, ctx: Dictionary) -> void:
	# Ohne Bewegung dreht sich der Hüter zum nächsten Gegner
	player.face_nearest_enemy()
	var fwd: Vector3 = player.facing
	var whirl := _br("sickle", "a")
	var angle := 360.0 if whirl else Config.sickle_angle
	if whirl:
		mult *= 0.8
	var half := deg_to_rad(angle) / 2.0
	var reach := Config.sickle_range + Config.sickle_range_per_level * (_lvl("sickle") - 1)
	for e in enemies():
		var to: Vector3 = e.global_position - player.global_position
		to.y = 0
		if to.length() > reach + e.hit_radius or not has_line_of_sight(e):
			continue
		if not whirl and to.length() > 0.3 and fwd.angle_to(to.normalized()) > half:
			continue
		hit(e, Config.sickle_damage * mult, ctx)
	var fx := MeshInstance3D.new()
	fx.set_script(SlashScript)
	fx.setup(reach, minf(angle, 359.0), mult > 1.0)
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + Vector3(0, 0.7, 0)
	fx.rotation.y = atan2(fwd.x, fwd.z)


func _bow(mult: float, ctx: Dictionary) -> void:
	if _br("bow", "a"):
		_shoot(Config.bow_damage * mult * 0.5, ctx, false, 3)   # Salve
	else:
		_shoot(Config.bow_damage * mult, ctx, false, 1)


func _ember(mult: float, ctx: Dictionary) -> void:
	_shoot(Config.ember_damage * mult, ctx, true, 1)


## Geschoss(e) auf die nächsten Gegner (Pfeil oder Glut). Die Splitterlinse trifft einen mehr.
func _shoot(damage: float, ctx: Dictionary, burning: bool, count: int) -> void:
	if _tal("lens"):
		count += 1
	var targets := nearest_enemies(Config.bow_range + player.range_bonus(), count)
	for target in targets:
		var arrow := Node3D.new()
		arrow.set_script(ArrowScript)
		player.get_parent().add_child(arrow)
		arrow.global_position = player.global_position + Vector3(0, 1.1, 0)
		var c := ctx if target == targets[0] else ctx.duplicate()
		if target != targets[0]:
			c["heal"] = 0.0
		arrow.launch(target, damage, c, self, burning)
		if burning:
			arrow.burn_dps = Config.ember_burn_dps + Config.ember_burn_per_level * (_lvl("ember") - 1)


## Glut schlägt ein: mit „Flächenbrand“ brennen alle in der Nähe mit.
func ember_impact(pos: Vector3, dps: float) -> void:
	if not _br("ember", "a"):
		return
	for e in enemies():
		if _flat_dist(e.global_position, pos) <= 2.5 + e.hit_radius:
			e.ignite(dps, Config.ember_burn_time)


## Glockenschlag: Schockwelle rundum, stößt Gegner zurück (oder zieht sie heran) und erschüttert sie.
func _bell(mult: float, ctx: Dictionary) -> void:
	var radius := Config.bell_radius + Config.bell_radius_per_level * (_lvl("bell") - 1)
	for e in enemies():
		var to: Vector3 = e.global_position - player.global_position
		to.y = 0
		if to.length() > radius + e.hit_radius or not has_line_of_sight(e):
			continue
		hit(e, Config.bell_damage * mult, ctx)
		if not is_instance_valid(e) or not e.is_alive():
			continue
		e.stagger(Config.stagger_time)
		var dir := to.normalized() if to.length() > 0.1 else Vector3(1, 0, 0)
		var falloff := 1.0 - clampf(to.length() / (radius + 1.0), 0.0, 0.7)
		if _br("bell", "a"):
			e.knockback(-dir * minf(Config.bell_knockback * 0.8, to.length() * 6.0))   # Sog
		else:
			e.knockback(dir * Config.bell_knockback * falloff)
	Sfx.play("slam", -4.0)
	var fx := MeshInstance3D.new()
	fx.set_script(WaveScript)
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + Vector3(0, 0.1, 0)
	fx.setup(radius, mult > 1.0)


## Schattenriss: trifft alles in einer Linie vor dem Hüter. Stärker mit Wahnsinn.
func _rift(mult: float, ctx: Dictionary) -> void:
	player.face_nearest_enemy()
	var fwd: Vector3 = player.facing
	var length := Config.rift_length * (2.0 if _br("rift", "a") else 1.0)
	var dmg: float = Config.rift_damage * mult
	var hits := 0
	var max_hits := 99
	for e in enemies():
		var to: Vector3 = e.global_position - player.global_position
		to.y = 0
		var along := to.dot(fwd)
		if along < -0.5 or along > length:
			continue
		var side := (to - fwd * along).length()
		if side > 1.0 + e.hit_radius:
			continue
		hit(e, dmg, ctx)
		hits += 1
		if hits >= max_hits:
			break
	# Bild: dunkler, langer Streifen
	var fx := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.2, 0.08, length)
	fx.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.55, 0.15, 0.85, 0.7)
	fx.material_override = mat
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + fwd * (length / 2.0) + Vector3(0, 0.4, 0)
	fx.rotation.y = atan2(fwd.x, fwd.z)
	var tw := fx.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(fx.queue_free)


## Läuterung: Lichtwelle rundum.
func _purge(mult: float, ctx: Dictionary) -> void:
	for e in enemies():
		if _flat_dist(e.global_position, player.global_position) > Config.purge_radius + e.hit_radius:
			continue
		if has_line_of_sight(e):
			hit(e, Config.purge_damage * mult, ctx)
	Sfx.play("ignite", -4.0, 0.2)
	var fx := MeshInstance3D.new()
	fx.set_script(WaveScript)
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + Vector3(0, 0.3, 0)
	fx.setup(Config.purge_radius, false)


## Lichtlanze: Strahl auf den nächsten Gegner (mit „Durchbohren“ auf alle in der Linie).
func _lance(mult: float, ctx: Dictionary) -> void:
	var target := nearest_enemy(skill_range("lance"))
	if target == null:
		return
	var dir: Vector3 = target.global_position - player.global_position
	dir.y = 0
	var length := dir.length()
	dir = dir.normalized()
	player.facing = dir
	var victims := [target]
	if _br("lance", "a"):
		length = skill_range("lance")
		for e in enemies():
			if e == target:
				continue
			var to: Vector3 = e.global_position - player.global_position
			to.y = 0
			var along := to.dot(dir)
			if along > 0.0 and along < length and (to - dir * along).length() < 0.9 + e.hit_radius:
				victims.append(e)
	for e in victims:
		hit(e, Config.lance_damage * mult, ctx)
		if _br("lance", "b") and is_instance_valid(e) and e.is_alive():
			e.stagger(2.0)
	_beam(player.global_position, dir, length, Color(1, 0.95, 0.6, 0.85), 0.5)


## Lichtstrahl / Schattenstreifen (verblasst schnell).
func _beam(from: Vector3, dir: Vector3, length: float, col: Color, width: float) -> void:
	var fx := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.08, length)
	fx.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	fx.material_override = mat
	player.get_parent().add_child(fx)
	fx.global_position = from + dir * (length / 2.0) + Vector3(0, 1.0, 0)
	fx.rotation.y = atan2(dir.x, dir.z)
	var tw := fx.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.3)
	tw.tween_callback(fx.queue_free)


## Leerenschrei: Gegner rundum nehmen Schaden und fliehen voller Furcht.
func _scream(mult: float, ctx: Dictionary) -> void:
	var fear := Config.scream_fear * (2.0 if _br("scream", "a") else 1.0)
	for e in enemies():
		if _flat_dist(e.global_position, player.global_position) > Config.scream_radius + e.hit_radius:
			continue
		hit(e, Config.scream_damage * mult, ctx)
		if is_instance_valid(e) and e.is_alive():
			e.frighten(fear)
	Sfx.play("omen", -2.0, 0.3)
	var fx := MeshInstance3D.new()
	fx.set_script(WaveScript)
	player.get_parent().add_child(fx)
	fx.global_position = player.global_position + Vector3(0, 0.1, 0)
	fx.setup(Config.scream_radius, true)


func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
