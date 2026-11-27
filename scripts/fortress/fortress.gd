## Die Festung: Holz (im Feuer und für Gebäude), Nahrung, Bewohner, Gebäude.
## Läuft ständig weiter – auch während der Hüter draußen ist.
## advance(dt) wird jede Sekunde aufgerufen und beim Tod des Hüters mit 60 s ("Zeitsprung").
## v0.3: Bewohner haben Namen, Eigenschaften und Stimmung. Die Stimmung strebt einem Zielwert zu
## (satt? Feuer sicher? Prediger? Wahn des Hüters?), Schocks (Tod, Tor gefallen, Belagerung gehalten)
## verschieben sie sofort. Tote bekommen ein Grab an der Westmauer.
extends Node3D

signal fire_out
signal resident_died(reason: String)
signal message(text: String)

const ResidentScript := preload("res://scripts/fortress/resident.gd")
const HutScript := preload("res://scripts/fortress/hut.gd")

## Bauplätze für eigene Häuser (an der Süd- und Ostmauer, innen)
const HUT_SPOTS := [Vector3(-10.4, 0, 10.6), Vector3(-8.4, 0, 10.6), Vector3(-6.4, 0, 10.6), Vector3(-4.4, 0, 10.6),
		Vector3(-2.7, 0, 10.6), Vector3(2.7, 0, 10.6), Vector3(4.4, 0, 10.6), Vector3(6.4, 0, 10.6),
		Vector3(8.4, 0, 10.6), Vector3(10.4, 0, 8.6), Vector3(10.6, 0, 3.0), Vector3(10.6, 0, 1.0),
		Vector3(10.6, 0, -3.2), Vector3(10.6, 0, -5.2), Vector3(-2.6, 0, -6.4)]
const TRAINING_POS := Vector3(-4.0, 0, -9.0)   # Übungsplatz innen neben dem Tor

var wood := 0.0                    # Holz im Feuer/Lager
var food := 0.0
var stone := 0.0                   # Stein (für Feuerstellen)
var bows := 0                      # Bögen im Lager (nicht verteilt)
var armed_target := 0              # (alt, v0.2: im Menü eingestellt) – Bögen werden jetzt automatisch verteilt
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
var graves: Array = []             # [Name, Todesursache] – Gräber an der Westmauer
var away: Array = []               # Bewohner, die gerade unterwegs sind (Ereignis): [Identität, Restzeit, Begleitung?]
var ration_t := 0.0                # s mit gekürzten Rationen (Ereignis)
var tools := {"wood": 0, "stone": 0, "food": 0}   # Werkzeug-Stufen: Axt, Spitzhacke, Sammelkorb
var day := 1                       # Tag (v0.4)
var day_time := 0.0                # s seit Tagesbeginn
var huts: Array = []               # Bauplätze/Häuser der Bewohner
var _last_phase := "work"
var _desert_acc := 0.0
var _grave_nodes: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("fortress")
	wood = Config.fire_wood_start
	food = Config.food_start
	stone = Config.stone_start
	for c in get_children():
		if c.is_in_group("buildings") or c.has_method("build"):
			buildings.append(c)
	_rng.randomize()
	for p in HUT_SPOTS:
		var h := Node3D.new()
		h.set_script(HutScript)
		add_child(h)
		h.position = p
		huts.append(h)
	_make_training_post()
	for i in Config.residents_start:
		var a := TAU * i / Config.residents_start
		_add_resident(Vector3(cos(a), 0, sin(a)) * 3.5)
	# zwei Paare/Geschwister am Start
	for k in mini(2, residents.size() / 2):
		bond(residents[k * 2], residents[k * 2 + 1], "Geschwister" if k == 0 else "Paar")
	_assign_jobs()


## Neuer Bewohner. identity = gespeicherte/vorgegebene Daten, sonst wird gewürfelt.
func _add_resident(pos: Vector3, identity := {}) -> Node3D:
	var r := Node3D.new()
	r.set_script(ResidentScript)
	add_child(r)
	r.position = pos
	if identity.is_empty():
		identity = new_identity()
	r.setup_identity(identity)
	residents.append(r)
	return r


