class_name Movie
extends CanvasLayer
## The Movie button on the start screen: a gameplay showcase, played by the game itself. The
## camera films a run of short scenes - the land from above, a fight, magic, the depths, the snow
## and the desert, boats, the tavern, the arena, the church and the cemetery at night, winter, a
## storm, a world boss - each with a title over letterbox bars, while the hero fights and casts
## for real. Nothing is saved; when it ends (or Skip is pressed) the game starts afresh at the
## title.

var game
var world: World
var hero: Entity
var shots: Array = []
var i := -1
var t := 0.0
var running := false
var _title: Label
var _sub: Label
var _bars: Array[ColorRect] = []
var _actors: Array[Entity] = []
var _fade: ColorRect
var _cast_acc := 0.0
var _fx: ShaderMaterial            # grain, vignette, a light leak, the flash
var _rule: ColorRect               # the gold line under the title
var _counter: Label
var _progress: ColorRect
var _shake := 0.0
var _flash := 0.0
var _was_casting := false
var _slow := 0.0                   # real seconds of slow motion left
var _end_card: Control
var _riser_done := false


func _sound(sound_name: String, pitch: float, db: float) -> void:
	if game.property.sound_on:
		game.sfx.play(sound_name, pitch, db)
const SWEEP_SHADER := """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float pos = fract(TIME * 0.3) * 1.8 - 0.4;
	float band = smoothstep(0.07, 0.0, abs(SCREEN_UV.x - pos - (SCREEN_UV.y - 0.4) * 0.3));
	c.rgb += vec3(1.0, 0.95, 0.8) * band * 0.85 * c.a;
	COLOR = c;
}
"""
const FX_SHADER := """
shader_type canvas_item;
uniform float flash = 0.0;
uniform float leak = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	// film grain and a soft flicker
	float g = (hash(uv * 800.0 + vec2(TIME * 41.0, TIME * 73.0)) - 0.5) * 0.08;
	float flick = sin(TIME * 23.0) * 0.012;
	// the corners in shadow
	float v = smoothstep(0.42, 0.95, length((uv - 0.5) * vec2(1.25, 1.0))) * 0.55;
	// a warm light leak drifting across the left edge
	float lk = leak * smoothstep(0.55, 0.0, uv.x + 0.15 * sin(TIME * 0.4 + uv.y * 3.0)) * 0.35;
	vec3 col = vec3(1.0, 0.6, 0.3) * lk + vec3(g + flick);
	float a = clamp(v + abs(g) + lk, 0.0, 1.0);
	// a white flash on a big blow or a cut
	col = mix(col, vec3(1.0, 0.97, 0.9), flash);
	a = max(a, flash);
	COLOR = vec4(mix(col, vec3(0.0), v / max(a, 0.001) * (1.0 - flash)), a);
}
"""


func start(p_game) -> void:
	game = p_game
	world = game.world
	hero = game.hero
	layer = 50
	game.add_child(self)
	# a clean picture: no buttons, log, stats or menus, and nothing over anyone's head
	if game.ui_layer != null:
		game.ui_layer.visible = false
	for e in game.creatures:
		e.show_name(false)
		e.hp_bar.visible = false
	_build_ui()
	# the hero, for the cameras: a master of arms and magic (nothing of it is kept)
	for s in [Hero.Skill.MAGERY, Hero.Skill.EVALUATING_INTELLECT, Hero.Skill.SWORDSMANSHIP, Hero.Skill.TACTICS, Hero.Skill.ANATOMY]:
		hero.stats.skills[s] = 100.0
	for id in Spells.LIST:
		hero.spellbook[id] = true
	hero.weapon = "longsword@ex"
	hero.armor_id = "platemail"
	hero.shield_id = "heater_shield"
	hero.refresh_look()
	hero.ai_enabled = true
	hero.roam_timer = 1.0e9                             # no wandering off between scenes
	game.frontier._auto_wait = 1.0e9                     # and no errands
	game.skip_save = true                               # nothing of the movie is kept
	game.music.set_enabled(game.property.music_on)
	game.music.play_area("trailer")                     # its own score: drums, brass, choir
	for k in ["crickets", "water", "fire", "wind", "tavern", "crowd"]:
		game._amb_set(k, -80.0)                         # the ambience steps back
	_make_shots()
	running = true
	_next()


