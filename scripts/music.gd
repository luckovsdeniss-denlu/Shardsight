class_name Music
extends Node
## Procedural music, like the sound effects: no audio files. Each place and mood has its own
## piece - sixteen bars in two halves - written once, on a worker thread, the first time it's
## needed, then cross-faded in over the last one. The instruments are built from formulas too:
## a warm detuned pad, a plucked lute, a breathy flute, a bass, a choir, bells, and drums (a deep
## drum, a hand drum, a shaker).
## Pieces: town, wilds, night, dungeon, battle, boss, frost, desert, church, cemetery.

const RATE := 16000
const BARS := 16
const VOLUME_DB := -12.0

## For each piece: the beat (seconds), the chords (root note and kind, one a bar; the second
## eight bars may differ), the melody's scale and how busy it is, and which instruments play.
const PLANS := {
	"town": {"beat": 0.5, "chords": [[60, "maj"], [57, "min"], [53, "maj"], [55, "maj"], [60, "maj"], [57, "min"], [62, "min"], [55, "maj"],
			[53, "maj"], [55, "maj"], [60, "maj"], [57, "min"], [53, "maj"], [55, "maj"], [60, "maj"], [60, "maj"]],
		"scale": [60, 62, 64, 67, 69, 72, 74, 76], "melody": 0.6, "lead": "flute", "lute": true, "hand": true},
	"wilds": {"beat": 0.6, "chords": [[50, "min"], [53, "maj"], [48, "maj"], [55, "maj"], [50, "min"], [57, "min"], [53, "maj"], [52, "min"],
			[48, "maj"], [50, "min"], [53, "maj"], [55, "maj"], [57, "min"], [53, "maj"], [52, "min"], [50, "min"]],
		"scale": [62, 64, 65, 67, 69, 71, 72, 74], "melody": 0.38, "lead": "flute", "deep": true},
	"night": {"beat": 0.75, "chords": [[45, "min"], [41, "maj"], [48, "maj"], [43, "maj"], [45, "min"], [40, "min"], [41, "maj"], [44, "maj"],
			[45, "min"], [48, "maj"], [43, "maj"], [41, "maj"], [45, "min"], [40, "min"], [41, "maj"], [45, "min"]],
		"scale": [69, 71, 72, 74, 76, 77, 79], "melody": 0.22, "lead": "bell"},
	"dungeon": {"beat": 0.8, "chords": [[45, "min"], [45, "min"], [46, "maj"], [45, "min"], [43, "min"], [45, "min"], [41, "maj"], [40, "min"],
			[45, "min"], [44, "dim"], [45, "min"], [46, "maj"], [43, "min"], [41, "maj"], [40, "min"], [45, "min"]],
		"scale": [57, 60, 62, 63, 64, 67], "melody": 0.12, "lead": "bell", "deep": true, "bells": true},
	"battle": {"beat": 0.36, "chords": [[50, "min"], [50, "min"], [46, "maj"], [48, "maj"], [50, "min"], [50, "min"], [53, "maj"], [52, "maj"],
			[46, "maj"], [48, "maj"], [50, "min"], [45, "maj"], [46, "maj"], [48, "maj"], [45, "maj"], [50, "min"]],
		"scale": [62, 64, 65, 67, 69, 70, 72, 74], "melody": 0.55, "lead": "brass", "drums": true, "ostinato": true},
	"boss": {"beat": 0.4, "chords": [[45, "min"], [45, "min"], [41, "maj"], [44, "maj"], [45, "min"], [46, "maj"], [41, "maj"], [40, "maj"],
			[45, "min"], [43, "min"], [41, "maj"], [40, "maj"], [45, "min"], [46, "maj"], [44, "dim"], [45, "min"]],
		"scale": [57, 59, 60, 62, 64, 65, 68, 69], "melody": 0.45, "lead": "brass", "drums": true, "ostinato": true, "choir": true},
	"frost": {"beat": 0.8, "chords": [[52, "min"], [48, "maj"], [55, "maj"], [50, "maj"], [52, "min"], [57, "min"], [48, "maj"], [47, "maj"],
			[52, "min"], [55, "maj"], [50, "maj"], [48, "maj"], [45, "min"], [48, "maj"], [47, "maj"], [52, "min"]],
		"scale": [76, 78, 79, 81, 83, 84, 86], "melody": 0.3, "lead": "bell"},
	"desert": {"beat": 0.5, "chords": [[52, "maj"], [53, "maj"], [52, "maj"], [50, "min"], [52, "maj"], [53, "maj"], [55, "min"], [52, "maj"],
			[50, "min"], [52, "maj"], [53, "maj"], [52, "maj"], [50, "min"], [48, "maj"], [53, "maj"], [52, "maj"]],
		"scale": [64, 65, 68, 69, 71, 72, 74, 76], "melody": 0.5, "lead": "lute", "hand": true, "desert": true},
	"church": {"beat": 0.9, "chords": [[48, "maj"], [53, "maj"], [45, "min"], [55, "maj"], [48, "maj"], [50, "min"], [53, "maj"], [55, "maj"],
			[57, "min"], [53, "maj"], [48, "maj"], [55, "maj"], [53, "maj"], [50, "min"], [55, "maj"], [48, "maj"]],
		"scale": [72, 74, 76, 77, 79, 81], "melody": 0.18, "lead": "choir", "choir": true},
	"cemetery": {"beat": 0.85, "chords": [[44, "min"], [44, "min"], [40, "maj"], [43, "maj"], [44, "min"], [41, "dim"], [40, "maj"], [44, "min"],
			[44, "min"], [47, "maj"], [40, "maj"], [43, "maj"], [44, "min"], [41, "dim"], [43, "maj"], [44, "min"]],
		"scale": [56, 59, 61, 63, 64, 66], "melody": 0.14, "lead": "choir", "choir": true, "bells": true},
}

