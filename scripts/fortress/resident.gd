## Ein Bewohner.
## Drinnen: arbeitet in seinem Gebäude oder bummelt ums Feuer (und heilt dort).
## Mit Zonen-Arbeit (Holzfäller/Sammler): läuft durchs Tor in die Zone, sammelt ein paar Einheiten,
## bringt sie zum Feuer und läuft wieder los. Arbeitet nur, solange die Zone hell ist und keine
## Belagerung droht. Draußen können Gegner ihn angreifen – verletzt flieht er heim.
## Steinbrecher holen Stein von den Felsen der Zone.
## Mit Bogen (aus der Werkstatt) schießt er draußen selbst auf Gegner in der Nähe.
## Geht eine Feuerstelle bald aus, bringt er Holz hin (Holzfäller in der Nähe direkt aus ihrer Ladung).
## Nebenbei: Ist er draußen im Lichtkreis einer Fackel/Feuerstelle, die unter 50 % ist, legt er kurz
## 1 Holz nach (aus seiner Ladung, sonst aus dem Lager) und macht dann weiter.
## v0.3 – Eigenleben: Name, 1–2 Eigenschaften (resident_data.gd), Stimmung 0–100, manchmal verbunden
## mit einem anderen Bewohner (Geschwister/Paar). Stirbt der Verbundene, trauert er.
## Gute Stimmung: arbeitet schneller. Verzweifelt: arbeitet halb so schnell und verlässt vielleicht die Festung.
extends Node3D

const HpBar := preload("res://scripts/hp_bar.gd")
const DamageNumber := preload("res://scripts/damage_number.gd")
const ArrowScript := preload("res://scripts/arrow.gd")

enum State { HOME, OUT, WORK, BACK, DELIVER, TEND, CART_OUT, DROP, DEFEND, LIFE }

const GATE_IN := Vector3(0, 0, -9.5)     # innen vor dem Tor
const GATE_OUT := Vector3(0, 0, -15.0)   # draußen vor dem Tor

var job: Node3D = null             # Gebäude, in dem er arbeitet (oder null)
var zone_id := ""                  # Zonen-Arbeit: in welcher Zone ("" = keine)
var zone_kind := ""                # "wood" (Holzfäller), "food" (Sammler) oder "stone" (Steinbrecher)
var _alt_zone := ""                # Ausweich-Arbeit: in der eigenen Zone ist nichts mehr zu holen -> hilft hier
var _alt_kind := ""
var _alt_check := 0.0
var hp := 0.0
var cargo := 0                      # getragene Einheiten
var cargo_kind := "wood"            # was er gerade trägt
var has_bow := false                # trägt einen Bogen (verteilt von der Festung)
var auto_job := false               # Zonen-Arbeit selbst gewählt (zählt weiter als "frei")
var res_name := ""                  # Name (v0.3)
var traits: Array = []              # Eigenschaften, z. B. ["flink"]
var mood := 60.0                    # Stimmung 0–100
var bond_name := ""                 # mit wem verbunden ("" = niemand)
var bond_kind := ""                 # "Geschwister" oder "Paar"
var grief := 0.0                    # s Trauer übrig
# --- eigenes Leben (v0.4) ---
var satiety := 80.0                 # Sättigung 0–100 (sinkt, Essen füllt auf)
var energy := 100.0                 # Kraft 0–100 (sinkt im Wachsein, Schlaf füllt auf)
var combat := 0.0                   # Kampf-Stufe 0–5 (Training am Übungsplatz)
var age := 99999.0                  # s seit der Geburt (Kinder: < Config.child_grow)
var house: Node3D = null            # eigenes Haus (oder null)
var pantry := 0.0                   # Nahrung im eigenen Haus
var house_wood := 0                 # selbst gehacktes Holz für das eigene Haus
var courtship := 0.0                # gemeinsame Zeit am Feuer mit einem möglichen Partner
var activity := ""                  # was er gerade tut (für das Menü)
var _name_label: Label3D
var cart_load := {"wood": 0, "food": 0, "stone": 0}   # Karrenfahrer: Ladung auf dem Karren
var _depot: Node3D = null           # Lagerplatz, zu dem er gerade fährt (Karren) bzw. geht (Ablegen)
var _cart: Node3D                   # Karren (nur sichtbar, wenn er Karrenfahrer ist)
var _cart_load_mesh: MeshInstance3D
var state := State.HOME

var _path: Array[Vector3] = []
var _target := Vector3.ZERO
var _wait := 0.0
var _gather_t := 0.0
var _node: Node3D = null           # Pilzstelle, an der er gerade sammelt (Sammler)
var _tree := -1                    # Baum, an dem er gerade hackt (Holzfäller)
var _fleeing := false
var _flash := 0.0
var _rng := RandomNumberGenerator.new()
var _mat := StandardMaterial3D.new()
var _hp_bar: Node3D
var _load_mesh: MeshInstance3D
var _load_mat := StandardMaterial3D.new()
var _bow_mesh: MeshInstance3D
var _shoot_cd := 0.0
var _delivery: Node3D = null        # Feuerstelle, zu der er Holz bringt
var _delivery_wood := 0
var _work_after_delivery := false  # Holzfäller: nach dem Abliefern weiterarbeiten
var _tend: Node3D = null            # Fackel/Feuerstelle, an der er gerade nebenbei nachlegt
var _tend_prev := 0                 # was er vorher gemacht hat
var _tend_t := 0.0
var _tend_cd := 0.0


