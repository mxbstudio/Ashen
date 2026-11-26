## Hilfen rund um die Zonen draußen: Ist eine Zone hell? Wie heißt sie? Sollen alle heimkommen?
class_name Zones
extends RefCounted


## Zone hell = ihr Fackelpfahl brennt (bzw. in der Leuchtfeuer-Zone: das Leuchtfeuer ist entzündet).
static func is_lit(tree: SceneTree, zone_id: String) -> bool:
	if zone_id == "beacon":
		var b := tree.get_first_node_in_group("beacon")
		return b != null and b.lit
	var t := torch_of(tree, zone_id)
	return t != null and t.is_burning()


static func torch_of(tree: SceneTree, zone_id: String) -> Node3D:
	for t in tree.get_nodes_in_group("torches"):
		if t.zone_id == zone_id:
			return t
	return null


## Mittelpunkt der Zone (Fackelplatz bzw. Leuchtfeuer).
static func center(tree: SceneTree, zone_id: String) -> Vector3:
	if zone_id == "beacon":
		var b := tree.get_first_node_in_group("beacon")
		return b.global_position if b else Vector3(0, 0, -50)
	var t := torch_of(tree, zone_id)
	return t.global_position if t else Vector3.ZERO


static func zone_name(zone_id: String) -> String:
	for z in ZoneDefs.ZONES:
		if z["id"] == zone_id:
			return z["name"]
	return zone_id


## Belagerung droht oder läuft -> alle Bewohner bleiben in der Festung.
static func recalled(tree: SceneTree) -> bool:
	var s := tree.get_first_node_in_group("siege")
	return s != null and (s.active or s.omen_active())


## Kurzer Text, wie viel Brennzeit die Zone noch hat (für das Einteilen-Menü).
static func status_text(tree: SceneTree, zone_id: String) -> String:
	if zone_id == "beacon":
		return "hell (Leuchtfeuer)" if is_lit(tree, zone_id) else "dunkel – Leuchtfeuer entzünden"
	var t := torch_of(tree, zone_id)
	if t == null or not t.built:
		return "dunkel – Fackelpfahl errichten"
	if not t.is_burning():
		return "dunkel – Fackel erloschen"
	var s := int(t.fuel)
	return "hell (Fackel %d:%02d)" % [s / 60, s % 60]
