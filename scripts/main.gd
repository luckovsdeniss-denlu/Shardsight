extends Node3D
## Third-person 3D view of the tile world, populated with the hero, other players, NPCs
## and monsters. Tap the ground to walk, tap a monster to attack it. With Auto on, the hero
## also acts by itself: wanders, fights monsters nearby and retreats to a healer when hurt.

const CAM_OFFSET := Vector3(0.0, 9.0, 7.0)
const MANUAL_PAUSE := 4.0      # seconds auto mode waits after a tap
const LOG_LINES := 6
const DEFAULT_RUNE := Vector2i(25, 13)
const GATE_SECONDS := 20.0
const DAY_SECONDS := 480.0       # one full day and night

var version: String = ProjectSettings.get_setting("application/config/version", "dev")
var world := World.new()
var creatures: Array[Entity] = []
var corpses: Array[Corpse] = []
var hero: Entity
var cam := Camera3D.new()
var marker := MeshInstance3D.new()
var hud := Label.new()
var log_label := Label.new()
var auto_button := Button.new()
var log_lines: Array[String] = []
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
]
var _tips_left: Array = []
var _tip_timer := 8.0


func _ready() -> void:
	world.build(self)
	_build_environment()
	_build_marker()
	_spawn_all()

	cam.fov = 50.0
	add_child(cam)
	cam.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 26)
	layer.add_child(hud)

	# Event log: pinned to the lower-left corner. The containers are full-screen but ignore
	# the mouse, so taps still reach the game. No background; a thick outline keeps it readable.
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	layer.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.alignment = BoxContainer.ALIGNMENT_END
	margin.add_child(column)
	log_label.add_theme_font_size_override("font_size", 28)
	log_label.add_theme_color_override("font_outline_color", Color.BLACK)
	log_label.add_theme_constant_override("outline_size", 8)
	log_label.custom_minimum_size = Vector2(700, 0)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(log_label)

	var corner := VBoxContainer.new()
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	layer.add_child(corner)
	auto_button.custom_minimum_size = Vector2(240, 80)
	auto_button.add_theme_font_size_override("font_size", 28)
	auto_button.pressed.connect(_toggle_auto)
	corner.add_child(auto_button)
	corner.add_child(_menu_button("Menu", _open_menu))
	minimap.setup(self, world)
	corner.add_child(minimap)
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_update_button()
	_build_menu(layer)
	_build_skills_panel(layer)
	_build_craft_panel(layer)
	_build_property_panel(layer)
	travel_panel = _make_overlay(layer)
	travel_box = travel_panel.get_meta("box")
	settings_panel = _make_overlay(layer)
	settings_box = settings_panel.get_meta("box")

	if autotest:
		seed(20261103)                       # same dice every run, so results are comparable
		skip_save = true                     # a fresh game; never touch the real save
		_start_skill_total = hero.stats.skill_total()
		print("AUTOTEST start: %d game-seconds" % int(autotest_seconds))
	elif SaveGame.load_into(hero, property):
		log_event("Welcome back. Your progress was loaded.")
		_restore_house()
	else:
		log_event("Welcome to Shardsight. Tap a monster to attack it.")
		_tips_left = TIPS.duplicate()        # first launch: a few tips over the first minute
	if property.rune.x < 0:
		property.rune = DEFAULT_RUNE         # a starting rune marked in town, for Recall
	_follow_camera()


func _menu_button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 80)
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(callback)
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
	box.add_child(title)
	box.add_child(_menu_button("Resume", _resume))
	box.add_child(_menu_button("Skills", _open_skills))
	box.add_child(_menu_button("Craft", _open_craft))
	box.add_child(_menu_button("Bank & House", _open_property))
	box.add_child(_menu_button("Travel", _open_travel))
	box.add_child(_menu_button("Settings", _open_settings))
	box.add_child(_menu_button("Help", _open_help))
	box.add_child(_menu_button("Save now", _save_now))
	reset_button = _menu_button("Reset progress", _reset_progress)
	box.add_child(reset_button)


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


## Long lists scroll (drag on a phone) so they fit the screen.
func _scroll_wrap(box: VBoxContainer) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	return scroll


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