func _ready() -> void:
	add_to_group("residents")
	_rng.randomize()
	hp = Config.resident_hp
	_mat.albedo_color = Color(0.5, 0.45, 0.38)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.28
	cm.height = 1.2
	cm.radial_segments = 8
	cm.rings = 2
	body.mesh = cm
	body.material_override = _mat
	body.position.y = 0.6
	add_child(body)
	var head := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	sm.radial_segments = 8
	sm.rings = 4
	head.mesh = sm
	head.material_override = _mat
	head.position.y = 1.35
	add_child(head)
	# Ladung auf dem Rücken (nur sichtbar, wenn er etwas trägt)
	_load_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.45, 0.3, 0.3)
	_load_mesh.mesh = bm
	_load_mesh.material_override = _load_mat
	_load_mesh.position = Vector3(0, 1.0, -0.3)
	_load_mesh.visible = false
	add_child(_load_mesh)
	# Bogen auf dem Rücken (nur sichtbar, wenn er einen trägt)
	_bow_mesh = MeshInstance3D.new()
	var bow := BoxMesh.new()
	bow.size = Vector3(0.06, 1.1, 0.06)
	_bow_mesh.mesh = bow
	var bow_mat := StandardMaterial3D.new()
	bow_mat.albedo_color = Color(0.55, 0.35, 0.18)
	_bow_mesh.material_override = bow_mat
	_bow_mesh.position = Vector3(0.22, 1.0, -0.22)
	_bow_mesh.rotation.z = 0.35
	_bow_mesh.visible = false
	add_child(_bow_mesh)
	_hp_bar = Node3D.new()
	_hp_bar.set_script(HpBar)
	add_child(_hp_bar)
	_hp_bar.setup(0.8)
	_hp_bar.position.y = 1.9
	_hp_bar._fill.material_override.albedo_color = Color(0.4, 0.85, 0.4)
	_name_label = Label3D.new()
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.fixed_size = true
	_name_label.pixel_size = 0.0008
	_name_label.font_size = 26
	_name_label.outline_size = 8
	_name_label.position.y = 2.2
	_name_label.visible = false
	add_child(_name_label)
	_build_cart()
	_pick_home_target()


## Name, Eigenschaften usw. setzen (von der Festung, gleich nach dem Erschaffen).
func setup_identity(d: Dictionary) -> void:
	res_name = d.get("name", "Namenlos")
	traits = Array(d.get("traits", []))
	mood = float(d.get("mood", Config.mood_start))
	bond_name = d.get("bond", "")
	bond_kind = d.get("bond_kind", "")
	grief = float(d.get("grief", 0.0))
	satiety = float(d.get("satiety", 80.0))
	energy = float(d.get("energy", 100.0))
	combat = float(d.get("combat", 0.0))
	age = float(d.get("age", 99999.0))
	pantry = float(d.get("pantry", 0.0))
	house_wood = int(d.get("house_wood", 0))
	hp = float(d.get("hp", max_hp()))
	_hp_bar.set_fraction(hp / max_hp())
	_update_size()


func identity() -> Dictionary:
	var fort := get_tree().get_first_node_in_group("fortress") if is_inside_tree() else null
	return {"name": res_name, "traits": traits, "mood": mood, "bond": bond_name, "bond_kind": bond_kind,
			"grief": grief, "hp": hp, "satiety": satiety, "energy": energy, "combat": combat, "age": age,
			"pantry": pantry, "house_wood": house_wood,
			"house": fort.huts.find(house) if fort and house else -1}


func has_trait(t: String) -> bool:
	return traits.has(t)


func max_hp() -> float:
	var m := Config.resident_hp
	if has_trait("zaeh"):
		m *= 1.5
	if has_trait("kraenklich"):
		m *= 0.75
	m *= 1.0 + 0.1 * floorf(combat)   # Kampftraining macht zäher
	if is_child():
		m *= 0.5
	return m


## Arbeitstempo: Stimmung, Trauer, Fleiß.
func efficiency() -> float:
	var e := 1.0
	if mood >= 75.0:
		e = 1.15
	elif mood < 25.0:
		e = 0.5
	if grief > 0.0:
		e *= 0.6
	if has_trait("fleissig"):
		e *= 1.25
	if energy < 25.0:
		e *= 0.6   # übermüdet
	return e


func appetite() -> float:
	var a := 1.0
	if has_trait("vielfrass"):
		a = 2.0
	elif has_trait("genuegsam"):
		a = 0.5
	return a * (0.5 if is_child() else 1.0)


func _speed() -> float:
	return Config.worker_speed * (1.3 if has_trait("flink") else 1.0)


func carry_cap() -> int:
	return Config.worker_carry + (2 if has_trait("kraeftig") else 0)


## Weigert er sich gerade hinauszugehen? (Ängstlich bei schlechter Stimmung)
func refuses() -> bool:
	return has_trait("aengstlich") and mood < 40.0


## Kurzbeschreibung für Menüs: "Hanna (Flink, Zäh)"
func title() -> String:
	var names := traits.map(func(t): return ResidentData.trait_name(t))
	return "%s (%s)" % [res_name, ", ".join(names)] if not names.is_empty() else res_name


func has_zone_job() -> bool:
	return zone_id != ""


## Schlüssel der von Max eingeteilten Zonen-Arbeit ("" = keine oder nur selbst gewählt).
func zone_key() -> String:
	return "%s:%s" % [zone_id, zone_kind] if has_zone_job() and not auto_job else ""


## Frei = von Max weder in ein Gebäude noch in eine Zone eingeteilt (selbstständige Helfer zählen als frei).
func is_free() -> bool:
	return job == null and (not has_zone_job() or auto_job) and not is_child()


## Steht er draußen vor der Mauer (dort können Gegner ihn erreichen)?
func is_exposed() -> bool:
	return global_position.z < -12.3


func is_alive() -> bool:
	return hp > 0.0


## Darf er gerade in seiner Zone arbeiten?
func can_work() -> bool:
	if _alt_zone != "" and not Zones.is_lit(get_tree(), _alt_zone):
		_alt_zone = ""   # Ausweich-Zone ist dunkel geworden: wieder die eigene Arbeit
		_alt_kind = ""
	return has_zone_job() and Zones.is_lit(get_tree(), wz()) and not Zones.recalled(get_tree()) and not refuses() \
			and _work_time() and not is_child()


## Gebäude-Arbeit zuteilen (von der Festung).
func assign(building: Node3D) -> void:
	if building == job:
		return
	job = building
	if state == State.HOME:
		_pick_home_target()


## Zonen-Arbeit zuteilen ("" = keine).
func set_zone_job(id: String, kind: String, auto := false) -> void:
	auto_job = auto and id != ""
	if id == zone_id and kind == zone_kind:
		return
	zone_id = id
	zone_kind = kind
	_alt_zone = ""
	_alt_kind = ""
	_node = null
	_tree = -1
	_work_after_delivery = false
	if state != State.HOME and state != State.DELIVER and state != State.DEFEND:
		_go_home()


