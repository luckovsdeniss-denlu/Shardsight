class_name Sfx
extends Node
## Tiny synthesized sound effects: no audio files, each sound is built from a formula at start-up.

const RATE := 22050
const VOICES := 12

var _streams := {}
var _variants := {}                  # sound -> several takes; one is picked at random each time
var _pending := {}                   # takes being built on a worker thread (installed when done)
## Until the takes are ready (a moment after start), these play the original single sounds.
const FALLBACK := {
	"mine": "gather", "chop": "gather", "splash": "gather", "crossbow": "bow", "parry": "hit", "hit_blade": "hit",
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
		p.bus = "SFX"
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
	var splash := []
	for d: float in [0.25, 0.32]:
		var lp := [0.0]
		splash.append(_make(d, func(t: float) -> float:
			lp[0] = float(lp[0]) * 0.75 + randf_range(-1.0, 1.0) * 0.25
			return float(lp[0]) * 3.0 * exp(-t * 12.0) * (0.6 + 0.4 * sin(TAU * 9.0 * t))))
	_pending["splash"] = splash
	_build_ambience()


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


## Sounds of the world: footsteps on grass and on stone, birdsong, and three loops (crickets at
## night, running water, a crackling fire) that the game fades in and out by place and time.
func _build_ambience() -> void:
	var grass_steps := []
	for f: float in [0.55, 0.65, 0.75]:
		var lp := [0.0]
		grass_steps.append(_make(0.09, func(t: float) -> float:
			lp[0] = float(lp[0]) * f + randf_range(-1.0, 1.0) * (1.0 - f)
			return float(lp[0]) * 2.5 * exp(-t * 45.0)))
	_pending["step_grass"] = grass_steps
	var stone_steps := []
	for f: float in [900.0, 1200.0, 1500.0]:
		stone_steps.append(_make(0.07, func(t: float) -> float:
			return (randf_range(-1.0, 1.0) * 0.6 + sin(TAU * f * t) * 0.4) * exp(-t * 70.0)))
	_pending["step_stone"] = stone_steps
	var birds := []
	for k: Array in [[2600.0, 900.0, 3], [3200.0, -700.0, 4], [2200.0, 1400.0, 2]]:
		var base: float = k[0]
		var sweep: float = k[1]
		var notes: int = k[2]
		var note_len := 0.09
		birds.append(_make(note_len * notes + 0.08, func(t: float) -> float:
			var i := mini(int(t / note_len), notes - 1)
			var lt := t - i * note_len
			if lt > note_len * 0.8:
				return 0.0
			var f := base + sweep * (lt / note_len) + 150.0 * i
			return sin(TAU * f * lt) * sin(PI * lt / (note_len * 0.8)) * 0.35))
	_pending["bird"] = birds
	var crickets := _make(2.0, func(t: float) -> float:
		var pulse := fmod(t, 0.5)
		var on := 1.0 if pulse < 0.12 and fmod(pulse, 0.03) < 0.018 else 0.0
		return sin(TAU * 4400.0 * t) * on * 0.25)
	crickets.loop_mode = AudioStreamWAV.LOOP_FORWARD
	crickets.loop_end = int(2.0 * RATE)
	_pending["crickets"] = [crickets]
	var wlp := [0.0]
	var water := _make(2.0, func(t: float) -> float:
		wlp[0] = float(wlp[0]) * 0.92 + randf_range(-1.0, 1.0) * 0.08
		return float(wlp[0]) * 4.0 * (0.75 + 0.25 * sin(TAU * 1.5 * t) * sin(TAU * 0.5 * t)))
	water.loop_mode = AudioStreamWAV.LOOP_FORWARD
	water.loop_end = int(2.0 * RATE)
	_pending["water"] = [water]
	var flp := [0.0]
	var fire := _make(2.0, func(t: float) -> float:
		flp[0] = float(flp[0]) * 0.96 + randf_range(-1.0, 1.0) * 0.04
		var pop := randf_range(-1.0, 1.0) * 0.8 if randf() < 0.0015 else 0.0     # a crackle now and then
		return float(flp[0]) * 5.0 + pop)
	fire.loop_mode = AudioStreamWAV.LOOP_FORWARD
	fire.loop_end = int(2.0 * RATE)
	_pending["fire"] = [fire]
	_build_wider_world()
	_build_flourishes()
	_build_trailer()


## The wider world's sounds: oars and waves, beasts' voices, the wind of the Frostmarch, the hum
## of the tavern, the arena's crowd.
func _build_wider_world() -> void:
	var oar := []
	for d: float in [0.35, 0.42]:
		var olp := [0.0]
		oar.append(_make(d, func(t: float) -> float:
			olp[0] = float(olp[0]) * 0.8 + randf_range(-1.0, 1.0) * 0.2
			return float(olp[0]) * 2.2 * sin(PI * t / d) * (0.6 + 0.4 * sin(TAU * 7.0 * t))))
	_pending["oar"] = oar
	var roar := []
	for f: float in [70.0, 85.0, 100.0]:
		var rlp := [0.0]
		roar.append(_make(0.9, func(t: float) -> float:
			rlp[0] = float(rlp[0]) * 0.9 + randf_range(-1.0, 1.0) * 0.1
			var env := sin(PI * minf(t / 0.9, 1.0))
			return (sin(TAU * (f + 20.0 * sin(TAU * 6.0 * t)) * t) * 0.6 + float(rlp[0]) * 3.0) * env))
	_pending["roar"] = roar
	var hiss := []
	for k: float in [0.5, 0.7]:
		hiss.append(_make(0.5, func(t: float) -> float:
			return randf_range(-1.0, 1.0) * sin(PI * t / 0.5) * k * (0.7 + 0.3 * sin(TAU * 30.0 * t))))
	_pending["hiss"] = hiss
	var rattle := []
	for f: float in [900.0, 1200.0]:
		rattle.append(_make(0.45, func(t: float) -> float:
			var click := 1.0 if fmod(t, 0.05) < 0.012 else 0.0
			return sin(TAU * f * t) * click * exp(-t * 3.0) * 0.6))
	_pending["rattle"] = rattle
	var cheer := []
	for d: float in [1.6, 2.0]:
		var clp := [0.0]
		cheer.append(_make(d, func(t: float) -> float:
			clp[0] = float(clp[0]) * 0.75 + randf_range(-1.0, 1.0) * 0.25
			return float(clp[0]) * 2.4 * sin(PI * t / d) * (0.8 + 0.2 * sin(TAU * 11.0 * t))))
	_pending["cheer"] = cheer
	# loops
	var wind_lp := [0.0]
	var wind := _make(4.0, func(t: float) -> float:
		wind_lp[0] = float(wind_lp[0]) * 0.985 + randf_range(-1.0, 1.0) * 0.015
		var gust := 0.55 + 0.45 * sin(TAU * 0.25 * t) * sin(TAU * 0.5 * t + 1.0)
		return float(wind_lp[0]) * 9.0 * gust)
	wind.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wind.loop_end = int(4.0 * RATE)
	_pending["wind"] = [wind]
	var chat_lp := [0.0]
	var notes := [196.0, 247.0, 294.0, 330.0, 294.0, 247.0, 220.0, 247.0]
	var tavern := _make(4.0, func(t: float) -> float:
		chat_lp[0] = float(chat_lp[0]) * 0.9 + randf_range(-1.0, 1.0) * 0.1
		var murmur := float(chat_lp[0]) * 2.5 * (0.6 + 0.4 * sin(TAU * 2.3 * t) * sin(TAU * 0.7 * t))
		var nt := fmod(t, 0.5)
		var f: float = notes[int(t / 0.5) % notes.size()]
		var lute := sin(TAU * f * nt) * exp(-nt * 7.0) * 0.35 + sin(TAU * f * 2.0 * nt) * exp(-nt * 9.0) * 0.12
		return murmur + lute)
	tavern.loop_mode = AudioStreamWAV.LOOP_FORWARD
	tavern.loop_end = int(4.0 * RATE)
	_pending["tavern"] = [tavern]
	var crowd_lp := [0.0]
	var crowd := _make(4.0, func(t: float) -> float:
		crowd_lp[0] = float(crowd_lp[0]) * 0.8 + randf_range(-1.0, 1.0) * 0.2
		return float(crowd_lp[0]) * 2.6 * (0.7 + 0.3 * sin(TAU * 0.5 * t)))
	crowd.loop_mode = AudioStreamWAV.LOOP_FORWARD
	crowd.loop_end = int(4.0 * RATE)
	_pending["crowd"] = [crowd]


## The richer effects: the roar of fire spells, the crack of lightning, the bright chime of a heal,
## the deep boom of explosions, a fanfare for a level, coins, a soft click for buttons, a potion's
## gulp, the whoosh of a missed blow.
func _build_flourishes() -> void:
	var fire := []
	for k: float in [0.9, 1.1]:
		var flp := [0.0]
		fire.append(_make(0.7, func(t: float) -> float:
			flp[0] = float(flp[0]) * 0.85 + randf_range(-1.0, 1.0) * 0.15
			var env := minf(t / 0.05, 1.0) * exp(-t * 3.5)
			return (float(flp[0]) * 3.2 + sin(TAU * (90.0 * k + 60.0 * t) * t) * 0.35) * env))
	_pending["spell_fire"] = fire
	var zap := []
	for f: float in [1800.0, 2400.0]:
		zap.append(_make(0.45, func(t: float) -> float:
			var crack := randf_range(-1.0, 1.0) * exp(-t * 18.0)
			var buzz := signf(sin(TAU * (f - 2600.0 * t) * t)) * exp(-t * 7.0) * 0.35
			return crack * 0.8 + buzz))
	_pending["spell_zap"] = zap
	var heal := []
	for base: float in [880.0, 990.0]:
		heal.append(_make(0.9, func(t: float) -> float:
			var v := 0.0
			for i in range(4):                          # an arpeggio rising, shimmering
				var lt := t - 0.08 * i
				if lt > 0.0:
					v += sin(TAU * base * pow(1.26, i) * lt) * exp(-lt * 4.0) * 0.22
			return v * (1.0 + 0.2 * sin(TAU * 7.0 * t))))
	_pending["spell_heal"] = heal
	var boom := []
	for d: float in [1.1, 1.4]:
		var blp := [0.0]
		boom.append(_make(d, func(t: float) -> float:
			blp[0] = float(blp[0]) * 0.97 + randf_range(-1.0, 1.0) * 0.03
			return (float(blp[0]) * 7.0 + sin(TAU * (60.0 - 25.0 * t) * t) * 0.7) * exp(-t * (4.0 / d))))
	_pending["spell_boom"] = boom
	var notes := [523.25, 659.25, 783.99, 1046.5]
	_pending["fanfare"] = [_make(1.3, func(t: float) -> float:
		var v := 0.0
		for i in range(notes.size()):
			var lt := t - 0.11 * i
			if lt > 0.0:
				var hold := 0.6 if i == notes.size() - 1 else 0.12
				var env := minf(lt / 0.01, 1.0) * (1.0 if lt < hold else exp(-(lt - hold) * 6.0))
				var f: float = notes[i]
				v += (sin(TAU * f * lt) + 0.3 * sin(TAU * 2.0 * f * lt) + 0.15 * sin(TAU * 3.0 * f * lt)) * env * 0.22
		return v)]
	var coins := []
	for n: int in [3, 4]:
		coins.append(_make(0.35, func(t: float) -> float:
			var v := 0.0
			for i in range(n):
				var lt := t - 0.06 * i
				if lt > 0.0:
					var f := 2400.0 + 450.0 * i
					v += (sin(TAU * f * lt) + 0.6 * sin(TAU * f * 2.76 * lt)) * exp(-lt * 30.0) * 0.25
			return v))
	_pending["coins"] = coins
	_pending["click"] = [_make(0.05, func(t: float) -> float:
		return sin(TAU * 1500.0 * t) * exp(-t * 120.0) * 0.5)]
	_pending["gulp"] = [_make(0.4, func(t: float) -> float:
		var g := fmod(t, 0.13)
		return sin(TAU * (240.0 + 300.0 * g) * g) * exp(-g * 25.0) * 0.6 * (1.0 if t < 0.39 else 0.0))]
	var whoosh := []
	for d: float in [0.18, 0.24]:
		var wlp := [0.0]
		whoosh.append(_make(d, func(t: float) -> float:
			wlp[0] = float(wlp[0]) * 0.7 + randf_range(-1.0, 1.0) * 0.3
			return float(wlp[0]) * 1.6 * sin(PI * t / d)))
	_pending["whoosh"] = whoosh
	_pending["heartbeat"] = [_make(1.0, func(t: float) -> float:
		var v := 0.0
		for o: float in [0.0, 0.22]:
			var lt := t - o
			if lt > 0.0:
				v += sin(TAU * 55.0 * lt) * exp(-lt * 22.0) * (0.9 if o == 0.0 else 0.6)
		return v)]


## Trailer sounds: a riser (noise sweeping up into a cut), a deep brass "braam" with a drum hit
## under it, and a short heavy impact.
func _build_trailer() -> void:
	var rlp := [0.0]
	_pending["riser"] = [_make(1.2, func(t: float) -> float:
		var k := t / 1.2
		rlp[0] = lerpf(float(rlp[0]), randf_range(-1.0, 1.0), 0.05 + 0.6 * k * k)   # the noise brightens as it rises
		var tone := sin(TAU * (200.0 + 900.0 * k * k) * t) * 0.25
		return (float(rlp[0]) * 1.4 + tone) * k * k)]
	var blp := [0.0]
	_pending["braam"] = [_make(2.4, func(t: float) -> float:
		var env := minf(t / 0.06, 1.0) * exp(-t * 1.1)
		var v := 0.0
		for k in range(1, 9):                                  # a low brass chord, buzzing
			v += sin(TAU * 55.0 * k * t + 0.3 * sin(TAU * 3.0 * t)) / k
			v += sin(TAU * 82.4 * k * t) / (k * 1.6)
		blp[0] = float(blp[0]) * 0.96 + randf_range(-1.0, 1.0) * 0.04
		var thump := sin(TAU * (40.0 + 80.0 * exp(-t * 20.0)) * t) * exp(-t * 5.0) * 1.2
		return clampf((v * 0.35 + float(blp[0]) * 3.0) * env * 1.6, -1.0, 1.0) + thump)]
	# the flying words: a swoop in from afar (a falling whistle over rushing air), a magical
	# shimmer as the word hangs (bell-like partials, glittering), and a rush past the ear
	var slp := [0.0]
	_pending["swoop"] = [_make(0.75, func(t: float) -> float:
		var k := t / 0.75
		slp[0] = lerpf(float(slp[0]), randf_range(-1.0, 1.0), 0.08 + 0.25 * sin(PI * k))
		var whistle := sin(TAU * (1500.0 * t - 700.0 * t * t)) * 0.18 * sin(PI * k)
		return (float(slp[0]) * 1.5 + whistle) * sin(PI * k) * (0.4 + 0.6 * k))]
	_pending["shimmer"] = [_make(1.3, func(t: float) -> float:
		var v := 0.0
		for f: float in [1046.5, 1318.5, 1568.0, 2093.0]:      # a high C major, ringing
			v += sin(TAU * f * t + 2.0 * sin(TAU * 6.0 * t)) * exp(-t * (2.0 + f / 1200.0))
		var sparkle := sin(TAU * 3136.0 * t) * exp(-fmod(t, 0.11) * 40.0) * exp(-t * 2.5) * 0.4
		return (v * 0.22 + sparkle) * minf(t / 0.01, 1.0))]
	# when a word lands: two cinematic hits instead of the plain shimmer. Gold: a deep boom under a
	# ringing metal "shing" (inharmonic, like struck steel), a burst of air and a falling sparkle.
	# Ice: a cracking crystal chime, high glassy partials with a shiver, over a soft low thud.
	var glp := [0.0]
	_pending["word_gold"] = [_make(1.6, func(t: float) -> float:
		var boom := sin(TAU * (34.0 + 40.0 * exp(-t * 12.0)) * t) * exp(-t * 3.2) * 0.9
		var shing := 0.0
		for p: Array in [[1180.0, 1.0], [1873.0, 0.7], [2611.0, 0.55], [3420.0, 0.4], [4475.0, 0.25]]:
			shing += sin(TAU * float(p[0]) * t * (1.0 + 0.002 * sin(TAU * 7.0 * t))) * float(p[1])
		shing *= exp(-t * 3.5) * 0.18
		glp[0] = float(glp[0]) * 0.8 + randf_range(-1.0, 1.0) * 0.2
		var air := float(glp[0]) * 1.2 * exp(-t * 14.0)
		var k := fmod(t, 0.075)
		var sp := sin(TAU * (3000.0 - t * 900.0) * t) * exp(-k * 60.0) * exp(-t * 2.2) * 0.18 * (1.0 if t > 0.15 else 0.0)
		return clampf(boom + shing + air + sp, -1.0, 1.0))]
	_pending["word_ice"] = [_make(1.5, func(t: float) -> float:
		var v := 0.0
		for p: Array in [[2093.0, 1.0, 3.0], [2637.0, 0.8, 3.6], [3520.0, 0.6, 4.4], [4186.0, 0.45, 5.0], [5274.0, 0.3, 6.0]]:
			v += sin(TAU * float(p[0]) * t + 1.5 * sin(TAU * 9.0 * t)) * float(p[1]) * exp(-t * float(p[2]))
		var crack := randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.6
		var thud := sin(TAU * (60.0 + 50.0 * exp(-t * 20.0)) * t) * exp(-t * 6.0) * 0.6
		var shiver := 0.6 + 0.4 * sin(TAU * 13.0 * t)
		return clampf(v * 0.16 * shiver + crack + thud, -1.0, 1.0))]
	# a word coming in: a reverse-cymbal swell (bright noise growing faster and faster) with a
	# tone sweeping up and a shimmer of fifths - cut off just as the word lands on its hit
	var ilo := [0.0]
	_pending["word_in"] = [_make(0.6, func(t: float) -> float:
		var k := t / 0.6
		var n := randf_range(-1.0, 1.0)
		var hp := n - float(ilo[0])                    # bright: the noise minus its low part
		ilo[0] = lerpf(float(ilo[0]), n, 0.3)
		var sweep := sin(TAU * (180.0 * t + 900.0 * t * t * 1.6)) * 0.35
		var fifth := sin(TAU * (270.0 * t + 1350.0 * t * t * 1.6)) * 0.2
		var env := k * k * k * (1.0 if k < 0.97 else (1.0 - k) / 0.03)
		return clampf((hp * 0.9 + sweep + fifth) * env * 1.3, -1.0, 1.0))]
	# a word leaving: a jet fly-by - a hum that drops in pitch as it passes (the Doppler fall), air
	# swelling then fading behind it, and a trail of tinkling sparks
	var olp := [0.0]
	_pending["word_out"] = [_make(0.9, func(t: float) -> float:
		var k := t / 0.9
		var f := 860.0 - 540.0 * smoothstep(0.25, 0.6, k)           # the pitch falls as it goes by
		var hum := (sin(TAU * f * t) + 0.5 * sin(TAU * f * 1.5 * t)) * 0.18
		olp[0] = lerpf(float(olp[0]), randf_range(-1.0, 1.0), 0.25 + 0.4 * (1.0 - k))
		var air := float(olp[0]) * 1.4
		var env := pow(sin(PI * minf(k * 1.4, 1.0)), 2.0) * (1.0 - k * 0.6)
		var tk := fmod(t, 0.06)
		var sparks := sin(TAU * (4200.0 - 2000.0 * k) * t) * exp(-tk * 70.0) * 0.12 * (1.0 - k)
		return clampf((hum + air) * env + sparks, -1.0, 1.0))]
	var plp := [0.0]
	_pending["rush"] = [_make(0.5, func(t: float) -> float:
		var k := t / 0.5
		plp[0] = lerpf(float(plp[0]), randf_range(-1.0, 1.0), 0.15 + 0.6 * k)   # brightening as it passes
		return float(plp[0]) * 1.8 * pow(sin(PI * k), 2.0) * (1.2 - k * 0.5))]
	# moments: a level gained (a quick rising arpeggio and sparkle), an achievement (a brass
	# chord swelling up), a quest done (two bright chords), the church bell (deep bronze, with
	# its hum), and the dead rising (a ghostly wail sliding down over wind)
	_pending["levelup"] = [_make(1.1, func(t: float) -> float:
		var v := 0.0
		var notes := [523.25, 659.25, 783.99, 1046.5, 1318.5]
		for k in range(notes.size()):
			var lt := t - k * 0.07
			if lt > 0.0:
				v += sin(TAU * float(notes[k]) * lt) * exp(-lt * 4.0) * (0.3 + 0.1 * k / 4.0)
		var sp := sin(TAU * 2637.0 * t) * exp(-fmod(t, 0.09) * 50.0) * exp(-t * 3.0) * 0.25
		return v * 0.6 + sp)]
	_pending["achieve"] = [_make(1.6, func(t: float) -> float:
		var env := minf(t / 0.12, 1.0) * exp(-t * 1.6)
		var v := 0.0
		for f: float in [261.63, 329.63, 392.0, 523.25]:
			for h in range(1, 5):                              # brassy: rich in partials
				v += sin(TAU * f * h * t + 0.2 * sin(TAU * 5.0 * t)) / (h * 1.3)
		var snare := randf_range(-1.0, 1.0) * exp(-t * 18.0) * 0.4
		return clampf(v * 0.12 * env + snare, -1.0, 1.0))]
	_pending["quest"] = [_make(1.0, func(t: float) -> float:
		var chord: Array = [392.0, 493.88, 587.33] if t < 0.22 else [523.25, 659.25, 783.99]
		var lt := t if t < 0.22 else t - 0.22
		var v := 0.0
		for f in chord:
			v += sin(TAU * float(f) * lt) + 0.3 * sin(TAU * float(f) * 2.0 * lt)
		return v * 0.16 * exp(-lt * (6.0 if t < 0.22 else 2.6)))]
	_pending["toll"] = [_make(3.2, func(t: float) -> float:
		var v := 0.0
		for p: Array in [[110.0, 1.0, 0.5], [220.0, 0.7, 0.9], [264.0, 0.5, 1.4], [330.0, 0.35, 1.8], [440.0, 0.3, 2.4], [587.0, 0.2, 3.2]]:
			v += sin(TAU * float(p[0]) * t) * float(p[1]) * exp(-t * float(p[2]))
		return v * 0.35 * minf(t / 0.004, 1.0))]
	var wlp2 := [0.0]
	_pending["wail"] = [_make(2.2, func(t: float) -> float:
		var k := t / 2.2
		wlp2[0] = float(wlp2[0]) * 0.97 + randf_range(-1.0, 1.0) * 0.03
		var f := 620.0 - 260.0 * k + 18.0 * sin(TAU * 5.5 * t)       # a slide down, trembling
		var voice := (sin(TAU * f * t) + 0.4 * sin(TAU * f * 1.5 * t)) * sin(PI * k) * 0.25
		return voice + float(wlp2[0]) * 5.0 * sin(PI * k))]
	var ilp := [0.0]
	_pending["impact"] = [_make(0.9, func(t: float) -> float:
		ilp[0] = float(ilp[0]) * 0.9 + randf_range(-1.0, 1.0) * 0.1
		return (sin(TAU * (35.0 + 120.0 * exp(-t * 30.0)) * t) * 1.1 + float(ilp[0]) * 4.0) * exp(-t * 5.5))]
	# The Shardveil's guns (the "Shardveil chaos" experiment), two or three takes each:
	# the shotgun: a crack, a heavy thump and a roar of shot, then the pump racked for the next
	var shotgun := []
	for low: float in [95.0, 80.0]:
		var slp := [0.0]
		shotgun.append(_make(0.5, func(t: float) -> float:
			slp[0] = float(slp[0]) * 0.6 + randf_range(-1.0, 1.0) * 0.4
			var crack := randf_range(-1.0, 1.0) * exp(-t * 40.0)
			var roar := float(slp[0]) * 2.2 * exp(-t * 9.0)
			var thump := sin(TAU * (low - 60.0 * t) * t) * exp(-t * 14.0) * 0.9
			var pump := randf_range(-1.0, 1.0) * exp(-(t - 0.33) * 120.0) * 0.35 if t > 0.33 else 0.0
			return crack * 0.9 + roar + thump + pump))
	_pending["gun_shotgun"] = shotgun
	# the rocket launcher: a pop, then the rocket's rushing roar and a rising hum as it goes
	var rocket := []
	for rise: float in [220.0, 300.0]:
		var rlp := [0.0]
		rocket.append(_make(0.7, func(t: float) -> float:
			var k := 0.25 + 0.6 * minf(t / 0.15, 1.0)          # (the roar opens up as it lights)
			rlp[0] = float(rlp[0]) * (1.0 - k) + randf_range(-1.0, 1.0) * k
			var rush := float(rlp[0]) * minf(t / 0.03, 1.0) * exp(-t * 3.5) * 0.9
			var pop := randf_range(-1.0, 1.0) * exp(-t * 60.0) * 0.7
			var hum := sin(TAU * (140.0 + rise * t) * t) * exp(-t * 4.0) * 0.25
			return rush + pop + hum))
	_pending["gun_rocket"] = rocket
	# the spike gun: a sharp metal thwip
	var spike := []
	for f: float in [1300.0, 1600.0, 1900.0]:
		spike.append(_make(0.13, func(t: float) -> float:
			return (sin(TAU * f * t) * 0.5 + sin(TAU * f * 2.7 * t) * 0.25) * exp(-t * 45.0) \
				+ randf_range(-1.0, 1.0) * exp(-t * 120.0) * 0.6))
	_pending["gun_spike"] = spike
	# the arc caster: a buzzing, crackling zap
	var arc := []
	for f: float in [220.0, 260.0]:
		arc.append(_make(0.35, func(t: float) -> float:
			var buzz := signf(sin(TAU * (f + 900.0 * sin(TAU * 31.0 * t)) * t)) * exp(-t * 9.0) * 0.4
			var crackle := (randf_range(-1.0, 1.0) if randf() < 0.35 else 0.0) * exp(-t * 10.0) * 0.6
			return buzz + crackle))
	_pending["gun_arc"] = arc
	# the ember launcher: a hollow thoomp
	var ember := []
	for f: float in [160.0, 130.0]:
		ember.append(_make(0.4, func(t: float) -> float:
			var thoomp := sin(TAU * (f - 220.0 * t) * t) * exp(-t * 12.0)
			var pop := randf_range(-1.0, 1.0) * exp(-t * 70.0) * 0.5
			return thoomp * 0.9 + pop))
	_pending["gun_ember"] = ember
	# a blast (a rocket or an ember going off): a deep boom, a rumble and a crackle of debris
	var blast := []
	for low: float in [60.0, 48.0]:
		var blp := [0.0]
		blast.append(_make(0.9, func(t: float) -> float:
			blp[0] = float(blp[0]) * 0.85 + randf_range(-1.0, 1.0) * 0.15
			var boom := sin(TAU * (low + 90.0 * exp(-t * 25.0)) * t) * exp(-t * 6.0) * 0.9
			var rumble := float(blp[0]) * 3.2 * exp(-t * 4.0)
			var crackle := (randf_range(-1.0, 1.0) if randf() < 0.15 else 0.0) * exp(-t * 6.0) * 0.5
			return boom + rumble + crackle))
	_pending["blast"] = blast


## A looping ambience ("crickets", "water", "fire") once built, else null.
func loop_stream(sound_name: String) -> AudioStreamWAV:
	if _variants.has(sound_name):
		return (_variants[sound_name] as Array)[0]
	return null


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
