extends Node3D
## Third-person 3D view of the tile world, populated with the hero, other players, NPCs
## and monsters. Tap the ground to walk, tap a monster to attack it. With Auto on, the hero
## also acts by itself: wanders, fights monsters nearby and retreats to a healer when hurt.

const CAM_OFFSET := Vector3(0.0, 9.0, 7.0)
const MANUAL_PAUSE := 4.0      # seconds auto mode waits after a tap
const LOG_LINES := 6
const DEFAULT_RUNE := Vector2i(25, 13)
const GATE_SECONDS := 20.0
const VENDOR_HIRE_COST := 100
const VENDOR_SALES_PER_HOUR := 3     # while you are away (capped at two days)
const DAY_SECONDS := 480.0       # one full day and night

var version: String = ProjectSettings.get_setting("application/config/version", "dev")
var world := World.new()
var creatures: Array[Entity] = []
var corpses: Array[Corpse] = []
var hero: Entity
var guilds := Guilds.new()
var frontier: Frontier                 # the wider world: depths, biomes, boats, tavern, side quests, arena...
var music := Music.new()
var weather := "clear"           # clear, rain or storm
const CLEAR_HAZE := 0.011        # fog density on a clear day: just a little depth
var _weather_timer := 240.0
var _flash := 0.0
var _thunder_in := -1.0
var _music_timer := 0.0
var rain: CPUParticles3D
var rain_sound := AudioStreamPlayer.new()
var retreat_button: Button
var ride_button: Button
var players_panel: Control
var players_box: VBoxContainer
var bag_panel: Control
var corner_toggle: Button              # the Menu button in the upper right
var corner_grid: GridContainer         # the buttons it opens
var mute_button: Button
var names_button: Button
var stats_button: Button
var map_button: Button
var bow_button: Button
var view_button: Button
var corpse_button: Button
var magic_button: Button
var bag_box: VBoxContainer
var spells_panel: Control
var shop_panel: Control
var shop_box: VBoxContainer
var shop_open: Entity                    # the merchant whose shop is showing
var shop_tab := "buy"                    # "buy" or "sell"
var exp_panel: Control
var exp_box: VBoxContainer
var stats_panel: Control
var stats_box: VBoxContainer
var spell_details := true              # the Spells panel shows each spell's numbers
var priest_panel: Control
var priest_box: VBoxContainer
var priest_open: Entity                  # the priest whose panel is showing
var spells_box: VBoxContainer
var last_spell := ""                   # the spell cast last from the Spells panel (offered first)
var thief_panel: Control
var thief_box: VBoxContainer
var guild_panel: Control
var guild_box: VBoxContainer
var cam := Camera3D.new()
var marker := MeshInstance3D.new()
var hud := Label.new()
var log_label := RichTextLabel.new()
var auto_button := Button.new()
var log_lines: Array[String] = []
var world_label := RichTextLabel.new()        # what happens to everyone else (lower right)
var world_lines: Array[String] = []
var held := false
var auto := true
var paused := false
var menu: Control
var skills_panel: Control
var skills_box: VBoxContainer
var craft_panel: Control
var craft_box: VBoxContainer
var property := Property.new()
var property_panel: Control
var property_box: VBoxContainer
var travel_panel: Control
var travel_box: VBoxContainer
var settings_panel: Control
var settings_box: VBoxContainer
var sfx := Sfx.new()
var minimap := Minimap.new()
var env: Environment
var sun: DirectionalLight3D
var day_time := 0.35             # 0 = midnight, 0.5 = noon
var touches := {}                # screen touch index -> position (for pinch and twist)
var _pinch_dist := 0.0
var _pinch_angle := 0.0
var animals_panel: Control
var bard_panel: Control
var prices_panel: Control
var prices_box: VBoxContainer
var vendor_npc: Entity = null
var _vendor_timer := 60.0
var bard_box: VBoxContainer
var animals_box: VBoxContainer
var pending_spawns: Array[Dictionary] = []   # spawns requested mid-frame, done after the tick loop
var saved_pets: Array = []                   # pets read from the save, restored after start-up
var saved_mounted := false
var gates: Array[Dictionary] = []      # {"a": Vector3, "b": Vector3, "life": float, "nodes": [Node3D]}
var reset_button: Button
var reset_armed := false
var save_timer := 0.0
var skip_save := false

# Automated play-test (CI): `godot --headless --fixed-fps 20 -- --autotest` plays a fresh game
# in Auto mode for autotest_seconds of game time (default 15 minutes, or --autotest-seconds=N),
# checks invariants, prints a report and quits.
var autotest: bool = "--autotest" in OS.get_cmdline_user_args()
var autotest_seconds := _autotest_seconds_arg()
var autotest_time := 0.0
var counters := {}
var problems: Array[String] = []
var _check_timer := 0.0
var _start_skill_total := 0.0
var _activity := ""                # snapshot of the activity counters, for the stuck check
var _idle_time := 0.0
const STUCK_SECONDS := 300.0

const TIPS := [
	"Tip: tap the ground to walk, tap a monster to attack it, tap a corpse to loot it.",
	"Tip: with Auto on, your hero fights, loots, gathers, crafts and banks by itself.",
	"Tip: Menu has Skills, Craft, Bank & House, Travel, Settings and Help.",
	"Tip: pinch with two fingers to zoom, twist them to turn the camera.",
	"Tip: townsfolk with a ! over their action button have work for you. Main Menu > Adventures lists it all.",
]
var _tips_left: Array = []
var _tip_timer := 8.0


## The mode this run was started in: "" (first start: the title offers the choice), "classic" or
## "experimental". Kept across restarts of the scene (a mode switch reloads it).
static var start_mode := ""
var movie: Movie                       # the showcase, while it plays
var ui_layer: CanvasLayer              # the whole interface: buttons, log, stats, menus (hidden for the movie)
var title_up := false                  # the title and fly-by are up: the world waits
var booted := false                    # the world is built (the loading screen is done)


func _ready() -> void:
	Soundscape.setup()                       # the mix: music, effects and ambience buses, reverb, compressor
	# experimental mode: its own save, and the experiments' switches
	Experiments.active = start_mode == "experimental" and not autotest
	SaveGame.slot = "_experimental" if Experiments.active else ""
	if Experiments.active:
		Experiments.load_cfg()
	if not autotest and DisplayServer.get_name() != "headless":
		Engine.max_fps = FPS_GOAL                # no faster than 60, even on a 120 Hz screen (cooler, steadier)
	# The loading screen, then the world built a step at a time so it can move between steps.
	# Nothing ticks until it's all built.
	set_process(false)
	var loading := LoadingScreen.new()
	add_child(loading)
	loading.step(0.04, "Waking the shard")
	await get_tree().process_frame
	loading.step(0.08, "Raising the land")
	await get_tree().process_frame
	await world.build(self, func(f: float) -> void:
		loading.step(0.08 + 0.5 * f, "Painting the land" if f < 0.72 else "Growing the forests"))
	loading.step(0.6, "Lighting the sky")
	await get_tree().process_frame
	_build_environment()
	_build_marker()
	loading.step(0.68, "Calling the creatures")
	await get_tree().process_frame
	_spawn_all()
	_build_rings()
	loading.step(0.8, "Building the towns")
	await get_tree().process_frame

	cam.fov = 50.0
	add_child(cam)
	cam.make_current()

	_make_ui_solid(ThemeDB.get_default_theme())   # buttons and panels with solid backgrounds
	var layer := CanvasLayer.new()
	add_child(layer)
	ui_layer = layer
	_build_fps_counter()
	# Upper left: a button that shows or hides the stats text under it.
	stats_button = _menu_button("", _toggle_stats)
	stats_button.custom_minimum_size = Vector2(180, 60)
	stats_button.add_theme_font_size_override("font_size", 24)
	stats_button.position = Vector2(16, 12)
	layer.add_child(stats_button)
	hud.position = Vector2(16, 82)
	hud.add_theme_font_size_override("font_size", 26)
	layer.add_child(hud)

	# Event log: pinned to the lower-left corner. The containers
	# are full-screen but ignore the mouse, so taps still reach the game. No background; a thick
	# outline keeps it readable.
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	layer.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_END
	margin.add_child(column)
	_setup_log(log_label, 28, 520.0)
	log_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(log_label)

	# World log: everyone else's deaths, crimes and resurrections, lower right.
	var wmargin := MarginContainer.new()
	wmargin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["right", "bottom"]:
		wmargin.add_theme_constant_override("margin_" + side, 16)
	layer.add_child(wmargin)
	wmargin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wcolumn := VBoxContainer.new()
	wcolumn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wcolumn.alignment = BoxContainer.ALIGNMENT_END
	wmargin.add_child(wcolumn)
	_setup_log(world_label, 24, 460.0)
	world_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	wcolumn.add_child(world_label)

	# Upper right: one Menu button that opens every other button (two columns, so they fit the
	# screen), with the minimap under it.
	var corner := VBoxContainer.new()
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner.alignment = BoxContainer.ALIGNMENT_BEGIN
	layer.add_child(corner)
	corner_toggle = _menu_button("Menu", _toggle_corner)
	corner_toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
	corner.add_child(corner_toggle)
	corner_grid = GridContainer.new()
	corner_grid.columns = 2
	corner_grid.visible = false
	corner.add_child(corner_grid)
	auto_button.pressed.connect(_toggle_auto)
	_corner_add(auto_button)
	_corner_add(_menu_button("Main Menu", _open_menu))
	_corner_add(_menu_button("Bag", _open_bag))
	_corner_add(_menu_button("Spells", _open_spells))
	retreat_button = _menu_button("Retreat", _on_retreat)
	_corner_add(retreat_button)
	ride_button = _menu_button("Ride", _on_ride)
	_corner_add(ride_button)
	bow_button = _menu_button("Bow", _on_switch_weapon)
	_corner_add(bow_button)
	mute_button = _menu_button("", _toggle_mute)
	_corner_add(mute_button)
	names_button = _menu_button("", _toggle_names)
	_corner_add(names_button)
	map_button = _menu_button("", _toggle_map)
	_corner_add(map_button)
	view_button = _menu_button("", _toggle_view)
	_corner_add(view_button)
	corpse_button = _menu_button("", _toggle_corpse_names)
	_corner_add(corpse_button)
	magic_button = _menu_button("", _toggle_magic_label)
	_corner_add(magic_button)
	_corner_add(_menu_button("Statistics", _open_stats))
	minimap.setup(self, world)
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_END
	corner.add_child(minimap)
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_update_button()
	_update_corner_buttons()
	_build_select_bar(layer)
	_build_ghost_view(layer)
	_build_story_ui(layer)
	fp_overlay = FpOverlay.new()
	fp_overlay.game = self
	fp_overlay.visible = false
	layer.add_child(fp_overlay)
	fp_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_menu(layer)
	_build_skills_panel(layer)
	_build_craft_panel(layer)
	_build_property_panel(layer)
	travel_panel = _make_overlay(layer)
	travel_box = travel_panel.get_meta("box")
	settings_panel = _make_overlay(layer)
	animals_panel = _make_overlay(layer)
	bard_panel = _make_overlay(layer)
	prices_panel = _make_overlay(layer)
	prices_box = prices_panel.get_meta("box")
	players_panel = _make_overlay(layer)
	players_box = players_panel.get_meta("box")
	bag_panel = _make_overlay(layer)
	bag_box = bag_panel.get_meta("box")
	spells_panel = _make_overlay(layer)
	spells_box = spells_panel.get_meta("box")
	priest_panel = _make_overlay(layer)
	priest_box = priest_panel.get_meta("box")
	stats_panel = _make_overlay(layer)
	stats_box = stats_panel.get_meta("box")
	exp_panel = _make_overlay(layer)
	exp_box = exp_panel.get_meta("box")
	shop_panel = _make_overlay(layer)
	shop_box = shop_panel.get_meta("box")
	thief_panel = _make_overlay(layer)
	thief_box = thief_panel.get_meta("box")
	guild_panel = _make_overlay(layer)
	guild_box = guild_panel.get_meta("box")
	bard_box = bard_panel.get_meta("box")
	animals_box = animals_panel.get_meta("box")
	settings_box = settings_panel.get_meta("box")
	loading.step(0.88, "Remembering your hero")
	await get_tree().process_frame
	if autotest:
		seed(20261103)                       # same dice every run, so results are comparable
		skip_save = true                     # a fresh game; never touch the real save
		_start_skill_total = hero.stats.skill_total()
		print("AUTOTEST start: %d game-seconds" % int(autotest_seconds))
	elif SaveGame.load_into(hero, property):
		hero.refresh_look()                  # the saved gear shows on the model
		if not hero._has_ranged():           # heroes from before bows: one in the pack
			hero.inventory["bow"] = 1
			hero.arrows = maxi(hero.arrows, Bestiary.PLAYER_ARROWS)
			log_event("You find a bow and %d arrows in your pack (Menu > Bow to draw it)." % hero.arrows)
		log_event("Welcome back. Your progress was loaded.")
		_restore_house()
		_restore_pets()
		_ensure_escort()
		if saved_mounted:
			for p in hero.pets:
				if hero.can_ride(p):
					p.position = hero.position
					hero.mount(p)
					break
	else:
		log_event("Welcome to Shardsight. Tap a monster to attack it.")
		_tips_left = TIPS.duplicate()        # first launch: a few tips over the first minute
	_update_corner_buttons()                 # the saved switches: stats, map
	loading.step(0.96, "Opening the wider world")
	await get_tree().process_frame
	frontier = Frontier.new()
	frontier.setup(self, layer)
	_halve_monsters()
	for e in creatures:
		e.show_name(property.names_on)
	if property.rune.x < 0 or property.runes.is_empty():
		property.rune = DEFAULT_RUNE         # a starting rune marked in town, for Recall
		property.runes.clear()
		property.runes.append(DEFAULT_RUNE)
	_apply_graphics()                        # now that the sun and the rain exist
	_follow_camera()
	booted = true
	set_process(true)
	loading.finish()
	if not autotest:
		_show_title(layer)                   # the title and the fly-by, as the loading screen fades


const MENU_ICONS := {"Resume": "travel", "Story": "scroll", "Adventures": "star", "Skills": "star", "Craft": "tool",
	"Bank & House": "coin", "Travel & Spellbook": "map", "Players": "info", "Guild & Fame": "shield", "Thievery": "gem",
	"Animals": "heart", "Bard": "magic", "Prices": "coin", "Settings": "tool", "Help": "info", "Save now": "chest",
	"Back": "travel", "Close": "travel"}


func _menu_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	if MENU_ICONS.has(text):                           # a little picture beside the word
		b.icon = Icons.tex(String(MENU_ICONS[text]))
		b.add_theme_constant_override("icon_max_width", 30)
	b.custom_minimum_size = Vector2(240, 80)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(callback)
	b.pressed.connect(func() -> void:
		if property.sound_on:
			sfx.play("click", 1.0, -14.0))           # a soft click under every button
	return b


