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
var carry_capacity := 6            # Trage: Einheiten (v0.1: 15 – sammeln sollen jetzt die Bewohner)
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
var food_start := 25               # (v0.1: 15)
var food_seconds_per_person := 75.0 # (v0.1: 60)
var residents_start := 7          # (v0.1: 5)
var survivor_interval := 240.0     # s – so oft findet ein Überlebender das Licht (+1 Bewohner)
var residents_max := 12            # mehr Bewohner kommen nicht dazu
var survivor_min_food := 3         # nur wenn mindestens so viel Nahrung da ist
var scrapyard_seconds_per_wood := 45.0   # Trümmerhof
var mushroom_seconds_per_food := 30.0  # Pilzkeller (v0.1: 40)
var starve_seconds := 30.0         # ohne Nahrung stirbt alle 30 s ein Bewohner
var vital_reserve := 5            # Holz und Nahrung: darunter darf nichts verbraucht werden (nur Feuer und Essen)
var wood_cap := 30                 # so viel Holz passt ohne Vorratslager ins Lager
var food_cap := 25
var storehouse_bonus := 30         # Vorratslager: +30 auf beide Grenzen
var cost_storehouse := 5           # Baukosten in Holz
var cost_scrapyard := 8
var cost_mushroom := 8
var cost_tower := 10
var cost_workshop := 8             # Werkstatt (baut Bögen)
var cost_carts := 10               # Karrenschuppen: je Stufe ein Karren (v0.3)
var cart_capacity := 15            # so viel passt auf einen Karren
var cart_speed := 2.2              # m/s mit Karren (etwas langsamer als zu Fuß)
var cart_min_load := 4             # erst ab so viel Vorrat fährt ein Karren zu einem Lagerplatz
var depot_cap := 20                # so viel passt je Rohstoff auf einen Lagerplatz an der Fackel
var bow_craft_seconds := 60.0      # s pro Bogen und Bewohner in der Werkstatt
var bow_wood_cost := 4             # Holz pro Bogen
var resident_bow_damage := 5.0     # Bewohner mit Bogen: Schaden pro Pfeil
var resident_bow_interval := 1.8   # s zwischen zwei Schüssen
var resident_bow_range := 10.0     # m
var tower_range := 14.0            # m – Wachturm schießt auf Gegner in dieser Nähe
var tower_damage := 6.0
var tower_interval := 1.5          # s zwischen zwei Schüssen

# Gebäude-Stufen (v0.2): Stufe 2 und 3 kosten so viel Holz
var upgrade_cost_2 := 10
var upgrade_cost_3 := 16
var tower_damage_per_level := 0.5  # Wachturm: +50 % Schaden je Stufe
var tower_range_per_level := 3.0   # m mehr Reichweite je Stufe
var tower_interval_per_level := 0.8 # Schussabstand × 0,8 je Stufe (schneller)
var tower_climb_range := 5.0       # m mehr Reichweite, wenn der Hüter auf dem Turm steht
var tower_climb_range_per_level := 2.0  # m zusätzlich je Turmstufe über 1

# --- Sammeln ----------------------------------------------------------------
var gather_seconds := 1.2          # s pro Einheit, solange man neben der Fundstelle steht (v0.1: 0,6)
var gather_range := 2.0            # m
var tree_wood := 25                # Holz pro Baum – jeder Baum im Wald ist fällbar (v0.1: Holzhaufen mit 5)
var tree_regrow := 360.0           # s, bis aus dem Stumpf wieder ein Baum gewachsen ist
var rock_stone := 10               # Stein pro Felsen
var rock_regrow := 600.0           # s, bis ein abgebauter Felsen wieder da ist
var stone_cap := 40                # so viel Stein passt ins Lager (Vorratslager: +storehouse_bonus je Stufe)
var stone_start := 0
var food_per_node := 5            # Nahrung pro Pilzstelle (v0.1: 3)
var resource_regrow := 120.0       # s, bis eine leere Pilzstelle nachwächst (v0.1: 150)

