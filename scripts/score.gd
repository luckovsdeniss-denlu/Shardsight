class_name Score
extends Node
## The living score (the "Living score" experiment): new music that follows what happens on the
## screen, moment by moment, instead of one piece per place.
##
## Each place has its own new piece, written in code like the rest of the sound - but in five
## layers that play together, always in step, each turned up or down as the scene changes:
##   bed     - the chords (a pad, or a choir in holy and haunted places) and the bass: always there
##   pulse   - the motion (a plucked arpeggio, hand drums, or a soft tick): up as you walk, full as
##             you run or drive, down to a murmur when you stand still
##   theme   - the tune (a motif that grows through the chords): up while you explore in peace,
##             drawn back when danger comes, gone when you're a ghost
##   tension - a low pulsing ostinato, toms and a high dissonant shimmer: rising as foes close in
##             on you, and in the Shardveil's chaos
##   battle  - drums, brass stabs and a brass counter-line (and a choir for bosses): the fight
##   itself
## Moments land as short stingers in the piece's key, on the next half beat: a brass hit for each
## kill of yours, a swelling chord and bell through a rift, a falling bell line when you die. As a
## ghost the whole score slows and sinks (and the world's own muffling does the rest).

const STEMS := ["bed", "pulse", "theme", "tension", "battle"]
const BARS := 16
const KEEP := 5                                # pieces kept written (the rest are rewritten when wanted)
const VOLUME_DB := -12.0

const MODES := {
	"major": [0, 2, 4, 5, 7, 9, 11], "dorian": [0, 2, 3, 5, 7, 9, 10], "phrygian": [0, 1, 3, 5, 7, 8, 10],
	"lydian": [0, 2, 4, 6, 7, 9, 11], "mixolydian": [0, 2, 4, 5, 7, 9, 10], "aeolian": [0, 2, 3, 5, 7, 8, 10],
	"harmonic": [0, 2, 3, 5, 7, 8, 11],
}

## The pieces: key (the root, as a MIDI note) and mode, the beat (seconds), eight bars of chords as
## degrees of the scale (played twice, the tune changing the second time), the bed, the lead and
## the kind of pulse.
const SCENES := {
	"wilds": {"root": 55, "mode": "lydian", "beat": 0.52, "prog": [0, 1, 0, 4, 5, 3, 1, 4], "lead": "flute", "pulse": "arp"},
	"town": {"root": 53, "mode": "major", "beat": 0.45, "prog": [0, 3, 4, 5, 0, 3, 1, 4], "lead": "lute", "pulse": "hand"},
	"night": {"root": 57, "mode": "aeolian", "beat": 0.8, "prog": [0, 5, 3, 6, 0, 5, 2, 4], "lead": "bell", "pulse": "tick"},
	"dungeon": {"root": 52, "mode": "phrygian", "beat": 0.85, "prog": [0, 1, 0, 6, 0, 1, 4, 0], "lead": "bell", "pulse": "tick", "bed": "choir", "low": true},
	"cave": {"root": 49, "mode": "aeolian", "beat": 1.0, "prog": [0, 0, 5, 6, 0, 3, 5, 4], "lead": "bell", "pulse": "tick", "low": true},
	"frost": {"root": 59, "mode": "aeolian", "beat": 0.75, "prog": [0, 2, 6, 5, 0, 3, 4, 4], "lead": "bell", "pulse": "arp"},
	"desert": {"root": 52, "mode": "harmonic", "beat": 0.48, "prog": [0, 1, 0, 6, 5, 1, 6, 0], "lead": "lute", "pulse": "hand"},
	"swamp": {"root": 50, "mode": "phrygian", "beat": 0.7, "prog": [0, 0, 1, 0, 6, 5, 6, 0], "lead": "flute", "pulse": "tick", "low": true},
	"ash": {"root": 55, "mode": "harmonic", "beat": 0.55, "prog": [0, 5, 1, 4, 0, 6, 5, 4], "lead": "brass", "pulse": "hand", "low": true},
	"veil": {"root": 56, "mode": "lydian", "beat": 0.62, "prog": [0, 1, 0, 6, 2, 1, 5, 4], "lead": "flute", "pulse": "arp", "bed": "choir", "bells": true},
	"sea": {"root": 50, "mode": "mixolydian", "beat": 0.5, "prog": [0, 6, 3, 0, 4, 6, 3, 0], "lead": "flute", "pulse": "arp"},
	"church": {"root": 48, "mode": "major", "beat": 0.9, "prog": [0, 3, 5, 4, 0, 3, 1, 4], "lead": "choir", "pulse": "tick", "bed": "choir"},
	"cemetery": {"root": 54, "mode": "aeolian", "beat": 0.85, "prog": [0, 3, 0, 4, 5, 3, 6, 0], "lead": "bell", "pulse": "tick", "bed": "choir", "bells": true},
	"tavern": {"root": 57, "mode": "mixolydian", "beat": 0.3, "prog": [0, 6, 3, 0, 0, 6, 4, 0], "lead": "flute", "pulse": "hand"},
	"arena": {"root": 58, "mode": "major", "beat": 0.38, "prog": [0, 3, 4, 0, 5, 3, 4, 4], "lead": "brass", "pulse": "hand"},
}