func _build_menu(layer: CanvasLayer) -> void:
	menu = CenterContainer.new()
	menu.visible = false
	menu.mouse_filter = Control.MOUSE_FILTER_STOP     # swallow taps while the menu is open
	layer.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	menu.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	pad.add_child(box)
	var title := Label.new()
	title.text = "Shardsight v%s" % version
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.42))
	box.add_child(title)
	var rule := ColorRect.new()
	rule.color = Color(0.78, 0.64, 0.34, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	box.add_child(rule)
	# the buttons in three columns that scroll, so they all fit the screen
	var scroll := TouchScroll.new()
	scroll.custom_minimum_size = Vector2(790, 500)
	box.add_child(scroll)
	var grid := GridContainer.new()
	_dress_overlay(menu, grid)                         # dimmed behind; a tap outside resumes
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	grid.add_child(_menu_button("Resume", _resume))
	grid.add_child(_menu_button("Story", _open_story))
	grid.add_child(_menu_button("Adventures", _open_adventures))
	grid.add_child(_menu_button("Skills", _open_skills))
	grid.add_child(_menu_button("Craft", _open_craft))
	grid.add_child(_menu_button("Bank & House", _open_property))
	grid.add_child(_menu_button("Travel & Spellbook", _open_travel))
	grid.add_child(_menu_button("Players", _open_players.bind(null)))
	grid.add_child(_menu_button("Guild & Fame", _open_guild))
	grid.add_child(_menu_button("Thievery", _open_thief))
	grid.add_child(_menu_button("Animals", _open_animals))
	grid.add_child(_menu_button("Bard", _open_bard))
	grid.add_child(_menu_button("Prices", _open_prices))
	grid.add_child(_menu_button("Settings", _open_settings))
	grid.add_child(_menu_button("Help", _open_help))
	grid.add_child(_menu_button("Save now", _save_now))
	reset_button = _menu_button("Reset progress", _reset_progress)
	grid.add_child(reset_button)
	if Experiments.active:
		grid.add_child(_menu_button("Experiments", _open_experiments))
		grid.add_child(_menu_button("Ordinary game", _switch_mode.bind("classic")))
	else:
		grid.add_child(_menu_button("Experimental mode", _switch_mode.bind("experimental")))


func _build_skills_panel(layer: CanvasLayer) -> void:
	skills_panel = CenterContainer.new()
	skills_panel.visible = false
	skills_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(skills_panel)
	skills_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	skills_panel.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(pad)
	skills_box = VBoxContainer.new()
	skills_box.add_theme_constant_override("separation", 6)
	pad.add_child(_scroll_wrap(skills_box))
	_dress_overlay(skills_panel, skills_box)


## Long lists scroll (drag on a phone) so they fit the screen.
## A panel's body: a slim bar on top with a close button that is always in reach (no scrolling
## to the bottom for Back), and under it the list, which scrolls under your finger.
func _scroll_wrap(box: VBoxContainer) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var bar := HBoxContainer.new()
	var hint := Label.new()
	hint.text = "drag to scroll"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.8, 0.72, 0.5, 0.7))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(hint)
	var x := Button.new()
	x.text = "X"
	x.custom_minimum_size = Vector2(84, 48)
	x.add_theme_font_size_override("font_size", 24)
	x.pressed.connect(_press_back.bind(box))
	bar.add_child(x)
	col.add_child(bar)
	var rule := ColorRect.new()                     # a thin gold line under the bar
	rule.color = Color(0.78, 0.64, 0.34, 0.6)
	rule.custom_minimum_size = Vector2(0, 2)
	col.add_child(rule)
	var scroll := TouchScroll.new()                 # drag anywhere to scroll, flick to glide
	scroll.custom_minimum_size = Vector2(880, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	col.add_child(scroll)
	return col


func _build_craft_panel(layer: CanvasLayer) -> void:
	craft_panel = CenterContainer.new()
	craft_panel.visible = false
	craft_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(craft_panel)
	craft_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	craft_panel.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(pad)
	craft_box = VBoxContainer.new()
	craft_box.add_theme_constant_override("separation", 6)
	pad.add_child(_scroll_wrap(craft_box))
	_dress_overlay(craft_panel, craft_box)


## Recipes with what they need. Blacksmithy and smelting need the forge in the smith's house;
## Tailoring and Carpentry work anywhere.
func _refresh_craft() -> void:
	for c in craft_box.get_children():
		craft_box.remove_child(c)
		c.queue_free()
	var inv := hero.inventory
	var title := Label.new()
	title.text = "Crafting   (%s)\nIngots %d   Ore %d   Logs %d   Wolf Pelts %d" % [
		"at the forge" if world.near_forge(hero.position) else "the forge is in the smith's house",
		Crafting.ingot_count(inv), Crafting.ore_count(inv), Crafting.count(inv, "log"),
		Crafting.count(inv, "wolf_pelt")]
	title.add_theme_font_size_override("font_size", 26)
	craft_box.add_child(title)
	var smelt := _menu_button("Smelt ore", _on_smelt)
	smelt.disabled = Crafting.ore_count(inv) == 0 or not world.near_forge(hero.position)
	craft_box.add_child(smelt)
	for id in Crafting.ORDER:
		var r: Dictionary = Crafting.RECIPES[id]
		var row := HBoxContainer.new()
		var info := Label.new()
		var skill := int(r["skill"])
		info.text = "%s\n%s · %s %d · %d%%" % [
			Items.item_name(id), Items.mats_text(r["mats"]), Hero.skill_name(skill), int(r["min"]),
			roundi(Rules.craft_chance(float(hero.stats.skills[skill]), float(r["min"])) * 100.0)]
		info.custom_minimum_size = Vector2(620, 0)
		info.add_theme_font_size_override("font_size", 22)
		row.add_child(info)
		var make := Button.new()
		make.text = "Make"
		make.custom_minimum_size = Vector2(160, 56)
		make.add_theme_font_size_override("font_size", 24)
		make.disabled = hero.craft_problem(id) != ""
		make.pressed.connect(_on_craft.bind(id))
		row.add_child(make)
		craft_box.add_child(row)
	craft_box.add_child(_menu_button("Back", _close_craft))


func _on_craft(id: String) -> void:
	hero.craft(id)
	_refresh_craft()


func _on_smelt() -> void:
	hero.smelt_all()
	_refresh_craft()


func _open_craft() -> void:
	menu.visible = false
	craft_panel.visible = true
	_refresh_craft()


func _close_craft() -> void:
	craft_panel.visible = false
	menu.visible = true


## Rebuilds the skills list. Lock arrows: Up = may rise, Down = may be lost when the skill
## cap is reached (so another skill can rise), Locked = frozen.
func _refresh_skills() -> void:
	for c in skills_box.get_children():
		skills_box.remove_child(c)
		c.queue_free()
	var s := hero.stats
	var title := Label.new()
	title.text = "Level %d / %d (from combat skills: %.1f / %d)\nStr %d   Dex %d   Int %d   (%d/%d)\nSkills %.1f / %d" % [
		hero.stats.level(), Hero.LEVEL_MAX, s.combat_total(), Hero.COMBAT_SKILLS.size() * Rules.SKILL_MAX,
		s.strength, s.dexterity, s.intelligence, s.stat_total(), Rules.STAT_CAP,
		s.skill_total(), Rules.SKILL_CAP_TOTAL]
	title.add_theme_font_size_override("font_size", 28)
	skills_box.add_child(title)
	for skill in Hero.Skill.values():
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = Hero.skill_name(skill)
		name_label.custom_minimum_size = Vector2(380, 0)
		name_label.add_theme_font_size_override("font_size", 26)
		row.add_child(name_label)
		var value_label := Label.new()
		value_label.text = "%.1f" % float(s.skills[skill])
		value_label.custom_minimum_size = Vector2(110, 0)
		value_label.add_theme_font_size_override("font_size", 26)
		row.add_child(value_label)
		var lock_button := Button.new()
		lock_button.text = ["Up", "Down", "Locked"][int(s.locks[skill])]
		lock_button.custom_minimum_size = Vector2(170, 50)
		lock_button.add_theme_font_size_override("font_size", 24)
		lock_button.pressed.connect(_cycle_lock.bind(skill))
		row.add_child(lock_button)
		skills_box.add_child(row)
	skills_box.add_child(_menu_button("Back", _close_skills))


func _cycle_lock(skill: int) -> void:
	hero.stats.locks[skill] = (int(hero.stats.locks[skill]) + 1) % 3
	_refresh_skills()


func _open_skills() -> void:
	menu.visible = false
	skills_panel.visible = true
	_refresh_skills()


func _close_skills() -> void:
	skills_panel.visible = false
	menu.visible = true


# --- bank and house --------------------------------------------------------

func _build_property_panel(layer: CanvasLayer) -> void:
	property_panel = CenterContainer.new()
	property_panel.visible = false
	property_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(property_panel)
	property_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	property_panel.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(pad)
	property_box = VBoxContainer.new()
	property_box.add_theme_constant_override("separation", 8)
	pad.add_child(_scroll_wrap(property_box))
	_dress_overlay(property_panel, property_box)


func _hero_at_bank() -> bool:
	if hero.dead or hero.notoriety() != Entity.Notoriety.BLUE:
		return false
	for e in creatures:
		if e.role == "banker" and e.position.distance_to(hero.position) <= 3.0:
			return true
	return false


func _hero_at_house() -> bool:
	return property.has_house() and not hero.dead \
		and hero.position.distance_to(world.tile_center(property.house_center_tile())) <= float(property.house_size) / 2.0 + 0.1


func _info(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(840, 0)
	l.add_theme_font_size_override("font_size", 24)
	return l


func _action(text: String, callback: Callable, enabled: bool) -> Button:
	var b := _menu_button(text, callback)
	b.disabled = not enabled
	return b


## Banking needs the banker (in town); the chest needs you inside your house.
func _refresh_property() -> void:
	for c in property_box.get_children():
		property_box.remove_child(c)
		c.queue_free()
	var at_bank := _hero_at_bank()
	var at_house := _hero_at_house()
	var title := _info("Bank & House")
	title.add_theme_font_size_override("font_size", 30)
	property_box.add_child(title)
	property_box.add_child(_info("Gold: %d carried, %d in the bank. %s" % [
		hero.gold, property.bank_gold,
		"You are at the bank." if at_bank else "Banking needs Oswin the banker, in town."]))
	property_box.add_child(_info("Bank box: " + Property.items_text(property.bank_items)))
	property_box.add_child(_action("Deposit all gold", _on_deposit_gold, at_bank and hero.gold > 0))
	property_box.add_child(_action("Withdraw 100 gold", _on_withdraw_gold, at_bank and property.bank_gold > 0))
	property_box.add_child(_action("Deposit bag", _on_deposit_bag, at_bank and not hero.inventory.is_empty()))
	property_box.add_child(_action("Take all from the bank", _on_withdraw_items, at_bank and not property.bank_items.is_empty()))

	if property.has_house():
		var o := property.house_origin
		property_box.add_child(_info("Your %s (%dx%d) at %d,%d: %s. You or a co-owner coming near keeps it standing; after %d days away it collapses and its chest spills out for anyone." % [
			Property.DEEDS[property.house_size]["name"], property.house_size, property.house_size,
			o.x, o.y, property.condition(), int(property.collapse_days())]))
		property_box.add_child(_info("Chest: " + Property.items_text(property.house_chest)))
		property_box.add_child(_action("Store bag in the chest", _on_chest_store, at_house and not hero.inventory.is_empty()))
		property_box.add_child(_action("Take all from the chest", _on_chest_take, at_house and not property.house_chest.is_empty()))
		# Lock-downs: kept safe even if the house collapses (they go to the bank instead).
		var free_slots := property.lockdown_slots() - property.lockdowns.size()
		property_box.add_child(_info("Locked down (%d of %d slots; safe even if the house falls): %s" % [
			property.lockdowns.size(), property.lockdown_slots(), Property.items_text(property.lockdowns)]))
		property_box.add_child(_action("Lock down items from your bag (%d slots free)" % free_slots,
			_on_lock_down, at_house and free_slots > 0 and not hero.inventory.is_empty()))
		property_box.add_child(_action("Release all lock-downs to your bag", _on_release_lockdowns,
			at_house and not property.lockdowns.is_empty()))
		# Co-owners: trusted players; each keeps the house standing longer.
		property_box.add_child(_info("Co-owners (%d of %d): %s. The house collapses after %d days away." % [
			property.co_owners.size(), property.co_owner_slots(),
			", ".join(property.co_owners) if not property.co_owners.is_empty() else "none",
			int(property.collapse_days())]))
		for e in creatures:
			if e.kind != Entity.Kind.PLAYER or e.is_hero or e.is_pk:
				continue
			if property.co_owners.has(e.display_name):
				property_box.add_child(_action("Remove co-owner %s" % e.display_name, _on_co_owner.bind(e.display_name), true))
			elif property.co_owners.size() < property.co_owner_slots():
				property_box.add_child(_action("Make %s a co-owner" % e.display_name, _on_co_owner.bind(e.display_name), at_house))
		property_box.add_child(_action("Re-deed the house (pack it up: contents and lock-downs go to the bank)", _on_redeed, at_house))
		if property.vendor_hired:
			property_box.add_child(_info("Your vendor sells at full value (merchants pay half for used gear), even while you are away, and keeps 10%%. Stock: %s. Earnings waiting: %d gold." % [
				Property.items_text(property.vendor_stock), property.vendor_gold]))
			property_box.add_child(_action("Give the vendor your bag to sell", _on_vendor_stock, at_house and not _sellable_bag().is_empty()))
			property_box.add_child(_action("Take the vendor's stock back", _on_vendor_unstock, at_house and not property.vendor_stock.is_empty()))
			property_box.add_child(_action("Collect %d gold from the vendor" % property.vendor_gold, _on_vendor_collect, at_house and property.vendor_gold > 0))
		else:
			property_box.add_child(_info("Hire a vendor to sell your goods from the house, even while you are away (%d gold from the bank)." % VENDOR_HIRE_COST))
			property_box.add_child(_action("Hire a vendor", _on_vendor_hire, at_house and property.bank_gold >= VENDOR_HIRE_COST))
	elif property.has_deed:
		var deed: Dictionary = Property.DEEDS[property.deed_size]
		property_box.add_child(_info("You own a %s deed (%dx%d). Stand on open ground outside town and place it." % [
			deed["name"], property.deed_size, property.deed_size]))
		property_box.add_child(_action("Place house here", _on_place_house, not hero.dead and not hero._in_town()))
		for size in Property.DEEDS:
			if size == property.deed_size:
				continue
			var other: Dictionary = Property.DEEDS[size]
			var diff := int(other["price"]) - int(deed["price"])
			property_box.add_child(_action("Exchange it for a %s deed (%s %d gold)" % [
				other["name"], "pay" if diff > 0 else "get back", absi(diff)],
				_on_exchange_deed.bind(size), at_bank and property.bank_gold >= diff))
	else:
		property_box.add_child(_info("House deeds are paid from the bank. Bigger houses hold more lock-downs (kept even if the house collapses) and more co-owners (each one keeps it standing %d days longer)." % int(Property.CO_OWNER_DAYS)))
		for size in Property.DEEDS:
			var deed: Dictionary = Property.DEEDS[size]
			property_box.add_child(_action("Buy a %s deed (%dx%d, %d gold, %d lock-downs, %d co-owners)" % [
				deed["name"], size, size, int(deed["price"]), int(deed["lockdowns"]), int(deed["co_owners"])],
				_on_buy_deed.bind(size), at_bank and property.bank_gold >= int(deed["price"])))
	property_box.add_child(_menu_button("Back", _close_property))


## Also used by the hero's automatic bank trips.
func bank_deposit(e: Entity, amount: int) -> void:
	amount = mini(amount, e.gold)
	if amount <= 0:
		return
	e.gold -= amount
	if not e.is_hero:
		e.bank_gold += amount            # other players keep their own account
		return
	property.bank_gold += amount
	count("banked", amount)
	log_event("You deposit %d gold. Bank balance: %d." % [amount, property.bank_gold])


func _on_deposit_gold() -> void:
	bank_deposit(hero, hero.gold)
	_refresh_property()


func _on_withdraw_gold() -> void:
	var amount := mini(100, property.bank_gold)
	property.bank_gold -= amount
	hero.gold += amount
	log_event("You withdraw %d gold." % amount)
	_refresh_property()


func _on_deposit_bag() -> void:
	Property.merge(property.bank_items, hero.inventory)
	hero.inventory.clear()
	log_event("You put your bag in the bank box.")
	_refresh_property()


func _on_withdraw_items() -> void:
	Property.merge(hero.inventory, property.bank_items)
	property.bank_items.clear()
	log_event("You take everything out of the bank box.")
	_refresh_property()


func _on_chest_store() -> void:
	Property.merge(property.house_chest, hero.inventory)
	hero.inventory.clear()
	log_event("You store your bag in the house chest.")
	_refresh_property()


func _on_chest_take() -> void:
	Property.merge(hero.inventory, property.house_chest)
	property.house_chest.clear()
	log_event("You take everything from the house chest.")
	_refresh_property()


func _on_buy_deed(size: int) -> void:
	var deed: Dictionary = Property.DEEDS[size]
	property.bank_gold -= int(deed["price"])
	property.has_deed = true
	property.deed_size = size
	log_event("You buy a %s deed for %d gold from the bank." % [deed["name"], int(deed["price"])])
	_refresh_property()


func _on_exchange_deed(size: int) -> void:
	var diff := int(Property.DEEDS[size]["price"]) - int(Property.DEEDS[property.deed_size]["price"])
	property.bank_gold -= diff
	property.deed_size = size
	log_event("You exchange your deed for a %s deed." % Property.DEEDS[size]["name"])
	_refresh_property()


## Moves item kinds from the bag into the house's lock-downs while slots are free.
func _on_lock_down() -> void:
	for id in hero.inventory.keys():
		if not property.lockdowns.has(id) and property.lockdowns.size() >= property.lockdown_slots():
			continue                       # no slot for a new kind (existing kinds still stack)
		property.lockdowns[id] = int(property.lockdowns.get(id, 0)) + int(hero.inventory[id])
		hero.inventory.erase(id)
	log_event("You lock items down in your house. They stay safe even if it collapses.")
	_refresh_property()


func _on_release_lockdowns() -> void:
	Property.merge(hero.inventory, property.lockdowns)
	property.lockdowns.clear()
	log_event("You release your lock-downs into your bag.")
	_refresh_property()


func _on_co_owner(player_name: String) -> void:
	if property.co_owners.has(player_name):
		property.co_owners.erase(player_name)
		log_event("%s is no longer a co-owner of your house." % player_name)
	elif property.co_owners.size() < property.co_owner_slots():
		property.co_owners.append(player_name)
		log_event("%s is now a co-owner of your house and will help keep it standing." % player_name)
	_refresh_property()


## Packs the house back into a deed of the same size; everything inside goes to the bank.
func _on_redeed() -> void:
	Property.merge(property.bank_items, property.house_chest)
	Property.merge(property.bank_items, property.lockdowns)
	Property.merge(property.bank_items, property.vendor_stock)
	property.bank_gold += property.vendor_gold
	property.vendor_gold = 0
	world.remove_house(property.house_origin, property.house_size)
	_despawn_vendor()
	property.deed_size = property.house_size
	property.has_deed = true
	property.clear_house()
	log_event("You pack your house back into a deed. Its contents are in the bank.")
	_refresh_property()


func _despawn_vendor() -> void:
	if vendor_npc == null:
		return
	creatures.erase(vendor_npc)
	vendor_npc.queue_free()
	vendor_npc = null


## Tiles a new house must not cover: everyone's position and home, and corpses.
func _occupied_tiles() -> Dictionary:
	var occupied := {}
	for e in creatures:
		occupied[world.to_tile(e.position)] = true
		occupied[world.to_tile(e.home)] = true
	for c in corpses:
		occupied[world.to_tile(c.position)] = true
	return occupied


func _on_place_house() -> void:
	var o := world.find_house_spot(world.to_tile(hero.position), _occupied_tiles(), property.deed_size)
	if o.x < 0:
		log_event("There is no room for a house here. Try open ground.")
		return
	world.place_house(self, o, property.deed_size)
	property.house_origin = o
	property.house_size = property.deed_size
	property.house_chest = {}
	property.has_deed = false
	property.refresh()
	log_event("You place your house. Its chest is safe storage; visit it to keep it standing.")
	if property.vendor_hired:
		_spawn_vendor()
	_refresh_property()


## On load: rebuild the saved house, or let it collapse if it was neglected too long.
func _restore_house() -> void:
	if not property.has_house():
		return
	var center := world.tile_center(property.house_center_tile())
	if property.should_collapse():
		var ruins := Corpse.new()
		add_child(ruins)
		var spilled := property.house_chest.duplicate()
		Property.merge(spilled, property.vendor_stock)
		ruins.setup("House", true, false, 0, center,
			{"gold": property.vendor_gold, "reagents": 0, "items": spilled})
		property.vendor_gold = 0
		ruins.set_title("Ruins of your house")
		Property.merge(property.bank_items, property.lockdowns)   # lock-downs survive the collapse
		ruins.life = 600.0
		corpses.append(ruins)
		ruins.label.visible = property.corpse_names_on
		property.clear_house()
		log_event("Your neglected house has collapsed! Its chest lies in the ruins for anyone to take; your lock-downs were saved to the bank.")
		return
	var occupied := _occupied_tiles()
	occupied.erase(world.to_tile(hero.position))      # the hero may be standing inside it
	if not world.can_place_house(property.house_origin, occupied, property.house_size):
		Property.merge(property.bank_items, property.house_chest)
		Property.merge(property.bank_items, property.lockdowns)
		property.deed_size = property.house_size
		property.clear_house()
		property.has_deed = true
		log_event("Your house could not be rebuilt here; its deed and chest went to the bank.")
		return
	world.place_house(self, property.house_origin, property.house_size)
	if property.vendor_hired:
		_spawn_vendor()
		_settle_vendor_offline()


func _open_property() -> void:
	menu.visible = false
	property_panel.visible = true
	_refresh_property()


func _close_property() -> void:
	property_panel.visible = false
	menu.visible = true


## A centred, scrolling panel; the list box inside is stored as meta "box".
func _make_overlay(layer: CanvasLayer) -> Control:
	var overlay := CenterContainer.new()
	overlay.visible = false
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	overlay.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 20)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	pad.add_child(_scroll_wrap(box))
	_dress_overlay(overlay, box)
	overlay.set_meta("box", box)
	return overlay


# --- quests ----------------------------------------------------------------

## A health bar for the boss while you fight it.
func _boss_text() -> String:
	var t := hero.target
	if t == null or not is_instance_valid(t) or not t.is_boss or t.dead:
		return ""
	var frac := t.hp / float(t.stats.max_hp())
	var bar := "#".repeat(roundi(frac * 20.0)) + "-".repeat(20 - roundi(frac * 20.0))
	return "\n%s  [%s]  %d/%d" % [t.display_name, bar, ceili(t.hp), t.stats.max_hp()]


func _quest_text() -> String:
	if not property.quest_active:
		return "Quest: visit %s in town for work." % Quests.GIVER
	var q: Dictionary = Quests.LIST[property.quest_index]
	var done := _quest_done(q)
	var back := " - done, return to %s!" % Quests.GIVER if done else ""
	match Quests.kind(q):
		"fetch":
			return "Quest: bring %d %s (%d/%d), reward %d gold%s" % [Quests.goal(q), Items.item_name(String(q["item"])),
				Quests.progress(q, 0, hero.inventory), Quests.goal(q), int(q["reward"]), back]
		"escort":
			return "Quest: lead %s to %s, reward %d gold%s" % [q["escort"], q["place"], int(q["reward"]), back]
	return "Quest: slay %s%s (%d/%d), reward %d gold%s" % [
		"" if Quests.goal(q) == 1 else "%d " % Quests.goal(q), q["target"],
		Quests.progress(q, property.quest_kills, {}), Quests.goal(q), int(q["reward"]), back]


## Called by Entity._die for every death.
# --- keeping the frame rate up --------------------------------------------------------------

var _render_base := 1.0               # the 3D resolution aimed for (full)
var _render_scale := 1.0              # what it is right now
var _fps_acc := 0.0
var _fps_frames := 0


## Holding 60 frames a second. Measured every second: under 55, the 3D picture is drawn at a
## slightly lower resolution, a step at a time down to 75%; then the looks go one by one (see
## _set_quality); then the resolution again, down to half. After eight smooth seconds it all comes
## back a step at a time in the reverse order; whatever brings the stutter back stays off.
## Buttons and text always stay sharp.
const FPS_GOAL := 60
var _fps_good := 0                    # smooth two-second spells in a row
var _scale_cap := 1.0                 # the resolution it has learned not to go above
var _fps_windows := 0
var _raised_ago := 99                 # two-second spells since the resolution last went up


func _adapt_resolution(delta: float) -> void:
	_fps_acc += delta
	_fps_frames += 1
	if _fps_acc < 1.0:
		return
	var fps := _fps_frames / _fps_acc
	_fps_acc = 0.0
	_fps_frames = 0
	_fps_windows += 1
	if _fps_windows <= 6:
		return                                 # the first seconds stutter while everything loads: don't judge by them
	_raised_ago += 1
	var want := _render_scale
	var floor_scale := SCALE_FLOOR if _q < Q_MAX else 0.5   # the resolution goes below this only once everything else is off
	if fps < FPS_GOAL * 0.92:
		_fps_good = 0
		if _raised_ago <= 2 and _last_raise == "q":
			_q_floor = mini(_q + 1, Q_MAX)       # bringing that back cost too much: keep it off
			_set_quality(_q + 1)
		else:
			if _raised_ago <= 2:
				_scale_cap = maxf(_render_scale - 0.05, 0.5)   # going up again cost too much: stay below
			if _render_scale > floor_scale + 0.001:
				want = maxf(_render_scale - (0.1 if fps < FPS_GOAL * 0.8 else 0.05), floor_scale)
			elif _q < Q_MAX:
				_set_quality(_q + 1)              # the next thing off
	elif fps > FPS_GOAL * 0.97:
		_fps_good += 1
		if _fps_good >= 8:
			_fps_good = 0
			# back up in the reverse order: resolution to its floor, then the looks, then full resolution
			if _q == Q_MAX and _render_scale < SCALE_FLOOR - 0.001:
				want = minf(_render_scale + 0.05, SCALE_FLOOR)
				_raised_ago = 0
				_last_raise = "scale"
			elif _q > _q_floor:
				_set_quality(_q - 1)
				_raised_ago = 0
				_last_raise = "q"
			elif _render_scale < minf(_render_base, _scale_cap):
				want = minf(_render_scale + 0.05, minf(_render_base, _scale_cap))
				_raised_ago = 0
				_last_raise = "scale"
	else:
		_fps_good = 0
	if not is_equal_approx(want, _render_scale):
		_render_scale = want
		get_viewport().scaling_3d_scale = _render_scale


## What is drawn, by how much has had to go to hold 60 (each level adds to the ones before):
## 1 no glow, vignette or edge smoothing, 2 no sun shadows, 3 no grass and flowers, 4 no butterflies or
## leaves, 5 the camera sees 70 m (then the resolution may drop as low as half).
const Q_MAX := 5
const VIEW_FAR := 170.0               # the camera sees across the whole land (from the fly-by's height too), not 4 km
const SCALE_FLOOR := 0.75
var _q := 0
var _q_floor := 0                     # learned: the looks that couldn't be afforded stay off
var _last_raise := ""


func _set_quality(level: int) -> void:
	_q = clampi(level, 0, Q_MAX)
	env.glow_enabled = _q < 1
	if _grade != null:
		_grade.visible = _q < 1 and movie == null      # the vignette overlay (a full-screen layer) goes first
	get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if _q < 1 else Viewport.SCREEN_SPACE_AA_DISABLED
	sun.shadow_enabled = _q < 2
	for n in world.decor:
		if n != null:
			(n as Node3D).visible = _q < 3
	if _q >= 4:
		_butterflies.emitting = false
		_leaves.emitting = false
	if _q >= 5:
		cam.far = minf(cam.far, 70.0)
	elif cam.far < 80.0 and not property.first_person:
		cam.far = 130.0 if movie != null else VIEW_FAR


# --- the world in motion: banners, birds, butterflies, leaves, the ankhs ---------------------

const BANNER_SHADER := """
shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth : source_color = vec4(0.7, 0.15, 0.12, 1.0);
void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float free_end = UV.x;                        // fixed at the pole, flapping at the far end
	VERTEX.z += sin(TIME * 4.0 + UV.x * 6.0 + o.x) * 0.08 * free_end;
	VERTEX.y += sin(TIME * 3.0 + UV.x * 4.0 + o.z) * 0.03 * free_end;
}
void fragment() {
	ALBEDO = cloth.rgb * (0.85 + 0.15 * sin(UV.x * 20.0));   // a faint weave
	ROUGHNESS = 0.9;
}
"""
const TOWN_COLOURS := [Color(0.72, 0.16, 0.13), Color(0.18, 0.35, 0.72), Color(0.2, 0.55, 0.25), Color(0.85, 0.6, 0.15), Color(0.55, 0.3, 0.7)]
var _birds: Array[Node3D] = []
var _bird_wings: Array = []                 # [left pivot, right pivot] per bird
var _flock_centre := Vector3.ZERO
var _flock_dir := Vector3.RIGHT
var _butterflies: CPUParticles3D
var _leaves: CPUParticles3D
var _trees_near := 0


## Banners in each town's colours fly from poles at its four corners.
func _build_banners() -> void:
	var sh := Shader.new()
	sh.code = BANNER_SHADER
	var pole_mesh := Art.merge([[Art.box(0.08, 3.0, 0.08), Art.at(0, 1.5, 0), Color(0.42, 0.3, 0.18)],
		[Art.ball(0.08, 6, 3), Art.at(0, 3.05, 0), Color(0.9, 0.75, 0.3)]])
	for i in range(World.TOWNS.size()):
		var r: Rect2i = World.TOWNS[i]
		var mat := ShaderMaterial.new()
		mat.shader = sh
		mat.set_shader_parameter("cloth", TOWN_COLOURS[i % TOWN_COLOURS.size()])
		for corner in [r.position, Vector2i(r.end.x - 1, r.position.y), Vector2i(r.position.x, r.end.y - 1), r.end - Vector2i.ONE]:
			var t: Vector2i = corner
			var at := world.tile_center(t) + Vector3(0.0, 0.0, 0.0)
			if world.is_blocked(t):
				at.y = 1.5                                  # on top of the wall
			var pole := MeshInstance3D.new()
			pole.mesh = pole_mesh
			pole.material_override = Art.vc_mat()
			pole.position = at
			add_child(pole)
			var cloth := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(1.0, 0.6)
			q.subdivide_width = 6
			q.center_offset = Vector3(0.5, 0.0, 0.0)          # hangs from the pole, out to one side
			cloth.mesh = q
			cloth.material_override = mat
			cloth.position = Vector3(0.04, 2.6, 0.0)
			cloth.rotation.y = randf() * TAU
			pole.add_child(cloth)


## A small flock of birds wheeling over the land by day (on screen near you).
func _make_birds() -> void:
	var body := Art.merge([[Art.box(0.08, 0.06, 0.22), Art.at(0, 0, 0), Color(0.18, 0.16, 0.15)],
		[Art.box(0.05, 0.05, 0.06), Art.at(0, 0.02, -0.13), Color(0.25, 0.22, 0.2)]])
	var wing := Art.merge([[Art.box(0.26, 0.015, 0.1), Art.at(0.13, 0, 0), Color(0.22, 0.2, 0.19)]])
	for i in range(6):
		var b := Node3D.new()
		add_child(b)
		var mb := MeshInstance3D.new()
		mb.mesh = body
		mb.material_override = Art.vc_mat()
		mb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		b.add_child(mb)
		var pivots: Array = []
		for side: float in [1.0, -1.0]:
			var p := Node3D.new()
			b.add_child(p)
			var mw := MeshInstance3D.new()
			mw.mesh = wing
			mw.material_override = Art.vc_mat()
			mw.scale = Vector3(side, 1.0, 1.0)
			p.add_child(mw)
			pivots.append(p)
		b.scale = Vector3.ONE * 1.6
		_birds.append(b)
		_bird_wings.append(pivots)
	_flock_centre = hero.position + Vector3(-25.0, 6.0, 0.0)


## Ambient particles round you: butterflies over the meadows by day, leaves drifting down in the
## woods.
func _make_ambient_particles() -> void:
	_butterflies = CPUParticles3D.new()
	_butterflies.amount = 10
	_butterflies.lifetime = 5.0
	_butterflies.local_coords = false
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.vertex_color_use_as_albedo = true
	bm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = bm
	_butterflies.mesh = q
	_butterflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_butterflies.emission_box_extents = Vector3(8.0, 0.5, 8.0)
	_butterflies.gravity = Vector3(0.0, 0.05, 0.0)
	_butterflies.spread = 180.0
	_butterflies.initial_velocity_min = 0.3
	_butterflies.initial_velocity_max = 0.8
	_butterflies.orbit_velocity_min = -0.3            # fluttering in loops
	_butterflies.orbit_velocity_max = 0.3
	var cg := Gradient.new()
	cg.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	cg.colors = PackedColorArray([Color(1.0, 0.85, 0.2), Color(1.0, 1.0, 1.0), Color(0.55, 0.65, 1.0), Color(1.0, 0.5, 0.2)])
	_butterflies.color_initial_ramp = cg
	var flap := Curve.new()                            # wings beating: the size pulses
	for i in range(11):
		flap.add_point(Vector2(i / 10.0, 0.5 + 0.5 * absf(sin(i * 1.7))))
	_butterflies.scale_amount_curve = flap
	add_child(_butterflies)
	_leaves = CPUParticles3D.new()
	_leaves.amount = 14
	_leaves.lifetime = 6.0
	_leaves.local_coords = false
	var lq := QuadMesh.new()
	lq.size = Vector2(0.1, 0.07)
	var lm := StandardMaterial3D.new()
	lm.vertex_color_use_as_albedo = true
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	lq.material = lm
	_leaves.mesh = lq
	_leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_leaves.emission_box_extents = Vector3(7.0, 0.5, 7.0)
	_leaves.gravity = Vector3(0.25, -0.35, 0.1)        # drifting down on the breeze
	_leaves.initial_velocity_min = 0.0
	_leaves.initial_velocity_max = 0.2
	_leaves.angular_velocity_min = -180.0
	_leaves.angular_velocity_max = 180.0
	_leaves.particle_flag_rotate_y = true
	var lg := Gradient.new()
	lg.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	lg.colors = PackedColorArray([Color(0.35, 0.55, 0.2), Color(0.75, 0.6, 0.2), Color(0.65, 0.35, 0.15)])
	_leaves.color_initial_ramp = lg
	add_child(_leaves)


func _world_life(delta: float) -> void:
	if hero == null:
		return
	if _birds.is_empty():
		_make_birds()
		_make_ambient_particles()
	var t := Time.get_ticks_msec() / 1000.0
	var here := world.to_tile(hero.position)
	var day := not is_night()
	var wild := not world.is_town(here) and not world.is_dungeon(here)
	var nice := weather == "clear" and property.graphics != "low"
	# the flock drifts across, wheeling, and comes round again near you
	_flock_centre += _flock_dir * 3.0 * delta
	if _flock_centre.distance_to(hero.position) > 40.0:
		var a := randf() * TAU
		_flock_centre = hero.position + Vector3(cos(a), 0.0, sin(a)) * 30.0
		_flock_centre.y = 6.0
		_flock_dir = (hero.position - _flock_centre).normalized()
		_flock_dir.y = 0.0
	var show_birds := day and weather != "storm" and not world.is_dungeon(here)
	for i in range(_birds.size()):
		var b := _birds[i]
		b.visible = show_birds
		if not show_birds:
			continue
		var ang := t * 0.5 + i * 1.05
		var p := _flock_centre + Vector3(cos(ang) * (2.0 + i * 0.4), sin(t * 0.9 + i) * 0.5, sin(ang) * (2.0 + i * 0.4))
		var heading := p - b.position
		b.position = p
		if heading.length() > 0.001:
			b.rotation.y = atan2(-heading.x, -heading.z)
		var flap := sin(t * 11.0 + i * 1.3) * 0.7
		var wings: Array = _bird_wings[i]
		(wings[0] as Node3D).rotation.z = flap
		(wings[1] as Node3D).rotation.z = -flap
	# butterflies by day in the meadows, leaves in the woods
	_butterflies.emitting = day and wild and nice and _trees_near < 12 and _q < 4
	_butterflies.global_position = hero.position + Vector3(0.0, 0.8, 0.0)
	_leaves.emitting = wild and nice and _trees_near >= 6 and _q < 4
	_leaves.global_position = hero.position + Vector3(0.0, 3.5, 0.0)
	# the ankhs turn slowly and their light breathes
	for a in _ankhs:
		a.rotation.y += delta * 0.6
		var l := a.get_parent().get_child(2) as OmniLight3D
		if l != null:
			l.light_energy = 0.9 + 0.3 * sin(t * 1.5 + a.get_parent().position.x)


# --- the sounds of the world ---------------------------------------------------------------

var _amb_players := {}                   # "crickets", "water", "fire" -> AudioStreamPlayer
var _amb_acc := 0.0
var _heart_acc := 0.0
var _step_acc := 0.0
var _bird_in := 5.0
var _last_hero_pos := Vector3.ZERO


func _amb_player(sound_name: String) -> AudioStreamPlayer:
	if not _amb_players.has(sound_name):
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		p.bus = "Ambience"
		add_child(p)
		_amb_players[sound_name] = p
	return _amb_players[sound_name]


## Fades a loop towards `db` (-80 is silent), starting it once its sound is ready.
func _amb_set(sound_name: String, db: float) -> void:
	var p := _amb_player(sound_name)
	if p.stream == null:
		var st := sfx.loop_stream(sound_name)
		if st == null:
			return
		p.stream = st
	if db <= -60.0:
		if p.playing:
			p.volume_db = move_toward(p.volume_db, -80.0, 12.0)
			if p.volume_db <= -79.0:
				p.stop()
		return
	if not p.playing:
		p.volume_db = -60.0
		p.play()
	p.volume_db = move_toward(p.volume_db, db, 6.0)


func _ambience_tick(delta: float) -> void:
	if hero == null or autotest:
		return
	var on := property.sound_on and not hero.dead
	# footsteps
	var moved := hero.position.distance_to(_last_hero_pos) > 0.01
	_last_hero_pos = hero.position
	_step_acc -= delta
	if on and moved and hero.mounted_on == null and _step_acc <= 0.0:
		_step_acc = 0.36
		var t := world.to_tile(hero.position)
		sfx.play("step_stone" if world.is_town(t) or world.is_dungeon(t) else "step_grass", 1.0, -16.0)
	_amb_acc += delta
	if _amb_acc < 0.5:
		return
	_amb_acc = 0.0
	var tile := world.to_tile(hero.position)
	var space := "dungeon" if world.is_dungeon(tile) else ("cave" if world.is_cave(tile) else ("church" if world.in_church(tile) else ("town" if world.is_town(tile) else "wilds")))
	var near_death := not hero.dead and hero.hp < float(hero.stats.max_hp()) * 0.25
	Soundscape.update(space, hero.dead and hero.ghost, near_death)
	if near_death and on:
		_heart_acc += 0.5
		if _heart_acc >= 1.0:
			_heart_acc = 0.0
			sfx.play("heartbeat", 1.0, -6.0)
	if not on:
		for k in ["crickets", "water", "fire"]:
			_amb_set(k, -80.0)
		return
	var here := world.to_tile(hero.position)
	# crickets at night, out of the dungeon
	_amb_set("crickets", -20.0 if is_night() and not world.is_dungeon(here) else -80.0)
	# running water nearby; trees nearby (for the birds)
	var water_d := 99.0
	var trees := 0
	for dy in range(-7, 8):
		for dx in range(-7, 8):
			var c := here + Vector2i(dx, dy)
			if not world.in_bounds(c):
				continue
			var tt: int = world.tiles[c.y * world.cols + c.x]
			if tt == World.Tile.WATER:
				water_d = minf(water_d, Vector2(dx, dy).length())
			elif tt == World.Tile.TREE:
				trees += 1
	_amb_set("water", lerpf(-14.0, -36.0, water_d / 7.0) if water_d <= 7.0 else -80.0)
	_trees_near = trees
	# fire: braziers, campfires, the forge
	var fire_d := 99.0
	for l in brazier_lights:
		fire_d = minf(fire_d, l.global_position.distance_to(hero.position))
	for cf in campfires:
		var node: Node3D = cf["node"]
		if is_instance_valid(node):
			fire_d = minf(fire_d, node.global_position.distance_to(hero.position))
	if world.forge_tile.x >= 0:
		fire_d = minf(fire_d, world.tile_center(world.forge_tile).distance_to(hero.position))
	_amb_set("fire", lerpf(-12.0, -34.0, fire_d / 6.0) if fire_d <= 6.0 else -80.0)
	# birdsong by day among the trees
	_bird_in -= 0.5
	if _bird_in <= 0.0:
		_bird_in = randf_range(3.0, 9.0)
		if not is_night() and trees >= 4 and weather == "clear":
			sfx.play("bird", randf_range(0.9, 1.2), -12.0)


# --- achievements and titles ---------------------------------------------------------------

var _achieve_acc := 0.0


func _check_achievements() -> void:
	if autotest or hero == null:
		return
	for a: Dictionary in Achievements.LIST:
		var id := String(a["id"])
		if property.achievements.has(id):
			continue
		var p := Achievements.progress(a, property.stats_counts, hero.stats)
		if int(p[0]) < int(p[1]):
			continue
		property.achievements[id] = true
		var reward := int(a["gold"])
		hero.gold += reward
		log_event("Achievement: %s! %s. +%d gold, and the title \"%s\" (Statistics > Titles)." % [
			a["name"], a["desc"], reward, a["title"]])
		sound("gain", hero.position)
		if hero.position.distance_to(cam.position) < 40.0:
			Fx.sparkle(self, hero.position + Vector3(0.0, 1.0, 0.0), Color(1.0, 0.85, 0.4), 30)


func _set_title(t: String) -> void:
	property.title_choice = t
	hero.show_name(property.names_on)
	_refresh_stats()


# --- world events: the restless dead at night, orc warbands, champions -------------------------

const INVASION_EVERY := 600.0            # seconds between orc warbands (give or take)
const INVASION_LASTS := 360.0
const CHAMPION_EVERY := 900.0
const CHAMPION_LASTS := 600.0
const CHAMPIONS := [
	["Gorgath the Ravager", "ogre"], ["Ulmara the Bone Witch", "lich"], ["Kruul Ironhide", "ogre"],
]
var _event_acc := 0.0
var _night_up := false
var _night_dead: Array[Entity] = []
var _invasion_in := 300.0
var _invasion_left := 0.0
var invaders: Array[Entity] = []
var _invasion_town := ""
var _invasion_hero_kills := 0
var _champion_in := 480.0
var _champion_left := 0.0
var champion: Entity


func _events_tick(delta: float) -> void:
	if autotest:
		return                                # the play-test keeps to the ordinary world
	_event_acc += delta
	if _event_acc < 1.0:
		return
	var dt := _event_acc
	_event_acc = 0.0
	# the restless dead walk the wilds at night and crumble at dawn
	var night := is_night()
	if night and not _night_up:
		_night_up = true
		_raise_night_dead()
	elif not night and _night_up:
		_night_up = false
		_lay_night_dead()
	# orc warbands
	if invaders.is_empty():
		_invasion_in -= dt
		if _invasion_in <= 0.0:
			_start_invasion()
	else:
		_invasion_left -= dt
		var alive := 0
		for e in invaders:
			if not e.dead:
				alive += 1
		if alive == 0:
			_end_invasion(true)
		elif _invasion_left <= 0.0:
			_end_invasion(false)
	# champions
	if champion == null:
		_champion_in -= dt
		if _champion_in <= 0.0:
			_start_champion()
	else:
		_champion_left -= dt
		if champion.dead:
			champion = null
			_champion_in = CHAMPION_EVERY * randf_range(0.8, 1.2)
		elif _champion_left <= 0.0:
			event_about("%s fades back into the wilds." % champion.display_name, true)
			champion.vanish()
			champion = null
			_champion_in = CHAMPION_EVERY * randf_range(0.8, 1.2)


func _wild_spot() -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return world.tile_center(world.open_tile_in(world.zone_rect(rng.randi() % world.zone_count()), rng))


func _raise_night_dead() -> void:
	var kinds := [["Skeleton", Bestiary.SKELETON, Color("d8d2c0")], ["Zombie", Bestiary.ZOMBIE, Color("6f8f5a")],
		["Skeleton Archer", Bestiary.SKELETON_ARCHER, Color("d8d2c0")]]
	_night_dead.clear()
	for i in range(3):
		var k: Array = kinds[i % kinds.size()]
		_night_dead.append(pool_spawn(String(k[0]), k[1], k[2], _wild_spot()))
	event_about("Night falls, and the restless dead rise in the wilds.", true)


func _lay_night_dead() -> void:
	for e in _night_dead:
		if not e.dead:
			if e.position.distance_to(hero.position) < 20.0:
				e._pop("crumbles to dust", Color(0.8, 0.8, 0.75))
				Fx.sparkle(self, e.position + Vector3(0.0, 0.6, 0.0), Color(0.75, 0.72, 0.65), 14)
			e.vanish()
	_night_dead.clear()
	event_about("Dawn breaks, and the restless dead crumble to dust.", true)


## Orcs march on a town: a warband with a Warlord camps outside its gates.
func _start_invasion() -> void:
	var i := randi() % World.TOWNS.size()
	var r: Rect2i = World.TOWNS[i]
	_invasion_town = String(World.TOWN_NAMES[i])
	var centre := Vector2(r.position) + Vector2(r.size) / 2.0
	var dir := Vector2.RIGHT.rotated(randf() * TAU)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	# a camp just outside the town, and where the warband gathers first, further out
	var camp_t := Vector2i(centre + dir * (maxf(r.size.x, r.size.y) / 2.0 + 4.0)).clamp(Vector2i(2, 2), Vector2i(world.cols - 3, world.rows - 3))
	var camp := world.tile_center(world.open_tile_in(Rect2i(camp_t - Vector2i(2, 2), Vector2i(5, 5)), rng))
	var start_t := Vector2i(centre + dir * (maxf(r.size.x, r.size.y) / 2.0 + 14.0))
	start_t = start_t.clamp(Vector2i(1, 1), Vector2i(world.cols - 2, world.rows - 2))
	var start := world.tile_center(world.open_tile_in(Rect2i(start_t - Vector2i(3, 3), Vector2i(7, 7)), rng))
	invaders.clear()
	var warlord := Bestiary.ORC.duplicate()
	warlord["str"] = 80
	warlord["dmg_min"] = 7
	warlord["dmg_max"] = 15
	warlord["scale"] = 1.4
	warlord["danger"] = 5
	warlord["armor"] = 4.0
	warlord["boss"] = true
	warlord["loot"] = {"gold_min": 150, "gold_max": 300, "drops": [["chainmail", 0.4], ["broadsword", 0.4], ["orc_ear", 1.0]]}
	invaders.append(pool_spawn("Orc Warlord", warlord, Color("8a2a20"), start))
	for k in range(5):
		var cfg: Dictionary = Bestiary.ORC_ARCHER if k % 3 == 2 else Bestiary.ORC
		invaders.append(pool_spawn("Orc Raider" if k % 3 != 2 else "Orc Archer", cfg, Color("c0392b"), start + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))))
	for e in invaders:
		e.home = camp                          # they march on the town and camp at its gates
		e.go_to(camp)
	_invasion_left = INVASION_LASTS
	_invasion_hero_kills = 0
	var v := camp - hero.position
	event_about("An orc warband marches on %s! It will camp outside the gates (%d m %s of you)." % [
		_invasion_town, roundi(v.length()), _compass(v)], true)


func _end_invasion(beaten: bool) -> void:
	if beaten:
		event_about("The orc warband at %s is destroyed!" % _invasion_town, true)
		if _invasion_hero_kills > 0:
			var reward := 60 * _invasion_hero_kills
			hero.gold += reward
			hero.add_fame(25 * _invasion_hero_kills)
			count("gold_earned", reward)
			count("invasions_repelled")
			log_event("The grateful townsfolk reward you with %d gold for the %d raider%s you slew." % [
				reward, _invasion_hero_kills, "" if _invasion_hero_kills == 1 else "s"])
	else:
		event_about("The orc warband at %s withdraws into the wilds." % _invasion_town, true)
		for e in invaders:
			if not e.dead:
				e.vanish()
	invaders.clear()
	_invasion_in = INVASION_EVERY * randf_range(0.8, 1.2)


## A champion rises somewhere in the wilds: much tougher than its kind, a health bar when you
## fight it, and a treasure chest when it falls.
func _start_champion() -> void:
	var pick: Array = CHAMPIONS[randi() % CHAMPIONS.size()]
	var base: Dictionary = Bestiary.LICH if String(pick[1]) == "lich" else Bestiary.OGRE
	var cfg := base.duplicate()
	cfg["str"] = int(base["str"]) * 2
	cfg["dmg_min"] = int(base["dmg_min"]) * 2
	cfg["dmg_max"] = int(base["dmg_max"]) * 2
	cfg["scale"] = float(base.get("scale", 1.0)) * 1.4
	cfg["danger"] = 9
	cfg["armor"] = float(base.get("armor", 0.0)) + 4.0
	cfg["boss"] = true
	cfg["leash"] = 6
	cfg["loot"] = {"gold_min": 500, "gold_max": 1000, "reagents": 20, "drops": [["platemail", 0.3], ["heater_shield", 0.3]]}
	var at := _wild_spot()
	champion = pool_spawn(String(pick[0]), cfg, Color("5a1a10") if String(pick[1]) == "ogre" else Color("4a2a6a"), at)
	_champion_left = CHAMPION_LASTS
	var v := at - hero.position
	event_about("A champion, %s, has risen %d m %s of you! Its lair is marked on the map." % [
		champion.display_name, roundi(v.length()), _compass(v)], true)


# --- the main story: The Shattered Sight -------------------------------------------------------

var story_panel: Control
var story_box: VBoxContainer
var story_hint: Label
var story_boss: Entity
var story_target := Vector3.ZERO          # where the current chapter leads (a violet mark on the map)
var has_story_target := false
var _story_acc := 0.0
var _circle_light: OmniLight3D


func _build_story_ui(layer: CanvasLayer) -> void:
	story_panel = _make_overlay(layer)
	story_box = story_panel.get_meta("box")
	story_hint = Label.new()
	story_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_hint.add_theme_font_size_override("font_size", 20)
	story_hint.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	story_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	story_hint.add_theme_constant_override("outline_size", 8)
	story_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	story_hint.visible = false
	layer.add_child(story_hint)
	story_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 14)
	story_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH


## The Broken Circle: eight standing stones round an altar in the heart of the land, where the
## story ends. A violet light wakes in it while the Shardbreaker waits there.
func _build_broken_circle() -> void:
	var c := world.tile_center(Story.SITE)
	var stone := Color(0.42, 0.4, 0.44)
	var menhir := Art.merge([[Art.box(0.45, 1.8, 0.35), Art.at(0, 0.9, 0), stone],
		[Art.box(0.5, 0.2, 0.4), Art.at(0, 1.85, 0), stone.lightened(0.1)]])
	var altar := Art.merge([[Art.box(1.0, 0.5, 0.7), Art.at(0, 0.25, 0), stone.darkened(0.15)],
		[Art.box(1.1, 0.08, 0.8), Art.at(0, 0.52, 0), stone.lightened(0.05)]])
	var node := Node3D.new()
	add_child(node)
	node.position = c
	var a := MeshInstance3D.new()
	a.mesh = altar
	a.material_override = Art.vc_mat()
	node.add_child(a)
	for i in range(8):
		var ang := TAU * i / 8.0
		var p := Vector3(cos(ang), 0.0, sin(ang)) * 3.2 * World.TILE
		var m := MeshInstance3D.new()
		m.mesh = menhir
		m.material_override = Art.vc_mat()
		node.add_child(m)
		m.position = Vector3(p.x, world.height_at(c + p) - c.y, p.z)
		m.rotation.y = -ang + PI / 2.0
	_circle_light = OmniLight3D.new()
	_circle_light.light_color = Color(0.7, 0.45, 1.0)
	_circle_light.light_energy = 0.0
	_circle_light.omni_range = 8.0
	_circle_light.position = Vector3(0.0, 1.5, 0.0)
	node.add_child(_circle_light)


func _show_chapter() -> void:
	if autotest:
		return
	_open_story()


## The story panel: the current chapter (or the epilogue), your task, and the chapters behind you.
func _open_story() -> void:
	paused = true
	menu.visible = false
	story_panel.visible = true
	for ch in story_box.get_children():
		story_box.remove_child(ch)
		ch.queue_free()
	var t := _info("The Shattered Sight")
	t.add_theme_font_size_override("font_size", 32)
	t.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0))
	story_box.add_child(t)
	if property.story_done:
		story_box.add_child(_heading("Epilogue"))
		story_box.add_child(_info(Story.EPILOGUE))
	else:
		var step: Dictionary = Story.STEPS[property.story_step]
		story_box.add_child(_heading(String(step["title"])))
		story_box.add_child(_info(String(step["text"])))
		var goal := _info("Your task: " + String(step["goal"]))
		goal.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
		story_box.add_child(goal)
	if property.story_step > 0 or property.story_done:
		story_box.add_child(_heading("The story so far"))
		var last := Story.STEPS.size() if property.story_done else property.story_step
		for i in range(last):
			story_box.add_child(_small(String(Story.STEPS[i]["title"]) + "  (done)"))
	story_box.add_child(_menu_button("Continue", _close_story))


func _close_story() -> void:
	story_panel.visible = false
	_resume()
	_cine_release()                               # the camera rises back to the usual view


## Where the current chapter leads, for the hint and the minimap (false if nowhere in particular).
func _story_goal_pos() -> bool:
	if property.story_done:
		return false
	var step: Dictionary = Story.STEPS[property.story_step]
	match String(step["kind"]):
		"talk":
			for c in creatures:
				if c.display_name == String(step["who"]):
					story_target = c.position
					return true
		"shrine":
			var best := INF
			for p in shrines:
				if p.distance_to(hero.position) < best:
					best = p.distance_to(hero.position)
					story_target = p
			return best < INF
		"kill":
			if step.has("area"):
				var r: Rect2i = step["area"]
				story_target = world.tile_center(r.get_center())
				return true
			for c in creatures:
				if c.display_name == String(step["target"]) and not c.dead:
					story_target = c.position
					return true
		"boss":
			story_target = world.tile_center(Story.SITE)
			return true
	return false


