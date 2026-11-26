## Die Festung: Holz (im Feuer und für Gebäude), Nahrung, Bewohner, Gebäude.
## Läuft ständig weiter – auch während der Hüter draußen ist.
## advance(dt) wird jede Sekunde aufgerufen und beim Tod des Hüters mit 60 s ("Zeitsprung").
extends Node3D

signal fire_out
signal resident_died(reason: String)
signal message(text: String)

const ResidentScript := preload("res://scripts/fortress/resident.gd")

var wood := 0.0                    # Holz im Feuer/Lager
var food := 0.0
var stone := 0.0                   # Stein (für Feuerstellen)
var bows := 0                      # Bögen im Lager (nicht verteilt)
var armed_target := 0              # so viele Bewohner sollen einen Bogen tragen (Einteilen-Menü)
var _courier_t := 0.0
var _smart_t := 0.0
var residents: Array[Node3D] = []
var buildings: Array[Node3D] = []
var zone_jobs := {}                # Zonen-Arbeit: "west:wood" -> Anzahl Bewohner (am Feuer eingeteilt)

var _burn_acc := 0.0
var _eat_acc := 0.0
var _starve_acc := 0.0
var _survivor_acc := 0.0
var _tick := 0.0
var _fire_dead := false


func _ready() -> void:
	add_to_group("fortress")
	wood = Config.fire_wood_start
	food = Config.food_start
	stone = Config.stone_start
	for c in get_children():
		if c.is_in_group("buildings") or c.has_method("build"):
			buildings.append(c)
	for i in Config.residents_start:
		var a := TAU * i / Config.residents_start
		_add_resident(Vector3(cos(a), 0, sin(a)) * 3.5)
	_assign_jobs()


func _add_resident(pos: Vector3) -> Node3D:
	var r := Node3D.new()
	r.set_script(ResidentScript)
	add_child(r)
	r.position = pos
	residents.append(r)
	return r


func wood_cap() -> int:
	return Config.wood_cap + Config.storehouse_bonus * _level_of("storehouse")


func stone_cap() -> int:
	return Config.stone_cap + Config.storehouse_bonus * _level_of("storehouse")


func food_cap() -> int:
	return Config.food_cap + Config.storehouse_bonus * _level_of("storehouse")


## Stufe des (ersten) Gebäudes dieser Art (0 = nicht gebaut).
func _level_of(kind: String) -> int:
	for b in buildings:
		if b.kind == kind:
			return b.level
	return 0


func is_fire_burning() -> bool:
	return not _fire_dead


## Wie lange reicht das Holz noch (Sekunden)?
func wood_seconds_left() -> float:
	return wood * Config.fire_seconds_per_wood


func _process(delta: float) -> void:
	if _fire_dead:
		return
	_tick += delta
	if _tick >= 1.0:
		_tick -= 1.0
		advance(1.0)


## Spielzeit vergehen lassen (normal 1 s pro Aufruf; nach dem Tod 60 s auf einmal).
func advance(dt: float) -> void:
	if _fire_dead:
		return
	# Gebäude produzieren
	for b in buildings:
		var out: Dictionary = b.advance(dt)
		wood = minf(wood + out["wood"], wood_cap())
		food = minf(food + out["food"], food_cap())
		if out.get("bows", 0) > 0:
			bows += out["bows"]
			message.emit("Die Werkstatt hat einen Bogen gebaut")
			_hand_out_bows()
	# Feuerstellen: Bewohner bringen Holz, wenn eine bald leer ist
	_courier_t += dt
	if _courier_t >= 1.0:
		_courier_t = 0.0
		_send_couriers()
	# schlaue Bewohner: ruhende Gebäude, freie Bewohner helfen, wo das Lager etwas braucht
	_smart_t += dt
	if _smart_t >= Config.smart_interval:
		_smart_t = 0.0
		var changed := false
		for b in buildings:
			if b.built and b.update_need(self):
				changed = true
		if changed:
			_assign_jobs()
		_auto_jobs()
	# Feuer verbrennt Holz
	_burn_acc += dt
	while _burn_acc >= Config.fire_seconds_per_wood:
		_burn_acc -= Config.fire_seconds_per_wood
		wood -= 1.0
	if wood <= 0.0:
		wood = 0.0
		_fire_dead = true
		fire_out.emit()
		return
	# Bewohner essen
	if residents.size() > 0:
		_eat_acc += dt * residents.size()
		while _eat_acc >= Config.food_seconds_per_person:
			_eat_acc -= Config.food_seconds_per_person
			food -= 1.0
		if food <= 0.0:
			food = 0.0
			_starve_acc += dt
			while _starve_acc >= Config.starve_seconds and residents.size() > 0:
				_starve_acc -= Config.starve_seconds
				kill_resident("Ein Bewohner ist verhungert.")
		else:
			_starve_acc = 0.0
	# Überlebende finden das Licht
	_survivor_acc += dt
	while _survivor_acc >= Config.survivor_interval:
		_survivor_acc -= Config.survivor_interval
		if residents.size() < Config.residents_max and food >= Config.survivor_min_food:
			_add_resident(Vector3(0, 0, -9.5))   # kommt durchs Tor herein
			_assign_jobs()
			Sfx.play("pickup", 0.0, 0.0)
			message.emit("Ein Überlebender hat das Licht gefunden (+1 Bewohner)")


