## Lagerplatz an der Fackel einer Zone, am Leuchtfeuer oder an einer Feuerstelle (v0.3, Karren).
## Der Hüter kann dort seine Trage als Haufen abladen (Knopf „Abladen“, Taste G).
## Gibt es in der Festung Karren, legen Sammler, Holzfäller und Steinbrecher ihre volle Ladung hier ab
## und arbeiten gleich weiter. Karrenfahrer holen den Vorrat ab und bringen ihn zum Feuer.
## Sichtbar als kleine Stapel (Holz braun, Nahrung türkis, Stein grau) mit Schild.
extends Node3D

var zone_id := ""                  # Lagerplatz einer Zone (an der Fackel bzw. am Leuchtfeuer)
var host: Node3D = null            # … oder einer Feuerstelle (dann zone_id leer)
var stock := {"wood": 0, "food": 0, "stone": 0}
var claimed_by: Node3D = null      # Karrenfahrer, der gerade hierher unterwegs ist

var _label: Label3D
var _piles := {}


func _ready() -> void:
	add_to_group("depots")
	var cols := {"wood": Color(0.45, 0.3, 0.17), "food": Color(0.4, 0.8, 0.7), "stone": Color(0.55, 0.55, 0.6)}
	var x := -0.7
	for k in ["wood", "food", "stone"]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.6, 1.0, 0.6)
		m.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = cols[k]
		m.material_override = mat
		m.position = Vector3(x, 0, 0)
		m.visible = false
		add_child(m)
		_piles[k] = m
		x += 0.7
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.fixed_size = true
	_label.pixel_size = 0.0008
	_label.font_size = 26
	_label.outline_size = 8
	_label.modulate = Color(1, 0.9, 0.7, 0.85)
	_label.position.y = 1.6
	add_child(_label)
	update_visuals()


## Dürfen Karren hierher? Nur solange es dort hell ist.
func is_safe() -> bool:
	if host != null:
		return is_instance_valid(host) and host.is_burning()
	return Zones.is_lit(get_tree(), zone_id)


func total() -> int:
	return stock["wood"] + stock["food"] + stock["stone"]


## Platz für eine Art (jede Art hat ihren eigenen Stapel – Holz verstopft nicht den Platz für Nahrung).
func space(kind: String) -> int:
	return maxi(Config.depot_cap - stock[kind], 0)


## Ablegen (Bewohner). Gibt zurück, wie viel gepasst hat.
func put(kind: String, n: int) -> int:
	var m := mini(n, space(kind))
	stock[kind] += m
	update_visuals()
	return m


## Aufladen (Karren): bis zu n Einheiten, das Dringendste zuerst (order = Reihenfolge der Arten).
## limits: höchstens so viel je Art (was in der Festung noch Platz hat).
func take(n: int, order: Array, limits := {}) -> Dictionary:
	var out := {"wood": 0, "food": 0, "stone": 0}
	for k in order:
		var m := mini(mini(stock[k], n), limits.get(k, 9999))
		stock[k] -= m
		out[k] += m
		n -= m
	update_visuals()
	return out


func update_visuals() -> void:
	for k in _piles:
		var n: int = stock[k]
		_piles[k].visible = n > 0
		var h := clampf(0.15 + n * 0.04, 0.15, 1.2)
		_piles[k].scale = Vector3(1, h, 1)
		_piles[k].position.y = h / 2.0
	if total() == 0:
		_label.text = "Lagerplatz"
		_label.modulate.a = 0.45
	else:
		var parts := []
		for k in [["wood", "Holz"], ["food", "Nahrung"], ["stone", "Stein"]]:
			if stock[k[0]] > 0:
				parts.append("%d %s" % [stock[k[0]], k[1]])
		_label.text = "Lager: " + " · ".join(parts)
		_label.modulate.a = 0.9


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var d: float = player.global_position.distance_to(global_position)
		var show := d < 14.0
		if _label.visible != show:
			_label.visible = show