func _story_tick(delta: float) -> void:
	if autotest or hero == null or property.story_done or movie != null:   # (the story waits for the real game)
		if story_hint != null:
			story_hint.visible = false
		return
	_story_acc += delta
	if _story_acc < 0.5:
		return
	_story_acc = 0.0
	if not property.story_started:
		if _flyby_t >= 0.0:
			return                                # wait for the title and fly-by to finish
		property.story_started = true
		_show_chapter()
		return
	var step: Dictionary = Story.STEPS[property.story_step]
	has_story_target = _story_goal_pos()
	if has_story_target:
		var v := story_target - hero.position
		story_hint.text = "%s   %d m %s" % [step["goal"], roundi(v.length()), _compass(v)]
	else:
		story_hint.text = String(step["goal"])
	story_hint.visible = true
	if hero.dead:
		return
	match String(step["kind"]):
		"talk":
			if has_story_target and hero.position.distance_to(story_target) <= 3.5:
				_story_advance(story_target)
		"shrine":
			if has_story_target and hero.position.distance_to(story_target) <= 2.5:
				_story_advance(story_target)
		"boss":
			# the Shardbreaker waits at the Broken Circle (and returns there if it fades away)
			if story_boss == null or (story_boss.dead and not story_boss.visible):
				story_boss = pool_spawn(Story.BOSS_NAME, Story.BOSS, Color("3a1a4a"), world.tile_center(Story.SITE) + Vector3(0.0, 0.0, 1.5))
			if _circle_light != null:
				_circle_light.light_energy = 2.0 + 0.6 * sin(Time.get_ticks_msec() * 0.004)
			# the first sight of him: the camera comes down to look the Shardbreaker in the eye
			if not _boss_revealed and story_boss != null and not story_boss.dead \
					and hero.position.distance_to(story_boss.position) <= 16.0 and _cine_phase == 0:
				_boss_revealed = true
				log_event("Malgrath the Shardbreaker rises at the Broken Circle: \"Give me the Shard, little thief.\"")
				_cine_start(story_boss.position + Vector3(0.0, 0.6, 0.0), Callable(), 3.0)


# --- story scenes: the camera comes down to the hero's eyes and looks at what matters ----------

const CINE_IN := 1.4                      # seconds to come down from the overhead view
const CINE_OUT := 1.1                     # seconds to rise back to it
var _cine_phase := 0                      # 0 none, 1 coming down, 2 holding, 3 going back up
var _cine_t := 0.0
var _cine_hold := 0.0                     # seconds to hold when there's no story panel
var _cine_from_pos := Vector3.ZERO
var _cine_from_look := Vector3.ZERO
var _cine_focus := Vector3.ZERO
var _cine_then: Callable                  # what happens once the camera is down (the story panel)
var _boss_revealed := false


## Starts a story scene: the camera glides from wherever it is down to the hero's eyes, looking
## at `focus`; then `then` runs (the story panel), or it holds for `hold` seconds; then it rises
## back to the usual view.
func _cine_start(focus: Vector3, then: Callable, hold := 0.0) -> void:
	if autotest:
		if then.is_valid():
			then.call()
		return
	_cine_phase = 1
	_cine_t = 0.0
	_cine_hold = hold
	_cine_then = then
	_cine_focus = focus + Vector3(0.0, 1.3, 0.0)
	_cine_from_pos = cam.position
	_cine_from_look = _hero_cam_look() if not property.first_person else cam.position + _fp_dir() * 4.0
	hero.path.clear()
	hero.target = null


## The hero's eyes, turned towards the scene.
func _cine_eye() -> Vector3:
	var eye := hero.position + Vector3(0.0, 1.55 * hero.visual_scale, 0.0)
	var to := _cine_focus - eye
	to.y = 0.0
	if to.length() > 0.01:
		eye -= to.normalized() * 0.6              # a step back, so the scene fits the view
		hero._face(to)
	return eye


func _cine_step(delta: float) -> bool:
	if _cine_phase == 0:
		return false
	_cine_t += delta
	var pos: Vector3
	var look: Vector3
	match _cine_phase:
		1:
			var k := smoothstep(0.0, 1.0, minf(_cine_t / CINE_IN, 1.0))
			pos = _cine_from_pos.lerp(_cine_eye(), k)
			look = _cine_from_look.lerp(_cine_focus, k)
			if hero.rig != null:
				hero.rig.visible = k < 0.6               # out of the way as we reach the eyes
			if _cine_t >= CINE_IN:
				_cine_phase = 2
				_cine_t = 0.0
				if _cine_then.is_valid():
					_cine_then.call()                     # the story panel (it pauses the game)
		2:
			pos = _cine_eye()
			look = _cine_focus
			if not _cine_then.is_valid() and _cine_t >= _cine_hold:
				_cine_release()
		3:
			var k := smoothstep(0.0, 1.0, minf(_cine_t / CINE_OUT, 1.0))
			pos = _cine_from_pos.lerp(_hero_cam_pos(), k)
			look = _cine_from_look.lerp(_hero_cam_look(), k)
			if hero.rig != null:
				hero.rig.visible = k > 0.4 and not property.first_person
			if _cine_t >= CINE_OUT:
				_cine_phase = 0
				return false
	cam.position = pos
	cam.look_at(look, Vector3.UP)
	view_planes = cam.get_frustum()
	return true


## The scene is over: rise back to the usual view.
func _cine_release() -> void:
	if _cine_phase != 2:
		return
	_cine_phase = 3
	_cine_t = 0.0
	_cine_from_pos = cam.position
	_cine_from_look = _cine_focus


func _story_on_kill(killer: Entity, victim: Entity) -> void:
	if autotest or property.story_done:
		return
	var step: Dictionary = Story.STEPS[property.story_step]
	var k := killer
	if k != null and k.kind == Entity.Kind.PET and k.pet_owner != null:
		k = k.pet_owner
	match String(step["kind"]):
		"kill":
			if k != hero or victim.display_name != String(step["target"]):
				return
			if step.has("area") and not (step["area"] as Rect2i).has_point(world.to_tile(victim.position)):
				return
			_story_advance(victim.position)
		"boss":
			if victim == story_boss:
				_story_advance(victim.position)


## The chapter is done: its reward, then (with the camera down at the hero's eyes, looking at
## where it happened) the next chapter is told.
func _story_advance(subject: Vector3) -> void:
	var step: Dictionary = Story.STEPS[property.story_step]
	var gold := int(step.get("gold", 0))
	hero.gold += gold
	hero.add_fame(int(step.get("fame", 0)))
	count("gold_earned", gold)
	var reward := "%d gold" % gold
	if step.has("item"):
		var item := String(step["item"])
		hero.inventory[item] = 1
		reward += " and the " + Items.item_name(item)
	if step.has("title_reward"):
		property.title_choice = String(step["title_reward"])
		hero.show_name(property.names_on)
		reward += "; you are known as %s %s" % [hero.display_name, step["title_reward"]]
	log_event("%s - done! (%s)" % [step["title"], reward])
	sound("gain", hero.position)
	Fx.sparkle(self, hero.position + Vector3(0.0, 1.0, 0.0), Color(0.85, 0.7, 1.0), 30)
	count("story_chapters")
	if String(step["kind"]) == "boss":
		for f in ["shard_fragment_1", "shard_fragment_2", "shard_fragment_3"]:
			hero.inventory.erase(f)                # the fragments become one
		hero.inventory["shard_of_sight"] = 1
		if _circle_light != null:
			_circle_light.light_energy = 0.0
	if property.story_step >= Story.STEPS.size() - 1:
		property.story_done = true
		count("story_finished")
	else:
		property.story_step += 1
	_cine_start(subject, _show_chapter)


func on_kill(killer: Entity, victim: Entity) -> void:
	_story_on_kill(killer, victim)
	if killer != null and killer.is_hero and invaders.has(victim):
		_invasion_hero_kills += 1
	if victim == champion:
		_drop_chest(victim)                      # a champion always leaves treasure
		event_about("%s has been slain%s!" % [victim.display_name,
			(" by " + killer.display_name) if killer != null else ""], true)
		if killer != null and killer.is_hero:
			count("champions_slain")
	if killer != null and victim.kind == Entity.Kind.MONSTER:    # pets learn from the kills they share in
		var master: Entity = killer.pet_owner if killer.kind == Entity.Kind.PET else killer
		if master != null:
			for pet in master.pets:
				if not pet.dead and (pet == killer or pet == master.mounted_on or pet.position.distance_to(victim.position) < 10.0):
					pet.pet_gain_xp(victim.danger * (10.0 if pet == killer else 5.0))
	if killer != null and killer.kind == Entity.Kind.PET and killer.pet_owner != null:
		if killer.pet_owner.is_hero:
			count("pet_kills")
		killer = killer.pet_owner                # a pet's kill counts for its owner (quests too)
	if killer != null and killer.kind == Entity.Kind.PLAYER and killer != victim:
		killer.reputation_for_kill(victim)
	if frontier != null:
		frontier.on_kill(killer, victim)
	if victim.kind == Entity.Kind.PLAYER:
		victim.add_fame(-victim.fame / 10)       # dying costs a tenth of your fame
	if killer != null and killer.is_hero:
		count("kills")
		count("hero_killed_" + victim.display_name)
	if killer == null or not killer.is_hero or not property.quest_active:
		return
	var q: Dictionary = Quests.LIST[property.quest_index]
	if not Quests.kind(q) in ["kill", "boss"]:
		return                                   # fetch and escort quests don't count kills
	if victim.display_name != String(q["target"]) or property.quest_kills >= int(q["count"]):
		return
	property.quest_kills += 1
	log_event("Quest: %d/%d %s slain." % [property.quest_kills, int(q["count"]), q["target"]])
	if property.quest_kills >= int(q["count"]):
		log_event("Quest complete! Return to %s for your reward." % Quests.GIVER)


## Standing near the captain hands in a finished quest and takes the next one.
func _quest_tick() -> void:
	if hero.dead:
		return
	var captain := _role_entity("questgiver")
	if captain == null or captain.position.distance_to(hero.position) > 3.0:
		return
	if property.quest_active:
		var q: Dictionary = Quests.LIST[property.quest_index]
		if not _quest_done(q):
			return
		if Quests.kind(q) == "fetch":
			Crafting.take_mats(hero.inventory, {String(q["item"]): int(q["count"])}, 1.0)
		hero._earn(int(q["reward"]))
		hero.add_fame(int(q["reward"]) / 3)
		hero.add_karma(int(q["reward"]) / 4)
		count("quests_completed")
		count("quests_" + Quests.kind(q))
		log_event("%s: Well done! Here are %d gold." % [Quests.GIVER, int(q["reward"])])
		property.quest_active = false
		property.quest_index = (property.quest_index + 1) % Quests.LIST.size()
	var next: Dictionary = Quests.LIST[property.quest_index]
	property.quest_active = true
	property.quest_kills = 0
	property.quest_escorted = false
	log_event("%s: %s Reward: %d gold." % [Quests.GIVER, next["text"], int(next["reward"])])
	_ensure_escort()


func _quest_done(q: Dictionary) -> bool:
	if Quests.kind(q) == "escort":
		return property.quest_escorted
	return Quests.progress(q, property.quest_kills, hero.inventory) >= Quests.goal(q)


func _current_quest() -> Dictionary:
	return Quests.LIST[property.quest_index] if property.quest_active else {}


## The item an active fetch quest wants (the hero won't sell it), or "".
func quest_item() -> String:
	var q := _current_quest()
	return String(q["item"]) if not q.is_empty() and Quests.kind(q) == "fetch" else ""


## Where an escort is headed, or null.
func escort_destination() -> Variant:
	var q := _current_quest()
	if q.is_empty() or Quests.kind(q) != "escort" or property.quest_escorted:
		return null
	return world.tile_center(Vector2i(int(q["to"][0]), int(q["to"][1])))


## Where the hero on Auto should head for a quest: the escort's destination, or back to the
## captain once a quest is done. null when there is nothing to walk to.
func quest_walk_target() -> Variant:
	var q := _current_quest()
	if q.is_empty():
		return null
	if Quests.kind(q) == "escort" and not property.quest_escorted:
		return escort_destination() if escortee != null else null
	if _quest_done(q):
		var captain := _role_entity("questgiver")
		return captain.position if captain != null else null
	return null


var escortee: Entity = null


## An escort quest is active and its traveller isn't with us yet: they appear next to the hero.
func _ensure_escort() -> void:
	var q := _current_quest()
	if q.is_empty() or Quests.kind(q) != "escort" or property.quest_escorted or escortee != null:
		return
	escortee = _spawn(Entity.Kind.NPC, String(q["escort"]), Bestiary.ESCORT, Color("d8c8a0"), world.to_tile(hero.position))
	log_event("%s: Lead the way to %s, I'll stay close behind you." % [q["escort"], q["place"]])


func escort_arrived(e: Entity) -> void:
	if property.quest_escorted:
		return
	property.quest_escorted = true
	log_event("%s: We made it! Thank you. Captain Marcus will reward you." % e.display_name)
	call_deferred("_despawn_escort")


func _despawn_escort() -> void:
	if escortee == null:
		return
	creatures.erase(escortee)
	escortee.queue_free()
	escortee = null


## The Bone King calls two skeletons out of the ground; they crumble after a minute.
func raise_minions(boss: Entity) -> void:
	for i in range(2):
		pending_spawns.append({"name": "Risen Skeleton", "cfg": Bestiary.SKELETON, "color": Color("d8d2c0"),
			"tile": world.to_tile(boss.position), "temp_secs": 60.0})
	event_about("%s raises the dead!" % boss.display_name, hero.target == boss)


func _role_entity(r: String) -> Entity:
	for e in creatures:
		if e.role == r:
			return e
	return null


# --- moongates (Gate Travel) -----------------------------------------------

## Opens a two-way gate between two points for a while. Anyone walking into one end comes out
## of the other (monsters too).
func open_gate(a: Vector3, b: Vector3) -> void:
	var nodes: Array[Node3D] = []
	for p in [a, b]:
		var gate := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.4
		mesh.bottom_radius = 0.4
		mesh.height = 2.0
		gate.mesh = mesh
		var mat := World._mat(Color(0.3, 0.5, 1.0))
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.4, 1.0)
		gate.material_override = mat
		gate.transparency = 0.4
		add_child(gate)
		gate.position = p + Vector3(0.0, 1.0, 0.0)
		nodes.append(gate)
	gates.append({"a": a, "b": b, "life": GATE_SECONDS, "nodes": nodes})


func _gates_tick(delta: float) -> void:
	for g in gates.duplicate():
		g["life"] = float(g["life"]) - delta
		if float(g["life"]) <= 0.0:
			for n in g["nodes"]:
				(n as Node3D).queue_free()
			gates.erase(g)
	for e in creatures:
		if e.dead or e.kind == Entity.Kind.NPC:
			continue
		for g in gates:
			var a: Vector3 = g["a"]
			var b: Vector3 = g["b"]
			var at_a := e.position.distance_to(a) < 0.6
			var at_b := e.position.distance_to(b) < 0.6
			if not at_a and not at_b:
				continue
			if e.gate_cd > 0.0:
				e.gate_cd = maxf(e.gate_cd, 0.5)   # just arrived: must step out before going back
			else:
				e.teleport_to(b if at_a else a)
			break


# --- travel menu -----------------------------------------------------------

func _refresh_travel() -> void:
	for c in travel_box.get_children():
		travel_box.remove_child(c)
		c.queue_free()
	var title := _info("Travel magic")
	title.add_theme_font_size_override("font_size", 30)
	travel_box.add_child(title)
	travel_box.add_child(_info("Runebook (%d of %d runes). Recall and Gate Travel use the selected rune; Mark adds a rune where you stand (when the book is full it replaces the selected one)." % [
		property.runes.size(), Property.MAX_RUNES]))
	for i in range(property.runes.size()):
		var r: Vector2i = property.runes[i]
		var label := "%s %d. %s (%d,%d)%s" % [
			">" if r == property.rune else " ", i + 1, world.place_name(r), r.x, r.y,
			" - the town square" if r == DEFAULT_RUNE else ""]
		var row := HBoxContainer.new()
		var pick := _action(label, _on_select_rune.bind(i), r != property.rune)
		pick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(pick)
		row.add_child(_action("Forget", _on_forget_rune.bind(i), property.runes.size() > 1))
		travel_box.add_child(row)
	for id in ["recall", "mark", "gate_travel"]:
		var sp: Dictionary = Spells.LIST[id]
		var problem := hero.travel_problem(id)
		travel_box.add_child(_info("%s: circle %d, %d mana, Magery %.1f, %d%% chance%s" % [
			sp["name"], int(sp["circle"]), int(sp["mana"]), float(sp["min"]),
			roundi(Rules.cast_chance(float(hero.stats.skills[Hero.Skill.MAGERY]), float(sp["min"])) * 100.0),
			"" if problem == "" else " (" + problem + ")"]))
		travel_box.add_child(_action("Cast " + String(sp["name"]), _on_travel.bind(id), problem == ""))
	travel_box.add_child(_info("Recall takes you to the selected rune; Mark adds a rune where you stand; Gate Travel opens a moongate there that anyone can use for %d seconds." % int(GATE_SECONDS)))
	# The spellbook: what you know, circle by circle. Scrolls drop from monsters (tougher ones
	# carry higher circles) and merchants sell circles 1-6; they are copied in automatically.
	var spellbook_title := _info("Spellbook (%d of %d spells)" % [hero.spellbook.size(), Spells.ORDER.size()])
	spellbook_title.add_theme_font_size_override("font_size", 28)
	travel_box.add_child(spellbook_title)
	for circle in range(1, 9):
		var known: Array[String] = []
		var missing: Array[String] = []
		for id in Spells.ORDER:
			if int(Spells.LIST[id]["circle"]) != circle:
				continue
			(known if hero.spellbook.has(id) else missing).append(String(Spells.LIST[id]["name"]))
		travel_box.add_child(_info("Circle %d: %s%s" % [circle,
			", ".join(known) if not known.is_empty() else "-",
			("   (missing: " + ", ".join(missing) + ")") if not missing.is_empty() else ""]))
	travel_box.add_child(_info("Scrolls drop from monsters (tougher ones carry higher circles) and merchants sell circles 1-%d. A new scroll is copied into your book as soon as you pick it up." % Entity.SHOP_SCROLL_CIRCLES))
	travel_box.add_child(_info("Cast a spell (harmful ones go at your target or the nearest foe; corpse spells at the nearest corpse):"))
	for id in Spells.ORDER:
		if not hero.spellbook.has(id) or String(Spells.LIST[id]["kind"]) == "travel":
			continue
		var sp: Dictionary = Spells.LIST[id]
		travel_box.add_child(_action("Cast %s (circle %d, %d mana)" % [sp["name"], int(sp["circle"]), int(sp["mana"])],
			_on_cast_from_book.bind(id), hero.can_cast(id)))
	travel_box.add_child(_menu_button("Back", _close_travel))


func _on_cast_from_book(id: String) -> void:
	hero.cast_from_book(id)
	travel_panel.visible = false
	_resume()


func _on_select_rune(i: int) -> void:
	property.select_rune(i)
	_refresh_travel()


func _on_forget_rune(i: int) -> void:
	property.forget_rune(i)
	_refresh_travel()


func _on_travel(id: String) -> void:
	hero.cast_travel(id)
	travel_panel.visible = false
	_resume()                      # the spell finishes once the game runs again


func _open_travel() -> void:
	menu.visible = false
	travel_panel.visible = true
	_refresh_travel()


func _close_travel() -> void:
	travel_panel.visible = false
	menu.visible = true


# --- automated play-test ---------------------------------------------------

## Counts something for the play-test report (does nothing in normal play).
func count(key: String, n := 1) -> void:
	if autotest:
		counters[key] = int(counters.get(key, 0)) + n
	else:
		property.stats_counts[key] = int(property.stats_counts.get(key, 0)) + n   # Statistics


static func _autotest_seconds_arg() -> float:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autotest-seconds="):
			return maxf(60.0, float(a.trim_prefix("--autotest-seconds=")))
	return 900.0


func _note_problem(msg: String) -> void:
	if not problems.has(msg) and problems.size() < 20:
		problems.append(msg)


func _autotest_tick(delta: float) -> void:
	autotest_time += delta
	# Where the hero's time goes: game-seconds per state (first word of its state text).
	var state_key := "t_" + hero.state_text().split(" ")[0]
	counters[state_key] = float(counters.get(state_key, 0.0)) + delta
	# What a "fighting" or "looting" hero is stuck on, and whether it is close enough to act.
	if hero.target != null and is_instance_valid(hero.target) and not hero.dead:
		var tk := "tt_" + hero.target.display_name
		counters[tk] = float(counters.get(tk, 0.0)) + delta
		var near := hero.position.distance_to(hero.target.position) <= Entity.MELEE_RANGE + 0.1
		var fk := "t_fight_near" if near else ("t_fight_casting" if hero.casting_id != "" else "t_fight_far")
		counters[fk] = float(counters.get(fk, 0.0)) + delta
		if not near and hero.path.is_empty() and hero.casting_id == "":
			counters["t_fight_far_no_path"] = float(counters.get("t_fight_far_no_path", 0.0)) + delta
	if hero.target == null and hero.loot_target != null and is_instance_valid(hero.loot_target):
		var lk := "t_loot_no_path" if hero.path.is_empty() else "t_loot_walking"
		counters[lk] = float(counters.get(lk, 0.0)) + delta
	if not hero.dead and world.is_dungeon(world.to_tile(hero.position)):
		counters["dungeon_seconds"] = float(counters.get("dungeon_seconds", 0.0)) + delta
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = 1.0
		_check_invariants()
		_check_stuck(1.0)
	if autotest_time >= autotest_seconds:
		_autotest_finish()


## Things that must never happen, whatever the AI does.
func _check_invariants() -> void:
	for e in creatures:
		if e.dead or (e.is_hero and frontier != null and not frontier.sail.is_empty()):
			continue                               # (out on the lake in a boat is fine)
		var p := e.position
		if is_nan(p.x) or is_nan(p.z):
			_note_problem("%s has an invalid position" % e.display_name)
		elif world.is_blocked(world.to_tile(p)):
			_note_problem("%s is inside a wall at %s" % [e.display_name, world.to_tile(p)])
		if e.hp > float(e.stats.max_hp()) + 0.01:
			_note_problem("%s has more HP than its maximum" % e.display_name)
		if e.gold < 0 or e.reagents < 0.0 or e.bandages < 0 or e.arrows < 0:
			_note_problem("%s has negative gold, reagents or bandages" % e.display_name)
	if property.bank_gold < 0:
		_note_problem("the bank balance is negative")


## The hero must keep doing something: fighting, looting, gathering, casting, healing...
func _check_stuck(step: float) -> void:
	var now := ""
	for k in ["kills", "loot", "gathered", "crafted", "spells_cast", "bandaged", "potions_drunk", "banked", "hero_deaths"]:
		now += "%d," % int(counters.get(k, 0))
	now += "%d" % int(hero.stats.skill_total() * 10.0)
	if now != _activity:
		_activity = now
		_idle_time = 0.0
		return
	_idle_time += step
	if _idle_time >= STUCK_SECONDS:
		_note_problem("the hero did nothing for %d game-minutes (state: %s, at %s, gold %d, reagents %d)" % [
			int(STUCK_SECONDS / 60.0), hero.state_text(), world.to_tile(hero.position),
			hero.gold, int(hero.reagents)])


func _autotest_finish() -> void:
	counters["game_minutes"] = int(autotest_time / 60.0)
	counters["skill_points_gained"] = snappedf(hero.stats.skill_total() - _start_skill_total, 0.1)
	counters["hero_gold"] = hero.gold
	counters["dungeon_seconds"] = int(float(counters.get("dungeon_seconds", 0.0)))
	for k in counters.keys():
		if String(k).begins_with("t_") or String(k).begins_with("tt_"):
			counters[k] = int(float(counters[k]))
	counters["bank_gold"] = property.bank_gold
	print("AUTOTEST REPORT " + JSON.stringify(counters))
	if int(counters.get("kills", 0)) == 0:
		_note_problem("the hero killed nothing")
	if int(counters.get("loot", 0)) == 0:
		_note_problem("the hero looted nothing")
	if float(counters["skill_points_gained"]) <= 0.0:
		_note_problem("none of the hero's skills rose")
	var earned := int(counters.get("gold_earned", 0))
	var spent := int(counters.get("gold_spent", 0))
	# An economy check: only meaningful over a longer run (a short one can be all fighting).
	if earned <= spent and autotest_seconds >= 1800.0:
		_note_problem("the hero spent at least as much gold as it earned (%d earned, %d spent)" % [earned, spent])
	var deaths := int(counters.get("hero_deaths", 0))
	if deaths > int(counters.get("kills", 0)):
		_note_problem("the hero died more often than it killed (%d deaths, %d kills)" % [deaths, int(counters.get("kills", 0))])
	for p in problems:
		print("AUTOTEST FAIL: " + p)
	if problems.is_empty():
		print("AUTOTEST PASS")
	get_tree().quit(0 if problems.is_empty() else 1)


# --- help ------------------------------------------------------------------

func _open_help() -> void:
	menu.visible = false
	settings_panel.visible = true
	for c in settings_box.get_children():
		settings_box.remove_child(c)
		c.queue_free()
	var title := _info("How to play")
	title.add_theme_font_size_override("font_size", 30)
	settings_box.add_child(title)
	for line in [
		"Tap anywhere on the minimap and your hero walks there, right across the map if need be (a gold flag marks it; tap the ground to stop).",
		"Main Menu > Adventures: side quests, bounties, the tavern, cooking, brews and blade poisons, furnishing your house, the arena, the guild towers and the dungeon's depths. When you stand by something you can use (a villager, a bounty board, a landing, the stairs down, a tower, the tavern, the arena, your house, a campfire), an action button appears at the bottom of the screen.",
		"Tap the ground to walk there. Tap a monster to attack it, a corpse to loot it, a rock to mine it, a tree to chop it. Tap a player to pick them: Attack and Info buttons appear at the bottom.",
		"The Menu button (top right) opens every button: Auto, Main Menu, Bag, Spells, Retreat, Ride, Mute, and switches to show names, stats and the map, Bow / Melee (draw your bow, the shield goes in the bag; switch back for sword and shield), and First person / Top view (in first person you see through the hero's eyes; twist two fingers to look around). Auto lets your hero play by itself: fight, heal, loot, gather, craft at the forge, sell to Bran and bank with Oswin. Tapping takes over for a few seconds.",
		"Names (Menu > Show names): blue innocent, grey criminal, red murderer or monster. The tan towns are safe: nobody can be hurt inside a town, and nobody can attack out of one.",
		"Skills and stats rise by use. Menu > Skills shows them and lets you set Up, Down or Locked. There's no real cap: every skill can reach 100.",
		"Tap a merchant to trade: buy supplies, weapons, armour, jewelry and scrolls, sell what you carry, and have worn gear repaired. Gear wears out with use and breaks at 0 (Bag shows durability); you can also repair it yourself at the forge with a tool kit (Blacksmithy).",
		"Treasure maps drop from monsters (or come up in a fishing net). In the Bag: Read marks the spot with a red X on the minimap; walk there and Dig with a shovel. The chest is rich, but its guardians rise.",
		"Fishing: carry a fishing pole and tap the water. Fish feed you; skill brings big fish, and sometimes a pearl or a map in a bottle. Rings and amulets (Bag > Wear) add strength, spell power, faster casting, resistance, armour or healing.",
		"World events: the restless dead walk the wilds at night; orc warbands march on the towns (help drive them off for a reward); champions rise in the wilds (orange dots on the map) and always leave treasure. Statistics shows your achievements, and the titles they earn.",
		"Die and you become a ghost in a grey world: walk (tap the ground, or let Auto do it) to a resurrection spot to be raised for free: a glowing ankh shrine (one in every part of the map, pale blue crosses on the minimap) or a healer or priest (not for murderers). The top of the screen shows the nearest. Your corpse keeps your bag; go back for it. Bank gold to keep it safe.",
		"Captain Marcus in town gives kill quests. The dungeon is east, past the outpost.",
		"The world is bigger now: Southmoor, a third town, lies south. Wolf packs and an orc fort roam the far east, spiders the southern forest, and the restless dead an old graveyard in the south-east. The hills south-east are rich in ore.",
		"Priests (Father Corwin by the healer, Brother Anselm at the outpost, Mother Isolde in Southmoor) cure poison, lift curses, restore mana and raise the dead for free, bless you for 25 gold (+10% damage dealt, -10% taken, 5 minutes) and lift a murder count for 50 gold. Stand near one, or tap them.",
		"Menu also has Craft, Bank & House (deeds, lock-downs, co-owners), Travel & Spellbook (a runebook of up to 8 runes for Recall and Gate Travel, and the spells you know) and Settings (sound, camera).",
		"Spells must be in your spellbook. You start with circles 1-4; scrolls for more drop from monsters (tougher ones carry higher circles) or are sold by merchants (circles 1-6), and are copied in as soon as you pick them up.",
	]:
		settings_box.add_child(_info("• " + String(line)))
	settings_box.add_child(_menu_button("Back", _close_settings))


# --- animals ---------------------------------------------------------------

## Called by Entity when a taming attempt succeeds. A new wild animal of the same kind
## appears at the old lair after a while.
func tame(tamer: Entity, animal: Entity) -> void:
	pending_spawns.append({"name": animal.display_name, "cfg": animal.cfg_ref,
		"color": animal.spawn_color, "tile": world.to_tile(animal.home), "delay": 90.0})
	tamer.adopt_pet(animal)
	if tamer.is_hero:
		count("tamed")
		log_event("You tame the %s! It follows you and fights at your side." % animal.display_name)


const SUMMON_NAMES := {
	"EARTH_ELEMENTAL": "Earth Elemental", "BLADE_SPIRITS": "Blade Spirits",
	"ENERGY_VORTEX": "Energy Vortex", "AIR_ELEMENTAL": "Air Elemental",
	"FIRE_ELEMENTAL": "Fire Elemental", "WATER_ELEMENTAL": "Water Elemental", "DAEMON": "Daemon",
}


## A summoning spell: the creature forms next to the caster (spawned after this frame's ticks).
func summon_creature(caster: Entity, spell_id: String) -> void:
	var sp: Dictionary = Spells.LIST[spell_id]
	var key := String(sp.get("summon", "EARTH_ELEMENTAL"))
	var cfg: Dictionary = Bestiary.summon_cfg(key)
	var summon_label := String(SUMMON_NAMES.get(key, ""))
	if summon_label == "":
		summon_label = "Wolf" if cfg == Bestiary.WOLF else "Brown Bear"
	pending_spawns.append({"name": summon_label, "cfg": cfg, "color": sp["color"],
		"tile": world.to_tile(caster.position), "summoner": caster, "secs": float(sp.get("secs", 60.0))})


# --- spell fields: fire, poison, paralysis, traps and walls --------------------------------

var fields: Array = []           # {"kind", "pos", "radius", "life", "owner", "min", "max", "acc", "hit", "tiles", "node"}


## Lays a field spell down at `at` (a wall goes up across the line from its caster to `at`).
func add_field(owner_e: Entity, spell_id: String, at: Vector3) -> void:
	var sp: Dictionary = Spells.LIST[spell_id]
	var kind := String(sp["field"])
	var f := {"kind": kind, "pos": at, "radius": 1.6 if kind != "trap" else 0.8,
		"life": float(sp.get("secs", 10.0)), "owner": owner_e, "min": float(sp["min_dmg"]),
		"max": float(sp["max_dmg"]), "acc": 0.0, "hit": {}, "tiles": []}
	var node := Node3D.new()
	add_child(node)
	f["node"] = node
	if kind == "wall":
		var from := world.to_tile(owner_e.position)
		var to := world.to_tile(at)
		var dv := to - from
		var mid := from + Vector2i(clampi(dv.x, -2, 2), clampi(dv.y, -2, 2))
		var across := Vector2i(0, 1) if absi(dv.x) >= absi(dv.y) else Vector2i(1, 0)
		var occupied := _occupied_tiles()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.95, 1.2, 0.95)
		var mat := World._mat(sp["color"])
		mat.emission_enabled = spell_id == "energy_field"
		mat.emission = sp["color"]
		for i in range(-1, 2):
			var c := mid + across * i
			if world.is_blocked(c) or occupied.has(c):
				continue
			world.set_temp_block(c, true)
			(f["tiles"] as Array).append(c)
			var m := MeshInstance3D.new()
			m.mesh = mesh
			m.material_override = mat
			node.add_child(m)
			m.position = world.tile_center(c) + Vector3(0, 0.6, 0)
		if (f["tiles"] as Array).is_empty():
			node.queue_free()
			return
	else:
		var disc := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = float(f["radius"])
		cyl.bottom_radius = float(f["radius"])
		cyl.height = 0.05
		disc.mesh = cyl
		var mat := World._mat(sp["color"])
		mat.emission_enabled = true
		mat.emission = sp["color"]
		disc.material_override = mat
		disc.transparency = 0.45
		node.add_child(disc)
		node.position = Vector3(at.x, 0.04, at.z)
		if kind == "fire":
			node.add_child(Fx.flame(float(f["radius"]) * 1.4, 40, 1.0))
	fields.append(f)


## Removes fields of the given kinds (all kinds when empty) within `radius` of `at`.
func remove_fields(at: Vector3, radius: float, kinds: Array) -> void:
	for f in fields.duplicate():
		if (kinds.is_empty() or kinds.has(f["kind"])) and (f["pos"] as Vector3).distance_to(at) <= radius + 1.0:
			_end_field(f)


func _end_field(f: Dictionary) -> void:
	for c in f["tiles"]:
		world.set_temp_block(c, false)
	(f["node"] as Node3D).queue_free()
	fields.erase(f)


func _fields_tick(delta: float) -> void:
	for f in fields.duplicate():
		f["life"] = float(f["life"]) - delta
		var owner_e: Entity = f["owner"] if is_instance_valid(f["owner"]) else null
		if float(f["life"]) <= 0.0 or owner_e == null:
			_end_field(f)
			continue
		if f["kind"] == "wall":
			continue
		f["acc"] = float(f["acc"]) + delta
		var hit: Dictionary = f["hit"]
		for id in hit.keys():
			hit[id] = float(hit[id]) - delta
			if float(hit[id]) <= 0.0:
				hit.erase(id)
		for e in creatures:
			if e.dead or e == owner_e or e.kind == Entity.Kind.NPC or not owner_e._is_fair_target(e):
				continue
			if Vector2(e.position.x - f["pos"].x, e.position.z - f["pos"].z).length() > float(f["radius"]):
				continue
			if e.town_protects(owner_e):
				continue                       # fields can't touch anyone in a town
			match String(f["kind"]):
				"fire":
					if float(f["acc"]) >= 1.0:
						e.take_damage(randf_range(float(f["min"]), float(f["max"])) + 0.5, owner_e)
				"poison":
					if not hit.has(e.get_instance_id()):
						hit[e.get_instance_id()] = 3.0
						e.apply_poison(1 if owner_e._skill(Hero.Skill.MAGERY) < 80.0 else 2, owner_e)
				"paralyze":
					if not hit.has(e.get_instance_id()) and e.paralyzed_timer <= 0.0:
						hit[e.get_instance_id()] = 6.0
						e.paralyzed_timer = 3.0
						e.path.clear()
						e._pop("paralyzed", Color(0.85, 0.7, 1.0))
				"trap":
					e._pop("a trap!", Color(1.0, 0.4, 0.2))
					e.take_damage(randf_range(float(f["min"]), float(f["max"])), owner_e)
					f["life"] = 0.0
					break
		if float(f["acc"]) >= 1.0:
			f["acc"] = 0.0


func is_night() -> bool:
	return sin((day_time - 0.25) * TAU) < -0.2


func on_pet_died(p: Entity) -> void:
	if p.pet_owner != null:
		p.pet_owner.pets.erase(p)
		if p.pet_owner.is_hero:
			log_event("Your %s has died." % p.display_name)


