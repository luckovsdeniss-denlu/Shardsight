class_name MovieRift
extends Movie
## The Riftrunner trailer ("Riftrunner trailer" on the start screen): the story of experimental
## mode, about fifty seconds. A car of violet metal hums into being beside the hero out in the
## meadows; the hero gets in and drives; Rift jump - the car changes, wings out, lifting off - and
## tears through to the Shardveil, the same land in another dimension; there everyone has a gun,
## the sky burns and the ground splits; and the hero drives home again. Then the logo.
## It's its own script (with the Shardveil let into the trailer by its shows_veil()), so nothing
## here changes the other trailers.

var _exp_was := false                  # experimental mode's switches, as they were (put back after)
var _jump_at := -1.0                   # seconds into the scene to press Rift jump (-1: not this scene)
var _jumped := false

const MEADOW := Vector2i(40, 92)       # open grass by the river: room to drive and to jump
const ROAD_END := Vector2i(58, 92)
const VEIL_SPOT := Vector2i(62, 92)


func start(p_game) -> void:
	_exp_was = Experiments.active
	Experiments.active = true          # (the experiments' world, for this trailer: the car, the Shardveil, its chaos)
	super.start(p_game)


## Lets the Shardveil, its chaos and the car's jumps play out for this trailer's cameras.
func shows_veil() -> bool:
	return running or _intro != null


func _make_shots() -> void:
	shots = [
		{"title": "EXPERIMENTAL MODE", "sub": "Shardsight, as it might yet be.", "dur": 5.0, "no_hero": true, "day": 0.4, "weather": "clear",
			"at": _tc(Vector2i(50, 92)), "r": 24.0, "h": 16.0, "a0": 0.3, "a1": 1.0, "cam": "orbit"},
		{"title": "A gift of violet metal", "story": [["hero", "\"What... is that?\""], ["hero", "\"It's humming.\""]], "words": ["THE RIFTRUNNER"],
			"sub": "Out in the meadows a car hums into being - with a shard of crystal turning at its heart.", "dur": 6.0, "day": 0.42, "stay": true, "cam": "orbit",
			"at": _tc(MEADOW), "r": 5.5, "h": 3.2, "a0": 0.6, "a1": 1.6, "setup": _stage_gift},
		{"title": "Behind the wheel", "words": ["IT FOLLOWS YOU", "GET IN · DRIVE"],
			"sub": "It drives itself after you. Get in - and it goes fast.", "dur": 6.0, "day": 0.44, "cam": "track",
			"at": _tc(MEADOW), "r": 7.5, "h": 4.0, "a0": 2.8, "a1": 3.4, "setup": _stage_drive},
		{"title": "Rift jump", "words": ["IT CHANGES", "WINGS · LIGHT · THRUST"],
			"sub": "Wheels fold into hover pads, wings swing out, the shard blazes - and it tears through.", "dur": 6.0, "day": 0.45, "stay": true, "cam": "orbit",
			"at": _tc(ROAD_END), "r": 7.0, "h": 3.4, "a0": 1.2, "a1": 2.2, "setup": _stage_jump},
		{"title": "The Shardveil", "story": [["hero", "\"Where... am I?\""], ["hero", "\"Same hills. Wrong sky.\""]], "words": ["ANOTHER DIMENSION", "THE SAME LAND · TRANSFORMED"],
			"sub": "A violet sky, two moons, glass trees, glowing water - the land in another dimension.", "dur": 6.5, "stay": true, "cam": "crane",
			"at": _tc(VEIL_SPOT), "r": 12.0, "h": 8.0, "a0": 0.4, "a1": 1.1, "setup": _stage_arrive},
		{"title": "Every one for themselves", "story": [["foe", "\"Nice coat. Mine now.\""], ["hero", "\"Come and take it.\""]], "words": ["EVERYONE HAS A GUN", "NO MERCY"],
			"sub": "In the Shardveil everyone is armed - rockets, shotguns, arc casters - and anyone fights anyone.", "dur": 7.0,
			"at": _tc(VEIL_SPOT), "r": 6.0, "h": 3.6, "a0": 2.0, "a1": 3.2, "setup": _stage_fight.bind(VEIL_SPOT, "Orc", Bestiary.ORC, 2)},
		{"title": "The apocalypse", "story": [["hero", "\"Is the sky supposed to do that?\""]], "words": ["THE SKY IS FALLING", "THE SPOILS ARE RICH"],
			"sub": "Meteors, earthquakes, waves out of the rifts - and gold three times over.", "dur": 7.0, "white": true,
			"at": _tc(VEIL_SPOT + Vector2i(-6, -2)), "r": 7.5, "h": 5.0, "a0": 3.6, "a1": 4.6, "setup": _stage_apocalypse},
		{"title": "And home again", "words": ["DRIVE HOME", "WHENEVER YOU DARE"],
			"sub": "One more jump, and the old sky again.", "dur": 6.0, "stay": true, "cam": "orbit",
			"at": _tc(VEIL_SPOT + Vector2i(-6, -2)), "r": 7.0, "h": 3.4, "a0": 5.0, "a1": 6.0, "setup": _stage_home},
		{"title": "Experimental mode", "words": ["TRY IT NOW", "MAIN MENU · EXPERIMENTS"],
			"sub": "Main Menu > Experiments: the Riftrunner, the Shardveil, and every new idea first.", "dur": 6.0, "no_hero": true, "day": 0.4,
			"at": _tc(Vector2i(50, 92)), "r": 26.0, "h": 18.0, "a0": 1.0, "a1": 1.6, "cam": "orbit"},
	]