## Zufälliger Name und Eigenschaften.
func new_identity(extra_traits := []) -> Dictionary:
	var taken := residents.map(func(r): return r.res_name)
	for a in away:
		taken.append(a[0].get("name", ""))
	var t: Array = ResidentData.roll_traits(_rng)
	for e in extra_traits:
		if not t.has(e):
			t.append(e)
	return {"name": ResidentData.pick_name(_rng, taken), "traits": t, "mood": Config.mood_start}


func bond(a: Node3D, b: Node3D, kind: String) -> void:
	a.bond_name = b.res_name
	b.bond_name = a.res_name
	a.bond_kind = kind
	b.bond_kind = kind


func find_resident(n: String) -> Node3D:
	for r in residents:
		if r.res_name == n:
			return r
	return null


func trait_count(t: String) -> int:
	var n := 0
	for r in residents:
		if r.has_trait(t):
			n += 1
	return n


## Stimmung aller ändern (Schock), z. B. +10 nach einer gehaltenen Belagerung.
func mood_shock(amount: float) -> void:
	for r in residents:
		r.mood = clampf(r.mood + amount, 0.0, 100.0)


func average_mood() -> float:
	if residents.is_empty():
		return 0.0
	var sum := 0.0
	for r in residents:
		sum += r.mood
	return sum / residents.size()


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


## Wie lange reicht das Holz noch (Sekunden, genau – das angebrannte Scheit zählt mit)?
func wood_seconds_left() -> float:
	return maxf(wood * Config.fire_seconds_per_wood - _burn_acc, 0.0) / fire_burn_factor()


## Feuerhüter sparen Holz.
func fire_burn_factor() -> float:
	return 0.9 if trait_count("feuerhueter") > 0 else 1.0


## Wie viel darf von Holz/Nahrung verbraucht werden? Unter Config.vital_reserve bleibt alles für Feuer und Essen.
## Stein ist nicht überlebenswichtig.
func spendable(kind: String) -> int:
	match kind:
		"wood": return maxi(int(wood) - Config.vital_reserve, 0)
		"food": return maxi(int(food) - Config.vital_reserve, 0)
		"stone": return int(stone)
	return 0


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
	# Gebäude produzieren – nur in der Arbeitszeit
	for b in buildings:
		if phase() != "work" and b.kind != "tower":
			continue
		# Gebäude arbeiten nur in der Arbeitszeit, dafür entsprechend schneller – pro Tag liefern sie so viel wie früher
		var out: Dictionary = b.advance(dt / Config.work_share if b.kind != "tower" else dt)
		wood = minf(wood + out["wood"], wood_cap())
		food = minf(food + out["food"], food_cap())
		if out.get("bows", 0) > 0:
			bows += out["bows"]
			_bowyer_call(b)
			var got := _hand_out_bows()
			for r in got:
				if Sfx.audible(r.global_position):
					message.emit("%s holt sich den neuen Bogen." % r.res_name)
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
	_clock_step(dt)
	_needs_step(dt)
	_mood_step(dt)
	# Feuer verbrennt Holz (Feuerhüter sparen etwas)
	_burn_acc += dt * fire_burn_factor()
	while _burn_acc >= Config.fire_seconds_per_wood:
		_burn_acc -= Config.fire_seconds_per_wood
		wood -= 1.0
	if wood <= 0.0:
		wood = 0.0
		_fire_dead = true
		fire_out.emit()
		return
	# Essen: jeder Bewohner isst selbst (am Feuer oder zu Hause), siehe resident.gd – Hunger in _needs_step
	if ration_t > 0.0:
		ration_t -= dt
	# Überlebende finden das Licht
	_survivor_acc += dt
	while _survivor_acc >= Config.survivor_interval:
		_survivor_acc -= Config.survivor_interval
		if residents.size() < Config.residents_max and food >= Config.survivor_min_food:
			var nr := _add_resident(Vector3(0, 0, -9.5))   # kommt durchs Tor herein
			_assign_jobs()
			Sfx.play_at("pickup", Vector3(0, 0, -9.5), 0.0, 0.0)
			message.emit("%s hat das Licht gefunden (+1 Bewohner)" % nr.title())
	# Unterwegs (Ereignis): zurückkehren
	_away_step(dt)


