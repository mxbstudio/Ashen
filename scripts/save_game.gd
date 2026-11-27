## Speicherstand im Browser (Godot legt "user://" im Web im Speicher des Browsers ab).
## - Speichert automatisch alle Config.autosave_interval Sekunden und wenn der Browser-Tab verlassen wird.
## - Nicht während einer Belagerung, nicht während der Hüter tot ist und nicht nach Spielende.
## - Gespeichert wird, was man sich für "später weiterspielen" merken muss. Gegner nicht (die erscheinen neu).
## - Laden geschieht über das Startfenster (ui/continue_panel.gd): apply().
extends Node

const PATH := "user://spielstand.json"
const SmallTorch := preload("res://scripts/zones/small_torch.gd")
const FirePit := preload("res://scripts/zones/fire_pit.gd")
const VERSION := 2                  # 2 = v0.3 (Wahnsinn, Talismane, Bewohner mit Namen); 1 wird noch gelesen

@export var player: Node3D
@export var fortress: Node3D
@export var siege: Node
@export var beacon: Node3D

var play_time := 0.0               # Sekunden gespielte Zeit (nur für die Anzeige)
var enabled := false               # erst nach der Wahl im Startfenster speichern
var finished := false              # Spiel zu Ende (Sieg/Niederlage) -> nichts mehr speichern
var _timer := 0.0


func _ready() -> void:
	add_to_group("save")
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if not enabled or get_tree().paused:
		return
	play_time += delta
	_timer += delta
	if _timer >= Config.autosave_interval:
		_timer = 0.0
		save()


## Browser-Tab wird verlassen / App in den Hintergrund -> schnell noch speichern.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST \
			or what == NOTIFICATION_APPLICATION_PAUSED:
		if enabled and not get_tree().paused:
			save()


func can_save() -> bool:
	return enabled and not finished and player.is_alive() and not siege.active \
			and fortress.is_fire_burning()


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(PATH)


## Spiel ist vorbei (Sieg/Niederlage): Stand löschen, nicht mehr speichern.
func game_finished() -> void:
	finished = true
	delete_save()


# --- Speichern -------------------------------------------------------------------

func save() -> void:
	if not can_save():
		return
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		push_error("Speichern fehlgeschlagen (%d)" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(_collect()))
	f.close()
	get_tree().call_group("hud", "saved_flash")


func _collect() -> Dictionary:
	var bar: Node = player.skill_bar
	var p := player.global_position
	if player.on_tower:
		p = player.on_tower.work_spot()
	var d := {
		"version": VERSION,
		"time": play_time,
		"player": {
			"pos": [p.x, p.z], "health": player.health, "potions": player.potions,
			"xp": player.xp, "level": player.level, "carry": player.carry,
			"fuel": player.lantern.fuel,
			"slots": Array(bar.slots), "stash": Array(bar.stash), "levels": bar.levels,
			"branches": bar.branches, "madness": player.madness.value, "bar_on": bar.active,
			"talismans": Array(player.talismans), "equipped": Array(player.equipped),
		},
		"fort": {
			"wood": fortress.wood, "food": fortress.food, "stone": fortress.stone,
			"bows": fortress.bows_total(), "armed": fortress.armed_target,
			"burn": fortress._burn_acc, "eat": fortress._eat_acc, "starve": fortress._starve_acc,
			"survivor": fortress._survivor_acc, "zone_jobs": fortress.zone_jobs,
			"residents": fortress.residents.map(func(r): return r.identity()),
			"graves": fortress.graves, "away": fortress.away, "ration": fortress.ration_t, "tools": fortress.tools,
			"buildings": {},
		},
		"shrines": get_tree().get_nodes_in_group("shrines").map(func(sh): return sh.opened),
		"depots": get_tree().get_nodes_in_group("depots").filter(func(dp): return dp.zone_id != "").map(
				func(dp): return [dp.zone_id, dp.stock]),
		"event_t": get_tree().get_first_node_in_group("events").time_left,
		"torches": {},
		"beacon": beacon.lit,
		"forest": get_tree().get_first_node_in_group("forest").save_data(),
		"food_spots": get_tree().get_nodes_in_group("resources").map(func(r): return [r.amount, r._regrow]),
		"rocks": get_tree().get_nodes_in_group("rocks").map(func(r): return [r.amount, r._regrow]),
		"fire_pits": get_tree().get_nodes_in_group("fire_pits").map(
				func(t): return [t.global_position.x, t.global_position.z, t.fuel, t.depot.stock]),
		"small_torches": get_tree().get_nodes_in_group("small_torches").map(
				func(t): return [t.global_position.x, t.global_position.z, t.fuel]),
		"siege": {"time": siege.time_to_bell, "count": siege.count, "final": siege.final_pending},
		"boss_defeated": get_parent().boss_defeated,
	}
	for b in fortress.buildings:
		d["fort"]["buildings"][b.name] = [b.level, b.wanted]
	for t in get_tree().get_nodes_in_group("torches"):
		d["torches"][t.zone_id] = [t.built, t.fuel]
	return d


