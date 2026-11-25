## Ein Bewohner.
## Drinnen: arbeitet in seinem Gebäude oder bummelt ums Feuer (und heilt dort).
## Mit Zonen-Arbeit (Holzfäller/Sammler): läuft durchs Tor in die Zone, sammelt ein paar Einheiten,
## bringt sie zum Feuer und läuft wieder los. Arbeitet nur, solange die Zone hell ist und keine
## Belagerung droht. Draußen können Gegner ihn angreifen – verletzt flieht er heim.
extends Node3D

const HpBar := preload("res://scripts/hp_bar.gd")
const DamageNumber := preload("res://scripts/damage_number.gd")

enum State { HOME, OUT, WORK, BACK }

const GATE_IN := Vector3(0, 0, -9.5)     # innen vor dem Tor
const GATE_OUT := Vector3(0, 0, -15.0)   # draußen vor dem Tor

var job: Node3D = null             # Gebäude, in dem er arbeitet (oder null)
var zone_id := ""                  # Zonen-Arbeit: in welcher Zone ("" = keine)
var zone_kind := ""                # "wood" (Holzfäller) oder "food" (Sammler)
var hp := 0.0
var cargo := 0                      # getragene Einheiten
var state := State.HOME

var _path: Array[Vector3] = []
var _target := Vector3.ZERO
var _wait := 0.0
var _gather_t := 0.0
var _node: Node3D = null           # Fundstelle, an der er gerade arbeitet
var _fleeing := false
var _flash := 0.0
var _rng := RandomNumberGenerator.new()
var _mat := StandardMaterial3D.new()
var _hp_bar: Node3D
var _load_mesh: MeshInstance3D
var _load_mat := StandardMaterial3D.new()


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
	_hp_bar = Node3D.new()
	_hp_bar.set_script(HpBar)
	add_child(_hp_bar)
	_hp_bar.setup(0.8)
	_hp_bar.position.y = 1.9
	_hp_bar._fill.material_override.albedo_color = Color(0.4, 0.85, 0.4)
	_pick_home_target()


func has_zone_job() -> bool:
	return zone_id != ""


func zone_key() -> String:
	return "%s:%s" % [zone_id, zone_kind] if has_zone_job() else ""


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
func set_zone_job(id: String, kind: String) -> void:
	if id == zone_id and kind == zone_kind:
		return
	zone_id = id
	zone_kind = kind
	_node = null
	if state != State.HOME:
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
	if state != State.HOME and not _fleeing:
		_fleeing = true
		_go_home()


func _process(delta: float) -> void:
	_flash -= delta
	_mat.albedo_color = Color(1, 0.75, 0.7) if _flash > 0.0 else Color(0.5, 0.45, 0.38)
	_load_mesh.visible = cargo > 0
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
			if _follow_path(delta, Config.worker_speed * (1.3 if _fleeing else 1.0)):
				_arrive_home()


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


## In der Zone: Fundstelle suchen, hinlaufen, sammeln, mit voller Ladung heim.
func _work(delta: float) -> void:
	if not can_work():
		_go_home()
		return
	if _node == null or not is_instance_valid(_node) or not _node.is_available():
		_node = _find_node()
		_gather_t = 0.0
	if _node == null:
		# nichts mehr zu holen: mit dem, was er hat, heim – sonst am Licht warten
		if cargo > 0:
			_go_home()
		else:
			_step_towards(Zones.center(get_tree(), zone_id) + Vector3(1.5, 0, 1.5), Config.worker_speed, delta)
		return
	var to := _node.global_position - global_position
	to.y = 0
	if to.length() > 1.3:
		_step_towards(_node.global_position, Config.worker_speed, delta)
		return
	_gather_t += delta
	rotation.z = sin(_gather_t * 9.0) * 0.08   # kleine Arbeitsbewegung
	if _gather_t >= Config.worker_gather_seconds:
		_gather_t = 0.0
		if _node.take_one():
			cargo += 1
			_load_mat.albedo_color = Color(0.5, 0.32, 0.18) if zone_kind == "wood" else Color(0.45, 0.85, 0.75)
		if cargo >= Config.worker_carry:
			_go_home()


func _find_node() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for r in get_tree().get_nodes_in_group("resources"):
		if r.zone_id == zone_id and r.kind == zone_kind and r.is_available():
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
			var carry := {"wood": cargo if zone_kind == "wood" else 0, "food": cargo if zone_kind == "food" else 0}
			var gave: Dictionary = fort.deposit(carry)
			var n: int = gave["wood"] + gave["food"]
			if n > 0:
				_number("+%d %s" % [n, "Holz" if gave["wood"] > 0 else "Nahrung"],
						Color(1, 0.75, 0.45) if gave["wood"] > 0 else Color(0.5, 1, 0.85))
		cargo = 0
	_pick_home_target()


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
