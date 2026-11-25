## Hauptszene: verbindet die Teile des Spiels miteinander.
extends Node3D

@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	player.dashed.connect(func(): DebugOverlay.watch("Letzter Dash", "%.1fs" % (Time.get_ticks_msec() / 1000.0)))


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("potion"):
		DebugOverlay.note("Trank gedrückt (Funktion kommt in Etappe 4)")
