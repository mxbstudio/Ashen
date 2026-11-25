## Hauptszene: verbindet die Teile des Spiels miteinander.
extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var fortress: Node3D = $Fortress
@onready var game_over: Control = $UI/GameOver


func _ready() -> void:
	player.died.connect(_on_player_died)
	fortress.fire_out.connect(_on_fire_out)


func _on_player_died() -> void:
	# Beim Tod vergeht Zeit: die Festung verbraucht weiter Holz und Nahrung.
	fortress.advance(Config.death_time_loss)
	get_tree().call_group("hud", "toast", "%d Sekunden sind vergangen" % int(Config.death_time_loss))


func _on_fire_out() -> void:
	game_over.show_end("Das Feuer ist erloschen",
			"Die Dunkelheit hat die Festung verschluckt.\nDer Durchgang ist verloren.")