## Getroffen (nur draußen möglich).
func take_damage(amount: float, _from: Node3D = null) -> void:
	if not is_alive():
		return
	hp -= amount
	_flash = 0.12
	Sfx.play_at("hurt", global_position, -8.0)
	_number(str(roundi(amount)), Color(1, 0.35, 0.3))
	_hp_bar.set_fraction(hp / max_hp())
	mood = maxf(mood - (4.0 if has_trait("aengstlich") else 2.0), 0.0)
	if hp <= 0.0:
		var fort := get_tree().get_first_node_in_group("fortress")
		if fort:
			fort.kill_resident("%s wurde draußen getötet.", self)
		return
	# verletzt: Ladung bleibt, aber sofort zurück in die Festung
	if state == State.TEND:
		_end_tend(false)
	if state == State.DELIVER:
		_work_after_delivery = false
		_abort_delivery()
		_fleeing = true
	elif state != State.HOME and not _fleeing:
		_fleeing = true
		_go_home()


func _process(delta: float) -> void:
	_flash -= delta
	_mat.albedo_color = Color(1, 0.75, 0.7) if _flash > 0.0 else Color(0.5, 0.45, 0.38)
	_load_mesh.visible = cargo > 0 or state == State.DELIVER
	_bow_mesh.visible = has_bow
	var driving := is_driver() and state in [State.CART_OUT, State.BACK]
	if _cart.visible != driving:
		_cart.visible = driving
	_cart_load_mesh.visible = _cart_total() > 0
	_update_name_label()
	_life_tick -= delta
	if _life_tick <= 0.0:
		_life_tick = 0.5
		_life_decide()
	if has_bow and is_exposed():
		_defend(delta)
	_tend_cd -= delta
	if _tend_cd <= 0.0 and not _fleeing and state in [State.OUT, State.WORK, State.BACK]:
		_tend_cd = 1.0
		_start_tend(_torch_to_tend())
	match state:
		State.HOME:
			_home(delta)
		State.OUT:
			if not can_work():
				_go_home()
			elif _follow_path(delta, _speed()):
				state = State.WORK
				_node = null
		State.WORK:
			_work(delta)
		State.BACK:
			if _follow_path(delta, _speed() * (1.6 if _fleeing else 1.0)):
				_arrive_home()
		State.TEND:
			_tend_step(delta)
		State.DELIVER:
			if Zones.recalled(get_tree()) or not is_instance_valid(_delivery) or _delivery.wood_space() <= 0:
				_abort_delivery()
			elif _follow_path(delta, _speed()):
				_finish_delivery()
		State.CART_OUT:
			_cart_out(delta)
		State.DEFEND:
			_defend_step(delta)
		State.LIFE:
			_life_step(delta)
		State.DROP:
			if not can_work() or not is_instance_valid(_depot):
				_go_home()
			elif _follow_path(delta, _speed()):
				_drop_at_depot()


## Drinnen: heilen, ums Feuer bummeln bzw. am Gebäude arbeiten; mit Zonen-Arbeit wieder losgehen.
func _home(delta: float) -> void:
	if hp < max_hp():
		var rate := Config.resident_heal_per_second * (0.5 if has_trait("kraenklich") else 1.0)
		hp = minf(hp + rate * delta, max_hp())
		_hp_bar.set_fraction(hp / max_hp())
	_wait -= delta
	if can_work() and _wait <= 0.0 and hp >= max_hp() * 0.6:
		_go_out()
		return
	if is_driver() and _wait <= 0.0 and hp >= max_hp() * 0.6 and not Zones.recalled(get_tree()) and not refuses() \
			and _work_time():
		var fort := get_tree().get_first_node_in_group("fortress")
		var d: Node3D = fort.pick_depot(self) if fort and _cart_total() < Config.cart_capacity else null
		if d:
			_start_cart(d)
			return
	var to := _target - global_position
	to.y = 0
	if to.length() > 0.2:
		_step_towards(_target, 1.6, delta)
	elif _wait <= 0.0:
		_pick_home_target()


## In der Zone: Baum bzw. Pilzstelle suchen, hinlaufen, hacken/sammeln, mit voller Ladung heim.
func _work(delta: float) -> void:
	if not can_work():
		_go_home()
		return
	var forest := get_tree().get_first_node_in_group("forest")
	var spot := Vector3.INF
	if wk() == "wood":
		var c := Zones.center(get_tree(), wz())
		if forest == null or not forest.has_wood(_tree) \
				or forest.tree_pos(_tree).distance_to(c) > Config.torch_light_radius - 1.0:   # Baum muss in SEINER Zone stehen
			# nur Bäume, die sicher im Licht der Zone stehen
			_tree = forest.nearest(Zones.center(get_tree(), wz()), Config.torch_light_radius - 1.5) if forest else -1
			_gather_t = 0.0
		if _tree >= 0:
			spot = forest.tree_pos(_tree)
	else:
		if _node == null or not is_instance_valid(_node) or not _node.is_available():
			_node = _find_node()
			_gather_t = 0.0
		if _node:
			spot = _node.global_position
	if spot == Vector3.INF:
		# nichts mehr zu holen: mit dem, was er hat, abladen – dann überlegen, was sonst gebraucht wird
		if cargo > 0:
			_unload_or_home()
		else:
			_find_other_work()
		return
	# Ausweich-Arbeit: ab und zu schauen, ob es in der eigentlichen Zone wieder etwas gibt
	if _alt_kind != "":
		_alt_check -= delta
		if _alt_check <= 0.0:
			_alt_check = 10.0
			var f := get_tree().get_first_node_in_group("fortress")
			if f and f.zone_has(zone_id, zone_kind) and cargo == 0:
				_alt_zone = ""
				_alt_kind = ""
				_number("zurück zur eigenen Arbeit", Color(0.8, 0.9, 1.0))
				_node = null
				_tree = -1
				_go_out()
				return
	var to := spot - global_position
	to.y = 0
	var reach: float = _node.reach() if wk() == "stone" and _node else 1.1
	if to.length() > reach:
		_step_towards(spot, _speed(), delta)
		return
	_gather_t += delta
	rotation.z = sin(_gather_t * 9.0) * 0.08   # kleine Arbeitsbewegung
	var fort := get_tree().get_first_node_in_group("fortress")
	if _gather_t >= Config.worker_gather_seconds / efficiency() * (fort.tool_factor(wk()) if fort else 1.0):
		_gather_t = 0.0
		var ok: bool = forest.take_one(_tree) if wk() == "wood" else _node.take_one()
		if ok:
			cargo += 1
			cargo_kind = wk()
			_load_mat.albedo_color = {"wood": Color(0.5, 0.32, 0.18), "food": Color(0.45, 0.85, 0.75),
					"stone": Color(0.6, 0.6, 0.65)}[wk()]
		if cargo >= carry_cap():
			# Holzfäller sieht eine Feuerstelle in der Nähe, die bald ausgeht? Dann bringt er das Holz dorthin.
			var pit := _low_fire_pit_near() if wk() == "wood" else null
			if pit:
				_delivery_wood = cargo
				cargo = 0
				_work_after_delivery = true
				_head_to_pit(pit)
			else:
				_unload_or_home()


