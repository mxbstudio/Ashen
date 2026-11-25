## Die Spielwelt: Boden, Festungsmauer mit einem Tor, das dunkle Gebiet davor,
## Felsen und tote Bäume. Alles aus einfachen Formen, im Code erzeugt.
##
## Karte (von oben, x nach rechts, z nach unten):
##   z = +14 … -12  : Festung (24 × 24 m) mit Feuer in der Mitte, Tor in der Nordmauer (z = -12)
##   z = -12 … -90  : das Gebiet draußen (60 m breit)
extends Node3D

const FORT_HALF := 12.0            # Festung: x und z von -12 bis +12
const GATE_WIDTH := 4.0
const OUT_MIN := Vector2(-30, -92) # Außengebiet (x, z)
const OUT_MAX := Vector2(30, -12)

const ResourceScript := preload("res://scripts/resource_node.gd")
const WOOD_SPOTS := [Vector3(-8, 0, -20), Vector3(9, 0, -24), Vector3(-18, 0, -30), Vector3(20, 0, -34),
		Vector3(-5, 0, -38), Vector3(12, 0, -46), Vector3(-22, 0, -50), Vector3(4, 0, -58),
		Vector3(-12, 0, -66), Vector3(18, 0, -70)]
const FOOD_SPOTS := [Vector3(-14, 0, -22), Vector3(24, 0, -26), Vector3(22, 0, -44),
		Vector3(-7, 0, -53), Vector3(14, 0, -62), Vector3(-24, 0, -72)]

var _rock_mat := StandardMaterial3D.new()
var _tree_mat := StandardMaterial3D.new()
var _wall_mat := StandardMaterial3D.new()


func _ready() -> void:
	_rock_mat.albedo_color = Color(0.32, 0.3, 0.3)
	_tree_mat.albedo_color = Color(0.22, 0.17, 0.13)
	_wall_mat.albedo_color = Color(0.36, 0.33, 0.3)
	_make_ground()
	_make_bounds()
	_make_fort_walls()
	_make_resources()
	_make_obstacles()


func _make_resources() -> void:
	for p in WOOD_SPOTS:
		_resource(p, "wood")
	for p in FOOD_SPOTS:
		_resource(p, "food")


func _resource(p: Vector3, kind: String) -> void:
	var n := Node3D.new()
	n.set_script(ResourceScript)
	n.kind = kind
	n.position = p
	add_child(n)


func _near_resource(p: Vector3) -> bool:
	for s in WOOD_SPOTS + FOOD_SPOTS:
		if p.distance_to(s) < 3.5:
			return true
	return false


## Liegt der Punkt im Außengebiet? (für Gegner, Fundstellen)
static func is_outside(p: Vector3, margin := 0.0) -> bool:
	return p.x > OUT_MIN.x + margin and p.x < OUT_MAX.x - margin \
			and p.z > OUT_MIN.y + margin and p.z < OUT_MAX.y - margin


func _make_ground() -> void:
	# Außen: dunkler, kalter Boden
	_ground(Vector3(0, 0, (OUT_MIN.y + OUT_MAX.y) / 2.0), Vector2(OUT_MAX.x - OUT_MIN.x, OUT_MAX.y - OUT_MIN.y),
			Color(0.17, 0.17, 0.18))
	# Festung: gestampfte Erde, etwas wärmer
	_ground(Vector3(0, 0, 1), Vector2(FORT_HALF * 2 + 6, FORT_HALF * 2 + 2), Color(0.24, 0.21, 0.18))
	# Flecken, damit man Bewegung sieht
	var spot_mat := StandardMaterial3D.new()
	spot_mat.albedo_color = Color(0.14, 0.14, 0.15)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 40:
		var p := Vector3(rng.randf_range(-28, 28), 0.01, rng.randf_range(-90, -14))
		var m := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(rng.randf_range(3, 7), rng.randf_range(3, 7))
		m.mesh = pm
		m.material_override = spot_mat
		m.position = p
		m.rotation.y = rng.randf() * PI
		add_child(m)


func _ground(center: Vector3, size: Vector2, col: Color) -> void:
	var g := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = size
	plane.subdivide_width = int(size.x / 5.0)
	plane.subdivide_depth = int(size.y / 5.0)
	g.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	g.material_override = mat
	g.position = center
	add_child(g)