func _build_ui() -> void:
	var vs := get_viewport().get_visible_rect().size
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_left = 0.0
		bar.offset_right = 0.0
		bar.offset_top = 0.0 if top else -vs.y * 0.12
		bar.offset_bottom = vs.y * 0.12 if top else 0.0
		_bars.append(bar)
	_title = _label(44, Color(0.95, 0.8, 0.42))
	_sub = _label(24, Color(0.85, 0.88, 0.95))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	col.add_child(_title)
	col.add_child(_sub)
	col.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 40)
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.offset_top -= vs.y * 0.12
	col.offset_bottom -= vs.y * 0.12
	var skip := Button.new()
	skip.text = "Skip"
	skip.custom_minimum_size = Vector2(150, 56)
	skip.add_theme_font_size_override("font_size", 24)
	skip.pressed.connect(finish)
	add_child(skip)
	skip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	skip.offset_top += vs.y * 0.12 * 0.15
	# the grain, the dark corners, the light leak and the flash, under the titles
	var fxr := ColorRect.new()
	var sh := Shader.new()
	sh.code = FX_SHADER
	_fx = ShaderMaterial.new()
	_fx.shader = sh
	fxr.material = _fx
	fxr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fxr)
	move_child(fxr, 0)
	fxr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# a gold rule that draws itself under each title, the scene's number, and a thread of progress
	_rule = ColorRect.new()
	_rule.color = Color(0.95, 0.78, 0.35)
	_rule.custom_minimum_size = Vector2(0, 3)
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.get_parent().add_child(_rule)
	_title.get_parent().move_child(_rule, 1)
	_counter = _label(18, Color(0.95, 0.78, 0.35, 0.8))
	add_child(_counter)
	_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)
	_counter.offset_top += vs.y * 0.12 * 0.25
	_progress = ColorRect.new()
	_progress.color = Color(0.95, 0.78, 0.35, 0.8)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_progress)
	_progress.position = Vector2(0, vs.y - 3)
	_progress.size = Vector2(0, 3)
	# the bars close in at the start
	for b in _bars:
		var full := b.offset_bottom - b.offset_top
		if b.offset_top == 0.0:
			b.offset_bottom = 0.0
			b.create_tween().tween_property(b, "offset_bottom", full, 1.0).set_trans(Tween.TRANS_SINE)
		else:
			b.offset_top = 0.0
			b.create_tween().tween_property(b, "offset_top", -full, 1.0).set_trans(Tween.TRANS_SINE)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _label(px: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 10)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# --- the scenes --------------------------------------------------------------------------------

