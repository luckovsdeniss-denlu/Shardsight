class_name Music
extends Node
## Procedural ambient music, like the sound effects: no audio files. Each area has its own loop,
## built from a note list (soft sine voices with gentle envelopes) on a worker thread the first
## time it is needed, then cross-faded in. Areas: "town", "wilds", "dungeon".

const RATE := 11025
const BEAT := 0.6                 # seconds per beat (100 bpm)
const BARS := 8                   # 4 beats each: loops of 19.2 s
const VOLUME_DB := -13.0

## Chord roots and kinds per area (one chord per bar), and the melody scale.
const PLANS := {
	"town": {"chords": [[60, "maj"], [57, "min"], [53, "maj"], [55, "maj"], [60, "maj"], [57, "min"], [62, "min"], [55, "maj"]],
		"scale": [60, 62, 64, 67, 69, 72, 74, 76], "melody": 0.7, "bell": false},
	"wilds": {"chords": [[50, "min"], [53, "maj"], [48, "maj"], [55, "maj"], [50, "min"], [57, "min"], [53, "maj"], [52, "min"]],
		"scale": [62, 64, 65, 67, 69, 72, 74], "melody": 0.35, "bell": false},
	"dungeon": {"chords": [[45, "min"], [45, "min"], [46, "maj"], [45, "min"], [43, "min"], [45, "min"], [41, "maj"], [40, "min"]],
		"scale": [57, 60, 62, 63, 64, 67], "melody": 0.18, "bell": true},
}

var player := AudioStreamPlayer.new()
var enabled := true
var _tracks := {}                 # area -> AudioStreamWAV, once built
var _building := {}               # area -> true while its worker task runs
var _area := ""
var _wanted := ""
var _fade: Tween


func _ready() -> void:
	add_child(player)
	player.volume_db = -80.0


## Ask for an area's music; it fades in once ready (and when music is on).
func play_area(area: String) -> void:
	_wanted = area
	if not enabled:
		player.stop()
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
	if _fade != null:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(player, "volume_db", -40.0, 0.8)
	_fade.tween_callback(func() -> void:
		player.stream = _tracks[area]
		player.play())
	_fade.tween_property(player, "volume_db", VOLUME_DB, 1.5)


func set_enabled(on: bool) -> void:
	enabled = on
	if on:
		_area = ""
		play_area(_wanted)
	else:
		player.stop()
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


## Writes the notes of one loop into a sample buffer and packs it as a looping WAV.
static func _compose(area: String) -> AudioStreamWAV:
	var plan: Dictionary = PLANS[area]
	var n := int(BARS * 4 * BEAT * RATE)
	var c := Composer.new(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = area.hash()
	var bar_len := 4.0 * BEAT
	var chords: Array = plan["chords"]
	for b in range(BARS):
		var root := int(chords[b][0])
		var third := 4 if String(chords[b][1]) == "maj" else 3
		# a soft pad: root, third and fifth held for the bar (an octave down in the dungeon)
		for note in [root - 12, root + third - 12, root + 7 - 12]:
			c.tone(b * bar_len, bar_len, _freq(note), 0.09, 0.6, 0.8)
		# a slow bass note on beat one
		c.tone(b * bar_len, BEAT * 2.0, _freq(root - 24), 0.12, 0.05, 1.2)
	# the melody: notes from the scale on some beats, more often in town
	var scale: Array = plan["scale"]
	var prev := rng.randi() % scale.size()
	for beat in range(BARS * 4):
		if rng.randf() > float(plan["melody"]):
			continue
		prev = clampi(prev + rng.randi_range(-2, 2), 0, scale.size() - 1)
		var length := BEAT * (2.0 if rng.randf() < 0.3 else 1.0)
		c.tone(beat * BEAT, length, _freq(int(scale[prev])), 0.1, 0.02, 0.35 if bool(plan["bell"]) else 0.5)
	# a far-off bell now and then in the dungeon
	if bool(plan["bell"]):
		for k in range(3):
			c.tone(rng.randf_range(0.0, BARS * bar_len - 3.0), 3.0, _freq(81 + rng.randi_range(-3, 3)), 0.05, 0.005, 2.5)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		data.encode_s16(i * 2, int(clampf(c.buf[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n
	return s


## Holds the sample buffer while a loop is written (one per worker task).
class Composer:
	var buf := PackedFloat32Array()

	func _init(n: int) -> void:
		buf.resize(n)

	## Adds one note: a sine with a touch of its octave, attack and decay in seconds. Notes that
	## run past the end wrap round to the start, so the loop is seamless.
	func tone(start: float, length: float, freq: float, amp: float, attack: float, release: float) -> void:
		_add(start, length, freq, amp, attack, release)

	func _add(start: float, length: float, freq: float, amp: float, attack: float, release: float) -> void:
		var n := buf.size()
		var count := int((length + release) * Music.RATE)
		var s0 := int(start * Music.RATE)
		var w := TAU * freq / Music.RATE
		for i in range(count):
			var t := float(i) / Music.RATE
			var env := minf(t / maxf(attack, 0.001), 1.0)
			if t > length:
				env *= maxf(0.0, 1.0 - (t - length) / release)
			var v := (sin(w * i) + 0.25 * sin(2.0 * w * i)) * amp * env
			var j := (s0 + i) % n
			buf[j] += v