## Ein Bewohner stirbt. victim = null -> bevorzugt einer ohne Arbeit, sonst der letzte.
func kill_resident(reason: String, victim: Node3D = null) -> void:
	if residents.is_empty():
		return
	if victim == null or not residents.has(victim):
		victim = residents[-1]
		for r in residents:
			if r.job == null and not r.has_zone_job():
				victim = r
				break
	# seine Zonen-Arbeit fällt weg (sonst würde einer aus einem Gebäude nachrücken)
	var key: String = victim.zone_key()
	if key != "" and zone_jobs.get(key, 0) > 0:
		zone_jobs[key] -= 1
	for b in buildings:
		if b.workers.has(victim):
			b.wanted = maxi(b.wanted - 1, 0)
	residents.erase(victim)
	victim.queue_free()   # sein Bogen geht mit verloren
	if armed_target > bows_total():
		armed_target = bows_total()
	_assign_jobs()
	resident_died.emit(reason)
	message.emit(reason)


## Alle Bögen: im Lager + von Bewohnern getragen.
func bows_total() -> int:
	return bows + armed_count()


func armed_count() -> int:
	var n := 0
	for r in residents:
		if r.has_bow:
			n += 1
	return n


## Wie viele Bewohner sollen einen Bogen tragen (aus dem Einteilen-Menü)?
func change_armed(delta: int) -> void:
	armed_target = clampi(armed_target + delta, 0, mini(bows_total(), residents.size()))
	_hand_out_bows()


## Bögen verteilen: wer draußen arbeitet, bekommt zuerst einen.
func _hand_out_bows() -> void:
	var total := bows_total()
	var want := mini(mini(armed_target, total), residents.size())
	var order := residents.duplicate()
	order.sort_custom(func(a, b): return a.has_zone_job() and not b.has_zone_job())
	for i in order.size():
		order[i].has_bow = i < want
	bows = total - want


## Feuerstellen, die bald ausgehen: ein Bewohner aus der Festung bringt Holz.
func _send_couriers() -> void:
	if Zones.recalled(get_tree()):
		return
	for pit in get_tree().get_nodes_in_group("fire_pits"):
		if not pit.needs_wood() or (pit.courier and is_instance_valid(pit.courier)):
			continue
		var n := mini(Config.firepit_courier_wood, pit.wood_space())
		if n <= 0 or wood < n + 1:
			continue
		# nur freie Bewohner (ohne Gebäude und ohne Zone) springen ein
		var best: Node3D = null
		for r in residents:
			if r.state == 0 and r.is_free() and r.hp >= Config.resident_hp * 0.6:
				best = r
				break
		if best == null:
			return
		wood -= n
		best.start_delivery(pit, n)


## Wie viele Bewohner sind insgesamt für Zonen eingeteilt?
func zone_workers_total() -> int:
	var n := 0
	for k in zone_jobs:
		n += zone_jobs[k]
	return n


## Zonen-Arbeit ändern (aus dem Einteilen-Menü). Gibt zurück, ob es geklappt hat.
func change_zone_job(zone_id: String, kind: String, delta: int) -> bool:
	var key := "%s:%s" % [zone_id, kind]
	var n: int = zone_jobs.get(key, 0) + delta
	if n < 0 or (delta > 0 and free_count() <= 0):
		return false   # einteilen nur, wenn ein Bewohner frei ist
	zone_jobs[key] = n
	_assign_jobs()
	return true