## Ein Bewohner stirbt. victim = null -> bevorzugt einer ohne Arbeit, sonst der letzte.
## reason darf "%s" für den Namen enthalten. Er bekommt ein Grab, alle trauern, der Verbundene am meisten.
func kill_resident(reason: String, victim: Node3D = null) -> void:
	if residents.is_empty():
		return
	if victim == null or not residents.has(victim):
		victim = residents[-1]
		for r in residents:
			if r.job == null and not r.has_zone_job() and not r.is_child():
				victim = r
				break
	if "%s" in reason:
		reason = reason % victim.res_name
	else:
		reason = "%s – %s" % [reason, victim.res_name]
	graves.append([victim.res_name, reason])
	_update_graves()
	remove_resident(victim, reason, true)


## Bewohner verlässt die Festung (tot, verbannt, fortgegangen). death = trauern die anderen?
func remove_resident(victim: Node3D, reason: String, death := false, keep_bond := false) -> void:
	if not residents.has(victim):
		return
	if death:
		for r in residents:
			if r == victim:
				continue
			r.mood = maxf(r.mood - Config.mood_on_death, 0.0)
			if r.bond_name == victim.res_name:
				r.grief = Config.grief_time
				r.mood = maxf(r.mood - 30.0, 0.0)
				message.emit("%s trauert um %s." % [r.res_name, victim.res_name])
	if victim.house:
		victim.house.move_out(victim)
	for h in huts:
		if h.claimed_by == victim:
			h.claimed_by = null
	if not keep_bond:
		for r in residents:
			if r.bond_name == victim.res_name:
				r.bond_name = ""
	# seine Zonen-Arbeit fällt weg (sonst würde einer aus einem Gebäude nachrücken)
	var key: String = victim.zone_key()
	if key != "" and zone_jobs.get(key, 0) > 0:
		zone_jobs[key] -= 1
	for b in buildings:
		if b.workers.has(victim):
			b.wanted = maxi(b.wanted - 1, 0)
	residents.erase(victim)
	victim.queue_free()   # sein Bogen geht mit verloren
	_assign_jobs()
	if death:
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


## Der Bogner ruft, wenn ein Bogen fertig ist.
func _bowyer_call(workshop: Node3D) -> void:
	var calls := ["Ein Bogen ist fertig!", "Bogen fertig – wer will?", "Noch einer für die Mauer!", "Fertig! Holt ihn euch!"]
	var text: String = calls[_rng.randi() % calls.size()]
	var bowyer: Node3D = null
	for w in workshop.workers:
		if is_instance_valid(w):
			bowyer = w
			break
	var where: Vector3 = bowyer.global_position if bowyer else workshop.global_position
	if bowyer:
		bowyer.shout(text)
	Sfx.play_at("call", where, 0.0, 0.05)
	# Meldung nur, wenn der Hüter den Ruf hören kann (draußen hört man ihn nicht)
	if Sfx.audible(where):
		message.emit("%s (Bogner): „%s“" % [bowyer.res_name, text] if bowyer else "Werkstatt: „%s“" % text)


## Bögen verteilen: Bögen im Lager gehen automatisch an Bewohner ohne Bogen –
## wer draußen arbeitet, zuerst. Wer schon einen hat, behält ihn. Gibt die neuen Träger zurück.
func _hand_out_bows() -> Array:
	var got := []
	var order := residents.filter(func(r): return not r.has_bow)
	order.sort_custom(func(a, b): return a.has_zone_job() and not b.has_zone_job())
	for r in order:
		if bows <= 0:
			break
		r.has_bow = true
		bows -= 1
		got.append(r)
	return got


## Feuerstellen, die bald ausgehen: ein Bewohner aus der Festung bringt Holz.
func _send_couriers() -> void:
	if Zones.recalled(get_tree()):
		return
	for pit in get_tree().get_nodes_in_group("fire_pits"):
		if not pit.needs_wood() or (pit.courier and is_instance_valid(pit.courier)):
			continue
		var n := mini(Config.firepit_courier_wood, pit.wood_space())
		if n <= 0 or spendable("wood") < n:
			continue
		# nur freie Bewohner (ohne Gebäude und ohne Zone) springen ein
		var best: Node3D = null
		for r in residents:
			if r.state == 0 and r.is_free() and r.hp >= r.max_hp() * 0.6:
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


## Bauen oder verbessern möglich? Die Reserve (5 Holz) bleibt immer fürs Feuer.
func can_build(b: Node3D) -> bool:
	return b.can_improve() and spendable("wood") >= b.next_cost()


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
	for kind in ["mushroom", "scrapyard", "workshop", "carts", "tower"]:
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


