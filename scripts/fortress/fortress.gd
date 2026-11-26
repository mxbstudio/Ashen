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
		var best: Node3D = null
		for r in residents:
			if r.state == 0 and not r.has_zone_job() and r.hp >= Config.resident_hp * 0.6:
				if best == null or (best.job != null and r.job == null):
					best = r
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
	if n < 0 or (delta > 0 and zone_workers_total() >= residents.size()):
		return false
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
	_assign_jobs()
	if b.level == 1:
		message.emit("%s gebaut (−%d Holz)" % [b.display_name(), c])
	else:
		message.emit("%s auf Stufe %d (−%d Holz)" % [b.display_name(), b.level, c])


## Bewohner verteilen: zuerst die Zonen-Arbeit (wer schon die richtige hat, behält sie),
## dann Gebäude in dieser Reihenfolge: Pilzkeller, Trümmerhof, Wachturm. Der Rest bummelt am Feuer.
func _assign_jobs() -> void:
	var need := zone_jobs.duplicate()
	var free: Array[Node3D] = []
	for r in residents:
		var k: String = r.zone_key()
		if k != "" and need.get(k, 0) > 0:
			need[k] -= 1
		else:
			free.append(r)
	# für neue Zonen-Arbeit zuerst Bewohner ohne Gebäude nehmen
	free.sort_custom(func(a, b): return a.job == null and b.job != null)
	var keys := need.keys()
	keys.sort()
	for k in keys:
		while need[k] > 0 and not free.is_empty():
			var r: Node3D = free.pop_front()
			var parts: PackedStringArray = k.split(":")
			r.set_zone_job(parts[0], parts[1])
			need[k] -= 1
	for r in free:
		r.set_zone_job("", "")
	# Gebäude mit den Übrigen besetzen
	var home: Array[Node3D] = []
	for r in residents:
		if not r.has_zone_job():
			home.append(r)
	# Reihenfolge: Pilzkeller, Trümmerhof, Wachturm. Wer schon im Gebäude arbeitet, bleibt;
	# freie Plätze bekommen zuerst Bewohner ohne Arbeit, dann irgendein noch nicht verteilter.
	var taken := {}
	for kind in ["mushroom", "scrapyard", "workshop", "tower"]:
		for b in buildings:
			if b.kind != kind:
				continue
			var list: Array[Node3D] = []
			for w in b.workers:
				if home.has(w) and not taken.has(w) and list.size() < b.capacity():
					list.append(w)
					taken[w] = true
			for pass_ in 2:
				for r in home:
					if list.size() < b.capacity() and not taken.has(r) and (pass_ == 1 or r.job == null):
						list.append(r)
						taken[r] = true
			b.set_workers(list)
	for r in residents:
		var j: Node3D = null
		for b in buildings:
			if b.workers.has(r):
				j = b
		r.assign(j)
	_hand_out_bows()
