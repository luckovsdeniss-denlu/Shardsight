class_name Entity
extends Node3D
## A creature in the world: the hero, other players, NPCs and monsters.
## Players and monsters fight with the classic formulas in Rules; NPCs are peaceful.
## `game` is the main scene: it provides `world`, `creatures` and `log_event()`.

enum Kind { PLAYER, NPC, MONSTER, PET }   # PET: a tamed animal following its owner
enum Notoriety { BLUE, GREY, RED }   # innocent, criminal, murderer (monsters are always red)

const MELEE_RANGE := 1.5
const FLEE_HP := 0.45          # players retreat to a healer below this HP fraction
const YOUNG_SKILL_TOTAL := 200.0   # below this, a player is "young" and player killers leave them be
const RECOVER_HP := 0.9
const HEAL_RANGE := 2.5
const HEAL_PER_SEC := 4.0
const REGEN_PER_SEC := 0.4
const SPELL_RANGE := 7.0
const CAST_RECOVERY := 0.8     # seconds between casts
const LOOT_RANGE := 1.6
const LOOT_SEEK := 9.0         # how far players look for corpses
const REAGENT_PRICE := 2       # gold per reagent at the merchant
const MAX_REAGENTS := 60.0
const BANDAGE_PRICE := 2
const MAX_BANDAGES := 10
const MARKET_RANGE := 4.0          # the merchant trades with players this close
const GATHER_TIME := 2.0           # seconds per swing of the pickaxe or hatchet
const CARRY_MATERIALS := 30        # gatherers stop when carrying this many materials
const SWING_ANIM := 0.22           # seconds of the attack lunge
const STAMINA_REGEN := 0.4         # per second
const SWING_STAMINA := 0.6         # each swing tires you a little (slower swings when drained)
const POTION_DELAY := 8.0          # seconds between potions
const POTION_PRICE := 15
const MAX_PETS := 2
const TAME_TIME := 3.0             # seconds of coaxing per taming attempt
const PET_LEASH := 14.0            # pets drop a chase that strays this far from their owner
const TAME_COOLDOWN := 60.0        # Auto waits this long between taming attempts
const PERFORM_TIME := 2.0          # seconds of playing per bard performance
const BARD_COOLDOWN := 6.0
const BARD_RANGE := 8.0
const PEACE_SECONDS := 15.0
const ENTICE_SECONDS := 8.0
const LUTE_PRICE := 20
const ARROW_PRICE := 1
const TOOL_PRICE := 12
const TOOL_USES := 40              # a pickaxe, hatchet or tool kit lasts this many uses
const TOOLS := ["pickaxe", "hatchet", "tool_kit"]
const SUPPLY_RESERVE := 30         # gold kept back when restocking supplies at the merchant
const CRIMINAL_SECONDS := 60.0     # grey after attacking an innocent
const MURDER_WINDOW := 30.0        # an innocent dying this soon after your attack is a murder
const MURDER_DECAY := 180.0        # seconds for one murder count to fade
const MURDERER_COUNTS := 5         # this many counts turn you red
const BOUNTY_PER_COUNT := 25       # gold on a murderer's head, per count
const GHOST_TIMEOUT := 60.0        # a shrine raises ghosts after this long
const RED_GHOST_TIMEOUT := 30.0

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
var is_hero := false           # the player's own character (gets spell feedback in the log)

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
var mana := 0.0
var reagents := 0.0
var restocking := false
var casting_id := ""
var cast_timer := 0.0
var cast_target: Entity = null
var cast_cd := 0.0
var _med_timer := 0.0
var gold := 0
var inventory := {}            # trophy item id -> count
var loot_cfg := {}             # what a monster drops
var loot_target: Corpse = null
var weapon := ""               # equipped weapon id (see Gear); "" = bare hands
var armor_id := ""             # equipped armor id
var shield_id := ""            # equipped shield id (needs a free hand)
var bandages := 0
var bandage_timer := 0.0
var _gear_timer := 0.0
var _trade_timer := 0.0
var label: Label3D
var _last_text := ""
var body: MeshInstance3D
var nose: MeshInstance3D
var base_label_color := Color.WHITE
var murder_counts := 0
var murder_timer := 0.0
var criminal_timer := 0.0
var attackers := {}            # attacker instance id -> seconds left in which our death is murder
var is_pk := false             # a player killer: hunts innocent players in the wilderness
var danger := 1.0              # how tough a monster is (players compare it with their power)
var stamina := 0.0
var poison_level := 0          # 0 none, 1 lesser, 2 regular, 3 greater
var poison_time := 0.0
var poison_tick := 0.0
var poisoner: Entity = null
var poison_cfg := []           # [level, chance] if this creature poisons on hit
var potion_cd := 0.0
var poison_immune := 0.0       # seconds of grace after a cure, when no new poison takes hold
var last_poison_target: Entity = null
var cfg_ref := {}              # the stat block this creature was made from
var spawn_color := Color.WHITE
var species := ""              # tameable animals only
var tame_min := -1.0           # minimum Animal Taming to tame it (-1: can't be tamed)
var passive := false           # never starts a fight
var pet_owner: Entity = null       # for pets
var pets: Array[Entity] = []
var tame_target: Entity = null
var tame_timer := 0.0
var bandage_target: Entity = null
var shop: Shop = null          # merchants: their purse, shelves and town prices
var arrows := 0
var tool_uses := {}            # tool id -> uses left on the one in hand
var track_cd := 0.0
var camp_cd := 0.0
var beg_cd := {}               # NPC instance id -> msec until they can be asked again
var spirit_channel := false    # the current "bandage" timer is really Spirit Speak
var tame_cd := 0.0
var bard_cd := 0.0
var perform_timer := 0.0
var perform_kind := ""         # "peace", "provoke" or "entice"
var perform_a: Entity = null
var perform_b: Entity = null
var peaced_timer := 0.0        # calmed by Peacemaking: won't fight
var enticed_timer := 0.0       # lured by Enticement: walks to the bard
var enticer: Entity = null
var ghost := false
var died_red := false
var crafter := false           # gathers and crafts when idle (the hero)
var gather_tile := Vector2i(-1, -1)
var gather_timer := 0.0
var crafting_trip := false
var banking := false
var gate_cd := 0.0             # just came through a moongate: don't bounce straight back
var rig: Node3D                # body + nose, moved by the procedural animation
var anim_t := 0.0
var swing_anim := 0.0
var _last_pos := Vector3.ZERO


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
	cfg_ref = cfg
	spawn_color = color
	species = String(cfg.get("species", ""))
	tame_min = float(cfg.get("tame", -1.0))
	passive = bool(cfg.get("passive", false))
	_build_visual(color, float(cfg.get("scale", 1.0)))
	home = world.tile_center(tile)
	position = home
	hp = float(stats.max_hp())
	mana = float(stats.max_mana())
	reagents = float(cfg.get("reagents", 0))
	gold = int(cfg.get("gold", 0))
	loot_cfg = cfg.get("loot", {})
	weapon = String(cfg.get("weapon", ""))
	armor_id = String(cfg.get("wear", ""))
	shield_id = String(cfg.get("shield", ""))
	bandages = int(cfg.get("bandages", 0))
	is_pk = bool(cfg.get("pk", false))
	var start_bag: Dictionary = cfg.get("inventory", {})
	for k in start_bag:
		inventory[k] = int(start_bag[k])
	danger = float(cfg.get("danger", 1.0))
	poison_cfg = cfg.get("poison", [])
	stamina = float(stats.max_stamina())
	arrows = int(cfg.get("arrows", 0))
	crafter = bool(cfg.get("crafter", false))
	stats.skill_gained.connect(_on_skill_gained)
	stats.stat_gained.connect(_on_stat_gained)


func _build_visual(color: Color, s: float) -> void:
	rig = Node3D.new()
	add_child(rig)
	anim_t = randf() * 10.0          # so idle creatures don't breathe in lockstep
	body = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	body.mesh = capsule
	body.material_override = World._mat(color)
	body.position = Vector3(0.0, 0.6 * s, 0.0)
	body.scale = Vector3.ONE * s
	rig.add_child(body)
	# A small "nose" so the facing direction is visible.
	nose = MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.16, 0.16, 0.28)
	nose.mesh = nose_mesh
	nose.material_override = World._mat(color.darkened(0.45))
	nose.position = Vector3(0.0, 0.95 * s, -0.32 * s)
	nose.scale = Vector3.ONE * s
	rig.add_child(nose)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.008
	label.font_size = 40
	label.outline_size = 12
	label.no_depth_test = true
	base_label_color = color.lightened(0.35)
	label.modulate = base_label_color
	label.position = Vector3(0.0, 1.5 * s + 0.25, 0.0)
	add_child(label)


func tick(delta: float) -> void:
	_tick_reputation(delta)              # flags and counts keep fading even while dead
	if dead:
		if ghost:
			_ghost_tick(delta)
			_animate(delta)
		else:
			dead_timer -= delta
			if dead_timer <= 0.0:
				_respawn()
		return
	_animate(delta)
	gate_cd = maxf(gate_cd - delta, 0.0)
	swing_cd = maxf(swing_cd - delta, 0.0)
	cast_cd = maxf(cast_cd - delta, 0.0)
	pause = maxf(pause - delta, 0.0)
	repath_timer -= delta
	hp = minf(hp + REGEN_PER_SEC * delta, float(stats.max_hp()))
	_regen_mana(delta)
	stamina = minf(stamina + STAMINA_REGEN * delta, float(stats.max_stamina()))
	potion_cd = maxf(potion_cd - delta, 0.0)
	poison_immune = maxf(poison_immune - delta, 0.0)
	tame_cd = maxf(tame_cd - delta, 0.0)
	track_cd = maxf(track_cd - delta, 0.0)
	camp_cd = maxf(camp_cd - delta, 0.0)
	if game.near_campfire(position):
		hp = minf(hp + REGEN_PER_SEC * 3.0 * delta, float(stats.max_hp()))   # resting by a fire
	bard_cd = maxf(bard_cd - delta, 0.0)
	peaced_timer = maxf(peaced_timer - delta, 0.0)
	enticed_timer = maxf(enticed_timer - delta, 0.0)
	if poison_level > 0:
		_poison_step(delta)
		if dead:
			return
	if role == "healer":
		_heal_aura(delta)
	elif role == "merchant":
		_market_aura(delta)
	if casting_id != "":
		_cast_step(delta)
		_refresh_label()
		return
	if tame_timer > 0.0:
		_tame_channel(delta)
		_refresh_label()
		return
	if perform_timer > 0.0:
		_perform_channel(delta)
		_refresh_label()
		return
	if bandage_timer > 0.0:
		bandage_timer -= delta
		if bandage_timer <= 0.0:
			_finish_bandage()
		_refresh_label()
		return
	_gear_timer -= delta
	if _gear_timer <= 0.0:
		_gear_timer = 1.0
		if target == null:
			_manage_gear()
	_think(delta)
	_follow_path(delta)
	_fight()
	_refresh_label()


