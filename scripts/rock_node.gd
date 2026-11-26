## Abbaubarer Felsen draußen (Stein).
## Bleibt der Hüter daneben stehen, schlägt er Stein ab; Steinbrecher (Bewohner) ebenso.
## Der Felsen schrumpft mit jedem Stein; leer verschwindet er und wächst nach Config.rock_regrow wieder nach.
## Wie viel Stein noch drin ist, steht nur kurz über ihm, während jemand daran arbeitet.
extends Node3D

const LABEL_TIME := 3.0

var zone_id := ""                  # zu welcher Zone der Felsen gehört ("" = keine)
var radius := 1.0                  # Größe (für Aussehen und Kollision)
var amount := 0
var _regrow := 0.0
var _mesh: MeshInstance3D
var _shape: CollisionShape3D
var _label: Label3D
var _label_t := 0.0


func _ready() -> void:
	add_to_group("rocks")
	amount = Config.rock_stone
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.34, 0.34)
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 1.4
	sphere.radial_segments = 8
	sphere.rings = 4
	_mesh.mesh = sphere
	_mesh.material_override = mat
	_mesh.position.y = radius * 0.3
	add_child(_mesh)
	var body := StaticBody3D.new()
	_shape = CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius * 0.9
	cyl.height = 2.0
	_shape.shape = cyl
	_shape.position.y = 1.0
	body.add_child(_shape)
	add_child(body)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0008
	_label.font_size = 30
	_label.outline_size = 8
	_label.modulate = Color(0.85, 0.85, 0.95, 0.9)
	_label.position.y = radius + 1.2
	_label.visible = false
	add_child(_label)


func is_available() -> bool:
	return amount > 0


## Abbau-Abstand: Rand des Felsens + etwas Luft.
func reach() -> float:
	return radius + 1.3


## Einen Stein abschlagen.
func take_one() -> bool:
	if amount <= 0:
		return false
	amount -= 1
	_label.text = "Fels: %d Stein" % amount if amount > 0 else "abgebaut"
	_label.visible = true
	_label_t = LABEL_TIME
	if amount <= 0:
		_regrow = Config.rock_regrow
	_update()
	return true


func _update() -> void:
	var k := clampf(float(amount) / Config.rock_stone, 0.0, 1.0)
	_mesh.visible = amount > 0
	_mesh.scale = Vector3.ONE * lerpf(0.45, 1.0, k)
	_shape.disabled = amount <= 0


func _process(delta: float) -> void:
	if _label_t > 0.0:
		_label_t -= delta
		if _label_t <= 0.0:
			_label.visible = false
	if amount <= 0:
		_regrow -= delta
		if _regrow <= 0.0:
			amount = Config.rock_stone
			_update()