## Wie viele Bewohner sind gerade draußen vor der Mauer?
func residents_outside() -> int:
	var n := 0
	for r in residents:
		if r.is_exposed():
			n += 1
	return n


## Ladung (Trage des Hüters oder eines Bewohners) abgeben. Was über die Lagergrenze geht, bleibt in der Trage.
func deposit(carry: Dictionary) -> Dictionary:
	var gave := {"wood": 0, "food": 0, "stone": 0}
	var w := mini(carry.get("wood", 0), int(wood_cap() - wood))
	var f := mini(carry.get("food", 0), int(food_cap() - food))
	var st := mini(carry.get("stone", 0), int(stone_cap() - stone))
	wood += w
	food += f
	stone += st
	for k in ["wood", "food", "stone"]:
		if carry.has(k):
			carry[k] -= {"wood": w, "food": f, "stone": st}[k]
	gave["wood"] = w
	gave["food"] = f
	gave["stone"] = st
	return gave


## Wie viel Holz/Stein steht zur Verfügung: Trage + Lager (beim Holz bleibt das letzte fürs Feuer)?
func available(kind: String, carry: Dictionary) -> int:
	var store: int = int(wood) - 1 if kind == "wood" else int(stone)
	return carry.get(kind, 0) + maxi(store, 0)


## Bezahlen: zuerst aus der Trage, der Rest aus dem Lager.
func pay(kind: String, n: int, carry: Dictionary) -> void:
	var from_carry := mini(carry.get(kind, 0), n)
	carry[kind] -= from_carry
	if kind == "wood":
		wood -= n - from_carry
	else:
		stone -= n - from_carry


## Bauen oder verbessern möglich? Das letzte Holz bleibt immer fürs Feuer.
func can_build(b: Node3D) -> bool:
	return b.can_improve() and wood >= b.next_cost() + 1


## Bauen bzw. eine Stufe verbessern.
func build(b: Node3D) -> void:
	if not can_build(b):
		return
	var c: int = b.next_cost()
	wood -= c
	b.improve()
	b.wanted = b.capacity()   # neue Plätze: freie Bewohner rücken automatisch nach
	_assign_jobs()
	if b.level == 1:
		message.emit("%s gebaut (−%d Holz)" % [b.display_name(), c])
	else:
		message.emit("%s auf Stufe %d (−%d Holz)" % [b.display_name(), b.level, c])


## Bewohner verteilen. Grundsatz: Max teilt über das Menü ein – niemand wird automatisch
## aus einem Gebäude oder einer Zone abgezogen. Es passiert nur zweierlei:
##  1. Wer über die gewünschte Zahl hinaus eingeteilt ist (Max hat "−" gedrückt), wird frei.
##  2. Freie Bewohner füllen offene Plätze (gewünschte Zahl > besetzt): zuerst Gebäude
##     (Pilzkeller, Trümmerhof, Werkstatt, Wachturm), dann Zonen.
func _assign_jobs() -> void:
	# 1a. Zonen: überzählige werden frei
	var seen := {}
	for r in residents:
		var k: String = r.zone_key()
		if k == "":
			continue
		seen[k] = seen.get(k, 0) + 1
		if seen[k] > zone_jobs.get(k, 0):
			r.set_zone_job("", "")
	# 1b. Gebäude: Tote und Überzählige raus; ruhende Gebäude lassen ihre Arbeiter frei
	for b in buildings:
		var list: Array[Node3D] = []
		for w in b.workers:
			if residents.has(w) and not b.resting and not w.has_zone_job() and list.size() < b.wanted_workers():
				list.append(w)
		b.set_workers(list)
	# 2. freie Bewohner auf offene Plätze (wer gerade in der Festung ist, zuerst)
	var free: Array[Node3D] = []
	for r in residents:
		if r.is_free() and not _in_building(r):
			free.append(r)
	free.sort_custom(func(a, b): return (a.state == 0 and not a.auto_job) and not (b.state == 0 and not b.auto_job))
	for kind in ["mushroom", "scrapyard", "workshop", "tower"]:
		for b in buildings:
			if b.kind != kind:
				continue
			if b.resting:
				continue
			var list: Array[Node3D] = b.workers.duplicate()
			while list.size() < b.wanted_workers() and not free.is_empty():
				var w: Node3D = free.pop_front()
				w.set_zone_job("", "")   # selbstständiger Helfer kommt zurück
				list.append(w)
			b.set_workers(list)
	var keys := zone_jobs.keys()
	keys.sort()
	for k in keys:
		var have := 0
		for r in residents:
			if r.zone_key() == k:
				have += 1
		while have < zone_jobs[k] and not free.is_empty():
			var r: Node3D = free.pop_front()
			var parts: PackedStringArray = k.split(":")
			r.set_zone_job(parts[0], parts[1])
			have += 1
	for r in residents:
		var j: Node3D = null
		for b in buildings:
			if b.workers.has(r):
				j = b
		r.assign(j)
	_hand_out_bows()


