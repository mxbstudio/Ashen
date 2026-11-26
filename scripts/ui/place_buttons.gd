## Zwei Knöpfe rechts über dem Dash-Knopf, nur draußen sichtbar:
##  - "Kleine Fackel" (1 Holz): steckt eine kurz brennende Fackel vor dem Hüter in den Boden
##  - "Feuerstelle" (5 Stein + 1 Holz): baut eine nachfüllbare Feuerstelle vor dem Hüter
## Bezahlt wird zuerst aus der Trage, der Rest aus dem Lager (das letzte Holz bleibt fürs Feuer).
extends Control

const SmallTorch := preload("res://scripts/zones/small_torch.gd")
const FirePit := preload("res://scripts/zones/fire_pit.gd")

@export var player: Node3D
@export var fortress: Node3D

var _torch_btn: Button
var _pit_btn: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_torch_btn = UiStyle.button("", Color(1, 0.7, 0.3), 18, Vector2(125, 72))
	_torch_btn.pressed.connect(_place_torch)
	_pit_btn = UiStyle.button("", Color(0.85, 0.5, 0.3), 18, Vector2(125, 72))
	_pit_btn.pressed.connect(_place_pit)
	for b in [_torch_btn, _pit_btn]:
		b.add_to_group("touch_blockers")
		b.visible = false
		add_child(b)


## Wie viel hat man von einer Sache (Trage + Lager; beim Holz bleibt das letzte im Lager)?
func _available(kind: String) -> int:
	var store: int = int(fortress.wood) - 1 if kind == "wood" else int(fortress.stone)
	return player.carry[kind] + maxi(store, 0)


func _pay(kind: String, n: int) -> void:
	var from_carry := mini(player.carry[kind], n)
	player.carry[kind] -= from_carry
	if kind == "wood":
		fortress.wood -= n - from_carry
	else:
		fortress.stone -= n - from_carry


## Wichtig: Sichtbarkeit nur ändern, wenn nötig – sonst geht ein Fingertipp verloren.
func _process(_delta: float) -> void:
	var show: bool = player.is_alive() and not get_tree().paused and player.on_tower == null \
			and player.global_position.z < -12.5
	if _torch_btn.visible != show:
		_torch_btn.visible = show
		_pit_btn.visible = show
	if not show:
		return
	var n_t := get_tree().get_nodes_in_group("small_torches").size()
	_torch_btn.text = "Kl. Fackel\n%d Holz  (%d/%d)" % [Config.small_torch_cost, n_t, Config.small_torch_max]
	_torch_btn.disabled = _available("wood") < Config.small_torch_cost or n_t >= Config.small_torch_max
	var n_p := get_tree().get_nodes_in_group("fire_pits").size()
	_pit_btn.text = "Feuerstelle\n%d Stein  (%d/%d)" % [Config.firepit_stone_cost, n_p, Config.firepit_max]
	_pit_btn.disabled = _available("stone") < Config.firepit_stone_cost or _available("wood") < 1 \
			or n_p >= Config.firepit_max
	var vp := get_viewport_rect().size
	_torch_btn.size = _torch_btn.custom_minimum_size
	_pit_btn.size = _pit_btn.custom_minimum_size
	_torch_btn.position = Vector2(vp.x - 130, vp.y - 455)   # über der Skill-Leiste, rechts
	_pit_btn.position = Vector2(vp.x - 130, vp.y - 537)


## Stelle vor dem Hüter.
func _spot() -> Vector3:
	var p: Vector3 = player.global_position + player.facing * 1.3
	p.y = 0
	return p


func _place_torch() -> void:
	if _available("wood") < Config.small_torch_cost:
		return
	_pay("wood", Config.small_torch_cost)
	var t := Node3D.new()
	t.set_script(SmallTorch)
	_world().add_child(t)
	t.global_position = _spot()
	t.built = true
	t.fuel = t.max_fuel()
	t._update_visuals()
	Sfx.play("ignite", -4.0)


func _place_pit() -> void:
	var at := _spot()
	for other in get_tree().get_nodes_in_group("fire_pits") + get_tree().get_nodes_in_group("torches"):
		if Vector2(other.global_position.x - at.x, other.global_position.z - at.z).length() < 4.0:
			get_tree().call_group("hud", "toast", "Zu nah an einem anderen Feuer")
			return
	if _available("stone") < Config.firepit_stone_cost or _available("wood") < 1:
		return
	_pay("stone", Config.firepit_stone_cost)
	_pay("wood", 1)
	var pit := Node3D.new()
	pit.set_script(FirePit)
	_world().add_child(pit)
	pit.global_position = _spot()
	pit.build()
	pit.fuel = pit.seconds_per_wood()   # erste Füllung: 1 Holz
	pit._update_visuals()
	get_tree().call_group("hud", "toast", "Feuerstelle gebaut – Bewohner bringen Holz, wenn sie ausgeht")


## Hierhin kommen die gebauten Lichter (gespeichert werden sie über save_game.gd).
func _world() -> Node:
	return get_tree().get_first_node_in_group("world")