## Gibt es in dieser Zone gerade etwas von dieser Art zu holen (und ist sie hell)?
func zone_has(id: String, kind: String) -> bool:
	if id == "" or not Zones.is_lit(get_tree(), id):
		return false
	match kind:
		"wood":
			var forest := get_tree().get_first_node_in_group("forest")
			return forest != null and forest.nearest(Zones.center(get_tree(), id), Config.torch_light_radius - 1.5) >= 0
		"food":
			for r in get_tree().get_nodes_in_group("resources"):
				if r.zone_id == id and r.is_available():
					return true
		"stone":
			for r in get_tree().get_nodes_in_group("rocks"):
				if r.zone_id == id and r.is_available():
					return true
	return false


## Eine helle Zone, in der es gerade etwas von dieser Art zu holen gibt ("" = keine).
func _zone_with(kind: String) -> String:
	for z in ZoneDefs.ZONES:
		if zone_has(z["id"], kind):
			return z["id"]
	return ""


## Ausweich-Arbeit für einen Bewohner, dessen Zone leer ist: das Dringendste, was das Lager braucht –
## zuerst in seiner eigenen Zone, sonst in der nächsten hellen Zone. [] = nichts Sinnvolles zu tun.
func fallback_for(r: Node3D) -> Array:
	var need := needs()
	var kinds := ["wood", "food", "stone"]
	kinds.sort_custom(func(a, b): return need[a] > need[b])
	var zones: Array = []
	for z in ZoneDefs.ZONES:
		zones.append(z["id"])
	zones.sort_custom(func(a, b): return Zones.center(get_tree(), a).distance_to(r.global_position) \
			< Zones.center(get_tree(), b).distance_to(r.global_position))
	for k in kinds:
		if need[k] <= Config.smart_min_need:
			continue
		for z in zones:
			if zone_has(z, k):
				return [z, k]
	return []


## Freie Bewohner verteilen sich selbst auf das, was das Lager am dringendsten braucht.
## Wer schon unterwegs ist, wird nicht unterbrochen, solange seine Arbeit noch gebraucht wird.
func _auto_jobs() -> void:
	if Zones.recalled(get_tree()):
		return
	var need := needs()
	var zone_for := {}
	for k in need:
		zone_for[k] = _zone_with(k)
	var free := residents.filter(func(r): return r.is_free() and r.state != 4 and r.hp >= r.max_hp() * 0.6)
	# wer schon hilft, zuerst (damit er bleiben kann)
	free.sort_custom(func(a, b): return a.auto_job and not b.auto_job)
	for r in free:
		var keep: bool = r.auto_job and need.get(r.zone_kind, 0.0) > Config.smart_min_need \
				and zone_has(r.zone_id, r.zone_kind)   # nur bleiben, wenn es in SEINER Zone noch etwas gibt
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



# --- Stimmung (v0.3) -------------------------------------------------------------

## Zielwert der Stimmung: satt, Feuer sicher, Prediger, Wahn des Hüters …
func mood_target() -> float:
	var t := 55.0
	if food <= 0.0:
		t -= 35.0
	elif food >= residents.size() * 2:
		t += 10.0
	if wood_seconds_left() < 180.0:
		t -= 15.0
	else:
		t += 5.0
	if ration_t > 0.0:
		t -= 10.0
	t += 8.0 * trait_count("prediger")
	var player := get_tree().get_first_node_in_group("player")
	if player:
		t -= [0.0, 0.0, 12.0, 25.0][player.madness.stage()]   # die Bewohner fürchten den Wahn des Hüters
	return clampf(t, 5.0, 95.0)


func _mood_step(dt: float) -> void:
	var target := mood_target()
	for r in residents:
		var own := target - (30.0 if r.grief > 0.0 else 0.0) + personal_mood(r)
		r.mood = move_toward(r.mood, own, Config.mood_rate * dt)
		r.grief = maxf(r.grief - dt, 0.0)
	# Verzweifelte verlassen vielleicht die Festung (einmal pro Minute würfeln)
	_desert_acc += dt
	while _desert_acc >= 60.0:
		_desert_acc -= 60.0
		for r in residents.duplicate():
			if r.mood < Config.desert_mood and r.state == 0 and _rng.randf() < Config.desert_chance:
				remove_resident(r, "%s hat die Festung verlassen – die Verzweiflung war zu groß." % r.res_name)
				mood_shock(-5.0)
				break


