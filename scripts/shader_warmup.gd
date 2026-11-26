## Vorwärmen gegen Ruckler: Der Browser muss beim ERSTEN Anzeigen jeder Art von Oberfläche
## (Gegner, leuchtende Augen, Lebensbalken, Zahlen, Pfeile, Feuer …) einmal ein kleines Grafikprogramm
## vorbereiten – das ruckelt kurz. Deshalb zeigen wir gleich beim Start je ein Beispiel von allem,
## versteckt UNTER dem Boden direkt beim Hüter, für ein paar Bilder – dann wird alles wieder entfernt.
extends Node3D

const SHOW_FRAMES := 8

@export var player: Node3D

var _frames := 0
var _things: Array[Node] = []


func _ready() -> void:
	_spawn.call_deferred()


func _spawn() -> void:
	global_position = player.global_position + Vector3(0, -3.5, 0)   # unter dem Boden, aber im Bild
	var scripts := [
		"res://scripts/enemies/crawler.gd", "res://scripts/enemies/lighteater.gd", "res://scripts/enemies/lost.gd",
		"res://scripts/fortress/resident.gd", "res://scripts/zones/fire_pit.gd", "res://scripts/zones/small_torch.gd",
		"res://scripts/rock_node.gd", "res://scripts/phantom.gd",
	]
	var x := -3.0
	for path in scripts:
		var n: Node3D = load(path).new()
		n.process_mode = Node.PROCESS_MODE_DISABLED   # nur zeigen, keine Spiel-Logik
		add_child(n)
		n.position = Vector3(x, 0, 0)
		x += 1.0
		_things.append(n)
		# nicht als echter Gegner/Bewohner/Fackel zählen
		for g in n.get_groups():
			n.remove_from_group(g)
		_warm_extras(n)
	# Effekte: Zahl, Sichelbogen, Glockenwelle, Pfeil/Glut
	var num := Label3D.new()
	num.set_script(preload("res://scripts/damage_number.gd"))
	num.setup(5, Color(1, 1, 1, 0.02))
	num.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(num)
	_things.append(num)
	var slash := MeshInstance3D.new()
	slash.set_script(preload("res://scripts/slash_effect.gd"))
	slash.setup(2.0, 120.0, false)
	slash.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(slash)
	_things.append(slash)
	var wave := MeshInstance3D.new()
	wave.set_script(preload("res://scripts/bell_wave.gd"))
	wave.setup(2.0, false)
	wave.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(wave)
	_things.append(wave)
	for burning in [false, true]:
		var arrow := Node3D.new()
		arrow.set_script(preload("res://scripts/arrow.gd"))
		arrow.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(arrow)
		arrow.launch(null, 0.0, {}, null, burning)
		_things.append(arrow)


## Feuer: auch die Flamme zeigen.
func _warm_extras(n: Node) -> void:
	if n.has_method("_update_visuals") and "built" in n:
		n.built = true
		n.fuel = 10.0
		n._update_visuals()
	# keine zusätzlichen Lichter (würden den Boden von unten aufhellen)
	for c in n.get_children():
		if c is Light3D:
			c.visible = false


func _process(_delta: float) -> void:
	if _things.is_empty():
		return
	_frames += 1
	if _frames >= SHOW_FRAMES:
		for t in _things:
			if is_instance_valid(t):
				t.queue_free()
		_things.clear()
		queue_free()
