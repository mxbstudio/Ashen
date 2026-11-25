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
var residents: Array[Node3D] = []
var buildings: Array[Node3D] = []
var zone_jobs := {}                # Zonen-Arbeit: "west:wood" -> Anzahl Bewohner (am Feuer eingeteilt)

var _burn_acc := 0.0
var _eat_acc := 0.0
var _starve_acc := 0.0
var _tick := 0.0
var _fire_dead := false


func _ready() -> void:
	add_to_group("fortress")
	wood = Config.fire_wood_start
	food = Config.food_start
	for c in get_children():
		if c.is_in_group("buildings") or c.has_method("build"):
			buildings.append(c)
	for i in Config.residents_start:
		var r := Node3D.new()
		r.set_script(ResidentScript)
		add_child(r)
		var a := TAU * i / Config.residents_start
		r.position = Vector3(cos(a), 0, sin(a)) * 3.5
		residents.append(r)
	_assign_jobs()


func wood_cap() -> int:
	return Config.wood_cap + (Config.storehouse_bonus if _has("storehouse") else 0)


func food_cap() -> int:
	return Config.food_cap + (Config.storehouse_bonus if _has("storehouse") else 0)


func _has(kind: String) -> bool:
	for b in buildings:
		if b.kind == kind and b.built:
			return true
	return false


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
	victim.queue_free()
	_assign_jobs()
	resident_died.emit(reason)
	message.emit(reason)


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


## Ladung der Trage abgeben. Was über die Lagergrenze geht, bleibt in der Trage.
func deposit(carry: Dictionary) -> Dictionary:
	var gave := {"wood": 0, "food": 0}
	var w := mini(carry["wood"], int(wood_cap() - wood))
	var f := mini(carry["food"], int(food_cap() - food))
	wood += w
	food += f
	carry["wood"] -= w
	carry["food"] -= f
	gave["wood"] = w
	gave["food"] = f
	return gave


func can_build(b: Node3D) -> bool:
	return not b.built and wood >= b.cost() + 1   # das letzte Holz bleibt fürs Feuer


func build(b: Node3D) -> void:
	if not can_build(b):
		return
	wood -= b.cost()
	b.build()
	_assign_jobs()
	message.emit("%s gebaut (−%d Holz)" % [b.display_name(), b.cost()])


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
	var taken := {}
	for kind in ["mushroom", "scrapyard", "tower"]:
		for b in buildings:
			if b.kind == kind and b.built and b.needs_worker():
				# wer schon hier arbeitet, bleibt – sonst zuerst einer ohne Arbeit, dann irgendeiner
				var w: Node3D = b.worker if home.has(b.worker) and not taken.has(b.worker) else null
				for pass_ in 2:
					for r in home:
						if w == null and not taken.has(r) and (pass_ == 1 or r.job == null):
							w = r
				if w:
					taken[w] = true
				b.set_worker(w)
	for r in residents:
		var j: Node3D = null
		for b in buildings:
			if b.worker == r:
				j = b
		r.assign(j)