## Nächste volle Pilzstelle bzw. Fels (Steinbrecher) in seiner Zone.
func _find_node() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var group := "rocks" if wk() == "stone" else "resources"
	for r in get_tree().get_nodes_in_group(group):
		if r.zone_id == wz() and (wk() == "stone" or r.kind == wk()) and r.is_available():
			var d := global_position.distance_to(r.global_position)
			if d < best_d:
				best_d = d
				best = r
	return best


func _go_out() -> void:
	state = State.OUT
	_fleeing = false
	_path.clear()
	if not is_exposed():
		_path.append(GATE_IN)
		_path.append(GATE_OUT)
	_path.append(Zones.center(get_tree(), wz()) + Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(1.0, 2.0)))


func _go_home() -> void:
	_stand_up()
	state = State.BACK
	rotation.z = 0.0
	_path.clear()
	if global_position.z < -11.0:
		_path.append(GATE_OUT)
		_path.append(GATE_IN)
	var a := _rng.randf_range(-PI * 0.8, -PI * 0.2)   # Seite des Feuers zum Tor hin
	_path.append(Vector3(cos(a), 0, sin(a)) * 3.0)


## Am Feuer angekommen: Ladung abgeben.
func _arrive_home() -> void:
	state = State.HOME
	_fleeing = false
	_wait = 2.0
	if cargo > 0:
		var fort := get_tree().get_first_node_in_group("fortress")
		if fort:
			var gave: Dictionary = fort.deposit({cargo_kind: cargo})
			var n: int = gave[cargo_kind]
			if n > 0:
				_number("+%d %s" % [n, {"wood": "Holz", "food": "Nahrung", "stone": "Stein"}[cargo_kind]],
						{"wood": Color(1, 0.75, 0.45), "food": Color(0.5, 1, 0.85), "stone": Color(0.8, 0.8, 0.9)}[cargo_kind])
		cargo = 0
	if _cart_total() > 0:
		var fort := get_tree().get_first_node_in_group("fortress")
		if fort:
			var gave: Dictionary = fort.deposit(cart_load)
			var parts := []
			for k in [["wood", "Holz"], ["food", "Nahrung"], ["stone", "Stein"]]:
				if gave[k[0]] > 0:
					parts.append("+%d %s" % [gave[k[0]], k[1]])
			if not parts.is_empty():
				_number(", ".join(parts), Color(1, 0.85, 0.55))
	_release_depot()
	_pick_home_target()


# --- Feuerstellen mit Holz versorgen ------------------------------------------------

## Von der Festung losgeschickt: n Holz (schon aus dem Lager genommen) zur Feuerstelle bringen.
func start_delivery(pit: Node3D, n: int) -> void:
	_delivery_wood = n
	_work_after_delivery = false
	_head_to_pit(pit)
	_number("bringt Holz", Color(1, 0.8, 0.5))


func _head_to_pit(pit: Node3D) -> void:
	_delivery = pit
	pit.courier = self
	state = State.DELIVER
	_fleeing = false
	_load_mat.albedo_color = Color(0.5, 0.32, 0.18)
	_path.clear()
	if not is_exposed() and pit.global_position.z < -12.0:
		_path.append(GATE_IN)
		_path.append(GATE_OUT)
	_path.append(pit.global_position + (global_position - pit.global_position).normalized() * 1.3)


func _finish_delivery() -> void:
	var n := mini(_delivery_wood, _delivery.wood_space())
	if n > 0:
		_delivery.add_wood(n)
		_number("+%d Holz ins Feuer" % n, Color(1, 0.75, 0.45))
	_delivery_wood -= n
	_delivery.courier = null
	_delivery = null
	_after_delivery()


## Abbruch (Belagerung, Feuerstelle weg oder voll): Holz geht zurück ins Lager.
func _abort_delivery() -> void:
	if is_instance_valid(_delivery):
		_delivery.courier = null
	_delivery = null
	_after_delivery()


func _after_delivery() -> void:
	if _delivery_wood > 0:
		cargo = _delivery_wood
		cargo_kind = "wood"
	_delivery_wood = 0
	if _work_after_delivery and can_work() and cargo == 0:
		_work_after_delivery = false
		state = State.WORK
		_tree = -1
	else:
		_work_after_delivery = false
		_go_home()


## Feuerstelle im Umkreis von 15 m, die bald ausgeht und zu der noch keiner unterwegs ist.
func _low_fire_pit_near() -> Node3D:
	for pit in get_tree().get_nodes_in_group("fire_pits"):
		if pit.needs_wood() and (pit.courier == null or not is_instance_valid(pit.courier)) \
				and global_position.distance_to(pit.global_position) < 15.0:
			return pit
	return null


# --- Nebenbei nachlegen --------------------------------------------------------------