# --- Unterwegs (Ereignis „Suche nach Verwandten“) -----------------------------------

## Bewohner zieht los. Er kommt nach dt Sekunden zurück – vielleicht mit Begleitung, vielleicht nie.
func send_away(r: Node3D, seconds: float) -> void:
	var id: Dictionary = r.identity()
	away.append([id, seconds])
	remove_resident(r, "%s ist in die Dunkelheit aufgebrochen." % r.res_name, false, true)


func _away_step(dt: float) -> void:
	for a in away.duplicate():
		a[1] -= dt
		if a[1] > 0.0:
			continue
		away.erase(a)
		var id: Dictionary = a[0]
		var roll := _rng.randf()
		if roll < 0.2:
			graves.append([id["name"], "%s kehrte nie zurück." % id["name"]])
			_update_graves()
			message.emit("%s ist nicht zurückgekehrt …" % id["name"])
			mood_shock(-8.0)
			continue
		var r := _add_resident(Vector3(0, 0, -9.5), id)
		r.mood = minf(r.mood + 10.0, 100.0)
		if roll < 0.65:
			var kin := _add_resident(Vector3(0.8, 0, -9.5))
			bond(r, kin, "Geschwister")
			message.emit("%s ist zurück – und bringt %s mit!" % [r.res_name, kin.res_name])
			mood_shock(6.0)
		else:
			message.emit("%s ist allein zurückgekehrt." % r.res_name)
		_assign_jobs()


# --- Gräber -----------------------------------------------------------------------

## Grabsteine an der Westmauer (innen), mit Namen.
func _update_graves() -> void:
	while _grave_nodes.size() < graves.size() and _grave_nodes.size() < 18:
		var i := _grave_nodes.size()
		var g := Node3D.new()
		add_child(g)
		g.position = Vector3(-10.6 + (i % 2) * 0.9, 0, -9.0 + (i / 2) * 1.3)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.7, 0.18)
		m.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.38, 0.4)
		m.material_override = mat
		m.position.y = 0.35
		m.rotation.y = PI / 2.0
		g.add_child(m)
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.fixed_size = true
		l.pixel_size = 0.0007
		l.font_size = 24
		l.outline_size = 6
		l.modulate = Color(0.8, 0.8, 0.85, 0.75)
		l.position.y = 1.0
		g.add_child(l)
		_grave_nodes.append(g)
	for i in _grave_nodes.size():
		var idx := graves.size() - _grave_nodes.size() + i   # die jüngsten Gräber zeigen
		(_grave_nodes[i].get_child(1) as Label3D).text = "† " + str(graves[idx][0])


func update_graves() -> void:
	_update_graves()



# --- Werkzeuge -------------------------------------------------------------------

const TOOL_NAMES := {"wood": "Axt", "stone": "Spitzhacke", "food": "Sammelkorb"}
const TOOL_VERBS := {"wood": "Holz hacken", "stone": "Stein klopfen", "food": "Nahrung sammeln"}


## Faktor auf die Abbau-Zeit (1 = ohne Werkzeug, kleiner = schneller).
func tool_factor(kind: String) -> float:
	return 1.0 / (1.0 + Config.tool_speed_per_level * tools.get(kind, 0))


func _workshop_level() -> int:
	return _level_of("workshop")


## Kann das Werkzeug verbessert werden? "" = ja, sonst der Grund.
func tool_blocker(kind: String) -> String:
	var lvl: int = tools.get(kind, 0)
	if lvl >= 3:
		return "höchste Stufe"
	if _workshop_level() <= lvl:
		return "braucht Werkstatt Stufe %d" % (lvl + 1)
	if spendable("wood") < Config.tool_cost_wood[lvl] or stone < Config.tool_cost_stone[lvl]:
		return "zu wenig Holz/Stein – %d Holz bleiben fürs Feuer" % Config.vital_reserve
	return ""


func upgrade_tool(kind: String) -> bool:
	if tool_blocker(kind) != "":
		return false
	var lvl: int = tools[kind]
	wood -= Config.tool_cost_wood[lvl]
	stone -= Config.tool_cost_stone[lvl]
	tools[kind] = lvl + 1
	Sfx.play("gate", 0.0, 0.0)
	message.emit("%s Stufe %d: %s geht schneller" % [TOOL_NAMES[kind], lvl + 1, TOOL_VERBS[kind]])
	return true