# --- decisions -------------------------------------------------------------

func _think(delta: float) -> void:
	if target != null and (not is_instance_valid(target) or target.dead or target.kind == Kind.NPC):
		target = null
	if kind == Kind.PET:
		_pet_think()
		return
	if kind == Kind.PLAYER and (_try_potion() or _try_bandage()):
		return
	var autonomous := kind != Kind.PLAYER or ai_enabled
	if kind == Kind.MONSTER:
		if enticed_timer > 0.0 and enticer != null and is_instance_valid(enticer) and not enticer.dead:
			target = null                    # lured: walk to the bard, no fighting
			if position.distance_to(enticer.position) > 1.6 and (repath_timer <= 0.0 or path.is_empty()):
				repath_timer = 0.5
				go_to(enticer.position)
			return
		if peaced_timer > 0.0:
			target = null                    # calmed by music
		elif target == null and pause <= 0.0:
			target = _pick_target()
		elif target != null and (target._in_town() or position.distance_to(home) > leash + aggro_range * 1.5):
			target = null       # gave up: prey fled into the guarded town, or too far from its lair
			pause = 3.0
			go_to(home)
	elif kind == Kind.PLAYER and autonomous and pause <= 0.0:
		if is_hero and _try_bard():
			return
		if _recover() or _resupply():
			return
		if target == null:
			target = _pick_target()
			# Lure a far-off monster away from its friends before fighting it.
			if is_hero and target != null and position.distance_to(target.position) > 4.0 \
					and randf() < 0.3 and bard_problem("entice") == "":
				start_perform("entice", target, null)
				target = null
				return
	if target != null:
		_chase()
		return
	if kind == Kind.PLAYER:
		if _loot_step():
			return
		if autonomous and pause <= 0.0 and _seek_loot():
			return
		if autonomous and pause <= 0.0 and crafter and _craft_trip():
			return
		if autonomous and pause <= 0.0 and is_hero and _bank_trip():
			return
		if _tame_step():
			return
		if _gather_step(delta):
			return
	if autonomous and pause <= 0.0 and path.is_empty():
		idle_timer -= delta
		if idle_timer <= 0.0:
			if kind == Kind.PLAYER and (_try_camp() or _try_beg()):
				idle_timer = randf_range(1.5, 4.0)
				return
			if not (crafter and randf() < 0.5 and _start_gathering_nearby()) \
					and not (is_hero and randf() < 0.3 and _start_taming_nearby()) \
					and not (kind == Kind.PLAYER and not crafter and randf() < 0.5 and _track_hunt()):
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
	if casting_id == "" and cast_cd <= 0.0:
		var heal_id := _best_spell("heal")
		if heal_id != "":
			start_cast(heal_id, self)
			return true
	var healer := _nearest_role("healer")
	if healer != null and position.distance_to(healer.position) > 2.0 and path.is_empty():
		go_to(healer.position)
	return true


func _chase() -> void:
	var reach := attack_range()
	if (kind != Kind.PLAYER or ai_enabled) and _best_spell("attack") != "":
		reach = maxf(reach, SPELL_RANGE)   # casters keep their distance
	if position.distance_to(target.position) > reach:
		if repath_timer <= 0.0 or path.is_empty():
			repath_timer = 0.4
			var p: Array[Vector3] = world.find_path(position, target.position, _avoids_town())
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
	var p: Array[Vector3] = world.find_path(position, dest, _avoids_town())
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
	if target == null or peaced_timer > 0.0 or enticed_timer > 0.0:
		return
	var d := position.distance_to(target.position)
	if (kind != Kind.PLAYER or ai_enabled) and _try_auto_cast(d):
		return
	if swing_cd > 0.0 or d > attack_range():
		return
	var ws := weapon_speed
	var lo := dmg_min
	var hi := dmg_max
	var wielded := _wielded()
	if wielded != "":
		var w: Dictionary = Gear.stats(wielded)
		ws = int(w["speed"])
		lo = float(w["min"])
		hi = float(w["max"])
		if Gear.is_ranged(wielded):
			arrows -= 1
			_bolt(target.position, Color(0.85, 0.75, 0.5))
	elif kind == Kind.PLAYER:
		lo = 1.0                           # bare hands
		hi = 4.0
	swing_cd = Rules.swing_seconds(maxi(1, int(stamina)), ws)   # tired fighters swing slower
	stamina = maxf(stamina - SWING_STAMINA, 0.0)
	swing_anim = SWING_ANIM
	var skill := _weapon_skill()
	var atk := _skill(skill)
	var def := target._skill(target._weapon_skill())
	if randf() < Rules.hit_chance(atk, def):
		var tactics: float = stats.skills.get(Hero.Skill.TACTICS, 0.0)
		var anatomy: float = stats.skills.get(Hero.Skill.ANATOMY, 0.0)
		var dmg := randf_range(lo, hi) * Rules.damage_multiplier(
			float(stats.strength), tactics, anatomy)
		var dealt := target._absorb(dmg)
		if is_hero:
			game.count("hero_hits")
			game.count("hero_dmg_dealt", roundi(dealt))
		elif target.is_hero:
			game.count("hero_dmg_taken_melee", roundi(dealt))
		target.take_damage(dealt, self)
		if poison_cfg.size() == 2 and not target.dead and randf() < float(poison_cfg[1]):
			target.apply_poison(int(poison_cfg[0]), self)
		if kind == Kind.PLAYER:
			stats.try_gain(skill)
			stats.try_gain(Hero.Skill.TACTICS)
	else:
		if is_hero:
			game.count("hero_misses")
		target._pop("miss", Color(0.8, 0.8, 0.8))


## Armor soaks a random half-to-all of its rating, but a hit always does at least 1.
func _absorb(amount: float) -> float:
	if shield_id != "":
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.PARRYING)     # every attack at a shield-bearer trains it
		if randf() < Rules.parry_chance(_skill(Hero.Skill.PARRYING)):
			amount *= 1.0 - float(Gear.stats(shield_id)["block"])
			_pop("parried", Color(0.8, 0.9, 1.0))
	var rating := _armor_rating()
	if rating <= 0.0:
		return amount
	return maxf(1.0, amount - randf_range(0.5, 1.0) * rating)


## Natural armor (monster hide) plus whatever is worn.
func _armor_rating() -> float:
	var worn := 0.0
	if armor_id != "":
		worn = float(Gear.stats(armor_id)["rating"])
	return armor + worn


func take_damage(amount: float, from: Entity) -> void:
	if dead or kind == Kind.NPC:
		return
	# Hitting an innocent player makes the attacker a criminal and, if the victim dies soon
	# after, a murderer. The victim can fight back freely.
	if from.kind == Kind.PLAYER and kind == Kind.PLAYER and notoriety() == Notoriety.BLUE:
		from.criminal_timer = CRIMINAL_SECONDS
		var aid := from.get_instance_id()
		if not attackers.has(aid):
			game.log_event("%s attacks %s!" % [from.display_name, display_name])
		attackers[aid] = MURDER_WINDOW
	hp -= amount
	if peaced_timer > 0.0 or (enticed_timer > 0.0 and from == enticer):
		peaced_timer = 0.0                   # a blow breaks the spell of the music
		enticed_timer = 0.0
	game.sound("hit", position)
	if casting_id != "":
		_fizzle("disrupted")      # taking damage breaks a spell in progress
	if bandage_timer > 0.0:
		bandage_timer = 0.0
		_pop("interrupted", Color(0.75, 0.75, 0.75))
	if tame_timer > 0.0:
		tame_timer = 0.0
		tame_target = null
		_pop("interrupted", Color(0.75, 0.75, 0.75))
	_pop("-%d" % maxi(1, roundi(amount)), Color(1.0, 0.45, 0.4))
	if target == null and not recovering:
		target = from                  # fight back
	if hp <= 0.0:
		_die(from)


func _die(killer: Entity) -> void:
	dead = true
	hp = 0.0
	poison_level = 0
	casting_id = ""
	bandage_timer = 0.0
	loot_target = null
	target = null
	recovering = false
	path.clear()
	gather_tile = Vector2i(-1, -1)
	crafting_trip = false
	banking = false
	died_red = kind == Kind.PLAYER and notoriety() == Notoriety.RED
	_settle_crimes(killer)
	game.spawn_corpse(self)
	game.log_event("%s was slain by %s" % [display_name, killer.display_name])
	game.on_kill(killer, self)
	if is_hero:
		game.count("hero_deaths")
		game.count("hero_killed_by_" + killer.display_name)
	game.sound("death", position)
	if kind == Kind.PLAYER:
		ghost = true                   # players become ghosts and look for a healer
		dead_timer = RED_GHOST_TIMEOUT if died_red else GHOST_TIMEOUT
		_set_ghost_look(true)
	elif kind == Kind.PET:
		dead_timer = INF                 # a dead pet is gone for good
		visible = false
		game.on_pet_died(self)
	else:
		dead_timer = respawn_time
		visible = false


func _respawn() -> void:
	dead = false
	ghost = false
	_set_ghost_look(false)
	visible = true
	position = home
	hp = float(stats.max_hp())
	mana = float(stats.max_mana())
	pause = 2.0
	swing_cd = 1.0
	if kind == Kind.PLAYER:
		# Raised at a shrine: -10% to skills (-20% to stats and skills for murderers),
		# never below the starting values.
		var keep := 0.8 if died_red else 0.9
		for s in stats.skills:
			stats.skills[s] = maxf(float(start_skills.get(s, 0.0)), float(stats.skills[s]) * keep)
		if died_red:
			for st in [Hero.Stat.STR, Hero.Stat.DEX, Hero.Stat.INT]:
				stats.set_stat(st, maxi(Rules.STAT_MIN, roundi(stats.get_stat(st) * 0.8)))
			game.log_event("%s was raised at a shrine (murderer: -20%% stats and skills)." % display_name)
		else:
			game.log_event("%s was raised at a shrine (-10%% skills)." % display_name)
	died_red = false


func _heal_aura(delta: float) -> void:
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.dead or e.kind == Kind.MONSTER:
			continue
		if e.kind == Kind.PLAYER and e.notoriety() == Notoriety.RED:
			continue                       # healers shun murderers
		if position.distance_to(e.position) <= HEAL_RANGE:
			e.hp = minf(e.hp + HEAL_PER_SEC * delta, float(e.stats.max_hp()))


# --- feedback --------------------------------------------------------------

