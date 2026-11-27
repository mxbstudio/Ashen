## Knopf am Fackelpfahl: "Fackelpfahl errichten" bzw. "Holz nachlegen".
## Erscheint, wenn der Hüter direkt neben einem Fackelplatz steht.
## Holz kommt zuerst aus der Trage, der Rest aus dem Lager der Festung
## (das letzte Holz im Lager bleibt immer fürs Feuer).
extends Button

@export var player: Node3D
@export var fortress: Node3D

var _target: Node3D = null
var _cost := 0


func _ready() -> void:
	add_to_group("touch_blockers")
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(440, 90)
	add_theme_font_size_override("font_size", 24)
	add_theme_stylebox_override("normal", UiStyle.box(Color(0.9, 0.6, 0.25, 0.4), Color(1, 0.75, 0.4)))
	add_theme_stylebox_override("pressed", UiStyle.box(Color(0.9, 0.6, 0.25, 0.8), Color.WHITE, 3))
	add_theme_stylebox_override("hover", UiStyle.box(Color(0.9, 0.6, 0.25, 0.5), Color(1, 0.75, 0.4)))
	add_theme_stylebox_override("disabled", UiStyle.box(Color(0.3, 0.3, 0.3, 0.5), Color(0.6, 0.6, 0.6)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(_on_pressed)
	visible = false


## Wie viel Holz steht gerade zur Verfügung (Trage + Lager ohne die Reserve fürs Feuer)?
func _wood_available() -> int:
	return player.carry["wood"] + fortress.spendable("wood")


## Wichtig: Sichtbarkeit nur EINMAL pro Bild setzen – sonst geht ein Fingertipp verloren.
func _process(_delta: float) -> void:
	_target = null
	if player.is_alive() and not get_tree().paused:
		var p := Vector2(player.global_position.x, player.global_position.z)
		for t in get_tree().get_nodes_in_group("torches") + get_tree().get_nodes_in_group("fire_pits"):
			if p.distance_to(Vector2(t.global_position.x, t.global_position.z)) < Config.torch_use_range:
				_target = t
				break
	var show := _target != null
	if _target:
		var have := _wood_available()
		if not _target.built:
			_cost = Config.torch_build_cost
			text = "Fackelpfahl errichten (%d Holz)\n%s" % [_cost,
					"macht %s hell" % _target.zone_name if have >= _cost else "Nicht genug Holz (%d bleiben fürs Feuer)" % Config.vital_reserve]
		else:
			_cost = 1
			var s := int(_target.fuel)
			if _target.wood_space() <= 0:
				text = "%s ist voll  (%d:%02d)" % [_target.title(), s / 60, s % 60]
			elif _target.is_burning():
				text = "Holz nachlegen (1 Holz)\n+%d s · jetzt %d:%02d" % [int(_target.seconds_per_wood()), s / 60, s % 60]
			else:
				text = "%s entzünden (1 Holz)" % _target.title()
			if have < _cost:
				text += "\nNicht genug Holz (Trage + Lager)"
		disabled = have < _cost or (_target.built and _target.wood_space() <= 0)
		var vp := get_viewport_rect().size
		size = custom_minimum_size
		position = Vector2((vp.x - size.x) / 2.0, vp.y - 580.0)
	if visible != show:
		visible = show


func _on_pressed() -> void:
	if _target == null or _wood_available() < _cost:
		return
	# erst aus der Trage, dann aus dem Lager
	var from_carry := mini(player.carry["wood"], _cost)
	player.carry["wood"] -= from_carry
	fortress.wood -= _cost - from_carry
	if _target.built:
		_target.add_wood(_cost)
	else:
		_target.build()