# --- Karren & Lagerplätze (v0.3) ---------------------------------------------------

## Fährt mindestens ein Karren? Dann legen die Sammler ihre Ladung an der Fackel ab.
func has_carts() -> bool:
	for b in buildings:
		if b.kind == "carts" and b.built and not b.workers.is_empty():
			return true
	return false


func depot_of(zone_id: String) -> Node3D:
	for d in get_tree().get_nodes_in_group("depots"):
		if d.zone_id == zone_id:
			return d
	return null


## Lagerplatz für einen Karrenfahrer: hell, genug Vorrat, nicht schon von einem anderen angefahren – der vollste.
func pick_depot(driver: Node3D) -> Node3D:
	var best: Node3D = null
	for d in get_tree().get_nodes_in_group("depots"):
		if _useful(d) < Config.cart_min_load or not d.is_safe():
			continue
		if d.claimed_by != null and is_instance_valid(d.claimed_by) and d.claimed_by != driver:
			continue
		if best == null or _useful(d) > _useful(best):
			best = d
	return best


## Platz im Lager der Festung je Art.
func room() -> Dictionary:
	return {"wood": maxi(wood_cap() - int(wood), 0), "food": maxi(food_cap() - int(food), 0),
			"stone": maxi(stone_cap() - int(stone), 0)}


## Wie viel vom Lagerplatz passt gerade in die Festung? (Volles Holzlager -> Holz lohnt die Fahrt nicht.)
func _useful(d: Node3D) -> int:
	var r := room()
	var n := 0
	for k in r:
		n += mini(d.stock[k], r[k])
	return n


## Was soll der Karren zuerst aufladen? Das, was das Lager am dringendsten braucht.
func cart_order() -> Array:
	var n := needs()
	var order := ["wood", "food", "stone"]
	order.sort_custom(func(a, b): return n[a] > n[b])
	return order



# --- Belagerung: Bewohner auf den Wachturm ---------------------------------------------

## Plätze oben auf dem Wachturm: Stufe 1: 4, Stufe 2: 6, Stufe 3: 8. Ohne Turm schießt niemand.
func tower_posts() -> Array:
	var out := []
	for b in buildings:
		if b.kind == "tower" and b.built:
			var top: Vector3 = b.top_position()
			var offs := [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(-0.8, 0, 0.8), Vector3(0.8, 0, 0.8),
					Vector3(0, 0, -0.9), Vector3(0, 0, 0.9), Vector3(-0.9, 0, 0), Vector3(0.9, 0, 0)]
			for i in mini(2 + 2 * b.level, offs.size()):
				out.append([b, top + offs[i]])
	return out


## Wer gerade in der Festung ist (und nicht schwer verletzt), steigt auf einen freien Platz.
func update_defense() -> void:
	var posts := tower_posts()
	var taken := 0
	for r in residents:
		if r.state == 8:
			taken += 1
	for r in residents:
		if taken >= posts.size():
			return
		if r.state in [0, 9] and r.hp >= r.max_hp() * 0.4 and not r.is_child():
			if r.state == 9:
				r._end_life()
			var p: Array = posts[taken]
			r.defend(p[0], p[1])
			taken += 1


func end_defense() -> void:
	for r in residents:
		r.stop_defend()


## Bewohner, die oben auf dem Turm stehen.
func defenders() -> Array:
	return residents.filter(func(r): return r.state == 8 and r.on_post)


# --- Eigenes Leben (v0.4): Tagesablauf, Bedürfnisse, Häuser, Paare, Kinder -------------

## "work" (Arbeitszeit), "free" (Freizeit) oder "night" (Nachtruhe)
func phase() -> String:
	var k := day_time / Config.day_length
	if k < Config.work_share:
		return "work"
	if k < Config.work_share + Config.free_share:
		return "free"
	return "night"


## Sekunden bis zum Ende der aktuellen Phase (für die Uhr im HUD).
func phase_left() -> float:
	var k := day_time / Config.day_length
	var end := 1.0
	if k < Config.work_share:
		end = Config.work_share
	elif k < Config.work_share + Config.free_share:
		end = Config.work_share + Config.free_share
	return end * Config.day_length - day_time