func _flush_spawns() -> void:
	while not pending_spawns.is_empty():
		var s: Dictionary = pending_spawns.pop_back()
		var e := _spawn(Entity.Kind.MONSTER, String(s["name"]), s["cfg"], s["color"], s["tile"])
		if s.has("temp_secs"):
			e.summoned = true                # risen minions crumble on their own
			e.summon_timer = float(s["temp_secs"])
			continue
		var summoner: Entity = s.get("summoner", null)
		if summoner != null:
			if not is_instance_valid(summoner) or summoner.dead:
				e.summoned = true                # the caster died before it formed
				e.summon_timer = 0.0
				continue
			e.summoned = true
			e.summon_timer = float(s.get("secs", 60.0))
			summoner.adopt_pet(e)
			summoner.summon = e
			e.pause = 0.5
			if summoner.is_hero:
				count("summoned")
				log_event("A %s answers your call and fights for you." % e.display_name)
			continue
		if float(s.get("delay", 0.0)) > 0.0:
			e.dead = true                    # waits out of sight, then appears at its lair
			e.visible = false
			e.dead_timer = float(s["delay"])


## Pets saved with the game come back next to the hero.
func _restore_pets() -> void:
	for item in saved_pets:
		var d: Dictionary = item
		var cfg := Bestiary.by_species(String(d.get("species", "")))
		if cfg.is_empty() or hero.pets.size() >= Entity.MAX_PETS:
			continue
		var p := _spawn(Entity.Kind.MONSTER, String(d.get("name", "Pet")), cfg,
			Color(String(cfg.get("color", "8a6a4a"))), world.to_tile(hero.position))
		hero.adopt_pet(p)
		p.set_pet_level(int(d.get("level", 1)), float(d.get("xp", 0.0)))
		p.hp = clampf(float(d.get("hp", p.hp)), 1.0, float(p.stats.max_hp()))


func _refresh_animals() -> void:
	for c in animals_box.get_children():
		animals_box.remove_child(c)
		c.queue_free()
	var s := hero.stats
	var title := _info("Animals")
	title.add_theme_font_size_override("font_size", 30)
	animals_box.add_child(title)
	animals_box.add_child(_info("Animal Taming %.1f   Animal Lore %.1f   Veterinary %.1f" % [
		float(s.skills[Hero.Skill.ANIMAL_TAMING]), float(s.skills[Hero.Skill.ANIMAL_LORE]),
		float(s.skills[Hero.Skill.VETERINARY])]))
	if hero.mounted_on != null:
		var mo := hero.mounted_on
		animals_box.add_child(_info("You are riding your %s: %.1fx speed%s%s." % [mo.display_name, mo.mount_speed,
			", +%d armour" % int(mo.mount_armor) if mo.mount_armor > 0.0 else "",
			", carry %dx" % int(mo.mount_carry) if mo.mount_carry > 1.0 else ""]))
		animals_box.add_child(_menu_button("Get off your %s" % hero.mounted_on.display_name, _on_dismount))
	var stable := _role_entity("stable")
	if stable != null and stable.position.distance_to(hero.position) <= 4.0:
		animals_box.add_child(_info("%s sells tame mounts (paid from the bank). Riding is much faster than walking." % stable.display_name))
		for offer in [["Horse", Bestiary.HORSE, STABLE_HORSE], ["Llama", Bestiary.LLAMA, STABLE_LLAMA],
			["Forest Ostard", Bestiary.OSTARD, 500], ["Giant Beetle", Bestiary.BEETLE, 450]]:
			animals_box.add_child(_action("Buy a %s (%d gold)" % [String(offer[0]).to_lower(), int(offer[2])],
				_on_buy_mount.bind(offer[0], offer[2]), property.bank_gold >= int(offer[2]) and hero.pets.size() < Entity.MAX_PETS))
	else:
		animals_box.add_child(_info("Hal the Stablemaster in town sells horses, llamas, ostards and giant beetles. Wild mounts: horses on the eastern plains, a llama and giant beetles in the south-east hills, forest ostards in the southern forest, a swamp dragon in the swamp (it bites!) and a nightmare deep in the dungeon (very dangerous; Animal Taming 90)."))
	if hero.pets.is_empty():
		animals_box.add_child(_info("You have no pets (up to %d)." % Entity.MAX_PETS))
	for p in hero.pets:
		animals_box.add_child(_info("%s: level %d%s, HP %d/%d, Str %d, Dex %d, carries +%d" % [
			p.display_name, p.pet_level,
			" (max)" if p.pet_level >= Entity.PET_LEVEL_MAX else " (%d/%d to the next)" % [int(p.pet_xp), p.pet_level * 40],
			ceili(p.hp), p.stats.max_hp(), p.stats.strength, p.stats.dexterity, (p.pet_level - 1) * 2]))
		if hero.can_ride(p) and hero.mounted_on == null:
			animals_box.add_child(_action("Ride the %s" % p.display_name, _on_mount.bind(p), p.position.distance_to(hero.position) <= 3.0))
		if p != hero.mounted_on:
			animals_box.add_child(_menu_button("Release the %s" % p.display_name, _on_release_pet.bind(p)))
	# The nearest wild animal: Animal Lore tells you about it.
	var wild: Entity = null
	var best := 8.0
	for e in creatures:
		if e.kind == Entity.Kind.MONSTER and not e.dead and e.tame_min >= 0.0:
			var d := e.position.distance_to(hero.position)
			if d < best:
				wild = e
				best = d
	if wild == null:
		animals_box.add_child(_info("No tameable animal nearby. Hinds graze in the open, a bear roams the south-east, wolves hunt the south."))
	else:
		hero.stats.try_gain(Hero.Skill.ANIMAL_LORE)   # studying an animal teaches Animal Lore
		animals_box.add_child(_info("Nearby: %s. HP %d/%d, Str %d, needs Animal Taming %d. %s" % [
			wild.display_name, ceili(wild.hp), wild.stats.max_hp(), wild.stats.strength, int(wild.tame_min),
			"Peaceful." if wild.passive else "Aggressive!"]))
		var problem := hero.can_tame(wild)
		var label := "Tame the %s (%d%% chance)" % [wild.display_name, roundi(hero.tame_chance_of(wild) * 100.0)]
		if problem != "":
			label = "Can't tame: " + problem
		animals_box.add_child(_action(label, _on_tame.bind(wild), problem == "" and not hero.dead))
	animals_box.add_child(_info("Pets follow you and attack what you attack. With Auto on your hero tames animals by itself, and bandages hurt pets (Veterinary). A dead pet is gone for good."))
	animals_box.add_child(_menu_button("Back", _close_animals))


func _on_tame(e: Entity) -> void:
	hero.start_taming(e)
	animals_panel.visible = false
	_resume()


const STABLE_HORSE := 300
const STABLE_LLAMA := 200


func _on_buy_mount(animal: String, price: int) -> void:
	var cfg: Dictionary = {"Horse": Bestiary.HORSE, "Llama": Bestiary.LLAMA, "Forest Ostard": Bestiary.OSTARD,
		"Giant Beetle": Bestiary.BEETLE}.get(animal, Bestiary.HORSE)
	property.bank_gold -= price
	var p := _spawn(Entity.Kind.MONSTER, animal, cfg, Color(String(cfg["color"])), world.to_tile(hero.position))
	hero.adopt_pet(p)
	log_event("You buy a %s for %d gold. It follows you; ride it from Menu > Animals." % [animal.to_lower(), price])
	_refresh_animals()


func _on_mount(p: Entity) -> void:
	hero.mount(p)
	_refresh_animals()


func _on_dismount() -> void:
	hero.dismount()
	_refresh_animals()


func _on_release_pet(p: Entity) -> void:
	hero.release_pet(p)
	_refresh_animals()


func _open_animals() -> void:
	menu.visible = false
	animals_panel.visible = true
	_refresh_animals()


func _close_animals() -> void:
	animals_panel.visible = false
	menu.visible = true


# --- bard ------------------------------------------------------------------

func _refresh_bard() -> void:
	for c in bard_box.get_children():
		bard_box.remove_child(c)
		c.queue_free()
	var s := hero.stats
	var title := _info("Bard")
	title.add_theme_font_size_override("font_size", 30)
	bard_box.add_child(title)
	bard_box.add_child(_info("Musicianship %.1f   Peacemaking %.1f   Provocation %.1f   Enticement %.1f%s" % [
		float(s.skills[Hero.Skill.MUSICIANSHIP]), float(s.skills[Hero.Skill.PEACEMAKING]),
		float(s.skills[Hero.Skill.PROVOCATION]), float(s.skills[Hero.Skill.ENTICEMENT]),
		"" if hero.has_instrument() else "\nYou have no lute: Bran sells them for %d gold." % Entity.LUTE_PRICE]))
	var a := hero.nearest_hostile()
	var b: Entity = hero.nearest_hostile(a) if a != null else null
	var tune := Rules.music_chance(float(s.skills[Hero.Skill.MUSICIANSHIP]))
	for entry in [
		["peace", "Peacemaking: calm every monster around you", Hero.Skill.PEACEMAKING, a],
		["provoke", "Provocation: turn the nearest monster on another", Hero.Skill.PROVOCATION, a],
		["entice", "Enticement: lure the nearest monster to you", Hero.Skill.ENTICEMENT, a],
	]:
		var what := String(entry[0])
		var problem := hero.bard_problem(what)
		var label := String(entry[1])
		if problem != "":
			label += " (%s)" % problem
		elif entry[3] != null:
			label += " (%s, %d%%)" % [(entry[3] as Entity).display_name,
				roundi(tune * hero.bard_chance_vs(int(entry[2]), entry[3]) * 100.0)]
		bard_box.add_child(_action(label, _on_perform.bind(what, a, b), problem == ""))
	bard_box.add_child(_info("Every tune first needs a good Musicianship roll. A failed provocation or enticement makes the monster angry with you. Hitting a calmed monster wakes it. With Auto on, your hero provokes when two monsters gang up on it, calms them when badly hurt, and lures lone monsters away from their friends."))
	bard_box.add_child(_menu_button("Back", _close_bard))


func _on_perform(what: String, a: Entity, b: Entity) -> void:
	hero.start_perform(what, a, b)
	bard_panel.visible = false
	_resume()


func _open_bard() -> void:
	menu.visible = false
	bard_panel.visible = true
	_refresh_bard()


func _close_bard() -> void:
	bard_panel.visible = false
	menu.visible = true


# --- shops and player vendors ----------------------------------------------

func _merchants() -> Array[Entity]:
	var out: Array[Entity] = []
	for e in creatures:
		if e.shop != null:
			out.append(e)
	return out


func _refresh_prices() -> void:
	for c in prices_box.get_children():
		prices_box.remove_child(c)
		c.queue_free()
	var title := _info("Prices")
	title.add_theme_font_size_override("font_size", 30)
	prices_box.add_child(title)
	var merchants := _merchants()
	var header := "Merchants: "
	for mrc in merchants:
		header += "%s in %s (%d gold in the purse)   " % [mrc.display_name, mrc.shop.town, mrc.shop.cash]
	prices_box.add_child(_info(header))
	var bag := _sellable_bag()
	if bag.is_empty():
		prices_box.add_child(_info("Nothing in your bag to sell."))
	for id in bag:
		var line := "%s x%d:" % [Items.item_name(id), int(bag[id])]
		for mrc in merchants:
			var offer := mrc.shop.offer(id)
			line += "   %s %s" % [mrc.display_name, ("%d each" % offer) if offer > 0 else "won't buy"]
		prices_box.add_child(_info(line))
	var supplies := "Supplies:"
	for mrc in merchants:
		supplies += "   %s: reagent %d, bandage %d, heal potion %d" % [mrc.display_name,
			mrc.shop.price(Entity.REAGENT_PRICE), mrc.shop.price(Entity.BANDAGE_PRICE),
			mrc.shop.price(Entity.POTION_PRICE)]
	prices_box.add_child(_info(supplies))
	prices_box.add_child(_info("A merchant pays less for what it already holds, refuses overstocked goods and can run out of gold; every couple of minutes it restocks. The outpost pays more, so hauling loot there earns more. You sell automatically when you stand near a merchant."))
	prices_box.add_child(_menu_button("Back", _close_prices))


# --- guild & fame panel ----------------------------------------------------

func _refresh_guild() -> void:
	for c in guild_box.get_children():
		guild_box.remove_child(c)
		c.queue_free()
	var title_label := _info("Guild & Fame")
	title_label.add_theme_font_size_override("font_size", 30)
	guild_box.add_child(title_label)
	guild_box.add_child(_info("You are %s. Fame %d, Karma %d. Killing monsters brings fame (and karma, unless it is just an animal); criminals and murderers bring karma; an innocent costs a lot of karma; dying costs a tenth of your fame." % [
		hero.title_name(), hero.fame, hero.karma]))
	var mine := hero.guild_id()
	if mine == "":
		guild_box.add_child(_info("You are in no guild. Guild members show green to each other and allies; guilds at war show orange and may fight anywhere outside town without becoming criminals."))
	else:
		var g: Dictionary = guilds.list[mine]
		guild_box.add_child(_info("Your guild: %s [%s]%s. Members: %s." % [g["name"], g["abbr"],
			" (you lead it)" if String(g["leader"]) == hero.display_name else "", ", ".join(g["members"])]))
	# every guild and how it stands with yours
	for id in guilds.list:
		if id == mine:
			continue
		var g: Dictionary = guilds.list[id]
		var stance := ""
		if guilds.at_war(mine, id):
			stance = " - AT WAR with you"
		elif mine != "" and guilds.allied(mine, id):
			stance = " - your ally"
		guild_box.add_child(_info("%s [%s]: %s%s" % [g["name"], g["abbr"], ", ".join(g["members"]), stance]))
		if mine == "":
			var ok := _guild_accepts(id)
			guild_box.add_child(_action("Join %s%s" % [g["name"], "" if ok else " (they won't have you: " + _guild_refusal(id) + ")"],
				_on_guild_join.bind(id), ok and not hero.dead))
	if mine == "":
		guild_box.add_child(_action("Found your own guild (%d gold from the bank)" % Guilds.FOUND_COST,
			_on_guild_found, property.bank_gold >= Guilds.FOUND_COST))
	else:
		guild_box.add_child(_action("Leave your guild", _on_guild_leave, true))
	if mine == "player":
		for e in creatures:
			if e.kind != Entity.Kind.PLAYER or e.is_hero or e.guild_id() != "":
				continue
			var cd := float(guilds.invite_cd.get(e.display_name, 0.0))
			guild_box.add_child(_action("Invite %s%s" % [e.display_name, " (asked recently)" if cd > 0.0 else ""],
				_on_guild_invite.bind(e.display_name), cd <= 0.0))
		for id in guilds.list:
			if id == "player":
				continue
			var gname := String(guilds.list[id]["name"])
			if guilds.at_war("player", id):
				guild_box.add_child(_action("Make peace with " + gname, _on_guild_war.bind(id, false), true))
			else:
				guild_box.add_child(_action("Declare war on " + gname, _on_guild_war.bind(id, true), true))
				if guilds.allied("player", id):
					guild_box.add_child(_action("End the alliance with " + gname, _on_guild_ally.bind(id, false), true))
				else:
					guild_box.add_child(_action("Propose an alliance to " + gname, _on_guild_ally.bind(id, true), true))
	guild_box.add_child(_menu_button("Back", _close_guild))


## The computer guilds pick their members: honest guilds want good karma, Shadowclan bad.
func _guild_accepts(id: String) -> bool:
	return _guild_refusal(id) == ""


func _guild_refusal(id: String) -> String:
	if id == "shd":
		return "" if hero.karma <= -1000 else "they want karma -1000 or less"
	if hero.notoriety() != Entity.Notoriety.BLUE:
		return "no criminals or murderers"
	return "" if hero.karma >= 0 else "they want karma 0 or more"


func _on_guild_join(id: String) -> void:
	guilds.join(hero.display_name, id)
	log_event("You join %s." % guilds.list[id]["name"])
	_refresh_guild()


func _on_guild_leave() -> void:
	var id := hero.guild_id()
	var gname := String(guilds.list[id]["name"]) if guilds.list.has(id) else "your guild"
	guilds.leave(hero.display_name)
	log_event("You leave %s." % gname)
	_refresh_guild()


func _on_guild_found() -> void:
	property.bank_gold -= Guilds.FOUND_COST
	guilds.found(hero.display_name, "%s's Company" % hero.display_name, hero.display_name.left(3).to_upper())
	log_event("You found %s. Invite players to join you." % guilds.list["player"]["name"])
	_refresh_guild()


## A guildless player joins if your name means something to them (fame and good karma help).
func _on_guild_invite(player_name: String) -> void:
	var e: Entity = null
	for c in creatures:
		if c.display_name == player_name and c.kind == Entity.Kind.PLAYER:
			e = c
	if e == null:
		return
	var chance := 0.35 + float(hero.fame) / 10000.0 * 0.45 + (0.15 if hero.karma >= 1250 else 0.0)
	if e.is_pk != (hero.karma < 0):
		chance *= 0.3                    # player killers and honest folk don't mix
	if randf() < chance:
		guilds.join(player_name, "player")
		log_event("%s joins %s!" % [player_name, guilds.list["player"]["name"]])
	else:
		guilds.invite_cd[player_name] = Guilds.INVITE_COOLDOWN
		log_event("%s declines your invitation, for now." % player_name)
	_refresh_guild()


func _on_guild_war(id: String, on: bool) -> void:
	guilds.set_war("player", id, on)
	log_event(("You declare war on %s! Their members show orange." if on else "You make peace with %s.") % guilds.list[id]["name"])
	_refresh_guild()


## Honest guilds ally with an honest leader; Shadowclan only with a wicked one.
func _on_guild_ally(id: String, on: bool) -> void:
	if on:
		var ok := hero.karma < 0 if id == "shd" else hero.karma >= 0 and not guilds.at_war(id, "player")
		for other in guilds.list:              # nobody allies with their own enemy's friend
			if other != id and other != "player" and guilds.allied("player", other) and guilds.at_war(id, other):
				ok = false
		if not ok:
			log_event("%s turns down your alliance." % guilds.list[id]["name"])
			_refresh_guild()
			return
	guilds.set_ally("player", id, on)
	log_event(("%s is now your ally." if on else "Your alliance with %s is over.") % guilds.list[id]["name"])
	_refresh_guild()


# --- equipment & bag panel --------------------------------------------------------

## What the hero wears and wields, and everything in the bag. Opened from the Bag button.
func _refresh_bag() -> void:
	for c in bag_box.get_children():
		bag_box.remove_child(c)
		c.queue_free()
	var title_label := _info("Equipment & Bag")
	title_label.add_theme_font_size_override("font_size", 30)
	bag_box.add_child(title_label)
	# equipped
	bag_box.add_child(_heading("Equipped"))
	for slot: String in ["weapon", "armor", "shield"]:
		var id := hero._equipped_id(slot)
		var label := slot.capitalize() + ": "
		if id == "":
			label += "nothing" + (" (bare hands)" if slot == "weapon" else "")
		else:
			label += _gear_line(id)
			if slot == "weapon" and Gear.is_ranged(id):
				label += ", %d arrows" % hero.arrows
			label += "   [durability %d/%d]" % [hero.durability(id), Gear.max_durability(id)]
		var row := HBoxContainer.new()
		var info := _info(label)
		info.custom_minimum_size = Vector2(560, 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		if id != "":
			row.add_child(_action("Take off", _on_unequip.bind(slot), not hero.dead))
		bag_box.add_child(row)
	for sl: String in ["ring", "amulet"]:
		var jid: String = hero.ring_id if sl == "ring" else hero.amulet_id
		var jrow := HBoxContainer.new()
		var jinfo := _info("%s: %s" % [sl.capitalize(), "nothing" if jid == "" else "%s (%s)" % [Items.item_name(jid), Jewelry.describe(jid)]])
		jinfo.custom_minimum_size = Vector2(560, 0)
		jinfo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		jrow.add_child(jinfo)
		if jid != "":
			jrow.add_child(_action("Take off", _on_remove_jewel.bind(sl), not hero.dead))
		bag_box.add_child(jrow)
	bag_box.add_child(_info("Riding: %s" % (hero.mounted_on.display_name if hero.mounted_on != null else "on foot")))
	bag_box.add_child(_action("Auto-equip better gear: %s" % ("On" if hero.auto_equip else "Off (you choose)"), _on_toggle_auto_equip, true))
	if world.near_forge(hero.position):
		bag_box.add_child(_action("Repair worn gear at the forge (Blacksmithy, uses the tool kit)", _on_forge_repair, not hero.dead))
	else:
		bag_box.add_child(_small("Worn gear breaks at 0. Repair it at a merchant (tap them) or yourself at the forge."))
	# supplies
	bag_box.add_child(_heading("Supplies"))
	bag_box.add_child(_info("Gold %d (bank %d)   Reagents %d   Bandages %d   Arrows %d" % [
		hero.gold, property.bank_gold, floori(hero.reagents), hero.bandages, hero.arrows]))
	# the bag
	var total := 0
	for id in hero.inventory:
		total += int(hero.inventory[id])
	bag_box.add_child(_heading("Bag (%d item%s)" % [total, "" if total == 1 else "s"]))
	if hero.inventory.is_empty():
		bag_box.add_child(_info("Your bag is empty."))
	var ids := hero.inventory.keys()
	ids.sort_custom(func(a, b) -> bool: return Items.item_name(a) < Items.item_name(b))
	for id in ids:
		var n := int(hero.inventory[id])
		var line := "%s x%d" % [Items.item_name(id), n]
		if Gear.has(id):
			line = "%s x%d: %s" % [Items.item_name(id), n, _gear_line(id)]
		elif Jewelry.has(id):
			line = "%s x%d: %s" % [Items.item_name(id), n, Jewelry.describe(id)]
		elif Items.is_tool_item(id):
			line += " (%d uses left)" % int(hero.tool_uses.get(id, Entity.TOOL_USES))
		if Items.is_known(id) and not Items.is_tool_item(id):
			line += "   worth %d each" % Items.value(id)
		var row := HBoxContainer.new()
		var pic := TextureRect.new()                   # a little picture of what it is
		pic.texture = Icons.tex(Icons.for_item(String(id)))
		pic.custom_minimum_size = Vector2(40, 40)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.modulate = Art.item_color(String(id))
		row.add_child(pic)
		var info := _info(line)
		info.custom_minimum_size = Vector2(520, 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		if Gear.has(id):
			var problem := hero.equip_problem(id)
			row.add_child(_action("Equip" if problem == "" else "Can't: " + problem, _on_equip.bind(id), problem == "" and not hero.dead))
		elif Jewelry.has(id):
			row.add_child(_action("Wear", _on_wear_jewel.bind(String(id)), not hero.dead))
		elif Items.is_map(id):
			row.add_child(_action("Read", _on_read_map.bind(String(id)), true))
			row.add_child(_action("Dig", _on_dig_map.bind(String(id)), not hero.dead))
		bag_box.add_child(row)
	bag_box.add_child(_menu_button("Back", _close_bag))


func _heading(text: String) -> Label:
	var l := _info(text)
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	return l


## One line about a piece of gear: damage and speed, armour or block, and what it needs.
func _gear_line(id: String) -> String:
	var g := Gear.stats(id)
	match String(g["slot"]):
		"weapon":
			var sp := Gear.special(id)
			return "%s, %d-%d %s damage, speed %d (%s)%s%s" % [Items.item_name(id), int(g["min"]), int(g["max"]),
				Gear.dtype(id), int(g["speed"]), String(g["skill"]).capitalize(),
				", two-handed" if bool(g.get("two_handed", false)) else "",
				(", special: " + SPECIAL_NAMES.get(sp, sp)) if sp != "" else ""]
		"shield":
			return "%s, blocks %d%%" % [Items.item_name(id), roundi(float(g["block"]) * 100.0)]
	return "%s, armour %d" % [Items.item_name(id), int(g["rating"])]


const SPECIAL_NAMES := {"bleed": "Bleeding Wound", "armor_ignore": "Armor Ignore", "crush": "Crushing Blow",
	"double": "Double Strike", "concuss": "Concussion"}


func _on_equip(id: String) -> void:
	hero.equip_by_hand(id)
	_refresh_bag()


func _on_read_map(id: String) -> void:
	var t := Items.map_tile(id)
	map_mark = t
	var v := world.tile_center(t) - hero.position
	log_event("The map shows a spot %d m %s of you, marked with a red X on your minimap. Dig there with a shovel." % [
		roundi(v.length()), _compass(v)])
	_refresh_bag()


func _on_dig_map(id: String) -> void:
	var msg := hero.start_dig(id)
	if msg != "":
		log_event(msg)
		_refresh_bag()
	else:
		_close_bag()


func _on_forge_repair() -> void:
	log_event(hero.repair_at_forge())
	_refresh_bag()


func _on_wear_jewel(id: String) -> void:
	hero.wear_jewel(id)
	_refresh_bag()


func _on_remove_jewel(sl: String) -> void:
	hero.remove_jewel(sl)
	_refresh_bag()


func _on_unequip(slot: String) -> void:
	hero.unequip(slot)
	_refresh_bag()


func _on_toggle_auto_equip() -> void:
	hero.auto_equip = not hero.auto_equip
	_refresh_bag()


func _open_bag() -> void:
	paused = true
	menu.visible = false
	bag_panel.visible = true
	_refresh_bag()


func _close_bag() -> void:
	bag_panel.visible = false
	_resume()


# --- priest panel: what a priest does, and buying a blessing or confession -----------------

func _open_priest(p: Entity) -> void:
	priest_open = p
	paused = true
	menu.visible = false
	priest_panel.visible = true
	_refresh_priest()


func _close_priest() -> void:
	priest_panel.visible = false
	_resume()


func _refresh_priest() -> void:
	for c in priest_box.get_children():
		priest_box.remove_child(c)
		c.queue_free()
	var p := priest_open
	var title_label := _info(p.display_name)
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
	priest_box.add_child(title_label)
	priest_box.add_child(_info("\"Peace be with you, traveller.\" Stand near %s and, for free, poison is drawn out, curses are lifted, your mana is restored by prayer and the dead are raised. A blessing and confession ask a donation." % p.display_name))
	var near := hero.position.distance_to(p.position) <= Entity.PRIEST_RANGE and not hero.dead
	var cursed: Array[String] = []
	for id in hero.effects:
		if Spells.LIST.has(id) and String(Spells.LIST[id]["kind"]) == "curse":
			cursed.append(String(Spells.LIST[id]["name"]))
	priest_box.add_child(_heading("You"))
	priest_box.add_child(_info("Gold %d   Mana %d / %d   %s   %s   %s   Murder counts %d" % [
		hero.gold, int(hero.mana), hero.stats.max_mana(),
		"poisoned" if hero.poison_level > 0 else "not poisoned",
		("cursed: " + ", ".join(cursed)) if not cursed.is_empty() else "no curses",
		("blessed %d:%02d" % [int(hero.bless_timer) / 60, int(hero.bless_timer) % 60]) if hero.bless_timer > 0.0 else "not blessed",
		hero.murder_counts]))
	if hero.notoriety() != Entity.Notoriety.BLUE:
		priest_box.add_child(_info("The priest will not serve criminals or murderers until their name is clear."))
	priest_box.add_child(_heading("Services"))
	if not near:
		priest_box.add_child(_action("Walk to %s" % p.display_name, _walk_to_priest, not hero.dead))
	var ok := near and hero.notoriety() == Entity.Notoriety.BLUE
	priest_box.add_child(_action("Blessing: +10%% damage, -10%% damage taken, 5 minutes (%d gold)" % Entity.BLESS_PRICE,
		_on_priest_bless, ok and hero.bless_timer <= 0.0 and hero.gold >= Entity.BLESS_PRICE))
	priest_box.add_child(_action("Confession: lift one murder count (%d gold)" % Entity.CONFESS_PRICE,
		_on_priest_confess, near and hero.murder_counts > 0 and hero.gold >= Entity.CONFESS_PRICE))
	priest_box.add_child(_info("Priests: Father Corwin in the main town, Brother Anselm at the outpost and Mother Isolde, the abbess of Southmoor."))
	priest_box.add_child(_menu_button("Close", _close_priest))


func _walk_to_priest() -> void:
	hero.target = null
	hero.go_to(priest_open.position)
	_close_priest()


func _on_priest_bless() -> void:
	var msg := hero.buy_blessing(priest_open)
	if msg != "":
		log_event(msg)
	_refresh_priest()


func _on_priest_confess() -> void:
	var msg := hero.confess_to(priest_open)
	if msg != "":
		log_event(msg)
	_refresh_priest()


# --- the merchant's shop: buy, sell, repair ------------------------------------------------

## What every merchant keeps on the shelves (gear the merchant sells at its own value; the best
## pieces are only made or found). [id, how many you get, base price per lot].
const SHOP_GEAR := ["dagger", "kryss", "short_sword", "longsword", "broadsword", "mace", "war_hammer",
	"scimitar", "axe", "short_spear", "quarterstaff", "war_axe", "maul", "katana", "spear", "war_fork",
	"bow", "crossbow", "leather_armor", "studded_armor", "chainmail", "wooden_shield", "bronze_shield"]


func _shop_supplies() -> Array:
	return [["arrows", 10, Entity.ARROW_PRICE * 10], ["bandages", 5, Entity.BANDAGE_PRICE * 5],
		["reagents", 10, Entity.REAGENT_PRICE * 10], ["potion_heal", 1, Entity.POTION_PRICE],
		["potion_cure", 1, Entity.POTION_PRICE], ["potion_refresh", 1, 10],
		["pickaxe", 1, Entity.TOOL_PRICE], ["hatchet", 1, Entity.TOOL_PRICE], ["tool_kit", 1, 15],
		["shovel", 1, 15], ["fishing_pole", 1, Entity.TOOL_PRICE], ["lute", 1, Entity.LUTE_PRICE]]


func _open_shop(m: Entity) -> void:
	shop_open = m
	paused = true
	menu.visible = false
	shop_panel.visible = true
	_refresh_shop()


func _close_shop() -> void:
	shop_panel.visible = false
	_resume()


func _shop_tab(t: String) -> void:
	shop_tab = t
	_refresh_shop()


func _refresh_shop() -> void:
	for c in shop_box.get_children():
		shop_box.remove_child(c)
		c.queue_free()
	var m := shop_open
	var s: Shop = m.shop
	var title_label := _info("%s's shop (%s)" % [m.display_name, s.town])
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5))
	shop_box.add_child(title_label)
	shop_box.add_child(_info("Your gold: %d   The merchant's purse: %d gold" % [hero.gold, s.cash]))
	var near := hero.position.distance_to(m.position) <= Entity.MARKET_RANGE and not hero.dead
	if hero.notoriety() != Entity.Notoriety.BLUE:
		shop_box.add_child(_info("\"I don't trade with criminals.\" Clear your name first."))
		near = false
	elif not near:
		shop_box.add_child(_action("Walk to %s" % m.display_name, _walk_to_shop, not hero.dead))
	var tabs := HBoxContainer.new()
	var b_buy := _menu_button("Buy" + (" <" if shop_tab == "buy" else ""), _shop_tab.bind("buy"))
	var b_sell := _menu_button("Sell" + (" <" if shop_tab == "sell" else ""), _shop_tab.bind("sell"))
	tabs.add_child(b_buy)
	tabs.add_child(b_sell)
	shop_box.add_child(tabs)
	# repairs
	var rc := hero.repair_cost(s)
	if rc > 0:
		shop_box.add_child(_action("Repair your worn gear as new (%d gold)" % rc, _on_shop_repair, near and hero.gold >= rc))
	if shop_tab == "buy":
		shop_box.add_child(_heading("Supplies"))
		for sup in _shop_supplies():
			var price := s.price(int(sup[2]))
			var what := String(sup[0])
			var label := "%s x%d" % [what.capitalize(), int(sup[1])] if what in ["arrows", "bandages", "reagents"] else Items.item_name(what)
			shop_box.add_child(_action("%s  -  %d gold" % [label, price], _on_shop_buy.bind(what, int(sup[1]), price), near and hero.gold >= price))
		shop_box.add_child(_heading("Weapons, armour and shields"))
		for id: String in SHOP_GEAR:
			var price := s.price(int(Gear.stats(id)["value"]))
			shop_box.add_child(_action("%s  -  %d gold" % [_gear_line(id), price], _on_shop_buy.bind(id, 1, price), near and hero.gold >= price))
		shop_box.add_child(_heading("Jewelry"))
		for id in Jewelry.shop_ids():
			var price := s.price(int(Jewelry.LIST[id]["value"]))
			shop_box.add_child(_action("%s (%s)  -  %d gold" % [Items.item_name(id), Jewelry.describe(id), price], _on_shop_buy.bind(id, 1, price), near and hero.gold >= price))
		shop_box.add_child(_heading("Spell scrolls (circles 1-%d you don't know yet)" % Entity.SHOP_SCROLL_CIRCLES))
		var any_scroll := false
		for sp_id: String in Spells.ORDER:
			if hero.spellbook.has(sp_id) or int(Spells.LIST[sp_id]["circle"]) > Entity.SHOP_SCROLL_CIRCLES:
				continue
			var sid := Spells.scroll_id(sp_id)
			var price := s.price(Items.scroll_price(sid))
			any_scroll = true
			shop_box.add_child(_action("%s  -  %d gold" % [Items.item_name(sid), price], _on_shop_buy.bind(sid, 1, price), near and hero.gold >= price))
		if not any_scroll:
			shop_box.add_child(_info("You know every spell this merchant has."))
	else:
		shop_box.add_child(_heading("Your bag"))
		var ids := hero.inventory.keys()
		ids.sort_custom(func(a, b) -> bool: return Items.item_name(a) < Items.item_name(b))
		var any := false
		for id in ids:
			var sid := String(id)
			if not Items.is_known(sid):
				continue
			any = true
			var offer := s.offer(sid)
			var n := int(hero.inventory[sid])
			shop_box.add_child(_action("Sell %s (you have %d)  -  %s" % [Items.item_name(sid), n,
				("%d gold" % offer) if offer > 0 else "won't buy now"], _on_shop_sell.bind(sid), near and offer > 0))
		if not any:
			shop_box.add_child(_info("Nothing to sell."))
		shop_box.add_child(_small("The merchant pays less the more of something it already holds, and only what its purse allows; it refills every couple of minutes."))
	shop_box.add_child(_menu_button("Close", _close_shop))


func _walk_to_shop() -> void:
	hero.target = null
	hero.go_to(shop_open.position)
	_close_shop()


func _on_shop_buy(id: String, n: int, price: int) -> void:
	if hero.gold < price:
		return
	hero._pay(shop_open.shop, price)
	match id:
		"arrows":
			hero.arrows += n
		"bandages":
			hero.bandages += n
		"reagents":
			hero.reagents = minf(hero.reagents + n, Entity.MAX_REAGENTS)
		_:
			hero.inventory[id] = int(hero.inventory.get(id, 0)) + n
	log_event("You buy %s for %d gold." % [("%d %s" % [n, id]) if id in ["arrows", "bandages", "reagents"] else Items.item_name(id), price])
	if Items.is_scroll(id):
		hero.learn_scrolls()
	count("shop_bought")
	_refresh_shop()


