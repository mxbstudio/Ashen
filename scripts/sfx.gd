## Einfache Platzhalter-Klänge (Autoload "Sfx"). Werden beim Start im Code erzeugt –
## keine Sounddateien, kein FMOD. Aufruf überall: Sfx.play("bell")
## Im Browser startet der Ton erst nach der ersten Berührung (Regel der Browser).
extends Node

const RATE := 22050
const VOICES := 10

var volume_db := -6.0
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last := {}                     # gegen zu viele gleiche Klänge auf einmal
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_streams["bell"] = _bell()
	_streams["omen"] = _rumble()
	_streams["hit"] = _noise_hit(0.07, 0.5)
	_streams["swing"] = _whoosh(0.16)
	_streams["shoot"] = _twang()
	_streams["hurt"] = _thump(0.18, 110.0, 0.9)
	_streams["slam"] = _thump(0.4, 60.0, 1.0)
	_streams["gate"] = _thump(0.12, 80.0, 0.5)
	_streams["pickup"] = _chirp(0.09, 600.0, 900.0)
	_streams["levelup"] = _arpeggio([523.0, 659.0, 784.0, 1047.0])
	_streams["death"] = _arpeggio([392.0, 330.0, 262.0, 196.0], 0.18)
	_streams["ignite"] = _whoosh(0.5)


## Klang abspielen. pitch_var = zufällige Tonhöhen-Schwankung (klingt natürlicher).
func play(name: String, volume := 0.0, pitch_var := 0.08) -> void:
	if not _streams.has(name):
		return
	var now := Time.get_ticks_msec()
	if now - _last.get(name, -1000) < 45:
		return
	_last[name] = now
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[name]
	p.volume_db = volume_db + volume
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


# --- Klang-Erzeugung ---------------------------------------------------------

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


## Glocke: mehrere Teiltöne, die langsam ausklingen.
func _bell() -> AudioStreamWAV:
	var n := int(RATE * 2.8)
	var s := PackedFloat32Array()
	s.resize(n)
	var partials := [[180.0, 1.0, 1.2], [360.0, 0.6, 1.8], [433.0, 0.45, 2.4], [540.0, 0.35, 3.0], [905.0, 0.2, 4.5]]
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for p in partials:
			v += sin(TAU * p[0] * t) * p[1] * exp(-t * p[2])
		s[i] = v * 0.35 * minf(t * 200.0, 1.0)
	return _wav(s)


## Tiefes Grollen (Vorzeichen).
func _rumble() -> AudioStreamWAV:
	var n := int(RATE * 2.2)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		lp += (randf_range(-1, 1) - lp) * 0.02   # stark gefiltertes Rauschen
		var env := sin(PI * t / 2.2)
		s[i] = (lp * 3.0 + sin(TAU * 45.0 * t) * 0.3) * env * 0.8
	return _wav(s)


func _noise_hit(dur: float, vol: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = randf_range(-1, 1) * exp(-t * 50.0) * vol
	return _wav(s)


func _whoosh(dur: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var cut := 0.05 + 0.25 * sin(PI * t / dur)
		lp += (randf_range(-1, 1) - lp) * cut
		s[i] = lp * sin(PI * t / dur) * 0.9
	return _wav(s)


func _twang() -> AudioStreamWAV:
	var n := int(RATE * 0.12)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = sin(TAU * (300.0 - t * 1200.0) * t) * exp(-t * 30.0) * 0.5
	return _wav(s)


func _thump(dur: float, freq: float, vol: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var f := freq * (1.0 - 0.5 * t / dur)
		s[i] = (sin(TAU * f * t) + randf_range(-0.3, 0.3)) * exp(-t * 8.0 / dur) * vol
	return _wav(s)


func _chirp(dur: float, f0: float, f1: float) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		ph += TAU * lerpf(f0, f1, t / dur) / RATE
		s[i] = sin(ph) * sin(PI * t / dur) * 0.35
	return _wav(s)


func _arpeggio(freqs: Array, step := 0.1) -> AudioStreamWAV:
	var n := int(RATE * (step * freqs.size() + 0.3))
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in freqs.size():
			var t0: float = k * step
			if t >= t0:
				v += sin(TAU * freqs[k] * (t - t0)) * exp(-(t - t0) * 6.0)
		s[i] = v * 0.25
	return _wav(s)
