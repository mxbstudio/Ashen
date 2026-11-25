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
var respawn_delay := 2.5           # s Todesbildschirm, bevor er am Feuer erscheint
var respawn_protection := 3.0      # s unverwundbar nach dem Wiedererscheinen
var fire_heal_per_second := 10.0   # am Feuer heilt der Hüter langsam
var potions_refill_at_fire := true # am Feuer werden die Tränke wieder aufgefüllt

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
var starve_seconds := 30.0         # ohne Nahrung stirbt alle 30 s ein Bewohner
var wood_cap := 30                 # so viel Holz passt ohne Vorratslager ins Lager
var food_cap := 25
var storehouse_bonus := 30         # Vorratslager: +30 auf beide Grenzen
var cost_storehouse := 5           # Baukosten in Holz
var cost_scrapyard := 8
var cost_mushroom := 8
var cost_tower := 10
var tower_range := 14.0            # m – Wachturm schießt auf Gegner in dieser Nähe
var tower_damage := 6.0
var tower_interval := 1.5          # s zwischen zwei Schüssen

# --- Sammeln ----------------------------------------------------------------
var gather_seconds := 0.6          # s pro Einheit, solange man neben der Fundstelle steht
var gather_range := 2.0            # m
var wood_per_node := 5
var food_per_node := 3
var resource_regrow := 150.0       # s, bis eine leere Fundstelle nachwächst

# --- Belagerung ------------------------------------------------------------
var siege_interval := 480.0        # s (8 min)
var siege_warning := 30.0          # s Vorzeichen
var gate_health := 200.0
var siege_size := 12               # Gegner in der ersten Belagerung
var siege_growth := 4              # jede weitere Belagerung: so viele mehr
var final_siege_size := 22         # letzte Belagerung nach dem Boss
var siege_batch := 4               # so viele erscheinen auf einmal
var siege_batch_interval := 3.0    # s zwischen zwei Gruppen
var siege_retry_delay := 60.0      # s Pause, falls das Tor in der letzten Belagerung fällt
var gate_dps_crawler := 0.8        # Schaden pro Sekunde am Tor
var gate_dps_lighteater := 0.5
var gate_dps_lost := 2.5
var resident_defense_damage := 3.0 # Bewohner schießen von der Mauer (pro Pfeil)
var resident_defense_interval := 2.5 # s pro Bewohner-Schuss (geteilt durch Anzahl Bewohner)
var siege_player_engage := 3.0     # m – so nah muss der Hüter sein, damit Belagerer ihn angreifen

# --- Leuchtfeuer ------------------------------------------------------------
var beacon_light_radius := 7.0
var beacon_light_time := 1.5       # s daneben stehen zum Entzünden
var beacon_refill_range := 3.0

# --- Boss -------------------------------------------------------------------
var boss_speed := 1.6
var boss_aggro_range := 15.0       # m – ab dieser Nähe greift er an
var boss_leash := 30.0             # m – entfernt man sich weiter, kehrt er zurück und heilt
var boss_melee_damage := 20.0
var boss_melee_reach := 3.0
var boss_melee_windup := 0.8
var boss_area_damage := 30.0       # Flächenangriff
var boss_area_radius := 3.5
var boss_area_windup := 1.4        # s Vorwarnung (roter Kreis)
var boss_area_interval := 6.0      # s zwischen zwei Flächenangriffen
var xp_boss := 40

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
var ember_damage := 6.0            # Glutwurf: Aufprall
var ember_burn_dps := 4.0          # Glutwurf: Brandschaden pro Sekunde
var ember_burn_time := 3.0         # s
var ember_speed := 16.0            # m/s
var bell_damage := 10.0            # Glockenschlag
var bell_radius := 4.5             # m rund um den Hüter
var bell_knockback := 14.0         # Stärke des Zurückstoßens
var echo_cast_multiplier := 1.6    # Echo: Angriff dauert so viel länger
var mend_heal := 8.0               # Labung: Heilung pro Treffer
var sacrifice_multiplier := 2.5    # Opferlicht: Schaden ×2,5
var sacrifice_lantern_cost := 4.0  # Opferlicht: kostet so viele Sekunden Laternenlicht
var dummy_hp := 60.0               # Übungspuppen
var dummy_respawn := 3.0           # s

# --- Gegner ----------------------------------------------------------------
var hp_crawler := 10.0
var hp_lighteater := 20.0
var hp_lost := 80.0
var hp_boss := 800.0

# Kriecher: schnell, schwach, Schwarm; lauern am Rand des Lichts und springen hinein
var crawler_speed := 5.0
var crawler_damage := 5.0
var crawler_attack_pause := Vector2(1.5, 3.5)   # s zwischen zwei Angriffen (zufällig)
# Lichtfresser: saugen an der Laterne statt den Hüter zu verletzen
var lighteater_speed := 3.2
var lighteater_drain := 6.0        # s Laternenlicht pro Sekunde, solange er saugt
# Verlorener: langsam, groß, ignoriert das Licht, holt sichtbar aus
var lost_speed := 1.8
var lost_damage := 18.0
var lost_windup := 0.9             # s Vorwarnung vor dem Schlag
var lost_reach := 2.4              # m

# Gegner im Gelände
var max_enemies := 16              # mehr gleichzeitig nicht (Leistung im Browser)
var spawn_interval := 3.0          # s zwischen zwei Nachschüben
var spawn_min_distance := 14.0     # m – erscheinen nie näher am Hüter
var xp_crawler := 1
var xp_lighteater := 2
var xp_lost := 5

# --- Stufenaufstieg --------------------------------------------------------
var xp_first_level := 8            # EP für Stufe 2
var xp_level_step := 6             # jede weitere Stufe braucht so viel mehr
var max_skill_level := 5           # Skills können bis Stufe 5 verbessert werden
var extra_slot_levels := [6, 11]    # bei diesen Hüter-Stufen kommt ein weiteres Feld dazu

# Verbesserung pro Skill-Stufe (ab Stufe 2)
var skill_damage_per_level := 0.3  # Angriffe: +30 % Schaden je Stufe
var sickle_range_per_level := 0.3  # m
var bell_radius_per_level := 0.5   # m
var ember_burn_per_level := 1.5    # Brandschaden/s
var mend_heal_per_level := 4.0     # Labung
var echo_cast_per_level := 0.15    # Echo: Cast-Verlängerung sinkt je Stufe
var sacrifice_per_level := 0.5     # Opferlicht: +0,5 Multiplikator je Stufe

# --- Kamera ----------------------------------------------------------------
var camera_width := 14.0           # wie viele Meter waagerecht ins Bild passen (Hochformat)
var camera_follow := 0.0           # 0 = Kamera klebt direkt am Hüter; >0 = weiches Folgen

# --- Touch-Steuerung -------------------------------------------------------
var joystick_radius := 110.0       # Pixel (bezogen auf 720×1280)
var joystick_deadzone := 0.15      # so weit muss man schieben, bevor es losgeht
var joystick_analog := false       # false = sofort volle Geschwindigkeit
var button_radius := 80.0


var _defaults := {}


func _ready() -> void:
	# Startwerte merken, damit ein Neustart alles zurücksetzen kann
	for prop in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and not prop["name"].begins_with("_"):
			_defaults[prop["name"]] = get(prop["name"])
	_setup_input()


## Alle Werte auf die Startwerte zurücksetzen (z. B. nach Niederlage/Neustart).
func reset() -> void:
	for k in _defaults:
		set(k, _defaults[k])


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
