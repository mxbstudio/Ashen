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
var lantern_refill_seconds := 3.0  # s am Feuer von leer bis voll
var dark_damage_bonus := 0.5       # +50 % Gegnerschaden außerhalb des Lichts

# --- Feuer & Festung -------------------------------------------------------
var fire_wood_start := 20
var fire_seconds_per_wood := 20.0
var fire_light_radius := 10.0      # m Lichtkreis des Feuers
var fire_refill_range := 3.5       # m – so nah ran, um die Laterne aufzufüllen
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

# --- Skills (Wirkung) -----------------------------------------------------
var combat_range := 14.0           # m – nur wenn ein Gegner so nah ist, läuft die Leiste
var sickle_damage := 12.0
var sickle_range := 2.8            # m Reichweite des Bogens vor dem Hüter
var sickle_angle := 150.0          # Grad Öffnungswinkel
var bow_damage := 9.0
var bow_range := 14.0              # m
var arrow_speed := 24.0            # m/s
var echo_cast_multiplier := 1.6    # Echo: Angriff dauert so viel länger
var mend_heal := 8.0               # Labung: Heilung pro Treffer
var sacrifice_multiplier := 2.5    # Opferlicht: Schaden ×2,5
var sacrifice_lantern_cost := 15.0 # Opferlicht: kostet so viele Sekunden Laternenlicht
var dummy_hp := 60.0               # Übungspuppen
var dummy_respawn := 3.0           # s

# --- Gegner-Leben ----------------------------------------------------------
var hp_crawler := 10.0
var hp_lighteater := 20.0
var hp_lost := 80.0
var hp_boss := 800.0

# --- Kamera ----------------------------------------------------------------
var camera_width := 14.0           # wie viele Meter waagerecht ins Bild passen (Hochformat)
var camera_follow := 0.0           # 0 = Kamera klebt direkt am Hüter; >0 = weiches Folgen

# --- Touch-Steuerung -------------------------------------------------------
var joystick_radius := 110.0       # Pixel (bezogen auf 720×1280)
var joystick_deadzone := 0.15      # so weit muss man schieben, bevor es losgeht
var joystick_analog := false       # false = sofort volle Geschwindigkeit
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
		InputMap.add_action(action, 0.05)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