var _banks: Array = []                         # two banks of players (a piece fades from one to the other)
var _bank := 0                                 # the one playing now
var _bank_scene := ["", ""]
var _fade := [0.0, 0.0]                        # each bank's level (0-1)
var _sting: AudioStreamPlayer
var _pieces := {}                              # scene -> {"stems": {stem: wav}, "stings": {...}, "beat": s}
var _order: Array = []                         # least recently wanted first
var _building := {}                            # scene -> task id
var _wanted := ""
var _levels := {}                              # stem -> its level now (0-1)
var _targets := {}
var _pitch := 1.0
var _running := false
var _last_pos := Vector3.ZERO
var _fight := 0.0                              # the fight, held a little after the last blow
var _boss := 0.0
var _state_t := 0.0


func _ready() -> void:
	for b in range(2):
		var bank := {}
		for s in STEMS:
			var p := AudioStreamPlayer.new()
			p.bus = "Music"
			p.volume_db = -80.0
			add_child(p)
			bank[s] = p
		_banks.append(bank)
	_sting = AudioStreamPlayer.new()
	_sting.bus = "Music"
	add_child(_sting)
	for s in STEMS:
		_levels[s] = 0.0
		_targets[s] = 0.0
	_levels["bed"] = 1.0


func _exit_tree() -> void:
	for id in _building.values():
		WorkerThreadPool.wait_for_task_completion(int(id))
	_building.clear()


## Every frame (from the game): `on` while the living score should play.
func tick(game, delta: float, on: bool) -> void:
	if not on:
		if _running:
			stop()
		return
	_running = true
	_state_t -= delta
	if _state_t <= 0.0:
		_state_t = 0.25
		_read_screen(game, 0.25)
	_mix(delta)


func stop() -> void:
	_running = false
	for bank in _banks:
		for s in STEMS:
			(bank[s] as AudioStreamPlayer).stop()
	_sting.stop()
	_bank_scene = ["", ""]
	_fade = [0.0, 0.0]


## What's on the screen, four times a second: where you are, how fast you go, who's after you,
## whether you're fighting (a boss?), dead, or in the Shardveil's chaos.
func _read_screen(game, dt: float) -> void:
	var hero: Entity = game.hero
	if hero == null:
		return
	var scene: String = game._place_piece(game.world.to_tile(hero.position))
	if not SCENES.has(scene):
		scene = "wilds"
	_want(scene)
	var moved := Vector2(hero.position.x - _last_pos.x, hero.position.z - _last_pos.z).length() / dt
	_last_pos = hero.position
	if moved > 40.0:
		moved = 0.0                            # (a jump across the map, not running)
	var move := clampf(moved / 3.5, 0.0, 1.0)
	var hunters := 0
	var boss := false
	for item in game.creatures:
		var e := item as Entity
		if e == null or e.dead or e.parked or e.kind == Entity.Kind.NPC or e == hero:
			continue
		if e.target == hero and e.position.distance_to(hero.position) < 16.0:
			hunters += 1
			if e.is_boss or e.danger >= 8.0:
				boss = true
	var foe := hero.target
	var fighting := foe != null and is_instance_valid(foe) and not foe.dead and foe.kind != Entity.Kind.NPC \
		and foe.position.distance_to(hero.position) < 12.0
	if fighting and (foe.is_boss or foe.danger >= 8.0):
		boss = true
	if fighting or (hunters > 0 and _fight > 0.5):
		_fight = 1.0
	else:
		_fight = maxf(_fight - dt / 6.0, 0.0)  # (the fight fades out over six seconds)
	_boss = 1.0 if boss and _fight > 0.0 else maxf(_boss - dt / 4.0, 0.0)
	var danger := clampf(hunters / 3.0, 0.0, 1.0)
	var chaos := 1.0 if game.dimension != null and game.dimension.chaos else 0.0
	var ghost := hero.dead
	var night: bool = game.is_night()
	_targets["bed"] = 1.0
	_targets["pulse"] = 0.0 if ghost else clampf(0.18 + 0.82 * move + 0.6 * _fight, 0.0, 1.0)
	_targets["theme"] = 0.0 if ghost else clampf((0.95 if not night else 0.75) - 0.7 * _fight - 0.35 * danger, 0.1, 1.0)
	_targets["tension"] = 0.0 if ghost else clampf(maxf(maxf(danger * 0.9, _fight * 0.65), chaos * 0.55) + _boss * 0.35, 0.0, 1.0)
	_targets["battle"] = 0.0 if ghost else clampf(_fight * (0.85 + 0.15 * danger) + _boss * 0.15, 0.0, 1.0)
	_pitch = 0.88 if ghost else 1.0