## Each scene: a title and a line, how long it runs, what it sets up, and the camera: an orbit
## round a point ("at", "r" metres out, "h" up, from angle "a0" to "a1") or a glide ("from" ->
## "to", looking at "at").
func _make_shots() -> void:
	shots = [
		{"title": "SHARDSIGHT", "sub": "A world of swords, spells and skill.", "dur": 6.0, "day": 0.35, "weather": "clear",
			"at": _tc(Vector2i(24, 9)), "r": 26.0, "h": 22.0, "a0": 0.4, "a1": 1.3},
		{"title": "Living towns", "sub": "Healers, priests, merchants, bankers - and folk who keep their own days.", "dur": 6.0,
			"at": _tc(Vector2i(24, 10)), "r": 9.0, "h": 6.0, "a0": 2.4, "a1": 3.4, "setup": _stage_town},
		{"title": "Fight", "sub": "Swords, axes, maces, spears, bows - and a different blow for each.", "dur": 8.0,
			"at": _tc(Vector2i(14, 19)), "r": 4.5, "h": 2.6, "a0": 0.0, "a1": 1.4, "setup": _stage_fight.bind(Vector2i(14, 19), "Orc", Bestiary.ORC, 2)},
		{"title": "Magic", "sub": "Sixty-seven spells in eight circles. Speak the old words.", "dur": 9.0, "white": true,
			"at": _tc(Vector2i(14, 19)), "r": 6.0, "h": 4.0, "a0": 1.4, "a1": 2.8, "setup": _stage_magic},
		{"title": "The dungeon's depths", "sub": "Five levels down, each darker than the last.", "dur": 7.0,
			"at": _tc(Vector2i(44, 16)), "r": 7.0, "h": 6.5, "a0": 3.0, "a1": 4.2, "setup": _stage_fight.bind(Vector2i(45, 19), "Skeleton", Bestiary.SKELETON, 2)},
		{"title": "The Frostmarch", "sub": "Biomes: snow, desert, swamp and ash - each with its own beasts.", "dur": 7.0, "snow": true,
			"at": _tc(Vector2i(70, 5)), "r": 8.0, "h": 5.0, "a0": 0.5, "a1": 1.6, "setup": _stage_fight.bind(Vector2i(70, 5), "Yeti", Bestiary.YETI, 1)},
		{"title": "Caves and deserts", "sub": "Scorpions in the Sunscar Wastes; crystals deep in the caves.", "dur": 7.0,
			"at": _tc(Vector2i(74, 42)), "r": 6.0, "h": 4.0, "a0": 4.0, "a1": 5.0, "setup": _stage_fight.bind(Vector2i(74, 42), "Sand Scorpion", Bestiary.SAND_SCORPION, 2)},
		{"title": "Boats", "sub": "Cross the lakes, fish the deep water, sail to the Isle of Tides.", "dur": 8.0,
			"from": _tc(Vector2i(64, 16)) + Vector3(0, 7, 6), "to": _tc(Vector2i(74, 14)) + Vector3(0, 5, 5), "at": _tc(Vector2i(72, 11)), "setup": _stage_boat},
		{"title": "The Drunken Shard", "sub": "Ale, a hot meal, a room for the night - and rumours.", "dur": 6.0, "day": 0.8,
			"at": _tc(Vector2i(53, 36)), "r": 5.0, "h": 4.0, "a0": 0.8, "a1": 1.8, "setup": _stage_place.bind(Vector2i(53, 37))},
		{"title": "The Arena", "sub": "Fight champions for the purse. Bet on yourself.", "dur": 8.0, "day": 0.45,
			"at": _tc(Vector2i(19, 19)), "r": 5.5, "h": 3.5, "a0": 2.0, "a1": 3.3, "setup": _stage_fight.bind(Vector2i(19, 19), "Valka the Undefeated", Bestiary.WARRIOR, 1)},
		{"title": "Ravenhollow", "sub": "Graves, wisps, and a tomb that should stay shut.", "dur": 7.0, "day": 0.02,
			"at": _tc(Vector2i(87, 34)), "r": 9.0, "h": 7.0, "a0": 5.0, "a1": 6.0, "setup": _stage_fight.bind(Vector2i(87, 34), "Zombie", Bestiary.ZOMBIE, 2)},
		{"title": "The Church of the Shard", "sub": "Pray at the altar. The bell tolls at dawn.", "dur": 6.0, "day": 0.28,
			"at": _tc(Vector2i(26, 18)), "r": 6.5, "h": 6.0, "a0": 1.2, "a1": 2.0, "setup": _stage_place.bind(Vector2i(26, 18))},
		{"title": "Seasons and storms", "sub": "Spring to winter; rain, snow, thunder.", "dur": 7.0, "day": 0.5, "weather": "storm", "winter": true, "white": true,
			"at": _tc(Vector2i(30, 30)), "r": 18.0, "h": 13.0, "a0": 3.5, "a1": 4.3},
		{"title": "World bosses", "sub": "Now and then a giant wakes. The whole land comes to fight it.", "dur": 9.0, "day": 0.55, "weather": "clear", "white": true,
			"at": _tc(Vector2i(60, 26)), "r": 8.0, "h": 5.0, "a0": 0.2, "a1": 1.5, "setup": _stage_boss},
		{"title": "Your story", "sub": "Quests, bounties, guilds, a house, a horse, a boat. Begin.", "dur": 6.0,
			"at": _tc(Vector2i(24, 9)), "r": 30.0, "h": 26.0, "a0": 1.3, "a1": 1.9},
	]


func _tc(tile: Vector2i) -> Vector3:
	return world.tile_center(tile)