## Fackel/Feuerstelle in Reichweite (im eigenen Lichtkreis), die unter 50 % ist und um die sich keiner kümmert.
func _torch_to_tend() -> Node3D:
	if Zones.recalled(get_tree()):
		return null
	var fort := get_tree().get_first_node_in_group("fortress")
	var has_wood: bool = (cargo_kind == "wood" and cargo > 0) or (fort and fort.spendable("wood") >= 1)
	if not has_wood:
		return null
	for t in get_tree().get_nodes_in_group("torches") + get_tree().get_nodes_in_group("fire_pits"):
		if not t.built or t.wood_space() < 1 or t.fuel >= t.max_fuel() * Config.tend_below:
			continue
		if t.tender and is_instance_valid(t.tender):
			continue
		var d := Vector2(t.global_position.x - global_position.x, t.global_position.z - global_position.z).length()
		if d < t.light_radius_full():
			return t
	return null


func _start_tend(t: Node3D) -> void:
	if t == null:
		return
	_tend = t
	t.tender = self
	_tend_prev = state
	_tend_t = 0.0
	state = State.TEND


func _tend_step(delta: float) -> void:
	if not is_instance_valid(_tend) or _tend.wood_space() < 1:
		_end_tend(true)
		return
	var spot: Vector3 = _tend.global_position + (global_position - _tend.global_position).normalized() * 1.2
	if not _step_towards(spot, _speed(), delta):
		return
	_tend_t += delta
	if _tend_t < 1.2:
		return   # kurz nachlegen
	var fort := get_tree().get_first_node_in_group("fortress")
	if cargo_kind == "wood" and cargo > 0:
		cargo -= 1
	elif fort and fort.spendable("wood") >= 1:
		fort.wood -= 1.0
	else:
		_end_tend(true)
		return
	_tend.add_wood(1)
	_number("+1 Holz nachgelegt", Color(1, 0.75, 0.45))
	_end_tend(true)


## Nachlegen beenden und weitermachen, wo er war.
func _end_tend(resume: bool) -> void:
	if is_instance_valid(_tend):
		_tend.tender = null
	_tend = null
	_tend_cd = Config.tend_cooldown
	if resume and state == State.TEND:
		state = _tend_prev


# --- Bogen ------------------------------------------------------------------------

## Mit Bogen: auf den nächsten Gegner in Reichweite schießen.
func _defend(delta: float) -> void:
	_shoot_cd -= delta
	if _shoot_cd > 0.0:
		return
	var best: Node3D = null
	var best_d := Config.resident_bow_range
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_alive():
			var d := global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
	if best == null:
		return
	_shoot_cd = Config.resident_bow_interval
	var arrow := Node3D.new()
	arrow.set_script(ArrowScript)
	get_parent().add_child(arrow)
	arrow.global_position = global_position + Vector3(0, 1.2, 0)
	arrow.launch(best, Config.resident_bow_damage * (2.0 if has_trait("schuetze") else 1.0) * combat_factor(), {}, self)
	Sfx.play_at("shoot", global_position, -10.0)


## Wird vom Pfeil aufgerufen.
func hit(target: Node3D, amount: float, _heal: Dictionary) -> void:
	if is_instance_valid(target) and target.is_alive():
		target.take_damage(amount, self)


## Läuft die Wegpunkte ab. Gibt true zurück, wenn das Ende erreicht ist.
func _follow_path(delta: float, speed: float) -> bool:
	if _path.is_empty():
		return true
	if _step_towards(_path[0], speed, delta):
		_path.pop_front()
	return _path.is_empty()


## Ein Schritt Richtung Ziel. true = angekommen.
func _step_towards(target: Vector3, speed: float, delta: float) -> bool:
	var to := target - global_position
	to.y = 0
	if to.length() <= 0.25:
		return true
	global_position += to.normalized() * minf(speed * delta, to.length())
	rotation.y = atan2(to.x, to.z)
	return false


func _pick_home_target() -> void:
	if job:
		_target = job.work_spot() + Vector3(_rng.randf_range(-0.6, 0.6), 0, _rng.randf_range(-0.6, 0.6))
	else:
		var a := _rng.randf() * TAU
		_target = Vector3(cos(a), 0, sin(a)) * _rng.randf_range(2.5, 4.5)
	_wait = maxf(_wait, _rng.randf_range(2.0, 5.0))


func _number(text: String, col: Color) -> void:
	var num := Label3D.new()
	num.set_script(DamageNumber)
	num.setup(0, col)
	num.text = text
	get_parent().add_child(num)
	num.global_position = global_position + Vector3(0, 2.2, 0)


## Name über dem Kopf: sichtbar, wenn der Hüter in der Nähe ist (Farbe = Stimmung).
func _update_name_label() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var near: bool = player != null and global_position.distance_to(player.global_position) < 6.5
	var show := near or _flash > 0.0
	if _name_label.visible != show:
		_name_label.visible = show
	if show:
		var t := res_name
		if grief > 0.0:
			t += " (trauert)"
		elif refuses():
			t += " (hat Angst)"
		_name_label.text = t
		_name_label.modulate = ResidentData.mood_color(mood)


## Ruft etwas (Sprechblase über dem Kopf, 3 s, auch von Weitem sichtbar).
func shout(text: String) -> void:
	var l := Label3D.new()
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.fixed_size = true
	l.no_depth_test = true
	l.pixel_size = 0.001
	l.font_size = 32
	l.outline_size = 10
	l.modulate = Color(1, 0.95, 0.7)
	l.text = "„%s“" % text
	l.position.y = 2.7
	add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", 3.2, 3.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.0).set_delay(2.0)
	tw.tween_callback(l.queue_free)



# --- Karren & Lagerplätze (v0.3) ---------------------------------------------------

## Arbeitet er im Karrenschuppen?
func is_driver() -> bool:
	return job != null and is_instance_valid(job) and job.kind == "carts"


func _cart_total() -> int:
	return cart_load["wood"] + cart_load["food"] + cart_load["stone"]


## Volle Ladung: gibt es Karren, an der Fackel ablegen und weiterarbeiten – sonst wie früher heim.
func _unload_or_home() -> void:
	var fort := get_tree().get_first_node_in_group("fortress")
	var d: Node3D = fort.depot_of(wz()) if fort and fort.has_carts() else null
	if d == null or d.space(cargo_kind) <= 0:
		_go_home()
		return
	_depot = d
	state = State.DROP
	_path.clear()
	_path.append(d.global_position + (global_position - d.global_position).normalized() * 1.1)


