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
const TRAILER_MUSIC_DB := 6.0          # the epic score louder than in the game
const CAST_EVERY := 2.8                # a spell this often in a fight; between them the hero fights with the blade
var _fight := []
const CAM_MOVES := ["orbit", "crane", "track", "spiral", "dolly", "orbit", "track", "crane"]
var _punch := 0.0
var _look_s := Vector3.INF             # where the camera looks, eased (it follows the hero)
var _runs := 0                         # runs from a blade in a row before a spell                      # a quick zoom on a heavy blow (fades)


## A heavy blow or a K.O.: the camera punches in for an instant.
func punch(amount := 1.0) -> void:
	if _punch_cd > 0.0 and amount <= _punch:
		return                         # (not one on top of another: a run of blows made it shake)
	_punch = maxf(_punch, amount)
	_punch_cd = 1.2


var _punch_cd := 0.0


# --- in time with the music ---------------------------------------------------------------
# The cuts, the flying words and the big blows land on the beat of the trailer's score (a beat
# every half second): a scene that has had its time cuts on the next half bar, each word flies in
# on one, and a heavy blow's punch-in waits for the beat if it's only a moment away.
const TRAILER_BEAT := 0.5              # (the "trailer" piece in music.gd)
var _beat_prev := -1
var _on_beat := false
var _on_half_bar := false
var _punch_pending := 0.0


## Beats since the score began, or -1 when it isn't playing (then nothing waits for it).
func _music_beat() -> float:
	var m = game.music
	if m == null or m.player == null or not m.player.playing or String(m._area) != "trailer":
		return -1.0
	return (m.player.get_playback_position() + AudioServer.get_time_since_last_mix()) / TRAILER_BEAT


## A heavy blow: its punch-in lands on the beat when the beat is close; otherwise at once.
func punch_on_beat(amount := 1.0) -> void:
	var b := _music_beat()
	if b >= 0.0 and (ceil(b) - b) * TRAILER_BEAT < 0.2:
		_punch_pending = maxf(_punch_pending, amount)
	else:
		punch(amount)


func _beat_step() -> float:
	var b := _music_beat()
	_on_beat = false
	_on_half_bar = false
	if b < 0.0:
		_beat_prev = -1
		return b
	var bi := int(floor(b))
	if bi != _beat_prev:
		_on_beat = _beat_prev >= 0
		_on_half_bar = _on_beat and bi % 2 == 0
		_beat_prev = bi
	if _on_beat and _punch_pending > 0.0:
		punch(_punch_pending)
		_punch_pending = 0.0
	return b


# --- hooks for the other trailers (short, phone format) --------------------------------------
func _min_lean() -> float:
	return 0.0                         # how far the camera always leans to the hero (phone: centred)


func _bar_frac() -> float:
	return 0.12                        # the letterbox bars, of the screen's height
var _words_box: Control                 # where the flying words appear (each fills the screen)
var _word_queue: Array = []
var _word_t := 0.0
var _word_n := 0                       # the scene's fight: [tile, foe name, cfg, count] (a new wave when it's won)
var _fx: ShaderMaterial            # grain, vignette, a light leak, the flash
var _rule: ColorRect               # the gold line under the title
var _progress: ColorRect
var _flash := 0.0
var _was_casting := false
var _slow := 0.0                   # real seconds of slow motion left
var _end_card: Control
var _spell_light: OmniLight3D           # the light of the hero's spells

# --- one colour grade for the whole trailer ---------------------------------------------------
# Every scene the same look: the same saturation and contrast, the same warm edge of light, and
# the brightness evened out - a scene at night, in a storm or at dusk is exposed up towards the
# brightness of a sunny one (keeping a little of its mood), so the trailer doesn't go dark and
# light from scene to scene. Put back as it was afterwards.
const GRADE_SATURATION := 0.92
const GRADE_CONTRAST := 1.14
const GRADE_EXPOSURE := 1.05         # (the game's own, in full daylight)
const LEAK := 0.4
var _expo := -1.0
var _spell_col := Color(0.7, 0.8, 1.0)
var _flare := 0.0
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
	float g = (hash(floor(uv * vec2(480.0, 270.0)) + floor(TIME * 24.0) * vec2(0.37, 0.71)) - 0.5) * 0.08;   // grain 24 times a second, as on film
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
	_snapshot()
	_was_rich = Art.rich
	game.set_rich_graphics(true)                       # the trailer shows the game at its best (put back after)
	# a clean screen: no buttons, log, stats or menus (over heads the fight shows in full: damage,
	# spell words, health and casting bars - the hero's too)
	if game.ui_layer != null:
		game.ui_layer.visible = false
	hero.show_name(false)                               # (the hero's name stays off; the fight's numbers, words and bars all show)
	# lighter, for a steady 60: the movie has its own vignette (the game's overlay goes), the camera
	# sees no further than the land, the 3D starts a little under full resolution on a phone
	if game._grade != null:
		game._grade.visible = false
	game.cam.far = 130.0
	game.sun.directional_shadow_max_distance = 28.0
	if OS.has_feature("mobile"):
		game._render_base = 0.8
		game._render_scale = 0.8
		game._scale_cap = 0.8
		get_viewport().scaling_3d_scale = 0.8
	_build_ui()
	game.property.names_on = false                      # no names over anyone's head (put back after)
	for e in game.creatures:
		e.show_name(false)
	var env: Environment = game.env
	_snap["grade"] = [env.tonemap_exposure, env.adjustment_enabled, env.adjustment_saturation, env.adjustment_contrast, env.adjustment_brightness]
	env.adjustment_enabled = true
	env.adjustment_saturation = GRADE_SATURATION
	env.adjustment_contrast = GRADE_CONTRAST
	env.adjustment_brightness = 1.0
	# the spell light: the hero's spells light them and the ground round them (best at night)
	_spell_light = OmniLight3D.new()
	_spell_light.light_energy = 0.0
	_spell_light.omni_range = 9.0
	_spell_light.shadow_enabled = false
	game.add_child(_spell_light)
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
	game.music.set_enabled(true)                        # the trailer always has its score (even with music off)
	game.music.play_area("trailer")                     # its own score: drums, brass, choir
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), TRAILER_MUSIC_DB)   # and up front
	for k in ["crickets", "water", "fire", "wind", "tavern", "crowd"]:
		game._amb_set(k, -80.0)                         # the ambience steps back
	_make_shots()
	seed(SEED)
	_warm_up()
	_intro_loading()


## The opening: the loading screen's own animation - the spinning Shard in its rings over the
## glowing hexagons, the bar filling as the lines type out - then it fades into the first scene.
var _intro: LoadingScreen


func _intro_loading() -> void:
	if "--trailer-video" in OS.get_cmdline_user_args() or "--trailer-video-2" in OS.get_cmdline_user_args():
		print("TRAILER_START_FRAME %d" % Engine.get_frames_drawn())   # (the video is cut from here: its opening included)
	_intro = LoadingScreen.new()
	add_child(_intro)
	_intro._root.mouse_filter = Control.MOUSE_FILTER_IGNORE   # (Skip stays in reach)
	_intro.step(0.18, "Waking the shard")
	var tw := create_tween()
	tw.tween_interval(0.6)
	tw.tween_callback(_intro.step.bind(0.45, "Raising the land"))
	tw.tween_interval(0.6)
	tw.tween_callback(_intro.step.bind(0.7, "Calling the heroes"))
	tw.tween_interval(0.6)
	tw.tween_callback(_intro.step.bind(0.92, "Rolling the trailer"))
	tw.tween_interval(0.6)
	tw.tween_callback(_begin)