func _on_shop_sell(id: String) -> void:
	if not hero.inventory.has(id):
		return
	var price := shop_open.shop.buy_from_player(id)
	if price <= 0:
		return
	hero.inventory[id] = int(hero.inventory[id]) - 1
	if int(hero.inventory[id]) <= 0:
		hero.inventory.erase(id)
	hero.gold += price
	count("gold_earned", price)
	count("shop_sold")
	log_event("You sell a %s for %d gold." % [Items.item_name(id), price])
	_refresh_shop()


func _on_shop_repair() -> void:
	log_event(hero.repair_all(shop_open.shop))
	_refresh_shop()


# --- statistics panel: what you've done ------------------------------------------------

func _open_stats() -> void:
	paused = true
	menu.visible = false
	stats_panel.visible = true
	_refresh_stats()


func _close_stats() -> void:
	stats_panel.visible = false
	_resume()


func _stat(key: String) -> int:
	return int(property.stats_counts.get(key, 0))


## The keys starting with `prefix`, biggest first: [[name, count], ...] (top `n`).
func _top(prefix: String, n: int) -> Array:
	var out: Array = []
	for k in property.stats_counts:
		var key := String(k)
		if key.begins_with(prefix):
			out.append([key.trim_prefix(prefix), int(property.stats_counts[k])])
	out.sort_custom(func(a, b) -> bool: return int(a[1]) > int(b[1]))
	return out.slice(0, n)


func _refresh_stats() -> void:
	for c in stats_box.get_children():
		stats_box.remove_child(c)
		c.queue_free()
	var title_label := _info("Statistics")
	title_label.add_theme_font_size_override("font_size", 30)
	stats_box.add_child(title_label)
	var t := int(property.play_time)
	var s := hero.stats
	stats_box.add_child(_info("%s, level %d. Played %d h %02d min. Skills %.1f in all (combat %.1f). Fame %d, karma %d." % [
		hero.title_name(), s.level(), t / 3600, (t / 60) % 60, s.skill_total(), s.combat_total(), hero.fame, hero.karma]))
	var hits := _stat("hero_hits")
	var swings := hits + _stat("hero_misses")
	stats_box.add_child(_heading("Combat"))
	stats_box.add_child(_info("Kills %d   Deaths %d   Pets' kills %d   Bounties %d\nBlows landed %d of %d (%d%%)   Damage dealt %d   Melee damage taken %d\nParalyzed %d   Poisoned %d   Cured %d   Bandaged %d   Levels gained %d" % [
		_stat("kills"), _stat("hero_deaths"), _stat("pet_kills"), _stat("bounties"),
		hits, swings, roundi(100.0 * hits / maxf(swings, 1.0)), _stat("hero_dmg_dealt"), _stat("hero_dmg_taken_melee"),
		_stat("paralyzed"), _stat("poisoned"), _stat("cured"), _stat("bandaged"), _stat("levels_gained")]))
	var killers := _top("hero_killed_by_", 3)
	if not killers.is_empty():
		var names: Array[String] = []
		for k in killers:
			names.append("%s (%d)" % [k[0], int(k[1])])
		stats_box.add_child(_info("Killed most often by: " + ", ".join(names)))
	stats_box.add_child(_heading("Magic"))
	var fav: Array[String] = []
	for k in _top("spell_", 5):
		var sid := String(k[0])
		fav.append("%s (%d)" % [Spells.LIST[sid]["name"] if Spells.LIST.has(sid) else sid, int(k[1])])
	stats_box.add_child(_info("Spells cast %d   Scrolls learned %d   Summons %d   Ghosts raised %d\nFavourite spells: %s\nBlessings bought %d   Cured by priests %d   Confessions %d" % [
		_stat("spells_cast"), _stat("scrolls_learned"), _stat("summoned"), _stat("resurrected_others"),
		", ".join(fav) if not fav.is_empty() else "none yet", _stat("blessed"), _stat("priest_cured"), _stat("confessed")]))
	stats_box.add_child(_heading("Gathering and crafting"))
	stats_box.add_child(_info("Gathered %d   Crafted %d (exceptional %d, coloured metal %d)   Tools worn out %d" % [
		_stat("gathered"), _stat("crafted"), _stat("crafted_exceptional"), _stat("crafted_colored"), _stat("tools_broken")]))
	stats_box.add_child(_heading("Gold"))
	stats_box.add_child(_info("Earned %d   Spent %d   Corpses looted %d   Banked %d times   From appraisal %d   Begged %d (%d gold)" % [
		_stat("gold_earned"), _stat("gold_spent"), _stat("loot"), _stat("banked"), _stat("appraisal_gold"), _stat("begged"), _stat("begged_gold")]))
	stats_box.add_child(_heading("Animals and music"))
	stats_box.add_child(_info("Tamed %d of %d tries   Rides %d   Peacemaking %d   Provocation %d   Enticement %d   Failed songs %d" % [
		_stat("tamed"), _stat("tame_attempts"), _stat("mounted"), _stat("bard_peace"), _stat("bard_provoke"), _stat("bard_entice"), _stat("bard_fail")]))
	stats_box.add_child(_heading("Thievery"))
	stats_box.add_child(_info("Stole %d   Caught %d   Hid %d   Robbed by thieves %d" % [
		_stat("stole"), _stat("caught"), _stat("hid"), _stat("stolen_from_hero")]))
	stats_box.add_child(_heading("The world"))
	stats_box.add_child(_info("Quests done %d   Campfires %d   Tracked prey %d   Meals %d   Spirit Speak %d" % [
		_stat("quests_completed"), _stat("camped"), _stat("tracked"), _stat("food_eaten"), _stat("spirit_speak")]))
	stats_box.add_child(_small("Counted from version 0.47 on."))
	# achievements, and the titles they earn
	stats_box.add_child(_heading("Achievements (%d of %d)" % [property.achievements.size(), Achievements.LIST.size()]))
	for a: Dictionary in Achievements.LIST:
		var got := property.achievements.has(String(a["id"]))
		var p := Achievements.progress(a, property.stats_counts, hero.stats)
		stats_box.add_child(_info("%s %s: %s%s   (%d gold)" % ["[x]" if got else "[  ]", a["name"], a["desc"],
			"" if got else "  -  %d / %d" % [int(p[0]), int(p[1])], int(a["gold"])]))
	stats_box.add_child(_heading("Titles"))
	stats_box.add_child(_info("Wearing: %s" % (hero.title_name())))
	stats_box.add_child(_action("No title (or your fame and karma title)", _set_title.bind(""), property.title_choice != ""))
	for a: Dictionary in Achievements.LIST:
		if property.achievements.has(String(a["id"])):
			var title_text := String(a["title"])
			stats_box.add_child(_action("Be known as \"%s %s\"" % [hero.display_name, title_text], _set_title.bind(title_text), property.title_choice != title_text))
	stats_box.add_child(_menu_button("Close", _close_stats))


# --- spells panel: cast from your spellbook ----------------------------------------

## Where a spell goes, in a word or two, by its kind.
static func _spell_aim(sp: Dictionary) -> String:
	var k := String(sp["kind"])
	if k in ["attack", "poison", "paralyze", "drain"] or (k == "curse" and not bool(sp.get("area", false))):
		return "at your foe"
	if k == "field":
		return "at your foe's feet"
	if k == "area" or k == "curse":
		return "all foes around you"
	if k == "summon":
		return "summons an ally"
	if k == "transform":
		return "transforms you"
	if k == "resurrect":
		return "raises a ghost"
	if k == "dispel":
		return "dispels"
	if k == "util":
		return "utility"
	return "on you"


## The game pauses while you choose; picking a spell closes the book and starts the cast.
func _open_spells() -> void:
	paused = true
	menu.visible = false
	spells_panel.visible = true
	_refresh_spells()


func _close_spells() -> void:
	spells_panel.visible = false
	_resume()


func _refresh_spells() -> void:
	for c in spells_box.get_children():
		spells_box.remove_child(c)
		c.queue_free()
	var title_label := _info("Spellbook (%d of %d spells)" % [hero.spellbook.size(), Spells.ORDER.size()])
	title_label.add_theme_font_size_override("font_size", 30)
	spells_box.add_child(title_label)
	var foe := "none"
	if hero.target != null and is_instance_valid(hero.target) and not hero.target.dead:
		foe = hero.target.display_name
	spells_box.add_child(_info("Mana %d / %d   Reagents %d   Magery %.1f   Target: %s (or the nearest foe)" % [
		int(hero.mana), hero.stats.max_mana(), int(hero.reagents),
		float(hero.stats.skills.get(Hero.Skill.MAGERY, 0.0)), foe]))
	_add_magic_overview()
	spells_box.add_child(_action("Details: %s" % ("On" if spell_details else "Off"), _toggle_spell_details, true))
	if hero.dead:
		spells_box.add_child(_info("Ghosts can't cast. Find a healer or a shrine first."))
	elif hero.casting_id != "":
		spells_box.add_child(_info("You are already casting."))
	if last_spell != "" and hero.spellbook.has(last_spell):
		var lsp: Dictionary = Spells.LIST[last_spell]
		spells_box.add_child(_action("Again: %s (%d mana)" % [lsp["name"], int(lsp["mana"])],
			_on_cast_spell.bind(last_spell), hero.can_cast(last_spell)))
	for circle in range(1, 9):
		var ids: Array[String] = []
		for id: String in Spells.ORDER:
			if int(Spells.LIST[id]["circle"]) == circle and hero.spellbook.has(id) \
					and String(Spells.LIST[id]["kind"]) != "travel":
				ids.append(id)
		if ids.is_empty():
			continue
		spells_box.add_child(_heading("Circle %d" % circle))
		for id in ids:
			var sp: Dictionary = Spells.LIST[id]
			var b := _action("%s  -  %d mana, %s" % [sp["name"], int(sp["mana"]), _spell_aim(sp)],
				_on_cast_spell.bind(id), hero.can_cast(id))
			b.custom_minimum_size = Vector2(840, 72)
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			spells_box.add_child(b)
			if spell_details:
				spells_box.add_child(_small(_spell_detail(id)))
	spells_box.add_child(_info("Magery makes spells hit and heal harder and cast faster; Evaluating Intellect adds damage. A blow while you cast may break the spell (less likely the better your Magery); the Protection spell stops that."))
	spells_box.add_child(_info("Greyed-out spells need more mana, reagents or Magery. Find or buy scrolls to fill your book; Recall, Mark and Gate Travel are under Menu > Travel."))
	spells_box.add_child(_menu_button("Close", _close_spells))


func _toggle_spell_details() -> void:
	spell_details = not spell_details
	_refresh_spells()


func _small(text: String) -> Label:
	var l := _info(text)
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", Color(0.78, 0.82, 0.9))
	return l


## Everything about your magic in numbers: skills, mana and regeneration, power, casting speed,
## disruption, resistance, and each circle's required Magery and your success chance.
func _add_magic_overview() -> void:
	var s := hero.stats
	var magery := float(s.skills.get(Hero.Skill.MAGERY, 0.0))
	var eval_int := float(s.skills.get(Hero.Skill.EVALUATING_INTELLECT, 0.0))
	var med := float(s.skills.get(Hero.Skill.MEDITATION, 0.0))
	var resist := float(s.skills.get(Hero.Skill.RESISTING_SPELLS, 0.0))
	var metal := Gear.is_metal(hero.armor_id) or Gear.is_metal(hero.shield_id)
	var eff_med := 0.0 if metal else med
	spells_box.add_child(_heading("Your magic"))
	spells_box.add_child(_info("Magery %.1f   Evaluating Intellect %.1f   Meditation %.1f   Resisting Spells %.1f" % [magery, eval_int, med, resist]))
	spells_box.add_child(_info("Mana %d / %d (Intelligence %d). Regains %.2f a second at rest, %.2f on the move%s." % [
		int(hero.mana), s.max_mana(), s.intelligence, Rules.mana_regen(eff_med, true), Rules.mana_regen(eff_med, false),
		"; metal armor or shield stops Meditation" if metal else ""]))
	spells_box.add_child(_info("Spell damage x%.2f (Magery and Evaluating Intellect), healing x%.2f (Magery), casting %d%% faster (Magery)." % [
		Rules.spell_power(magery, eval_int), Rules.heal_power(magery), roundi(clampf(magery, 0.0, 100.0) / 4.0)]))
	var protected := hero.flags.has("protection")
	spells_box.add_child(_info("A blow while casting breaks the spell %d%% of the time%s. You shrug off %d%% of hostile spells (half damage) with Resisting Spells. Reagents: %d (each spell uses some, as in the list)." % [
		roundi(Rules.disrupt_chance(magery) * 100.0), " (but Protection is on: 0% now)" if protected else "; the Protection spell stops it",
		roundi(Rules.resist_chance(resist) * 100.0), int(hero.reagents)]))
	var rows: Array[String] = []
	for circle in range(1, 9):
		var min_skill := 0.0
		for id: String in Spells.ORDER:
			if int(Spells.LIST[id]["circle"]) == circle:
				min_skill = float(Spells.LIST[id]["min"])
				break
		rows.append("Circle %d: needs %s, %d%% success" % [circle, "%.1f" % min_skill if min_skill > 0.0 else "nothing",
			roundi(Rules.cast_chance(magery, min_skill) * 100.0)])
	spells_box.add_child(_small("   ".join(rows.slice(0, 4)) + "\n" + "   ".join(rows.slice(4, 8))))
	spells_box.add_child(_small("Success rises from 0% at a circle's minimum Magery to 100% forty points above it. Each success trains Magery (and damage spells Evaluating Intellect)."))


## One spell in numbers: circle, mana, reagents, required Magery, your success chance, cast time,
## and what it does with your current power.
func _spell_detail(id: String) -> String:
	var sp: Dictionary = Spells.LIST[id]
	var magery := float(hero.stats.skills.get(Hero.Skill.MAGERY, 0.0))
	var eval_int := float(hero.stats.skills.get(Hero.Skill.EVALUATING_INTELLECT, 0.0))
	var lo := float(sp["min_dmg"])
	var hi := float(sp["max_dmg"])
	var effect := ""
	match String(sp["kind"]):
		"attack":
			var p := Rules.spell_power(magery, eval_int)
			effect = "%d-%d damage (your power)" % [roundi(lo * p), roundi(hi * p)]
		"area":
			var p := Rules.spell_power(magery, eval_int)
			effect = "%d-%d damage to every foe within %d m" % [roundi(lo * p), roundi(hi * p), int(Spells.AREA_RADIUS)]
		"heal":
			var h := Rules.heal_power(magery)
			effect = "heals you %d-%d" % [roundi(lo * h), roundi(hi * h)]
		"cure":
			effect = "cures poison (harder the stronger the poison)"
		"poison":
			effect = "%s poison" % Rules.POISON_NAMES[Rules.spell_poison_level(magery)]
		"paralyze":
			effect = "the target can't move or act for %.1f s, or until hit" % (Spells.PARALYZE_BASE + magery / 25.0)
		"summon":
			effect = "an ally fights for you for %d s" % int(Spells.SUMMON_SECONDS)
		"buff", "curse":
			var mods: Dictionary = sp.get("mods", {})
			var parts: Array[String] = []
			for k in mods:
				parts.append("%s %+d" % [String(k).capitalize(), int(mods[k])])
			if String(sp.get("flag", "")) != "":
				parts.append(String(sp["flag"]).replace("_", " "))
			effect = "%s for %d s%s" % [", ".join(parts) if not parts.is_empty() else "an effect",
				int(float(sp.get("secs", 60.0))), " on every foe around" if bool(sp.get("area", false)) else ""]
		"drain":
			var d := 1.0 + magery / 200.0
			effect = "drains %d-%d mana%s" % [roundi(lo * d), roundi(hi * d), " into yours" if bool(sp.get("steal", false)) else ""]
		"field":
			effect = "a %s field at the target" % String(sp.get("field", "magic")).replace("_", " ")
		"dispel":
			effect = "dispels %s" % String(sp.get("field", "magic")).replace("_", " ")
		"resurrect":
			effect = "raises a ghost"
		"transform":
			var fid := String(sp.get("form", ""))
			if fid == "beast":
				effect = "you become a wolf (Dex +15, faster), a bear from Magery 75 (Str +20, armour) or an ogre from 90 (Str +30, heavy blows) for %d s; no spells meanwhile" % int(sp["secs"])
			else:
				var f: Dictionary = Spells.FORMS.get(fid, {})
				var bits: Array[String] = []
				var fm: Dictionary = f.get("mods", {})
				for k2 in fm:
					bits.append("%s %+d" % [String(k2).capitalize(), int(fm[k2])])
				if f.has("melee"):
					bits.append("blows x%.2f" % float(f["melee"]))
				if f.has("taken"):
					bits.append("damage taken x%.2f" % float(f["taken"]))
				if f.has("mana_regen"):
					bits.append("mana back x%.1f" % float(f["mana_regen"]))
				if f.has("regen"):
					bits.append("+%.1f health a second" % float(f["regen"]))
				effect = "you become %s for %d s: %s%s" % [f.get("name", fid), int(sp["secs"]), ", ".join(bits),
					"" if bool(f.get("cast", true)) else "; no spells meanwhile"]
		"travel":
			effect = "travel (Menu > Travel)"
		_:
			effect = "a special effect"
	return "   Circle %d, %d mana, %d reagents, needs Magery %s, %d%% success, %.1f s to cast: %s." % [
		int(sp["circle"]), int(sp["mana"]), int(sp["reagents"]),
		"%.1f" % float(sp["min"]) if float(sp["min"]) > 0.0 else "nothing",
		roundi(Rules.cast_chance(magery, float(sp["min"])) * 100.0),
		Rules.cast_seconds(int(sp["circle"]), magery), effect]


func _on_cast_spell(id: String) -> void:
	last_spell = id
	spells_panel.visible = false
	_resume()
	hero.cast_from_book(id)


# --- players panel: what everyone wears ------------------------------------------

## Every other player (nearest first) with their title, guild, level, standing and the gear they
## wear and wield; or just one, when opened by tapping them. Bags stay private (that's Snooping).
func _refresh_players(focus: Entity) -> void:
	for c in players_box.get_children():
		players_box.remove_child(c)
		c.queue_free()
	var title_label := _info("Players" if focus == null else focus.display_name)
	title_label.add_theme_font_size_override("font_size", 30)
	players_box.add_child(title_label)
	var list: Array = []
	if focus != null:
		list.append(focus)
	else:
		for e in creatures:
			if e.kind == Entity.Kind.PLAYER and not e.is_hero and not e.flags.has("invisible"):
				list.append(e)
		list.sort_custom(func(a, b) -> bool:
			return a.position.distance_to(hero.position) < b.position.distance_to(hero.position))
		players_box.add_child(_info("Tap a player in the world to see just them. Hidden and invisible players don't show."))
	for e in list:
		var p := e as Entity
		var g := p.guild_abbr()
		var standing := "dead (a ghost)" if p.ghost else p.notoriety_text()
		var relation := ""
		if hero.at_war_with(p):
			relation = ", at war with your guild"
		elif hero.friends_with(p):
			relation = ", your guild or ally"
		players_box.add_child(_heading("%s%s" % [p.title_name(), (" [%s]" % g) if g != "" else ""]))
		players_box.add_child(_info("Level %d, HP %d/%d, %s%s. %d m away%s." % [
			p.stats.level(), ceili(p.hp), p.stats.max_hp(), standing, relation,
			roundi(p.position.distance_to(hero.position)),
			", in town" if p._in_town() else ""]))
		var weapon_line := "bare hands" if p.weapon == "" else _gear_line(p.weapon)
		players_box.add_child(_info("Weapon: %s" % weapon_line))
		players_box.add_child(_info("Armour: %s   Shield: %s   Riding: %s" % [
			"none" if p.armor_id == "" else _gear_line(p.armor_id),
			"none" if p.shield_id == "" else _gear_line(p.shield_id),
			p.mounted_on.display_name if p.mounted_on != null else "on foot"]))
		if focus != null:
			players_box.add_child(_action("Walk over to %s" % p.display_name, _on_walk_to_player.bind(p), not hero.dead))
			var problem := hero.pvp_problem(p)
			var innocent := p.notoriety() == Entity.Notoriety.BLUE and not hero.at_war_with(p)
			if problem == "":
				players_box.add_child(_action("Attack %s%s" % [p.display_name,
					" (an innocent: you become a criminal)" if innocent else ""], _on_attack_player.bind(p), not hero.dead))
			else:
				players_box.add_child(_info("You can't attack %s: %s." % [p.display_name, problem]))
			players_box.add_child(_menu_button("All players", _open_players.bind(null)))
	players_box.add_child(_menu_button("Back", _close_players))


## The Retreat button: break off and heal (press again to stop).
func _on_retreat() -> void:
	if hero.dead:
		return
	if hero.retreating:
		hero.stop_retreat()
		log_event("You stop retreating.")
	else:
		hero.start_retreat()
	_update_retreat_button()


func _update_retreat_button() -> void:
	if retreat_button != null:
		retreat_button.text = "Retreating..." if hero.retreating else "Retreat"
	if ride_button != null:
		ride_button.text = "Dismount" if hero.mounted_on != null else "Ride"
	if bow_button != null:
		bow_button.text = "Melee" if Gear.is_ranged(hero.weapon) else "Bow"


## The Bow / Melee button: draw the best bow or crossbow (the shield goes in the bag), or go back
## to the best hand weapon and shield.
func _on_switch_weapon() -> void:
	var msg := hero.switch_weapon()
	if msg != "":
		log_event(msg)
	elif Gear.is_ranged(hero.weapon):
		log_event("Bow ready: %d arrows. Archers keep their distance and shoot from up to %d m." % [
			hero.arrows, int(hero.attack_range())])


## The Ride button: mount the nearest own mount, or get off.
func _on_ride() -> void:
	if hero.dead:
		return
	var msg := hero.toggle_ride()
	if msg != "":
		log_event(msg)


func _on_walk_to_player(p: Entity) -> void:
	_close_players()
	hero.target = null
	hero.go_to(p.position)


# --- the picked player: Attack and Info buttons at the bottom of the screen -------------

var selected_player: Entity
var select_bar: HBoxContainer
var select_attack: Button
var select_ring: MeshInstance3D
const SELECT_RANGE := 30.0               # the pick is dropped when they're further off than this


func _build_select_bar(layer: CanvasLayer) -> void:
	select_bar = HBoxContainer.new()
	select_bar.add_theme_constant_override("separation", 8)
	select_bar.visible = false
	layer.add_child(select_bar)
	select_attack = _menu_button("Attack", _on_select_attack)
	select_attack.custom_minimum_size = Vector2(250, 66)
	select_attack.add_theme_font_size_override("font_size", 24)
	select_attack.clip_text = true
	select_bar.add_child(select_attack)
	var info := _menu_button("Info", _on_select_info)
	info.custom_minimum_size = Vector2(90, 66)
	info.add_theme_font_size_override("font_size", 24)
	select_bar.add_child(info)
	var close := _menu_button("X", _select_player.bind(null))
	close.custom_minimum_size = Vector2(60, 66)
	close.add_theme_font_size_override("font_size", 24)
	select_bar.add_child(close)
	select_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)
	select_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	select_ring = Art.ground_ring(Color(0.45, 0.75, 1.0, 0.9), 0.6)
	select_ring.visible = false
	add_child(select_ring)


func _select_player(p: Entity) -> void:
	selected_player = p
	_update_select_bar()


## Keeps the buttons in step: the Attack button says why not when you can't (in town, Trammel,
## an ally...) and warns when the player is an innocent. The pick is dropped when they die,
## vanish or are far off.
func _update_select_bar() -> void:
	if select_bar == null:
		return
	var p := selected_player
	if p != null and (not is_instance_valid(p) or p.dead or p.flags.has("invisible") \
			or p.position.distance_to(hero.position) > SELECT_RANGE):
		selected_player = null
		p = null
	select_bar.visible = p != null and not hero.dead
	select_ring.visible = select_bar.visible
	if p == null:
		return
	select_ring.position = p.position + Vector3(0.0, 0.04, 0.0)
	var problem := hero.pvp_problem(p)
	var innocent := p.notoriety() == Entity.Notoriety.BLUE and not hero.at_war_with(p)
	if hero.target == p:
		select_attack.text = "Fighting %s" % p.display_name
		select_attack.disabled = true
	elif problem != "":
		select_attack.text = "Can't: %s" % problem
		select_attack.disabled = true
	else:
		select_attack.text = "Attack %s%s" % [p.display_name, " (crime!)" if innocent else ""]
		select_attack.disabled = false


func _on_select_attack() -> void:
	if selected_player != null and is_instance_valid(selected_player) and hero.pvp_problem(selected_player) == "":
		_on_attack_player(selected_player)
	_update_select_bar()


func _on_select_info() -> void:
	if selected_player != null and is_instance_valid(selected_player):
		_open_players(selected_player)


func _on_attack_player(p: Entity) -> void:
	_close_players()
	hero.retreating = false
	hero.recovering = false
	hero.pause = MANUAL_PAUSE
	hero.target = p
	log_event("You attack %s!" % p.display_name)


func _open_players(focus: Entity) -> void:
	paused = true
	menu.visible = false
	players_panel.visible = true
	_refresh_players(focus)


func _close_players() -> void:
	players_panel.visible = false
	_resume()


# --- thievery panel ----------------------------------------------------------

func _refresh_thief() -> void:
	for c in thief_box.get_children():
		thief_box.remove_child(c)
		c.queue_free()
	var title_label := _info("Thievery")
	title_label.add_theme_font_size_override("font_size", 30)
	thief_box.add_child(title_label)
	var s := hero.stats
	thief_box.add_child(_info("Hiding %.1f, Stealth %.1f, Snooping %.1f, Stealing %.1f, Detecting Hidden %.1f." % [
		s.skills[Hero.Skill.HIDING], s.skills[Hero.Skill.STEALTH], s.skills[Hero.Skill.SNOOPING],
		s.skills[Hero.Skill.STEALING], s.skills[Hero.Skill.DETECTING_HIDDEN]]))
	thief_box.add_child(_info("Hide to vanish (nobody can target you); Stealth lets you walk %.0f m hidden; attacking or casting reveals you. Snoop to see what a player next to you carries; steal to lift an item or some gold. Getting caught makes you a criminal and the victim turns on you. Watch out for Sly and Pip, the thieves." % Rules.stealth_distance(s.skills[Hero.Skill.STEALTH])))
	thief_box.add_child(_action("Hide", _on_hide, not hero.dead and not hero.effects.has("hiding")))
	thief_box.add_child(_action("Detect hidden (look for thieves close by)", _on_detect, not hero.dead))
	var mark := _nearest_player_to_hero(1.8)
	if mark == null:
		thief_box.add_child(_info("Stand right next to another player to snoop or steal."))
	else:
		var problem := hero.theft_problem(mark)
		thief_box.add_child(_action("Snoop in %s's bag" % mark.display_name, _on_snoop.bind(mark), problem == ""))
		thief_box.add_child(_action("Steal from %s" % mark.display_name, _on_steal.bind(mark), problem == ""))
		if problem != "":
			thief_box.add_child(_info("You can't: %s." % problem))
	thief_box.add_child(_menu_button("Back", _close_thief))


func _nearest_player_to_hero(radius: float) -> Entity:
	var best: Entity = null
	var best_d := radius
	for e in creatures:
		if e.is_hero or e.dead or e.kind != Entity.Kind.PLAYER:
			continue
		var d := e.position.distance_to(hero.position)
		if d <= best_d:
			best = e
			best_d = d
	return best


func _on_hide() -> void:
	if hero.try_hide():
		log_event("You hide in the shadows.")
	_refresh_thief()


func _on_detect() -> void:
	var n := hero.detect_hidden()
	log_event("You reveal %d hidden figure%s." % [n, "" if n == 1 else "s"] if n > 0 else "You see nobody hiding nearby.")
	_refresh_thief()


func _on_snoop(v: Entity) -> void:
	var seen := hero.snoop(v)
	if seen != "":
		log_event("You peek into %s's bag: %s." % [v.display_name, seen])
	_refresh_thief()


func _on_steal(v: Entity) -> void:
	var got := hero.steal_from(v)
	if got != "":
		log_event("You steal %s from %s." % [got, v.display_name])
	_refresh_thief()


func _open_thief() -> void:
	menu.visible = false
	thief_panel.visible = true
	_refresh_thief()


func _close_thief() -> void:
	thief_panel.visible = false
	menu.visible = true


func _open_guild() -> void:
	menu.visible = false
	guild_panel.visible = true
	_refresh_guild()


func _close_guild() -> void:
	guild_panel.visible = false
	menu.visible = true


func _open_prices() -> void:
	menu.visible = false
	prices_panel.visible = true
	_refresh_prices()


func _close_prices() -> void:
	prices_panel.visible = false
	menu.visible = true


## What the hero would sell: everything but upgrades, potions, instruments and (for a crafter)
## crafting materials.
func _sellable_bag() -> Dictionary:
	var out := {}
	for id in hero.inventory:
		if Items.is_potion(id) or Items.is_instrument(id):
			continue
		out[id] = hero.inventory[id]
	return out


## The hero or a co-owner close to the house.
func _someone_minds_house() -> bool:
	var center := world.tile_center(property.house_center_tile())
	var reach := float(property.house_size) + 3.0
	for e in creatures:
		if e.dead or e.kind != Entity.Kind.PLAYER:
			continue
		if (e.is_hero or property.co_owners.has(e.display_name)) and e.position.distance_to(center) <= reach:
			return true
	return false


func _spawn_vendor() -> void:
	if vendor_npc != null or not property.has_house():
		return
	vendor_npc = _spawn(Entity.Kind.NPC, "Your vendor", Bestiary.VENDOR, Color("c9a86a"),
		World.house_door(property.house_origin, property.house_size))


## Sales made while the game was closed: a few an hour, up to two days' worth.
func _settle_vendor_offline() -> void:
	var now := Time.get_unix_time_from_system()
	var hours := clampf((now - property.vendor_last) / 3600.0, 0.0, 48.0)
	property.vendor_last = now
	var made := property.vendor_sell(floori(hours * VENDOR_SALES_PER_HOUR))
	if made > 0:
		log_event("While you were away your vendor made %d gold." % made)


## While playing: now and then a customer buys something.
func _vendor_tick(delta: float) -> void:
	if not property.vendor_hired:
		return
	_vendor_timer -= delta
	if _vendor_timer > 0.0:
		return
	_vendor_timer = 60.0
	property.vendor_last = Time.get_unix_time_from_system()
	if randf() < 0.25:
		var made := property.vendor_sell(1)
		if made > 0:
			log_event("Your vendor sold something for %d gold." % made)


func _on_vendor_hire() -> void:
	property.bank_gold -= VENDOR_HIRE_COST
	property.vendor_hired = true
	property.vendor_last = Time.get_unix_time_from_system()
	_spawn_vendor()
	log_event("You hire a vendor for your house.")
	_refresh_property()


func _on_vendor_stock() -> void:
	var bag := _sellable_bag()
	Property.merge(property.vendor_stock, bag)
	for id in bag:
		hero.inventory.erase(id)
	log_event("Your vendor puts your goods on display.")
	_refresh_property()


func _on_vendor_unstock() -> void:
	Property.merge(hero.inventory, property.vendor_stock)
	property.vendor_stock.clear()
	_refresh_property()


func _on_vendor_collect() -> void:
	hero._earn(property.vendor_gold)
	log_event("You collect %d gold from your vendor." % property.vendor_gold)
	property.vendor_gold = 0
	_refresh_property()


func _open_menu() -> void:
	paused = true
	menu.visible = true
	reset_armed = false
	reset_button.text = "Reset progress"
	_autosave()


## After the movie: the game starts again from the title, nothing kept.
func restart_to_title() -> void:
	start_mode = ""
	get_tree().reload_current_scene()


func _open_adventures() -> void:
	if frontier != null:
		frontier.open_hub()


func _resume() -> void:
	paused = false
	menu.visible = false


## Restarts in the other mode (the ordinary game and experimental mode keep separate saves).
func _switch_mode(mode: String) -> void:
	if not skip_save and hero != null and start_mode != "":
		SaveGame.save(hero, property)          # keep this game's progress
	start_mode = mode
	get_tree().reload_current_scene()


func _open_experiments() -> void:
	paused = true
	menu.visible = false
	exp_panel.visible = true
	_refresh_experiments()


func _close_experiments() -> void:
	exp_panel.visible = false
	_resume()


func _refresh_experiments() -> void:
	for c in exp_box.get_children():
		exp_box.remove_child(c)
		c.queue_free()
	var t := _info("Experiments")
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(1.0, 0.6, 0.25))
	exp_box.add_child(t)
	exp_box.add_child(_info("New ideas tried out here first, in a game with its own save. Switch them on and off; the ordinary game is never touched."))
	for e: Dictionary in Experiments.LIST:
		var id := String(e["id"])
		var is_on := bool(Experiments.enabled.get(id, false))
		exp_box.add_child(_action("%s: %s" % [e["name"], "On" if is_on else "Off"], _toggle_experiment.bind(id), true))
		exp_box.add_child(_small(String(e["desc"])))
	exp_box.add_child(_menu_button("Back", _close_experiments))


func _toggle_experiment(id: String) -> void:
	Experiments.enabled[id] = not bool(Experiments.enabled.get(id, false))
	Experiments.save_cfg()
	_refresh_experiments()


func _save_now() -> void:
	if SaveGame.save(hero, property):
		log_event("Progress saved.")
	else:
		log_event("Could not save.")


func _reset_progress() -> void:
	if not reset_armed:
		reset_armed = true
		reset_button.text = "Really reset? Tap again"
		return
	skip_save = true
	SaveGame.erase()
	get_tree().reload_current_scene()


func _autosave() -> void:
	if not skip_save and hero != null and booted:   # never over the save while it's still loading
		SaveGame.save(hero, property)


## Save when the game is closed or sent to the background (Android may kill it there).
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_autosave()


