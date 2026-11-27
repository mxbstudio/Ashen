## Schnellreise: erscheint am entzündeten Leuchtfeuer ("zum Tor") und
## innen am Tor ("zum Leuchtfeuer").
extends Button

@export var player: Node3D
@export var beacon: Node3D

const GATE_SPOT := Vector3(0, 0, -9.0)   # innen vor dem Tor

var _dest := Vector3.ZERO


func _ready() -> void:
	add_to_group("touch_blockers")
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(420, 80)
	add_theme_font_size_override("font_size", 26)
	add_theme_stylebox_override("normal", UiStyle.box(Color(0.4, 0.6, 1.0, 0.4), Color(0.6, 0.8, 1.0)))
	add_theme_stylebox_override("pressed", UiStyle.box(Color(0.4, 0.6, 1.0, 0.8), Color.WHITE, 3))
	add_theme_stylebox_override("hover", UiStyle.box(Color(0.4, 0.6, 1.0, 0.5), Color(0.6, 0.8, 1.0)))
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	pressed.connect(_on_pressed)
	visible = false


## Wichtig: Sichtbarkeit nur EINMAL pro Bild setzen – sonst geht ein Fingertipp verloren.
func _process(_delta: float) -> void:
	var show := false
	if beacon.lit and player.is_alive() and not get_tree().paused:
		var p := Vector2(player.global_position.x, player.global_position.z)
		if p.distance_to(Vector2(beacon.global_position.x, beacon.global_position.z)) < 3.5:
			text = "Schnellreise zum Tor"
			_dest = GATE_SPOT + Vector3(0, 0, 1.0)
			show = true
		elif p.distance_to(Vector2(GATE_SPOT.x, GATE_SPOT.z)) < 2.5:
			text = "Schnellreise zum Leuchtfeuer"
			_dest = beacon.global_position + Vector3(0, 0, 2.2)
			show = true
	if visible != show:
		visible = show
	if show:
		if not text.ends_with("]"):
			text += UiStyle.key_hint("F")
		var vp := get_viewport_rect().size
		size = custom_minimum_size
		position = Vector2((vp.x - size.x) / 2.0, vp.y - 680.0)


func _on_pressed() -> void:
	player.global_position = _dest
	player.velocity = Vector3.ZERO
	get_tree().call_group("hud", "toast", "Schnellreise")
