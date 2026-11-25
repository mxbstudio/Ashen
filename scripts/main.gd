## Hauptszene: verbindet die Teile des Spiels miteinander.
extends Node3D

const BossScript := preload("res://scripts/enemies/boss.gd")

@onready var player: CharacterBody3D = $Player
@onready var fortress: Node3D = $Fortress
@onready var siege: Node = $Siege
@onready var game_over: Control = $UI/GameOver


func _ready() -> void:
	player.died.connect(_on_player_died)
	fortress.fire_out.connect(_on_fire_out)
	siege.siege_ended.connect(_on_siege_ended)
	_spawn_boss()


func _spawn_boss() -> void:
	var boss: EnemyBase = BossScript.new()
	boss.player = player
	$Enemies.add_child(boss)
	boss.global_position = Vector3(0, 0, -80)
	boss.home = boss.global_position
	boss.defeated.connect(_on_boss_defeated)


func _on_player_died() -> void:
	# Beim Tod vergeht Zeit: die Festung verbraucht weiter Holz und Nahrung,
	# und die nächste Belagerung rückt näher.
	fortress.advance(Config.death_time_loss)
	siege.advance(Config.death_time_loss)
	get_tree().call_group("hud", "toast", "%d Sekunden sind vergangen" % int(Config.death_time_loss))


func _on_boss_defeated() -> void:
	get_tree().call_group("hud", "toast", "Der Hauptmann ist gefallen …")
	get_tree().call_group("hud", "toast", "Die Dunkelheit sammelt sich zum letzten Sturm!")
	siege.boss_defeated()


func _on_siege_ended(held: bool, final: bool) -> void:
	if final and held:
		game_over.show_end("Das Feuer brennt weiter",
				"Der Hauptmann ist besiegt und das Tor hat gehalten.\nSieg!")
	elif final:
		get_tree().call_group("hud", "toast", "Das Tor ist gefallen – sie kommen wieder!")


func _on_fire_out() -> void:
	game_over.show_end("Das Feuer ist erloschen",
			"Die Dunkelheit hat die Festung verschluckt.\nDer Durchgang ist verloren.")