## The levels move toward where the screen says: a fight comes in at once, peace returns slowly.
func _mix(delta: float) -> void:
	for s in STEMS:
		var cur := float(_levels[s])
		var tgt := float(_targets[s])
		var rate := 2.5 if tgt > cur else 0.35
		if s == "battle" and tgt > cur:
			rate = 5.0
		_levels[s] = move_toward(cur, tgt, rate * delta)
	for b in range(2):
		var on := b == _bank and _bank_scene[b] != ""
		_fade[b] = move_toward(float(_fade[b]), 1.0 if on else 0.0, delta / (1.2 if on else 2.5))
		var bank: Dictionary = _banks[b]
		for s in STEMS:
			var p: AudioStreamPlayer = bank[s]
			if not p.playing:
				continue
			var amp := float(_levels[s]) * float(_fade[b])
			p.volume_db = VOLUME_DB + linear_to_db(maxf(amp, 0.0001))
			p.pitch_scale = move_toward(p.pitch_scale, _pitch, delta * 0.15)
			if float(_fade[b]) <= 0.0 and b != _bank:
				p.stop()
	_sting.pitch_scale = _pitch


## A piece for the place: faded in over the last once it's written.
func _want(scene: String) -> void:
	_wanted = scene
	_order.erase(scene)
	_order.append(scene)
	if _bank_scene[_bank] == scene:
		return
	if not _pieces.has(scene):
		if not _building.has(scene):
			_building[scene] = WorkerThreadPool.add_task(_build.bind(scene))
		return
	_bank = 1 - _bank
	_bank_scene[_bank] = scene
	var bank: Dictionary = _banks[_bank]
	var stems: Dictionary = _pieces[scene]["stems"]
	for s in STEMS:
		var p: AudioStreamPlayer = bank[s]
		p.stream = stems[s]
		p.volume_db = -80.0
		p.pitch_scale = _pitch
	for s in STEMS:
		(bank[s] as AudioStreamPlayer).play()   # (all together: they stay in step)
	_fade[_bank] = 0.0


## A stinger in the key of the piece playing, on the next half beat: "kill", "rift" or "fall".
func sting(kind: String) -> void:
	if not _running:
		return
	var scene: String = _bank_scene[_bank]
	if scene == "" or not _pieces.has(scene):
		return
	var stings: Dictionary = _pieces[scene]["stings"]
	if not stings.has(kind):
		return
	var half := float(_pieces[scene]["beat"]) * 0.5
	var bed: AudioStreamPlayer = _banks[_bank]["bed"]
	var wait := half - fmod(bed.get_playback_position(), half) if bed.playing else 0.0
	if wait < 0.03:
		wait += half
	var tw := create_tween()
	tw.tween_interval(wait)
	tw.tween_callback(func() -> void:
		_sting.stream = stings[kind]
		_sting.volume_db = VOLUME_DB + (-2.0 if kind == "kill" else 0.0)
		_sting.play())


func _build(scene: String) -> void:
	var piece := _compose(scene)
	call_deferred("_built", scene, piece)


func _built(scene: String, piece: Dictionary) -> void:
	_building.erase(scene)
	_pieces[scene] = piece
	while _pieces.size() > KEEP:                  # (the least recently wanted goes)
		var old := ""
		for s in _order:
			if _pieces.has(s) and s != scene and s != _bank_scene[0] and s != _bank_scene[1]:
				old = s
				break
		if old == "":
			break
		_pieces.erase(old)
	if _wanted == scene and _running:
		_want(scene)


# --- writing a piece ---------------------------------------------------------------------------

static func _note(plan: Dictionary, degree: int) -> int:
	var mode: Array = MODES[String(plan["mode"])]
	var o := floori(degree / 7.0)
	return int(plan["root"]) + 12 * o + int(mode[degree - o * 7])