## Unsichtbare Grenzen um die ganze Karte.
func _make_bounds() -> void:
	var zmin := OUT_MIN.y
	var zmax := FORT_HALF + 2.0
	_box_body(Vector3(OUT_MIN.x - 0.5, 2, (zmin + zmax) / 2), Vector3(1, 4, zmax - zmin), null)
	_box_body(Vector3(OUT_MAX.x + 0.5, 2, (zmin + zmax) / 2), Vector3(1, 4, zmax - zmin), null)
	_box_body(Vector3(0, 2, zmin - 0.5), Vector3(OUT_MAX.x - OUT_MIN.x + 2, 4, 1), null)
	_box_body(Vector3(0, 2, zmax + 0.5), Vector3(OUT_MAX.x - OUT_MIN.x + 2, 4, 1), null)
	# Außerhalb der Festung, aber neben ihr (links/rechts) ist kein Gebiet: sperren
	var side_w := OUT_MAX.x - FORT_HALF
	_box_body(Vector3(FORT_HALF + side_w / 2 + 0.5, 2, 1), Vector3(side_w, 4, FORT_HALF * 2 + 2), null)
	_box_body(Vector3(-FORT_HALF - side_w / 2 - 0.5, 2, 1), Vector3(side_w, 4, FORT_HALF * 2 + 2), null)


## Mauer: hinten (Nord, mit Tor) und links hoch, vorne/rechts niedrig,
## damit sie den Blick der Kamera nicht verdeckt.
func _make_fort_walls() -> void:
	var h := FORT_HALF
	var high := 3.0
	var low := 1.0
	var t := 0.8
	var seg := h - GATE_WIDTH / 2.0
	# Nordmauer mit Lücke fürs Tor
	_box_body(Vector3(-(GATE_WIDTH / 2 + seg / 2), high / 2, -h), Vector3(seg, high, t), _wall_mat)
	_box_body(Vector3(GATE_WIDTH / 2 + seg / 2, high / 2, -h), Vector3(seg, high, t), _wall_mat)
	# Torpfosten
	for side in [-1, 1]:
		_box_body(Vector3(side * (GATE_WIDTH / 2 + 0.4), 2.0, -h), Vector3(0.8, 4.0, 1.2), _wall_mat)
	# Westmauer (hoch), Ost- und Südmauer (niedrig)
	_box_body(Vector3(-h, high / 2, 0), Vector3(t, high, h * 2), _wall_mat)
	_box_body(Vector3(h, low / 2, 0), Vector3(t, low, h * 2), _wall_mat)
	_box_body(Vector3(0, low / 2, h), Vector3(h * 2 + t, low, t), _wall_mat)


func _box_body(pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	if mat:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = size
		mi.mesh = bm
		mi.material_override = mat
		body.add_child(mi)
	add_child(body)


func _make_obstacles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var placed := 0
	var tries := 0
	while placed < 55 and tries < 400:
		tries += 1
		var p := Vector3(rng.randf_range(-28, 28), 0, rng.randf_range(-90, -15))
		# Weg vor dem Tor und Boss-Platz freihalten
		if absf(p.x) < 4.0 and p.z > -26.0:
			continue
		if p.distance_to(Vector3(0, 0, -80)) < 10.0 or p.distance_to(Vector3(0, 0, -50)) < 5.0:
			continue   # Boss-Platz und Leuchtfeuer frei
		if _near_resource(p):
			continue
		if placed % 2 == 0:
			_make_rock(p, rng.randf_range(0.6, 1.6))
		else:
			_make_tree(p, rng.randf_range(2.0, 3.5))
		placed += 1


func _make_rock(pos: Vector3, r: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = r
	sphere.height = r * 1.4
	sphere.radial_segments = 8
	sphere.rings = 4
	mesh.mesh = sphere
	mesh.material_override = _rock_mat
	mesh.position.y = r * 0.3
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r * 0.9
	cyl.height = 2.0
	shape.shape = cyl
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)


func _make_tree(pos: Vector3, h: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.3
	cyl.height = h
	cyl.radial_segments = 6
	mesh.mesh = cyl
	mesh.material_override = _tree_mat
	mesh.position.y = h / 2.0
	body.add_child(mesh)
	var branch := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.03
	bm.bottom_radius = 0.1
	bm.height = h * 0.4
	bm.radial_segments = 5
	branch.mesh = bm
	branch.material_override = _tree_mat
	branch.position = Vector3(0.25, h * 0.65, 0)
	branch.rotation.z = -0.9
	body.add_child(branch)
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.35
	cs.height = 2.0
	shape.shape = cs
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)