func _drop_at_depot() -> void:
	var n: int = _depot.put(cargo_kind, cargo)
	if n > 0:
		_number("+%d abgelegt" % n, Color(1, 0.85, 0.55))
	cargo -= n
	_depot = null
	if cargo > 0:
		_go_home()   # Lagerplatz voll: den Rest selbst heimtragen
	else:
		state = State.WORK
		_node = null
		_tree = -1


## Karrenfahrer: hinaus zum Lagerplatz.
func _start_cart(d: Node3D) -> void:
	_depot = d
	d.claimed_by = self
	state = State.CART_OUT
	_fleeing = false
	_path.clear()
	if not is_exposed():
		_path.append(GATE_IN)
		_path.append(GATE_OUT)
	_path.append(d.global_position + Vector3(0, 0, 1.6))
	_wait = 0.0


func _cart_out(delta: float) -> void:
	if Zones.recalled(get_tree()) or not is_instance_valid(_depot) or not _depot.is_safe():
		_go_home()
		return
	var spd := Config.cart_speed * (1.3 if has_trait("flink") else 1.0)
	if not _follow_path(delta, spd):
		return
	_wait += delta
	rotation.z = sin(_wait * 9.0) * 0.06
	if _wait < 2.0:
		return   # aufladen
	var fort := get_tree().get_first_node_in_group("fortress")
	var limits: Dictionary = fort.room() if fort else {}
	for k in limits:
		limits[k] = maxi(limits[k] - cart_load[k], 0)
	var got: Dictionary = _depot.take(Config.cart_capacity - _cart_total(),
			fort.cart_order() if fort else ["wood", "food", "stone"], limits)
	for k in got:
		cart_load[k] += got[k]
	_number("Karren beladen (%d)" % _cart_total(), Color(1, 0.85, 0.55))
	_go_home()


func _release_depot() -> void:
	if is_instance_valid(_depot) and _depot.claimed_by == self:
		_depot.claimed_by = null
	_depot = null


## Einfacher Handkarren vor dem Bewohner (Kasten, zwei Räder, Ladung).
func _build_cart() -> void:
	_cart = Node3D.new()
	_cart.position = Vector3(0, 0, 1.0)
	add_child(_cart)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.4, 0.28, 0.16)
	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 0.35, 1.1)
	box.mesh = bm
	box.material_override = wood
	box.position.y = 0.45
	_cart.add_child(box)
	for side in [-1, 1]:
		var w := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.28
		cm.bottom_radius = 0.28
		cm.height = 0.08
		cm.radial_segments = 10
		w.mesh = cm
		w.material_override = wood
		w.rotation.z = PI / 2.0
		w.position = Vector3(side * 0.5, 0.28, 0)
		_cart.add_child(w)
	_cart_load_mesh = MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.75, 0.3, 0.95)
	_cart_load_mesh.mesh = lm
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.55, 0.45, 0.3)
	_cart_load_mesh.material_override = lmat
	_cart_load_mesh.position.y = 0.75
	_cart.add_child(_cart_load_mesh)
	_cart.visible = false



# --- Belagerung: vom Wachturm aus verteidigen (v0.3) --------------------------------

var _post := Vector3.ZERO           # Platz oben auf dem Turm
var _post_tower: Node3D = null
var on_post := false                # steht oben und schießt


## Zum Wachturm gehen und hinaufsteigen.
func defend(tower: Node3D, post: Vector3) -> void:
	_post_tower = tower
	_post = post
	on_post = false
	state = State.DEFEND
	_path.clear()
	_path.append(tower.work_spot())


func stop_defend() -> void:
	if state != State.DEFEND:
		return
	if on_post and is_instance_valid(_post_tower):
		global_position = _post_tower.work_spot()   # wieder herunter
	on_post = false
	_post_tower = null
	state = State.HOME
	_wait = 1.0
	_pick_home_target()


func _defend_step(delta: float) -> void:
	if not is_instance_valid(_post_tower):
		stop_defend()
		return
	if not on_post:
		if _follow_path(delta, _speed() * 1.3):
			global_position = _post
			on_post = true
		return
	global_position = _post
	rotation.y = PI   # nach Norden, zum Tor hin



# --- Ausweich-Arbeit --------------------------------------------------------------

## Zone und Art, in der er gerade wirklich arbeitet (eigene Zuteilung oder Ausweich-Arbeit).
func wz() -> String:
	return _alt_zone if _alt_zone != "" else zone_id


func wk() -> String:
	return _alt_kind if _alt_kind != "" else zone_kind


## In der Zone ist nichts mehr zu holen: das Lager fragen, was sonst gebraucht wird, und dort helfen.
## Gibt es nirgends etwas Sinnvolles, geht er heim ans Feuer und ruht etwas, statt draußen herumzustehen.
func _find_other_work() -> void:
	var fort := get_tree().get_first_node_in_group("fortress")
	var alt: Array = fort.fallback_for(self) if fort else []
	if alt.is_empty():
		_alt_zone = ""
		_alt_kind = ""
		_go_home()
		_wait = 25.0   # erst später wieder hinaus
		_number("nichts zu tun – ruht am Feuer", Color(0.8, 0.8, 0.8))
		return
	var z: String = alt[0]
	var k: String = alt[1]
	if z == zone_id and k == zone_kind:
		_alt_zone = ""
		_alt_kind = ""
	else:
		_alt_zone = z
		_alt_kind = k
		_alt_check = 10.0
		_number("hilft bei: %s" % {"wood": "Holz", "food": "Nahrung", "stone": "Stein"}[k], Color(0.8, 0.9, 1.0))
	_node = null
	_tree = -1
	_go_out()


# --- Eigenes Leben (v0.4) -----------------------------------------------------------
# Tagesablauf (fortress.phase()): Arbeitszeit – Freizeit – Nachtruhe.
# In der Freizeit sorgt jeder für sich: essen, Holz fürs eigene Haus hacken und bauen, Nahrung für den eigenen
# Vorrat sammeln, am Übungsplatz trainieren, am Feuer zusammensitzen (daraus werden Paare). Nachts wird geschlafen.
# Kinder spielen am Feuer, bis sie erwachsen sind. Bei Belagerung (und schon beim Vorzeichen) gilt: alle heim.