static func _f(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


static func _compose(scene: String) -> Dictionary:
	var plan: Dictionary = SCENES[scene]
	var beat := float(plan["beat"])
	var bar := 4.0 * beat
	var n := int(BARS * bar * Music.RATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = ("score" + scene).hash()
	var prog: Array = plan["prog"]
	var low := 12 if bool(plan.get("low", false)) else 0
	var choir_bed := String(plan.get("bed", "pad")) == "choir"
	var c := {}
	for s in STEMS:
		c[s] = Music.Composer.new(n)
	var bed: Music.Composer = c["bed"]
	var pulse: Music.Composer = c["pulse"]
	var theme: Music.Composer = c["theme"]
	var tension: Music.Composer = c["tension"]
	var battle: Music.Composer = c["battle"]
	# the motif: two bars of rhythm and steps, grown through the chords
	var motif: Array = []                          # [beat offset, scale step from the chord root, length in beats]
	var at := 0.0
	while at < 8.0:
		var dur := float([0.5, 1.0, 1.0, 1.5, 2.0][rng.randi() % 5])
		if at + dur > 8.0:
			dur = 8.0 - at
		var step := int([0, 2, 4, 1, 3, 5, 7, -1][rng.randi() % 8])
		if rng.randf() < 0.18 and at > 0.0:
			at += dur                              # a rest
			continue
		motif.append([at, step, dur])
		at += dur
	for b in range(BARS):
		var deg := int(prog[b % 8])
		var tri := [_note(plan, deg), _note(plan, deg + 2), _note(plan, deg + 4)]
		var t0 := b * bar
		var second := b >= 8
		# bed: the chord held, the bass on one and three
		for note in tri:
			if choir_bed:
				bed.choir(t0, bar, _f(int(note) - low), 0.055)
			else:
				bed.pad(t0, bar, _f(int(note) - 12 - low), 0.05)
		bed.bass(t0, beat * 2.0, _f(int(tri[0]) - 24 - low), 0.12)
		bed.bass(t0 + 2.0 * beat, beat * 1.6, _f(int(tri[0]) - 24 - low + (7 if second and b % 2 == 1 else 0)), 0.08)
		if bool(plan.get("bells", false)) and b % 4 == 0:
			bed.bell(t0 + beat * 0.5, _f(int(tri[2]) + 12), 0.035)
		# pulse: the motion
		match String(plan["pulse"]):
			"arp":
				var arp := [tri[0], tri[1], tri[2], int(tri[0]) + 12, int(tri[1]) + 12, tri[2], tri[1], tri[2]]
				for e in range(8):
					pulse.pluck(t0 + e * beat * 0.5, _f(int(arp[e]) - low), 0.07 if e % 2 == 0 else 0.05)
			"hand":
				for p: float in [0.0, 0.75, 1.5, 2.0, 2.75, 3.5]:
					pulse.drum_hand(t0 + p * beat, 0.18 if p == 0.0 or p == 2.0 else 0.11)
				for e in range(8):
					pulse.shaker(t0 + e * beat * 0.5, 0.035)
				pulse.pluck(t0 + beat, _f(int(tri[1])), 0.05)
				pulse.pluck(t0 + 3.0 * beat, _f(int(tri[2])), 0.05)
			_:
				for q in range(4):
					pulse.shaker(t0 + q * beat, 0.03)
					pulse.pluck(t0 + q * beat + beat * 0.5, _f(int(tri[q % 3]) + 12 - low), 0.03)
		# tension: a low pulsing ostinato (root and the note a half step above), toms, a high
		# dissonant shimmer
		for e in range(8):
			var tn := int(tri[0]) - 24 - low + (1 if e % 4 == 3 else 0)
			tension.bass(t0 + e * beat * 0.5, beat * 0.4, _f(tn), 0.1 if e % 2 == 0 else 0.07)
		tension.drum_low(t0, 0.32)
		tension.drum_low(t0 + 2.5 * beat, 0.22)
		if b % 2 == 1:
			tension.pad(t0, bar, _f(int(tri[0]) + 18), 0.012)   # (a tritone, high and thin)
			tension.pad(t0, bar, _f(int(tri[0]) + 13), 0.01)
		# battle: drums driving every beat, brass stabs on the chord, a brass counter-line
		for q in range(4):
			battle.drum_low(t0 + q * beat, 0.5 if q % 2 == 0 else 0.32)
			battle.drum_hand(t0 + q * beat + beat * 0.5, 0.22)
			battle.shaker(t0 + q * beat + beat * 0.25, 0.04)
			battle.shaker(t0 + q * beat + beat * 0.75, 0.04)
		if b % 4 == 3:                             # a fill at the end of each phrase
			for k in range(4):
				battle.drum_hand(t0 + 3.0 * beat + k * beat * 0.25, 0.16 + 0.04 * k)
		for st: float in [0.0, 1.5]:
			for note in tri:
				battle.brass(t0 + st * beat, beat * 0.35, _f(int(note) - 12), 0.035)
		if second:
			battle.choir(t0, bar, _f(int(tri[0])), 0.035)
			battle.choir(t0, bar, _f(int(tri[2])), 0.03)
		var cl := [tri[2], tri[1], tri[0], tri[1]]
		for q in range(4):
			battle.brass(t0 + q * beat + beat * 0.5, beat * 0.4, _f(int(cl[q])), 0.03)
	# theme: the motif over every two bars, on the chord's root - an octave up the second time,
	# ending each half on the home note
	var lead := String(plan["lead"])
	for b in range(0, BARS, 2):
		var deg := int(prog[b % 8])
		var up := 7 if b >= 8 else 0
		for m in motif:
			var t := b * bar + float(m[0]) * beat
			var note := _note(plan, deg + int(m[1]) + up) + (12 if lead == "bell" else 0) - (12 if lead == "brass" else 0)
			if (b == 6 or b == 14) and float(m[0]) >= 6.0:
				note = int(plan["root"]) + 12 + (12 if b == 14 else 0)    # (home at the phrase's end)
			var length := float(m[2]) * beat
			match lead:
				"flute":
					theme.flute(t, length, _f(note), 0.07)
				"lute":
					theme.pluck(t, _f(note), 0.11)
					if length > beat:
						theme.pluck(t + beat * 0.5, _f(note), 0.06)
				"brass":
					theme.brass(t, length * 0.9, _f(note), 0.06)
				"choir":
					theme.choir(t, length * 1.3, _f(note), 0.05)
				_:
					theme.bell(t, _f(note), 0.055)
	# the stingers, in the key
	var stings := {}
	var k_n := int(1.4 * Music.RATE)
	var kill := Music.Composer.new(k_n)
	for d in [0, 2, 4, 7]:
		kill.brass(0.0, 0.32, _f(_note(plan, d)), 0.06)
	kill.drum_low(0.0, 0.6)
	kill.drum_hand(0.0, 0.3)
	stings["kill"] = _pack([kill], k_n, false)
	var r_n := int(3.0 * Music.RATE)
	var rift := Music.Composer.new(r_n)
	for d in [0, 4, 9]:
		rift.choir(0.0, 1.6, _f(_note(plan, d)), 0.06)
	rift.bell(0.0, _f(_note(plan, 7) + 12), 0.08)
	rift.bell(0.25, _f(_note(plan, 11) + 12), 0.06)
	rift.drum_low(0.0, 0.5)
	stings["rift"] = _pack([rift], r_n, false)
	var f_n := int(3.5 * Music.RATE)
	var fall := Music.Composer.new(f_n)
	for i in range(5):
		fall.bell(i * 0.42, _f(_note(plan, 7 - i * 2) + 12), 0.07)
	fall.pad(0.0, 2.5, _f(_note(plan, 0) - 12), 0.06)
	fall.pad(0.0, 2.5, _f(_note(plan, 2) - 12), 0.05)
	stings["fall"] = _pack([fall], f_n, false)
	# the layers, all at one gain (so they stay in balance with each other)
	var mix := PackedFloat32Array()
	mix.resize(n)
	for s in STEMS:
		var buf: PackedFloat32Array = (c[s] as Music.Composer).buf
		for i in range(n):
			mix[i] += buf[i]
	var peak := 0.001
	for i in range(n):
		peak = maxf(peak, absf(mix[i]))
	var gain := minf(0.95 / peak, 3.0)
	var stems := {}
	for s in STEMS:
		stems[s] = _wav((c[s] as Music.Composer).buf, n, gain, true)
	return {"stems": stems, "stings": stings, "beat": beat}


static func _pack(parts: Array, n: int, loop: bool) -> AudioStreamWAV:
	var buf: PackedFloat32Array = (parts[0] as Music.Composer).buf
	var peak := 0.001
	for i in range(n):
		peak = maxf(peak, absf(buf[i]))
	return _wav(buf, n, minf(0.8 / peak, 3.0), loop)


static func _wav(buf: PackedFloat32Array, n: int, gain: float, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var v := buf[i] * gain
		v = v / (1.0 + absf(v) * 0.25)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = Music.RATE
	s.stereo = false
	s.data = data
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = n
	return s
