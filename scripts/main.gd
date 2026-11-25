## Hauptszene: verbindet die Teile des Spiels miteinander.
extends Node3D

@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	player.died.connect(_on_player_died)


func _on_player_died() -> void:
	# Die Zeitstrafe wirkt ab Etappe 6 auf die Festung (Holz/Nahrung).
	DebugOverlay.note("Hüter gefallen – %d s vergehen" % int(Config.death_time_loss))
