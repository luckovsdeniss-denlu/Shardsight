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
	_punch = maxf(_punch, amount)
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
	_intro_loading()


## The opening: the loading screen's own animation - the spinning Shard in its rings over the
## glowing hexagons, the bar filling as the lines type out - then it fades into the first scene.
var _intro: LoadingScreen


func _intro_loading() -> void:
	if "--trailer-video" in OS.get_cmdline_user_args():
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
## The second trailer: the action cut - the opening, then only the fights, each cut shorter
## and filmed with the boldest moves, and the closing shot. About a minute.
const ACTION_CUT := ["SHARDSIGHT", "Fight", "Magic", "Bounties", "The dungeon's depths", "The Frostmarch",
	"The Arena", "Ravenhollow", "World bosses", "Your story"]
const ACTION_CAMS := ["spiral", "dolly", "crane", "track"]
var variant := 1                       # 1: the full trailer; 2: the action cut


func _action_cut() -> void:
	var cut: Array = []
	for sh: Dictionary in shots:
		if String(sh["title"]) in ACTION_CUT:
			cut.append(sh)
	for k in range(cut.size()):
		var sh: Dictionary = cut[k]
		var first_or_last := k == 0 or k == cut.size() - 1
		sh["dur"] = float(sh["dur"]) * (1.0 if first_or_last else 0.7)   # quicker cuts
		if not first_or_last and not sh.has("from"):
			sh["cam"] = ACTION_CAMS[k % ACTION_CAMS.size()]               # the boldest camera moves
		sh.erase("story")                                              # (all action: no talk)
	shots = cut