func state_text() -> String:
	if dead:
		return "ghost" if ghost else "dead"
	if casting_id != "":
		return "casting " + String(Spells.LIST[casting_id]["name"])
	if perform_timer > 0.0:
		return "playing " + perform_kind
	if tame_timer > 0.0 or tame_target != null:
		return "taming"
	if bandage_timer > 0.0:
		return "bandaging"
	if target != null:
		return "fighting " + target.display_name
	if loot_target != null:
		return "looting"
	if target == null and gather_tile.x >= 0:
		return "mining" if world.resource_kind(gather_tile) == "ore" else "chopping wood"
	if target == null and crafting_trip:
		return "going to the forge"
	if target == null and banking:
		return "going to the bank"
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
	elif kind == Kind.PET:
		text += "\n(%s's pet)" % (pet_owner.display_name if pet_owner != null else "a")
	elif ghost:
		text = "%s\n(ghost)" % display_name
	elif kind == Kind.PLAYER and notoriety() == Notoriety.RED:
		text += " (murderer)"
	elif kind == Kind.PLAYER and notoriety() == Notoriety.GREY:
		text += " (criminal)"
	if poison_level > 0 and not ghost:
		text += "\n(poisoned)"
	label.modulate = _name_color()
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


# --- magery ----------------------------------------------------------------

func _skill(s: int) -> float:
	return float(stats.skills.get(s, 0.0))


func can_cast(id: String) -> bool:
	if dead or casting_id != "":
		return false
	var sp: Dictionary = Spells.LIST[id]
	return mana >= float(sp["mana"]) and reagents >= float(sp["reagents"]) \
		and _skill(Hero.Skill.MAGERY) >= float(sp["min"])


func _why_not(id: String) -> String:
	var sp: Dictionary = Spells.LIST[id]
	if _skill(Hero.Skill.MAGERY) < float(sp["min"]):
		return "Your Magery is too low for %s." % sp["name"]
	if mana < float(sp["mana"]):
		return "Not enough mana."
	return "Not enough reagents."


## Begin casting. Mana and reagents are spent up front, as in the classic game.
func start_cast(id: String, tgt: Entity) -> bool:
	if dead or casting_id != "" or cast_cd > 0.0 or tgt == null:
		return false
	if not can_cast(id):
		if is_hero:
			game.log_event(_why_not(id))
		return false
	if tgt != self and position.distance_to(tgt.position) > SPELL_RANGE:
		if is_hero:
			game.log_event("That is too far away.")
		return false
	var sp: Dictionary = Spells.LIST[id]
	mana -= float(sp["mana"])
	reagents -= float(sp["reagents"])
	casting_id = id
	cast_target = tgt
	cast_timer = 0.5 + 0.25 * float(sp["circle"])
	path.clear()
	_pop(String(sp["words"]), Color(0.7, 0.85, 1.0))
	game.sound("cast", position)
	if is_hero:
		game.count("spells_cast")
	return true


## Used by the on-screen spell buttons. Attack spells pick the current or nearest monster.
func cast_manual(id: String) -> void:
	var sp: Dictionary = Spells.LIST[id]
	var tgt: Entity = self
	if String(sp["kind"]) == "attack":
		tgt = target if target != null else _nearest(Kind.MONSTER, SPELL_RANGE)
		if tgt == null:
			game.log_event("No target in range.")
			return
		target = tgt
	start_cast(id, tgt)


func _cast_step(delta: float) -> void:
	cast_timer -= delta
	if cast_target != null and cast_target != self:
		_face(cast_target.position - position)
	if cast_timer <= 0.0:
		_finish_cast()


func _fizzle(reason: String) -> void:
	casting_id = ""
	cast_target = null
	cast_cd = CAST_RECOVERY
	_pop(reason, Color(0.75, 0.75, 0.75))


func _finish_cast() -> void:
	var id := casting_id
	var sp: Dictionary = Spells.LIST[casting_id]
	var tgt := cast_target
	casting_id = ""
	cast_target = null
	cast_cd = CAST_RECOVERY
	if tgt == null or tgt.dead or (tgt != self and position.distance_to(tgt.position) > SPELL_RANGE + 1.0):
		_pop("fizzle", Color(0.75, 0.75, 0.75))
		return
	if randf() >= Rules.cast_chance(_skill(Hero.Skill.MAGERY), float(sp["min"])):
		_pop("fizzle", Color(0.75, 0.75, 0.75))
		return
	var spell_kind := String(sp["kind"])
	if spell_kind == "cure":
		if randf() < Rules.cure_chance(_skill(Hero.Skill.MAGERY), poison_level):
			_cure("cured")
		else:
			_pop("cure failed", Color(0.75, 0.75, 0.75))
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.MAGERY)
		return
	if spell_kind == "poison":
		if randf() < Rules.resist_chance(tgt._skill(Hero.Skill.RESISTING_SPELLS)):
			tgt._pop("resisted", Color(0.7, 0.9, 1.0))
		else:
			tgt.apply_poison(Rules.spell_poison_level(_skill(Hero.Skill.MAGERY)), self)
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.MAGERY)
		return
	if spell_kind == "travel" or spell_kind == "area":
		if spell_kind == "travel":
			_travel(id)
		else:
			_area_blast(sp)
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.MAGERY)
		return
	var amount := randf_range(float(sp["min_dmg"]), float(sp["max_dmg"]))
	if String(sp["kind"]) == "heal":
		tgt.hp = minf(tgt.hp + amount, float(tgt.stats.max_hp()))
		tgt._pop("+%d" % roundi(amount), Color(0.5, 1.0, 0.5))
	else:
		_bolt(tgt.position, sp["color"])
		amount *= Rules.spell_damage_multiplier(_skill(Hero.Skill.EVALUATING_INTELLECT))
		if randf() < Rules.resist_chance(tgt._skill(Hero.Skill.RESISTING_SPELLS)):
			amount *= 0.5
			tgt._pop("resisted", Color(0.7, 0.9, 1.0))
			if tgt.kind == Kind.PLAYER:
				tgt.stats.try_gain(Hero.Skill.RESISTING_SPELLS)
		tgt.take_damage(amount, self)
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.EVALUATING_INTELLECT)
	if kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.MAGERY)


## Heals itself when hurt, otherwise casts the best affordable attack spell in range.
func _try_auto_cast(d: float) -> bool:
	if casting_id != "" or cast_cd > 0.0:
		return false
	if poison_level > 0:
		var cure_id := _best_spell("cure")
		if cure_id != "":
			return start_cast(cure_id, self)
	# Poison is an opener: cast once at a new target, then move on to damage spells.
	if target != null and target != last_poison_target and target.poison_level == 0 and d <= SPELL_RANGE:
		var poison_id := _best_spell("poison")
		if poison_id != "":
			last_poison_target = target
			return start_cast(poison_id, target)
	if hp < float(stats.max_hp()) * 0.5:
		var heal_id := _best_spell("heal")
		if heal_id != "":
			return start_cast(heal_id, self)
	if _count_fair_targets(Spells.AREA_RADIUS) >= 2:
		var area_id := _best_spell("area")
		if area_id != "":
			return start_cast(area_id, self)
	if d <= SPELL_RANGE:
		var attack_id := _best_spell("attack")
		if attack_id != "":
			return start_cast(attack_id, target)
	return false


## Best affordable spell of a kind: highest expected effect per mana, ignoring long shots.
func _best_spell(k: String) -> String:
	var best := ""
	var best_score := 0.0
	var magery := _skill(Hero.Skill.MAGERY)
	for id in Spells.ORDER:
		var sp: Dictionary = Spells.LIST[id]
		if String(sp["kind"]) != k or not can_cast(id):
			continue
		var chance := Rules.cast_chance(magery, float(sp["min"]))
		if chance < 0.2:
			continue
		var avg := maxf((float(sp["min_dmg"]) + float(sp["max_dmg"])) / 2.0, 1.0)   # cure/poison: no damage
		var score := chance * avg / float(sp["mana"])
		if score > best_score:
			best_score = score
			best = id
	return best


func _regen_mana(delta: float) -> void:
	var metal := Gear.is_metal(armor_id) or Gear.is_metal(shield_id)   # metal kills Meditation
	var resting := path.is_empty() and target == null and casting_id == "" and not metal
	var max_mana := float(stats.max_mana())
	var med := 0.0 if metal else _skill(Hero.Skill.MEDITATION)
	mana = minf(mana + Rules.mana_regen(med, resting) * delta, max_mana)
	if resting and mana < max_mana and kind == Kind.PLAYER:
		_med_timer += delta
		if _med_timer >= 1.0:
			_med_timer = 0.0
			stats.try_gain(Hero.Skill.MEDITATION)   # resting while drained trains Meditation


## Mages walk to the merchant when their reagents run low.
func _resupply() -> bool:
	if _skill(Hero.Skill.MAGERY) < 0.1:
		return false
	# Only go if the merchant will actually sell (he keeps the supply reserve in mind),
	# otherwise the trip would never end.
	var affordable := gold >= REAGENT_PRICE * 2 + SUPPLY_RESERVE
	if reagents < 3.0 and affordable:
		restocking = true
	elif reagents >= 15.0 or not affordable:
		restocking = false
	if not restocking:
		return false
	target = null
	var m := _find_role("merchant")
	if m != null and position.distance_to(m.position) > 2.0 and path.is_empty():
		go_to(m.position)
	return true


## The merchant buys trophies and sells reagents to players standing nearby.
func _market_aura(delta: float) -> void:
	var list: Array = game.creatures
	for item in list:
		var other := item as Entity
		if other.dead or other.kind != Kind.PLAYER:
			continue
		if position.distance_to(other.position) <= MARKET_RANGE and shop != null:
			other.trade(delta, shop)


