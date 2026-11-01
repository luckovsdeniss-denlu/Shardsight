class_name Entity
extends Node3D
## A creature in the world: the hero, other players, NPCs and monsters.
## Players and monsters fight with the classic formulas in Rules; NPCs are peaceful.
## `game` is the main scene: it provides `world`, `creatures` and `log_event()`.

enum Kind { PLAYER, NPC, MONSTER }

const MELEE_RANGE := 1.5
const FLEE_HP := 0.35          # players retreat to a healer below this HP fraction
const RECOVER_HP := 0.9
const HEAL_RANGE := 2.5
const HEAL_PER_SEC := 4.0
const REGEN_PER_SEC := 0.4

var kind: int = Kind.PLAYER
var display_name := "?"
var stats := Hero.new()
var hp := 1.0
var speed := 3.0
var weapon_speed := 40
var dmg_min := 5.0
var dmg_max := 10.0
var armor := 0.0
var role := ""
var leash := 8
var aggro_range := 5.0
var respawn_time := 8.0
var ai_enabled := true         # for players: false = only obeys taps

var game
var world: World
var home := Vector3.ZERO
var target: Entity = null
var path: Array[Vector3] = []
var dead := false
var recovering := false
var dead_timer := 0.0
var swing_cd := 0.0
var idle_timer := 1.0
var pause := 0.0
var repath_timer := 0.0
var start_skills := {}
var label: Label3D
var _last_text := ""


func setup(p_game, p_kind: int, p_name: String, cfg: Dictionary, color: Color, tile: Vector2i) -> void:
	game = p_game
	world = p_game.world
	kind = p_kind
	display_name = p_name
	stats.strength = int(cfg.get("str", 20))
	stats.dexterity = int(cfg.get("dex", 20))
	stats.intelligence = int(cfg.get("int", 20))
	var skills: Dictionary = cfg.get("skills", {})
	for s in skills:
		stats.skills[s] = float(skills[s])
	start_skills = stats.skills.duplicate()
	weapon_speed = int(cfg.get("wspeed", 40))
	dmg_min = float(cfg.get("dmg_min", 1))
	dmg_max = float(cfg.get("dmg_max", 2))
	speed = float(cfg.get("move", 3.0))
	armor = float(cfg.get("armor", 0.0))
	role = String(cfg.get("role", ""))
	leash = int(cfg.get("leash", 8))
	aggro_range = float(cfg.get("aggro", 5.0))
	respawn_time = float(cfg.get("respawn", 8.0))
	_build_visual(color, float(cfg.get("scale", 1.0)))
	home = world.tile_center(tile)
	position = home
	hp = float(stats.max_hp())


func _build_visual(color: Color, s: float) -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	body.mesh = capsule
	body.material_override = World._mat(color)
	body.position = Vector3(0.0, 0.6 * s, 0.0)
	body.scale = Vector3.ONE * s
	add_child(body)
	# A small "nose" so the facing direction is visible.
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.16, 0.16, 0.28)
	nose.mesh = nose_mesh
	nose.material_override = World._mat(color.darkened(0.45))
	nose.position = Vector3(0.0, 0.95 * s, -0.32 * s)
	nose.scale = Vector3.ONE * s
	add_child(nose)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.008
	label.font_size = 40
	label.outline_size = 12
	label.no_depth_test = true
	label.modulate = color.lightened(0.35)
	label.position = Vector3(0.0, 1.5 * s + 0.25, 0.0)
	add_child(label)


func tick(delta: float) -> void:
	if dead:
		dead_timer -= delta
		if dead_timer <= 0.0:
			_respawn()
		return
	swing_cd = maxf(swing_cd - delta, 0.0)
	pause = maxf(pause - delta, 0.0)
	repath_timer -= delta
	hp = minf(hp + REGEN_PER_SEC * delta, float(stats.max_hp()))
	if role == "healer":
		_heal_aura(delta)
	_think(delta)
	_follow_path(delta)
	_fight()
	_refresh_label()


# --- decisions -------------------------------------------------------------

func _think(delta: float) -> void:
	if target != null and (not is_instance_valid(target) or target.dead):
		target = null
	var autonomous := kind != Kind.PLAYER or ai_enabled
	if kind == Kind.MONSTER:
		if target == null and pause <= 0.0:
			target = _nearest(Kind.PLAYER, aggro_range)
		elif target != null and position.distance_to(home) > leash + aggro_range * 1.5:
			target = null       # gave up: too far from its lair
			pause = 3.0
			go_to(home)
	elif kind == Kind.PLAYER and autonomous and pause <= 0.0:
		if _recover():
			return
		if target == null:
			target = _nearest(Kind.MONSTER, aggro_range)
	if target != null:
		_chase()
		return
	if autonomous and pause <= 0.0 and path.is_empty():
		idle_timer -= delta
		if idle_timer <= 0.0:
			_wander()
			idle_timer = randf_range(1.5, 4.0)


## Low on HP: stop fighting and walk to a healer. Returns true while recovering.
func _recover() -> bool:
	var max_hp := float(stats.max_hp())
	if hp < max_hp * FLEE_HP:
		recovering = true
	elif hp >= max_hp * RECOVER_HP:
		recovering = false
	if not recovering:
		return false
	target = null
	var healer := _find_role("healer")
	if healer != null and position.distance_to(healer.position) > 2.0 and path.is_empty():
		go_to(healer.position)
	return true