func _spawn_all() -> void:
	var gold := Color("f0c850")
	var blue := Color("4a7bd6")      # other players: innocent
	var cream := Color("e8e2c8")     # NPCs
	var red := Color("c0392b")       # monsters: hostile

	hero = _spawn(Entity.Kind.PLAYER, "Hero", Bestiary.HERO, gold, Vector2i(5, 5))
	hero.is_hero = true
	hero.prefers_bow = false                  # your hero draws a bow only at range (on Auto)
	if not autotest:
		hero.roam = world.zone_rect(0)            # on Auto, the hero travels the land too
		hero.roam_timer = 300.0
	hero._think_every = 0.05                  # the hero decides quickly, so taps feel immediate
	# The other players, spread evenly over the map's 8 regions (4 across, 2 down): each gets a
	# home region, starts there and keeps to it. Two player killers and two thieves, kept apart.
	var others := [
		["Aldric", Bestiary.WARRIOR], ["Mira", Bestiary.FIGHTER], ["Selene", Bestiary.MAGE],
		["Vex", Bestiary.PKILLER], ["Gareth", Bestiary.WARRIOR], ["Lyra", Bestiary.MAGE],
		["Thorne", Bestiary.FIGHTER], ["Brina", Bestiary.ARCHER], ["Dorian", Bestiary.WARRIOR],
		["Sly", Bestiary.THIEF], ["Morg", Bestiary.PKILLER], ["Pip", Bestiary.THIEF],
		["Fenn", Bestiary.CROSSBOWMAN],
		# more of them, for the whole land: each keeps to a region of their own, spread far and wide
		["Rowan", Bestiary.WARRIOR], ["Isla", Bestiary.MAGE], ["Brom", Bestiary.FIGHTER], ["Kestrel", Bestiary.ARCHER],
		["Hale", Bestiary.CROSSBOWMAN], ["Nyx", Bestiary.THIEF], ["Garrick", Bestiary.PKILLER], ["Elda", Bestiary.MAGE],
		["Torin", Bestiary.WARRIOR], ["Faye", Bestiary.FIGHTER],
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 777                           # the same layout every game
	for i in range(others.size()):
		# spread evenly over all the regions (every third or so), not packed into the first few
		var zone := world.zone_rect(int(float(i) * world.zone_count() / others.size() + 0.5) % world.zone_count())
		var cfg: Dictionary = others[i][1]
		var p := _spawn(Entity.Kind.PLAYER, String(others[i][0]), cfg, blue, world.open_tile_in(zone, rng))
		p.roam = zone
		p.roam_timer = rng.randf_range(120.0, 480.0)     # staggered: they don't all set off at once

	_build_braziers()
	_build_shrines()
	_build_broken_circle()
	_build_banners()
	_spawn(Entity.Kind.NPC, "Elara", Bestiary.HEALER, cream, Vector2i(24, 11))
	_spawn(Entity.Kind.NPC, "Hal the Stablemaster", Bestiary.STABLEMASTER, cream, Vector2i(21, 11))
	_spawn(Entity.Kind.NPC, "Father Corwin", Bestiary.PRIEST, Color("d9c7f0"), Vector2i(26, 19))   # in his church
	var bran := _spawn(Entity.Kind.NPC, "Bran", Bestiary.MERCHANT, cream, Vector2i(23, 6))
	bran.shop = Shop.new("town", 1.0, 1.0)
	# The outpost is remote: its merchant pays more for goods and charges more for supplies.
	var mara := _spawn(Entity.Kind.NPC, "Mara", Bestiary.MERCHANT, cream, Vector2i(37, 3))
	mara.shop = Shop.new("the outpost", 1.3, 1.25)
	_spawn(Entity.Kind.NPC, "Oswin", Bestiary.BANKER, cream, Vector2i(26, 12))
	_spawn(Entity.Kind.NPC, Quests.GIVER, Bestiary.QUESTGIVER, Color("c9a86a"), Vector2i(22, 13))
	# The outpost, east of the main town, near the dungeon.
	_spawn(Entity.Kind.NPC, "Brother Aldo", Bestiary.HEALER, cream, Vector2i(35, 4))
	_spawn(Entity.Kind.NPC, "Brother Anselm", Bestiary.PRIEST, Color("c8d0e8"), Vector2i(39, 5))
	# Southmoor, the southern town: its merchant pays a little more and charges a little more.
	_spawn(Entity.Kind.NPC, "Sister Maeve", Bestiary.HEALER, cream, Vector2i(46, 31))
	_spawn(Entity.Kind.NPC, "Mother Isolde", Bestiary.PRIEST, Color("eef2fa"), Vector2i(48, 32))   # the abbess
	var hollis := _spawn(Entity.Kind.NPC, "Hollis", Bestiary.MERCHANT, cream, Vector2i(53, 31))
	hollis.shop = Shop.new("Southmoor", 1.15, 1.1)
	_spawn(Entity.Kind.NPC, "Pell", Bestiary.BANKER, cream, Vector2i(46, 37))
	# Dawnport, the town of the eastern lands: far from anywhere, so goods are dear.
	_spawn(Entity.Kind.NPC, "Sister Ilse", Bestiary.HEALER, cream, Vector2i(106, 10))
	_spawn(Entity.Kind.NPC, "Father Edric", Bestiary.PRIEST, Color("e8dcc0"), Vector2i(112, 10))
	var quill := _spawn(Entity.Kind.NPC, "Quill", Bestiary.MERCHANT, cream, Vector2i(107, 14))
	quill.shop = Shop.new("Dawnport", 1.35, 1.3)
	_spawn(Entity.Kind.NPC, "Marta", Bestiary.BANKER, cream, Vector2i(111, 14))
	# Highmoor, the town of the far south.
	_spawn(Entity.Kind.NPC, "Brother Tam", Bestiary.HEALER, cream, Vector2i(98, 102))
	var wyn := _spawn(Entity.Kind.NPC, "Wyn", Bestiary.MERCHANT, cream, Vector2i(104, 102))
	wyn.shop = Shop.new("Highmoor", 1.25, 1.2)
	_spawn(Entity.Kind.NPC, "Osric", Bestiary.BANKER, cream, Vector2i(100, 106))
	# Four more towns, so that every part of the land has one: Westford in the west, Reedwick by
	# the Reedmarsh, Midmark in the middle of the land, Stormhold in the east.
	for t in [["Westford", Vector2i(7, 90), "Sister Wenna", "Dob", "Hesk", 1.2],
			["Reedwick", Vector2i(39, 102), "Brother Aldo", "Fen", "Garra", 1.2],
			["Midmark", Vector2i(80, 75), "Sister Mael", "Corwin", "Lise", 1.1],
			["Stormhold", Vector2i(124, 44), "Brother Kord", "Yara", "Thane", 1.3]]:
		var o: Vector2i = t[1]
		_spawn(Entity.Kind.NPC, String(t[2]), Bestiary.HEALER, cream, o + Vector2i(2, 2))
		var shopkeep := _spawn(Entity.Kind.NPC, String(t[3]), Bestiary.MERCHANT, cream, o + Vector2i(8, 2))
		shopkeep.shop = Shop.new(String(t[0]), float(t[5]), float(t[5]) - 0.05)
		_spawn(Entity.Kind.NPC, String(t[4]), Bestiary.BANKER, cream, o + Vector2i(5, 6))

	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(12, 8))
	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(6, 11))
	_spawn(Entity.Kind.MONSTER, "Wolf", Bestiary.WOLF, red, Vector2i(21, 24))
	_spawn(Entity.Kind.MONSTER, "Giant Spider", Bestiary.GIANT_SPIDER, Color("3a3a2a"), Vector2i(4, 21))   # south-west woods
	_spawn(Entity.Kind.MONSTER, "Hind", Bestiary.HIND, Color("b08a5a"), Vector2i(4, 13))
	_spawn(Entity.Kind.MONSTER, "Hind", Bestiary.HIND, Color("b08a5a"), Vector2i(12, 22))
	_spawn(Entity.Kind.MONSTER, "Brown Bear", Bestiary.BROWN_BEAR, Color("6b4a2a"), Vector2i(27, 25))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(24, 26))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(16, 20))
	_spawn(Entity.Kind.MONSTER, "Evil Mage", Bestiary.EVIL_MAGE, red, Vector2i(14, 22))
	# The dungeon.
	_spawn(Entity.Kind.MONSTER, "Skeleton", Bestiary.SKELETON, Color("d8d2c0"), Vector2i(39, 13))
	_spawn(Entity.Kind.MONSTER, "Skeleton", Bestiary.SKELETON, Color("d8d2c0"), Vector2i(40, 20))
	_spawn(Entity.Kind.MONSTER, "Zombie", Bestiary.ZOMBIE, Color("6f8f5a"), Vector2i(44, 12))
	_spawn(Entity.Kind.MONSTER, "Ogre", Bestiary.OGRE, Color("8a6a4a"), Vector2i(44, 20))
	_spawn(Entity.Kind.MONSTER, "Lich", Bestiary.LICH, Color("6a4a8a"), Vector2i(48, 12))
	_spawn(Entity.Kind.MONSTER, "The Bone King", Bestiary.BONE_KING, Color("3a2a4a"), Vector2i(48, 20))   # the deepest hall

	# The eastern wilds: wolf packs, deer, the bear wood and the orc fort.
	for t in [Vector2i(58, 10), Vector2i(60, 12), Vector2i(57, 13)]:
		_spawn(Entity.Kind.MONSTER, "Wolf", Bestiary.WOLF, red, t)
	for t in [Vector2i(75, 18), Vector2i(88, 15)]:
		_spawn(Entity.Kind.MONSTER, "Hind", Bestiary.HIND, Color("b08a5a"), t)
	for t in [Vector2i(63, 17), Vector2i(67, 18)]:
		_spawn(Entity.Kind.MONSTER, "Brown Bear", Bestiary.BROWN_BEAR, Color("6b4a2a"), t)
	for t in [Vector2i(55, 4), Vector2i(70, 3)]:
		_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, t)
	for t in [Vector2i(84, 4), Vector2i(87, 6), Vector2i(90, 4), Vector2i(86, 8)]:
		_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, t)
	_spawn(Entity.Kind.MONSTER, "Ogre", Bestiary.OGRE, Color("8a6a4a"), Vector2i(88, 3))
	# Wild horses on the eastern plains, llamas in the south-east hills: tame one and ride it.
	for t in [Vector2i(66, 8), Vector2i(80, 14)]:
		_spawn(Entity.Kind.MONSTER, "Horse", Bestiary.HORSE, Color("7a5232"), t)
	_spawn(Entity.Kind.MONSTER, "Llama", Bestiary.LLAMA, Color("e8e0d0"), Vector2i(58, 42))
	for t in [Vector2i(8, 30), Vector2i(20, 33)]:
		_spawn(Entity.Kind.MONSTER, "Forest Ostard", Bestiary.OSTARD, Color("8a6a3a"), t)
	for t in [Vector2i(62, 28), Vector2i(70, 44)]:
		_spawn(Entity.Kind.MONSTER, "Giant Beetle", Bestiary.BEETLE, Color("283040"), t)
	_spawn(Entity.Kind.MONSTER, "Swamp Dragon", Bestiary.SWAMP_DRAGON, Color("4a6a3a"), Vector2i(40, 43))
	_spawn(Entity.Kind.MONSTER, "Nightmare", Bestiary.NIGHTMARE, Color("1a1418"), Vector2i(44, 16))
	# The southern forest: spiders, wolves, deer.
	for t in [Vector2i(10, 34), Vector2i(22, 38)]:
		_spawn(Entity.Kind.MONSTER, "Giant Spider", Bestiary.GIANT_SPIDER, Color("3a3a2a"), t)
	for t in [Vector2i(15, 28), Vector2i(26, 44)]:
		_spawn(Entity.Kind.MONSTER, "Wolf", Bestiary.WOLF, red, t)
	_spawn(Entity.Kind.MONSTER, "Hind", Bestiary.HIND, Color("b08a5a"), Vector2i(8, 30))
	_spawn(Entity.Kind.MONSTER, "Brown Bear", Bestiary.BROWN_BEAR, Color("6b4a2a"), Vector2i(20, 33))
	# The swamp, the hills and the plains round Southmoor.
	for t in [Vector2i(40, 43), Vector2i(31, 35)]:
		_spawn(Entity.Kind.MONSTER, "Zombie", Bestiary.ZOMBIE, Color("6f8f5a"), t)
	_spawn(Entity.Kind.MONSTER, "Ogre", Bestiary.OGRE, Color("8a6a4a"), Vector2i(70, 44))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(66, 41))
	_spawn(Entity.Kind.MONSTER, "Evil Mage", Bestiary.EVIL_MAGE, red, Vector2i(78, 26))
	for t in [Vector2i(40, 30), Vector2i(58, 36), Vector2i(45, 26), Vector2i(62, 28)]:
		_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, t)
	# The old graveyard in the south-east: the restless dead.
	for t in [Vector2i(85, 30), Vector2i(90, 34), Vector2i(86, 38)]:
		_spawn(Entity.Kind.MONSTER, "Skeleton", Bestiary.SKELETON, Color("d8d2c0"), t)
	_spawn(Entity.Kind.MONSTER, "Zombie", Bestiary.ZOMBIE, Color("6f8f5a"), Vector2i(89, 30))
	_spawn(Entity.Kind.MONSTER, "Lich", Bestiary.LICH, Color("6a4a8a"), Vector2i(91, 35))
	# Monsters that shoot: crossbow orcs in the fort, skeleton archers in the graveyard and dungeon.
	for t in [Vector2i(84, 4), Vector2i(90, 7)]:
		_spawn(Entity.Kind.MONSTER, "Orc Archer", Bestiary.ORC_ARCHER, red, t)
	for t in [Vector2i(88, 29), Vector2i(84, 35), Vector2i(41, 17)]:
		_spawn(Entity.Kind.MONSTER, "Skeleton Archer", Bestiary.SKELETON_ARCHER, Color("d8d2c0"), t)
	_even_out_monsters(rng)


## Tops up the empty regions to a few monsters each, picking
## a creature that suits the area (the start area stays gentle).
func _even_out_monsters(rng: RandomNumberGenerator) -> void:
	var counts: Array[int] = []
	counts.resize(world.zone_count())
	counts.fill(0)
	for e in creatures:
		if e.kind == Entity.Kind.MONSTER:
			for i in range(world.zone_count()):
				if world.zone_rect(i).has_point(world.to_tile(e.home)):
					counts[i] += 1
	var goal := 3                                    # the empty regions: a few each (the land is wide, not crowded)
	if Experiments.on("crowded"):
		goal = ceili(goal * 1.5)
	var red := Color("c0392b")
	# What each region gets: north-west (by the start) to south-east (the graveyard).
	var picks := [
		["Rat", Bestiary.RAT, red], ["Rat", Bestiary.RAT, red], ["Wolf", Bestiary.WOLF, red],
		["Orc", Bestiary.ORC, red], ["Wolf", Bestiary.WOLF, red], ["Orc", Bestiary.ORC, red],
		["Wolf", Bestiary.WOLF, red], ["Zombie", Bestiary.ZOMBIE, Color("6f8f5a")], ["Orc", Bestiary.ORC, red],
		["Skeleton", Bestiary.SKELETON, Color("d8d2c0")], ["Wolf", Bestiary.WOLF, red], ["Orc", Bestiary.ORC, red],
	]
	# The rest of the land (the far east and the south): its own mix, tougher further from the start.
	var south := [["Wolf", Bestiary.WOLF, red], ["Orc", Bestiary.ORC, red], ["Brown Bear", Bestiary.BROWN_BEAR, Color("6b4a2a")],
		["Giant Spider", Bestiary.GIANT_SPIDER, Color("3a3a2a")], ["Skeleton", Bestiary.SKELETON, Color("d8d2c0")],
		["Zombie", Bestiary.ZOMBIE, Color("6f8f5a")], ["Hind", Bestiary.HIND, Color("b08a5a")],
		["Ogre", Bestiary.OGRE, Color("8a6a4a")], ["Evil Mage", Bestiary.EVIL_MAGE, red], ["Orc Archer", Bestiary.ORC_ARCHER, red]]
	for i in range(world.zone_count()):
		var far := i % World.ZONE_COLS >= 4 or i / World.ZONE_COLS >= 2      # beyond the old lands
		var near_pick: Array = picks[mini((i / World.ZONE_COLS) * 4 + i % World.ZONE_COLS, picks.size() - 1)]
		for _k in range(goal - counts[i]):
			var pick: Array = south[(i * 3 + _k) % south.size()] if far else near_pick
			var cfg: Dictionary = pick[1]
			_spawn(Entity.Kind.MONSTER, String(pick[0]), cfg, pick[2], world.open_tile_in(world.zone_rect(i), rng))


## Half the wild: of each kind of monster that the land has more than one of, every second one is
## taken away (the one-of-a-kind ones - chiefs, bosses, the Lich - and the beasts you can ride all stay).
func _halve_monsters() -> void:
	var counts := {}
	for e in creatures:
		if e.kind == Entity.Kind.MONSTER:
			counts[e.display_name] = int(counts.get(e.display_name, 0)) + 1
	var seen := {}
	for e in creatures.duplicate():
		if e.kind != Entity.Kind.MONSTER or int(counts[e.display_name]) < 2 or e.display_name in MOUNTS:
			continue
		seen[e.display_name] = int(seen.get(e.display_name, 0)) + 1
		if int(seen[e.display_name]) % 2 == 1:     # (the first, third, ...: of three, two go)
			creatures.erase(e)
			e.queue_free()


const MOUNTS := ["Horse", "Llama", "Forest Ostard", "Swamp Dragon", "Nightmare", "Giant Beetle"]


func _spawn(kind: int, label_text: String, cfg: Dictionary, color: Color, tile: Vector2i) -> Entity:
	var e := Entity.new()
	add_child(e)
	e.setup(self, kind, label_text, cfg, color, tile)
	creatures.append(e)
	return e


func spawn_corpse(victim: Entity) -> void:
	var c := Corpse.new()
	add_child(c)
	var open_to_all := victim.notoriety() != Entity.Notoriety.BLUE   # monsters, criminals, murderers
	var at := victim.position
	at.y = world.height_at(at)                    # lies on the ground (a creature may die mid-stride or in a boat)
	c.setup(victim.display_name, open_to_all, victim.kind == Entity.Kind.PLAYER,
		victim.get_instance_id(), at, victim.make_loot())
	corpses.append(c)
	c.label.visible = property.corpse_names_on
	if victim.kind == Entity.Kind.MONSTER and not victim.summoned and randf() < CHEST_CHANCE:
		_drop_chest(victim)


const CHEST_CHANCE := 0.03             # any slain monster may leave a treasure chest (rarely)


## A treasure chest with an artifact, gold and reagents drops beside a slain monster; anyone may
## take it, so be quick.
# --- treasure maps, and the pool of event creatures ------------------------------------

var map_mark := Vector2i(-1, -1)          # the spot of the treasure map last read (a red X on the minimap)
var _pool: Array[Entity] = []             # guardians, invaders, champions: reused, never respawn on their own


## A new treasure map: a chest buried somewhere out in the wilds (not in a town or the dungeon).
func make_treasure_map() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var t := world.open_tile_in(world.zone_rect(rng.randi() % world.zone_count()), rng)
	return "tmap@%d_%d" % [t.x, t.y]


## A creature for an event, at `at`: an idle one from the pool if there is one of that name,
## else a new one. They don't respawn by themselves.
func pool_spawn(creature_name: String, cfg: Dictionary, color: Color, at: Vector3) -> Entity:
	for e in _pool:
		if e.display_name == creature_name and e.dead and not e.ghost:
			e.revive_at(at)
			return e
	var c := cfg.duplicate()
	c["respawn"] = 1.0e9
	var e := _spawn(Entity.Kind.MONSTER, creature_name, c, color, world.to_tile(at))
	_pool.append(e)
	return e


## The map's chest is dug up: gold, reagents, scrolls of high circles, often an artifact and a
## ring or amulet, and the dead who guarded it rise around it.
func dig_up_treasure(digger: Entity, map_id: String) -> void:
	var t := Items.map_tile(map_id)
	if t.x < 0 or not digger.inventory.has(map_id):
		return
	Crafting.take_mats(digger.inventory, {map_id: 1}, 1.0)
	if map_mark == t:
		map_mark = Vector2i(-1, -1)
	var items := {}
	if randf() < 0.5:
		var arts := Gear.artifact_ids()
		items[arts[randi() % arts.size()]] = 1
	if randf() < 0.6:
		items[Jewelry.random_id()] = 1
	for _i in range(randi_range(1, 2)):
		var sp := Spells.random_of_circles(5, 8)
		if sp != "":
			items[Spells.scroll_id(sp)] = 1
	var loot := {"gold": randi_range(300, 900), "reagents": randi_range(10, 30), "items": items}
	var pos := world.tile_center(t)
	var c := Corpse.new()
	add_child(c)
	c.setup("Treasure", true, false, 0, pos, loot)
	c.make_chest()
	c.set_title("Buried Treasure")
	c.label.visible = property.corpse_names_on
	corpses.append(c)
	var guards := [["Skeleton", Bestiary.SKELETON, Color("d8d2c0")], ["Skeleton Archer", Bestiary.SKELETON_ARCHER, Color("d8d2c0")],
		["Zombie", Bestiary.ZOMBIE, Color("6f8f5a")]]
	for i in range(randi_range(2, 3)):
		var g: Array = guards[randi() % guards.size()]
		var at := pos + Vector3(randf_range(-2.5, 2.5), 0.0, randf_range(-2.5, 2.5))
		if world.is_blocked(world.to_tile(at)):
			at = pos
		var guard := pool_spawn(String(g[0]), g[1], g[2], at)
		guard.target = digger
	if digger.is_hero:
		count("treasures_dug")
		log_event("You dig up a buried chest... and its guardians rise from the earth!")
		Fx.sparkle(self, pos + Vector3(0.0, 0.4, 0.0), Color(1.0, 0.85, 0.45), 30)


## A player (or the hero on Auto) has spent long enough in one region: off to another across the
## map, preferring the emptiest ones so everyone stays spread out while on the move.
func next_region(e: Entity) -> void:
	e.roam_timer = randf_range(240.0, 480.0)
	var counts: Array[int] = []
	counts.resize(world.zone_count())
	counts.fill(0)
	for c in creatures:
		if c.kind == Entity.Kind.PLAYER and c != e and not c.dead:
			for i in range(world.zone_count()):
				if world.zone_rect(i) == c.roam:
					counts[i] += 1
	var best: Array[int] = []
	var least := 1 << 30
	for i in range(world.zone_count()):
		if world.zone_rect(i) == e.roam:
			continue
		if counts[i] < least:
			least = counts[i]
			best = [i]
		elif counts[i] == least:
			best.append(i)
	if best.is_empty():
		return
	var zone := world.zone_rect(best[randi() % best.size()])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	e.roam = zone
	e.set_journey(world.tile_center(world.open_tile_in(zone, rng)))
	if e.is_hero:
		log_event("Your hero sets off for another part of the land.")


## Tap the minimap: the hero walks there, right across the map if need be (a gold flag marks it).
func hero_journey(tile: Vector2i) -> void:
	if not world.in_bounds(tile):
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if world.is_blocked(tile):
		tile = world.open_tile_in(Rect2i(tile - Vector2i(2, 2), Vector2i(5, 5)), rng)
	var dest := world.tile_center(tile)
	if hero.dead:
		if hero.ghost:
			hero.go_to(dest)
		return
	hero.retreating = false
	hero.recovering = false
	hero.pause = MANUAL_PAUSE
	hero.set_journey(dest)
	var place := world.place_name(tile)
	var v := dest - hero.position
	log_event("You set off for %s: %d m %s. Tap the ground to stop." % [
		place if place != "" else "the spot", roundi(v.length()), _compass(v)])


func _drop_chest(victim: Entity) -> void:
	var arts := Gear.artifact_ids()
	var art := arts[randi() % arts.size()]
	var loot := {"gold": randi_range(40, 120) * maxi(1, int(victim.danger)), "reagents": randi_range(0, 10),
		"items": {art: 1}}
	if randf() < 0.4:
		(loot["items"] as Dictionary)[Jewelry.random_id()] = 1     # often a ring or amulet too
	var pos := victim.position + Vector3(randf_range(-0.9, 0.9), 0.0, randf_range(-0.9, 0.9))
	if world.is_blocked(world.to_tile(pos)):
		pos = victim.position
	pos.y = world.height_at(pos)                  # on the ground, hillside or not
	var c := Corpse.new()
	add_child(c)
	c.setup("Treasure", true, false, 0, pos, loot)
	c.make_chest()
	corpses.append(c)
	c.label.visible = property.corpse_names_on
	if hero != null and pos.distance_to(hero.position) <= 25.0:
		log_event("The %s leaves a treasure chest! (%s inside)" % [victim.display_name, Items.item_name(art)])
		sound("loot", pos)


func _build_environment() -> void:
	add_child(sfx)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("87a8c9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.76)
	env.ambient_light_energy = 0.8
	# The sky: blue by day, glowing orange towards the sun at dawn and dusk, dark with stars and
	# a moon at night. It is also where the ambient light comes from (bluish from above, a green
	# bounce from the ground), kept bright enough at night that the world never goes black.
	var sky_sh := Shader.new()
	sky_sh.code = SKY_SHADER
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = sky_sh
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL      # ambient light updates spread over frames
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# Filmic tone mapping keeps bright fire and sunlit grass from washing out; a light haze
	# gives the distance some depth (weather thickens it); glow is set by the graphics level.
	env.tonemap_mode = Environment.TONE_MAPPER_ACES     # deeper shadows, highlights that roll off like film
	env.tonemap_exposure = 1.05
	env.tonemap_white = 6.0
	env.adjustment_enabled = true                      # the grade: a little less colour, a little more punch
	env.adjustment_saturation = 0.85
	env.adjustment_contrast = 1.1
	env.fog_enabled = false                            # no fog or haze, ever: the land is seen clear to the horizon
	env.glow_intensity = 0.6
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 0.9
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	add_child(music)
	add_child(rain_sound)
	rain_sound.volume_db = -14.0
	rain_sound.bus = "Ambience"
	_build_rain()
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	_build_grade()


## The colour grade: the whole picture, under the buttons and text, passes through one shader
## that takes it from bright toy colours towards a painting - a little less saturated, a little
## more contrast, cool blue in the shadows and warm gold in the lights, the corners darkened.
const GRADE_SHADER := """
shader_type canvas_item;
uniform float vignette = 0.38;
// Only the vignette, laid over the picture (it never reads the screen back: a full-screen copy
// every frame cost more than it gave). The colour itself is graded by the environment.
void fragment() {
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.2, 1.0);
	COLOR = vec4(0.0, 0.0, 0.0, vignette * smoothstep(0.38, 0.95, length(d)));
}
"""
var _grade: ColorRect


func _build_grade() -> void:
	var under := CanvasLayer.new()
	under.layer = 0                                    # over the 3D world, under the interface
	add_child(under)
	_grade = ColorRect.new()
	var sh := Shader.new()
	sh.code = GRADE_SHADER
	var gm := ShaderMaterial.new()
	gm.shader = sh
	_grade.material = gm
	_grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	under.add_child(_grade)
	_grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


var hero_ring: MeshInstance3D
var target_ring: MeshInstance3D


## Rings on the ground: gold under the hero, a pulsing red one under whatever it fights.
func _build_rings() -> void:
	hero_ring = Art.ground_ring(Color(1.0, 0.82, 0.3, 0.85), 0.55)
	add_child(hero_ring)
	target_ring = Art.ground_ring(Color(1.0, 0.25, 0.2, 0.9), 0.6)
	target_ring.visible = false
	add_child(target_ring)


func _update_rings() -> void:
	hero_ring.visible = not hero.dead and not property.first_person and hero.visible
	if select_ring != null and select_ring.visible and selected_player != null and is_instance_valid(selected_player):
		select_ring.position = selected_player.position + Vector3(0.0, 0.04, 0.0)
	hero_ring.position = hero.position + Vector3(0.0, 0.04, 0.0)
	var t := hero.target
	var show := t != null and is_instance_valid(t) and not t.dead and t.visible
	target_ring.visible = show
	if show:
		var pulse := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.008)
		var k := t.visual_scale * pulse
		target_ring.position = t.position + Vector3(0.0, 0.04, 0.0)
		target_ring.scale = Vector3(k, 0.15, k)


func _build_marker() -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = 0.3
	ring.bottom_radius = 0.3
	ring.height = 0.04
	marker.mesh = ring
	marker.material_override = World._mat(Color(0.35, 0.78, 1.0))
	marker.visible = false
	add_child(marker)


## The logs are coloured by what a line is about, each with a mark in front: deaths red (†),
## danger orange (!), gold yellow ($), spoils and things made pale gold (+), skills and levels
## cyan (*), quests and bounties violet (»), magic blue (*), healing and rest green (+), travel
## teal (»), tips grey. The first kind whose words appear in the line wins.
const LOG_KINDS := [
	["skull", "ff6a5c", ["slain", "you die", "has fallen", "falls in the arena", "murdered"]],
	["scroll", "c9a2ff", ["quest", "task", "bounty", "chapter", "story", "return to "]],
	["alert", "ffa64d", ["attack", "poison", "criminal", "murder", "invasion", "warband", "raises the dead", "march on", "breaks",
		"you burn", "you fail", "you lose", "can't", "you need", "forfeit", "champion", "wanted", "stolen", "steal"]],
	["coin", "ffd94d", ["gold", "you sell", "you buy", "bank", "reward", "tolls"]],
	["star", "66e0ff", ["skill", "level", "you learn", "title", "achievement", "stronger", "you are now"]],
	["magic", "7fa8ff", ["cast", "spell", "scroll", "bless", "resurrect", "mana", "summon", "transform", "enchant"]],
	["heart", "7dea7d", ["heal", "cured", "rested", "well fed", "you eat", "you drink", "you sleep", "welcome", "bandage"]],
	["travel", "5fd9c0", ["you enter", "you leave", "set off", "descend", "climb", "push off", "ashore", "arrive", "takes ", "tower", "comes:"]],
	["chest", "f0dc9a", ["loot", "you find", "you make", "you cook", "you catch", "you gather", "you brew", "treasure", "pearl", "+1",
		"you take", "you pick", "smelt", "tame", "harvest", "you sow"]],
	["info", "aab2c0", ["tip:"]],
]


func _setup_log(l: RichTextLabel, font_px: int, width: float) -> void:
	l.bbcode_enabled = false
	l.fit_content = true
	l.scroll_active = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	l.add_theme_font_size_override("normal_font_size", font_px)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	l.set_meta("px", font_px)


## Which kind of line this is (an index into LOG_KINDS), or -1.
static func _log_kind(text: String) -> int:
	var low := text.to_lower()
	for i in range(LOG_KINDS.size()):
		for word in LOG_KINDS[i][2]:
			if low.contains(String(word)):
				return i
	return -1


## Writes the lines into a log: each with its little icon in front, in its colour.
func _render_log(l: RichTextLabel, lines: Array[String], right: bool) -> void:
	l.clear()
	var px := int(l.get_meta("px", 24))
	if right:
		l.push_paragraph(HORIZONTAL_ALIGNMENT_RIGHT)
	for i in range(lines.size()):
		var k := _log_kind(lines[i])
		var col := Color("eeeeea") if k < 0 else Color(String(LOG_KINDS[k][1]))
		var icon := "dot" if k < 0 else String(LOG_KINDS[k][0])
		l.add_image(Icons.tex(icon), px, px, col)
		l.push_color(col)
		l.add_text(" " + lines[i])
		l.pop()
		if i < lines.size() - 1:
			l.newline()
	if right:
		l.pop()


func log_event(text: String) -> void:
	log_lines.append(text)
	while log_lines.size() > LOG_LINES:
		log_lines.remove_at(0)
	_render_log(log_label, log_lines, false)


## Goes to the player's log (left) if it involves the hero, otherwise to the world log (right).
func event_about(text: String, mine: bool) -> void:
	if mine:
		log_event(text)
	else:
		world_event(text)


func world_event(text: String) -> void:
	world_lines.append(text)
	while world_lines.size() > LOG_LINES:
		world_lines.remove_at(0)
	_render_log(world_label, world_lines, true)


