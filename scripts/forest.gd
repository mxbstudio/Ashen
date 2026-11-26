## Der Wald: alle Bäume draußen sind fällbar.
## Für gute Leistung im Browser gibt es KEIN eigenes Objekt pro Baum: alle Stämme werden in einem Rutsch
## gezeichnet (MultiMesh), und hier stehen nur Listen (Ort, Holz, Nachwachs-Zeit).
## Gefällt -> der Stamm wird zum Stumpf gestaucht; nach Config.tree_regrow wächst er nach.
## Wie viel Holz ein Baum noch hat, steht nur über Bäumen, an denen gerade gehackt wird.
extends Node3D

const CELL := 4.0                  # Rastergröße für die schnelle "nächster Baum"-Suche
const LABEL_TIME := 3.0            # s, so lange bleibt die Holz-Anzeige nach dem letzten Hieb

var _pos := PackedVector3Array()
var _height := PackedFloat32Array()
var _yaw := PackedFloat32Array()
var _wood := PackedInt32Array()
var _regrow := PackedFloat32Array()
var _grid := {}                    # Vector2i -> Array[int]
var _stumps: Array[int] = []       # gefällte Bäume (warten aufs Nachwachsen)
var _labels := {}                  # Baum -> [Label3D, Restzeit]
var _trunks: MultiMesh
var _branches: MultiMesh
var _mat := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("forest")
	_mat.albedo_color = Color(0.22, 0.17, 0.13)


## Bäume anlegen (von world.gd aufgerufen). trees: [Position, Höhe, Drehung]
func setup(trees: Array) -> void:
	for t in trees:
		var i := _pos.size()
		_pos.append(t[0])
		_height.append(t[1])
		_yaw.append(t[2])
		_wood.append(Config.tree_wood)
		_regrow.append(0.0)
		var c := _cell(t[0])
		if not _grid.has(c):
			_grid[c] = []
		_grid[c].append(i)
		_collision(t[0])
	_build_multimesh()


func count() -> int:
	return _pos.size()


func tree_pos(i: int) -> Vector3:
	return _pos[i]


func has_wood(i: int) -> bool:
	return i >= 0 and i < _wood.size() and _wood[i] > 0


## Nächster Baum mit Holz im Umkreis (oder -1).
func nearest(at: Vector3, radius: float) -> int:
	var best := -1
	var best_d := radius
	var c := _cell(at)
	var r := int(ceil(radius / CELL))
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var key := Vector2i(c.x + dx, c.y + dz)
			if not _grid.has(key):
				continue
			for i in _grid[key]:
				if _wood[i] <= 0:
					continue
				var d := Vector2(_pos[i].x - at.x, _pos[i].z - at.z).length()
				if d < best_d:
					best_d = d
					best = i
	return best


## Ein Holz abhacken. Gibt true zurück, wenn es geklappt hat.
func take_one(i: int) -> bool:
	if not has_wood(i):
		return false
	_wood[i] -= 1
	_show_label(i)
	if _wood[i] <= 0:
		_regrow[i] = Config.tree_regrow
		_stumps.append(i)
		_set_visual(i)
	return true


func _process(delta: float) -> void:
	# Holz-Anzeigen ausblenden, wenn eine Weile nicht mehr gehackt wurde
	for i in _labels.keys():
		_labels[i][1] -= delta
		if _labels[i][1] <= 0.0:
			_labels[i][0].queue_free()
			_labels.erase(i)
	# Stümpfe wachsen nach
	for k in range(_stumps.size() - 1, -1, -1):
		var i: int = _stumps[k]
		_regrow[i] -= delta
		if _regrow[i] <= 0.0:
			_wood[i] = Config.tree_wood
			_stumps.remove_at(k)
			_set_visual(i)


func _show_label(i: int) -> void:
	var l: Label3D
	if _labels.has(i):
		l = _labels[i][0]
	else:
		l = Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.fixed_size = true
		l.pixel_size = 0.0008
		l.font_size = 30
		l.outline_size = 8
		l.modulate = Color(1, 0.85, 0.6, 0.9)
		add_child(l)
		l.global_position = _pos[i] + Vector3(0, minf(_height[i], 4.0) + 0.4, 0)
	l.text = "Baum: %d Holz" % _wood[i] if _wood[i] > 0 else "gefällt"
	_labels[i] = [l, LABEL_TIME]


func _cell(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.z / CELL))


func _trunk_transform(i: int) -> Transform3D:
	var p := _pos[i]
	if _wood[i] <= 0:
		# Stumpf: kurz und etwas breiter
		return Transform3D(Basis(Vector3.UP, _yaw[i]).scaled(Vector3(1.2, 0.14, 1.2)), p + Vector3(0, 0.2, 0))
	var b := Basis(Vector3.UP, _yaw[i]).scaled(Vector3(1, _height[i] / 3.0, 1))
	return Transform3D(b, p).translated_local(Vector3(0, 1.5, 0))


func _branch_transform(i: int) -> Transform3D:
	if _wood[i] <= 0:
		return Transform3D(Basis().scaled(Vector3.ONE * 0.001), _pos[i])   # unsichtbar
	var b := Basis(Vector3.UP, _yaw[i]).scaled(Vector3(1, _height[i] / 3.0, 1))
	return Transform3D(b, _pos[i]).translated_local(Vector3(0.3, 2.0, 0)).rotated_local(Vector3(0, 0, 1), -0.9)


func _set_visual(i: int) -> void:
	_trunks.set_instance_transform(i, _trunk_transform(i))
	_branches.set_instance_transform(i, _branch_transform(i))


## Alle Stämme und Äste zusammen zeichnen (spart viel Leistung im Browser).
func _build_multimesh() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.06
	trunk.bottom_radius = 0.3
	trunk.height = 3.0
	trunk.radial_segments = 5
	trunk.rings = 1
	trunk.material = _mat
	var branch := CylinderMesh.new()
	branch.top_radius = 0.03
	branch.bottom_radius = 0.1
	branch.height = 1.4
	branch.radial_segments = 4
	branch.rings = 1
	branch.material = _mat
	_trunks = _multimesh(trunk)
	_branches = _multimesh(branch)
	for i in _pos.size():
		_set_visual(i)


func _multimesh(mesh: Mesh) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = _pos.size()
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mm


func _collision(p: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = p
	var shape := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.35
	cs.height = 2.0
	shape.shape = cs
	shape.position.y = 1.0
	body.add_child(shape)
	add_child(body)
