class_name Sfx
extends Node
## Tiny synthesized sound effects: no audio files, each sound is built from a formula at start-up.

const RATE := 22050
const VOICES := 8

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	_streams["hit"] = _make(0.09, func(t: float) -> float:
		return randf_range(-1.0, 1.0) * exp(-t * 45.0))
	_streams["gather"] = _make(0.12, func(t: float) -> float:
		return (sin(TAU * 260.0 * t) * 0.8 + randf_range(-0.3, 0.3)) * exp(-t * 35.0))
	_streams["cast"] = _make(0.35, func(t: float) -> float:
		return sin(TAU * (400.0 * t + 700.0 * t * t)) * (1.0 - t / 0.35) * 0.7)
	_streams["death"] = _make(0.5, func(t: float) -> float:
		return sin(TAU * (220.0 * t - 120.0 * t * t)) * exp(-t * 5.0))
	_streams["loot"] = _make(0.2, func(t: float) -> float:
		var f := 880.0 if t < 0.08 else 1320.0
		return sin(TAU * f * t) * exp(-fmod(t, 0.08) * 30.0) * 0.6)
	_streams["gain"] = _make(0.3, func(t: float) -> float:
		var f := 660.0 if t < 0.1 else (880.0 if t < 0.2 else 1100.0)
		return sin(TAU * f * t) * exp(-fmod(t, 0.1) * 20.0) * 0.5)
	_streams["swing"] = _make(0.14, func(t: float) -> float:
		return randf_range(-1.0, 1.0) * sin(PI * t / 0.14) * 0.45)
	_streams["bow"] = _make(0.18, func(t: float) -> float:
		return sin(TAU * (180.0 - 300.0 * t) * t) * exp(-t * 22.0))
	var rumble := [0.0]                  # filter state (an array, so the lambda can update it)
	_streams["thunder"] = _make(1.4, func(t: float) -> float:
		rumble[0] = float(rumble[0]) * 0.985 + randf_range(-1.0, 1.0) * 0.015      # low-passed noise
		return float(rumble[0]) * 9.0 * exp(-t * 2.2) * (1.0 + 0.5 * sin(TAU * 3.0 * t)))
	for i in range(VOICES):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String) -> void:
	if not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.play()


## Rain: two seconds of soft hiss that loops.
func make_rain() -> AudioStreamWAV:
	var hiss := [0.0]
	var s := _make(2.0, func(_t: float) -> float:
		hiss[0] = float(hiss[0]) * 0.6 + randf_range(-1.0, 1.0) * 0.4
		return float(hiss[0]) * 0.5)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = int(2.0 * RATE)
	return s


func _make(seconds: float, wave: Callable) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var v := clampf(float(wave.call(float(i) / RATE)), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32767.0 * 0.6))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s
