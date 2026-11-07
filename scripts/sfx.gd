class_name Sfx
extends Node
## Tiny synthesized sound effects: no audio files, each sound is built from a formula at start-up.

const RATE := 22050
const VOICES := 8

var _streams := {}
var _variants := {}                  # sound -> several takes; one is picked at random each time
var _pending := {}                   # takes being built on a worker thread (installed when done)
## Until the takes are ready (a moment after start), these play the original single sounds.
const FALLBACK := {
	"mine": "gather", "chop": "gather", "crossbow": "bow", "parry": "hit", "hit_blade": "hit",
	"hit_blunt": "hit", "hit_armor": "hit", "hit_bone": "hit", "hit_arrow": "hit", "hit_flesh": "hit",
}


func _build_variants() -> void:
	_build_hits()
	_build_others()
	call_deferred("_install_variants")


func _install_variants() -> void:
	_variants = _pending
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
	WorkerThreadPool.add_task(_build_variants)   # the many takes are built off the main thread
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


## Plays a sound: a random take if it has several, at a slightly random pitch so no two blows
## sound quite alike. `pitch` and `volume_db` shift it further (heavy blows: lower and louder).
func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	var stream: AudioStreamWAV = null
	if _variants.has(sound):
		var takes: Array = _variants[sound]
		stream = takes[randi() % takes.size()]
	elif _streams.has(sound):
		stream = _streams[sound]
	elif _streams.has(FALLBACK.get(sound, "")):
		stream = _streams[FALLBACK[sound]]
	else:
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = stream
	p.pitch_scale = pitch * randf_range(0.9, 1.12)
	p.volume_db = volume_db
	p.play()


## Several takes of every other sound too, so nothing repeats exactly: mining (a pick on stone)
## and chopping (an axe in wood), spell casting, deaths, loot, skill gains, bow and crossbow
## shots, and thunder.
func _build_others() -> void:
	var mine := []
	for f: float in [1700.0, 2100.0, 2500.0]:
		mine.append(_make(0.14, func(t: float) -> float:
			return (sin(TAU * f * t) + 0.5 * sin(TAU * f * 1.9 * t)) * exp(-t * 32.0) * 0.5 \
				+ randf_range(-1.0, 1.0) * exp(-t * 90.0) * 0.6))
	_pending["mine"] = mine
	var chop := []
	for f: float in [180.0, 220.0, 260.0]:
		var lp := [0.0]
		chop.append(_make(0.16, func(t: float) -> float:
			lp[0] = float(lp[0]) * 0.6 + randf_range(-1.0, 1.0) * 0.4
			return sin(TAU * f * t) * exp(-t * 26.0) * 0.7 + float(lp[0]) * exp(-t * 45.0) * 1.2))
	_pending["chop"] = chop
	_pending["gather"] = mine + chop
	var cast := []
	for k: Array in [[400.0, 700.0], [300.0, 900.0], [520.0, 500.0], [350.0, 1100.0]]:
		var base: float = k[0]
		var sweep: float = k[1]
		cast.append(_make(0.4, func(t: float) -> float:
			var shimmer := 1.0 + 0.3 * sin(TAU * 18.0 * t)
			return (sin(TAU * (base * t + sweep * t * t)) + 0.35 * sin(TAU * 2.01 * (base * t + sweep * t * t))) \
				* (1.0 - t / 0.4) * 0.55 * shimmer))
	_pending["cast"] = cast
	var death := []
	for k: Array in [[220.0, 120.0], [180.0, 90.0], [260.0, 160.0]]:
		var f0: float = k[0]
		var fall: float = k[1]
		death.append(_make(0.55, func(t: float) -> float:
			return (sin(TAU * (f0 * t - fall * t * t)) + randf_range(-0.15, 0.15)) * exp(-t * 4.5)))
	_pending["death"] = death
	var loot := []
	for notes: Array in [[880.0, 1320.0], [988.0, 1480.0], [784.0, 1175.0, 1568.0]]:
		var step := 0.07
		var dur := step * notes.size() + 0.08
		loot.append(_make(dur, func(t: float) -> float:
			var i := mini(int(t / step), notes.size() - 1)
			return sin(TAU * float(notes[i]) * t) * exp(-fmod(t, step) * 28.0) * 0.55))
	_pending["loot"] = loot
	var gain := []
	for notes: Array in [[660.0, 880.0, 1100.0], [587.0, 784.0, 988.0, 1175.0], [523.0, 659.0, 784.0, 1047.0]]:
		var step := 0.09
		gain.append(_make(step * notes.size() + 0.1, func(t: float) -> float:
			var i := mini(int(t / step), notes.size() - 1)
			return sin(TAU * float(notes[i]) * t) * exp(-fmod(t, step) * 18.0) * 0.45))
	_pending["gain"] = gain
	var bow := []
	for f: float in [160.0, 190.0, 220.0]:
		bow.append(_make(0.2, func(t: float) -> float:
			return sin(TAU * (f - 300.0 * t) * t) * exp(-t * 22.0) + randf_range(-1.0, 1.0) * exp(-t * 150.0) * 0.3))
	_pending["bow"] = bow
	var xbow := []
	for f: float in [120.0, 140.0]:
		xbow.append(_make(0.22, func(t: float) -> float:
			var snap := randf_range(-1.0, 1.0) * exp(-t * 110.0)        # the trigger's snap
			return snap + sin(TAU * (f - 200.0 * t) * t) * exp(-t * 18.0) * 0.9))
	_pending["crossbow"] = xbow
	var thunder := []
	for k: Array in [[1.4, 2.2, 3.0], [1.8, 1.7, 2.0], [1.2, 2.8, 4.5]]:
		var dur: float = k[0]
		var decay: float = k[1]
		var wobble: float = k[2]
		var rumble := [0.0]
		thunder.append(_make(dur, func(t: float) -> float:
			rumble[0] = float(rumble[0]) * 0.985 + randf_range(-1.0, 1.0) * 0.015
			return float(rumble[0]) * 9.0 * exp(-t * decay) * (1.0 + 0.5 * sin(TAU * wobble * t))))
	_pending["thunder"] = thunder


