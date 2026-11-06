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
var thief_panel: Control
var thief_box: VBoxContainer
var guild_panel: Control
var guild_box: VBoxContainer
var cam := Camera3D.new()
var marker := MeshInstance3D.new()
var hud := Label.new()
var log_label := Label.new()
var auto_button := Button.new()
var log_lines: Array[String] = []
var world_label := Label.new()        # what happens to everyone else (lower right)
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
	log_label.custom_minimum_size = Vector2(640, 0)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	world_label.add_theme_font_size_override("font_size", 24)
	world_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.8))
	world_label.add_theme_color_override("font_outline_color", Color.BLACK)
	world_label.add_theme_constant_override("outline_size", 8)
	world_label.custom_minimum_size = Vector2(480, 0)
	world_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	world_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	wcolumn.add_child(world_label)

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
	animals_panel = _make_overlay(layer)
	bard_panel = _make_overlay(layer)
	prices_panel = _make_overlay(layer)
	prices_box = prices_panel.get_meta("box")
	thief_panel = _make_overlay(layer)
	thief_box = thief_panel.get_meta("box")
	guild_panel = _make_overlay(layer)
	guild_box = guild_panel.get_meta("box")
	bard_box = bard_panel.get_meta("box")
	animals_box = animals_panel.get_meta("box")
	settings_box = settings_panel.get_meta("box")

	if autotest:
		seed(20261103)                       # same dice every run, so results are comparable
		skip_save = true                     # a fresh game; never touch the real save
		_start_skill_total = hero.stats.skill_total()
		print("AUTOTEST start: %d game-seconds" % int(autotest_seconds))
	elif SaveGame.load_into(hero, property):
		hero.refresh_look()                  # the saved gear shows on the model
		log_event("Welcome back. Your progress was loaded.")
		_restore_house()
		_restore_pets()
	else:
		log_event("Welcome to Shardsight. Tap a monster to attack it.")
		_tips_left = TIPS.duplicate()        # first launch: a few tips over the first minute
	if property.rune.x < 0 or property.runes.is_empty():
		property.rune = DEFAULT_RUNE         # a starting rune marked in town, for Recall
		property.runes.clear()
		property.runes.append(DEFAULT_RUNE)
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
	box.add_child(_menu_button("Travel & Spellbook", _open_travel))
	box.add_child(_menu_button("Guild & Fame", _open_guild))
	box.add_child(_menu_button("Thievery", _open_thief))
	box.add_child(_menu_button("Animals", _open_animals))
	box.add_child(_menu_button("Bard", _open_bard))
	box.add_child(_menu_button("Prices", _open_prices))
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
	title.text = "Level %d / %d\nStr %d   Dex %d   Int %d   (%d/%d)\nSkills %.1f / %d" % [
		hero.stats.level(), Hero.LEVEL_MAX,
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
	if killer != null and killer.kind == Entity.Kind.PET and killer.pet_owner != null:
		if killer.pet_owner.is_hero:
			count("pet_kills")
		killer = killer.pet_owner                # a pet's kill counts for its owner (quests too)
	if killer != null and killer.kind == Entity.Kind.PLAYER and killer != victim:
		killer.reputation_for_kill(victim)
	if victim.kind == Entity.Kind.PLAYER:
		victim.add_fame(-victim.fame / 10)       # dying costs a tenth of your fame
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
		if e.dead:
			continue
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
		"The world is bigger now: Southmoor, a third town, lies south. Wolf packs and an orc fort roam the far east, spiders the southern forest, and the restless dead an old graveyard in the south-east. The hills south-east are rich in ore.",
		"Father Corwin, the priest by the healer, cures poison for free, blesses you for 25 gold (+10% damage dealt, -10% taken, 5 minutes) and lifts a murder count for 50 gold. Just stand near him.",
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
		p.hp = clampf(float(d.get("hp", p.hp)), 1.0, float(p.stats.max_hp()))
		hero.adopt_pet(p)


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
	if hero.pets.is_empty():
		animals_box.add_child(_info("You have no pets (up to %d)." % Entity.MAX_PETS))
	for p in hero.pets:
		animals_box.add_child(_info("%s: HP %d/%d, Str %d, Dex %d" % [
			p.display_name, ceili(p.hp), p.stats.max_hp(), p.stats.strength, p.stats.dexterity]))
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
	_spawn(Entity.Kind.PLAYER, "Gareth", Bestiary.WARRIOR, blue, Vector2i(52, 35))
	_spawn(Entity.Kind.PLAYER, "Lyra", Bestiary.MAGE, blue, Vector2i(47, 35))
	_spawn(Entity.Kind.PLAYER, "Thorne", Bestiary.FIGHTER, blue, Vector2i(60, 6))
	_spawn(Entity.Kind.PLAYER, "Brina", Bestiary.ARCHER, blue, Vector2i(12, 26))
	_spawn(Entity.Kind.PLAYER, "Dorian", Bestiary.WARRIOR, blue, Vector2i(54, 37))
	_spawn(Entity.Kind.PLAYER, "Morg", Bestiary.PKILLER, blue, Vector2i(70, 30))  # another player killer
	_spawn(Entity.Kind.PLAYER, "Sly", Bestiary.THIEF, blue, Vector2i(12, 24))     # thieves
	_spawn(Entity.Kind.PLAYER, "Pip", Bestiary.THIEF, blue, Vector2i(60, 24))

	_spawn(Entity.Kind.NPC, "Elara", Bestiary.HEALER, cream, Vector2i(24, 11))
	_spawn(Entity.Kind.NPC, "Father Corwin", Bestiary.PRIEST, Color("d9c7f0"), Vector2i(25, 13))
	var bran := _spawn(Entity.Kind.NPC, "Bran", Bestiary.MERCHANT, cream, Vector2i(23, 6))
	bran.shop = Shop.new("town", 1.0, 1.0)
	# The outpost is remote: its merchant pays more for goods and charges more for supplies.
	var mara := _spawn(Entity.Kind.NPC, "Mara", Bestiary.MERCHANT, cream, Vector2i(37, 3))
	mara.shop = Shop.new("the outpost", 1.3, 1.25)
	_spawn(Entity.Kind.NPC, "Oswin", Bestiary.BANKER, cream, Vector2i(26, 12))
	_spawn(Entity.Kind.NPC, "Town Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(20, 11))
	_spawn(Entity.Kind.NPC, "Town Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(28, 11))
	_spawn(Entity.Kind.NPC, Quests.GIVER, Bestiary.QUESTGIVER, Color("c9a86a"), Vector2i(22, 13))
	# The outpost, east of the main town, near the dungeon.
	_spawn(Entity.Kind.NPC, "Brother Aldo", Bestiary.HEALER, cream, Vector2i(35, 4))
	_spawn(Entity.Kind.NPC, "Outpost Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(38, 6))
	# Southmoor, the southern town: its merchant pays a little more and charges a little more.
	_spawn(Entity.Kind.NPC, "Sister Maeve", Bestiary.HEALER, cream, Vector2i(46, 31))
	var hollis := _spawn(Entity.Kind.NPC, "Hollis", Bestiary.MERCHANT, cream, Vector2i(53, 31))
	hollis.shop = Shop.new("Southmoor", 1.15, 1.1)
	_spawn(Entity.Kind.NPC, "Pell", Bestiary.BANKER, cream, Vector2i(46, 37))
	_spawn(Entity.Kind.NPC, "Southmoor Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(44, 34))
	_spawn(Entity.Kind.NPC, "Southmoor Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(55, 34))

	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(12, 8))
	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(6, 11))
	_spawn(Entity.Kind.MONSTER, "Wolf", Bestiary.WOLF, red, Vector2i(26, 18))
	_spawn(Entity.Kind.MONSTER, "Giant Spider", Bestiary.GIANT_SPIDER, Color("3a3a2a"), Vector2i(4, 21))   # south-west woods
	_spawn(Entity.Kind.MONSTER, "Hind", Bestiary.HIND, Color("b08a5a"), Vector2i(4, 13))
	_spawn(Entity.Kind.MONSTER, "Hind", Bestiary.HIND, Color("b08a5a"), Vector2i(24, 17))
	_spawn(Entity.Kind.MONSTER, "Brown Bear", Bestiary.BROWN_BEAR, Color("6b4a2a"), Vector2i(29, 19))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(27, 20))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(16, 20))
	_spawn(Entity.Kind.MONSTER, "Evil Mage", Bestiary.EVIL_MAGE, red, Vector2i(14, 22))
	# The dungeon.
	_spawn(Entity.Kind.MONSTER, "Skeleton", Bestiary.SKELETON, Color("d8d2c0"), Vector2i(39, 13))
	_spawn(Entity.Kind.MONSTER, "Skeleton", Bestiary.SKELETON, Color("d8d2c0"), Vector2i(40, 20))
	_spawn(Entity.Kind.MONSTER, "Zombie", Bestiary.ZOMBIE, Color("6f8f5a"), Vector2i(44, 12))
	_spawn(Entity.Kind.MONSTER, "Ogre", Bestiary.OGRE, Color("8a6a4a"), Vector2i(44, 20))
	_spawn(Entity.Kind.MONSTER, "Lich", Bestiary.LICH, Color("6a4a8a"), Vector2i(48, 12))

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
	world_label.text = "\n".join(world_lines)


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
	_campfire_tick(delta)
	_fields_tick(delta)
	guilds.tick(delta)
	save_timer += delta
	if save_timer >= 20.0:
		save_timer = 0.0
		_autosave()
	for e in creatures:
		e.tick(delta)
		if e.shop != null:
			e.shop.tick(delta)
	_flush_spawns()
	_vendor_tick(delta)
	_guards_strike()
	_gates_tick(delta)
	day_time = fmod(day_time + delta / DAY_SECONDS, 1.0)
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
	hud.text = "Shardsight v%s   %s   [%s]   %s   %s\nLevel %d   Fame %d  Karma %d   HP %d/%d%s   Stam %d/%d   Mana %d/%d   Reagents %d   Bandages %d   Gold %d\nStr %d  Dex %d  Int %d  (%d/%d)   Skills %.1f/%d (Menu > Skills)   Tile %d,%d\n%s\nBag: %s\n%s" % [
		version, hero.title_name() + ((" [%s]" % hero.guild_abbr()) if hero.guild_abbr() != "" else ""),
		hero.state_text(), hero.notoriety_text(), _clock_text(), hero.stats.level(), hero.fame, hero.karma, ceili(hero.hp), s.max_hp(), _poison_text() + _bless_text(), int(hero.stamina), s.max_stamina(),
		floori(hero.mana), s.max_mana(),
		floori(hero.reagents), hero.bandages, hero.gold,
		s.strength, s.dexterity, s.intelligence, s.stat_total(), Rules.STAT_CAP,
		s.skill_total(), Rules.SKILL_CAP_TOTAL, tile.x, tile.y, hero.gear_text() + _pets_text(), bag_text,
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
	campfires.append({"node": fire, "left": CAMPFIRE_SECONDS})


func near_campfire(p: Vector3) -> bool:
	for c in campfires:
		var n: Node3D = c["node"]
		if Vector2(n.position.x - p.x, n.position.z - p.z).length() <= CAMPFIRE_RANGE:
			return true
	return false


func _campfire_tick(delta: float) -> void:
	for i in range(campfires.size() - 1, -1, -1):
		campfires[i]["left"] = float(campfires[i]["left"]) - delta
		if float(campfires[i]["left"]) <= 0.0:
			(campfires[i]["node"] as Node3D).queue_free()
			campfires.remove_at(i)


func sound(sound_name: String, at: Vector3) -> void:
	if property.sound_on and hero != null and at.distance_to(hero.position) <= 12.0:
		sfx.play(sound_name)


## Moves the sun and dims the sky over the day; nights stay readable.
func _apply_daylight() -> void:
	var sun_height := sin((day_time - 0.25) * TAU)          # -1 midnight .. 1 noon
	var light := clampf(0.5 + 0.5 * sun_height, 0.0, 1.0)
	if hero != null and hero.flags.has("night_sight"):
		light = maxf(light, 0.7)                       # Night Sight: the dark lifts for you
	sun.light_energy = lerpf(0.25, 1.0, light)
	sun.light_color = Color(0.6, 0.7, 1.0).lerp(Color(1.0, 0.97, 0.9), light)
	sun.rotation_degrees = Vector3(-20.0 - 50.0 * maxf(sun_height, 0.0), day_time * 360.0, 0.0)
	env.background_color = Color("0d1426").lerp(Color("87a8c9"), light)
	env.ambient_light_energy = lerpf(0.45, 0.8, light)


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
	return "%02d:%02d %s" % [hour, minutes % 60, "day" if hour >= 6 and hour < 20 else "night"]


func _refresh_settings() -> void:
	for c in settings_box.get_children():
		settings_box.remove_child(c)
		c.queue_free()
	var title := _info("Settings")
	title.add_theme_font_size_override("font_size", 30)
	settings_box.add_child(title)
	settings_box.add_child(_menu_button("Sound: " + ("On" if property.sound_on else "Off"), _toggle_sound))
	settings_box.add_child(_menu_button("Ruleset: " + ("Trammel (no player killing)" if property.ruleset == "trammel" else "Felucca (open player-vs-player)"), _toggle_ruleset))
	settings_box.add_child(_info("Felucca: players may attack each other outside town (criminals and murderers face the guards). Trammel: players can't hurt each other at all, except guilds at war."))
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