func trade(delta: float, s: Shop) -> void:
	if notoriety() != Notoriety.BLUE:
		return                             # criminals and murderers are refused service
	var earned := 0
	for id in inventory.keys():
		if _is_usable_upgrade(id):
			continue                       # keep gear we are about to wear
		if Items.is_potion(id) or Items.is_instrument(id):
			continue                       # potions are kept for emergencies
		if crafter and Items.is_material(id):
			continue                       # crafters keep their ore, ingots, logs and hides
		if Items.is_tool(id) or (id == "log" and int(inventory[id]) <= 2):
			continue                       # tools, and a couple of logs for a campfire
		# The merchant pays less the more it already holds, and stops when overstocked or broke.
		var n := int(inventory[id])
		var sold := 0
		while sold < n:
			var p := s.buy_from_player(id)
			if p <= 0:
				break
			earned += p + _appraise(id, p)
			sold += 1
		if sold >= n:
			inventory.erase(id)
		elif sold > 0:
			inventory[id] = n - sold
	if earned > 0:
		_earn(earned)
		if is_hero:
			game.log_event("You sell your spare loot in %s for %d gold." % [s.town, earned])
	_trade_timer += delta
	if _trade_timer >= 0.5:
		_trade_timer = 0.0
		# Restock only what is short, and never dip into the reserve (except for a last
		# couple of bandages).
		var lute := s.price(LUTE_PRICE)
		var potion := s.price(POTION_PRICE)
		var bandage := s.price(BANDAGE_PRICE)
		var reagent_pair := s.price(REAGENT_PRICE * 2)
		if is_hero and not has_instrument() and gold >= lute + SUPPLY_RESERVE:
			_pay(s, lute)
			inventory["lute"] = 1
			game.log_event("You buy a lute.")
		if Crafting.count(inventory, "potion_heal") < 1 and gold >= potion + SUPPLY_RESERVE:
			_pay(s, potion)
			inventory["potion_heal"] = 1
		elif poison_level > 0 and Crafting.count(inventory, "potion_cure") < 1 and gold >= potion + SUPPLY_RESERVE:
			_pay(s, potion)
			inventory["potion_cure"] = 1
		if (bandages < 6 and gold >= bandage + SUPPLY_RESERVE) or (bandages < 2 and gold >= bandage):
			_pay(s, bandage)
			bandages += 1
		if reagents < 20.0 and gold >= reagent_pair + SUPPLY_RESERVE:
			_pay(s, reagent_pair)
			reagents = minf(reagents + 2.0, MAX_REAGENTS)
		var arrow_pack := s.price(ARROW_PRICE * 10)
		if _wants_arrows() and arrows < 30 and gold >= arrow_pack + SUPPLY_RESERVE:
			_pay(s, arrow_pack)
			arrows += 10
		for tool in _needed_tools():
			var tp := s.price(TOOL_PRICE)
			if gold >= tp + SUPPLY_RESERVE:
				_pay(s, tp)
				inventory[tool] = 1
				tool_uses[tool] = TOOL_USES
				if is_hero:
					game.log_event("You buy a %s." % Items.item_name(tool))
		_buy_gear(s)


func _bolt(to: Vector3, color: Color) -> void:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.15
	s.height = 0.3
	m.mesh = s
	m.material_override = World._mat(color)
	get_parent().add_child(m)
	m.position = position + Vector3(0.0, 1.0, 0.0)
	var tw := m.create_tween()
	tw.tween_property(m, "position", to + Vector3(0.0, 1.0, 0.0), 0.25)
	tw.tween_callback(m.queue_free)


# --- looting ---------------------------------------------------------------

## What this creature leaves in its corpse. Monsters roll their loot table;
## players lose all gold and trophies and half their reagents.
func make_loot() -> Dictionary:
	var items := {}
	var dropped_gold := 0
	var dropped_reagents := 0
	if kind == Kind.MONSTER:
		dropped_gold = randi_range(int(loot_cfg.get("gold_min", 0)), int(loot_cfg.get("gold_max", 0)))
		dropped_reagents = randi_range(0, int(loot_cfg.get("reagents", 0)))
		for d in loot_cfg.get("drops", []):
			if randf() < float(d[1]):
				items[d[0]] = int(items.get(d[0], 0)) + 1
	elif kind == Kind.PLAYER:
		dropped_gold = gold
		gold = 0
		dropped_reagents = floori(reagents / 2.0)
		reagents -= dropped_reagents
		items = inventory.duplicate()
		inventory.clear()
	return {"gold": dropped_gold, "reagents": dropped_reagents, "items": items}


## Walk to a corpse and loot it (used for taps; AI players choose corpses themselves).
func start_looting(c: Corpse) -> void:
	loot_target = c
	target = null


## Returns true while walking to or looting a corpse.
func _loot_step() -> bool:
	if loot_target == null:
		return false
	if not is_instance_valid(loot_target) or loot_target.is_empty():
		loot_target = null
		return false
	if position.distance_to(loot_target.position) > LOOT_RANGE:
		if path.is_empty() and not go_to(loot_target.position):
			loot_target = null        # unreachable
			return false
		return true
	path.clear()
	_take(loot_target)
	loot_target = null
	return true


func _take(c: Corpse) -> void:
	var got: Dictionary = c.take_all()
	_earn(int(got["gold"]))
	reagents = minf(reagents + float(got["reagents"]), MAX_REAGENTS)
	var parts: Array[String] = []
	if int(got["gold"]) > 0:
		parts.append("%d gold" % int(got["gold"]))
	if int(got["reagents"]) > 0:
		parts.append("%d reagents" % int(got["reagents"]))
	var found: Dictionary = got["items"]
	for id in found:
		inventory[id] = int(inventory.get(id, 0)) + int(found[id])
		parts.append("%s x%d" % [Items.item_name(id), int(found[id])])
	if is_hero and not parts.is_empty():
		game.log_event("You loot: " + ", ".join(parts))
		game.sound("loot", position)
		game.count("loot")


## Picks the nearest corpse worth looting, unless a monster is close.
func _seek_loot() -> bool:
	if _nearest(Kind.MONSTER, 4.0) != null:
		return false
	var best: Corpse = null
	var best_d := LOOT_SEEK
	var list: Array = game.corpses
	for item in list:
		var c := item as Corpse
		if c.is_empty() or not c.can_loot(self):
			continue
		var d := position.distance_to(c.position)
		if d <= best_d:
			best = c
			best_d = d
	if best == null:
		return false
	loot_target = best
	return true


# --- equipment -------------------------------------------------------------

func _can_use(id: String) -> bool:
	if stats.strength < int(Gear.stats(id)["str"]):
		return false
	# Mages stay in cloth: metal armor would ruin their Meditation.
	if Gear.is_metal(id) and _skill(Hero.Skill.MAGERY) >= 30.0:
		return false
	# Two-handed weapons and shields are mutually exclusive.
	var g: Dictionary = Gear.stats(id)
	if String(g["slot"]) == "shield" and weapon != "" and bool(Gear.stats(weapon).get("two_handed", false)):
		return false
	if bool(g.get("two_handed", false)) and shield_id != "":
		return false
	return true


func _is_usable_upgrade(id: String) -> bool:
	if not Gear.has(id) or not _can_use(id):
		return false
	return _slot_value(id) > _equipped_score(String(Gear.stats(id)["slot"])) + 0.01


func _equipped_id(slot: String) -> String:
	match slot:
		"weapon":
			return weapon
		"shield":
			return shield_id
		_:
			return armor_id


func _equipped_score(slot: String) -> float:
	return _slot_value(_equipped_id(slot))


## How good a piece is for THIS character: a weapon counts for little without its skill, and a
## bow needs arrows.
func _slot_value(id: String) -> float:
	if not Gear.has(id):
		return 0.0
	var g := Gear.stats(id)
	if String(g["slot"]) != "weapon":
		return Gear.score(id)
	if Gear.is_ranged(id) and arrows < 5:
		return 0.0
	return Gear.score(id) * (0.4 + _skill(skill_for(String(g["skill"]))) / 100.0)


## Equips any carried piece that beats what is worn (and the old piece goes into the bag).
func _manage_gear() -> void:
	for id in inventory.keys():
		if _is_usable_upgrade(id):
			_equip(id)


func _equip(id: String) -> void:
	var slot := String(Gear.stats(id)["slot"])
	var old := _equipped_id(slot)
	inventory[id] = int(inventory.get(id, 0)) - 1
	if int(inventory[id]) <= 0:
		inventory.erase(id)
	match slot:
		"weapon":
			weapon = id
		"shield":
			shield_id = id
		_:
			armor_id = id
	if old != "":
		inventory[old] = int(inventory.get(old, 0)) + 1
	if is_hero:
		game.log_event("You equip the %s." % Items.item_name(id))


## At the merchant: buy the best usable upgrade we can afford, keeping a little gold spare.
func _pay(s: Shop, amount: int) -> void:
	_spend(amount)
	s.take_payment(amount)


func _buy_gear(s: Shop) -> void:
	var best := ""
	var best_gain := 0.0
	for id in Gear.ORDER:
		var g: Dictionary = Gear.stats(id)
		var price := s.price(int(g["value"]))
		if price + 8 > gold or not _can_use(id) or inventory.has(id):
			continue
		var gain := _slot_value(id) - _equipped_score(String(g["slot"]))
		if gain > best_gain:
			best_gain = gain
			best = id
	if best == "":
		return
	var cost := s.price(int(Gear.stats(best)["value"]))
	_pay(s, cost)
	inventory[best] = int(inventory.get(best, 0)) + 1
	_manage_gear()
	if is_hero:
		game.log_event("You buy a %s for %d gold." % [Items.item_name(best), cost])


func gear_text() -> String:
	var w := "fists"
	if weapon != "":
		var g: Dictionary = Gear.stats(weapon)
		w = "%s %d-%d" % [g["name"], int(g["min"]), int(g["max"])]
	var a := "none"
	if armor_id != "":
		a = "%s (AR %d)" % [Gear.stats(armor_id)["name"], int(Gear.stats(armor_id)["rating"])]
	var s := "none"
	if shield_id != "":
		s = String(Gear.stats(shield_id)["name"])
	return "Weapon: %s   Armor: %s   Shield: %s" % [w, a, s]


# --- healing ---------------------------------------------------------------

## Players bandage themselves when hurt and no monster is close. Bandages take a few seconds
## (faster with Healing) and are interrupted by taking damage.
func _try_bandage() -> bool:
	if bandages <= 0:
		return _try_spirit_speak()
	if casting_id != "" or bandage_timer > 0.0:
		return false
	if _nearest(Kind.MONSTER, 2.5) != null:
		return false
	var can_cure := poison_level > 0 and Rules.bandage_can_cure(_skill(Hero.Skill.HEALING), _skill(Hero.Skill.ANATOMY))
	bandage_target = null
	if hp < float(stats.max_hp()) * 0.6 or can_cure:
		bandage_target = self
	else:
		for p in pets:                       # Veterinary: patch up a hurt pet close by
			if not p.dead and p.hp < float(p.stats.max_hp()) * 0.6 and position.distance_to(p.position) <= 2.0:
				bandage_target = p
				break
	if bandage_target == null:
		return false
	bandages -= 1
	spirit_channel = false
	var skill: int = Hero.Skill.HEALING if bandage_target == self else Hero.Skill.VETERINARY
	bandage_timer = maxf(2.0, 5.0 - _skill(skill) / 40.0)
	path.clear()
	_pop("bandaging", Color(0.6, 1.0, 0.6))
	return true