# --- input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if paused or not booted or (movie != null and movie.running):
		return
	# Two fingers: pinch to zoom, twist to turn the camera. Taps are ignored meanwhile.
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			touches[st.index] = st.position
		else:
			touches.erase(st.index)
		_pinch_dist = 0.0
		if touches.size() >= 2:
			held = false
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		touches[sd.index] = sd.position
		if touches.size() >= 2:
			_pinch()
			return
	if event is InputEventMagnifyGesture:
		_zoom((event as InputEventMagnifyGesture).factor)
		return
	var wheel := event as InputEventMouseButton
	if wheel != null and wheel.pressed and \
			(wheel.button_index == MOUSE_BUTTON_WHEEL_UP or wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		_zoom(1.1 if wheel.button_index == MOUSE_BUTTON_WHEEL_UP else 0.9)
		return
	if touches.size() >= 2:
		return
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if property.first_person:
			# first person: drag one finger to look round; a short tap walks or attacks
			if button.pressed:
				held = true
				_press_pos = button.position
				_dragging = false
			else:
				if held and not _dragging:
					_tap(button.position)
				held = false
				_dragging = false
			return
		held = button.pressed
		if held:
			_tap(button.position)
	elif event is InputEventMouseMotion and held:
		var mm := event as InputEventMouseMotion
		if property.first_person:
			if not _dragging and mm.position.distance_to(_press_pos) > 14.0:
				_dragging = true
			if _dragging:
				_fp_yaw -= mm.relative.x * 0.006
				_fp_pitch = clampf(_fp_pitch - mm.relative.y * 0.005, -1.1, 0.5)
				_fp_free_until = Time.get_ticks_msec() / 1000.0 + 4.0
			return
		_tap(mm.position)


## Intersects the camera ray through `screen` with the ground plane (y = 0).
func _tap(screen: Vector2) -> void:
	if _cine_phase != 0:
		return                                    # a story scene is playing
	var picked := _creature_at_screen(screen, 70.0 if property.first_person else 40.0)
	var hit: Variant = world.ray_ground(cam.project_ray_origin(screen), cam.project_ray_normal(screen))   # hills too
	if hit == null and picked == null:
		return
	var dest: Vector3
	if hit != null:
		dest = hit
	else:
		dest = picked.position
	if hero.dead:
		if hero.ghost:
			hero.go_to(dest)                # a ghost can only walk: find a resurrection spot
		return
	hero.pause = MANUAL_PAUSE  # player input wins; auto resumes after a pause
	hero.has_journey = false   # a tap ends a walk across the map
	var e := picked if picked != null else _creature_near(dest)
	if e != null and e.kind == Entity.Kind.MONSTER:
		hero.target = e
		hero.loot_target = null
		return
	if e != null and e.kind == Entity.Kind.PLAYER and not e.flags.has("invisible"):
		_select_player(e)                # tap a player to pick them: Attack or Info buttons appear
		return
	_select_player(null)                 # tapping anything else clears the pick
	if e != null and e.role == "priest":
		_open_priest(e)                  # tap a priest for blessings, confession and the rest
		return
	if e != null and e.shop != null:
		_open_shop(e)                    # tap a merchant to buy, sell and have gear repaired
		return
	hero.target = null
	hero.recovering = false
	hero.loot_target = null
	hero.gather_tile = Vector2i(-1, -1)
	hero.crafting_trip = false
	var c := _corpse_near(dest)
	if c != null and e == null:
		if c.can_loot(hero):
			hero.start_looting(c)
		else:
			log_event("That corpse is not yours to loot.")
		return
	var tile := world.to_tile(dest)
	if e == null and world.resource_kind(tile) != "":
		hero.start_gathering(tile)      # tap a rock to mine it, a tree to chop it
		return
	hero.go_to(e.position if e != null else dest)


## Loot rising out of a corpse: an icon and a coloured "+..." label for each thing taken, one
## after another, drifting over to whoever took it. Only shown near the hero.
func show_loot(from_pos: Vector3, looter: Entity, got: Dictionary, what: String) -> void:
	if looter != null and looter.is_hero:
		for id in got["items"]:
			if Gear.is_artifact(String(id)):
				count("artifacts_found")
	if hero == null or from_pos.distance_to(hero.position) > 18.0:
		return
	var entries: Array = []
	if int(got["gold"]) > 0:
		entries.append(["gold", "+%d gold" % int(got["gold"])])
	if int(got["reagents"]) > 0:
		entries.append(["reagents", "+%d reagents" % int(got["reagents"])])
	var found: Dictionary = got["items"]
	for id in found:
		var n := int(found[id])
		entries.append([String(id), "+" + Items.item_name(id) + (" x%d" % n if n > 1 else "")])
	if not looter.is_hero and not entries.is_empty():
		var names: Array[String] = []
		for e in entries:
			names.append(String(e[1]).trim_prefix("+"))
		world_event("%s loots %s: %s" % [looter.display_name, what, ", ".join(names)])
	for i in range(entries.size()):
		var id := String(entries[i][0])
		var node := Node3D.new()
		add_child(node)
		node.position = from_pos + Vector3(0.0, 0.5, 0.0)
		node.scale = Vector3.ONE * 0.01
		var icon := MeshInstance3D.new()
		icon.mesh = Art.item_icon(id)
		icon.material_override = Art.vc_mat()
		icon.scale = Vector3.ONE * 1.6
		node.add_child(icon)
		var lab := Label3D.new()
		lab.text = String(entries[i][1])
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.pixel_size = 0.007
		lab.font_size = 40
		lab.outline_size = 12
		lab.modulate = Art.item_color(id)
		lab.position = Vector3(0.0, 0.45, 0.0)
		node.add_child(lab)
		var delay := 0.18 * i
		var rise := from_pos + Vector3(randf_range(-0.3, 0.3), 1.6 + 0.25 * i, randf_range(-0.3, 0.3))
		var tw := node.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(node, "scale", Vector3.ONE, 0.15)
		tw.tween_property(node, "position", rise, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(icon, "rotation:y", TAU, 1.2)
		tw.tween_interval(0.5)
		tw.tween_property(node, "position", looter.position + Vector3(0.0, 1.2, 0.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(lab, "modulate:a", 0.0, 0.35)
		tw.parallel().tween_property(node, "scale", Vector3.ONE * 0.3, 0.35)
		tw.tween_callback(node.queue_free)


func _corpse_near(p: Vector3) -> Corpse:
	var best: Corpse = null
	var best_d := 1.0
	for c in corpses:
		var d := c.position.distance_to(p)
		if d <= best_d:
			best = c
			best_d = d
	return best


## Whoever is drawn nearest to `screen` (their chest within `radius` pixels), up to 30 m away:
## easier than hitting their feet on the ground, especially in first person.
func _creature_at_screen(screen: Vector2, radius: float) -> Entity:
	var best: Entity = null
	var best_d := radius
	for e in creatures:
		if e == hero or e.dead or not e.visible or e.parked or e.flags.has("invisible"):
			continue
		if e.position.distance_to(hero.position) > 30.0:
			continue
		var p := e.position + Vector3(0.0, 1.0 * e.visual_scale, 0.0)
		if cam.is_position_behind(p):
			continue
		var d := cam.unproject_position(p).distance_to(screen)
		if d <= best_d:
			best = e
			best_d = d
	return best


func _creature_near(p: Vector3) -> Entity:
	var best: Entity = null
	var best_d := 1.0
	for e in creatures:
		if e == hero or e.dead:
			continue
		var d := e.position.distance_to(p)
		if d <= best_d:
			best = e
			best_d = d
	return best


func _toggle_auto() -> void:
	auto = not auto
	hero.ai_enabled = auto
	hero.pause = 0.0
	_update_button()


func _update_button() -> void:
	auto_button.text = "Auto: ON" if auto else "Auto: OFF"


# --- the corner menu and its switches ------------------------------------------------

## Makes the buttons and panels opaque (Godot's default ones are see-through). Applied to the
## engine's default theme, so it reaches every menu (a theme set on the window doesn't pass
## through the CanvasLayer the menus live on).
func _make_ui_solid(t: Theme) -> void:
	# Smoked glass: the world shows through the panels and buttons, dimmed enough to read on, with
	# a thin gold edge, rounded corners and a soft shadow. Text gets a dark outline so it stays
	# clear over anything.
	var gold := Color(0.78, 0.64, 0.34)
	var looks := {
		"normal": Color(0.10, 0.12, 0.17, 0.62), "hover": Color(0.18, 0.22, 0.30, 0.72),
		"pressed": Color(0.42, 0.34, 0.16, 0.85), "disabled": Color(0.08, 0.08, 0.10, 0.40),
		"focus": Color(0.10, 0.12, 0.17, 0.0),
	}
	for state: String in looks:
		var sb := StyleBoxFlat.new()
		sb.bg_color = looks[state]
		sb.border_color = gold if state in ["hover", "pressed"] else Color(gold, 0.55 if state != "disabled" else 0.2)
		sb.set_border_width_all(1)
		sb.border_width_bottom = 3                      # a heavier lower edge: the button stands up a little
		sb.set_corner_radius_all(10)
		sb.content_margin_left = 14.0
		sb.content_margin_right = 14.0
		sb.content_margin_top = 8.0
		sb.content_margin_bottom = 8.0
		if state == "pressed":
			sb.border_width_bottom = 1                  # ...and sinks when pressed
			sb.content_margin_top = 10.0
		if state == "focus":
			sb.draw_center = false                      # just the edge over the normal look
		t.set_stylebox(state, "Button", sb)
	t.set_color("font_color", "Button", Color(0.96, 0.93, 0.84))
	t.set_color("font_hover_color", "Button", Color(1.0, 0.95, 0.8))
	t.set_color("font_pressed_color", "Button", Color(1.0, 0.92, 0.6))
	t.set_color("font_disabled_color", "Button", Color(0.6, 0.6, 0.6, 0.7))
	t.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.9))
	t.set_constant("outline_size", "Button", 4)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.9))
	t.set_constant("outline_size", "Label", 4)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.05, 0.06, 0.09, 0.66)
	panel.border_color = gold
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(16)
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 14
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	# a slim gold scroll bar
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.06)
	track.set_corner_radius_all(6)
	track.content_margin_left = 5.0
	track.content_margin_right = 5.0
	t.set_stylebox("scroll", "VScrollBar", track)
	for gs: Array in [["grabber", 0.55], ["grabber_highlight", 0.8], ["grabber_pressed", 1.0]]:
		var gb := StyleBoxFlat.new()
		gb.bg_color = Color(gold, float(gs[1]))
		gb.set_corner_radius_all(6)
		t.set_stylebox(String(gs[0]), "VScrollBar", gb)


## Presses a panel's own Back / Close button (wherever its list has put it), so the X in the
## corner and a tap outside the panel close it the way that button would.
func _press_back(box: Node) -> void:
	var kids := box.get_children()
	for i in range(kids.size() - 1, -1, -1):
		var b := kids[i] as Button
		if b != null and not b.disabled and b.text in ["Back", "Close", "Continue", "Resume"]:
			b.pressed.emit()
			return


## Behind an open panel the game is dimmed a little, and a tap there closes the panel.
func _dress_overlay(overlay: Control, box: Node) -> void:
	overlay.draw.connect(func() -> void:
		overlay.draw_rect(Rect2(Vector2.ZERO, overlay.size), Color(0.0, 0.01, 0.03, 0.3)))
	overlay.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed \
				and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_press_back(box))


const BUTTON_ICONS := {"Main Menu": "scroll", "Bag": "chest", "Spells": "magic", "Retreat": "alert", "Ride": "travel",
	"Bow": "weapon", "Statistics": "star"}


func _corner_add(b: Button) -> void:
	b.custom_minimum_size = Vector2(200, 58)
	b.add_theme_font_size_override("font_size", 22)
	if BUTTON_ICONS.has(b.text):                       # a little picture beside the word
		b.icon = Icons.tex(String(BUTTON_ICONS[b.text]))
		b.expand_icon = false
		b.add_theme_constant_override("icon_max_width", 28)
	corner_grid.add_child(b)


func _toggle_corner() -> void:
	corner_grid.visible = not corner_grid.visible
	corner_toggle.text = "Close" if corner_grid.visible else "Menu"


func _update_corner_buttons() -> void:
	var muted := not property.sound_on and not property.music_on
	mute_button.text = "Unmute" if muted else "Mute"
	names_button.text = "Hide names" if property.names_on else "Show names"
	stats_button.text = "Hide stats" if property.stats_on else "Show stats"
	map_button.text = "Hide map" if property.minimap_on else "Show map"
	view_button.text = "Top view" if property.first_person else "First person"
	corpse_button.text = "Hide corpse names" if property.corpse_names_on else "Show corpse names"
	magic_button.text = "Hide magic" if property.magic_label_on else "Show magic"
	_apply_view()
	hud.visible = property.stats_on
	minimap.visible = property.minimap_on


## Mute silences both music and sound effects; Unmute turns both back on.
func _toggle_mute() -> void:
	var on := not property.sound_on and not property.music_on
	property.sound_on = on
	property.music_on = on
	music.set_enabled(on)
	_update_corner_buttons()


## Names (and health) over everyone's heads: off by default.
func _toggle_names() -> void:
	property.names_on = not property.names_on
	for e in creatures:
		e.show_name(property.names_on)
	_update_corner_buttons()


## Magery, mana, spell power and the spell being cast over the hero's head.
func _toggle_magic_label() -> void:
	property.magic_label_on = not property.magic_label_on
	hero.show_name(property.names_on)                 # refreshes the label at once
	_update_corner_buttons()


## The labels over corpses and chests (whose they are and what's inside).
func _toggle_corpse_names() -> void:
	property.corpse_names_on = not property.corpse_names_on
	for c in corpses:
		c.label.visible = property.corpse_names_on
	_update_corner_buttons()


func _toggle_stats() -> void:
	property.stats_on = not property.stats_on
	_update_corner_buttons()


func _toggle_map() -> void:
	property.minimap_on = not property.minimap_on
	_update_corner_buttons()


# --- frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	if paused and movie != null and movie.running:
		paused = false                            # nothing stops the movie (its interface is hidden: a panel would freeze it)
	if paused:
		_update_hud()
		if frontier != null:
			frontier.act_button.visible = false   # no action button over a menu or panel
			frontier.while_paused()
		return
	if title_up:
		# The title and the opening fly-by: the world holds still - nobody moves, fights or ticks -
		# until the camera is down and a mode is chosen. Only the camera flies.
		if frontier != null:
			frontier.act_button.visible = false
		_flyby_step(delta)
		_cull_fx(delta)
		return
	if autotest:
		_autotest_tick(delta)
	_update_retreat_button()
	if not _tips_left.is_empty():
		_tip_timer -= delta
		if _tip_timer <= 0.0:
			_tip_timer = 15.0
			log_event(String(_tips_left.pop_front()))
	_campfire_tick(delta)
	_fields_tick(delta)
	_weather_tick(delta)
	_music_tick(delta)
	guilds.tick(delta)
	save_timer += delta
	if save_timer >= 20.0:
		save_timer = 0.0
		_autosave()
	# Everyone on screen (and the hero, and whoever is after the hero) lives every frame; the rest
	# of the world every fourth frame, a quarter of them at a time, with the time they missed.
	_tick_n += 1
	for i in range(creatures.size()):
		var e := creatures[i]
		if e._near or e.is_hero or e.parked or e.target == hero:
			e.tick(delta + e.tick_debt)
			e.tick_debt = 0.0
		elif movie != null:
			pass                                  # the movie: the world off camera holds still (nothing of it is kept)
		else:
			e.tick_debt += delta
			# off screen: every fourth frame; far away (more than 50 m from you) every eighth
			var every := 8 if e.position.distance_squared_to(hero.position) > 2500.0 else 4
			if (i + _tick_n) % every == 0:
				e.tick(e.tick_debt)
				e.tick_debt = 0.0
		if e.shop != null:
			e.shop.tick(delta)
	_flush_spawns()
	_separate_bodies()
	frontier.tick(delta)
	_vendor_tick(delta)
	_gates_tick(delta)
	day_time = fmod(day_time + delta / DAY_SECONDS * (4.0 if Experiments.on("fast_time") else 1.0), 1.0)
	_apply_daylight()
	_quest_tick()
	if property.has_house() and _someone_minds_house():
		property.refresh()             # the owner or a co-owner nearby keeps it from decaying
	for c in corpses.duplicate():
		c.tick(delta)
		if c.life <= 0.0:
			corpses.erase(c)
			c.queue_free()
	if hero.dead or hero.path.is_empty():
		marker.visible = false
	else:
		marker.visible = true
		marker.position = hero.path[hero.path.size() - 1] + Vector3(0.0, 0.03, 0.0)
	if movie != null and movie.tick(delta):
		pass                                      # the showcase movie has the camera
	elif _cine_step(delta):
		pass                                      # a story scene has the camera
	elif not _flyby_step(delta):
		_follow_camera()
	_update_rings()
	_cull_fx(delta)
	_adapt_resolution(delta)
	_story_tick(delta)
	_events_tick(delta)
	_world_life(delta)
	_ambience_tick(delta)
	_achieve_acc += delta
	if _achieve_acc >= 2.0:
		_achieve_acc = 0.0
		_check_achievements()
	property.play_time += delta
	_hud_timer -= delta
	if _hud_timer <= 0.0:
		_hud_timer = 0.2                     # the HUD text five times a second
		_update_hud()
		_update_select_bar()
		_update_ghost_view()


var _hud_timer := 0.0
var _tick_n := 0


## The frame counter: top middle, over everything (the movie too), green at 55+, yellow, red under 40,
## with the 3D resolution the frame-rate keeper has settled on.
var _fps_label: Label


func _build_fps_counter() -> void:
	var top := CanvasLayer.new()
	top.layer = 100
	add_child(top)
	_fps_label = Label.new()
	_fps_label.add_theme_font_size_override("font_size", 22)
	_fps_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps_label.add_theme_constant_override("outline_size", 8)
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_fps_label)
	_fps_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_fps_label.offset_left = -110.0
	_fps_label.offset_right = 110.0
	_fps_label.offset_top = 6.0
	var t := Timer.new()
	t.wait_time = 0.5
	t.autostart = true
	t.timeout.connect(_update_fps_counter)
	add_child(t)


func _update_fps_counter() -> void:
	var fps := Engine.get_frames_per_second()
	_fps_label.text = "%d FPS  ·  %d%%" % [fps, roundi(_render_scale * 100.0)] + ("  ·  -%d" % _q if _q > 0 else "")
	_fps_label.add_theme_color_override("font_color",
		Color(0.45, 1.0, 0.45) if fps >= 55 else (Color(1.0, 0.85, 0.3) if fps >= 40 else Color(1.0, 0.4, 0.35)))


## Bodies don't pass through each other: any two that overlap are eased apart (each by half the
## overlap, the bigger moving less), never into a wall. Ghosts, riders' parked mounts and a hero
## out in a boat are left alone. A grid of one-metre cells keeps it to near neighbours.
func _separate_bodies() -> void:
	var cells := {}
	var list: Array[Entity] = []
	for e in creatures:
		if e.dead or e.ghost or e.parked or (e.is_hero and frontier != null and not frontier.sail.is_empty()):
			continue
		if not e._near and not e.is_hero:
			continue                              # off screen nobody sees them overlap: only those in view
		var key := Vector2i(floori(e.position.x), floori(e.position.z))
		if not cells.has(key):
			cells[key] = []
		(cells[key] as Array).append(e)
		list.append(e)
	for e in list:
		var ra := 0.28 * maxf(e.visual_scale, 0.5)
		var key := Vector2i(floori(e.position.x), floori(e.position.z))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var bucket: Variant = cells.get(key + Vector2i(dx, dy))
				if bucket == null:
					continue
				for o in bucket:
					var b := o as Entity
					if b == e or b.get_instance_id() < e.get_instance_id():
						continue                  # each pair once
					var rb := 0.28 * maxf(b.visual_scale, 0.5)
					var d := Vector2(b.position.x - e.position.x, b.position.z - e.position.z)
					var dist := d.length()
					var overlap := ra + rb - dist
					if overlap <= 0.0:
						continue
					var n := d / dist if dist > 0.001 else Vector2(1, 0).rotated(randf() * TAU)
					var share := rb / (ra + rb)       # the smaller one gives way more
					_nudge(e, -n * overlap * share)
					_nudge(b, n * overlap * (1.0 - share))


func _nudge(e: Entity, v: Vector2) -> void:
	var to := e.position + Vector3(v.x, 0.0, v.y)
	if not world.is_blocked(world.to_tile(to)):
		e.position.x = to.x
		e.position.z = to.z


func _update_hud() -> void:
	var s := hero.stats
	var tile := world.to_tile(hero.position)
	var bag: Array[String] = []
	for id in hero.inventory:
		bag.append("%s x%d" % [Items.item_name(id), int(hero.inventory[id])])
	if bag.size() > 6:
		var extra := bag.size() - 6
		bag.resize(6)
		bag.append("+%d more" % extra)
	var bag_text := ", ".join(bag) if not bag.is_empty() else "empty"
	hud.text = "Shardsight v%s   %s   [%s]   %s   %s\nLevel %d   Fame %d  Karma %d   HP %d/%d%s   Stam %d/%d   Mana %d/%d   Reagents %d   Bandages %d   Gold %d\nStr %d  Dex %d  Int %d  (%d/%d)   Skills %.1f/%d (Menu > Skills)   Tile %d,%d\n%s\nBag: %s\n%s" % [
		version, hero.title_name() + ((" [%s]" % hero.guild_abbr()) if hero.guild_abbr() != "" else ""),
		hero.state_text(), hero.notoriety_text(), _clock_text(), hero.stats.level(), hero.fame, hero.karma, ceili(hero.hp), s.max_hp(), _poison_text() + _bless_text(), int(hero.stamina), s.max_stamina(),
		floori(hero.mana), s.max_mana(),
		floori(hero.reagents), hero.bandages, hero.gold,
		s.strength, s.dexterity, s.intelligence, s.stat_total(), Rules.STAT_CAP,
		s.skill_total(), Rules.SKILL_CAP_TOTAL, tile.x, tile.y, hero.gear_text() + _pets_text(), bag_text,
		_quest_text() + _boss_text() + (frontier.hud_text() if frontier != null else "")]


## factor > 1 zooms in.
func _zoom(factor: float) -> void:
	property.cam_zoom = clampf(property.cam_zoom / factor, 0.5, 1.8)


func _pinch() -> void:
	var keys := touches.keys()
	var p0: Vector2 = touches[keys[0]]
	var p1: Vector2 = touches[keys[1]]
	var dist := p0.distance_to(p1)
	var angle := (p1 - p0).angle()
	if _pinch_dist > 0.0 and dist > 1.0:
		_zoom(dist / _pinch_dist)
		property.cam_yaw -= wrapf(angle - _pinch_angle, -PI, PI)
	_pinch_dist = dist
	_pinch_angle = angle


## Sound effects near the hero (within 12 m), if sound is on.
# --- campfires (Camping) ----------------------------------------------------

const CAMPFIRE_SECONDS := 60.0
const CAMPFIRE_RANGE := 2.0
var campfires: Array = []          # [{"node": Node3D, "left": seconds}]


func light_campfire(at: Vector3) -> void:
	var fire := Node3D.new()
	var logs := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.25
	cyl.bottom_radius = 0.3
	cyl.height = 0.15
	logs.mesh = cyl
	logs.material_override = World._mat(Color(0.35, 0.22, 0.12))
	fire.add_child(logs)
	var flame := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.2
	cone.height = 0.45
	flame.mesh = cone
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(1.0, 0.55, 0.15)
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.5, 0.1)
	fm.emission_energy_multiplier = 2.0
	flame.material_override = fm
	flame.position.y = 0.3
	fire.add_child(flame)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.3)
	light.omni_range = 4.0
	light.position.y = 0.6
	fire.add_child(light)
	add_child(fire)
	fire.position = Vector3(at.x + 0.6, 0.0, at.z)
	flame.visible = false                          # real flames instead of the cone
	var flames := Fx.flame(0.35, 22, 0.8)
	flames.position.y = 0.15
	fire.add_child(flames)
	flames.add_to_group("view_fx")
	var smoke := Fx.smoke(6, 0.9)
	smoke.position.y = 0.8
	fire.add_child(smoke)
	smoke.add_to_group("view_fx")
	campfires.append({"node": fire, "left": CAMPFIRE_SECONDS})


func near_campfire(p: Vector3) -> bool:
	for c in campfires:
		var n: Node3D = c["node"]
		if Vector2(n.position.x - p.x, n.position.z - p.z).length() <= CAMPFIRE_RANGE:
			return true
	return false


# --- title screen --------------------------------------------------------------

## The opening card, drawn in code: the name in gold over the dark of the boot splash, a
## subtitle and the version. It fades after a few seconds, or at once on a tap.
func _show_title(layer: CanvasLayer) -> void:
	var card := ColorRect.new()
	card.color = Color(0.043, 0.055, 0.09, 0.15)   # see-through: the fly-by shows behind the title
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_flyby_fx(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var lines := [["SHARDSIGHT", 96, Color(0.85, 0.71, 0.29)],
		["a world of swords, spells and skill", 30, Color(0.72, 0.8, 0.92)],
		["v" + String(ProjectSettings.get_setting("application/config/version", "")), 22, Color(0.5, 0.55, 0.62)],
		["tap to skip", 24, Color(0.85, 0.85, 0.85)]]
	var hint: Label = null
	for l in lines:
		var lab := Label.new()
		lab.text = String(l[0])
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.add_theme_font_size_override("font_size", int(l[1]))
		lab.add_theme_color_override("font_color", l[2])
		lab.add_theme_color_override("font_outline_color", Color.BLACK)
		lab.add_theme_constant_override("outline_size", 10)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if box.get_child_count() == 0 and _fx_title_mat != null:
			lab.material = _fx_title_mat           # the name: a band of light sweeps across it
		box.add_child(lab)
		hint = lab                                 # the last line: "tap to skip"
		lab.modulate.a = 0.0                       # each line fades in after the one before
		var k := box.get_child_count() - 1
		var tw := lab.create_tween()
		tw.tween_interval(0.5 + 0.45 * k)
		tw.tween_property(lab, "modulate:a", 1.0, 0.9)
		if k == 0:                                 # the name: a slow golden shimmer
			var sh := lab.create_tween().set_loops()
			sh.tween_interval(1.4)
			sh.tween_property(lab, "modulate", Color(1.35, 1.25, 1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE)
			sh.tween_property(lab, "modulate", Color(1.0, 1.0, 1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE)
	if Experiments.active:
		var ex := Label.new()
		ex.text = "EXPERIMENTAL MODE"
		ex.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ex.add_theme_font_size_override("font_size", 26)
		ex.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
		ex.add_theme_color_override("font_outline_color", Color.BLACK)
		ex.add_theme_constant_override("outline_size", 10)
		ex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(ex)
	# The mode buttons wait, hidden, until the fly-by has come down to the hero.
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.visible = false
	row.modulate.a = 0.0
	box.add_child(row)
	var close := func() -> void:
		if not is_instance_valid(card) or card.get_meta("closing", false):
			return
		card.set_meta("closing", true)
		paused = false
		title_up = false                           # and now the world begins
		var tw := card.create_tween()
		tw.tween_property(card, "modulate:a", 0.0, 0.6)
		tw.tween_callback(card.queue_free)
	var play := _menu_button("Play", func() -> void:
		start_mode = "classic"                     # the ordinary game
		close.call())
	var tut := _menu_button("Tutorial", func() -> void:
		start_mode = "classic"                     # the ordinary game, with a guide for the first minutes
		close.call()
		if frontier != null:
			frontier.start_tutorial())
	var film := _menu_button("Movie", func() -> void:
		start_mode = "classic"
		close.call()
		movie = Movie.new()                        # the gameplay showcase (then back to this title)
		movie.start(self))
	var exp_b := _menu_button("Experimental mode", _switch_mode.bind("experimental"))
	exp_b.custom_minimum_size = Vector2(320, 80)
	row.add_child(play)
	row.add_child(tut)
	row.add_child(film)
	row.add_child(exp_b)
	# Once the camera is down: on a fresh start, the choice of mode (the game waits for it);
	# after switching modes the choice is already made, so the title simply fades.
	var flyby_done := func() -> void:
		if not is_instance_valid(card) or card.get_meta("closing", false) or row.visible:
			return
		_flyby_fx_end()
		if start_mode != "":
			close.call()
			return
		paused = true
		if hint != null:
			hint.text = "choose how to play"
		row.visible = true
		var tw := row.create_tween()
		tw.tween_property(row, "modulate:a", 1.0, 0.5)
		if "--movie-test" in OS.get_cmdline_user_args():
			film.pressed.emit()                    # (CI: play the movie by itself)
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if (ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed) or (ev is InputEventScreenTouch and (ev as InputEventScreenTouch).pressed):
			_skip_flyby())                         # a tap glides the camera down to the hero
	_title_close = flyby_done
	title_up = true
	_flyby_t = 0.0                                 # start the fly-by over the world
	_fov_rest = cam.fov
	get_tree().create_timer(FLYBY_SEG * FLYBY.size() + 3.0).timeout.connect(flyby_done)   # just in case


# --- the opening fly-by ------------------------------------------------------------

## Over the south-west forest, the main town, the dungeon, the eastern wilds, the graveyard and
## Southmoor, then down to the hero: [tile to fly over, height, tile to look at].
const FLYBY := [
	[Vector2i(8, 44), 20.0, Vector2i(18, 32)],
	[Vector2i(22, 20), 15.0, Vector2i(24, 9)],
	[Vector2i(42, 26), 13.0, Vector2i(43, 16)],
	[Vector2i(66, 20), 17.0, Vector2i(76, 10)],
	[Vector2i(82, 44), 15.0, Vector2i(88, 33)],
	[Vector2i(58, 46), 13.0, Vector2i(50, 34)],
]
const FLYBY_SEG := 2.2                 # seconds from one point to the next
const FLYBY_SKIP := 1.2                # seconds to glide down to the hero after a tap
var _flyby_t := -1.0                   # time into the fly-by; < 0 when not flying
var _skip_t := -1.0                    # time into the glide down after a tap
var _skip_from_pos := Vector3.ZERO
var _skip_from_look := Vector3.ZERO
var _cam_look := Vector3.ZERO          # where the camera looks during the fly-by
var _title_close: Callable
# the fly-by's effects
const FLYBY_PLACES := ["The Southern Woods", "The Town", "The Dungeon", "The Eastern Wilds", "Ravenhollow Cemetery", "Southmoor"]
const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float strength = 0.75;
void fragment() {
	vec2 d = (UV - vec2(0.5)) * vec2(1.25, 1.0);
	COLOR = vec4(0.0, 0.0, 0.03, smoothstep(0.32, 0.8, length(d)) * strength);
}
"""
var _fov_rest := 50.0
var _bank := 0.0                       # the camera leans into the turns
var _fx_heading := 0.0
var _fx_seg := -1
var _fx_bars: Array[ColorRect] = []
var _fx_caption: Label
var _fx_motes: CPUParticles3D
var _fx_done := false
var _fx_glare: ShaderMaterial
var _fx_title_mat: ShaderMaterial
## Over the fly-by: the sun's glare - a bloom round it, god rays streaming from it and lens ghosts
## strung across the picture - and a fine film grain.
const GLARE_SHADER := """
shader_type canvas_item;
uniform vec2 sun = vec2(0.5, 0.2);
uniform float strength = 0.0;
uniform float aspect = 1.78;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 d = (UV - sun) * vec2(aspect, 1.0);
	float r = length(d);
	float bloom = exp(-r * 6.0) * 0.9 + exp(-r * 18.0) * 0.8;
	float ang = atan(d.y, d.x);
	float rays = pow(abs(sin(ang * 9.0 + TIME * 0.15)) * abs(sin(ang * 5.0 - TIME * 0.1)), 6.0) * exp(-r * 2.4) * 0.55;
	vec3 col = vec3(1.0, 0.86, 0.6) * (bloom + rays);
	vec2 axis = vec2(0.5) - sun;                 // lens ghosts along the line through the middle
	for (int i = 1; i <= 4; i++) {
		vec2 gp = sun + axis * (0.55 * float(i));
		float gr = length((UV - gp) * vec2(aspect, 1.0));
		float size = 0.025 + 0.018 * float(i);
		float ring = smoothstep(size, size * 0.6, gr) * 0.22;
		col += mix(vec3(0.4, 0.7, 1.0), vec3(1.0, 0.5, 0.8), float(i) / 4.0) * ring;
	}
	col *= strength;
	float grain = (hash(UV * 900.0 + vec2(TIME * 37.0, TIME * 61.0)) - 0.5) * 0.06;
	COLOR = vec4(col + vec3(grain), clamp(max(max(col.r, col.g), col.b), 0.0, 1.0) * 0.85 + abs(grain));
}
"""
## A band of light sweeping slowly across the title's letters.
const SWEEP_SHADER := """
shader_type canvas_item;
void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float pos = fract(TIME * 0.22) * 1.8 - 0.4;
	float band = smoothstep(0.07, 0.0, abs(SCREEN_UV.x - pos - (SCREEN_UV.y - 0.4) * 0.3));
	c.rgb += vec3(1.0, 0.95, 0.8) * band * 0.85 * c.a;
	COLOR = c;
}
"""


## The fly-by as a film: it fades in from black, black bars frame the picture, the corners are
## darkened, golden motes drift in the air ahead, the camera leans into its turns with a wider
## lens, and each place it passes is named in the corner.
func _build_flyby_fx(card: Control) -> void:
	var vig := ColorRect.new()
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	var vm := ShaderMaterial.new()
	vm.shader = sh
	vig.material = vm
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vig)
	vig.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var h := get_viewport().get_visible_rect().size.y
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(bar)
		bar.set_anchors_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.offset_left = 0.0
		bar.offset_right = 0.0
		bar.offset_top = 0.0 if top else -h * 0.11
		bar.offset_bottom = h * 0.11 if top else 0.0
		_fx_bars.append(bar)
	_fx_caption = Label.new()
	_fx_caption.add_theme_font_size_override("font_size", 34)
	_fx_caption.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	_fx_caption.add_theme_color_override("font_outline_color", Color.BLACK)
	_fx_caption.add_theme_constant_override("outline_size", 10)
	_fx_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx_caption.modulate.a = 0.0
	card.add_child(_fx_caption)
	_fx_caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 40)
	_fx_caption.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_fx_caption.offset_top -= h * 0.11
	_fx_caption.offset_bottom -= h * 0.11
	var black := ColorRect.new()                   # fades in from black
	black.color = Color.BLACK
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(black)
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tw := black.create_tween()
	tw.tween_property(black, "modulate:a", 0.0, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(black.queue_free)
	var glare := ColorRect.new()                   # the sun's glare, rays, lens ghosts, grain
	var gsh := Shader.new()
	gsh.code = GLARE_SHADER
	_fx_glare = ShaderMaterial.new()
	_fx_glare.shader = gsh
	glare.material = _fx_glare
	glare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(glare)
	card.move_child(glare, 0)
	glare.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ssh := Shader.new()
	ssh.code = SWEEP_SHADER
	_fx_title_mat = ShaderMaterial.new()
	_fx_title_mat.shader = ssh
	_fx_motes = CPUParticles3D.new()
	_fx_motes.amount = 70
	_fx_motes.lifetime = 4.0
	_fx_motes.preprocess = 2.0
	_fx_motes.mesh = Fx._quad(0.12, Color(1.0, 0.85, 0.5))
	_fx_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_fx_motes.emission_box_extents = Vector3(7, 3, 7)
	_fx_motes.direction = Vector3(0, 1, 0)
	_fx_motes.spread = 60.0
	_fx_motes.gravity = Vector3(0, 0.08, 0)
	_fx_motes.initial_velocity_min = 0.1
	_fx_motes.initial_velocity_max = 0.4
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(1, 0.85, 0.5, 0.0), Color(1, 0.85, 0.5, 0.9), Color(1, 0.9, 0.6, 0.7), Color(1, 0.9, 0.6, 0.0)])
	_fx_motes.color_ramp = ramp
	add_child(_fx_motes)


func _flyby_fx_step(delta: float, pos: Vector3, look: Vector3) -> void:
	if _fx_done:
		return
	# a wider lens high above, narrowing to the usual as it comes down to the hero
	var t_all := FLYBY_SEG * (FLYBY.size() + 1)     # the places, then down to the hero
	var k := clampf(_flyby_t / t_all, 0.0, 1.0)
	if _skip_t >= 0.0:
		k = maxf(k, smoothstep(0.0, 1.0, minf(_skip_t / FLYBY_SKIP, 1.0)))
	cam.fov = lerpf(62.0, _fov_rest, smoothstep(0.75, 1.0, k))
	# lean into the turns
	var dir := Vector2(look.x - pos.x, look.z - pos.z)
	if dir.length() > 0.01 and delta > 0.0:
		var hd := atan2(dir.x, dir.y)
		var turn := wrapf(hd - _fx_heading, -PI, PI) / delta
		_fx_heading = hd
		_bank = lerpf(_bank, clampf(turn * 0.12, -0.14, 0.14), minf(1.0, 2.0 * delta))
	_bank *= 1.0 - smoothstep(0.8, 1.0, k)          # level again as it comes down
	cam.rotate_object_local(Vector3(0, 0, 1), _bank)
	# a hand-held drift: the camera breathes a little as it flies
	var tt := _flyby_t + _skip_t
	cam.position += Vector3(sin(tt * 1.3) * 0.06, sin(tt * 0.9) * 0.05, cos(tt * 1.1) * 0.06) * (1.0 - smoothstep(0.85, 1.0, k))
	# where the sun is on the screen, and how much of its glare to show
	if _fx_glare != null and sun != null:
		var sp := cam.global_position + sun.global_transform.basis.z * 500.0
		var vs := get_viewport().get_visible_rect().size
		var strength := 0.0
		if not cam.is_position_behind(sp):
			var uv := cam.unproject_position(sp) / vs
			_fx_glare.set_shader_parameter("sun", uv)
			var inside := 1.0 - smoothstep(0.55, 1.1, (uv - Vector2(0.5, 0.5)).length())
			strength = inside * clampf(sun.light_energy - 0.5, 0.0, 1.0) * (1.0 if weather == "clear" else 0.3)
		_fx_glare.set_shader_parameter("strength", strength * (1.0 - smoothstep(0.85, 1.0, k)))
		_fx_glare.set_shader_parameter("aspect", vs.x / maxf(vs.y, 1.0))
	if _fx_motes != null:
		_fx_motes.position = pos.lerp(look, 0.35)
	# name each place as the camera reaches it
	var seg := floori(_flyby_t / FLYBY_SEG) if _skip_t < 0.0 else 99
	if seg != _fx_seg:
		_fx_seg = seg
		var tw := _fx_caption.create_tween()
		tw.tween_property(_fx_caption, "modulate:a", 0.0, 0.3)
		if seg >= 0 and seg < FLYBY_PLACES.size():
			tw.tween_callback(func() -> void: _fx_caption.text = String(FLYBY_PLACES[seg]))
			tw.tween_property(_fx_caption, "modulate:a", 1.0, 0.6)


## The camera lands by the hero: a ring of golden light runs out over the ground, sparks fly up,
## a chime.
func _arrival_burst() -> void:
	if hero == null:
		return
	var ring := Art.ground_ring(Color(1.0, 0.85, 0.45, 0.9), 0.6)
	add_child(ring)
	ring.position = hero.position + Vector3(0, 0.05, 0)
	var tw := ring.create_tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * 9.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ring, "transparency", 1.0, 1.4)
	tw.chain().tween_callback(ring.queue_free)
	Fx.sparkle(self, hero.position + Vector3(0, 0.6, 0), Color(1.0, 0.85, 0.45), 40)
	if property.sound_on:
		sfx.play("gain", 0.8)


## The film ends: the bars slide away, the motes settle, the lens and the horizon come back.
func _flyby_fx_end() -> void:
	if _fx_done:
		return
	_fx_done = true
	cam.fov = _fov_rest
	_bank = 0.0
	for i in range(_fx_bars.size()):
		var bar := _fx_bars[i]
		if is_instance_valid(bar):                 # the top bar slides up, the bottom one down
			bar.create_tween().tween_property(bar, "offset_bottom" if i == 0 else "offset_top", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	if is_instance_valid(_fx_caption):
		_fx_caption.create_tween().tween_property(_fx_caption, "modulate:a", 0.0, 0.4)
	_arrival_burst()
	if _fx_motes != null:
		_fx_motes.emitting = false
		get_tree().create_timer(4.5).timeout.connect(_fx_motes.queue_free)
		_fx_motes = null


func _hero_cam_pos() -> Vector3:
	if property.first_person:
		return _eye()
	return hero.position + CAM_OFFSET.rotated(Vector3.UP, property.cam_yaw) * property.cam_zoom


func _hero_cam_look() -> Vector3:
	if property.first_person:
		return _eye() + _fp_dir() * 4.0
	return hero.position + Vector3(0.0, 0.5, 0.0)


# --- first person ----------------------------------------------------------------

var _fp_yaw := 0.0                     # where the first-person view faces (eases after the hero)
var _fp_pitch := -0.17                 # up (+) or down (-), in radians
var _fp_free_until := 0.0              # after you look round by hand, the view stays put a while
var _press_pos := Vector2.ZERO
var _dragging := false
var _bob_t := 0.0
var _bob := 0.0
var aimed: Entity                      # whoever is under the crosshair (first person)
var _aim_acc := 0.0
var fp_overlay: FpOverlay
var _viewmodel: Node3D
var _vm_mesh: MeshInstance3D
var _vm_weapon := "#"


func _fp_forward() -> Vector3:
	return Vector3(-sin(_fp_yaw), 0.0, -cos(_fp_yaw))


func _fp_dir() -> Vector3:
	var f := _fp_forward()
	return Vector3(f.x * cos(_fp_pitch), sin(_fp_pitch), f.z * cos(_fp_pitch))


## Everything first person needs each frame: the view eases round to where the hero walks
## (unless you've looked round by hand lately), a gentle bob as you walk, what's under the
## crosshair, the overlay and the weapon in your hand.
func _fp_step(delta: float) -> void:
	var fp := property.first_person and _flyby_t < 0.0
	if fp_overlay != null:
		fp_overlay.visible = fp and not hero.dead
		if fp_overlay.visible:
			fp_overlay.queue_redraw()
	if not fp:
		aimed = null
		if _viewmodel != null:
			_viewmodel.visible = false
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not _dragging and now > _fp_free_until:
		_fp_yaw = lerp_angle(_fp_yaw, hero.rotation.y, minf(1.0, 5.0 * delta))
	var walking := not hero.path.is_empty() and not hero.dead
	_bob_t += delta * (1.0 if walking else 0.0)
	_bob = lerpf(_bob, sin(_bob_t * 9.0) * 0.035 if walking else 0.0, minf(1.0, 10.0 * delta))
	_aim_acc -= delta
	if _aim_acc <= 0.0:                     # who's in the sights, ten times a second
		_aim_acc = 0.1
		aimed = _creature_at_screen(get_viewport().get_visible_rect().size / 2.0, 60.0)
	_update_viewmodel(delta, walking)


## Your weapon (and hand) at the lower right: swung when you strike, raised as you cast,
## bobbing as you walk.
func _update_viewmodel(_delta: float, walking: bool) -> void:
	if _viewmodel == null:
		_viewmodel = Node3D.new()
		cam.add_child(_viewmodel)
		_vm_mesh = MeshInstance3D.new()
		_vm_mesh.material_override = Art.vc_mat()
		_vm_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_viewmodel.add_child(_vm_mesh)
		_viewmodel.scale = Vector3.ONE * 0.8
	_viewmodel.visible = not hero.dead
	if hero.weapon != _vm_weapon:
		_vm_weapon = hero.weapon
		var parts := [[Art.box(0.11, 0.34, 0.13), Art.at(0, -0.3, 0), Color(0.34, 0.28, 0.22)],
			[Art.ball(0.065, 6, 3), Art.at(0, -0.51, 0), Art.pick(Art.SKINS, hero.display_name)]]
		parts.append_array(Art._weapon_parts(_vm_weapon))
		_vm_mesh.mesh = Art.merge(parts)
	var k := 0.0
	if hero.swing_anim > 0.0:
		k = sin(hero.swing_anim / Entity.SWING_ANIM * PI)
	var cast_lift := 0.25 + 0.05 * sin(Time.get_ticks_msec() * 0.008) if hero.casting_id != "" else 0.0
	_viewmodel.position = Vector3(0.34, -0.2 + _bob * 0.5 + cast_lift * 0.3, -0.05 - 0.12 * k)
	_viewmodel.rotation = Vector3(1.25 + 0.9 * k - cast_lift, 0.15, 0.1)


## The hero's eyes (higher in the saddle), a touch ahead of the head so it doesn't show.
func _eye() -> Vector3:
	var h := 1.55 * hero.visual_scale + _bob
	if hero.mounted_on != null:
		h += hero.mounted_on.saddle * hero.mounted_on.visual_scale
	return hero.position + Vector3(0.0, h, 0.0) + _fp_forward() * 0.2


func _toggle_view() -> void:
	property.first_person = not property.first_person
	_update_corner_buttons()


## Applies the camera mode: a wider lens and the hero's own model hidden in first person.
func _apply_view() -> void:
	var fp := property.first_person
	if fp:
		_fp_yaw = hero.rotation.y                        # start facing where the hero faces
		_fp_pitch = -0.17
	else:
		_fp_step(0.0)                                     # hides the crosshair and the weapon
	cam.fov = 75.0 if fp else 50.0
	cam.far = 80.0 if fp else VIEW_FAR
	hero.hide_self = fp
	if hero.rig != null:
		hero.rig.visible = not fp
	hero.show_name(property.names_on)
	if hero_ring != null:
		hero_ring.visible = not fp


func _skip_flyby() -> void:
	if _flyby_t < 0.0 or _skip_t >= 0.0:
		return
	_skip_t = 0.0
	_skip_from_pos = cam.position
	_skip_from_look = _cam_look


## Moves the camera along the fly-by; returns false once it's over (then the camera follows
## the hero as usual).
func _flyby_step(delta: float) -> bool:
	if _flyby_t < 0.0:
		return false
	var pos: Vector3
	var look: Vector3
	if _skip_t >= 0.0:
		_skip_t += delta
		var k := smoothstep(0.0, 1.0, minf(_skip_t / FLYBY_SKIP, 1.0))
		pos = _skip_from_pos.lerp(_hero_cam_pos(), k)
		look = _skip_from_look.lerp(_hero_cam_look(), k)
		if _skip_t >= FLYBY_SKIP:
			_end_flyby()
			return false
	else:
		_flyby_t += delta
		var ps: Array[Vector3] = []
		var ls: Array[Vector3] = []
		for f in FLYBY:
			ps.append(world.tile_center(f[0]) + Vector3(0.0, float(f[1]), 0.0))
			ls.append(world.tile_center(f[2]))
		ps.append(_hero_cam_pos())             # the last stop: the usual view of the hero
		ls.append(_hero_cam_look())
		var u := _flyby_t / FLYBY_SEG
		var i := mini(floori(u), ps.size() - 2)
		var w := clampf(u - i, 0.0, 1.0)
		w = w * w * (3.0 - 2.0 * w) if i == ps.size() - 2 else w   # ease into the hero
		var a := maxi(i - 1, 0)
		var d := mini(i + 2, ps.size() - 1)
		pos = ps[i].cubic_interpolate(ps[i + 1], ps[a], ps[d], w)
		look = ls[i].cubic_interpolate(ls[i + 1], ls[a], ls[d], w)
		if u >= ps.size() - 1:
			_end_flyby()
			return false
	_cam_look = look
	cam.position = pos
	cam.look_at(look, Vector3.UP)
	_flyby_fx_step(delta, pos, look)
	view_planes = cam.get_frustum()
	return true


func _end_flyby() -> void:
	_flyby_t = -1.0
	_skip_t = -1.0
	_flyby_fx_end()
	if _title_close.is_valid():
		_title_close.call()


# --- resurrection shrines: glowing ankhs all over the map --------------------------

var shrines: Array[Vector3] = []
var _ankhs: Array[MeshInstance3D] = []


## One ankh shrine in each of the map's 8 regions, near its middle, where a ghost is raised.
func _build_shrines() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150                          # the same spots every game
	var stone := Color(0.55, 0.55, 0.58)
	var gold := Color(0.95, 0.88, 0.62)
	var base_mesh := Art.merge([[Art.box(0.9, 0.16, 0.9), Art.at(0, 0.08, 0), stone],
		[Art.box(0.6, 0.12, 0.6), Art.at(0, 0.22, 0), stone.lightened(0.1)]])
	var ankh_mesh := Art.merge([[Art.box(0.12, 0.85, 0.12), Art.at(0, 0.7, 0), gold],
		[Art.box(0.56, 0.1, 0.1), Art.at(0, 0.92, 0), gold],
		[Art.ring_mesh(0.11, 0.17), Art.at(0, 1.22, 0, Vector3(PI / 2, 0, 0)), gold]])
	for i in range(world.zone_count()):
		if (i % World.ZONE_COLS) % 2 != 0 or (i / World.ZONE_COLS) % 2 != 0:
			continue                             # one region in four: an ankh never too far, never crowding
		var r := world.zone_rect(i)
		var mid := Rect2i(r.position + r.size / 4, r.size / 2)
		var t := world.open_tile_in(mid, rng)
		var at := world.tile_center(t)
		shrines.append(at)
		var node := Node3D.new()
		add_child(node)
		node.position = at
		var b := MeshInstance3D.new()
		b.mesh = base_mesh
		b.material_override = Art.vc_mat()
		node.add_child(b)
		var a := MeshInstance3D.new()
		a.mesh = ankh_mesh
		a.material_override = Art.glow_mat(Color(0.95, 0.9, 0.7))
		node.add_child(a)
		_ankhs.append(a)
		var l := OmniLight3D.new()
		l.light_color = Color(0.7, 0.85, 1.0)
		l.light_energy = 1.0
		l.omni_range = 4.0
		l.position = Vector3(0.0, 1.3, 0.0)
		node.add_child(l)
		var motes := Fx.cast_glow(Color(0.7, 0.88, 1.0))
		motes.amount = 10
		motes.lifetime = 1.4
		motes.position = Vector3(0.0, 0.25, 0.0)
		node.add_child(motes)
		motes.emitting = true
		motes.add_to_group("view_fx")


## The nearest place `e` can be raised: an ankh shrine, or (for innocents) a healer or priest.
## {"pos": Vector3, "name": String, "healer": Entity or null}, or {} if none.
func nearest_resurrection(e: Entity) -> Dictionary:
	var best := {}
	var best_d := INF
	var isle := world.on_island(world.to_tile(e.position))     # the sea can't be walked: stay on your shore
	for p in shrines:
		if world.on_island(world.to_tile(p)) != isle:
			continue
		var d := e.position.distance_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p, "name": "Ankh shrine", "healer": null}
	if not e.died_red and e.notoriety() == Entity.Notoriety.BLUE:
		for c in creatures:
			if (c.role == "healer" or c.role == "priest") and not c.dead and world.on_island(world.to_tile(c.position)) == isle:
				var d := e.position.distance_to(c.position)
				if d < best_d:
					best_d = d
					best = {"pos": c.position, "name": c.display_name, "healer": c}
	return best


# --- the ghost's view: a grey world and where to go ------------------------------

const GHOST_SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	float g = dot(c, vec3(0.3, 0.59, 0.11));
	COLOR = vec4(mix(c, vec3(g) * vec3(0.85, 0.92, 1.08), 0.8), 1.0);
}
"""
var ghost_overlay: ColorRect
var ghost_hint: Label