## Nacht-Anteil (v0.5): 0 = heller Tag, 1 = tiefe Nacht. Weich übergeblendet –
## Morgendämmerung zu Beginn der Arbeitszeit, Abenddämmerung über die ganze Freizeit, Nachtruhe = volle Nacht.
func night() -> float:
	var k := fposmod(day_time + _tick, Config.day_length) / Config.day_length
	if k < Config.dawn_share:
		return 1.0 - smoothstep(0.0, Config.dawn_share, k)
	if k < Config.work_share:
		return 0.0
	if k < Config.work_share + Config.free_share:
		return smoothstep(Config.work_share, Config.work_share + Config.free_share, k)
	return 1.0


func phase_name() -> String:
	return {"work": "Arbeitszeit", "free": "Freizeit", "night": "Nachtruhe"}[phase()]


func _clock_step(dt: float) -> void:
	day_time += dt
	while day_time >= Config.day_length:
		day_time -= Config.day_length
		day += 1
	var p := phase()
	if p != _last_phase:
		_last_phase = p
		match p:
			"work": message.emit("Tag %d – es wird hell, an die Arbeit" % day)
			"free": message.emit("Feierabend – es dämmert")
			"night":
				message.emit("Nachtruhe – die Dunkelheit wird stärker")
				_night_births()


## Hunger und Müdigkeit. Ohne jede Sättigung verliert man Leben – und verhungert.
func _needs_step(dt: float) -> void:
	var drain := Config.meal_satiety / Config.food_seconds_per_person
	var tired := 100.0 / (Config.day_length * (Config.work_share + Config.free_share) * 1.15)
	for r in residents.duplicate():
		r.age += dt
		r.satiety = maxf(r.satiety - drain * r.appetite() * dt, 0.0)
		if not r._lying:
			r.energy = maxf(r.energy - tired * dt, 0.0)
		if r.satiety <= 0.0:
			r.hp -= Config.starve_damage * dt
			if r.hp <= 0.0:
				kill_resident("%s ist verhungert.", r)


## Persönliche Stimmung: Haus, Partner, Kinder heben sie – Hunger und Müdigkeit drücken sie.
func personal_mood(r: Node3D) -> float:
	var m := 0.0
	if r.satiety < 25.0:
		m -= 15.0
	if r.energy < 25.0:
		m -= 8.0
	if r.is_child():
		return m + 5.0
	if r.house:
		m += 6.0
	elif day > 1:
		m -= 4.0
	if r.bond_kind == "Paar":
		m += 5.0
	if children_of(r) > 0:
		m += 4.0
	return m


func children_of(r: Node3D) -> int:
	if r.house == null:
		return 0
	var n := 0
	for c in r.house.residents:
		if is_instance_valid(c) and c.is_child():
			n += 1
	return n


## Bauplatz für diesen Bewohner (sein reservierter, sonst ein freier – der wird reserviert).
func hut_for(r: Node3D) -> Node3D:
	for h in huts:
		if h.claimed_by == r and not h.built:
			return h
	for h in huts:
		if h.is_free():
			h.claimed_by = r
			return h
	return null


## Haus fertig: der Bewohner (und sein Partner, falls der noch keins hat) zieht ein.
func give_house(r: Node3D, hut: Node3D) -> void:
	hut.build_for(r)
	r.house = hut
	Sfx.play_at("gate", hut.global_position, 0.0, 0.0)
	message.emit("%s hat sich ein Haus gebaut." % r.res_name)
	var p: Node3D = find_resident(r.bond_name) if r.bond_kind == "Paar" else null
	if p and p.house == null:
		p.house = hut
		hut.move_in(p)


## Nächste helle Zone, in der es gerade etwas von dieser Art gibt ("" = keine).
func nearest_zone_with(kind: String, from: Vector3) -> String:
	var best := ""
	var best_d := INF
	for z in ZoneDefs.ZONES:
		if zone_has(z["id"], kind):
			var d := Zones.center(get_tree(), z["id"]).distance_to(from)
			if d < best_d:
				best_d = d
				best = z["id"]
	return best


func training_spot() -> Vector3:
	return TRAINING_POS