# --- Belagerung ------------------------------------------------------------
var siege_interval := 480.0        # s (8 min)
var siege_warning := 30.0          # s Vorzeichen
var gate_health := 200.0
var siege_size := 18               # Gegner in der ersten Belagerung
var siege_growth := 6              # jede weitere Belagerung: so viele mehr
var final_siege_size := 30         # letzte Belagerung nach dem Boss
var siege_batch := 4               # so viele erscheinen auf einmal
var siege_batch_interval := 3.0    # s zwischen zwei Gruppen
var siege_retry_delay := 60.0      # s Pause, falls das Tor in der letzten Belagerung fällt
var gate_dps_crawler := 1.6        # Schaden pro Sekunde am Tor
var gate_dps_lighteater := 1.0
var gate_dps_lost := 5.0
var resident_defense_damage := 2.0 # Bewohner schießen von der Mauer (pro Pfeil)
var resident_defense_interval := 3.5 # s pro Bewohner-Schuss (geteilt durch Anzahl Bewohner)
var siege_player_engage := 3.0     # m – so nah muss der Hüter sein, damit Belagerer ihn angreifen

# --- Leuchtfeuer ------------------------------------------------------------
var beacon_light_radius := 7.0
var beacon_light_time := 1.5       # s daneben stehen zum Entzünden
var beacon_refill_range := 3.0

# --- Zonen & Fackelpfähle (v0.2) -------------------------------------------
var torch_build_cost := 4          # Holz zum Errichten (brennt danach mit voller Ladung)
var torch_max_wood := 4            # so viele Scheite passen hinein
var torch_seconds_per_wood := 90.0 # s Brenndauer pro Holz (voll = 4 × 90 s = 6 min)
var torch_light_radius := 8.0      # m – Lichtkreis der Zone, Kriecher meiden ihn
var torch_drain_lighteater := 5.0  # s Fackel-Brenndauer, die ein Lichtfresser pro Sekunde frisst (zuerst 8)
var torch_raid_interval := 90.0    # s – so oft schickt die Dunkelheit einen Lichtfresser zu einer Fackel (zuerst 45)
var small_torch_cost := 1          # Holz für eine kleine Fackel
var small_torch_seconds := 120.0   # s Brenndauer einer kleinen Fackel
var small_torch_radius := 4.5      # m Lichtkreis
var small_torch_max := 6           # höchstens so viele gleichzeitig (Leistung im Browser)
var firepit_stone_cost := 5        # Stein für eine Feuerstelle (dazu 1 Holz als erste Füllung)
var firepit_max_wood := 6          # so viele Scheite passen hinein
var firepit_seconds_per_wood := 90.0
var firepit_light_radius := 9.0    # m
var firepit_max := 4               # höchstens so viele (Leistung im Browser)
var firepit_refill_below := 0.35   # Bewohner bringen Holz, wenn weniger als 35 % drin sind
var smart_interval := 5.0          # s – so oft schauen freie Bewohner, was das Lager braucht
var smart_min_need := 0.15         # darunter (Lager fast voll) hilft niemand selbstständig
var smart_need_per_helper := 0.25  # jeder Helfer senkt den Bedarf etwas -> sie verteilen sich
var tend_below := 0.5              # Bewohner legen nebenbei nach, wenn eine Fackel/Feuerstelle unter 50 % ist
var tend_cooldown := 15.0          # s Pause, bevor derselbe Bewohner wieder nachlegt
var firepit_courier_wood := 3      # so viel Holz bringt ein Bewohner auf einmal
var torch_use_range := 2.6         # m – so nah muss der Hüter ran zum Errichten/Nachlegen

var gate_light_radius := 6.0       # m – Torfeuer: hält Kriecher vom Platz vor dem Tor fern

