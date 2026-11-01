extends Node3D
## Third-person 3D view of the tile world, populated with the hero, other players, NPCs
## and monsters. Tap the ground to walk, tap a monster to attack it. With Auto on, the hero
## also acts by itself: wanders, fights monsters nearby and retreats to a healer when hurt.

const CAM_OFFSET := Vector3(0.0, 9.0, 7.0)
const MANUAL_PAUSE := 4.0      # seconds auto mode waits after a tap
const LOG_LINES := 6

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
var reset_button: Button
var reset_armed := false
var save_timer := 0.0
var skip_save := false


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
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_update_button()
	_build_menu(layer)
	_build_skills_panel(layer)
	_build_craft_panel(layer)

	if SaveGame.load_into(hero):
		log_event("Welcome back. Your progress was loaded.")
	else:
		log_event("Welcome to Shardsight. Tap a monster to attack it.")
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
	if SaveGame.save(hero):
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
		SaveGame.save(hero)


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
	_spawn(Entity.Kind.NPC, "Town Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(20, 11))
	_spawn(Entity.Kind.NPC, "Town Guard", Bestiary.GUARD, Color("9aa7b5"), Vector2i(28, 11))

	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(12, 8))
	_spawn(Entity.Kind.MONSTER, "Rat", Bestiary.RAT, red, Vector2i(6, 11))
	_spawn(Entity.Kind.MONSTER, "Wolf", Bestiary.WOLF, red, Vector2i(26, 18))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(27, 20))
	_spawn(Entity.Kind.MONSTER, "Orc", Bestiary.ORC, red, Vector2i(16, 20))
	_spawn(Entity.Kind.MONSTER, "Evil Mage", Bestiary.EVIL_MAGE, red, Vector2i(14, 22))


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
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("87a8c9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.76)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
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
				log_event("A guard strikes down %s." % e.display_name)
				e.take_damage(9999.0, guard)


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
	save_timer += delta
	if save_timer >= 20.0:
		save_timer = 0.0
		_autosave()
	for e in creatures:
		e.tick(delta)
	_guards_strike()
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
	hud.text = "Shardsight v%s   [%s]   %s\nHP %d/%d   Mana %d/%d   Reagents %d   Bandages %d   Gold %d\nStr %d  Dex %d  Int %d  (%d/%d)   Skills %.1f/%d (Menu > Skills)   Tile %d,%d\n%s\nBag: %s" % [
		version, hero.state_text(), hero.notoriety_text(), ceili(hero.hp), s.max_hp(), floori(hero.mana), s.max_mana(),
		floori(hero.reagents), hero.bandages, hero.gold,
		s.strength, s.dexterity, s.intelligence, s.stat_total(), Rules.STAT_CAP,
		s.skill_total(), Rules.SKILL_CAP_TOTAL, tile.x, tile.y, hero.gear_text(), bag_text]


func _follow_camera() -> void:
	cam.position = hero.position + CAM_OFFSET
	cam.look_at(hero.position + Vector3(0.0, 0.5, 0.0), Vector3.UP)