func _finish_bandage() -> void:
	if spirit_channel:
		spirit_channel = false
		_finish_spirit_speak()
		return
	if bandage_target != null and bandage_target != self:
		_finish_vet(bandage_target)
		return
	var healing := _skill(Hero.Skill.HEALING)
	var anatomy := _skill(Hero.Skill.ANATOMY)
	if poison_level > 0 and Rules.bandage_can_cure(healing, anatomy) and randf() < Rules.bandage_chance(healing):
		_cure("cured")                 # a skilled healer's bandage draws out the poison
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.HEALING)
			stats.try_gain(Hero.Skill.ANATOMY)
	elif randf() < Rules.bandage_chance(healing):
		var amount := Rules.bandage_heal(healing, anatomy)
		hp = minf(hp + amount, float(stats.max_hp()))
		_pop("+%d" % roundi(amount), Color(0.5, 1.0, 0.5))
		if is_hero:
			game.count("bandaged")
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.HEALING)
			stats.try_gain(Hero.Skill.ANATOMY)
	else:
		_pop("bandage failed", Color(0.75, 0.75, 0.75))


func _on_skill_gained(skill_name: String, value: float) -> void:
	if is_hero:
		game.log_event("Your %s increases to %.1f." % [skill_name, value])
		game.sound("gain", position)


func _on_stat_gained(stat_name: String, value: int) -> void:
	if is_hero:
		game.log_event("Your %s increases to %d." % [stat_name, value])


# --- reputation ------------------------------------------------------------

## Blue = innocent, grey = criminal (attacked an innocent recently), red = murderer
## (five murder counts) or a monster.
func notoriety() -> int:
	if kind == Kind.MONSTER:
		return Notoriety.RED
	if kind == Kind.PLAYER:
		if murder_counts >= MURDERER_COUNTS:
			return Notoriety.RED
		if criminal_timer > 0.0:
			return Notoriety.GREY
	return Notoriety.BLUE


func notoriety_text() -> String:
	match notoriety():
		Notoriety.RED:
			return "Murderer (%d)" % murder_counts
		Notoriety.GREY:
			return "Criminal (%d)" % murder_counts
	return ("Innocent, young (%d)" if is_young() else "Innocent (%d)") % murder_counts


func _name_color() -> Color:
	if kind == Kind.PLAYER:
		match notoriety():
			Notoriety.RED:
				return Color(1.0, 0.3, 0.3)
			Notoriety.GREY:
				return Color(0.75, 0.75, 0.75)
	return base_label_color


func _tick_reputation(delta: float) -> void:
	criminal_timer = maxf(criminal_timer - delta, 0.0)
	if murder_counts > 0:
		murder_timer -= delta
		if murder_timer <= 0.0:
			murder_counts -= 1             # counts fade while you behave
			murder_timer = MURDER_DECAY
	for id in attackers.keys():
		attackers[id] = float(attackers[id]) - delta
		if float(attackers[id]) <= 0.0:
			attackers.erase(id)


func _add_murder(victim: Entity) -> void:
	murder_counts += 1
	murder_timer = MURDER_DECAY
	game.log_event("%s is guilty of murdering %s." % [display_name, victim.display_name])
	if murder_counts == MURDERER_COUNTS:
		game.log_event("%s is now a murderer!" % display_name)


## On death: pay the bounty on a murderer and charge anyone who recently hit an innocent us.
func _settle_crimes(killer: Entity) -> void:
	if died_red and killer.kind == Kind.PLAYER and murder_counts > 0:
		var bounty := murder_counts * BOUNTY_PER_COUNT
		killer._earn(bounty)
		if killer.is_hero:
			game.count("bounties")
		game.log_event("%s collects a %d gold bounty on %s." % [killer.display_name, bounty, display_name])
	for id in attackers.keys():
		var a := instance_from_id(int(id)) as Entity
		if a != null and not a.dead:
			a._add_murder(self)
	attackers.clear()


func _in_town() -> bool:
	return world.is_town(world.to_tile(position))


## Monsters, criminals and murderers keep out of the guarded town (the guards would kill them).
## Ghosts may pass: they are on their way to the healer.
func _avoids_town() -> bool:
	if dead:
		return false
	return kind == Kind.MONSTER or (kind == Kind.PLAYER and notoriety() != Notoriety.BLUE)


## Players fight monsters and criminals; player killers also prey on innocents.
## Nobody fights other players inside the guarded town.
func _is_fair_target(e: Entity) -> bool:
	if kind == Kind.MONSTER:
		if passive or aggro_range <= 0.0:
			return false                   # wildlife that never starts a fight
		return e.kind == Kind.PLAYER or e.kind == Kind.PET   # monsters hit players and their pets
	if e.kind == Kind.MONSTER:
		return not e.passive or e.target == self   # leave grazing animals be unless they bite
	if e.kind != Kind.PLAYER or _in_town() or e._in_town():
		return false
	if is_pk:
		return not e.is_young()            # young players are left alone
	return e.notoriety() != Notoriety.BLUE


## Young players (under 200 skill points) are spared by player killers.
func is_young() -> bool:
	return kind == Kind.PLAYER and stats.skill_total() < YOUNG_SKILL_TOTAL


## Rough fighting strength: best weapon or magic skill, plus worn armor.
func power() -> float:
	var best := maxf(_skill(_weapon_skill()), _skill(Hero.Skill.MAGERY))
	return best / 20.0 + _armor_rating() / 4.0


## Players only pick fights they can win: a monster much tougher than they are is left alone
## unless it is already attacking them.
func _worth_fighting(e: Entity) -> bool:
	if kind != Kind.PLAYER or e.kind != Kind.MONSTER or e.target == self:
		return true
	return e.threat() <= power() + 0.5


## A monster's danger, plus extra for spellcasters (they hurt from range, through armor).
func threat() -> float:
	var magery := _skill(Hero.Skill.MAGERY)
	return danger + (1.5 if magery >= 50.0 else (0.75 if magery >= 25.0 else 0.0))


func _pick_target() -> Entity:
	var best: Entity = null
	var best_d := aggro_range
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == self or e.dead:
			continue
		var d := position.distance_to(e.position)
		if d <= best_d and _is_fair_target(e) and _worth_fighting(e):
			best = e
			best_d = d
	return best


# --- ghosts ----------------------------------------------------------------

func _set_ghost_look(on: bool) -> void:
	var t := 0.65 if on else 0.0
	body.transparency = t
	nose.transparency = t


## A dead player drifts to the healer, who raises them for free. Murderers are refused and
## wait for the shrine; everyone else is raised at the shrine after a while, at a price.
func _ghost_tick(delta: float) -> void:
	dead_timer -= delta
	if dead_timer <= 0.0:
		_respawn()
		return
	if died_red:
		return
	if notoriety() != Notoriety.BLUE:
		return       # healers turn criminals away (and the guards would kill them on sight)
	var healer := _nearest_role("healer")
	if healer == null:
		return
	if position.distance_to(healer.position) <= HEAL_RANGE:
		_resurrect_free(healer)
		return
	if path.is_empty():
		go_to(healer.position)
	_follow_path(delta)
	_refresh_label()


func _resurrect_free(healer: Entity) -> void:
	dead = false
	ghost = false
	_set_ghost_look(false)
	hp = float(stats.max_hp()) * 0.5
	mana = float(stats.max_mana())
	pause = 1.0
	swing_cd = 1.0
	path.clear()
	game.log_event("%s resurrects %s." % [healer.display_name, display_name])


# --- gathering and crafting ------------------------------------------------

## Mine a rock or chop a tree (used for taps; crafters also choose nodes themselves).
func start_gathering(t: Vector2i) -> void:
	gather_tile = t
	gather_timer = GATHER_TIME
	target = null
	loot_target = null
	path.clear()


## Returns true while walking to or working a rock or tree.
func _gather_step(delta: float) -> bool:
	if gather_tile.x < 0:
		return false
	if not world.can_harvest(gather_tile) or Items.material_count(inventory) >= CARRY_MATERIALS:
		if is_hero and not world.can_harvest(gather_tile):
			game.log_event("There is nothing left to gather here for now.")
		gather_tile = Vector2i(-1, -1)
		return false
	var spot := world.tile_center(gather_tile)
	if position.distance_to(spot) > 1.6:
		if path.is_empty():
			var stand := world.stand_tile_for(gather_tile, position)
			if stand.x < 0 or not go_to(world.tile_center(stand)):
				gather_tile = Vector2i(-1, -1)      # nowhere to stand
				return false
		return true
	path.clear()
	_face(spot - position)
	gather_timer -= delta
	if gather_timer <= 0.0:
		gather_timer = GATHER_TIME
		_harvest_once()
	return true


func _harvest_once() -> void:
	var is_ore := world.resource_kind(gather_tile) == "ore"
	var skill: int = Hero.Skill.MINING if is_ore else Hero.Skill.LUMBERJACKING
	if not _use_tool("pickaxe" if is_ore else "hatchet"):
		if is_hero:
			game.log_event("You need a %s for that." % ("pickaxe" if is_ore else "hatchet"))
		gather_tile = Vector2i(-1, -1)
		return
	world.take_harvest(gather_tile)
	if randf() >= Rules.gather_chance(_skill(skill)):
		_pop("nothing", Color(0.75, 0.75, 0.75))
		return
	var id := Crafting.roll_ore(_skill(skill)) if is_ore else "log"
	inventory[id] = int(inventory.get(id, 0)) + 1
	_pop("+1 " + Items.item_name(id), Color(0.9, 0.85, 0.6))
	game.sound("gather", position)
	if is_hero:
		game.count("gathered")
	if kind == Kind.PLAYER:
		stats.try_gain(skill)


## Crafters pick whichever they have less of: ore or wood.
func _start_gathering_nearby() -> bool:
	if Items.material_count(inventory) >= CARRY_MATERIALS:
		return false
	var metal := Crafting.ore_count(inventory) + Crafting.ingot_count(inventory)
	var want := "ore" if metal <= Crafting.count(inventory, "log") else "wood"
	if Crafting.count(inventory, "pickaxe") <= 0:
		want = "wood"
	if Crafting.count(inventory, "hatchet") <= 0:
		if want == "wood" and Crafting.count(inventory, "pickaxe") <= 0:
			return false
		want = "ore"
	var t := world.find_harvest_near(position, want, 10)
	var other := "wood" if want == "ore" else "ore"
	if t.x < 0 and Crafting.count(inventory, "hatchet" if other == "wood" else "pickaxe") > 0:
		t = world.find_harvest_near(position, other, 10)
	if t.x < 0:
		return false
	start_gathering(t)
	return true


func _has_craft_load() -> bool:
	return Crafting.ore_count(inventory) >= 5 or Crafting.ingot_count(inventory) >= 3 \
		or Crafting.count(inventory, "wolf_pelt") >= 3 or Crafting.count(inventory, "log") >= 5