## The first scene starts as the opening fades away.
func _begin() -> void:
	if running or _intro == null:
		return
	if is_instance_valid(_intro):
		_intro.finish()
	_intro = null
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
		bar.offset_top = 0.0 if top else -vs.y * _bar_frac()
		bar.offset_bottom = vs.y * _bar_frac() if top else 0.0
		_bars.append(bar)
	_title = _label(44, Color(0.95, 0.8, 0.42))
	_sub = _label(24, Color(0.85, 0.88, 0.95))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	col.add_child(_title)
	col.add_child(_sub)
	var margin := maxf(40.0, vs.x * 0.05)               # titles inside a safe margin on any screen
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.custom_minimum_size.x = minf(vs.x - margin * 2.0, 1100.0)
	col.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, int(margin))
	col.grow_vertical = Control.GROW_DIRECTION_BEGIN
	col.offset_top -= vs.y * _bar_frac()
	col.offset_bottom -= vs.y * _bar_frac()
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
	_extra_ui()
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
	_words_box = Control.new()                          # the flying words: each one as big as the screen
	_words_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_words_box)
	_words_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 1.0                              # black from the first frame (no flash of the title)
	add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# no Skip button, and taps anywhere do nothing: the trailer plays to its end
	var hold := Control.new()
	hold.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(hold)
	hold.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


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
# the long flight's state (used by MovieFlight, trailer 2; nothing here for the first trailer)
var _fly_dur := 0.0                    # seconds of flying into this place
var _fly_arc := 0.0
var _fly_from_pos := Vector3.ZERO
var _fly_from_look := Vector3.ZERO
var _look_last := Vector3.ZERO
var _delay := 0.0                      # how long after a place's start its talk and words begin


# --- hooks for the second trailer (MovieFlight overrides them; the first trailer leaves them be)
func _shape_shots() -> void:
	pass


func _extra_ui() -> void:
	pass


func _plan_scene(_sh: Dictionary) -> void:
	pass


func _continuous() -> bool:
	return false


func _redraw_extra() -> void:
	pass


func _make_shots() -> void:
	shots = [
		{"title": "SHARDSIGHT", "sub": "A world of swords, spells and skill.", "dur": 6.0, "no_hero": true, "day": 0.35, "weather": "clear",
			"at": _tc(Vector2i(32, 9)), "r": 20.0, "h": 17.0, "a0": 0.4, "a1": 1.3},
		{"title": "One world", "words": ["ONE VAST WORLD"], "sub": "Nine towns, eight wild lands, caves, a dungeon and an island - one land.", "dur": 7.0, "no_hero": true, "day": 0.42, "weather": "clear",
			"at": _tc(Vector2i(72, 72)), "r": 70.0, "h": 62.0, "a0": 0.7, "a1": 1.4, "cam": "reveal", "far": 420.0},
		{"title": "Living towns", "story": [["Elara", "\"Back again? Try not to die this time.\""], ["hero", "\"No promises.\""]], "words": ["LIVE IN THE TOWNS", "TRADE · BANK · HEAL"], "sub": "Healers, priests, merchants, bankers - and folk who keep their own days.", "dur": 6.0,
			"at": _tc(Vector2i(32, 10)), "r": 9.0, "h": 6.0, "a0": 2.4, "a1": 3.4, "setup": _stage_town},
		{"title": "Quests", "words": ["TAKE ON QUESTS", "GOLD · FAME · KARMA"], "sub": "Captain Marcus has work for a strong arm - and every town has someone in need.", "dur": 7.0, "day": 0.4, "stay": true, "cam": "orbit",
			"at": _tc(Vector2i(30, 13)), "r": 4.5, "h": 3.0, "a0": 0.9, "a1": 1.9,
			"setup": _stage_talk.bind(Quests.GIVER, Vector2i(31, 13), ["\"Orcs on the north road!\"", ">\"I'll see to it.\"", "\"Four of them. Bring me proof.\""])},
		{"title": "Bounties", "story": [["foe", "\"Grrrrr...\""], ["hero", "\"Nice price on your head, Grimfang.\""], ["hero", "\"Sorry. Nothing personal.\""]], "words": ["HUNT THE BOUNTIES", "NAMED BEASTS · RICH REWARDS"], "sub": "Every board posts a beast with a name and a price on its head.", "dur": 7.0, "day": 0.35,
			"at": _tc(Vector2i(14, 19)), "r": 8.5, "h": 7.5, "a0": 3.0, "a1": 4.2, "cam": "orbit", "follow": 0.85,
			"setup": _stage_fight.bind(Vector2i(14, 19), "Grimfang the Wolf", _elite(Bestiary.WOLF), 1)},   # (higher and wider: the hero stays in sight)
		{"title": "Fight", "story": [["foe", "\"Fresh meat!\""], ["hero", "\"Not today.\""], ["foe", "\"...ow.\""]], "words": ["MASTER THE BLADE", "EVERY WEAPON ITS OWN BLOW"], "sub": "Swords, axes, maces, spears, bows - and a different blow for each.", "dur": 8.0,
			"at": _tc(Vector2i(14, 19)), "r": 4.5, "h": 2.6, "a0": 0.0, "a1": 1.4, "setup": _stage_fight.bind(Vector2i(14, 19), "Orc", Bestiary.ORC, 2)},
		{"title": "Magic", "story": [["foe", "\"ME SMASH TINY HUMAN!\""], ["hero", "\"Stand back. This gets loud.\""]], "words": ["67 SPELLS", "SPEAK THE OLD WORDS"], "sub": "Sixty-seven spells in eight circles. Speak the old words.", "dur": 9.0, "white": true, "day": 0.03, "weather": "clear",
			"at": _tc(Vector2i(14, 19)), "r": 6.0, "h": 4.0, "a0": 1.4, "a1": 2.8, "setup": _stage_magic},
		{"title": "The dungeon's depths", "story": [["foe", "\"...clatter... clatter...\""], ["hero", "\"Who keeps leaving these doors open?\""]], "words": ["FIVE LEVELS DEEP", "EACH DARKER THAN THE LAST"], "sub": "Five levels down, each darker than the last.", "dur": 7.0,
			"at": _tc(Vector2i(11, 72)), "r": 7.0, "h": 6.5, "a0": 3.0, "a1": 4.2, "setup": _stage_fight.bind(Vector2i(12, 75), "Skeleton", Bestiary.SKELETON, 2)},
		{"title": "The Frostmarch", "story": [["hero", "\"It's freezing up here.\""], ["foe", "\"ROOOAAAR!\""], ["hero", "\"...and getting colder.\""]], "words": ["EXPLORE EVERY LAND", "SNOW · SAND · SWAMP · ASH"], "sub": "Biomes: snow, desert, swamp and ash - each with its own beasts.", "dur": 7.0, "snow": true,
			"at": _tc(Vector2i(71, 4)), "r": 7.0, "h": 5.0, "a0": 3.6, "a1": 4.6, "setup": _stage_fight.bind(Vector2i(71, 4), "Yeti", Bestiary.YETI, 1)},   # (filmed from the north: clear of the piers and their flags)
		{"title": "Caves and deserts", "story": [["hero", "\"Sand. Everywhere. Always.\""], ["foe", "\"Hsssss!\""], ["hero", "\"And scorpions. Of course.\""]], "words": ["DIG FOR TREASURE"], "sub": "Scorpions in the Sunscar Wastes; crystals deep in the caves.", "dur": 7.0,
			"at": _tc(Vector2i(74, 42)), "r": 6.0, "h": 4.0, "a0": 4.0, "a1": 5.0, "setup": _stage_fight.bind(Vector2i(74, 42), "Sand Scorpion", Bestiary.SAND_SCORPION, 2)},
		{"title": "Boats", "story": [["hero", "\"Ah, a quiet day on the lake...\""], ["hero", "\"...said no adventurer, ever.\""]], "words": ["SAIL THE LAKES", "FISH THE DEEP"], "sub": "Cross the lakes, fish the deep water, sail to the Isle of Tides.", "dur": 8.0,
			"from": _tc(Vector2i(64, 16)) + Vector3(0, 7, 6), "to": _tc(Vector2i(74, 14)) + Vector3(0, 5, 5), "at": _tc(Vector2i(72, 11)), "setup": _stage_boat, "stay": true},
		{"title": "The Drunken Shard", "story": [["Rosa the Barkeep", "\"What'll it be, hero?\""], ["hero", "\"Whatever's strongest.\""], ["Rosa the Barkeep", "\"They say the dead walk at Ravenhollow...\""]], "words": ["REST · EAT · LISTEN"], "sub": "Ale, a hot meal, a room for the night - and rumours.", "dur": 6.0, "day": 0.8,
			"at": _tc(Vector2i(53, 36)), "r": 5.0, "h": 4.0, "a0": 0.8, "a1": 1.8, "setup": _stage_place.bind(Vector2i(53, 37))},
		{"title": "The Arena", "story": [["foe", "\"Another challenger? Adorable.\""], ["hero", "\"Put your gold on me.\""], ["foe", "\"...lucky blow.\""]], "words": ["CHALLENGE CHAMPIONS", "BET ON YOURSELF"], "sub": "Fight champions for the purse. Bet on yourself.", "dur": 8.0, "day": 0.45,
			"at": _tc(Vector2i(89, 91)), "r": 5.5, "h": 3.5, "a0": 2.0, "a1": 3.3, "setup": _stage_fight.bind(Vector2i(89, 91), "Valka the Undefeated", Bestiary.WARRIOR, 1)},
		{"title": "Help the townsfolk", "words": ["EVERYONE HAS A STORY"], "sub": "Farmers, fishers, wardens and smiths - each with a task, and a reward.", "dur": 7.0, "day": 0.45, "stay": true, "cam": "orbit",
			"at": _tc(Vector2i(103, 106)), "r": 4.5, "h": 3.0, "a0": 4.0, "a1": 5.0,
			"setup": _stage_talk.bind("Warden Sela", Vector2i(104, 106), ["\"Bears on the southern roads...\"", ">\"Leave them to me.\"", "\"Five of them. Highmoor won't forget.\""])},
		{"title": "Ravenhollow", "story": [["foe", "\"Braaaains...\""], ["hero", "\"You'll be disappointed.\""]], "words": ["FACE THE DEAD"], "sub": "Graves, wisps, and a tomb that should stay shut.", "dur": 7.0, "day": 0.02,
			"at": _tc(Vector2i(103, 133)), "r": 9.0, "h": 10.5, "cam": "orbit", "a0": 5.0, "a1": 6.0, "setup": _stage_fight.bind(Vector2i(103, 133), "Zombie", Bestiary.ZOMBIE, 2)},
		{"title": "The Shattered Sight", "words": ["A STORY TO UNCOVER", "WHAT WAS TAKEN FROM YOU?"], "sub": "You wake with no memory. Father Corwin knows more than he says.", "dur": 8.0, "day": 0.28,
			"at": _tc(Vector2i(13, 129)), "r": 13.0, "h": 12.0, "a0": 1.2, "a1": 2.0, "stay": true, "cam": "orbit", "wide": true,
			"setup": _stage_talk.bind("Father Corwin", Vector2i(12, 129), ["\"You saw something you shouldn't have.\"", ">\"I remember nothing...\"", "\"Then we'll find it again - together.\""])},
		{"title": "Seasons and storms", "story": [["hero", "\"Lovely weather for it.\""], ["hero", "\"Is it always winter when I'm out?\""]], "words": ["THE SEASONS TURN"], "sub": "Spring to winter; rain, snow, thunder.", "dur": 7.0, "day": 0.5, "weather": "storm", "winter": true,
			"at": _tc(Vector2i(30, 30)), "r": 14.0, "h": 11.0, "a0": 3.5, "a1": 4.3},
		{"title": "World bosses", "no_run": true, "story": [["foe", "\"I AM THAROK, THE WORLD-EATER!\""], ["hero", "\"You'll need a bigger appetite.\""], ["foe", "\"...urk.\""]], "words": ["SLAY THE GIANTS", "TOGETHER"], "sub": "Now and then a giant wakes. The whole land comes to fight it.", "dur": 9.0, "day": 0.55, "weather": "clear", "white": true,
			"at": _tc(Vector2i(60, 26)), "r": 8.0, "h": 5.0, "a0": 0.2, "a1": 1.5, "setup": _stage_boss},
		{"title": "Your story", "story": [["hero", "\"So... where do I begin?\""], ["hero", "\"Anywhere. Everywhere.\""]], "words": ["YOUR LEGEND", "BEGINS NOW"], "sub": "Quests, bounties, guilds, a house, a horse, a boat. Begin.", "dur": 6.0,
			"at": _tc(Vector2i(32, 9)), "r": 22.0, "h": 19.0, "a0": 1.3, "a1": 1.9},
	]
	_shape_shots()
	# each scene's camera move, fixed by its place in the list without the land's reveal (so
	# adding the reveal didn't change how any other scene is filmed)
	var n := 0
	for sh: Dictionary in shots:
		if String(sh["title"]) == "One world":
			continue
		if not sh.has("cam"):
			sh["cam"] = CAM_MOVES[n % CAM_MOVES.size()]
		n += 1