## Gemeinsame Zeit am Feuer: zwei Erwachsene ohne Partner (und keine Geschwister) kommen sich näher.
var _court := {}                   # "A|B" -> Sekunden
func courtship_tick(r: Node3D, dt: float) -> void:
	if r.is_child() or r.bond_kind == "Paar" or r.mood < 40.0:
		return
	for o in residents:
		if o == r or o.state != 9 or o._act != "social" or o.is_child() or o.bond_kind == "Paar":
			continue
		if o.bond_name == r.res_name or o.mood < 40.0:
			continue
		if o.global_position.distance_to(r.global_position) > 4.0:
			continue
		var names := [r.res_name, o.res_name]
		names.sort()
		var key := "|".join(names)
		_court[key] = _court.get(key, 0.0) + dt * 0.5   # beide melden sich – also je die halbe Zeit
		if _court[key] >= Config.courtship_needed:
			_court.erase(key)
			bond(r, o, "Paar")
			message.emit("%s und %s sind jetzt ein Paar." % [r.res_name, o.res_name])
			r.mood = minf(r.mood + 15.0, 100.0)
			o.mood = minf(o.mood + 15.0, 100.0)
			# zusammenziehen: wer ein Haus hat, nimmt den anderen auf
			var h: Node3D = r.house if r.house else o.house
			if h:
				for x in [r, o]:
					if x.house and x.house != h:
						x.house.move_out(x)
					x.house = h
					h.move_in(x)
		return


## Nachts: Paare mit eigenem Haus bekommen manchmal ein Kind (wenn genug zu essen da ist).
func _night_births() -> void:
	var done := {}
	for r in residents.duplicate():
		if r.bond_kind != "Paar" or r.house == null or r.is_child() or done.has(r):
			continue
		var p := find_resident(r.bond_name)
		if p == null or p.house != r.house:
			continue
		done[p] = true
		done[r] = true
		if residents.size() >= Config.residents_max or food < residents.size() * 1.5:
			continue
		if (r.mood + p.mood) / 2.0 < 55.0 or _rng.randf() > Config.child_chance:
			continue
		var traits := []
		for t in [r.traits, p.traits]:
			if not t.is_empty():
				traits.append(t[_rng.randi() % t.size()])
		var id := new_identity()
		id["traits"] = traits.slice(0, 1) if (_rng.randf() < 0.6 and not traits.is_empty()) else ResidentData.roll_traits(_rng)
		id["age"] = 0.0
		id["satiety"] = 90.0
		var c := _add_resident(r.house.bed_pos(), id)
		c.house = r.house
		r.house.move_in(c)
		Sfx.play_at("levelup", r.house.global_position, -6.0, 0.0)
		message.emit("%s und %s haben ein Kind bekommen: %s" % [r.res_name, p.res_name, c.res_name])
		mood_shock(4.0)


## Übungsplatz: zwei Holzpfähle mit Querbalken.
func _make_training_post() -> void:
	var post := Node3D.new()
	add_child(post)
	post.position = TRAINING_POS
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.33, 0.2)
	for x in [-0.6, 0.6]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.18, 1.6, 0.18)
		m.mesh = bm
		m.material_override = mat
		m.position = Vector3(x, 0.8, 0)
		post.add_child(m)
	var bar := MeshInstance3D.new()
	var bb := BoxMesh.new()
	bb.size = Vector3(1.5, 0.15, 0.15)
	bar.mesh = bb
	bar.material_override = mat
	bar.position = Vector3(0, 1.3, 0)
	post.add_child(bar)
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.pixel_size = 0.0007
	l.font_size = 24
	l.outline_size = 6
	l.modulate = Color(1, 0.85, 0.65, 0.7)
	l.text = "Übungsplatz"
	l.position.y = 2.1
	post.add_child(l)



# --- Essen: Gasthaus oder Lager (v0.4) ---------------------------------------------------

func tavern_level() -> int:
	return _level_of("tavern")


## Wo isst man? Im Gasthaus, sonst am Lager (Vorratslager, ohne das am Feuer). {"pos", "tavern": Stufe}
func eat_place() -> Dictionary:
	for b in buildings:
		if b.kind == "tavern" and b.built:
			return {"pos": b.work_spot() + Vector3(_rng.randf_range(-0.8, 0.8), 0, _rng.randf_range(-0.8, 0.8)), "tavern": b.level}
	for b in buildings:
		if b.kind == "storehouse" and b.built:
			return {"pos": b.work_spot() + Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.6, 0.6)), "tavern": 0}
	var a := _rng.randf() * TAU
	return {"pos": Vector3(cos(a), 0, sin(a)) * 2.6, "tavern": 0}