func _in_building(r: Node3D) -> bool:
	for b in buildings:
		if b.workers.has(r):
			return true
	return false


## Bewohner ohne jede Arbeit.
func free_count() -> int:
	var n := 0
	for r in residents:
		if r.is_free():
			n += 1
	return n


## Freie Bewohner, die gerade selbstständig helfen – {Art: Anzahl}.
func helpers() -> Dictionary:
	var out := {}
	for r in residents:
		if r.auto_job:
			out[r.zone_kind] = out.get(r.zone_kind, 0) + 1
	return out


## Wie dringend braucht das Lager gerade Holz, Nahrung, Stein? (0 = gar nicht, >1 = dringend)
func needs() -> Dictionary:
	var w := 2.0 if wood_seconds_left() < 180.0 else 1.0 - wood / wood_cap()
	var f := 2.0 if food < residents.size() * 2 else 1.0 - food / food_cap()
	var st := 0.6 * (1.0 - stone / stone_cap())
	return {"wood": w, "food": f, "stone": st}


## Eine helle Zone, in der es gerade etwas von dieser Art zu holen gibt ("" = keine).
func _zone_with(kind: String) -> String:
	var forest := get_tree().get_first_node_in_group("forest")
	for z in ZoneDefs.ZONES:
		var id: String = z["id"]
		if not Zones.is_lit(get_tree(), id):
			continue
		match kind:
			"wood":
				if forest and forest.nearest(Zones.center(get_tree(), id), Config.torch_light_radius - 1.5) >= 0:
					return id
			"food":
				for r in get_tree().get_nodes_in_group("resources"):
					if r.zone_id == id and r.is_available():
						return id
			"stone":
				for r in get_tree().get_nodes_in_group("rocks"):
					if r.zone_id == id and r.is_available():
						return id
	return ""


## Freie Bewohner verteilen sich selbst auf das, was das Lager am dringendsten braucht.
## Wer schon unterwegs ist, wird nicht unterbrochen, solange seine Arbeit noch gebraucht wird.
func _auto_jobs() -> void:
	if Zones.recalled(get_tree()):
		return
	var need := needs()
	var zone_for := {}
	for k in need:
		zone_for[k] = _zone_with(k)
	var free := residents.filter(func(r): return r.is_free() and r.state != 4 and r.hp >= Config.resident_hp * 0.6)
	# wer schon hilft, zuerst (damit er bleiben kann)
	free.sort_custom(func(a, b): return a.auto_job and not b.auto_job)
	for r in free:
		var keep: bool = r.auto_job and need.get(r.zone_kind, 0.0) > Config.smart_min_need \
				and zone_for.get(r.zone_kind, "") != ""
		if keep:
			need[r.zone_kind] -= Config.smart_need_per_helper
			continue
		var best := ""
		var best_v := Config.smart_min_need
		for k in need:
			if need[k] > best_v and zone_for[k] != "":
				best_v = need[k]
				best = k
		if best == "":
			if r.auto_job:
				r.set_zone_job("", "")   # nichts zu tun: zurück ans Feuer
			continue
		r.set_zone_job(zone_for[best], best, true)
		need[best] -= Config.smart_need_per_helper


## Gebäude-Arbeiter ändern (aus dem Einteilen-Menü). "+" geht nur mit einem freien Bewohner.
func change_building_workers(b: Node3D, delta: int) -> bool:
	var n: int = (b.wanted_workers() if b.resting else b.workers.size()) + delta   # vom tatsächlich besetzten Stand aus
	if n < 0 or n > b.capacity() or (delta > 0 and free_count() <= 0):
		return false
	b.wanted = n
	_assign_jobs()
	return true
