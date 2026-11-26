## Sicht: Was sieht der Hüter von diesem Gegner? (hängt als Kind an jedem Gegner)
## - VOLL: freie Sicht vom Hüter UND der Gegner steht im Licht (oder ganz nah)
##         – oder er steht im Licht eines Feuers/einer Fackel/Feuerstelle (dort wachen die Bewohner)
## - AUGEN: freie Sicht, aber er steht im Dunkeln -> nur die glühenden Augen sind zu sehen
## - NICHTS: etwas ist im Weg (Baum, Fels, Mauer) oder er ist zu weit weg
## Geprüft wird nur ein paar Mal pro Sekunde (spart Leistung im Browser).
extends Node

enum Seen { NOTHING, EYES, FULL }

const CHECK_INTERVAL := 0.15

var seen := Seen.FULL
var _t := 0.0
@onready var enemy: Node3D = get_parent()


func _ready() -> void:
	_t = randf() * CHECK_INTERVAL   # nicht alle Gegner im selben Bild prüfen


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = CHECK_INTERVAL
	var now := _evaluate()
	if now != seen:
		seen = now
		_apply()
	elif seen != Seen.FULL:
		enemy._hp_bar.visible = false   # der Lebensbalken schaltet sich bei Treffern sonst wieder ein


func _evaluate() -> Seen:
	if not Config.sight_enabled:
		return Seen.FULL
	var pos: Vector3 = enemy.global_position
	if Lights.fixed_source_at(pos) != null:
		return Seen.FULL   # im Licht eines Feuers: immer sichtbar
	var player := enemy.player as Node3D
	if player == null or not is_instance_valid(player):
		return Seen.NOTHING
	var d := Vector2(pos.x - player.global_position.x, pos.z - player.global_position.z).length()
	if d > Config.sight_range:
		return Seen.NOTHING
	if not player.combat.has_line_of_sight(enemy):
		return Seen.NOTHING
	if d <= Config.sight_near or Lights.is_lit(pos):
		return Seen.FULL
	return Seen.EYES


## Körper bzw. nur die Augen zeigen.
func _apply() -> void:
	for c in enemy.model.get_children():
		if c is Node3D:
			c.visible = seen == Seen.FULL or (seen == Seen.EYES and enemy._eye_nodes.has(c))
	for e in enemy._eye_nodes:
		e.scale = Vector3.ONE * (2.2 if seen == Seen.EYES else 1.0)   # im Dunkeln größer, damit man sie am Handy erkennt
	if seen != Seen.FULL:
		enemy._hp_bar.visible = false
	else:
		enemy._hp_bar.set_fraction(enemy.hp / enemy.max_hp)