# --- Laden -----------------------------------------------------------------------

## Gespeicherte Daten lesen (oder {} wenn keine/kaputt).
func read() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY or not int(d.get("version", 0)) in [1, VERSION]:
		return {}
	return d


## Kurzbeschreibung für das Startfenster.
func summary(d: Dictionary) -> String:
	var t := int(d.get("time", 0.0))
	var pl: Dictionary = d.get("player", {})
	var fo: Dictionary = d.get("fort", {})
	return "Spielzeit %d:%02d · Hüter-Stufe %d · %d Bewohner · %d Holz" % [t / 60, t % 60,
			int(pl.get("level", 1)), fo.get("residents", []).size(), int(fo.get("wood", 0))]


## Den gespeicherten Stand ins laufende Spiel übernehmen.
func apply(d: Dictionary) -> void:
	play_time = float(d.get("time", 0.0))
	_apply_world(d)
	_apply_fortress(d.get("fort", {}))
	_apply_player(d.get("player", {}))
	var s: Dictionary = d.get("siege", {})
	siege.count = int(s.get("count", 0))
	siege.final_pending = bool(s.get("final", false))
	siege.time_to_bell = maxf(float(s.get("time", Config.siege_interval)), Config.siege_warning + 15.0)
	var ev := get_tree().get_first_node_in_group("events")
	if ev and d.has("event_t"):
		ev.time_left = float(d["event_t"])
	if d.get("boss_defeated", false):
		get_parent().boss_defeated = true
		for b in get_tree().get_nodes_in_group("boss"):
			b.queue_free()


func _apply_world(d: Dictionary) -> void:
	if d.get("beacon", false) and not beacon.lit:
		beacon._light_up(true)
	var torches: Dictionary = d.get("torches", {})
	for t in get_tree().get_nodes_in_group("torches"):
		if torches.has(t.zone_id):
			t.built = bool(torches[t.zone_id][0])
			t.fuel = float(torches[t.zone_id][1])
			t._update_visuals()
	get_tree().get_first_node_in_group("forest").load_data(d.get("forest", {}))
	var rocks: Array = d.get("rocks", [])
	var rock_nodes := get_tree().get_nodes_in_group("rocks")
	if rocks.size() == rock_nodes.size():
		for i in rock_nodes.size():
			rock_nodes[i].amount = int(rocks[i][0])
			rock_nodes[i]._regrow = float(rocks[i][1])
			rock_nodes[i]._update()
	var world := get_tree().get_first_node_in_group("world")
	for e in d.get("fire_pits", []):
		var pit := Node3D.new()
		pit.set_script(FirePit)
		world.add_child(pit)
		pit.global_position = Vector3(float(e[0]), 0, float(e[1]))
		pit.built = true
		pit.fuel = float(e[2])
		pit._update_visuals()
		if e.size() > 3:
			for k in pit.depot.stock:
				pit.depot.stock[k] = int(e[3].get(k, 0))
			pit.depot.update_visuals()
	for e in d.get("small_torches", []):
		var t := Node3D.new()
		t.set_script(SmallTorch)
		world.add_child(t)
		t.global_position = Vector3(float(e[0]), 0, float(e[1]))
		t.built = true
		t.fuel = float(e[2])
		t._update_visuals()
	var shrines: Array = d.get("shrines", [])
	var shrine_nodes := get_tree().get_nodes_in_group("shrines")
	if shrines.size() == shrine_nodes.size():
		for i in shrine_nodes.size():
			shrine_nodes[i].set_opened(bool(shrines[i]))
	for e in d.get("depots", []):
		for dp in get_tree().get_nodes_in_group("depots"):
			if dp.zone_id != "" and dp.zone_id == str(e[0]):
				for k in dp.stock:
					dp.stock[k] = int(e[1].get(k, 0))
				dp.update_visuals()
	var spots: Array = d.get("food_spots", [])
	var nodes := get_tree().get_nodes_in_group("resources")
	if spots.size() == nodes.size():
		for i in nodes.size():
			nodes[i].amount = int(spots[i][0])
			nodes[i]._regrow = float(spots[i][1])
			nodes[i]._update()