var player_a := AudioStreamPlayer.new()
var player_b := AudioStreamPlayer.new()
var player: AudioStreamPlayer          # the one playing now
var enabled := true
var _tracks := {}                 # piece -> AudioStreamWAV, once written
var _building := {}               # piece -> true while its worker task runs
var _area := ""
var _wanted := ""


func _ready() -> void:
	for p in [player_a, player_b]:
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
	player = player_a


## Ask for a piece; it fades in over the last one once it's written (and when music is on).
func play_area(area: String) -> void:
	if not PLANS.has(area):
		area = "wilds"
	_wanted = area
	if not enabled:
		player_a.stop()
		player_b.stop()
		_area = ""
		return
	if area == _area:
		return
	if not _tracks.has(area):
		if not _building.has(area):
			_building[area] = true
			WorkerThreadPool.add_task(_build.bind(area))
		return
	_area = area
	# a cross-fade: the new piece rises as the old one sinks
	var old := player
	player = player_b if player == player_a else player_a
	player.stream = _tracks[area]
	player.volume_db = -40.0
	player.play()
	var quick := area in ["battle", "boss"]           # a fight starts at once; peace returns slowly
	var tw := create_tween().set_parallel(true)
	tw.tween_property(player, "volume_db", VOLUME_DB, 0.8 if quick else 2.5)
	tw.tween_property(old, "volume_db", -60.0, 1.0 if quick else 2.5)
	tw.chain().tween_callback(old.stop)


func set_enabled(on: bool) -> void:
	enabled = on
	if on:
		_area = ""
		play_area(_wanted)
	else:
		player_a.stop()
		player_b.stop()
		_area = ""


func _build(area: String) -> void:
	var stream := _compose(area)
	call_deferred("_built", area, stream)


func _built(area: String, stream: AudioStreamWAV) -> void:
	_tracks[area] = stream
	_building.erase(area)
	if _wanted == area:
		play_area(area)


static func _freq(midi: int) -> float:
	return 440.0 * pow(2.0, (midi - 69) / 12.0)


static func _triad(root: int, kind: String) -> Array[int]:
	match kind:
		"min":
			return [root, root + 3, root + 7]
		"dim":
			return [root, root + 3, root + 6]
	return [root, root + 4, root + 7]