## Rebuilds the skills list. Lock arrows: Up = may rise, Down = may be lost when the 700-point
## cap is reached (so another skill can rise), Locked = frozen.
func _refresh_skills() -> void:
	for c in skills_box.get_children():
		skills_box.remove_child(c)
		c.queue_free()
	var s := hero.stats
	var title := Label.new()
	title.text = "Str %d   Dex %d   Int %d   (%d/%d)\nSkills %.1f / %d" % [
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


func _hero_at_bank() -> bool:
	if hero.dead or hero.notoriety() != Entity.Notoriety.BLUE:
		return false
	for e in creatures:
		if e.role == "banker" and e.position.distance_to(hero.position) <= 3.0:
			return true
	return false


func _hero_at_house() -> bool:
	return property.has_house() and not hero.dead \
		and hero.position.distance_to(world.tile_center(property.house_center_tile())) <= 1.6


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
		property_box.add_child(_info("Your house at %d,%d: %s. Coming near it keeps it standing; after %d days away it collapses and its chest spills out for anyone." % [
			o.x, o.y, property.condition(), int(Property.COLLAPSE_DAYS)]))
		property_box.add_child(_info("Chest: " + Property.items_text(property.house_chest)))
		property_box.add_child(_action("Store bag in the chest", _on_chest_store, at_house and not hero.inventory.is_empty()))
		property_box.add_child(_action("Take all from the chest", _on_chest_take, at_house and not property.house_chest.is_empty()))
	elif property.has_deed:
		property_box.add_child(_info("You own a house deed. Stand on open ground outside town and place it."))
		property_box.add_child(_action("Place house here", _on_place_house, not hero.dead and not hero._in_town()))
	else:
		property_box.add_child(_info("A house deed costs %d gold, paid from the bank." % Property.DEED_PRICE))
		property_box.add_child(_action("Buy a house deed", _on_buy_deed, at_bank and property.bank_gold >= Property.DEED_PRICE))
	property_box.add_child(_menu_button("Back", _close_property))


## Also used by the hero's automatic bank trips.
func bank_deposit(e: Entity, amount: int) -> void:
	amount = mini(amount, e.gold)
	if amount <= 0:
		return
	e.gold -= amount
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


func _on_buy_deed() -> void:
	property.bank_gold -= Property.DEED_PRICE
	property.has_deed = true
	log_event("You buy a house deed for %d gold from the bank." % Property.DEED_PRICE)
	_refresh_property()


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
	var o := world.find_house_spot(world.to_tile(hero.position), _occupied_tiles())
	if o.x < 0:
		log_event("There is no room for a house here. Try open ground.")
		return
	world.place_house(self, o)
	property.house_origin = o
	property.house_chest = {}
	property.has_deed = false
	property.refresh()
	log_event("You place your house. Its chest is safe storage; visit it to keep it standing.")
	_refresh_property()


## On load: rebuild the saved house, or let it collapse if it was neglected too long.
func _restore_house() -> void:
	if not property.has_house():
		return
	var center := world.tile_center(property.house_center_tile())
	if property.should_collapse():
		var ruins := Corpse.new()
		add_child(ruins)
		ruins.setup("House", true, false, 0, center,
			{"gold": 0, "reagents": 0, "items": property.house_chest.duplicate()})
		ruins.set_title("Ruins of your house")
		ruins.life = 600.0
		corpses.append(ruins)
		property.clear_house()
		log_event("Your neglected house has collapsed! Its contents lie in the ruins for anyone to take.")
		return
	var occupied := _occupied_tiles()
	occupied.erase(world.to_tile(hero.position))      # the hero may be standing inside it
	if not world.can_place_house(property.house_origin, occupied):
		Property.merge(property.bank_items, property.house_chest)
		property.clear_house()
		property.has_deed = true
		log_event("Your house could not be rebuilt here; its deed and chest went to the bank.")
		return
	world.place_house(self, property.house_origin)


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
	overlay.set_meta("box", box)
	return overlay


# --- quests ----------------------------------------------------------------

func _quest_text() -> String:
	if not property.quest_active:
		return "Quest: visit %s in town for work." % Quests.GIVER
	var q: Dictionary = Quests.LIST[property.quest_index]
	var done := property.quest_kills >= int(q["count"])
	return "Quest: slay %d %s (%d/%d), reward %d gold%s" % [
		int(q["count"]), q["target"], mini(property.quest_kills, int(q["count"])), int(q["count"]),
		int(q["reward"]), " - done, return to %s!" % Quests.GIVER if done else ""]


## Called by Entity._die for every death.
func on_kill(killer: Entity, victim: Entity) -> void:
	if killer != null and killer.is_hero:
		count("kills")
		count("hero_killed_" + victim.display_name)
	if killer == null or not killer.is_hero or not property.quest_active:
		return
	var q: Dictionary = Quests.LIST[property.quest_index]
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
		if property.quest_kills < int(q["count"]):
			return
		hero._earn(int(q["reward"]))
		count("quests_completed")
		log_event("%s: Well done! Here are %d gold." % [Quests.GIVER, int(q["reward"])])
		property.quest_active = false
		property.quest_index = (property.quest_index + 1) % Quests.LIST.size()
	var next: Dictionary = Quests.LIST[property.quest_index]
	property.quest_active = true
	property.quest_kills = 0
	log_event("%s: %s Reward: %d gold." % [Quests.GIVER, next["text"], int(next["reward"])])


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
	var r := property.rune
	travel_box.add_child(_info("Your rune is marked at %d,%d%s." % [
		r.x, r.y, " (the town square)" if r == DEFAULT_RUNE else ""]))
	for id in ["recall", "mark", "gate_travel"]:
		var sp: Dictionary = Spells.LIST[id]
		var problem := hero.travel_problem(id)
		travel_box.add_child(_info("%s: circle %d, %d mana, Magery %.1f, %d%% chance%s" % [
			sp["name"], int(sp["circle"]), int(sp["mana"]), float(sp["min"]),
			roundi(Rules.cast_chance(float(hero.stats.skills[Hero.Skill.MAGERY]), float(sp["min"])) * 100.0),
			"" if problem == "" else " (" + problem + ")"]))
		travel_box.add_child(_action("Cast " + String(sp["name"]), _on_travel.bind(id), problem == ""))
	travel_box.add_child(_info("Recall takes you to the rune; Mark moves the rune to where you stand; Gate Travel opens a moongate there that anyone can use for %d seconds." % int(GATE_SECONDS)))
	travel_box.add_child(_menu_button("Back", _close_travel))


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
		if e.dead:
			continue
		var p := e.position
		if is_nan(p.x) or is_nan(p.z):
			_note_problem("%s has an invalid position" % e.display_name)
		elif world.is_blocked(world.to_tile(p)):
			_note_problem("%s is inside a wall at %s" % [e.display_name, world.to_tile(p)])
		if e.hp > float(e.stats.max_hp()) + 0.01:
			_note_problem("%s has more HP than its maximum" % e.display_name)
		if e.gold < 0 or e.reagents < 0.0 or e.bandages < 0:
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
	if earned <= spent:
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
		"Tap the ground to walk there. Tap a monster to attack it, a corpse to loot it, a rock to mine it, a tree to chop it.",
		"Auto (top right) lets your hero play by itself: fight, heal, loot, gather, craft at the forge, sell to Bran and bank with Oswin. Tapping takes over for a few seconds.",
		"Names: blue innocent, grey criminal, red murderer or monster. Guards in the tan towns kill monsters, criminals and murderers on sight.",
		"Skills and stats rise by use. Menu > Skills shows them and lets you set Up, Down or Locked for the 700-point cap.",
		"Die and you become a ghost: walk to a healer to be raised for free. Your corpse keeps your bag; go back for it. Bank gold to keep it safe.",
		"Captain Marcus in town gives kill quests. The dungeon is east, past the outpost.",
		"Menu also has Craft, Bank & House, Travel (Recall, Mark, Gate Travel) and Settings (sound, camera).",
	]:
		settings_box.add_child(_info("• " + String(line)))
	settings_box.add_child(_menu_button("Back", _close_settings))


