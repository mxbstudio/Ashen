## Etappe 1: einfaches Testgelände – Boden, Felsen, tote Bäume und ein Rand.
## Alles aus einfachen Formen, im Code erzeugt.
extends Node3D

const DummyScript := preload("res://scripts/dummy.gd")

const HALF_SIZE := 30.0   # Gelände ist 60 × 60 m

var _rock_mat := StandardMaterial3D.new()
var _tree_mat := StandardMaterial3D.new()


func _ready() -> void:
	_rock_mat.albedo_color = Color(0.32, 0.3, 0.3)
	_tree_mat.albedo_color = Color(0.22, 0.17, 0.13)
	_make_ground()
	_make_border()
	# Übungspuppen (zum Testen der Skill-Leiste)
	for p in [Vector3(7, 0, -3), Vector3(9, 0, 1), Vector3(-8, 0, 6), Vector3(-2, 0, -12)]:
		var d := StaticBody3D.new()
		d.set_script(DummyScript)
		d.position = p
		add_child(d)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7   # fester Startwert -> Gelände sieht immer gleich aus
	for i in 25:
		var p := Vector3(rng.randf_range(-27, 27), 0, rng.randf_range(-27, 27))
		if p.length() < 5.0 or _near_dummy(p):
			continue   # Startplatz frei lassen
		if i % 2 == 0:
			_make_rock(p, rng.randf_range(0.6, 1.6))
		else:
			_make_tree(p, rng.randf_range(2.0, 3.5))


func _make_ground() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_SIZE * 2, HALF_SIZE * 2)
	plane.subdivide_width = 12   # Unterteilung: Punktlichter sehen dadurch weicher aus
	plane.subdivide_depth = 12
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.19, 0.18)
	ground.material_override = mat
	add_child(ground)
	# Schachbrett-Flecken, damit man Bewegung sieht
	var spot_mat := StandardMaterial3D.new()
	spot_mat.albedo_color = Color(0.16, 0.15, 0.15)
	for x in range(-3, 3):
		for z in range(-3, 3):
			if (x + z) % 2 == 0:
				var spot := MeshInstance3D.new()
				var pm := PlaneMesh.new()
				pm.size = Vector2(10, 10)
				spot.mesh = pm
				spot.material_override = spot_mat
				spot.position = Vector3(x * 10 + 5, 0.01, z * 10 + 5)
				add_child(spot)


func _make_border() -> void:
	for side in 4:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(HALF_SIZE * 2 + 2, 4, 1)
		shape.shape = box
		body.add_child(shape)
		body.rotation.y = side * PI / 2.0
		body.position = Vector3(0, 2, HALF_SIZE + 0.5).rotated(Vector3.UP, side * PI / 2.0)
		add_child(body)


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
	# ein schräger Ast
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


func _near_dummy(p: Vector3) -> bool:
	for c in get_children():
		if c.is_in_group("enemies") and c.position.distance_to(p) < 3.0:
			return true
	return false