# --- Bewohner draußen (v0.2) ------------------------------------------------
var resident_hp := 40.0            # Leben eines Bewohners (heilt am Feuer; zuerst 25)
var resident_heal_per_second := 3.0
var worker_speed := 2.6            # m/s draußen (Holzfäller/Sammler)
var worker_carry := 3              # so viel bringt ein Bewohner pro Gang mit (zuerst 2)
var worker_gather_seconds := 4.0   # s pro Einheit an der Fundstelle
var resident_damage_factor := 0.5  # Gegner machen Bewohnern nur diesen Anteil ihres Schadens
var resident_hunt_range := 7.0     # m (zuerst 10) – so nah müssen Gegner sein, um einen Bewohner draußen anzugreifen

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
var bar_range_margin := 2.0        # m – die Leiste lädt schon, wenn ein Gegner so viel weiter weg ist als die größte Angriffs-Reichweite
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
var crawler_gaze_angle := 50.0     # Grad: so weit seitlich zählt noch als „angeschaut“ – dann weichen Kriecher zurück
var crawler_gaze_backoff := 3.0    # m so weit weichen angeschaute Kriecher zusätzlich zurück
var crawler_light_courage := 0.35  # Chance, trotzdem anzugreifen, wenn der Hüter im Licht einer Fackel/Feuerstelle steht
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

# --- Leiste mit Tiefe (v0.3) ----------------------------------------------------
var branch_level := 3              # beim Aufstieg auf diese Skill-Stufe wählt man eine Abzweigung
var stagger_time := 2.0            # s – Glockenschlag erschüttert (Gegner langsam, Sichel macht doppelt Schaden)
var stagger_slow := 0.35           # erschütterte Gegner laufen nur so schnell
var mark_time := 4.0               # s – markierte Gegner (Bogen „Markieren“) nehmen mehr Schaden
var mark_bonus := 0.35             # +35 % Schaden auf markierte Gegner
var combo_shatter := 2.0           # Sichel × erschüttert: Schaden ×2
var combo_kindle := 1.5            # Glocke × brennend: restlicher Brandschaden sofort ×1,5
var combo_flamearrow_radius := 2.2 # Bogen × brennend: Explosion (m)
var kindle_burn_dps := 3.0         # Zündschnur: Brand/s auf getroffene Gegner
var kindle_per_level := 1.0
var mirror_copy := 0.7             # Spiegel: kopierter Angriff macht 70 % Schaden
var mirror_per_level := 0.1
var oath_bonus := 0.25             # Schwur im letzten Feld: ganze nächste Runde +25 %
var oath_per_level := 0.05
var oath_next := 0.1               # Schwur anderswo: nur der nächste Angriff +10 %
var talisman_slots := 2            # so viele Talismane trägt der Hüter gleichzeitig
var lost_talisman_chance := 0.03   # Verlorene lassen selten einen Talisman fallen (zuerst 0,12)
var shrine_time := 1.5             # s neben einem Schrein stehen, um ihn zu öffnen

# --- Werkzeuge (v0.3) ------------------------------------------------------------
var tool_speed_per_level := 0.35   # jede Werkzeug-Stufe: Abbauen +35 % schneller (Hüter und Bewohner)
var tool_cost_wood := [6, 10, 16]  # Holz für Stufe 1 / 2 / 3
var tool_cost_stone := [4, 8, 14]  # Stein für Stufe 1 / 2 / 3

# --- Wahnsinn (v0.3) -----------------------------------------------------------
var madness_dark_rate := 0.15      # pro s draußen außerhalb fester Lichtquellen
var madness_low_lantern_rate := 0.35 # zusätzlich pro s, wenn die Laterne unter 30 % ist
var madness_empty_rate := 1.0      # zusätzlich pro s, wenn die Laterne leer ist
var madness_fire_recover := 0.3    # pro s am Feuer (langsam – Ruhe kostet Zeit)
var madness_death_relief := 25.0   # der Tod klärt den Geist etwas
var madness_damage_per_stage := 0.1 # +10 % Schaden je Wahn-Stufe (25 / 50 / 75)
var madness_dark_offer := 25.0     # ab so viel Wahnsinn bietet der Stufenaufstieg dunkle Skills an
var madness_full_drain := 2.0      # Leben pro s bei 100 Wahnsinn
var madness_event_threshold := 75.0 # ab so viel Wahnsinn („komplett wahnsinnig“) gibt es nur noch die Entscheidungen des Wahns
var cast_rift := 0.7               # Schattenriss
var rift_damage := 14.0
var rift_length := 7.0             # m Linie vor dem Hüter
var rift_madness := 0.6            # Wahnsinn pro Einsatz
var cast_scream := 1.2             # Leerenschrei
var scream_damage := 8.0
var scream_radius := 5.0
var scream_fear := 2.5             # s fliehen die Gegner
var scream_madness := 1.0
var pact_madness := 1.5            # Schattenpakt
# Licht-Skills (v0.3): arbeiten gegen den Wahn – je klarer der Geist, desto stärker
var cast_purge := 1.0              # Läuterung
var purge_damage := 8.0
var purge_radius := 4.0
var purge_madness := 1.5           # so viel Wahnsinn senkt ein Einsatz
var cast_lance := 0.9              # Lichtlanze
var lance_damage := 12.0
var lance_madness := 0.8
var vigil_madness := 3.0           # Andacht (Modifikator)