var _act := ""                      # aktuelle Freizeit-Tätigkeit
var _act_t := 0.0
var _life_tick := 0.0
var _own := 0                       # für sich selbst getragene Einheiten (Holz fürs Haus / Nahrung für den Vorrat)
var _own_target: Variant = null      # Baum-Index (int) bzw. Pilzstelle (Node3D)
var _no_chop := 0.0                 # s, in denen „Holz fürs Haus“ nicht geht (keine helle Zone mit Bäumen)
var _no_forage := 0.0
var _lying := false
var _was_child := false


func is_child() -> bool:
	return age < Config.child_grow


func combat_factor() -> float:
	return 1.0 + 0.2 * floorf(combat)


func _fort() -> Node3D:
	return get_tree().get_first_node_in_group("fortress")


func _work_time() -> bool:
	var f := _fort()
	return f == null or f.phase() == "work"


## Kinder sind kleiner; werden sie erwachsen, wachsen sie.
func _update_size() -> void:
	var c := is_child()
	scale = Vector3.ONE * (0.65 if c else 1.0)
	if _was_child and not c:
		var f := _fort()
		if f:
			f.message.emit("%s ist erwachsen geworden." % res_name)
			f._assign_jobs()
	_was_child = c


## Zweimal pro Sekunde: Soll er gerade Freizeit haben, arbeiten oder heim?
func _life_decide() -> void:
	var f := _fort()
	if f == null:
		return
	if is_child() != _was_child:
		_update_size()
	var recalled: bool = Zones.recalled(get_tree())
	var phase: String = f.phase()
	if state == State.LIFE:
		if recalled and is_exposed():
			_end_life()
			_go_home()
		elif phase == "work" and not is_child() and _act != "eat" and not recalled:
			_end_life()
		elif phase == "night" and _act != "sleep" and _act != "eat":
			_start_act(_choose_act())
		return
	if state == State.HOME:
		if is_child() or phase != "work" or satiety < Config.starving_below:
			_start_life()
	elif state in [State.OUT, State.WORK] and not _fleeing:
		# Feierabend (oder großer Hunger): mit der Ladung heim
		if phase != "work" or satiety < Config.starving_below * 0.75:
			_go_home()


func _start_life() -> void:
	state = State.LIFE
	_start_act(_choose_act())


func _end_life() -> void:
	_stand_up()
	if _own > 0 and _act == "forage" and house:
		pantry = minf(pantry + _own, Config.pantry_max)
	_own = 0
	_act = ""
	activity = ""
	state = State.HOME
	_wait = 0.5
	_pick_home_target()


## Was tut er jetzt in seiner freien Zeit?
func _choose_act() -> String:
	var f := _fort()
	if f.phase() == "night" and satiety >= 30.0:
		return "sleep"
	if satiety < Config.hungry_below:
		return "eat"
	if is_child():
		return "play"
	if Zones.recalled(get_tree()):
		return "social"
	if bond_kind != "Paar" and _rng.randf() < 0.3:
		return "social"   # wer allein ist, sucht öfter Gesellschaft
	if house == null and _no_chop <= 0.0:
		if house_wood >= Config.house_wood and f.hut_for(self) != null:
			return "build"
		if house_wood < Config.house_wood and f.hut_for(self) != null and f.nearest_zone_with("wood", global_position) != "":
			return "chop"
	if house != null and pantry < Config.pantry_max - 1 and _no_forage <= 0.0 \
			and f.nearest_zone_with("food", global_position) != "":
		return "forage"
	if combat < Config.combat_max and _rng.randf() < 0.35:
		return "train"
	return "social"


func _start_act(a: String) -> void:
	_stand_up()
	_act = a
	_act_t = 0.0
	_own_target = null
	var f := _fort()
	var fire := Vector3.ZERO
	match a:
		"eat":
			activity = "isst"
			if house and pantry >= 1.0:
				_path_to(house.bed_pos())
			else:
				_path_to(_around(fire, 2.2, 3.0))
		"sleep":
			activity = "schläft" + ("" if house else " am Feuer")
			_path_to(house.bed_pos() if house else _around(fire, 2.5, 3.5))
		"chop":
			activity = "hackt Holz fürs eigene Haus (%d/%d)" % [house_wood, Config.house_wood]
			var z: String = f.nearest_zone_with("wood", global_position)
			var forest := get_tree().get_first_node_in_group("forest")
			var t: int = forest.nearest(Zones.center(get_tree(), z), Config.torch_light_radius - 1.5) if forest and z != "" else -1
			if t < 0:
				_no_chop = 30.0
				_start_act(_choose_act())
				return
			_own_target = t
			_path_to(forest.tree_pos(t))
		"build":
			var hut: Node3D = f.hut_for(self)
			activity = "baut sein Haus"
			_path_to(hut.global_position + (hut.bed_pos() - hut.global_position) * 1.3)
		"forage":
			activity = "sammelt Nahrung für zu Hause"
			var z2: String = f.nearest_zone_with("food", global_position)
			var best: Node3D = null
			for r in get_tree().get_nodes_in_group("resources"):
				if r.zone_id == z2 and r.is_available():
					best = r
					break
			if best == null:
				_no_forage = 30.0
				_start_act(_choose_act())
				return
			_own_target = best
			_path_to(best.global_position)
		"train":
			activity = "trainiert für den Kampf (Stufe %d)" % int(combat)
			_path_to(f.training_spot() + Vector3(_rng.randf_range(-1.2, 1.2), 0, _rng.randf_range(0.8, 1.4)))
		"social":
			activity = "sitzt am Feuer"
			_path_to(_around(fire, 2.2, 3.2))
		"play":
			activity = "spielt"
			_path_to(_around(fire, 2.0, 4.5))