func _make_shots() -> void:
	shots = [
		{"title": "SHARDSIGHT", "sub": "A world of swords, spells and skill.", "dur": 6.0, "no_hero": true, "day": 0.35, "weather": "clear",
			"at": _tc(Vector2i(32, 9)), "r": 20.0, "h": 17.0, "a0": 0.4, "a1": 1.3},
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
		{"title": "Magic", "story": [["foe", "\"ME SMASH TINY HUMAN!\""], ["hero", "\"Stand back. This gets loud.\""]], "words": ["67 SPELLS", "SPEAK THE OLD WORDS"], "sub": "Sixty-seven spells in eight circles. Speak the old words.", "dur": 9.0, "white": true,
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
			"at": _tc(Vector2i(13, 129)), "r": 13.0, "h": 12.0, "a0": 1.2, "a1": 2.0, "stay": true, "cam": "orbit",
			"setup": _stage_talk.bind("Father Corwin", Vector2i(12, 129), ["\"You saw something you shouldn't have.\"", ">\"I remember nothing...\"", "\"Then we'll find it again - together.\""])},
		{"title": "Seasons and storms", "story": [["hero", "\"Lovely weather for it.\""], ["hero", "\"Is it always winter when I'm out?\""]], "words": ["THE SEASONS TURN"], "sub": "Spring to winter; rain, snow, thunder.", "dur": 7.0, "day": 0.5, "weather": "storm", "winter": true,
			"at": _tc(Vector2i(30, 30)), "r": 14.0, "h": 11.0, "a0": 3.5, "a1": 4.3},
		{"title": "World bosses", "story": [["foe", "\"I AM THAROK, THE WORLD-EATER!\""], ["hero", "\"You'll need a bigger appetite.\""], ["foe", "\"...urk.\""]], "words": ["SLAY THE GIANTS", "TOGETHER"], "sub": "Now and then a giant wakes. The whole land comes to fight it.", "dur": 9.0, "day": 0.55, "weather": "clear", "white": true,
			"at": _tc(Vector2i(60, 26)), "r": 8.0, "h": 5.0, "a0": 0.2, "a1": 1.5, "setup": _stage_boss},
		{"title": "Your story", "story": [["hero", "\"So... where do I begin?\""], ["hero", "\"Anywhere. Everywhere.\""]], "words": ["YOUR LEGEND", "BEGINS NOW"], "sub": "Quests, bounties, guilds, a house, a horse, a boat. Begin.", "dur": 6.0,
			"at": _tc(Vector2i(32, 9)), "r": 22.0, "h": 19.0, "a0": 1.3, "a1": 1.9},
	]
	if variant == 2:
		_action_cut()


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
	_tell(sh.get("story", []) as Array)
	hero.visible = not bool(sh.get("no_hero", false))
	hero.ai_enabled = not bool(sh.get("stay", false))   # in the church the hero stands still, inside
	if not hero.ai_enabled:
		hero.path.clear()
		hero.target = null
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
	_word_t = 1.0                                       # the first word a moment after the cut
	if "--movie-test" in OS.get_cmdline_user_args():
		print("MOVIE scene %d: %s (hero at %s)" % [i + 1, sh["title"], world.to_tile(hero.position)])
	_fx.set_shader_parameter("leak", 1.0 if float(sh.get("day", 0.4)) > 0.2 and String(sh.get("weather", "clear")) != "storm" else 0.0)
	game.cam.fov = 60.0                                 # each scene starts wide and pushes in
	if i == 0:
		# the very start: no flash and no blink - the picture simply rises out of black
		_flash = 0.0
		_fx.set_shader_parameter("flash", 0.0)
		_fx.set_shader_parameter("leak", 0.0)
		_fade.modulate.a = 1.0
		_fade.create_tween().tween_property(_fade, "modulate:a", 0.0, 1.4).set_trans(Tween.TRANS_SINE)
	else:                                               # (no cuts through white: every cut dips to black)
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
	# the explanation: big 3D words, one after another, flying in and past
	if not _word_queue.is_empty():
		_word_t -= delta / maxf(Engine.time_scale, 0.05)
		if _word_t <= 0.0:
			_word_t = 2.5
			var w := String(_word_queue.pop_front())
			_word_n += 1
			var screen := get_viewport().get_visible_rect().size
			var word := Title3D.make_flying(w, minf(screen.x * 0.75, 1100.0),
				Title3D.GOLD if _word_n % 2 == 1 else Title3D.ICE, screen)
			_words_box.add_child(word)                     # the whole screen: its flight is never cut off
			word.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			# (no sound for the word flying in or out; only the trailer's music and its brass cuts)
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
		Engine.time_scale = 0.35
		Soundscape.slowmo = true                       # the world goes dull and far away...
		Soundscape.update("wilds", false, false)
		game.music.player.pitch_scale = 0.8
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
	var vs := get_viewport().get_visible_rect().size
	_progress.size.x = vs.x * (float(i) + clampf(t / dur, 0.0, 1.0)) / float(shots.size())
	var k := smoothstep(0.0, 1.0, clampf(t / dur, 0.0, 1.0))
	var cam: Camera3D = game.cam
	cam.fov = lerpf(60.0, 48.0, k)                      # a slow push in
	var look: Vector3 = sh["at"]
	# the camera follows the hero: it looks at a point between the scene's centre and the hero,
	# leaning all the way to the hero if they slip out of the frame - so the hero never leaves it
	if hero.visible and not bool(sh.get("no_hero", false)):
		var lean := float(sh.get("follow", 0.6))
		if not cam.is_position_in_frustum(hero.position + Vector3(0.0, 1.0, 0.0)):
			lean = 1.0
		var want: Vector3 = look.lerp(hero.position, lean)
		if t < 0.05 or _look_s == Vector3.INF:
			_look_s = want
		_look_s = _look_s.lerp(want, 1.0 - exp(-delta * (6.0 if lean >= 1.0 else 3.0)))
		look = _look_s
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
			"dolly":                                    # the dolly zoom: pulls back as the lens closes in
				r = lerpf(r * 0.7, r * 1.5, k)
				cam.fov = lerpf(70.0, 34.0, k)
		cam.position = look + Vector3(cos(a) * r, h, sin(a) * r)
	# a little life in the hand-held camera, and a punch-in on a big blow
	cam.position += Vector3(sin(t * 1.7) * 0.06, sin(t * 2.3) * 0.04, cos(t * 1.3) * 0.06)
	_punch = maxf(_punch - delta * 3.0, 0.0)
	cam.fov -= _punch * 8.0
	cam.look_at(look + Vector3(0, 0.8, 0), Vector3.UP)
	cam.rotate_object_local(Vector3(0, 0, 1), sin(t * 0.6) * 0.035 * (1.0 if i % 2 == 0 else -1.0))   # a gentle dutch tilt
	game.view_planes = cam.get_frustum()
	if t >= dur:
		_next()
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


