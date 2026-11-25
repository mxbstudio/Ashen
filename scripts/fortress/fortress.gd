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


func kill_resident(reason: String) -> void:
	if residents.is_empty():
		return
	# bevorzugt einen ohne Arbeit, sonst den letzten
	var victim: Node3D = residents[-1]
	for r in residents:
		if r.job == null:
			victim = r
			break
	residents.erase(victim)
	victim.queue_free()
	_assign_jobs()
	resident_died.emit(reason)
	message.emit(reason)


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


## Bewohner auf Gebäude verteilen: Pilzkeller, Trümmerhof, Wachturm (in dieser Reihenfolge).
func _assign_jobs() -> void:
	for b in buildings:
		b.set_worker(null)
	for r in residents:
		r.assign(null)
	var free := residents.duplicate()
	for kind in ["mushroom", "scrapyard", "tower"]:
		for b in buildings:
			if b.kind == kind and b.built and b.needs_worker() and not free.is_empty():
				var r: Node3D = free.pop_front()
				b.set_worker(r)
				r.assign(b)