## With enough materials, walk to the forge, smelt and craft. Returns true while busy.
func _craft_trip() -> bool:
	if not crafting_trip and _has_craft_load() and gather_tile.x < 0:
		crafting_trip = true
	if not crafting_trip:
		return false
	if world.near_forge(position):
		crafting_trip = false
		craft_at_forge()
		return true
	if path.is_empty():
		var stand := world.stand_tile_for(world.forge_tile, position)
		if stand.x < 0 or not go_to(world.tile_center(stand)):
			crafting_trip = false
			return false
	return true


## At the forge: smelt all ore, then craft upgrades first and otherwise practise on the
## cheapest recipe you can make. Spare pieces get sold to the merchant next door.
func craft_at_forge() -> void:
	smelt_all()
	for _i in range(20):
		var id := _pick_recipe()
		if id == "":
			break
		craft(id)


func _pick_recipe() -> String:
	if reagents >= 12.0:
		for id in Crafting.POTIONS:
			if Crafting.count(inventory, id) < 3 and craft_problem(id) == "":
				return id
	for id in Crafting.ORDER:
		if craft_problem(id) == "" and _is_usable_upgrade(id) and not inventory.has(id):
			return id
	var best := ""
	var best_cost := 1 << 30
	for id in Crafting.ORDER:
		if craft_problem(id) != "":
			continue
		var r: Dictionary = Crafting.RECIPES[id]
		if _skill(int(r["skill"])) >= Rules.SKILL_MAX or Items.is_potion(id):
			continue                       # potions are brewed only when needed (above)
		var cost := 0
		var mats: Dictionary = r["mats"]
		for k in mats:
			cost += int(mats[k])
		if cost < best_cost:
			best_cost = cost
			best = id
	return best


## Why a recipe can't be made right now, or "" if it can.
func craft_problem(id: String) -> String:
	var r: Dictionary = Crafting.RECIPES[id]
	var skill := int(r["skill"])
	if _skill(skill) < float(r["min"]):
		return "needs %s %d" % [Hero.skill_name(skill), int(r["min"])]
	if not _has_mats(r["mats"]):
		return "needs " + Items.mats_text(r["mats"])
	if skill == Hero.Skill.BLACKSMITHY and not world.near_forge(position):
		return "needs the forge"
	if skill != Hero.Skill.ALCHEMY and Crafting.count(inventory, "tool_kit") <= 0:
		return "needs a tool kit"
	return ""


## Success uses all the materials and gives the item; failure wastes half of them.
func craft(id: String) -> void:
	var problem := craft_problem(id)
	var item_label := Items.item_name(id)
	if problem != "":
		if is_hero:
			game.log_event("You can't make a %s: %s." % [item_label, problem])
		return
	var r: Dictionary = Crafting.RECIPES[id]
	var skill := int(r["skill"])
	if skill != Hero.Skill.ALCHEMY:
		_use_tool("tool_kit")
	var mats: Dictionary = r["mats"]
	# Enough ingots of one coloured metal make a piece of that metal.
	var metal := ""
	if mats.has("ingot"):
		metal = Crafting.best_single_tier(inventory, int(mats["ingot"]))
	if randf() < Rules.craft_chance(_skill(skill), float(r["min"])):
		var made := id
		if metal != "":
			var only: Dictionary = mats.duplicate()
			only.erase("ingot")
			Crafting.take_mats(inventory, {"ingot_" + metal: int(mats["ingot"])}, 1.0)
			_take_mats(only, 1.0)
			if Crafting.tier_index(metal) > 0:
				made += "@" + metal
		else:
			_take_mats(mats, 1.0)
		var ex := Gear.has(id) and randf() < Rules.exceptional_chance(_skill(skill))
		if ex:
			made += "@ex"
		inventory[made] = int(inventory.get(made, 0)) + 1
		if kind == Kind.PLAYER:
			stats.try_gain(skill)
		if is_hero:
			game.log_event("You make %s." % Items.item_name(made))
			game.count("crafted")
			if ex:
				game.count("crafted_exceptional")
			if metal != "" and Crafting.tier_index(metal) > 0:
				game.count("crafted_colored")
	else:
		_take_mats(r["mats"], 0.5)
		if is_hero:
			game.log_event("You fail to make a %s and lose some materials." % item_label)


## Turns ore into ingots at the forge (Mining). A failed smelt loses the ore.
func smelt_all() -> void:
	if not world.near_forge(position):
		if is_hero:
			game.log_event("You need to stand at the forge to smelt.")
		return
	var made := 0
	var lost := 0
	for t in Crafting.ORE_TIERS:
		var ore := "ore_" + String(t["id"])
		var n := Crafting.count(inventory, ore)
		if n <= 0:
			continue
		inventory.erase(ore)
		for _i in range(n):
			if randf() < Rules.smelt_chance(_skill(Hero.Skill.MINING), float(t["min"])):
				var ingot := "ingot_" + String(t["id"])
				inventory[ingot] = int(inventory.get(ingot, 0)) + 1
				made += 1
			else:
				lost += 1
	if made > 0 and kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.MINING)
	if is_hero and made + lost > 0:
		game.log_event("You smelt %d ingots (%d ore lost)." % [made, lost])


# --- banking ---------------------------------------------------------------

## The hero banks spare gold (everything above a little pocket money) so dying can't lose it.
## Criminals and murderers are refused at the bank.
func _bank_trip() -> bool:
	if notoriety() != Notoriety.BLUE:
		banking = false
		return false
	if not banking and gold >= Property.POCKET_GOLD + 70:
		banking = true
	if not banking:
		return false
	var banker := _find_role("banker")
	if banker == null:
		banking = false
		return false
	if position.distance_to(banker.position) <= 3.0:
		banking = false
		game.bank_deposit(self, gold - Property.POCKET_GOLD)
		return true
	if path.is_empty() and not go_to(banker.position):
		banking = false
		return false
	return true


func _nearest_role(r: String) -> Entity:
	var best: Entity = null
	var best_d := INF
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.role == r and not e.dead:
			var d := position.distance_to(e.position)
			if d < best_d:
				best = e
				best_d = d
	return best


# --- area and travel magic -------------------------------------------------

func _count_fair_targets(radius: float) -> int:
	var n := 0
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e != self and not e.dead and _is_fair_target(e) and position.distance_to(e.position) <= radius:
			n += 1
	return n


## Earthquake: hurts everything hostile around the caster (never innocents).
func _area_blast(sp: Dictionary) -> void:
	_pop(String(sp["name"]) + "!", sp["color"])
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == self or e.dead or not _is_fair_target(e):
			continue
		if position.distance_to(e.position) > Spells.AREA_RADIUS:
			continue
		var amount := randf_range(float(sp["min_dmg"]), float(sp["max_dmg"])) \
			* Rules.spell_damage_multiplier(_skill(Hero.Skill.EVALUATING_INTELLECT))
		if randf() < Rules.resist_chance(e._skill(Hero.Skill.RESISTING_SPELLS)):
			amount *= 0.5
			e._pop("resisted", Color(0.7, 0.9, 1.0))
		e.take_damage(amount, self)


## Why a travel spell can't be cast now, or "" if it can.
func travel_problem(id: String) -> String:
	var sp: Dictionary = Spells.LIST[id]
	if dead:
		return "you are dead"
	if _skill(Hero.Skill.MAGERY) < float(sp["min"]):
		return "it needs Magery %.1f" % float(sp["min"])
	if mana < float(sp["mana"]):
		return "not enough mana"
	if reagents < float(sp["reagents"]):
		return "not enough reagents"
	if id == "mark":
		if world.is_dungeon(world.to_tile(position)):
			return "runes can't be marked in the dungeon"
		return ""
	var rune: Vector2i = game.property.rune
	if rune.x < 0:
		return "your rune isn't marked"
	if world.is_blocked(rune):
		return "the marked spot is blocked"
	return ""


## Cast from Menu > Travel.
func cast_travel(id: String) -> void:
	var problem := travel_problem(id)
	if problem != "":
		game.log_event("You can't cast %s: %s." % [Spells.LIST[id]["name"], problem])
		return
	target = null
	loot_target = null
	gather_tile = Vector2i(-1, -1)
	start_cast(id, self)


func _travel(id: String) -> void:
	if id == "mark":
		game.property.rune = world.to_tile(position)
		game.log_event("You mark your rune here.")
		return
	var rune: Vector2i = game.property.rune
	if rune.x < 0 or world.is_blocked(rune):
		_pop("fizzle", Color(0.75, 0.75, 0.75))
		return
	var dest := world.tile_center(rune)
	if id == "gate_travel":
		game.open_gate(world.tile_center(world.to_tile(position)), dest)
		game.log_event("A moongate opens to your rune. Anyone may follow for a short while.")
	else:
		game.log_event("You recall to your rune.")
	teleport_to(dest)


func teleport_to(p: Vector3) -> void:
	position = p
	path.clear()
	target = null
	gate_cd = 2.0


# --- animation -------------------------------------------------------------

## Simple procedural motion: a bob while walking, a lunge on each swing, a float while casting,
## a chopping tilt while gathering, gentle breathing when idle, and a drifting ghost.
func _animate(delta: float) -> void:
	anim_t += delta
	swing_anim = maxf(swing_anim - delta, 0.0)
	var moving := position.distance_to(_last_pos) > 0.001
	_last_pos = position
	var y := 0.0
	var tilt := 0.0
	if ghost:
		y = 0.25 + sin(anim_t * 2.0) * 0.08
	elif casting_id != "":
		y = 0.1 + sin(anim_t * 6.0) * 0.05
	elif moving:
		y = absf(sin(anim_t * 11.0)) * 0.09
	elif gather_tile.x >= 0:
		tilt = maxf(sin(anim_t * 6.0), 0.0) * 0.35
	else:
		y = sin(anim_t * 2.0) * 0.015
	var z := 0.0
	if swing_anim > 0.0:
		var k := sin(swing_anim / SWING_ANIM * PI)
		z = -0.25 * k
		tilt += 0.25 * k
	rig.position = Vector3(0.0, y, z)
	rig.rotation.x = -tilt


# --- poison and potions ----------------------------------------------------

## A stronger poison replaces a weaker one; it wears off on its own after a while.
func apply_poison(level: int, from: Entity) -> void:
	if dead or kind == Kind.NPC or level <= poison_level or poison_immune > 0.0:
		return
	poison_level = clampi(level, 1, 3)
	poison_time = 20.0 + 10.0 * poison_level
	poison_tick = 2.0
	poisoner = from
	_pop("%s poison!" % Rules.POISON_NAMES[poison_level], Color(0.4, 1.0, 0.3))
	if is_hero:
		game.count("poisoned")