func _apply_fortress(f: Dictionary) -> void:
	fortress.wood = float(f.get("wood", fortress.wood))
	fortress.food = float(f.get("food", fortress.food))
	fortress.stone = float(f.get("stone", 0.0))
	fortress.bows = int(f.get("bows", 0))
	fortress._burn_acc = float(f.get("burn", 0.0))
	fortress._eat_acc = float(f.get("eat", 0.0))
	fortress._starve_acc = float(f.get("starve", 0.0))
	fortress._survivor_acc = float(f.get("survivor", 0.0))
	var levels: Dictionary = f.get("buildings", {})
	for b in fortress.buildings:
		var e = levels.get(String(b.name), 0)
		var lvl := int(e[0]) if typeof(e) == TYPE_ARRAY else int(e)   # ältere Stände: nur die Stufe
		for i in lvl:
			b.improve()
		b.wanted = int(e[1]) if typeof(e) == TYPE_ARRAY else b.capacity()
	# Bewohner: v2 mit Name/Eigenschaften/Stimmung, v1 nur mit Leben
	var list: Array = f.get("residents", [])
	var with_identity := not list.is_empty() and typeof(list[0]) == TYPE_DICTIONARY
	if with_identity:
		for r in fortress.residents:
			r.queue_free()
		fortress.residents.clear()
		for e in list:
			var a := randf() * TAU
			fortress._add_resident(Vector3(cos(a), 0, sin(a)) * 3.5, e)
	else:
		while fortress.residents.size() > list.size():
			var r: Node3D = fortress.residents.pop_back()
			r.queue_free()
		while fortress.residents.size() < list.size():
			var a := randf() * TAU
			fortress._add_resident(Vector3(cos(a), 0, sin(a)) * 3.5)
		for i in list.size():
			fortress.residents[i].hp = float(list[i])
	fortress.graves = f.get("graves", [])
	fortress.update_graves()
	fortress.away = f.get("away", [])
	fortress.ration_t = float(f.get("ration", 0.0))
	var tl: Dictionary = f.get("tools", {})
	for k in fortress.tools:
		fortress.tools[k] = int(tl.get(k, 0))
	fortress.zone_jobs.clear()
	var jobs: Dictionary = f.get("zone_jobs", {})
	for k in jobs:
		fortress.zone_jobs[k] = int(jobs[k])
	fortress._assign_jobs()


func _apply_player(p: Dictionary) -> void:
	var pos: Array = p.get("pos", [0.0, 2.5])
	player.global_position = Vector3(float(pos[0]), 0, float(pos[1]))
	player.health = float(p.get("health", player.health))
	player.potions = int(p.get("potions", player.potions))
	player.xp = int(p.get("xp", 0))
	player.level = int(p.get("level", 1))
	player.lantern.fuel = float(p.get("fuel", player.lantern.fuel))
	var carry: Dictionary = p.get("carry", {})
	player.carry = {"wood": int(carry.get("wood", 0)), "food": int(carry.get("food", 0)),
			"stone": int(carry.get("stone", 0))}
	var bar: Node = player.skill_bar
	bar.slots.assign(p.get("slots", bar.slots))
	bar.stash.assign(p.get("stash", []))
	bar.levels.clear()
	var lv: Dictionary = p.get("levels", {})
	for k in lv:
		bar.levels[k] = int(lv[k])
	bar.branches = p.get("branches", {})
	bar.active = bool(p.get("bar_on", false))
	player.madness.value = float(p.get("madness", 0.0))
	# die „Umgekehrte Sanduhr“ ist jetzt das „Pendel“
	player.talismans.assign(Array(p.get("talismans", [])).map(func(x): return "pendulum" if x == "hourglass" else x))
	player.equipped.assign(Array(p.get("equipped", [])).map(func(x): return "pendulum" if x == "hourglass" else x))
	bar.index = 0
	bar.progress = 0.0
	bar.pending_mods.clear()
	bar.reset_cycle()