func _tc(tile: Vector2i) -> Vector3:
	return world.tile_center(tile)


func _next() -> void:
	for a in _actors:
		if is_instance_valid(a) and not a.dead:
			a.vanish()
	_actors.clear()
	i += 1
	t = 0.0
	_fight = []
	_word_queue = []
	if i >= shots.size():
		finish()
		return
	if i > 0 and (bool(shots[i].get("white", false)) or i % 4 == 0):   # the big cuts land on a low swell
		_sound("braam", 1.0, 0.0)
	_riser_done = false
	seed(SEED + i * 7919)                               # (each scene plays out the same every time)
	_finish_sent = false
	var sh: Dictionary = shots[i]
	_fly_dur = 0.0
	_delay = 0.0
	_plan_scene(sh)
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
	_tell(sh.get("story", []) as Array)
	hero.visible = not bool(sh.get("no_hero", false))
	hero.ai_enabled = not bool(sh.get("stay", false))   # in the church the hero stands still, inside
	if not hero.ai_enabled:
		hero.path.clear()
		hero.target = null
	_plan_camera(sh)                                    # the clearest way round the hero, chosen first
	for k in range(_actors.size()):                     # the foes on the far side, facing the camera
		var a := _actors[k]
		if is_instance_valid(a) and not a.dead and not _fight.is_empty():
			a.position = _foe_spot(k, _actors.size())
	_clear_stage(sh)                                    # and nobody else walks into the shot
	_title.text = " ".join(String(sh["title"]).to_upper().split(""))   # spaced capitals
	if _open_title != null and is_instance_valid(_open_title):
		_open_title.fade_out(0.5)
		_open_title = null
	if i == 0:                                          # the opening shot: the name in 3D, in the middle
		_title.text = ""
		var cc := CenterContainer.new()
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(cc)
		move_child(cc, _fade.get_index())               # under the fade
		cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cc.offset_bottom = -get_viewport().get_visible_rect().size.y * 0.28   # high, like the loading screen's: the words below
		_open_title = Title3D.make("SHARDSIGHT", minf(get_viewport().get_visible_rect().size.x * 0.98, 1900.0), 1.4)
		cc.add_child(_open_title)
	_sub.text = String(sh["sub"])
	for l in [_title, _sub]:                            # the words slide in and fade up
		l.modulate.a = 0.0
		l.position.x = -40.0
		var tw: Tween = l.create_tween().set_parallel(true)
		tw.tween_property(l, "modulate:a", 1.0, 0.7).set_delay(0.4 if l == _title else 0.75)
		tw.tween_property(l, "position:x", 0.0, 0.9).set_delay(0.4 if l == _title else 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_rule.custom_minimum_size.x = 0.0
	_rule.create_tween().tween_property(_rule, "custom_minimum_size:x", 360.0, 1.0).set_delay(0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_word_queue = (sh.get("words", []) as Array).duplicate()
	_word_t = 1.0 + _delay                              # the first word a moment after the cut (or the landing)
	if "--movie-test" in OS.get_cmdline_user_args():
		print("MOVIE scene %d: %s (hero at %s)" % [i + 1, sh["title"], world.to_tile(hero.position)])
	_fx.set_shader_parameter("leak", LEAK)                # (the same warm edge in every scene: one look throughout)
	game.cam.fov = 60.0                                 # each scene starts wide and pushes in
	if i == 0:
		# the very start: no flash and no blink - the picture simply rises out of black
		_flash = 0.0
		_fx.set_shader_parameter("flash", 0.0)
		_fx.set_shader_parameter("leak", 0.0)
		create_tween().tween_method(func(v: float) -> void: _fx.set_shader_parameter("leak", v), 0.0, LEAK, 1.4)
		_fade.modulate.a = 1.0
		_fade.create_tween().tween_property(_fade, "modulate:a", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	elif not _continuous():                             # (no cuts through white: every cut dips to black)
		_fade.modulate.a = 1.0                          # a dip to black between scenes
		_fade.create_tween().tween_property(_fade, "modulate:a", 0.0, 0.6)
	# (the long flight never cuts: no dip at all)


## The brightness evened out: how strongly the land is lit now (the sun and the sky's light, as the
## game sets them from the time of day and the weather), against full daylight.
func _grade_step(delta: float) -> void:
	var lit := clampf(float(game._lit), 0.0, 1.0)
	var now := lerpf(0.42, 0.6, lit) + 0.5 * lerpf(0.3, 1.35, lit)
	var full := 0.6 + 0.5 * 1.35
	var want := clampf(GRADE_EXPOSURE * pow(full / maxf(now, 0.1), 0.8), GRADE_EXPOSURE, 2.0)
	if _expo < 0.0 or (t < 0.05 and not _continuous()):
		_expo = want                                     # (at a cut: at once, under the dip to black)
	_expo = lerpf(_expo, want, 1.0 - exp(-delta * 1.5))  # (on the long flight: gliding)
	(game.env as Environment).tonemap_exposure = _expo


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
	var beat := _beat_step()
	# the explanation: big 3D words, one after another, flying in and past (each on a half bar)
	if not _word_queue.is_empty():
		_word_t -= delta / maxf(Engine.time_scale, 0.05)
		if _word_t <= 0.0 and (beat < 0.0 or _on_half_bar or _word_t < -1.2):
			_word_t = 2.4
			var w := String(_word_queue.pop_front())
			_word_n += 1
			var screen := get_viewport().get_visible_rect().size
			var word := Title3D.make_flying(w, minf(screen.x * 0.75, 1100.0),
				Title3D.GOLD if _word_n % 2 == 1 else Title3D.ICE, screen)
			_words_box.add_child(word)                     # the whole screen: its flight is never cut off
			word.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			# (no sound for the word flying in or out; only the trailer's music and its brass cuts)
	_script_fight(dur)
	if not _fight.is_empty() and t < dur - 2.0:
		var standing := false
		for a in _actors:
			if is_instance_valid(a) and not a.dead:
				standing = true
				break
		if not standing:
			Fx.sparkle(game, hero.position + Vector3(0, 0.8, 0), Color(1.0, 0.8, 0.4), 30)
			_spawn_wave()                               # more of them!
	if bool(sh.get("magic", false)):
		_cast_acc += delta
		if _cast_acc >= float(sh.get("cast_every", CAST_EVERY)):
			_cast_acc = 0.0
			_cast_something()
	# a spell landing: a flash and a moment of slow motion (the camera stays steady)
	var casting := hero.casting_id != ""
	if _was_casting and not casting:
		_slow = 0.5
		Soundscape.slowmo = true                       # the world goes dull and far away...
		Soundscape.update("wilds", false, false)
		game.music.player.pitch_scale = 0.8
	if _spell_light != null:
		var want := 0.0
		if casting:
			want = 2.2 + 0.4 * sin(t * 14.0)            # the spell gathering in the hero's hands
		if _flare > 0.0:
			want = maxf(want, 7.0 * _flare)            # and flaring as it flies
			_flare = maxf(_flare - delta * 2.2, 0.0)
		_spell_light.light_energy = lerpf(_spell_light.light_energy, want, 1.0 - exp(-delta * 9.0))
		_spell_light.light_color = _spell_col
		_spell_light.position = hero.position + Vector3(0.0, 1.6, 0.0)
		_spell_light.visible = hero.visible and _spell_light.light_energy > 0.02
	if _was_casting and not casting:
		_flare = 1.0
	_was_casting = casting
	# (the slow motion eases in and out, never snaps: a sudden change of speed made the camera
	# and everyone in the picture lurch)
	var real := delta / maxf(Engine.time_scale, 0.05)  # real seconds
	if _slow > 0.0:
		_slow -= real
		Engine.time_scale = move_toward(Engine.time_scale, 0.35, real * 5.0)
		if _slow <= 0.0:
			Soundscape.slowmo = false                  # ...and comes back
			game.music.player.pitch_scale = 1.0
	elif Engine.time_scale < 1.0:
		Engine.time_scale = move_toward(Engine.time_scale, 1.0, real * 2.5)
	if not _riser_done and t >= dur - 1.2 and i < shots.size() - 1:
		_riser_done = true                              # a riser sweeps up into the next cut
		_sound("riser", 1.0, -4.0)
	_flash = maxf(_flash - delta * 2.5, 0.0)
	_fx.set_shader_parameter("flash", _flash)
	var vs := get_viewport().get_visible_rect().size
	_progress.size.x = vs.x * (float(i) + clampf(t / dur, 0.0, 1.0)) / float(shots.size())
	var k := smoothstep(0.0, 1.0, clampf(t / dur, 0.0, 1.0))
	_grade_step(delta)
	var cam: Camera3D = game.cam
	cam.fov = lerpf(60.0, 48.0, k)                      # a slow push in
	cam.far = float(sh.get("far", 130.0))               # (the whole land in sight only where a scene asks for it)
	var look: Vector3 = sh["at"]
	# the camera follows the hero: it looks at a point between the scene's centre and the hero,
	# leaning all the way to the hero if they slip out of the frame - so the hero never leaves it
	if hero.visible and not bool(sh.get("no_hero", false)):
		var lean := maxf(float(sh.get("follow", 0.6)), _min_lean())
		if not cam.is_position_in_frustum(hero.position + Vector3(0.0, 1.0, 0.0)):
			lean = 1.0
		var want: Vector3 = look.lerp(hero.position, lean)
		if t < 0.05 or _look_s == Vector3.INF:
			_look_s = want
		_look_s = _look_s.lerp(want, 1.0 - exp(-delta * (6.0 if lean >= 1.0 else 3.0)))
		look = _look_s
	if sh.has("line"):
		# the long line over the whole map: gliding from one end of the land to the other,
		# looking ahead along the way
		var la: Vector3 = sh["line"][0]
		var lb: Vector3 = sh["line"][1]
		var lh := float(sh.get("line_h", 24.0))
		cam.position = la.lerp(lb, k) + Vector3(0.0, lh, 0.0)
		look = la.lerp(lb, minf(k + 0.12, 1.0))
	elif sh.has("from"):
		cam.position = (sh["from"] as Vector3).lerp(sh["to"], k)
	else:
		var a := lerpf(float(sh["a0"]), float(sh["a1"]), k)
		var r := float(sh["r"])
		var h := float(sh["h"])
		# each scene its own camera move (they take turns), so no two scenes are filmed alike
		match String(sh.get("cam", CAM_MOVES[i % CAM_MOVES.size()])):
			"crane":                                    # starts low among them, rises up and over
				h = lerpf(maxf(h * 0.25, 1.2), h * 1.5, k)
				r = lerpf(r * 0.8, r * 1.1, k)
			"spiral":                                   # circles faster and closes in, descending
				a = lerpf(float(sh["a0"]), float(sh["a0"]) + (float(sh["a1"]) - float(sh["a0"])) * 2.4, k)
				r = lerpf(r * 1.3, r * 0.7, k)
				h = lerpf(h * 1.4, h * 0.7, k)
			"track":                                    # low behind the hero, following the fight
				r *= 0.75
				h = maxf(h * 0.45, 1.3)
			"reveal":                                   # rising high over the land until all of it is in sight
				h = lerpf(h * 0.45, h * 1.35, k)
				r = lerpf(r * 0.55, r * 1.15, k)
			"dolly":                                    # the dolly zoom: pulls back as the lens closes in
				r = lerpf(r * 0.7, r * 1.5, k)
				cam.fov = lerpf(70.0, 34.0, k)
		cam.position = look + Vector3(cos(a) * r, h, sin(a) * r)
	# a fight opens tight on the hero - close, from the scene's side, just above them - and pulls
	# back to show the whole fight
	if bool(sh.get("hero_intro", false)) and hero.visible and t < 1.9 and not _continuous():
		var w := 1.0 - smoothstep(0.5, 1.9, t)
		var side := cam.position - hero.position
		side.y = 0.0
		if side.length() < 0.01:
			side = Vector3(0, 0, 1)
		var close := hero.position + side.normalized() * 3.0 + Vector3(0.0, CAM_ABOVE_HERO + 0.4, 0.0)
		cam.position = cam.position.lerp(close, w)
		look = look.lerp(hero.position, w)
		cam.fov = lerpf(cam.fov, 50.0, w)
	# the long flight: from where the camera was, up in an arc and down into this place
	if _fly_dur > 0.0 and t < _fly_dur:
		var fk := smoothstep(0.0, 1.0, t / _fly_dur)
		cam.position = _fly_from_pos.lerp(cam.position, fk) + Vector3(0.0, sin(PI * fk) * _fly_arc, 0.0)
		look = _fly_from_look.lerp(look, fk)
	# keep the hero in sight: if a wall, a house, a tree or a rock stands between the camera and
	# the hero (or what it films), rise and close in - smoothly - until the view is clear, then
	# ease back; and never sink into the ground or sit inside anything solid
	var see_hero: bool = hero.visible and not bool(sh.get("no_hero", false))
	# close on the hero: never high overhead nor far off - a little way out and a little above
	# (scenes marked "wide", like the whole church, keep their own framing; so do flights)
	var band := 0.0
	if see_hero and not bool(sh.get("wide", false)):
		band = 1.0
		if _fly_dur > 0.0 and t < _fly_dur:
			band = smoothstep(0.6, 1.0, t / _fly_dur)
	if band > 0.0:
		var off := cam.position - hero.position
		var flat := Vector2(off.x, off.z)
		if flat.length() < 0.01:
			flat = Vector2(0.0, 1.0)
		flat = flat.normalized() * clampf(flat.length(), CAM_NEAR, CAM_FAR)
		var held := hero.position + Vector3(flat.x, clampf(off.y, CAM_ABOVE_HERO, CAM_HIGH), flat.y)
		cam.position = cam.position.lerp(held, band)
	var subject: Vector3 = (hero.position + Vector3(0.0, 1.0, 0.0)) if see_hero else look + Vector3(0.0, 0.8, 0.0)
	# (it rises quickly when blocked, but comes down only once the view has stayed clear a while -
	# no bobbing up and down at the edge of a wall)
	if _view_blocked(cam.position, subject) or _inside_solid(cam.position):
		_occl = move_toward(_occl, 1.0, delta * 1.2)
		_clear_for = 0.0
	else:
		_clear_for += delta
		if _clear_for > 1.2:
			_occl = move_toward(_occl, 0.0, delta * 0.3)
	if _occl > 0.0:
		var ease_k := _occl * _occl * (3.0 - 2.0 * _occl)
		cam.position = cam.position.lerp(subject, 0.6 * ease_k) + Vector3(0.0, 1.2 * ease_k, 0.0)   # (closer in, barely up)
	# always a good height above the hero, so it is never filmed from below or at a crouch - and,
	# close on the hero, never far up either
	if see_hero:
		cam.position.y = maxf(cam.position.y, hero.position.y + CAM_ABOVE_HERO)
		if band > 0.0:
			cam.position.y = minf(cam.position.y, hero.position.y + CAM_HIGH + 1.2 * _occl + 30.0 * (1.0 - band))
	cam.position.y = maxf(cam.position.y, world.height_at(cam.position) + 1.3)
	# and if the hero is getting near the edge of the picture, turn (gently) towards them
	if see_hero:
		var sp := cam.unproject_position(hero.position + Vector3(0.0, 1.0, 0.0)) if not cam.is_position_behind(hero.position) else Vector2(-1.0, -1.0)
		var vsz := get_viewport().get_visible_rect().size
		var edge := sp.x < vsz.x * 0.15 or sp.x > vsz.x * 0.85 or sp.y < vsz.y * 0.18 or sp.y > vsz.y * 0.82
		_edge_k = move_toward(_edge_k, 1.0 if edge else 0.0, delta * (2.5 if edge else 0.8))
		look = look.lerp(hero.position, 0.5 * _edge_k)
	# no jitter: the camera and its aim glide towards where they want to be, instead of copying
	# every shuffle of the hero and every bump of the ground (at a cut, they start right there)
	if _cam_s == Vector3.INF or (t < 0.05 and _fly_dur <= 0.0 and not _continuous()):
		_cam_s = cam.position
		_aim_s = look
	_cam_s = _cam_s.lerp(cam.position, 1.0 - exp(-delta * 4.0))
	_aim_s = _aim_s.lerp(look, 1.0 - exp(-delta * 5.0))
	# the lowest it may go (above the hero, above the ground) - eased too, so a step of the hero
	# or a bump in the ground under the camera doesn't jolt it; and never into the ground
	var floor_y := world.height_at(_cam_s) + 1.3
	if see_hero:
		floor_y = maxf(floor_y, hero.position.y + CAM_ABOVE_HERO)
	if _floor_s == -INF or (t < 0.05 and _fly_dur <= 0.0 and not _continuous()):
		_floor_s = floor_y
	_floor_s = lerpf(_floor_s, floor_y, 1.0 - exp(-delta * 3.0))
	_cam_s.y = maxf(_cam_s.y, maxf(_floor_s, world.height_at(_cam_s) + 0.6))
	cam.position = _cam_s
	look = _aim_s
	_look_last = look
	_redraw_extra()
	# a little life in the hand-held camera, and a punch-in on a big blow
	cam.position += Vector3(sin(t * 1.7) * 0.06, sin(t * 2.3) * 0.04, cos(t * 1.3) * 0.06)
	_punch = maxf(_punch - delta * 3.0, 0.0)
	_punch_cd = maxf(_punch_cd - delta, 0.0)
	_punch_s = lerpf(_punch_s, _punch, 1.0 - exp(-delta * 10.0))   # (the punch-in eases in: no jolt)
	cam.fov -= _punch_s * 5.0
	cam.look_at(look + Vector3(0, 0.8, 0), Vector3.UP)
	cam.rotate_object_local(Vector3(0, 0, 1), sin(t * 0.6) * 0.035 * (1.0 if i % 2 == 0 else -1.0))   # a gentle dutch tilt
	game.view_planes = cam.get_frustum()
	if t >= dur and (beat < 0.0 or _on_half_bar or t >= dur + 1.2):
		_next()                                         # (on the beat)
	return running


func finish(skipped := false) -> void:
	if _intro != null:                                   # Skip during the opening
		if is_instance_valid(_intro):
			_intro.queue_free()
		_intro = null
		running = true
	if not running:
		return
	running = false
	Engine.time_scale = 1.0
	Soundscape.slowmo = false
	game.music.player.pitch_scale = 1.0
	game.skip_save = true
	_title.get_parent().visible = false
	var tw := _fade.create_tween()
	if skipped:                                         # Skip: straight back, a quick dip to black
		tw.tween_property(_fade, "modulate:a", 1.0, 0.35)
		tw.tween_callback(_back_to_title)
		return
	_sound("braam", 0.85, 2.0)                          # the last hit, and the score fades under the logo
	_music_fade = game.create_tween()
	_music_fade.tween_property(game.music.player, "volume_db", -50.0, 4.0)
	_end_logo()
	tw.tween_interval(3.2)
	tw.tween_property(_fade, "modulate:a", 1.0, 0.9)
	tw.tween_callback(_back_to_title)                   # back to the title, to choose how to play (no reload)


var _music_fade: Tween
var _open_title: Title3D


# --- leaving the movie without reloading the game -----------------------------------------------

var _snap := {}


## Everything the movie changes, as it was before (the hero, the clock, the weather, the records).
func _snapshot() -> void:
	_snap = {
		"skills": hero.stats.skills.duplicate(), "str": hero.stats.strength, "dex": hero.stats.dexterity, "int": hero.stats.intelligence,
		"spellbook": hero.spellbook.duplicate(), "weapon": hero.weapon, "armor": hero.armor_id, "shield": hero.shield_id,
		"gold": hero.gold, "inventory": hero.inventory.duplicate(true), "reagents": hero.reagents, "bandages": hero.bandages,
		"hp": hero.hp, "mana": hero.mana, "pos": hero.position, "fame": hero.fame, "karma": hero.karma,
		"ai": hero.ai_enabled, "roam": hero.roam_timer, "day": game.day_time, "weather": game.weather,
		"skip_save": game.skip_save, "auto_wait": game.frontier._auto_wait, "boat": game.frontier.data.get("boat", false),
		"property": game.property.to_dict(), "counters": game.counters.duplicate(true),
		"snow": (world.ground_material.get_shader_parameter("snow") if world.ground_material != null else 0.0),
	}


var _was_rich := false


func _restore() -> void:
	_release_stage()
	randomize()                                         # (the game's own chance again)
	game.set_rich_graphics(_was_rich)
	var f = game.frontier
	if not f.sail.is_empty():                           # skipped out on the lake: back to the shore
		f.sail = {}
		f._sail_node.visible = false
	for a in _actors:
		if is_instance_valid(a) and not a.dead:
			a.vanish()
	_actors.clear()
	if hero.form != "":
		hero.form_timer = 0.0
	hero.stats.skills = _snap["skills"]
	hero.stats.strength = _snap["str"]
	hero.stats.dexterity = _snap["dex"]
	hero.stats.intelligence = _snap["int"]
	hero.spellbook = _snap["spellbook"]
	hero.weapon = _snap["weapon"]
	hero.armor_id = _snap["armor"]
	hero.shield_id = _snap["shield"]
	hero.gold = _snap["gold"]
	hero.inventory = _snap["inventory"]
	hero.reagents = _snap["reagents"]
	hero.bandages = _snap["bandages"]
	hero.fame = _snap["fame"]
	hero.karma = _snap["karma"]
	hero.casting_id = ""
	hero.target = null
	hero.path.clear()
	hero.position = _snap["pos"]
	hero.hp = minf(float(_snap["hp"]), float(hero.stats.max_hp()))
	hero.mana = minf(float(_snap["mana"]), float(hero.stats.max_mana()))
	hero.ai_enabled = _snap["ai"]
	hero.roam_timer = _snap["roam"]
	hero.visible = true
	hero.refresh_look()
	game.day_time = _snap["day"]
	game._set_weather(String(_snap["weather"]))
	game.skip_save = _snap["skip_save"]
	f._auto_wait = _snap["auto_wait"]
	f.data["boat"] = _snap["boat"]
	f._snow.emitting = false
	if world.ground_material != null:
		world.ground_material.set_shader_parameter("snow", _snap["snow"])
	game.property.load_dict(_snap["property"])
	game.counters = _snap["counters"]
	Engine.time_scale = 1.0
	Soundscape.slowmo = false
	game.music.player.pitch_scale = 1.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), 0.0)
	_fight = []


## The end, or Skip: everything put back as it was, and the title with its mode buttons again -
## the world stays loaded.
func _back_to_title() -> void:
	running = false
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	if _end_card != null:
		_end_card.visible = false
	_restore()
	if _snap.has("grade"):
		var env: Environment = game.env
		var g: Array = _snap["grade"]
		env.tonemap_exposure = g[0]
		env.adjustment_enabled = g[1]
		env.adjustment_saturation = g[2]
		env.adjustment_contrast = g[3]
		env.adjustment_brightness = g[4]
	if _spell_light != null and is_instance_valid(_spell_light):
		_spell_light.queue_free()
	_spell_light = null
	game.movie_ended()
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
	if "--trailer-video" in OS.get_cmdline_user_args() or "--trailer-video-2" in OS.get_cmdline_user_args():
		print("TRAILER_END_FRAME %d" % Engine.get_frames_drawn())
		game.get_tree().create_timer(0.2).timeout.connect(game.get_tree().quit)   # the recording ends with it


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
	_end_card.offset_bottom = -get_viewport().get_visible_rect().size.y * 0.28   # the name high, as on the loading screen
	# the version under it (so a recording of the trailer shows which version it is)
	var ver := _label(22, Color(0.75, 0.8, 0.9, 0.85))
	ver.text = "v" + String(ProjectSettings.get_setting("application/config/version", ""))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(ver)
	move_child(ver, get_child_count() - 2)
	ver.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	ver.offset_top = -get_viewport().get_visible_rect().size.y * 0.3
	ver.offset_left = -200.0
	ver.offset_right = 200.0
	ver.modulate.a = 0.0
	ver.create_tween().tween_property(ver, "modulate:a", 1.0, 1.2).set_delay(0.6)
	var logo := Title3D.make("SHARDSIGHT", minf(get_viewport().get_visible_rect().size.x * 0.98, 1900.0), 1.2)
	_end_card.add_child(logo)                           # the name in 3D: gold, glowing, the light sweeping across
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
	sparks.position = Vector2(vs.x / 2.0, vs.y * 0.62)   # rising from just under the name
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


## A scene of talk: the hero beside someone, the two facing each other, and their lines rising
## over their heads one after another (a line starting with ">" is the hero's).
func _stage_talk(npc_name: String, hero_tile: Vector2i, lines: Array) -> void:
	_put_hero(hero_tile)
	var npc: Entity = null
	for e in game.creatures:
		if e.display_name == npc_name and not e.dead:
			npc = e
			break
	if npc != null:
		hero._face(npc.position - hero.position)
		npc._face(hero.position - npc.position)
	for k in range(lines.size()):
		var line := String(lines[k])
		if line.begins_with(">"):
			continue                                    # (no sentences over the hero's head)
		var who: Entity = npc
		if who == null:
			continue
		var say := line.trim_prefix(">")
		var col := Color(0.7, 0.88, 1.0) if who == hero else Color(1.0, 0.92, 0.6)
		get_tree().create_timer(0.9 + _delay + k * 1.8).timeout.connect(func() -> void:
			if running and is_instance_valid(who):
				who._pop(say, col))


## The scene's little story: its lines rise one after another over whoever says them - "hero",
## "foe" (the first of the scene's foes still standing), or someone by name (gold) - the hero's in
## blue, the foes' in red.
func _tell(lines: Array) -> void:
	var said := 0
	for k in range(lines.size()):
		var who_name := String(lines[k][0])
		if who_name == "hero":
			continue                                    # (no sentences over the hero's head)
		var say := String(lines[k][1])
		var scene := i
		said += 1
		get_tree().create_timer(1.0 + _delay + (said - 1) * 1.9).timeout.connect(func() -> void:
			if not running or i != scene:
				return                                  # (the scene has moved on)
			var who: Entity = null
			var col := Color(1.0, 0.92, 0.6)
			if who_name == "hero":
				who = hero
				col = Color(0.7, 0.88, 1.0)
			elif who_name == "foe":
				col = Color(1.0, 0.55, 0.45)
				for a in _actors:
					if is_instance_valid(a) and not a.dead:
						who = a
						break
			else:
				for e in game.creatures:
					if e.display_name == who_name and not e.dead:
						who = e
						break
			if who != null and is_instance_valid(who):
				who._pop(say, col))


# --- the hero's moves: sword combos and casting flourishes -------------------------------------

var _combo := 0
var _cast_n := 0
var _side := 1.0
const COMBO_NAMES := ["SLASH", "BACKHAND", "DRIVING BLOW", "FINISHER"]


## Each blow of the hero's sword is the next step of a four-step combo, each with its own move:
## a slash with a quick side-step, a backhand, a driving blow with a half step in, and a finisher
## with one clean turn (the camera punches in). The move's name rises over the foe that takes it.
func on_hero_strike(foe: Entity) -> void:
	var step := _combo % 4
	_combo += 1
	match step:
		0:                                               # slash, then a side-step round the foe
			if hero_holds_ground():
				foe._pop(String(COMBO_NAMES[step]), Color(1.0, 0.9, 0.5))
				return
			_side = -_side
			var to := foe.position - hero.position
			to.y = 0.0
			if to.length() > 0.01:
				var perp := Vector3(-to.z, 0.0, to.x).normalized() * _side
				var dest := hero.position + perp * 1.0
				if not world.is_blocked(world.to_tile(dest)):
					hero.create_tween().tween_property(hero, "position", dest, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		1:                                               # the backhand: the swing itself is the move
			pass
		2:                                               # a driving blow: a half step in behind it
			var to2 := foe.position - hero.position
			to2.y = 0.0
			var dest2 := hero.position + to2.normalized() * 0.35
			if to2.length() > 1.2 and not world.is_blocked(world.to_tile(dest2)) and not hero_holds_ground():
				hero.create_tween().tween_property(hero, "position", dest2, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			punch_on_beat(0.3)
		3:                                               # the finisher: one clean turn through the foe
			_spin(hero, 0.5, 1.0)
			punch_on_beat(0.6)
			Fx.sparkle(game, foe.position + Vector3(0.0, 1.0, 0.0), Color(1.0, 0.85, 0.35), 30)
	foe._pop(String(COMBO_NAMES[step]), [Color(1.0, 0.9, 0.5), Color(0.6, 0.9, 1.0), Color(1.0, 0.6, 0.3), Color(1.0, 0.45, 0.85)][step])


## Against the giant, blows are struck from the size of the two apart (the hero no longer stands
## inside the giant, sword through its legs, both shuffling to keep in reach).
func melee_extra(e: Entity) -> float:
	if not hero_holds_ground():
		return 0.0
	var x := maxf(e.visual_scale - 1.0, 0.0) * 0.6
	if e.target != null and is_instance_valid(e.target):
		x += maxf(e.target.visual_scale - 1.0, 0.0) * 0.6
	return x


## The hero takes the giant's blows standing: no squash, hop or punch-in on each one (they came
## every second and shook the hero, sword and all, and the camera with them).
func calm_hits(e: Entity) -> bool:
	return e == hero and hero_holds_ground()


## In a scene marked "no_run" (the giant), the hero stands and fights: no stepping back from the
## foe and no side-steps round it, which against a big foe that keeps closing in played as the
## same little move over and over (a jitter).
func hero_holds_ground() -> bool:
	return i >= 0 and i < shots.size() and bool(shots[i].get("no_run", false))


## As a spell begins, the hero moves with it, in turn: rising into the air, a twirl, a hop back.
func _cast_flourish() -> void:
	var kind := _cast_n % 3
	_cast_n += 1
	match kind:
		0:                                               # rises, held aloft while the words are spoken
			var tw := _new_tween(hero, "lift_tw")
			tw.tween_property(hero, "anim_lift", 0.55, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.7)
			tw.tween_property(hero, "anim_lift", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		1, 2:                                            # (no twirls or hops: a steady stance, a lesser rise)
			var tw2 := _new_tween(hero, "lift_tw")
			tw2.tween_property(hero, "anim_lift", 0.25, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw2.tween_interval(0.5)
			tw2.tween_property(hero, "anim_lift", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	Fx.sparkle(game, hero.position + Vector3(0.0, 1.2, 0.0), [Color(0.6, 0.8, 1.0), Color(1.0, 0.7, 0.4), Color(0.8, 0.6, 1.0)][kind], 20)


## A new move replaces the one still playing (instead of both pulling at the hero at once), and
## starts from where that one left off - no snap.
func _new_tween(e: Entity, key: String) -> Tween:
	if e.has_meta(key):
		var old: Variant = e.get_meta(key)
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var tw := e.create_tween()
	e.set_meta(key, tw)
	return tw


func _spin(e: Entity, secs: float, turns := 1.0) -> void:
	if e.has_meta("spin_tw") and e.get_meta("spin_tw") is Tween and (e.get_meta("spin_tw") as Tween).is_running():
		return                                           # (still turning: let it finish)
	e.anim_spin = 0.0
	var tw := _new_tween(e, "spin_tw")
	tw.tween_property(e, "anim_spin", TAU * turns, secs).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: e.anim_spin = 0.0)


func _hop(e: Entity, height: float, up: float, down: float) -> void:
	var tw := _new_tween(e, "lift_tw")
	tw.tween_property(e, "anim_lift", maxf(height, e.anim_lift), up).set_ease(Tween.EASE_OUT)
	tw.tween_property(e, "anim_lift", 0.0, down).set_ease(Tween.EASE_IN)


# --- staging: the same every time, nothing in the way -------------------------------------------
# Every scene plays out the same way each time (its own fixed chance, from the scene's number), on
# a cleared stage (the beasts near it sent off, the townsfolk standing where they are), with the
# foes coming from the far side of the hero (so the camera sees them, facing it), a fight that
# lasts the whole scene and ends near its close, and a camera path picked, before the scene plays,
# from the turns of its orbit that see the hero clearest.
const SEED := 90210
const STAGE_RADIUS := 18.0
var _held: Array[Entity] = []
var _plan_cam0 := Vector3.INF          # where the camera starts this scene (as planned)
var _finish_sent := false


## Everything near the scene that isn't in it: beasts and pets out of sight, townsfolk held still
## (they stay in the picture as people of the town; they just don't walk into the shot).
func _clear_stage(sh: Dictionary) -> void:
	_release_stage()
	var centre: Vector3 = sh["at"] if bool(sh.get("no_hero", false)) else hero.position
	for item in game.creatures:
		var e := item as Entity
		if e == null or e == hero or e.dead or e in _actors or e == hero.mounted_on:
			continue
		if e.position.distance_to(centre) > STAGE_RADIUS:
			continue
		e.trailer_held = true
		e.path.clear()
		if e.kind == Entity.Kind.MONSTER or e.kind == Entity.Kind.PET:
			e.visible = false
		_held.append(e)


func _release_stage() -> void:
	for e in _held:
		if is_instance_valid(e):
			e.trailer_held = false
			if not e.dead and (e.kind == Entity.Kind.MONSTER or e.kind == Entity.Kind.PET):
				e.visible = true
	_held.clear()


## Where the camera stands (close on the hero, as the scene films them) at orbit angle `a`.
func _held_cam(a: float, r: float, h: float) -> Vector3:
	var d := clampf(r, CAM_NEAR, CAM_FAR)
	return hero.position + Vector3(cos(a) * d, clampf(h, CAM_ABOVE_HERO, CAM_HIGH), sin(a) * d)


## Before the scene plays: its orbit turned to the way round that sees the hero clearest (no wall,
## house or tree between them along the whole move), and where the camera will start.
func _plan_camera(sh: Dictionary) -> void:
	_plan_cam0 = Vector3.INF
	if not sh.has("a0") or sh.has("line") or sh.has("from"):
		return
	var a0 := float(sh["a0"])
	var a1 := float(sh["a1"])
	var r := float(sh.get("r", 6.0))
	var h := float(sh.get("h", 4.0))
	if not hero.visible or bool(sh.get("wide", false)):
		_plan_cam0 = (sh["at"] as Vector3) + Vector3(cos(a0) * r, h, sin(a0) * r)
		return
	var best_off := 0.0
	var best_bad := 1 << 20
	for off in [0.0, 0.6, -0.6, 1.2, -1.2, 1.9, -1.9, PI]:
		var bad := 0
		for s in range(7):
			var p := _held_cam(lerpf(a0, a1, float(s) / 6.0) + float(off), r, h)
			if _view_blocked(p, hero.position + Vector3(0.0, 1.0, 0.0)) or _inside_solid(p):
				bad += 1
		if bad < best_bad:
			best_bad = bad
			best_off = float(off)
		if bad == 0:
			break
	sh["a0"] = a0 + best_off
	sh["a1"] = a1 + best_off
	_plan_cam0 = _held_cam(a0 + best_off, r, h)


## A foe's place: on the far side of the hero from the camera, spread a little, on open ground.
func _foe_spot(k: int, n: int) -> Vector3:
	var cam_at: Vector3 = _plan_cam0 if (t < 0.05 and _plan_cam0 != Vector3.INF) else game.cam.position
	var away := hero.position - cam_at
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(0.0, 0.0, -1.0)
	away = away.normalized()
	var spread := (float(k) - float(n - 1) * 0.5) * 0.75
	for tries in [[spread, 2.6], [-spread, 2.6], [spread * 1.6, 2.2], [spread, 3.4], [spread + PI * 0.5, 2.6], [spread - PI * 0.5, 2.6]]:
		var p: Vector3 = hero.position + away.rotated(Vector3.UP, float(tries[0])) * float(tries[1])
		if not world.is_blocked(world.to_tile(p)):
			return Vector3(p.x, world.height_at(p), p.z)
	return hero.position + away * 2.4


## The fight lasts the whole scene and ends near its close: the foes can't fall before then (they
## hold on to a share of their life), and from two seconds before the end the next blow fells them.
func _script_fight(dur: float) -> void:
	if _fight.is_empty():
		return
	var ending := t >= dur - 2.2
	for a in _actors:
		if not is_instance_valid(a) or a.dead:
			continue
		var mx := float(a.stats.max_hp())
		if not ending:
			a.hp = maxf(a.hp, mx * 0.4)
		elif not _finish_sent:
			a.hp = minf(a.hp, 1.0)
	if ending:
		_finish_sent = true


## Before the first scene, behind the opening: every kind of spell effect once, out of sight of the
## picture but in front of the camera - so none of them stutters the first time it's seen.
func _warm_up() -> void:
	var cam: Camera3D = game.cam
	var p := cam.global_position - cam.global_transform.basis.z * 6.0
	var q := p + Vector3(1.0, 0.0, 0.0)
	Fx.burst(game, p)
	Fx.fireball(game, p, q)
	Fx.pillar(game, p)
	Fx.lightning(game, p)
	Fx.sparkle(game, p, Color(1.0, 0.9, 0.5))
	Fx.orb(game, p, q, Color(0.7, 0.5, 1.0))
	for node: Node3D in [Fx.flame(0.4), Fx.embers(0.4), Fx.cast_glow(Color(0.6, 0.8, 1.0)), Fx.smoke()]:
		node.position = p
		game.add_child(node)
		get_tree().create_timer(1.2).timeout.connect(node.queue_free)
	if _spell_light != null:
		_spell_light.position = p
		_spell_light.visible = true
		_spell_light.light_energy = 0.05            # (its light, too, drawn once)


# --- the camera's sight -------------------------------------------------------------------

var _occl := 0.0                       # how far the camera has risen and closed in to see past something
var _clear_for := 0.0                  # how long the view of the hero has been clear
var _edge_k := 0.0                     # how hard the camera is turning towards a hero near the edge
var _cam_s := Vector3.INF              # the camera's place, eased (no jitter)
var _aim_s := Vector3.ZERO             # where it aims, eased
const CAM_ABOVE_HERO := 1.0            # the camera never comes lower than this above the hero...
const CAM_HIGH := 2.3                  # ...nor (close on the hero) higher: about the hero's own eye level
const CAM_NEAR := 3.5                  # and keeps between these, out from the hero (metres)
const CAM_FAR := 6.5
var _floor_s := -INF                   # the camera's lowest height, eased
var _punch_s := 0.0                    # the punch-in, eased            # the camera never comes lower than this above the hero


## How tall each solid thing is (metres), for the camera's sight.
const SOLID_HEIGHT := {World.Tile.WALL: 2.2, World.Tile.HOUSE: 3.2, World.Tile.TREE: 2.0, World.Tile.ROCK: 1.0, World.Tile.FORGE: 1.0}


## Whether anything solid stands in the line from the camera to `to`, at the line's own height there.
func _view_blocked(from: Vector3, to: Vector3) -> bool:
	var d := Vector2(to.x - from.x, to.z - from.z)
	var steps := int(d.length() / 0.35) + 1
	for k in range(1, steps - 1):
		var p := from.lerp(to, float(k) / steps)
		var c := world.to_tile(p)
		if not world.in_bounds(c):
			continue
		var tile: int = world.tiles[c.y * world.cols + c.x]
		if SOLID_HEIGHT.has(tile) and p.y < world.height_at(p) + float(SOLID_HEIGHT[tile]):
			return true
	return false


## Whether the camera itself is inside a wall, a house or a tree.
func _inside_solid(p: Vector3) -> bool:
	var c := world.to_tile(p)
	if not world.in_bounds(c):
		return false
	var tile: int = world.tiles[c.y * world.cols + c.x]
	return SOLID_HEIGHT.has(tile) and p.y < world.height_at(p) + float(SOLID_HEIGHT[tile]) + 0.3


## A named beast for a bounty: bigger, tougher, worth more.
static func _elite(cfg: Dictionary) -> Dictionary:
	var c := cfg.duplicate(true)
	c["scale"] = float(c.get("scale", 1.0)) * 1.4
	c["str"] = int(c.get("str", 40)) * 2
	c["danger"] = float(c.get("danger", 2.0)) + 2.0
	return c


func _stage_place(tile: Vector2i) -> void:
	_put_hero(tile)


func _stage_town() -> void:
	_put_hero(Vector2i(32, 12))


func _stage_fight(tile: Vector2i, foe_name: String, cfg: Dictionary, n: int) -> void:
	_put_hero(tile)
	_fight = [tile, foe_name, cfg, n + (0 if " the " in foe_name else 1)]   # one more foe (a champion stays alone)
	_spawn_wave()
	shots[i]["magic"] = true                            # and the hero's spells in every fight
	shots[i]["hero_intro"] = true                       # (it opens tight on the hero)
	_cast_acc = CAST_EVERY * 0.6


## The foes of the scene's fight rush in round the hero (again, if the last lot fell early).
func _spawn_wave() -> void:
	var tile: Vector2i = _fight[0]
	var foe_name := String(_fight[1])
	var cfg: Dictionary = _fight[2]
	var n := int(_fight[3])
	for k in range(n):
		var c := cfg.duplicate(true)
		c["passive"] = false
		c["leash"] = 20
		c["aggro"] = 15.0
		var at := _foe_spot(k, n)                       # (from the far side of the hero, facing the camera)
		var e: Entity = game.pool_spawn("%s " % foe_name if k > 0 else foe_name, c, Color(0.85, 0.3, 0.25), at)
		e.target = hero
		_actors.append(e)
		if e.rig != null:                               # they step in on their feet: no dropping from the sky
			e.anim_lift = 0.0
			var arrive := e.create_tween()
			arrive.tween_property(e.rig, "scale", Vector3(1.1, 0.9, 1.1), 0.08)
			arrive.tween_property(e.rig, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	for a in _actors:
		if is_instance_valid(a) and not a.dead:
			hero.target = a
			break


func _stage_magic() -> void:
	_stage_fight(Vector2i(14, 19), "Ogre", Bestiary.OGRE, 1)
	shots[i]["magic"] = true
	shots[i]["cast_every"] = 1.4                      # (the magic scene: spells come quicker)
	_cast_acc = 1.0


func _cast_something() -> void:
	var foe: Entity = null
	for a in _actors:
		if is_instance_valid(a) and not a.dead:
			foe = a
	if foe == null:
		return
	# a monster close enough to strike? run out of reach first (a blow would break the spell),
	# and cast when clear
	var threat: Entity = hero._melee_threat()
	if threat != null and _runs < 2 and not bool(shots[i].get("no_run", false)):   # (twice at most, then stand and cast anyway; never from a giant)
		_runs += 1
		var away := hero.position - threat.position
		away.y = 0.0
		if away.length() < 0.01:
			away = Vector3(1, 0, 0)
		for turn in [0.0, 0.6, -0.6, 1.2, -1.2]:
			var dest: Vector3 = hero.position + away.normalized().rotated(Vector3.UP, turn) * 4.5
			if not world.is_blocked(world.to_tile(dest)) and hero.go_to(dest):
				hero.casting_id = ""
				hero.kite_timer = 1.1               # the run plays out before the hero turns to fight
				break
		_cast_acc = float(shots[i].get("cast_every", CAST_EVERY)) - 1.15   # and the spell right after it
		return
	_runs = 0
	hero.casting_id = ""
	hero.cast_cd = 0.0
	var pick: String = ["fireball", "lightning", "flamestrike", "energy_bolt", "meteor_swarm", "chain_lightning"][randi() % 6]
	_spell_col = {"fireball": Color(1.0, 0.55, 0.2), "lightning": Color(0.65, 0.8, 1.0), "flamestrike": Color(1.0, 0.45, 0.15),
		"energy_bolt": Color(0.75, 0.5, 1.0), "meteor_swarm": Color(1.0, 0.6, 0.25), "chain_lightning": Color(0.6, 0.85, 1.0)}.get(pick, Color(0.7, 0.8, 1.0))
	_cast_flourish()
	hero.start_cast(pick, foe)


func _stage_boat() -> void:
	_put_hero(Vector2i(66, 11))
	game.frontier.data["boat"] = true
	game.frontier._sail(2, false)
	# the hero turns a full half-circle, smoothly, to face the way the boat is going
	hero.create_tween().tween_property(hero, "_face_yaw", hero._face_yaw + PI, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


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
	shots[i]["hero_intro"] = true
	shots[i]["magic"] = true
	_cast_acc = 0.0
