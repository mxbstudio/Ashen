## Hauptszene: verbindet die Teile des Spiels miteinander.
extends Node3D

const BossScript := preload("res://scripts/enemies/boss.gd")
const DayNightScript := preload("res://scripts/day_night.gd")

@onready var player: CharacterBody3D = $Player
@onready var fortress: Node3D = $Fortress
@onready var siege: Node = $Siege
@onready var game_over: Control = $UI/GameOver

var boss_defeated := false         # für den Speicherstand


func _ready() -> void:
	player.died.connect(_on_player_died)
	fortress.fire_out.connect(_on_fire_out)
	siege.siege_ended.connect(_on_siege_ended)
	# Tag und Nacht: Licht der Welt folgt der Uhr der Festung
	var dn: Node = DayNightScript.new()
	dn.fortress = fortress
	dn.environment = $WorldEnvironment.environment
	dn.sky_light = $Moon
	add_child(dn)
	_spawn_boss()
	# kurzer Ziel-Hinweis beim Start
	get_tree().call_group("hud", "toast", "Halte das Feuer am Brennen.", 6.0)
	get_tree().call_group("hud", "toast", "Erhelle Zonen draußen, schicke Bewohner hin.", 6.0)
	get_tree().call_group("hud", "toast", "Überlebe %d Nächte." % Config.nights_to_win, 6.0)


func _spawn_boss() -> void:
	var boss: EnemyBase = BossScript.new()
	boss.player = player
	$Enemies.add_child(boss)
	boss.global_position = Vector3(0, 0, -80)
	boss.home = boss.global_position
	boss.defeated.connect(_on_boss_defeated)
	# Arena gut auffindbar machen: dunkelrotes Glühen und ein Schild am Eingang
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.8, 0.1, 0.08)
	glow.light_energy = 1.6
	glow.omni_range = 13.0
	glow.shadow_enabled = false
	glow.position = Vector3(0, 4, -80)
	add_child(glow)
	var sign := Label3D.new()
	sign.text = "Arena des Hauptmanns"
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.fixed_size = true
	sign.pixel_size = 0.001
	sign.font_size = 36
	sign.outline_size = 10
	sign.modulate = Color(1, 0.45, 0.35, 0.9)
	sign.position = Vector3(0, 3, -67)
	add_child(sign)


func _on_player_died() -> void:
	# Beim Tod vergeht Zeit: die Festung verbraucht weiter Holz und Nahrung,
	# und die nächste Belagerung rückt näher.
	fortress.advance(Config.death_time_loss)
	get_tree().call_group("torches", "advance", Config.death_time_loss)
	get_tree().call_group("hud", "toast", "%d Sekunden sind vergangen" % int(Config.death_time_loss))


func _on_boss_defeated() -> void:
	boss_defeated = true
	get_tree().call_group("hud", "toast", "Der Hauptmann ist gefallen …")
	get_tree().call_group("hud", "toast", "Der letzte Sturm wird schwächer sein.")


func _on_siege_ended(held: bool, final: bool) -> void:
	if held:
		fortress.mood_shock(10.0)   # gehalten: die Bewohner schöpfen Mut
	if final and held:
		game_over.show_end("Das Feuer brennt weiter",
				"%d Nächte überstanden – das Tor hat gehalten.\nSieg!" % Config.nights_to_win)
	elif final:
		get_tree().call_group("hud", "toast", "Das Tor ist gefallen – sie kommen nächste Nacht wieder!")


func _on_fire_out() -> void:
	game_over.show_end("Das Feuer ist erloschen",
			"Die Dunkelheit hat die Festung verschluckt.\nDer Durchgang ist verloren.")