func _life_step(delta: float) -> void:
	_no_chop -= delta
	_no_forage -= delta
	if not is_exposed() and hp < max_hp():
		var rate := Config.resident_heal_per_second * (0.5 if has_trait("kraenklich") else 1.0)
		hp = minf(hp + rate * delta, max_hp())
		_hp_bar.set_fraction(hp / max_hp())
	var f := _fort()
	match _act:
		"eat":
			if not _follow_path(delta, _speed()):
				return
			_act_t += delta
			if _act_t < 2.0:
				return
			_eat(f)
			_after_act()
		"sleep":
			if not _lying:
				if not _follow_path(delta, _speed()):
					return
				_lie_down()
			var k := Config.sleep_home_factor if house else Config.sleep_fire_factor
			energy = minf(energy + delta * 100.0 / (Config.day_length * (1.0 - Config.work_share - Config.free_share)) * k, 100.0)
			if f.phase() != "night":
				_after_act()
		"chop":
			_chop_step(delta, f)
		"build":
			if not _follow_path(delta, _speed()):
				return
			_act_t += delta
			rotation.z = sin(_act_t * 9.0) * 0.08
			if _act_t >= Config.house_build_time:
				rotation.z = 0.0
				var hut: Node3D = f.hut_for(self)
				if hut:
					house_wood -= Config.house_wood
					f.give_house(self, hut)
				_after_act()
		"forage":
			_forage_step(delta, f)
		"train":
			if not _follow_path(delta, _speed()):
				return
			_act_t += delta
			rotation.z = sin(_act_t * 12.0) * 0.12   # Schwertübungen
			var before := int(combat)
			combat = minf(combat + delta / Config.train_seconds_per_level, Config.combat_max)
			if int(combat) > before:
				_number("Kampf-Stufe %d" % int(combat), Color(1, 0.8, 0.5))
				f.message.emit("%s hat trainiert: Kampf-Stufe %d" % [res_name, int(combat)])
			if _act_t > 25.0:
				rotation.z = 0.0
				_after_act()
		"social", "play":
			if not _follow_path(delta, _speed() * (1.2 if _act == "play" else 1.0)):
				return
			_act_t += delta
			if _act == "social":
				f.courtship_tick(self, delta)
			if _act_t > (20.0 if _act == "social" else 8.0):
				_after_act()
		_:
			_after_act()


func _after_act() -> void:
	var f := _fort()
	if f.phase() == "work" and not is_child() and satiety >= Config.starving_below:
		_end_life()
	else:
		_start_act(_choose_act())


## Essen: aus dem eigenen Vorrat, sonst aus dem Lager der Festung.
func _eat(f: Node3D) -> void:
	var want := (95.0 - satiety) / Config.meal_satiety   # Nahrung, die er bräuchte
	if want <= 0.0:
		return
	var cost := 0.5 if f.ration_t > 0.0 else 1.0       # gekürzte Rationen: halb so viel
	var got := 0.0
	if house and pantry > 0.0:
		got = minf(want, pantry)
		pantry -= got
	var rest := want - got
	if rest > 0.0 and f.food > 0.0:
		var take := minf(rest * cost, f.food)
		f.food -= take
		got += take / cost
	satiety = minf(satiety + got * Config.meal_satiety, 100.0)
	if got <= 0.0:
		_number("nichts zu essen …", Color(1, 0.5, 0.4))


func _chop_step(delta: float, f: Node3D) -> void:
	var forest := get_tree().get_first_node_in_group("forest")
	if _own_target == null or forest == null:
		_after_act()
		return
	var t: int = _own_target
	if _own >= Config.own_carry or house_wood + _own >= Config.house_wood or not forest.has_wood(t):
		# zum Bauplatz bringen
		var hut: Node3D = f.hut_for(self)
		if hut == null:
			_own = 0
			_after_act()
			return
		if _path.is_empty() and global_position.distance_to(hut.global_position) > 2.5:
			_path_to(hut.global_position + (hut.bed_pos() - hut.global_position) * 1.3)
		if _follow_path(delta, _speed()):
			house_wood += _own
			if _own > 0:
				_number("+%d Holz fürs Haus" % _own, Color(1, 0.75, 0.45))
			_own = 0
			_after_act()
		return
	if not _follow_path(delta, _speed()):
		return
	_act_t += delta
	rotation.z = sin(_act_t * 9.0) * 0.08
	if _act_t >= Config.worker_gather_seconds / efficiency() * f.tool_factor("wood"):
		_act_t = 0.0
		if forest.take_one(t):
			_own += 1


func _forage_step(delta: float, f: Node3D) -> void:
	var node = _own_target
	if node == null or not is_instance_valid(node):
		_after_act()
		return
	if _own >= 2 or not node.is_available():
		if _own == 0:
			_after_act()
			return
		if _path.is_empty() and global_position.distance_to(house.bed_pos()) > 1.0:
			_path_to(house.bed_pos())
		if _follow_path(delta, _speed()):
			pantry = minf(pantry + _own, Config.pantry_max)
			_number("+%d Nahrung für zu Hause" % _own, Color(0.5, 1, 0.85))
			_own = 0
			_after_act()
		return
	if not _follow_path(delta, _speed()):
		return
	_act_t += delta
	if _act_t >= Config.worker_gather_seconds / efficiency() * f.tool_factor("food"):
		_act_t = 0.0
		if node.take_one():
			_own += 1


## Weg zu einem Ziel – durch das Tor, wenn die Mauer dazwischen liegt.
func _path_to(target: Vector3) -> void:
	_path.clear()
	var inside := not is_exposed() and global_position.z > -12.0
	var t_inside := target.z > -12.0
	if inside and not t_inside:
		_path.append(GATE_IN)
		_path.append(GATE_OUT)
	elif not inside and t_inside:
		_path.append(GATE_OUT)
		_path.append(GATE_IN)
	_path.append(target)


func _around(center: Vector3, r0: float, r1: float) -> Vector3:
	var a := _rng.randf() * TAU
	return center + Vector3(cos(a), 0, sin(a)) * _rng.randf_range(r0, r1)


func _lie_down() -> void:
	_lying = true
	rotation.x = -PI / 2.0
	position.y = 0.3


func _stand_up() -> void:
	if _lying:
		_lying = false
		rotation.x = 0.0
		position.y = 0.0
	rotation.z = 0.0
