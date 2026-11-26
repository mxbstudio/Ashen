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
extends Node3D

const HpBar := preload("res://scripts/hp_bar.gd")
const DamageNumber := preload("res://scripts/damage_number.gd")
const ArrowScript := preload("res://scripts/arrow.gd")

enum State { HOME, OUT, WORK, BACK, DELIVER, TEND }

const GATE_IN := Vector3(0, 0, -9.5)     # innen vor dem Tor
const GATE_OUT := Vector3(0, 0, -15.0)   # draußen vor dem Tor

var job: Node3D = null             # Gebäude, in dem er arbeitet (oder null)
var zone_id := ""                  # Zonen-Arbeit: in welcher Zone ("" = keine)
var zone_kind := ""                # "wood" (Holzfäller), "food" (Sammler) oder "stone" (Steinbrecher)
var hp := 0.0
var cargo := 0                      # getragene Einheiten
var cargo_kind := "wood"            # was er gerade trägt
var has_bow := false                # trägt einen Bogen (verteilt von der Festung)
var auto_job := false               # Zonen-Arbeit selbst gewählt (zählt weiter als "frei")
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
	_pick_home_target()


func has_zone_job() -> bool:
	return zone_id != ""


## Schlüssel der von Max eingeteilten Zonen-Arbeit ("" = keine oder nur selbst gewählt).
func zone_key() -> String:
	return "%s:%s" % [zone_id, zone_kind] if has_zone_job() and not auto_job else ""


## Frei = von Max weder in ein Gebäude noch in eine Zone eingeteilt (selbstständige Helfer zählen als frei).
func is_free() -> bool:
	return job == null and (not has_zone_job() or auto_job)


## Steht er draußen vor der Mauer (dort können Gegner ihn erreichen)?
func is_exposed() -> bool:
	return global_position.z < -12.3


func is_alive() -> bool:
	return hp > 0.0


## Darf er gerade in seiner Zone arbeiten?
func can_work() -> bool:
	return has_zone_job() and Zones.is_lit(get_tree(), zone_id) and not Zones.recalled(get_tree())


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
	_node = null
	_tree = -1
	_work_after_delivery = false
	if state != State.HOME and state != State.DELIVER:
		_go_home()


## Getroffen (nur draußen möglich).
func take_damage(amount: float, _from: Node3D = null) -> void:
	if not is_alive():
		return
	hp -= amount
	_flash = 0.12
	Sfx.play("hurt", -8.0)
	_number(str(roundi(amount)), Color(1, 0.35, 0.3))
	_hp_bar.set_fraction(hp / Config.resident_hp)
	if hp <= 0.0:
		var fort := get_tree().get_first_node_in_group("fortress")
		if fort:
			fort.kill_resident("Ein Bewohner wurde draußen getötet.", self)
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
			elif _follow_path(delta, Config.worker_speed):
				state = State.WORK
				_node = null
		State.WORK:
			_work(delta)
		State.BACK:
			if _follow_path(delta, Config.worker_speed * (1.6 if _fleeing else 1.0)):
				_arrive_home()
		State.TEND:
			_tend_step(delta)
		State.DELIVER:
			if Zones.recalled(get_tree()) or not is_instance_valid(_delivery) or _delivery.wood_space() <= 0:
				_abort_delivery()
			elif _follow_path(delta, Config.worker_speed):
				_finish_delivery()


## Drinnen: heilen, ums Feuer bummeln bzw. am Gebäude arbeiten; mit Zonen-Arbeit wieder losgehen.
func _home(delta: float) -> void:
	if hp < Config.resident_hp:
		hp = minf(hp + Config.resident_heal_per_second * delta, Config.resident_hp)
		_hp_bar.set_fraction(hp / Config.resident_hp)
	_wait -= delta
	if can_work() and _wait <= 0.0 and hp >= Config.resident_hp * 0.6:
		_go_out()
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
	if zone_kind == "wood":
		if forest == null or not forest.has_wood(_tree):
			# nur Bäume, die sicher im Licht der Zone stehen
			_tree = forest.nearest(Zones.center(get_tree(), zone_id), Config.torch_light_radius - 1.5) if forest else -1
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
		# nichts mehr zu holen: mit dem, was er hat, heim – sonst am Licht warten
		if cargo > 0:
			_go_home()
		else:
			_step_towards(Zones.center(get_tree(), zone_id) + Vector3(1.5, 0, 1.5), Config.worker_speed, delta)
		return
	var to := spot - global_position
	to.y = 0
	var reach: float = _node.reach() if zone_kind == "stone" and _node else 1.1
	if to.length() > reach:
		_step_towards(spot, Config.worker_speed, delta)
		return
	_gather_t += delta
	rotation.z = sin(_gather_t * 9.0) * 0.08   # kleine Arbeitsbewegung
	if _gather_t >= Config.worker_gather_seconds:
		_gather_t = 0.0
		var ok: bool = forest.take_one(_tree) if zone_kind == "wood" else _node.take_one()
		if ok:
			cargo += 1
			cargo_kind = zone_kind
			_load_mat.albedo_color = {"wood": Color(0.5, 0.32, 0.18), "food": Color(0.45, 0.85, 0.75),
					"stone": Color(0.6, 0.6, 0.65)}[zone_kind]
		if cargo >= Config.worker_carry:
			# Holzfäller sieht eine Feuerstelle in der Nähe, die bald ausgeht? Dann bringt er das Holz dorthin.
			var pit := _low_fire_pit_near() if zone_kind == "wood" else null
			if pit:
				_delivery_wood = cargo
				cargo = 0
				_work_after_delivery = true
				_head_to_pit(pit)
			else:
				_go_home()


## Nächste volle Pilzstelle bzw. Fels (Steinbrecher) in seiner Zone.
func _find_node() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var group := "rocks" if zone_kind == "stone" else "resources"
	for r in get_tree().get_nodes_in_group(group):
		if r.zone_id == zone_id and (zone_kind == "stone" or r.kind == zone_kind) and r.is_available():
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
	_path.append(Zones.center(get_tree(), zone_id) + Vector3(_rng.randf_range(-1.5, 1.5), 0, _rng.randf_range(1.0, 2.0)))


func _go_home() -> void:
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
	var has_wood: bool = (cargo_kind == "wood" and cargo > 0) or (fort and fort.wood >= 2.0)
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
	if not _step_towards(spot, Config.worker_speed, delta):
		return
	_tend_t += delta
	if _tend_t < 1.2:
		return   # kurz nachlegen
	var fort := get_tree().get_first_node_in_group("fortress")
	if cargo_kind == "wood" and cargo > 0:
		cargo -= 1
	elif fort and fort.wood >= 2.0:
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
	arrow.launch(best, Config.resident_bow_damage, {}, self)
	Sfx.play("shoot", -10.0)


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