## Writes one piece into a sample buffer and packs it as a looping WAV.
static func _compose(area: String) -> AudioStreamWAV:
	var plan: Dictionary = PLANS[area]
	var beat := float(plan["beat"])
	var bar := 4.0 * beat
	var n := int(BARS * bar * RATE)
	var c := Composer.new(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = area.hash()
	var chords: Array = plan["chords"]
	for b in range(BARS):
		var root := int(chords[b][0])
		var tri := _triad(root, String(chords[b][1]))
		var t0 := b * bar
		# the pad (or the choir) holds the chord through the bar
		for note in tri:
			if bool(plan.get("choir", false)):
				c.choir(t0, bar, _freq(note - 12 if area != "church" else note), 0.06)
			else:
				c.pad(t0, bar, _freq(note - 12), 0.05)
		# the bass: on the bar, or driving eighths in a fight
		if bool(plan.get("ostinato", false)):
			for e in range(8):
				c.bass(t0 + e * beat / 2.0, beat * 0.45, _freq(root - 24 + (7 if e == 6 else 0)), 0.16)
		else:
			c.bass(t0, beat * 2.0, _freq(root - 24), 0.13)
			if bool(plan.get("deep", false)) and b % 2 == 1:
				c.bass(t0 + 2.0 * beat, beat * 1.5, _freq(root - 24), 0.08)
		# the lute: a rising, falling arpeggio, a note to each half beat
		if bool(plan.get("lute", false)):
			var arp := [tri[0], tri[1], tri[2], tri[0] + 12, tri[2], tri[1], tri[2], tri[0] + 12]
			for e in range(8):
				c.pluck(t0 + e * beat / 2.0, _freq(int(arp[e])), 0.09)
		# drums
		if bool(plan.get("drums", false)):
			for q in range(4):
				c.drum_low(t0 + q * beat, 0.5 if q % 2 == 0 else 0.3)
				c.drum_hand(t0 + q * beat + beat / 2.0, 0.22)
				if q == 3 and b % 4 == 3:            # a fill at the end of each phrase
					c.drum_hand(t0 + q * beat + beat * 0.25, 0.2)
					c.drum_hand(t0 + q * beat + beat * 0.75, 0.25)
			for e in range(8):
				c.shaker(t0 + e * beat / 2.0, 0.05)
		elif bool(plan.get("hand", false)):
			var pattern := [0.0, 1.5, 2.0, 3.0] if not bool(plan.get("desert", false)) else [0.0, 0.75, 1.5, 2.0, 2.5, 3.5]
			for p in pattern:
				c.drum_hand(t0 + float(p) * beat, 0.15 if float(p) != 0.0 else 0.22)
		elif bool(plan.get("deep", false)) and b % 2 == 0:
			c.drum_low(t0, 0.25)                      # a far-off drum every other bar
	# the melody: a walking line from the scale, more often where it's busier; the second half an
	# octave up in places, and resting on the chord's root at the phrase ends
	var scale: Array = plan["scale"]
	var prev := rng.randi() % scale.size()
	var lead := String(plan.get("lead", "flute"))
	for k in range(BARS * 4):
		var t := k * beat
		var phrase_end := k % 16 == 15
		if not phrase_end and rng.randf() > float(plan["melody"]):
			continue
		prev = clampi(prev + rng.randi_range(-2, 2), 0, scale.size() - 1)
		var note := int(scale[prev])
		if phrase_end:
			note = int(chords[k / 4][0]) + 12
			while note < int(scale[0]):
				note += 12
		var length := beat * (2.0 if rng.randf() < 0.35 or phrase_end else 1.0)
		match lead:
			"flute":
				c.flute(t, length, _freq(note), 0.07)
			"lute":
				c.pluck(t, _freq(note), 0.12)
				if rng.randf() < 0.4:
					c.pluck(t + beat / 4.0, _freq(note), 0.07)    # an ornament, as on an oud
			"brass":
				c.brass(t, length * 0.9, _freq(note), 0.07)
			"choir":
				c.choir(t, length * 1.5, _freq(note), 0.05)
			_:
				c.bell(t, _freq(note), 0.06)
	if bool(plan.get("bells", false)):              # tolls, far away
		for k in range(4):
			c.bell(rng.randf_range(0.0, BARS * bar - 3.0), _freq(rng.randi_range(57, 69)), 0.05)
	var data := PackedByteArray()
	data.resize(n * 2)
	var peak := 0.001
	for i in range(n):
		peak = maxf(peak, absf(c.buf[i]))
	var gain := minf(0.9 / peak, 2.0)                 # brought to a steady level
	for i in range(n):
		var v := c.buf[i] * gain
		v = v / (1.0 + absf(v) * 0.3)                  # a soft saturation: warmth, no harsh clipping
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n
	return s


## Holds the sample buffer while a piece is written (one per worker task). Notes that run past
## the end wrap round to the start, so the loop is seamless.
class Composer:
	var buf := PackedFloat32Array()
	var noise := RandomNumberGenerator.new()

	func _init(n: int) -> void:
		buf.resize(n)
		noise.seed = 99

	func _put(i: int, v: float) -> void:
		buf[i % buf.size()] += v

	## A warm pad: three slightly detuned voices and the octave, slow in and out, breathing.
	func pad(start: float, length: float, freq: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var count := int((length + 1.0) * r)
		for i in range(count):
			var t := float(i) / r
			var env := minf(t / 0.6, 1.0) * (1.0 if t < length else maxf(0.0, 1.0 - (t - length)))
			var v := sin(TAU * freq * t) + sin(TAU * freq * 1.004 * t) * 0.7 + sin(TAU * freq * 0.996 * t) * 0.7 + sin(TAU * freq * 2.0 * t) * 0.25
			_put(s0 + i, v * amp * env * (0.85 + 0.15 * sin(TAU * 0.5 * t)))

	## A plucked string: bright at first, the high partials dying fastest.
	func pluck(start: float, freq: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var count := int(1.6 * r)
		for i in range(count):
			var t := float(i) / r
			var v := 0.0
			for k in range(1, 6):
				v += sin(TAU * freq * k * t) * exp(-t * (2.5 + k * 2.0)) / k
			_put(s0 + i, v * amp * minf(t / 0.003, 1.0))

	## A flute: a pure tone with a little of its third harmonic, a breath at the start, and a
	## vibrato that comes in as the note is held.
	func flute(start: float, length: float, freq: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var count := int((length + 0.25) * r)
		var ph := 0.0
		for i in range(count):
			var t := float(i) / r
			var vib := 1.0 + 0.006 * sin(TAU * 5.2 * t) * smoothstep(0.15, 0.5, t)
			ph += TAU * freq * vib / r
			var env := minf(t / 0.07, 1.0) * (1.0 if t < length else maxf(0.0, 1.0 - (t - length) / 0.25))
			var breath := noise.randf_range(-1.0, 1.0) * 0.12 * exp(-t * 12.0)
			_put(s0 + i, (sin(ph) + 0.15 * sin(3.0 * ph) + breath) * amp * env)

	## Brass: a bright buzz (odd and even harmonics), swelling in.
	func brass(start: float, length: float, freq: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var count := int((length + 0.15) * r)
		for i in range(count):
			var t := float(i) / r
			var env := minf(t / 0.04, 1.0) * (1.0 if t < length else maxf(0.0, 1.0 - (t - length) / 0.15))
			var bright := 0.5 + 0.5 * minf(t / 0.12, 1.0)
			var v := 0.0
			for k in range(1, 7):
				v += sin(TAU * freq * k * t) / k * (1.0 if k < 3 else bright)
			_put(s0 + i, v * amp * env)

	func bass(start: float, length: float, freq: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var count := int((length + 0.3) * r)
		for i in range(count):
			var t := float(i) / r
			var env := minf(t / 0.01, 1.0) * exp(-t * (1.0 / maxf(length, 0.1)))
			_put(s0 + i, (sin(TAU * freq * t) + 0.35 * sin(TAU * freq * 2.0 * t)) * amp * env)

	## A choir: "ah" - the harmonics near the voice's formants sung loudest, a slow vibrato.
	func choir(start: float, length: float, freq: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var count := int((length + 0.8) * r)
		for i in range(count):
			var t := float(i) / r
			var vib := 1.0 + 0.004 * sin(TAU * 4.5 * t)
			var env := minf(t / 0.4, 1.0) * (1.0 if t < length else maxf(0.0, 1.0 - (t - length) / 0.8))
			var v := 0.0
			for k in range(1, 9):
				var hf := freq * k
				var w := exp(-pow((hf - 700.0) / 260.0, 2.0)) + 0.6 * exp(-pow((hf - 1150.0) / 300.0, 2.0)) + 0.3
				v += sin(TAU * hf * vib * t) * w / k
			_put(s0 + i, v * amp * env)

	## A bell: partials out of tune with each other, ringing long.
	func bell(start: float, freq: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var count := int(3.0 * r)
		for i in range(count):
			var t := float(i) / r
			var v := sin(TAU * freq * t) * exp(-t * 1.2) + 0.5 * sin(TAU * freq * 2.76 * t) * exp(-t * 2.5) + 0.25 * sin(TAU * freq * 5.4 * t) * exp(-t * 4.0)
			_put(s0 + i, v * amp * minf(t / 0.002, 1.0))

	## A deep drum: a thump that falls in pitch.
	func drum_low(start: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		var ph := 0.0
		for i in range(int(0.5 * r)):
			var t := float(i) / r
			ph += TAU * (45.0 + 90.0 * exp(-t * 25.0)) / r
			_put(s0 + i, sin(ph) * exp(-t * 7.0) * amp)

	## A hand drum: a slap of noise and a short ring.
	func drum_hand(start: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		for i in range(int(0.25 * r)):
			var t := float(i) / r
			_put(s0 + i, (noise.randf_range(-1.0, 1.0) * exp(-t * 60.0) + sin(TAU * 210.0 * t) * exp(-t * 18.0)) * amp)

	func shaker(start: float, amp: float) -> void:
		var r := Music.RATE
		var s0 := int(start * r)
		for i in range(int(0.08 * r)):
			var t := float(i) / r
			_put(s0 + i, noise.randf_range(-1.0, 1.0) * exp(-t * 50.0) * amp * minf(t / 0.01, 1.0))