func _restore() -> void:
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
	game.movie_ended()
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)
	if "--trailer-video" in OS.get_cmdline_user_args():
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
		get_tree().create_timer(0.9 + k * 1.8).timeout.connect(func() -> void:
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
		get_tree().create_timer(1.0 + (said - 1) * 1.9).timeout.connect(func() -> void:
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
const COMBO_NAMES := ["SLASH!", "SPIN SLASH!", "LEAP STRIKE!", "WHIRLWIND FINISH!"]


## Each blow of the hero's sword is the next step of a four-step combo, each with its own move:
## a slash with a quick side-step, a spinning slash, a leaping strike, and a whirling finisher
## (the camera punches in). The move's name bursts over the foe that takes it.
func on_hero_strike(foe: Entity) -> void:
	var step := _combo % 4
	_combo += 1
	match step:
		0:                                               # slash, then a side-step round the foe
			_side = -_side
			var to := foe.position - hero.position
			to.y = 0.0
			if to.length() > 0.01:
				var perp := Vector3(-to.z, 0.0, to.x).normalized() * _side
				var dest := hero.position + perp * 1.0
				if not world.is_blocked(world.to_tile(dest)):
					hero.create_tween().tween_property(hero, "position", dest, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		1:                                               # spin slash
			_spin(hero, 0.32)
		2:                                               # leaping strike
			_hop(hero, 0.7, 0.18, 0.2)
			punch(0.5)
		3:                                               # whirlwind finisher
			_spin(hero, 0.45, 2.0)
			_hop(hero, 0.45, 0.15, 0.2)
			punch(1.0)
			Fx.sparkle(game, foe.position + Vector3(0.0, 1.0, 0.0), Color(1.0, 0.85, 0.35), 30)
	foe._pop(String(COMBO_NAMES[step]), [Color(1.0, 0.9, 0.5), Color(0.6, 0.9, 1.0), Color(1.0, 0.6, 0.3), Color(1.0, 0.45, 0.85)][step])


## As a spell begins, the hero moves with it, in turn: rising into the air, a twirl, a hop back.
func _cast_flourish() -> void:
	var kind := _cast_n % 3
	_cast_n += 1
	match kind:
		0:                                               # rises, held aloft while the words are spoken
			var tw := hero.create_tween()
			tw.tween_property(hero, "anim_lift", 0.55, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.7)
			tw.tween_property(hero, "anim_lift", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		1:
			_spin(hero, 0.5)
		2:
			_hop(hero, 0.5, 0.15, 0.2)
	Fx.sparkle(game, hero.position + Vector3(0.0, 1.2, 0.0), [Color(0.6, 0.8, 1.0), Color(1.0, 0.7, 0.4), Color(0.8, 0.6, 1.0)][kind], 20)


func _spin(e: Entity, secs: float, turns := 1.0) -> void:
	e.anim_spin = 0.0
	var tw := e.create_tween()
	tw.tween_property(e, "anim_spin", TAU * turns, secs).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: e.anim_spin = 0.0)


func _hop(e: Entity, height: float, up: float, down: float) -> void:
	var tw := e.create_tween()
	tw.tween_property(e, "anim_lift", height, up).set_ease(Tween.EASE_OUT)
	tw.tween_property(e, "anim_lift", 0.0, down).set_ease(Tween.EASE_IN)


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
		var ang := TAU * float(k) / float(n) + randf() * 0.5     # from all sides
		var at := world.tile_center(tile) + Vector3(cos(ang), 0, sin(ang)) * (2.2 + randf() * 0.8)
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
	if threat != null and _runs < 2:                   # (twice at most, then stand and cast anyway)
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
	shots[i]["magic"] = true
	_cast_acc = 0.0