# --- Bewohner mit Eigenleben (v0.3) ----------------------------------------------
var mood_start := 60.0             # Stimmung 0–100
var mood_rate := 0.1               # so schnell (pro s) nähert sich die Stimmung ihrem Zielwert
var mood_on_death := 12.0          # stirbt jemand, sinkt die Stimmung aller
var grief_time := 240.0            # s Trauer des Verbundenen
var desert_mood := 15.0            # darunter kann ein Bewohner die Festung verlassen
var desert_chance := 0.25          # Chance pro Minute
var event_interval := 210.0        # s zwischen zwei Ereignissen (ungefähr)
var event_first := 150.0           # s bis zum ersten Ereignis

# --- Sicht (v0.3) -----------------------------------------------------------
var sight_enabled := true          # false = alle Gegner immer sichtbar (wie v0.2)
var sight_near := 3.5              # m – so nah sieht man einen Gegner auch im Dunkeln ganz
var sight_range := 24.0            # m – weiter weg sieht man nichts (auch keine Augen)

# --- Kamera ----------------------------------------------------------------
var camera_width := 14.0           # wie viele Meter waagerecht ins Bild passen (Hochformat)
var camera_follow := 0.0           # 0 = Kamera klebt direkt am Hüter; >0 = weiches Folgen

# --- Touch-Steuerung -------------------------------------------------------
var joystick_radius := 110.0       # Pixel (bezogen auf 720×1280)
var joystick_deadzone := 0.15      # so weit muss man schieben, bevor es losgeht
var joystick_analog := false       # false = sofort volle Geschwindigkeit
var button_radius := 80.0


# --- Speicherstand ------------------------------------------------------------
var autosave_interval := 20.0      # s zwischen zwei automatischen Speicherungen


const SETTINGS_PATH := "user://einstellungen.json"
var _defaults := {}                # Werte, auf die "Neu starten" zurücksetzt
var _originals := {}               # Werte genau wie in dieser Datei


func _ready() -> void:
	# Startwerte merken, damit ein Neustart alles zurücksetzen kann
	for prop in get_property_list():
		if prop["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and not prop["name"].begins_with("_"):
			_defaults[prop["name"]] = get(prop["name"])
			_originals[prop["name"]] = get(prop["name"])
	_setup_input()
	_load_settings()


## Im Werte-Menü verstellte Werte im Browser merken (bleiben auch nach dem Schließen erhalten).
func save_settings(extra := {}) -> void:
	var changed := extra.duplicate()
	for k in _originals:
		if get(k) != _originals[k]:
			changed[k] = get(k)
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(changed))
		f.close()


## Gemerkte Werte laden (beim Start). Gibt alle gelesenen Einträge zurück (z. B. "sfx" für die Lautstärke).
func _load_settings() -> Dictionary:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return {}
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	for k in d:
		if _originals.has(k):
			var old = _originals[k]
			set(k, int(d[k]) if typeof(old) == TYPE_INT else d[k])
			keep_as_default(k)
	return d


## Gemerkter Wert, der nicht in Config steht (z. B. Lautstärke).
func saved_setting(key: String, fallback):
	return _load_settings().get(key, fallback)


## Im Werte-Menü verstellter Wert soll auch nach "Neu starten" gelten.
func keep_as_default(key: String) -> void:
	_defaults[key] = get(key)


## Ursprünglicher Wert aus dieser Datei (für "Änderungen anzeigen").
func original(key: String):
	return _originals.get(key)


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
	_bind("bar_toggle", [KEY_E])


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.05)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