func _poison_step(delta: float) -> void:
	poison_time -= delta
	poison_tick -= delta
	if poison_tick <= 0.0:
		poison_tick = 2.0
		var dmg: float = Rules.POISON_DAMAGE[poison_level]
		hp -= dmg
		_pop("-%d" % maxi(1, roundi(dmg)), Color(0.4, 1.0, 0.3))
		if casting_id != "":
			_fizzle("disrupted")
		if hp <= 0.0:
			_die(poisoner if poisoner != null and is_instance_valid(poisoner) else self)
			return
	if poison_time <= 0.0:
		_cure("the poison wears off")


func _cure(message: String) -> void:
	poison_immune = 10.0
	if poison_level > 0 and is_hero:
		game.count("cured")
	poison_level = 0
	poisoner = null
	_pop(message, Color(0.6, 1.0, 0.6))


## Players drink a potion when it matters: cure when poisoned (and no Cure spell to hand),
## heal when badly hurt, refresh when worn out. One potion every few seconds.
func _try_potion() -> bool:
	if potion_cd > 0.0 or casting_id != "":
		return false
	var drink := ""
	if poison_level > 0 and Crafting.count(inventory, "potion_cure") > 0 and _best_spell("cure") == "":
		drink = "potion_cure"
	elif hp < float(stats.max_hp()) * 0.4:
		for id in ["potion_greater_heal", "potion_heal"]:
			if Crafting.count(inventory, id) > 0:
				drink = id
				break
	elif stamina < float(stats.max_stamina()) * 0.3 and Crafting.count(inventory, "potion_refresh") > 0:
		drink = "potion_refresh"
	if drink == "":
		return false
	Crafting.take_mats(inventory, {drink: 1}, 1.0)
	potion_cd = POTION_DELAY
	match drink:
		"potion_cure":
			if poison_level < 3 or randf() < 0.5:
				_cure("cured")
			else:
				_pop("the poison is too strong", Color(0.75, 0.75, 0.75))
		"potion_heal", "potion_greater_heal":
			var amount := randf_range(8.0, 12.0) if drink == "potion_heal" else randf_range(18.0, 25.0)
			hp = minf(hp + amount, float(stats.max_hp()))
			_pop("+%d" % roundi(amount), Color(0.5, 1.0, 0.5))
		"potion_refresh":
			stamina = float(stats.max_stamina())
			_pop("refreshed", Color(0.6, 0.8, 1.0))
	if is_hero:
		game.count("potions_drunk")
		game.log_event("You drink a %s." % Items.item_name(drink))
	return false                         # drinking is instant: carry on with the turn


## Materials for a recipe: "reagent" comes from the reagent pouch, the rest from the bag.
func _has_mats(mats: Dictionary) -> bool:
	var bag := mats.duplicate()
	if bag.has("reagent"):
		if reagents < float(bag["reagent"]):
			return false
		bag.erase("reagent")
	return Crafting.has_mats(inventory, bag)


func _take_mats(mats: Dictionary, fraction: float) -> void:
	var bag := mats.duplicate()
	if bag.has("reagent"):
		reagents = maxf(reagents - ceili(int(bag["reagent"]) * fraction), 0.0)
		bag.erase("reagent")
	Crafting.take_mats(inventory, bag, fraction)


# --- gold ------------------------------------------------------------------

func _earn(n: int) -> void:
	if n <= 0:
		return
	gold += n
	if is_hero:
		game.count("gold_earned", n)


func _spend(n: int) -> void:
	gold -= n
	if is_hero:
		game.count("gold_spent", n)


# --- animals: pets, taming, veterinary --------------------------------------

## Pets follow their owner, attack what the owner attacks (monsters only) and defend themselves.
func _pet_think() -> void:
	if pet_owner == null or not is_instance_valid(pet_owner):
		return
	if target == null and pet_owner.target != null and is_instance_valid(pet_owner.target) \
			and not pet_owner.target.dead and pet_owner.target.kind == Kind.MONSTER:
		target = pet_owner.target
	if target != null and position.distance_to(pet_owner.position) > PET_LEASH:
		target = null                        # don't chase off too far
	if target != null:
		_chase()
		return
	if position.distance_to(pet_owner.position) > 2.5:
		if repath_timer <= 0.0 or path.is_empty():
			repath_timer = 0.5
			go_to(pet_owner.position)
	else:
		path.clear()


func can_tame(e: Entity) -> String:
	if e == null or e.dead or e.kind != Kind.MONSTER or e.tame_min < 0.0:
		return "that can't be tamed"
	if pets.size() >= MAX_PETS:
		return "you already have %d pets" % MAX_PETS
	if _skill(Hero.Skill.ANIMAL_TAMING) < e.tame_min - 10.0:
		return "you have no chance (it needs Animal Taming %d)" % int(e.tame_min)
	return ""


func tame_chance_of(e: Entity) -> float:
	return Rules.tame_chance(_skill(Hero.Skill.ANIMAL_TAMING), _skill(Hero.Skill.ANIMAL_LORE), e.tame_min)


## Walk up to an animal and try to tame it.
func start_taming(e: Entity) -> void:
	var problem := can_tame(e)
	if problem != "":
		if is_hero:
			game.log_event("You can't tame that: %s." % problem)
		return
	tame_target = e
	target = null
	loot_target = null
	gather_tile = Vector2i(-1, -1)


## Players in Auto look for an animal they have some chance with (passive ones, or any not
## already attacking someone).
func _start_taming_nearby() -> bool:
	if pets.size() >= MAX_PETS or tame_cd > 0.0:
		return false
	var best: Entity = null
	var best_d := 10.0
	var list: Array = game.creatures
	for item in list:
		var x := item as Entity
		if can_tame(x) != "" or (not x.passive and x.target != null):
			continue
		var d := position.distance_to(x.position)
		if d < best_d:
			best = x
			best_d = d
	if best == null:
		return false
	start_taming(best)
	return true


## Returns true while walking to an animal to tame it.
func _tame_step() -> bool:
	if tame_target == null:
		return false
	if not is_instance_valid(tame_target) or can_tame(tame_target) != "":
		tame_target = null
		return false
	if position.distance_to(tame_target.position) > 2.5:
		if path.is_empty() or repath_timer <= 0.0:
			repath_timer = 0.5
			if not go_to(tame_target.position) and position.distance_to(tame_target.position) > 2.5:
				tame_target = null
				tame_cd = TAME_COOLDOWN          # couldn't reach it: try something else for a while
				return false
		return true
	path.clear()
	tame_timer = TAME_TIME
	tame_target.path.clear()                 # the animal holds still while it is coaxed
	tame_target.pause = TAME_TIME + 1.0
	_pop("taming...", Color(0.9, 0.8, 0.5))
	return true


func _tame_channel(delta: float) -> void:
	if tame_target == null or not is_instance_valid(tame_target) or can_tame(tame_target) != "" \
			or position.distance_to(tame_target.position) > 5.0:
		tame_timer = 0.0
		tame_target = null
		tame_cd = TAME_COOLDOWN              # a broken-off attempt also waits out the cooldown
		if is_hero:
			game.count("tame_cancelled")
		return
	_face(tame_target.position - position)
	tame_timer -= delta
	if tame_timer > 0.0:
		return
	var animal := tame_target
	tame_target = null
	tame_cd = TAME_COOLDOWN
	if is_hero:
		game.count("tame_attempts")
	var won := randf() < tame_chance_of(animal)
	if kind == Kind.PLAYER:                  # every attempt teaches
		stats.try_gain(Hero.Skill.ANIMAL_TAMING)
		stats.try_gain(Hero.Skill.ANIMAL_LORE)
	if won:
		game.tame(self, animal)
	else:
		animal._pop("resists", Color(0.75, 0.75, 0.75))
		if not animal.passive:
			animal.target = self                 # it didn't like that


## Turns a wild animal into this player's pet.
func adopt_pet(p: Entity) -> void:
	p.kind = Kind.PET
	p.pet_owner = self
	p.target = null
	p.path.clear()
	p.passive = false
	p._last_text = ""
	pets.append(p)


func release_pet(p: Entity) -> void:
	pets.erase(p)
	p.kind = Kind.MONSTER
	p.pet_owner = null
	p.target = null
	p.home = p.position
	p._last_text = ""
	if is_hero:
		game.log_event("You release your %s into the wild." % p.display_name)


## Veterinary bandage on a pet: heals with Veterinary and Animal Lore.
func _finish_vet(p: Entity) -> void:
	if not is_instance_valid(p) or p.dead or position.distance_to(p.position) > 2.5:
		_pop("bandage failed", Color(0.75, 0.75, 0.75))
		return
	var vet := _skill(Hero.Skill.VETERINARY)
	if randf() < Rules.bandage_chance(vet):
		var amount := Rules.bandage_heal(vet, _skill(Hero.Skill.ANIMAL_LORE))
		p.hp = minf(p.hp + amount, float(p.stats.max_hp()))
		p._pop("+%d" % roundi(amount), Color(0.5, 1.0, 0.5))
		if is_hero:
			game.count("vet_bandages")
	else:
		_pop("bandage failed", Color(0.75, 0.75, 0.75))
	if kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.VETERINARY)
		stats.try_gain(Hero.Skill.ANIMAL_LORE)


# --- bards: Musicianship, Peacemaking, Provocation, Enticement -------------

func has_instrument() -> bool:
	for id in inventory:
		if Items.is_instrument(id):
			return true
	return false


## How hard a creature is to calm, provoke or lure (0..100).
func bard_difficulty() -> float:
	return clampf(threat() * 12.0, 5.0, 100.0)


func bard_chance_vs(skill: int, e: Entity) -> float:
	return Rules.bard_chance(_skill(skill), _skill(Hero.Skill.MUSICIANSHIP), e.bard_difficulty())


## The nearest monster within reach that isn't already calmed, or null.
func nearest_hostile(exclude: Entity = null) -> Entity:
	var best: Entity = null
	var best_d := BARD_RANGE
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == exclude or e.dead or e.kind != Kind.MONSTER or e.peaced_timer > 0.0:
			continue
		var d := position.distance_to(e.position)
		if d < best_d:
			best = e
			best_d = d
	return best


## Why a performance can't start now, or "" if it can.
func bard_problem(what: String) -> String:
	if dead:
		return "you are dead"
	if not has_instrument():
		return "you need a lute (Bran sells them)"
	if bard_cd > 0.0 or perform_timer > 0.0:
		return "you are still catching your breath"
	var first := nearest_hostile()
	if first == null:
		return "no monster close enough"
	if what == "provoke" and nearest_hostile(first) == null:
		return "it needs a second monster nearby"
	return ""