## Blows by kind, three or four takes each with their own tone:
## blade (a slash with a ring of steel), blunt (a heavy thud), armor (steel on plate or mail),
## bone (a dry clack), arrow (a thunk), flesh (fists, claws and bites), parry (a shield clang),
## and a few different whooshes for a miss.
func _build_hits() -> void:
	var blade := []
	for f: float in [1900.0, 2300.0, 2700.0, 3100.0]:
		var lp := [0.0]
		blade.append(_make(0.16, func(t: float) -> float:
			lp[0] = float(lp[0]) * 0.3 + randf_range(-1.0, 1.0) * 0.7
			return float(lp[0]) * exp(-t * 55.0) * 0.8 \
				+ (sin(TAU * f * t) + 0.5 * sin(TAU * f * 1.47 * t)) * exp(-t * 28.0) * 0.3))
	_pending["hit_blade"] = blade
	var blunt := []
	for f: float in [70.0, 85.0, 100.0]:
		var lp := [0.0]
		blunt.append(_make(0.2, func(t: float) -> float:
			lp[0] = float(lp[0]) * 0.85 + randf_range(-1.0, 1.0) * 0.15
			return sin(TAU * (f - 40.0 * t) * t) * exp(-t * 16.0) * 0.9 + float(lp[0]) * 4.0 * exp(-t * 30.0)))
	_pending["hit_blunt"] = blunt
	var armor := []
	for f: float in [900.0, 1150.0, 1400.0]:
		armor.append(_make(0.3, func(t: float) -> float:
			return (sin(TAU * f * t) + 0.6 * sin(TAU * f * 2.76 * t) + 0.3 * sin(TAU * f * 5.4 * t)) * exp(-t * 13.0) * 0.4 \
				+ randf_range(-1.0, 1.0) * exp(-t * 80.0) * 0.5))
	_pending["hit_armor"] = armor
	var bone := []
	for f: float in [1000.0, 1300.0, 1600.0]:
		bone.append(_make(0.12, func(t: float) -> float:
			var click := randf_range(-1.0, 1.0) * exp(-t * 90.0) + sin(TAU * f * t) * exp(-t * 60.0) * 0.6
			var t2 := maxf(t - 0.035, 0.0)                     # a second, softer clack
			return click + (sin(TAU * f * 1.2 * t2) * exp(-t2 * 70.0) * 0.4 if t > 0.035 else 0.0)))
	_pending["hit_bone"] = bone
	var arrow := []
	for f: float in [200.0, 240.0, 280.0]:
		arrow.append(_make(0.14, func(t: float) -> float:
			return sin(TAU * (f - 170.0 * t) * t) * exp(-t * 28.0) + randf_range(-1.0, 1.0) * exp(-t * 120.0) * 0.6))
	_pending["hit_arrow"] = arrow
	var flesh := []
	for f: float in [120.0, 150.0, 180.0]:
		var lp := [0.0]
		flesh.append(_make(0.11, func(t: float) -> float:
			lp[0] = float(lp[0]) * 0.7 + randf_range(-1.0, 1.0) * 0.3
			return float(lp[0]) * 2.2 * exp(-t * 38.0) + sin(TAU * f * t) * exp(-t * 30.0) * 0.5))
	_pending["hit_flesh"] = flesh
	var parry := []
	for f: float in [1500.0, 1800.0]:
		parry.append(_make(0.35, func(t: float) -> float:
			return (sin(TAU * f * t) + 0.7 * sin(TAU * f * 2.3 * t)) * exp(-t * 10.0) * 0.4 \
				+ randf_range(-1.0, 1.0) * exp(-t * 70.0) * 0.6))
	_pending["parry"] = parry
	var whoosh := []
	for d: float in [0.12, 0.15, 0.19]:
		var lp := [0.0]
		whoosh.append(_make(d, func(t: float) -> float:
			lp[0] = float(lp[0]) * 0.55 + randf_range(-1.0, 1.0) * 0.45
			return float(lp[0]) * sin(PI * t / d) * 0.6))
	_pending["swing"] = whoosh


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