func _next() -> void:
	for a in _actors:
		if is_instance_valid(a) and not a.dead:
			a.vanish()
	_actors.clear()
	i += 1
	t = 0.0
	if i >= shots.size():
		finish()
		return
	if i > 0:                                           # every cut lands on a hit
		_sound("braam" if bool(shots[i].get("white", false)) or i % 4 == 0 else "impact", 1.0, 0.0)
	_riser_done = false
	var sh: Dictionary = shots[i]
	if sh.has("day"):
		game.day_time = float(sh["day"])
	if sh.has("weather"):
		game._set_weather(String(sh["weather"]))
	game.frontier._snow.emitting = bool(sh.get("snow", false))
	var gm: ShaderMaterial = world.ground_material
	if gm != null:
		gm.set_shader_parameter("snow", 0.8 if bool(sh.get("winter", false)) else 0.0)
	if sh.has("setup"):
		(sh["setup"] as Callable).call()
	_title.text = " ".join(String(sh["title"]).to_upper().split(""))   # spaced capitals
	_sub.text = String(sh["sub"])
	for l in [_title, _sub]:                            # the words slide in and fade up
		l.modulate.a = 0.0
		l.position.x = -40.0
		var tw: Tween = l.create_tween().set_parallel(true)
		tw.tween_property(l, "modulate:a", 1.0, 0.7).set_delay(0.4 if l == _title else 0.75)
		tw.tween_property(l, "position:x", 0.0, 0.9).set_delay(0.4 if l == _title else 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_rule.custom_minimum_size.x = 0.0
	_rule.create_tween().tween_property(_rule, "custom_minimum_size:x", 360.0, 1.0).set_delay(0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_counter.text = "%02d / %02d" % [i + 1, shots.size()]
	_fx.set_shader_parameter("leak", 1.0 if float(sh.get("day", 0.4)) > 0.2 and String(sh.get("weather", "clear")) != "storm" else 0.0)
	game.cam.fov = 60.0                                 # each scene starts wide and pushes in
	if bool(sh.get("white", false)):
		_flash = 1.0                                    # a cut through white
	else:
		_fade.modulate.a = 1.0                          # a dip to black between scenes
		_fade.create_tween().tween_property(_fade, "modulate:a", 0.0, 0.6)


## Runs the scene: films it and keeps the hero going. Returns false once the movie is over.
func tick(delta: float) -> bool:
	if not running:
		return false
	t += delta
	var sh: Dictionary = shots[i]
	var dur := float(sh["dur"])
	hero.hp = float(hero.stats.max_hp())                # the star can't die
	hero.mana = float(hero.stats.max_mana())
	hero.reagents = 60.0
	if bool(sh.get("magic", false)):
		_cast_acc += delta
		if _cast_acc >= 1.6:
			_cast_acc = 0.0
			_cast_something()
	# a spell landing: a flash, a shake and a moment of slow motion
	var casting := hero.casting_id != ""
	if _was_casting and not casting:
		_flash = maxf(_flash, 0.45)
		_shake = 0.35
		_slow = 0.5
		Engine.time_scale = 0.35
		Soundscape.slowmo = true                       # the world goes dull and far away...
		Soundscape.update("wilds", false, false)
		game.music.player.pitch_scale = 0.8
		_sound("impact", 0.7, 0.0)
	_was_casting = casting
	if _slow > 0.0:
		_slow -= delta / maxf(Engine.time_scale, 0.05)  # counted in real seconds
		if _slow <= 0.0:
			Engine.time_scale = 1.0
			Soundscape.slowmo = false                  # ...and snaps back
			game.music.player.pitch_scale = 1.0
	if not _riser_done and t >= dur - 1.2 and i < shots.size() - 1:
		_riser_done = true                              # a riser sweeps up into the next cut
		_sound("riser", 1.0, -4.0)
	_flash = maxf(_flash - delta * 2.5, 0.0)
	_fx.set_shader_parameter("flash", _flash)
	_shake = maxf(_shake - delta * 1.5, 0.0)
	var vs := get_viewport().get_visible_rect().size
	_progress.size.x = vs.x * (float(i) + clampf(t / dur, 0.0, 1.0)) / float(shots.size())
	var k := smoothstep(0.0, 1.0, clampf(t / dur, 0.0, 1.0))
	var cam: Camera3D = game.cam
	cam.fov = lerpf(60.0, 48.0, k)                      # a slow push in
	var look: Vector3 = sh["at"]
	if sh.has("from"):
		cam.position = (sh["from"] as Vector3).lerp(sh["to"], k)
	else:
		var a := lerpf(float(sh["a0"]), float(sh["a1"]), k)
		cam.position = look + Vector3(cos(a) * float(sh["r"]), float(sh["h"]), sin(a) * float(sh["r"]))
	cam.look_at(look + Vector3(0, 0.8, 0), Vector3.UP)
	if _shake > 0.0:
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.25
		cam.rotate_object_local(Vector3(0, 0, 1), randf_range(-1, 1) * _shake * 0.03)
	game.view_planes = cam.get_frustum()
	if t >= dur:
		_next()
	return running


func finish() -> void:
	if not running:
		return
	running = false
	Engine.time_scale = 1.0
	Soundscape.slowmo = false
	game.music.player.pitch_scale = 1.0
	_sound("braam", 0.85, 2.0)                          # the last hit, and the score fades under the logo
	game.create_tween().tween_property(game.music.player, "volume_db", -50.0, 4.0)
	game.skip_save = true
	_title.get_parent().visible = false
	_end_logo()
	var tw := _fade.create_tween()
	tw.tween_interval(3.2)
	tw.tween_property(_fade, "modulate:a", 1.0, 0.9)
	tw.tween_callback(game.restart_to_title)           # back to the title, to choose how to play


## The last card: SHARDSIGHT in gold, a band of light sweeping across it, sparks rising.
func _end_logo() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	move_child(dim, get_child_count() - 2)              # under the fade
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_card = CenterContainer.new()
	_end_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_end_card)
	move_child(_end_card, get_child_count() - 2)
	_end_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var logo := _label(110, Color(0.95, 0.8, 0.4))
	logo.text = "S H A R D S I G H T"
	var sweep := Shader.new()
	sweep.code = SWEEP_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sweep
	logo.material = sm
	_end_card.add_child(logo)
	logo.modulate.a = 0.0
	logo.create_tween().tween_property(logo, "modulate:a", 1.0, 1.0)
	var sparks := CPUParticles2D.new()
	sparks.amount = 60
	sparks.lifetime = 2.5
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(get_viewport().get_visible_rect().size.x / 2.0, 10)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 25.0
	sparks.initial_velocity_min = 60.0
	sparks.initial_velocity_max = 160.0
	sparks.gravity = Vector2.ZERO
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 4.0
	sparks.color = Color(1.0, 0.82, 0.4, 0.9)
	var vs := get_viewport().get_visible_rect().size
	sparks.position = Vector2(vs.x / 2.0, vs.y * 0.85)
	add_child(sparks)
	move_child(sparks, get_child_count() - 2)
	_flash = 0.0
	game.sound("gain", hero.position, 0.7, 2.0)


# --- staging -------------------------------------------------------------------------------------

func _put_hero(tile: Vector2i) -> void:
	hero.position = world.tile_center(tile)
	hero.path.clear()
	hero.target = null
	hero.has_journey = false
	hero.casting_id = ""
	hero.pause = 0.0
	if hero.mounted_on != null:
		hero.dismount()


func _stage_place(tile: Vector2i) -> void:
	_put_hero(tile)


func _stage_town() -> void:
	_put_hero(Vector2i(24, 12))


func _stage_fight(tile: Vector2i, foe_name: String, cfg: Dictionary, n: int) -> void:
	_put_hero(tile)
	for k in range(n):
		var c := cfg.duplicate(true)
		c["passive"] = false
		c["leash"] = 20
		c["aggro"] = 15.0
		var at := world.tile_center(tile) + Vector3(1.6 + k * 0.8, 0, 0.8 * (k - 0.5))
		var e: Entity = game.pool_spawn("%s " % foe_name if k > 0 else foe_name, c, Color(0.85, 0.3, 0.25), at)
		e.target = hero
		_actors.append(e)
	hero.target = _actors[0]


func _stage_magic() -> void:
	_stage_fight(Vector2i(14, 19), "Ogre", Bestiary.OGRE, 1)
	shots[i]["magic"] = true
	_cast_acc = 1.0


func _cast_something() -> void:
	var foe: Entity = null
	for a in _actors:
		if is_instance_valid(a) and not a.dead:
			foe = a
	if foe == null:
		return
	hero.casting_id = ""
	hero.cast_cd = 0.0
	var pick: String = ["fireball", "lightning", "flamestrike", "energy_bolt", "meteor_swarm", "chain_lightning"][randi() % 6]
	hero.start_cast(pick, foe)


func _stage_boat() -> void:
	_put_hero(Vector2i(66, 11))
	game.frontier.data["boat"] = true
	game.frontier._sail(2, false)


func _stage_boss() -> void:
	_put_hero(Vector2i(58, 26))
	var cfg := Bestiary.OGRE.duplicate(true)
	cfg["scale"] = 2.6
	cfg["str"] = 600
	cfg["danger"] = 12
	cfg["leash"] = 20
	cfg["aggro"] = 15.0
	var boss: Entity = game.pool_spawn("Tharok the World-Eater", cfg, Color(0.5, 0.35, 0.25), world.tile_center(Vector2i(61, 26)))
	boss.target = hero
	hero.target = boss
	_actors.append(boss)
	shots[i]["magic"] = true
	_cast_acc = 0.0