func _open_menu() -> void:
	paused = true
	menu.visible = true
	reset_armed = false
	reset_button.text = "Reset progress"
	_autosave()


func _resume() -> void:
	paused = false
	menu.visible = false


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
	if not skip_save and hero != null:
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
	_spawn(Entity.Kind.PLAYER, "Aldric", Bestiary.WARRIOR, blue, Vector2i(10, 10))
	_spawn(Entity.Kind.PLAYER, "Mira", Bestiary.FIGHTER, blue, Vector2i(20, 18))
	_spawn(Entity.Kind.PLAYER, "Selene", Bestiary.MAGE, blue, Vector2i(18, 8))
	_spawn(Entity.Kind.PLAYER, "Vex", Bestiary.PKILLER, blue, Vector2i(15, 16))   # a player killer

	_spawn(Entity.Kind.NPC, "Elara", Bestiary.HEALER, cream, Vector2i(24, 11))
	_spawn(Entity.Kind.NPC, "Bran", Bestiary.MERCHANT, cream, Vector2i(23, 6))
	_spawn(Entity.Kind.NPC, "Oswin", Bestiary.BANKER, cream, Vector2i(26, 12))
	_spawn(Entity.Kind.NPC, "Town Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(20, 11))
	_spawn(Entity.Kind.NPC, "Town Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(28, 11))
	_spawn(Entity.Kind.NPC, Quests.GIVER, Bestiary.QUESTGIVER, Color("c9a86a"), Vector2i(22, 13))
	# The outpost, east of the main town, near the dungeon.
	_spawn(Entity.Kind.NPC, "Brother Aldo", Bestiary.HEALER, cream, Vector2i(35, 4))
	_spawn(Entity.Kind.NPC, "Outpost Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(38, 6))

	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(12, 8))
	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(6, 11))
	_spawn(Entity.Kind.MONSTER, "Wolf", Bestiary.WOLF, red, Vector2i(26, 18))
	_spawn(Entity.Kind.MONSTER, "Giant Spider", Bestiary.GIANT_SPIDER, Color("3a3a2a"), Vector2i(4, 21))   # south-west woods
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(27, 20))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(16, 20))
	_spawn(Entity.Kind.MONSTER, "Evil Mage", Bestiary.EVIL_MAGE, red, Vector2i(14, 22))
	# The dungeon.
	_spawn(Entity.Kind.MONSTER, "Skeleton", Bestiary.SKELETON, Color("d8d2c0"), Vector2i(39, 13))
	_spawn(Entity.Kind.MONSTER, "Skeleton", Bestiary.SKELETON, Color("d8d2c0"), Vector2i(40, 20))
	_spawn(Entity.Kind.MONSTER, "Zombie", Bestiary.ZOMBIE, Color("6f8f5a"), Vector2i(44, 12))
	_spawn(Entity.Kind.MONSTER, "Ogre", Bestiary.OGRE, Color("8a6a4a"), Vector2i(44, 20))
	_spawn(Entity.Kind.MONSTER, "Lich", Bestiary.LICH, Color("6a4a8a"), Vector2i(48, 12))


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
	c.setup(victim.display_name, open_to_all, victim.kind == Entity.Kind.PLAYER,
		victim.get_instance_id(), victim.position, victim.make_loot())
	corpses.append(c)