func _build_ghost_view(layer: CanvasLayer) -> void:
	var gl := CanvasLayer.new()
	gl.layer = 0                              # over the world, under the buttons and text
	add_child(gl)
	ghost_overlay = ColorRect.new()
	ghost_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = GHOST_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	ghost_overlay.material = mat
	ghost_overlay.visible = false
	gl.add_child(ghost_overlay)
	ghost_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ghost_hint = Label.new()
	ghost_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ghost_hint.add_theme_font_size_override("font_size", 26)
	ghost_hint.add_theme_color_override("font_color", Color(0.75, 0.88, 1.0))
	ghost_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	ghost_hint.add_theme_constant_override("outline_size", 10)
	ghost_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost_hint.visible = false
	layer.add_child(ghost_hint)
	ghost_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 90)
	ghost_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH


static func _compass(v: Vector3) -> String:
	var names := ["north", "north-east", "east", "south-east", "south", "south-west", "west", "north-west"]
	var a := atan2(v.x, -v.z)                    # north is -z on the map
	return names[posmod(roundi(a / (PI / 4.0)), 8)]


func _update_ghost_view() -> void:
	if ghost_overlay == null:
		return
	var g := hero.dead and hero.ghost
	ghost_overlay.visible = g
	ghost_hint.visible = g
	if not g:
		return
	var spot := nearest_resurrection(hero)
	if spot.is_empty():
		ghost_hint.text = "You are a ghost."
		return
	var v: Vector3 = spot["pos"] - hero.position
	ghost_hint.text = "You are a ghost. Find a resurrection spot.\nNearest: %s, %d m %s%s" % [
		spot["name"], roundi(v.length()), _compass(v),
		"  (Auto is walking you there)" if auto else "  (tap the ground to walk)"]


# --- braziers: fire in the towns, glowing at night ----------------------------

const BRAZIERS := [Vector2i(19, 10), Vector2i(29, 10), Vector2i(19, 13), Vector2i(29, 13),
	Vector2i(34, 3), Vector2i(41, 7), Vector2i(44, 30), Vector2i(55, 30), Vector2i(44, 38), Vector2i(55, 38)]
var brazier_lights: Array[OmniLight3D] = []


func _build_braziers() -> void:
	var stone := Color(0.42, 0.4, 0.38)
	var bowl := Art.merge([[Art.cone(0.12, 0.7, 0.09, 6), Art.at(0, 0.35, 0), stone],
		[Art.cone(0.26, 0.18, 0.16, 8), Art.at(0, 0.78, 0), Color(0.3, 0.27, 0.25)],
		[Art.cone(0.2, 0.06, 0.2, 8), Art.at(0, 0.02, 0), stone.darkened(0.2)]])
	for t in BRAZIERS:
		var b := Node3D.new()
		add_child(b)
		b.position = world.tile_center(t) + Vector3(0.3, 0.0, 0.3)
		var m := MeshInstance3D.new()
		m.mesh = bowl
		m.material_override = Art.vc_mat()
		b.add_child(m)
		var f := Fx.flame(0.3, 16, 0.8)
		f.position.y = 0.88
		b.add_child(f)
		f.add_to_group("view_fx")
		var smoke := Fx.smoke(5, 0.8)
		smoke.position.y = 1.3
		b.add_child(smoke)
		smoke.add_to_group("view_fx")
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.62, 0.3)
		l.omni_range = 5.0
		l.light_energy = 0.0
		l.position.y = 1.2
		b.add_child(l)
		brazier_lights.append(l)


# --- weather and music -------------------------------------------------------

## Rain: streaks falling round the camera (a CPU particle box, cheap on phones).
func _build_rain() -> void:
	rain = CPUParticles3D.new()
	rain.amount = 280
	rain.lifetime = 0.7
	rain.emitting = false
	rain.local_coords = false
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(14.0, 0.5, 12.0)
	rain.direction = Vector3(0.15, -1.0, 0.0)
	rain.spread = 3.0
	rain.gravity = Vector3(0.0, -20.0, 0.0)
	rain.initial_velocity_min = 14.0
	rain.initial_velocity_max = 18.0
	var drop := BoxMesh.new()
	drop.size = Vector3(0.02, 0.45, 0.02)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.7, 0.85, 0.3)     # fine grey-blue streaks, not white
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = mat
	rain.mesh = drop
	add_child(rain)


func _set_weather(w: String) -> void:
	if w == weather:
		return
	var was := weather
	weather = w
	var wet := w == "rain" or w == "storm"
	rain.amount = 450 if w == "storm" else 280
	rain.emitting = wet
	if wet and property.sound_on:
		if rain_sound.stream == null:
			rain_sound.stream = sfx.make_rain()
		rain_sound.volume_db = -9.0 if w == "storm" else -14.0
		rain_sound.play()
	else:
		rain_sound.stop()
	env.fog_enabled = false
	if world.ground_material != null:            # an overcast sky casts no cloud shadows
		world.ground_material.set_shader_parameter("cloud_amount", 1.0 if w == "clear" else 0.0)
	match w:
		"rain":
			event_about("It starts to rain.", true)
		"storm":
			event_about("A storm rolls in!", true)
		_:
			if was != "clear":
				event_about("The sky clears.", true)
	count("weather_" + w)


func _weather_tick(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	if rain != null:
		# The rain starts a little below the camera, never at it: drops born right by the lens
		# streaked across the screen as big white smears (worse zoomed in).
		var above := clampf(cam.position.y - hero.position.y - 2.0, 2.5, 6.0)
		rain.global_position = hero.position + Vector3(0.0, above, 0.0)
		rain.visible = not world.is_dungeon(world.to_tile(hero.position)) \
			and not (frontier != null and frontier.season() == "winter")    # no rain underground; in winter it snows
	if not property.weather_on:
		return
	_weather_timer -= delta
	if _weather_timer <= 0.0:
		_weather_timer = randf_range(180.0, 420.0)
		var roll := randf()
		# the seasons lean the dice: dry summers, wet autumns, grey winters
		var sn := frontier.season() if frontier != null else "spring"
		var clear_p: float = {"spring": 0.5, "summer": 0.68, "autumn": 0.38, "winter": 0.42}[sn]
		var rain_p: float = clear_p + {"spring": 0.27, "summer": 0.16, "autumn": 0.32, "winter": 0.33}[sn]
		_set_weather("clear" if roll < clear_p else ("rain" if roll < rain_p + 0.13 else "storm"))   # (no fog: its share is rain)
	if weather == "storm":
		if _thunder_in < 0.0 and randf() < delta / 9.0:
			_flash = 0.15
			_thunder_in = randf_range(0.3, 1.5)        # thunder follows the flash
			_apply_daylight()
		if _thunder_in >= 0.0:
			_thunder_in -= delta
			if _thunder_in < 0.0 and property.sound_on:
				sfx.play("thunder")


## The music follows you: town, the wilds or the dungeon.
func _music_tick(delta: float) -> void:
	_music_timer -= delta
	if _music_timer > 0.0 or autotest:
		return
	_music_timer = 1.0
	if movie != null and movie.running:
		return                                    # the movie plays its own score
	var t := world.to_tile(hero.position)
	music.enabled = property.music_on
	music.play_area(_music_piece(t))


## Which piece suits the moment: a fight (a boss fight darker), then the place - the dungeon or
## a cave, the church, the cemetery, a town, the snow, the desert or the ash - then night or day.
var _battle_hold := 0.0


func _music_piece(t: Vector2i) -> String:
	var foe := hero.target
	var fighting := foe != null and is_instance_valid(foe) and not foe.dead and foe.kind != Entity.Kind.NPC \
		and foe.position.distance_to(hero.position) < 12.0
	if fighting:
		_battle_hold = 8.0                      # the fight music lingers a little after the last blow
		if foe.is_boss or foe.danger >= 8.0:
			return "boss"
		return "battle"
	if _battle_hold > 0.0:
		_battle_hold -= 1.0
		return music._area if music._area in ["battle", "boss"] else "battle"
	if world.is_dungeon(t) or world.is_cave(t):
		return "dungeon"
	if world.in_church(t):
		return "church"
	if World.CEMETERY.has_point(t):
		return "cemetery"
	if world.is_town(t):
		return "town"
	match world.biome_at(t):
		"snow":
			return "frost"
		"desert", "ash":
			return "desert"
	return "night" if is_night() else "wilds"


func _campfire_tick(delta: float) -> void:
	var douse := 4.0 if weather == "rain" or weather == "storm" else 1.0   # rain puts fires out sooner
	for i in range(campfires.size() - 1, -1, -1):
		campfires[i]["left"] = float(campfires[i]["left"]) - delta * douse
		if float(campfires[i]["left"]) <= 0.0:
			(campfires[i]["node"] as Node3D).queue_free()
			campfires.remove_at(i)


## Sound effects are heard only from the middle of the screen: a box SOUND_ZONE (75%) of the
## screen's width and height, centred, i.e. round the hero. Weather, music and thunder are global.
const SOUND_ZONE := 0.75


func sound(sound_name: String, at: Vector3, pitch := 1.0, volume_db := 0.0) -> void:
	if property.sound_on and hero != null and _in_sound_zone(at + Vector3(0.0, 0.5, 0.0)):
		# farther from the hero, quieter (up to 12 dB at the edge of the screen)
		var d := Vector2(at.x - hero.position.x, at.z - hero.position.z).length()
		sfx.play(sound_name, pitch, volume_db - clampf(d * 0.7, 0.0, 12.0))


func _in_sound_zone(p: Vector3) -> bool:
	if cam.is_position_behind(p):
		return false
	var size := get_viewport().get_visible_rect().size
	var off := (cam.unproject_position(p) - size / 2.0).abs()
	return off.x <= size.x * SOUND_ZONE / 2.0 and off.y <= size.y * SOUND_ZONE / 2.0


## Moves the sun and dims the sky over the day; nights stay readable.
func _apply_daylight() -> void:
	var sun_height := sin((day_time - 0.25) * TAU)          # -1 midnight .. 1 noon
	var light := clampf(0.5 + 0.5 * sun_height, 0.0, 1.0)
	match weather:
		"rain":
			light *= 0.7
		"storm":
			light *= 0.5
	if _flash > 0.0:
		light = 1.0                                    # lightning
	if hero != null and hero.flags.has("night_sight"):
		light = maxf(light, 0.7)                       # Night Sight: the dark lifts for you
	# Painted light: a strong warm sun against cool, dim shade by day; amber when the sun is low;
	# blue moonlight at night.
	var low_sun := clampf(1.0 - absf(sun_height) * 2.5, 0.0, 1.0) * (1.0 if weather == "clear" else 0.3)
	sun.light_energy = lerpf(0.3, 1.35, light)
	sun.light_color = Color(0.55, 0.66, 1.0).lerp(Color(1.0, 0.93, 0.8), light).lerp(Color(1.0, 0.66, 0.38), low_sun * 0.7)
	sun.rotation_degrees = Vector3(-20.0 - 50.0 * maxf(sun_height, 0.0), day_time * 360.0, 0.0)
	env.background_color = Color("0d1426").lerp(Color("87a8c9"), light)
	if weather == "clear":
		env.fog_light_color = env.background_color       # the haze takes the sky's colour
	env.ambient_light_energy = lerpf(0.42, 0.6, light)
	_sky_acc += get_process_delta_time()
	# The sky changes slowly, and each change re-lights the world from it, so it's updated at most
	# every 3 seconds and only when it has visibly changed (lightning at once).
	var dusk := clampf(1.0 - absf(sun_height) * 3.0, 0.0, 1.0) * (1.0 if weather == "clear" else 0.4)
	var cloudy := 0.0 if weather == "clear" else 0.7
	if _flash > 0.0 or (_sky_acc >= 3.0 and (absf(light - _sky_light) > 0.02 or absf(dusk - _sky_dusk) > 0.03 or cloudy != _sky_cloudy)):
		_sky_acc = 0.0
		_sky_light = light
		_sky_dusk = dusk
		_sky_cloudy = cloudy
		sky_mat.set_shader_parameter("light", light)
		sky_mat.set_shader_parameter("dusk", dusk)
		sky_mat.set_shader_parameter("sun_dir", sun.global_transform.basis.z)
		sky_mat.set_shader_parameter("cloudy", cloudy)
	_fireflies_step(sun_height < -0.15 and weather == "clear")
	var night := clampf(1.0 - light * 1.6, 0.0, 1.0)
	for l in brazier_lights:
		l.light_energy = 1.6 * night * (0.9 + 0.1 * sin(Time.get_ticks_msec() * 0.01))   # a flicker


const SKY_SHADER := """
shader_type sky;
uniform float light = 1.0;          // 0 night .. 1 day
uniform float dusk = 0.0;           // sunrise / sunset glow
uniform float cloudy = 0.0;         // greyer under rain and fog
uniform vec3 sun_dir = vec3(0.0, 1.0, 0.0);

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	float L = AT_CUBEMAP_PASS ? max(light, 0.45) : light;    // ambient light never drops to black
	vec3 top = mix(vec3(0.01, 0.02, 0.06), vec3(0.32, 0.52, 0.86), L);
	vec3 hor = mix(vec3(0.05, 0.07, 0.15), vec3(0.74, 0.81, 0.88), L);
	vec3 col = mix(hor, top, smoothstep(0.0, 0.55, h));
	vec3 sd = normalize(sun_dir);
	// the dawn and dusk glow, strongest low on the horizon towards the sun
	vec2 flat_d = normalize(d.xz + vec2(0.0001));
	vec2 flat_s = normalize(sd.xz + vec2(0.0001));
	float toward = max(dot(flat_d, flat_s), 0.0);
	col = mix(col, vec3(1.0, 0.5, 0.24), dusk * pow(toward, 3.0) * (1.0 - smoothstep(0.0, 0.4, abs(h))) * 0.85);
	col = mix(col, vec3(dot(col, vec3(0.33))) * 0.9, cloudy);
	if (!AT_CUBEMAP_PASS) {
		col += vec3(1.0, 0.92, 0.75) * smoothstep(0.9992, 0.9997, dot(d, sd)) * light * (1.0 - cloudy);   // the sun
		col += vec3(0.86, 0.89, 0.96) * smoothstep(0.9988, 0.9993, dot(d, -sd)) * (1.0 - light) * (1.0 - cloudy);  // the moon
		float star = step(0.9975, hash(floor(d * 190.0))) * (1.0 - light) * smoothstep(0.02, 0.25, h) * (1.0 - cloudy);
		col += vec3(star) * (0.6 + 0.4 * hash(floor(d * 190.0) + 7.0));
	}
	if (h < 0.0) {
		col = mix(col, vec3(0.12, 0.16, 0.1) * (0.3 + 0.7 * L), smoothstep(0.0, 0.15, -h));   // the ground below
	}
	COLOR = col;
}
"""
var sky_mat: ShaderMaterial
var _sky_acc := 10.0
var _sky_light := -1.0
var _sky_dusk := -1.0
var _sky_cloudy := -1.0
var _fireflies: CPUParticles3D


## Fireflies drift round you on clear nights out in the wilds (not in town or the dungeon).
func _fireflies_step(on: bool) -> void:
	if hero == null:
		return
	if _fireflies == null:
		_fireflies = CPUParticles3D.new()
		_fireflies.amount = 22
		_fireflies.lifetime = 4.0
		_fireflies.local_coords = false
		var q := QuadMesh.new()
		q.size = Vector2(0.07, 0.07)
		q.material = Fx.glow(Color.WHITE)
		_fireflies.mesh = q
		_fireflies.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_fireflies.emission_box_extents = Vector3(7.0, 0.8, 7.0)
		_fireflies.gravity = Vector3.ZERO
		_fireflies.direction = Vector3.UP
		_fireflies.spread = 180.0
		_fireflies.initial_velocity_min = 0.05
		_fireflies.initial_velocity_max = 0.25
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 0.8, 1.0])
		g.colors = PackedColorArray([Color(0.8, 1.0, 0.4, 0.0), Color(0.85, 1.0, 0.45, 1.0), Color(0.6, 0.9, 0.3, 0.2),
			Color(0.85, 1.0, 0.45, 1.0), Color(0.8, 1.0, 0.4, 0.0)])
		_fireflies.color_ramp = g
		add_child(_fireflies)
	var t := world.to_tile(hero.position)
	var want := on and not world.is_town(t) and not world.is_dungeon(t) and property.graphics != "low"
	_fireflies.emitting = want
	_fireflies.global_position = hero.position + Vector3(0.0, 1.0, 0.0)


func _bless_text() -> String:
	var parts: Array[String] = []
	if hero.bless_timer > 0.0:
		parts.append("blessed %d:%02d" % [int(hero.bless_timer) / 60, int(hero.bless_timer) % 60])
	for id in hero.effects:                       # spell buffs and curses on the hero
		var secs := int(float(hero.effects[id]["secs"]))
		parts.append("%s %d:%02d" % [Spells.LIST[id]["name"] if Spells.LIST.has(id) else id, secs / 60, secs % 60])
	if hero.paralyzed_timer > 0.0:
		parts.append("paralyzed")
	return "" if parts.is_empty() else " (" + ", ".join(parts) + ")"


func _poison_text() -> String:
	if hero.poison_level <= 0:
		return ""
	return " (%s poison)" % Rules.POISON_NAMES[hero.poison_level]


func _pets_text() -> String:
	if hero.pets.is_empty():
		return ""
	var names: Array[String] = []
	for p in hero.pets:
		names.append("%s %d/%d" % [p.display_name, ceili(p.hp), p.stats.max_hp()])
	return "   Pets: " + ", ".join(names)


func _clock_text() -> String:
	var minutes := int(day_time * 24.0 * 60.0)
	var hour := minutes / 60
	return "%02d:%02d %s%s" % [hour, minutes % 60, "day" if hour >= 6 and hour < 20 else "night",
		("   " + frontier.season_text()) if frontier != null else ""]


func _refresh_settings() -> void:
	for c in settings_box.get_children():
		settings_box.remove_child(c)
		c.queue_free()
	var title := _info("Settings")
	title.add_theme_font_size_override("font_size", 30)
	settings_box.add_child(title)
	settings_box.add_child(_menu_button("Sound: " + ("On" if property.sound_on else "Off"), _toggle_sound))
	settings_box.add_child(_menu_button("Music: " + ("On" if property.music_on else "Off"), _toggle_music))
	settings_box.add_child(_menu_button("Weather: " + ("On" if property.weather_on else "Off (always clear)"), _toggle_weather))
	settings_box.add_child(_menu_button("Ruleset: " + ("Trammel (no player killing)" if property.ruleset == "trammel" else "Felucca (open player-vs-player)"), _toggle_ruleset))
	settings_box.add_child(_info("Felucca: players may attack each other outside town (never inside a town: towns are safe). Trammel: players can't hurt each other at all, except guilds at war."))
	settings_box.add_child(_info("Camera: pinch with two fingers to zoom, twist them to turn the view (mouse wheel zooms on a computer)."))
	settings_box.add_child(_menu_button("Reset camera", _reset_camera))
	settings_box.add_child(_menu_button("Back", _close_settings))


func _toggle_ruleset() -> void:
	property.ruleset = "felucca" if property.ruleset == "trammel" else "trammel"
	for e in creatures:                          # stop any fight between players that is now forbidden
		if e.target != null and is_instance_valid(e.target) and e.target.kind == Entity.Kind.PLAYER \
				and e.kind == Entity.Kind.PLAYER and not e._is_fair_target(e.target):
			e.target = null
	log_event("The world follows %s rules now." % ("Trammel" if property.ruleset == "trammel" else "Felucca"))
	_refresh_settings()


## One look for everyone: everything on, at its best - with the cost of each kept down where it
## doesn't show. Shadows in two cascades to 40 m on a 2048 map, grass and flowers, fine ground,
## the glow (a light one), the colour grade, smooth edges by FXAA (a fraction of the cost of
## MSAA on phones). The only thing that ever gives is the 3D resolution, quietly, if a phone
## can't hold 60 frames a second.
func _apply_graphics() -> void:
	property.graphics = "high"
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL   # one shadow pass, not two
	sun.directional_shadow_max_distance = 28.0
	sun.directional_shadow_fade_start = 0.85
	world.set_ground_detail(true)
	_render_base = 0.8 if OS.has_feature("mobile") else 1.0    # phone screens are dense: 80% looks the same
	cam.far = 80.0 if property.first_person else VIEW_FAR
	_render_scale = _render_base
	_scale_cap = 1.0
	_fps_good = 0
	RenderingServer.directional_shadow_atlas_set_size(2048, true)
	for n in world.decor:
		if n != null:
			(n as Node3D).visible = true
	var vp := get_viewport()
	vp.scaling_3d_scale = _render_scale
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	env.glow_enabled = true                           # a soft glow round fire and magic
	for lv in range(7):
		env.set_glow_level(lv, lv == 2)              # one level (a quarter-size pass): the look, little of the cost
	if _grade != null:
		_grade.visible = true
	if rain != null:
		rain.amount = 450 if weather == "storm" else 280


func _toggle_music() -> void:
	property.music_on = not property.music_on
	music.set_enabled(property.music_on)
	_update_corner_buttons()
	_refresh_settings()


func _toggle_weather() -> void:
	property.weather_on = not property.weather_on
	if not property.weather_on:
		_set_weather("clear")
	_refresh_settings()


func _toggle_sound() -> void:
	property.sound_on = not property.sound_on
	_update_corner_buttons()
	_refresh_settings()


func _reset_camera() -> void:
	property.cam_zoom = 1.0
	property.cam_yaw = 0.0
	_follow_camera()
	log_event("Camera reset.")


func _open_settings() -> void:
	menu.visible = false
	settings_panel.visible = true
	_refresh_settings()


func _close_settings() -> void:
	settings_panel.visible = false
	menu.visible = true


func _follow_camera() -> void:
	if property.first_person:
		_fp_step(get_process_delta_time())
		if hero.rig != null and hero.rig.visible:
			hero.rig.visible = false        # the hero's own body stays out of view
	cam.position = _hero_cam_pos()
	cam.look_at(_hero_cam_look(), Vector3.UP)
	view_planes = cam.get_frustum()


var view_planes: Array[Plane] = []      # the camera's view, refreshed every frame
const MOVIE_VIEW := 48.0                  # creatures further than this from the camera aren't drawn or animated
var _fx_cull_timer := 0.0


## Whether `p` is inside the camera's view, or within `margin` of its edges.
func in_view(p: Vector3, margin := 2.0) -> bool:
	if p.distance_squared_to(cam.position) > MOVIE_VIEW * MOVIE_VIEW:
		return false                              # (far off, creatures are specks: not drawn or animated)
	for pl in view_planes:
		if pl.distance_to(p) > margin:          # the planes face outwards
			return false
	return true


## Fires and other ambient effects only simulate while on screen (CPU particles cost even when
## nobody sees them).
func _cull_fx(delta: float) -> void:
	_fx_cull_timer -= delta
	if _fx_cull_timer > 0.0:
		return
	_fx_cull_timer = 0.25
	for n in get_tree().get_nodes_in_group("view_fx"):
		var fx := n as Node3D
		var on := in_view(fx.global_position, 3.0)
		if fx.visible != on:
			fx.visible = on
			fx.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