## Begin playing. `a` (and `b` for Provocation) are the creatures to work on.
func start_perform(what: String, a: Entity, b: Entity) -> void:
	if is_hero:
		game.count("perform_" + what)
	perform_kind = what
	perform_a = a
	perform_b = b
	perform_timer = PERFORM_TIME
	path.clear()
	_pop("*plays the lute*", Color(0.9, 0.8, 1.0))


## Auto: provoke when two monsters gang up, calm them when badly hurt.
func _try_bard() -> bool:
	if bard_problem("peace") != "":
		return false
	var attackers: Array[Entity] = []
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if not e.dead and e.kind == Kind.MONSTER and e.target == self and e.peaced_timer <= 0.0 \
				and position.distance_to(e.position) <= BARD_RANGE:
			attackers.append(e)
	if attackers.size() >= 2:
		start_perform("provoke", attackers[0], attackers[1])
		return true
	if attackers.size() == 1 and hp < float(stats.max_hp()) * FLEE_HP:
		start_perform("peace", null, null)
		return true
	return false


func _perform_channel(delta: float) -> void:
	perform_timer -= delta
	if perform_timer > 0.0:
		return
	bard_cd = BARD_COOLDOWN
	var musicianship := _skill(Hero.Skill.MUSICIANSHIP)
	if randf() >= Rules.music_chance(musicianship):
		_pop("you play poorly", Color(0.75, 0.75, 0.75))
		if is_hero:
			game.count("bard_fail")
		return
	if kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.MUSICIANSHIP)
	match perform_kind:
		"peace":
			_do_peace()
		"provoke":
			_do_provoke()
		"entice":
			_do_entice()


## Calms every monster around the bard that the music reaches.
func _do_peace() -> void:
	var calmed := 0
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.dead or e.kind != Kind.MONSTER or position.distance_to(e.position) > BARD_RANGE:
			continue
		if randf() < bard_chance_vs(Hero.Skill.PEACEMAKING, e):
			e.peaced_timer = PEACE_SECONDS
			e.target = null
			e.path.clear()
			e._pop("calmed", Color(0.7, 0.9, 1.0))
			calmed += 1
	if calmed > 0:
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.PEACEMAKING)
		if is_hero:
			game.count("bard_peace", calmed)
	target = null
	recovering = recovering or hp < float(stats.max_hp()) * RECOVER_HP


## Turns one monster on another. Failing makes the first one angry with the bard.
func _do_provoke() -> void:
	var a := perform_a
	var b := perform_b
	if a == null or b == null or not is_instance_valid(a) or not is_instance_valid(b) or a.dead or b.dead:
		return
	var difficulty := (a.bard_difficulty() + b.bard_difficulty()) / 2.0
	if randf() < Rules.bard_chance(_skill(Hero.Skill.PROVOCATION), _skill(Hero.Skill.MUSICIANSHIP), difficulty):
		a.target = b
		b.target = a
		a.peaced_timer = 0.0
		a._pop("provoked!", Color(1.0, 0.6, 0.3))
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.PROVOCATION)
		if is_hero:
			game.count("bard_provoke")
			game.log_event("You provoke the %s into attacking the %s!" % [a.display_name, b.display_name])
	else:
		a.target = self
		a._pop("not fooled", Color(0.75, 0.75, 0.75))


## Lures a monster to walk over to the bard on its own. Failing angers it.
func _do_entice() -> void:
	var a := perform_a
	if a == null or not is_instance_valid(a) or a.dead:
		return
	if randf() < bard_chance_vs(Hero.Skill.ENTICEMENT, a):
		a.enticed_timer = ENTICE_SECONDS
		a.enticer = self
		a.target = null
		a._pop("enticed", Color(0.9, 0.8, 1.0))
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.ENTICEMENT)
		if is_hero:
			game.count("bard_entice")
	else:
		a.target = self
		a._pop("not fooled", Color(0.75, 0.75, 0.75))


# --- weapons, tools and the lesser skills ----------------------------------

static func skill_for(weapon_skill: String) -> int:
	match weapon_skill:
		"fencing":
			return Hero.Skill.FENCING
		"mace":
			return Hero.Skill.MACE_FIGHTING
		"archery":
			return Hero.Skill.ARCHERY
	return Hero.Skill.SWORDSMANSHIP


## The weapon actually in use: a bow without arrows is no weapon at all (bare hands).
func _wielded() -> String:
	if weapon != "" and Gear.is_ranged(weapon) and arrows <= 0:
		return ""
	return weapon


func _weapon_skill() -> int:
	var w := _wielded()
	if w == "":
		return Hero.Skill.SWORDSMANSHIP     # natural attacks and bare hands
	return skill_for(String(Gear.stats(w)["skill"]))


func attack_range() -> float:
	var w := _wielded()
	if w != "" and Gear.is_ranged(w):
		return float(Gear.stats(w)["range"])
	return MELEE_RANGE


func _wants_arrows() -> bool:
	if Gear.is_ranged(weapon):
		return true
	for id in inventory:
		if Gear.is_ranged(id):
			return true
	return _skill(Hero.Skill.ARCHERY) >= 30.0


## Tools the merchant should sell us: gatherers want both, and anyone who crafts wants a kit.
func _needed_tools() -> Array:
	var out := []
	if not (crafter or is_hero):
		return out
	for t in TOOLS:
		if Crafting.count(inventory, t) <= 0:
			out.append(t)
	return out


## Uses up a tool; the last use breaks it. Returns false if there is none to use.
func _use_tool(tool: String) -> bool:
	if Crafting.count(inventory, tool) <= 0:
		return false
	var left := int(tool_uses.get(tool, TOOL_USES)) - 1
	if left <= 0:
		Crafting.take_mats(inventory, {tool: 1}, 1.0)
		tool_uses[tool] = TOOL_USES
		if is_hero:
			game.log_event("Your %s breaks." % Items.item_name(tool))
			game.count("tools_broken")
	else:
		tool_uses[tool] = left
	return true


## Arms Lore (weapons and armor) and Item Identification (everything else): knowing what a
## thing is really worth gets a better price. Returns the extra gold.
func _appraise(id: String, paid: int) -> int:
	if kind != Kind.PLAYER:
		return 0
	var skill: int = Hero.Skill.ARMS_LORE if Gear.has(id) else Hero.Skill.ITEM_IDENTIFICATION
	stats.try_gain(skill)
	var extra := floori(paid * (Rules.appraisal_bonus(_skill(skill)) - 1.0))
	if extra > 0 and is_hero:
		game.count("appraisal_gold", extra)
	return extra


## Tracking: find something worth hunting beyond sight, and head that way.
func _track_hunt() -> bool:
	if track_cd > 0.0 or kind != Kind.PLAYER:
		return false
	track_cd = 20.0
	var radius := 14.0 + _skill(Hero.Skill.TRACKING) / 4.0
	var best: Entity = null
	var best_d := radius
	var list: Array = game.creatures
	for item in list:
		var x := item as Entity
		if x.dead or x.kind != Kind.MONSTER or x.passive or not _worth_fighting(x) or x._in_town():
			continue
		var dd := position.distance_to(x.position)
		if dd > aggro_range and dd < best_d:
			best = x
			best_d = dd
	if best == null:
		return false
	if randf() >= Rules.track_chance(_skill(Hero.Skill.TRACKING)):
		return false
	stats.try_gain(Hero.Skill.TRACKING)
	if not go_to(best.position):
		return false
	if is_hero:
		game.count("tracked")
	return true


## Camping: hurt and alone in the wild, make a fire from a log and rest by it.
func _try_camp() -> bool:
	if camp_cd > 0.0 or kind != Kind.PLAYER or _in_town() or game.near_campfire(position):
		return false
	if hp >= float(stats.max_hp()) * 0.75 or Crafting.count(inventory, "log") <= 0:
		return false
	if _nearest(Kind.MONSTER, 7.0) != null:
		return false
	camp_cd = 90.0
	Crafting.take_mats(inventory, {"log": 1}, 1.0)
	if randf() >= Rules.camp_chance(_skill(Hero.Skill.CAMPING)):
		_pop("the kindling won't catch", Color(0.75, 0.75, 0.75))
		return false
	stats.try_gain(Hero.Skill.CAMPING)
	game.light_campfire(position)
	path.clear()
	pause = 8.0                           # sit by the fire a while
	if is_hero:
		game.log_event("You make a campfire and rest.")
		game.count("camped")
	return true


## Begging: broke and standing by a townsperson, ask for a coin (each one once in a while).
func _try_beg() -> bool:
	if gold >= 15 or kind != Kind.PLAYER:
		return false
	var now := Time.get_ticks_msec()
	for id in beg_cd.keys():
		if now > int(beg_cd[id]):
			beg_cd.erase(id)
	var list: Array = game.creatures
	for item in list:
		var npc := item as Entity
		if npc.kind != Kind.NPC or npc.role == "guard":
			continue
		if beg_cd.has(npc.get_instance_id()) or position.distance_to(npc.position) > 3.0:
			continue
		beg_cd[npc.get_instance_id()] = now + 300000
		if randf() < Rules.beg_chance(_skill(Hero.Skill.BEGGING)):
			var coins := randi_range(2, 5 + int(_skill(Hero.Skill.BEGGING) / 10.0))
			_earn(coins)
			npc._pop("here, %d gold" % coins, Color(1.0, 0.9, 0.5))
			if is_hero:
				game.count("begged")
				game.count("begged_gold", coins)
		else:
			npc._pop("away with you", Color(0.75, 0.75, 0.75))
		stats.try_gain(Hero.Skill.BEGGING)
		return true
	return false


## Spirit Speak: with no bandages left, commune with the dead to mend your own wounds.
func _try_spirit_speak() -> bool:
	if kind != Kind.PLAYER or casting_id != "" or bandage_timer > 0.0:
		return false
	if hp >= float(stats.max_hp()) * 0.5 or _nearest(Kind.MONSTER, 2.5) != null:
		return false
	if mana < 10.0:
		return false
	mana -= 10.0
	bandage_target = self
	spirit_channel = true
	bandage_timer = maxf(2.0, 4.0 - _skill(Hero.Skill.SPIRIT_SPEAK) / 50.0)
	path.clear()
	_pop("channelling", Color(0.7, 0.8, 1.0))
	return true


func _finish_spirit_speak() -> void:
	var spirit := _skill(Hero.Skill.SPIRIT_SPEAK)
	stats.try_gain(Hero.Skill.SPIRIT_SPEAK)
	if randf() >= Rules.spirit_speak_chance(spirit):
		_pop("the spirits are silent", Color(0.75, 0.75, 0.75))
		return
	var amount := 4.0 + spirit / 8.0
	hp = minf(hp + amount, float(stats.max_hp()))
	_pop("+%d" % roundi(amount), Color(0.6, 0.8, 1.0))
	if is_hero:
		game.count("spirit_speak")