func _build_environment() -> void:
	add_child(sfx)
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("87a8c9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.76)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)


func _build_marker() -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = 0.3
	ring.bottom_radius = 0.3
	ring.height = 0.04
	marker.mesh = ring
	marker.material_override = World._mat(Color(0.35, 0.78, 1.0))
	marker.visible = false
	add_child(marker)


func log_event(text: String) -> void:
	log_lines.append(text)
	while log_lines.size() > LOG_LINES:
		log_lines.remove_at(0)
	log_label.text = "\n".join(log_lines)


# --- input -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if paused:
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
		held = button.pressed
		if held:
			_tap(button.position)
	elif event is InputEventMouseMotion and held:
		_tap((event as InputEventMouseMotion).position)


## Intersects the camera ray through `screen` with the ground plane (y = 0).
func _tap(screen: Vector2) -> void:
	if hero.dead:
		return
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(
		cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	if hit == null:
		return
	var dest: Vector3 = hit
	hero.pause = MANUAL_PAUSE  # player input wins; auto resumes after a pause
	var e := _creature_near(dest)
	if e != null and e.kind == Entity.Kind.MONSTER:
		hero.target = e
		hero.loot_target = null
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


func _corpse_near(p: Vector3) -> Corpse:
	var best: Corpse = null
	var best_d := 1.0
	for c in corpses:
		var d := c.position.distance_to(p)
		if d <= best_d:
			best = c
			best_d = d
	return best


## Inside the guarded town, guards instantly kill monsters, criminals and murderers.
func _guards_strike() -> void:
	for e in creatures:
		if e.dead or e.kind == Entity.Kind.NPC:
			continue
		if not world.is_town(world.to_tile(e.position)):
			continue
		if e.kind == Entity.Kind.MONSTER or e.notoriety() != Entity.Notoriety.BLUE:
			var guard := _nearest_guard(e.position)
			if guard != null:
				e.take_damage(9999.0, guard)     # the death message names the guard


func _nearest_guard(p: Vector3) -> Entity:
	var best: Entity = null
	var best_d := INF
	for e in creatures:
		if e.role == "guard":
			var d := e.position.distance_to(p)
			if d < best_d:
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


# --- frame -----------------------------------------------------------------

func _process(delta: float) -> void:
	if paused:
		_update_hud()
		return
	if autotest:
		_autotest_tick(delta)
	if not _tips_left.is_empty():
		_tip_timer -= delta
		if _tip_timer <= 0.0:
			_tip_timer = 15.0
			log_event(String(_tips_left.pop_front()))
	save_timer += delta
	if save_timer >= 20.0:
		save_timer = 0.0
		_autosave()
	for e in creatures:
		e.tick(delta)
	_guards_strike()
	_gates_tick(delta)
	day_time = fmod(day_time + delta / DAY_SECONDS, 1.0)
	_apply_daylight()
	_quest_tick()
	if property.has_house() and not hero.dead \
			and hero.position.distance_to(world.tile_center(property.house_center_tile())) <= 6.0:
		property.refresh()             # being near the house keeps it from decaying
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
	_follow_camera()
	_update_hud()


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
	hud.text = "Shardsight v%s   [%s]   %s   %s\nHP %d/%d%s   Stam %d/%d   Mana %d/%d   Reagents %d   Bandages %d   Gold %d\nStr %d  Dex %d  Int %d  (%d/%d)   Skills %.1f/%d (Menu > Skills)   Tile %d,%d\n%s\nBag: %s\n%s" % [
		version, hero.state_text(), hero.notoriety_text(), _clock_text(), ceili(hero.hp), s.max_hp(), _poison_text(), int(hero.stamina), s.max_stamina(),
		floori(hero.mana), s.max_mana(),
		floori(hero.reagents), hero.bandages, hero.gold,
		s.strength, s.dexterity, s.intelligence, s.stat_total(), Rules.STAT_CAP,
		s.skill_total(), Rules.SKILL_CAP_TOTAL, tile.x, tile.y, hero.gear_text(), bag_text,
		_quest_text()]


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
func sound(sound_name: String, at: Vector3) -> void:
	if property.sound_on and hero != null and at.distance_to(hero.position) <= 12.0:
		sfx.play(sound_name)


## Moves the sun and dims the sky over the day; nights stay readable.
func _apply_daylight() -> void:
	var sun_height := sin((day_time - 0.25) * TAU)          # -1 midnight .. 1 noon
	var light := clampf(0.5 + 0.5 * sun_height, 0.0, 1.0)
	sun.light_energy = lerpf(0.25, 1.0, light)
	sun.light_color = Color(0.6, 0.7, 1.0).lerp(Color(1.0, 0.97, 0.9), light)
	sun.rotation_degrees = Vector3(-20.0 - 50.0 * maxf(sun_height, 0.0), day_time * 360.0, 0.0)
	env.background_color = Color("0d1426").lerp(Color("87a8c9"), light)
	env.ambient_light_energy = lerpf(0.45, 0.8, light)


func _poison_text() -> String:
	if hero.poison_level <= 0:
		return ""
	return " (%s poison)" % Rules.POISON_NAMES[hero.poison_level]


func _clock_text() -> String:
	var minutes := int(day_time * 24.0 * 60.0)
	var hour := minutes / 60
	return "%02d:%02d %s" % [hour, minutes % 60, "day" if hour >= 6 and hour < 20 else "night"]


func _refresh_settings() -> void:
	for c in settings_box.get_children():
		settings_box.remove_child(c)
		c.queue_free()
	var title := _info("Settings")
	title.add_theme_font_size_override("font_size", 30)
	settings_box.add_child(title)
	settings_box.add_child(_menu_button("Sound: " + ("On" if property.sound_on else "Off"), _toggle_sound))
	settings_box.add_child(_info("Camera: pinch with two fingers to zoom, twist them to turn the view (mouse wheel zooms on a computer)."))
	settings_box.add_child(_menu_button("Reset camera", _reset_camera))
	settings_box.add_child(_menu_button("Back", _close_settings))


func _toggle_sound() -> void:
	property.sound_on = not property.sound_on
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
	cam.position = hero.position + CAM_OFFSET.rotated(Vector3.UP, property.cam_yaw) * property.cam_zoom
	cam.look_at(hero.position + Vector3(0.0, 0.5, 0.0), Vector3.UP)
