## ZENTRALE SPIELWERTE – alle Zahlen zum Einstellen stehen hier.
## Wird als "Autoload" geladen und ist überall als `Config.<name>` erreichbar.
## Einheiten: Meter (m), Sekunden (s).
extends Node

# --- Hüter -----------------------------------------------------------------
var player_max_health := 100.0
var player_speed := 6.0            # m/s Laufgeschwindigkeit
var dash_speed := 20.0             # m/s während des Dashs
var dash_duration := 0.18          # s
var dash_cooldown := 0.6           # s bis zum nächsten Dash
var potions_start := 3
var potion_heal := 40.0
var carry_capacity := 15           # Trage: Einheiten
var death_time_loss := 60.0        # s, die beim Tod vergehen

# --- Laterne ---------------------------------------------------------------
var lantern_burn_time := 180.0     # s volle Brenndauer
var lantern_radius_max := 8.0      # m
var lantern_radius_min := 2.0      # m
var dark_damage_bonus := 0.5       # +50 % Gegnerschaden außerhalb des Lichts

# --- Feuer & Festung -------------------------------------------------------
var fire_wood_start := 20
var fire_seconds_per_wood := 20.0
var food_start := 15
var food_seconds_per_person := 60.0
var residents_start := 5
var scrapyard_seconds_per_wood := 45.0   # Trümmerhof
var mushroom_seconds_per_food := 40.0    # Pilzkeller

# --- Belagerung ------------------------------------------------------------
var siege_interval := 480.0        # s (8 min)
var siege_warning := 30.0          # s Vorzeichen
var gate_health := 200.0

# --- Skills (Cast-Zeiten in s) --------------------------------------------
var cast_sickle := 0.8
var cast_bow := 0.6
var cast_ember := 0.5
var cast_bell := 1.6
var cast_modifier := 0.2

# --- Gegner-Leben ----------------------------------------------------------
var hp_crawler := 10.0
var hp_lighteater := 20.0
var hp_lost := 80.0
var hp_boss := 800.0

# --- Kamera ----------------------------------------------------------------
var camera_size := 18.0            # wie viele Meter senkrecht ins Bild passen
var camera_follow := 8.0           # wie schnell die Kamera folgt

# --- Touch-Steuerung -------------------------------------------------------
var joystick_radius := 110.0       # Pixel (bezogen auf 1280×720)
var button_radius := 80.0


func _ready() -> void:
	_setup_input()


## Tastenbelegung: WASD/Pfeile bewegen, Leertaste Dash, Q Trank.
func _setup_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("dash", [KEY_SPACE])
	_bind("potion", [KEY_Q])


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