func _chase() -> void:
	if position.distance_to(target.position) > MELEE_RANGE:
		if repath_timer <= 0.0 or path.is_empty():
			repath_timer = 0.4
			var p: Array[Vector3] = world.find_path(position, target.position)
			path = p
	else:
		path.clear()
		_face(target.position - position)


func _wander() -> void:
	var center: Vector2i = world.to_tile(position if kind == Kind.PLAYER else home)
	for _i in range(12):
		var c := center + Vector2i(randi_range(-leash, leash), randi_range(-leash, leash))
		if c != center and go_to(world.tile_center(c)):
			return


## Walk to `dest`. Returns false if it is blocked or unreachable.
func go_to(dest: Vector3) -> bool:
	var p: Array[Vector3] = world.find_path(position, dest)
	if p.is_empty():
		return false
	path = p
	return true


func _nearest(k: int, max_dist: float) -> Entity:
	var best: Entity = null
	var best_d := max_dist
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == self or e.dead or e.kind != k:
			continue
		var d := position.distance_to(e.position)
		if d <= best_d:
			best = e
			best_d = d
	return best


func _find_role(r: String) -> Entity:
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.role == r and not e.dead:
			return e
	return null


# --- movement --------------------------------------------------------------

func _follow_path(delta: float) -> void:
	var budget := speed * delta
	while budget > 0.0 and not path.is_empty():
		var to_next := path[0] - position
		var dist := to_next.length()
		_face(to_next)
		if dist <= budget:
			position = path[0]
			path.remove_at(0)
			budget -= dist
		else:
			position += to_next / dist * budget
			budget = 0.0


func _face(v: Vector3) -> void:
	if v.length() > 0.001:
		rotation.y = atan2(-v.x, -v.z)


# --- combat ----------------------------------------------------------------

func _fight() -> void:
	if target == null or swing_cd > 0.0:
		return
	if position.distance_to(target.position) > MELEE_RANGE:
		return
	swing_cd = Rules.swing_seconds(stats.max_stamina(), weapon_speed)
	var atk: float = stats.skills.get(Hero.Skill.SWORDSMANSHIP, 0.0)
	var def: float = target.stats.skills.get(Hero.Skill.SWORDSMANSHIP, 0.0)
	if randf() < Rules.hit_chance(atk, def):
		var tactics: float = stats.skills.get(Hero.Skill.TACTICS, 0.0)
		var anatomy: float = stats.skills.get(Hero.Skill.ANATOMY, 0.0)
		var dmg := randf_range(dmg_min, dmg_max) * Rules.damage_multiplier(
			float(stats.strength), tactics, anatomy)
		target.take_damage(target._absorb(dmg), self)
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.SWORDSMANSHIP)
			stats.try_gain(Hero.Skill.TACTICS)
	else:
		target._pop("miss", Color(0.8, 0.8, 0.8))


## Armor soaks a random half-to-all of its rating, but a hit always does at least 1.
func _absorb(amount: float) -> float:
	if armor <= 0.0:
		return amount
	return maxf(1.0, amount - randf_range(0.5, 1.0) * armor)


func take_damage(amount: float, from: Entity) -> void:
	if dead or kind == Kind.NPC:
		return
	hp -= amount
	_pop("-%d" % maxi(1, roundi(amount)), Color(1.0, 0.45, 0.4))
	if target == null and not recovering:
		target = from                  # fight back
	if hp <= 0.0:
		_die(from)


func _die(killer: Entity) -> void:
	dead = true
	hp = 0.0
	target = null
	recovering = false
	path.clear()
	dead_timer = respawn_time
	visible = false
	game.log_event("%s was slain by %s" % [display_name, killer.display_name])


func _respawn() -> void:
	dead = false
	visible = true
	position = home
	hp = float(stats.max_hp())
	pause = 2.0
	swing_cd = 1.0
	if kind == Kind.PLAYER:
		# Instant resurrection: -10% to skills, never below the starting values.
		for s in stats.skills:
			stats.skills[s] = maxf(float(start_skills.get(s, 0.0)), float(stats.skills[s]) * 0.9)
		game.log_event("%s was resurrected (-10%% skills)" % display_name)


func _heal_aura(delta: float) -> void:
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.dead or e.kind == Kind.MONSTER:
			continue
		if position.distance_to(e.position) <= HEAL_RANGE:
			e.hp = minf(e.hp + HEAL_PER_SEC * delta, float(e.stats.max_hp()))


# --- feedback --------------------------------------------------------------

func state_text() -> String:
	if dead:
		return "dead"
	if target != null:
		return "fighting " + target.display_name
	if recovering:
		return "recovering"
	if not path.is_empty():
		return "walking"
	return "idle"


func _refresh_label() -> void:
	var text := "%s\nHP %d/%d" % [display_name, ceili(hp), stats.max_hp()]
	if kind == Kind.NPC:
		text = "%s\n(%s)" % [display_name, role]
	if text != _last_text:
		_last_text = text
		label.text = text


## Floating combat text that drifts up and vanishes.
func _pop(text: String, color: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.pixel_size = 0.01
	l.font_size = 48
	l.outline_size = 12
	l.no_depth_test = true
	get_parent().add_child(l)
	l.position = position + Vector3(0.0, 2.0, 0.0)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.9, 0.8)
	tw.tween_callback(l.queue_free)