func _dim() -> Dimension:
	return game.dimension


## The car appears beside the hero, in a sparkle of violet light.
func _stage_gift() -> void:
	_put_hero(MEADOW)
	hero._face_yaw = -PI * 0.5                       # (facing east, along the open grass)
	hero.rotation.y = hero._face_yaw
	var d := _dim()
	if d == null:
		return
	if d.active:
		d._set_world(false, false)
	d._keep_car()
	if d.car != null and is_instance_valid(d.car):
		if hero.mounted_on == d.car:
			hero.dismount()
		d.car.position = d._beside(hero)
		d.car.path.clear()
		d.car.visible = true
		Fx.sparkle(game, d.car.position + Vector3(0.0, 0.8, 0.0), Dimension.VIOLET, 40)
		Fx.sparkle(game, d.car.position + Vector3(0.0, 0.6, 0.0), Dimension.TEAL, 30)


## In, and off across the meadow.
func _stage_drive() -> void:
	var d := _dim()
	if d == null or d.car == null or not is_instance_valid(d.car):
		return
	if hero.mounted_on != d.car:
		d.car.position = d._beside(hero)
		hero.stay_out = false
		d.car_pressed()
	hero.set_journey(_tc(ROAD_END))
	hero.journey_direct = true


## Rift jump, a moment after the cut.
func _stage_jump() -> void:
	var d := _dim()
	if d == null or d.car == null or not is_instance_valid(d.car):
		return
	if hero.mounted_on != d.car:
		d.car.position = hero.position
		d.car_pressed()
	hero.has_journey = false
	hero.path.clear()
	hero._face_yaw = -PI * 0.5                       # (east: the open way ahead)
	hero.rotation.y = hero._face_yaw
	d._cool = 0.0
	_jump_at = 0.6
	_jumped = false


## Through: the Shardveil all round. The hero steps out of the car.
func _stage_arrive() -> void:
	var d := _dim()
	if d != null and not d.active:
		d._set_world(true, false)                    # (if the jump didn't land in time: there all the same)
	if d != null and d.car != null and hero.mounted_on == d.car:
		hero.dismount()


## The end of the world: an earthquake and a storm of fire on cue, and a fight in the middle of it.
func _stage_apocalypse() -> void:
	_stage_fight(VEIL_SPOT + Vector2i(-6, -2), "Skeleton", Bestiary.SKELETON, 2)
	var d := _dim()
	if d == null:
		return
	if d._apoc:
		d._quake_t = 1.5
		d._storm_t = 0.2
	d._meteor_t = 0.3


## Back in the car, and one more jump - home.
func _stage_home() -> void:
	_put_hero(VEIL_SPOT + Vector2i(-6, -2))
	hero._face_yaw = PI * 0.5                        # (west, back over the meadow)
	hero.rotation.y = hero._face_yaw
	var d := _dim()
	if d == null or d.car == null or not is_instance_valid(d.car):
		return
	d.car.position = hero.position
	hero.stay_out = false
	d.car_pressed()
	d._cool = 0.0
	_jump_at = 0.8
	_jumped = false


## The car is no beast of the scene: it stays in the picture (the stage keeps others out of shot).
func _clear_stage(sh: Dictionary) -> void:
	super._clear_stage(sh)
	var d := _dim()
	if d != null and d.car != null and is_instance_valid(d.car):
		d.car.trailer_held = false
		_held.erase(d.car)
		if not d.car.parked:
			d.car.visible = true


func tick(delta: float) -> bool:
	var d0 := _dim()
	if d0 != null and d0.car != null and is_instance_valid(d0.car) and not d0.car.parked:
		d0.car._update_cull()                      # (the world off camera holds still in a trailer: the car must still show when it comes into view)
	if running and _jump_at >= 0.0 and not _jumped and t + delta >= _jump_at:
		_jumped = true
		_jump_at = -1.0
		var d := _dim()
		if d != null:
			d.jump()
	return super.tick(delta)


## The end: home, out of the car, the chaos over - and experimental mode's switches as they were.
func _back_to_title() -> void:
	var d := _dim()
	if d != null:
		if d._jump_t >= 0.0:
			d._tf_clear()
			d._jump_t = -1.0
		if d.active:
			d._set_world(false, false)
		d._chaos_step(0.0)                         # (everyone's own weapons back, before the hero's are put back)
	if hero.mounted_on != null:
		hero.dismount()
	Experiments.active = _exp_was
	super._back_to_title()
