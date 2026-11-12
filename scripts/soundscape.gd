class_name Soundscape
## The mix: music, sound effects and ambience each on their own bus, with reverb and a gentle
## compressor, and the whole held together on the master by a compressor (no clipping when much
## happens at once). The space you stand in changes how things sound: a long echo in the
## dungeon and the caves, a hall in the church, a little room in town, open air in the wilds.
## And your state: as a ghost, or near death, the world goes muffled (and your heart pounds).

const BUSES := ["Music", "SFX", "Ambience"]
## SFX reverb per kind of place: [room size, wet, damping].
const SPACES := {
	"dungeon": [0.88, 0.42, 0.25], "cave": [0.8, 0.38, 0.3], "church": [0.75, 0.32, 0.45],
	"town": [0.32, 0.1, 0.6], "wilds": [0.18, 0.05, 0.75],
}


## Builds the buses once (they last through scene reloads).
static func setup() -> void:
	if AudioServer.get_bus_index("SFX") >= 0:
		return
	for b in BUSES:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, b)
		AudioServer.set_bus_send(idx, "Master")
	var sfx := AudioServer.get_bus_index("SFX")
	var rv := AudioEffectReverb.new()
	rv.room_size = 0.18
	rv.wet = 0.05
	rv.dry = 1.0
	rv.damping = 0.75
	AudioServer.add_bus_effect(sfx, rv)
	var music := AudioServer.get_bus_index("Music")
	var hall := AudioEffectReverb.new()                 # music in a wide hall
	hall.room_size = 0.8
	hall.wet = 0.22
	hall.dry = 0.9
	hall.damping = 0.5
	hall.spread = 1.0
	AudioServer.add_bus_effect(music, hall)
	var chorus := AudioEffectChorus.new()               # a little width and shimmer
	chorus.voice_count = 2
	chorus.wet = 0.25
	chorus.dry = 1.0
	AudioServer.add_bus_effect(music, chorus)
	var amb := AudioServer.get_bus_index("Ambience")
	var arv := AudioEffectReverb.new()
	arv.room_size = 0.5
	arv.wet = 0.12
	AudioServer.add_bus_effect(amb, arv)
	# the master: a muffling filter (off until needed), then a compressor that keeps it all together
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(0, lp)
	AudioServer.set_bus_effect_enabled(0, 0, false)
	var comp := AudioEffectCompressor.new()
	comp.threshold = -12.0
	comp.ratio = 3.0
	comp.attack_us = 20.0
	comp.release_ms = 200.0
	AudioServer.add_bus_effect(0, comp)


## Each half second: the echo of the place, and the muffling of a ghost or someone near death.
static func update(space: String, ghost: bool, near_death: bool) -> void:
	var sfx := AudioServer.get_bus_index("SFX")
	if sfx < 0:
		return
	var rv := AudioServer.get_bus_effect(sfx, 0) as AudioEffectReverb
	var want: Array = SPACES.get(space, SPACES["wilds"])
	rv.room_size = lerpf(rv.room_size, float(want[0]), 0.35)
	rv.wet = lerpf(rv.wet, float(want[1]), 0.35)
	rv.damping = lerpf(rv.damping, float(want[2]), 0.35)
	var lp := AudioServer.get_bus_effect(0, 0) as AudioEffectLowPassFilter
	var cutoff := 900.0 if ghost else (1800.0 if near_death else 20000.0)
	lp.cutoff_hz = lerpf(lp.cutoff_hz, cutoff, 0.4)
	AudioServer.set_bus_effect_enabled(0, 0, lp.cutoff_hz < 15000.0)
