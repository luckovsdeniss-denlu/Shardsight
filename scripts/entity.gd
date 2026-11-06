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
const HURT_NO_REGEN := 6.0         # seconds without natural healing after being hit
const SPELL_RANGE := 7.0
const CAST_RECOVERY := 0.8     # seconds between casts
const LOOT_RANGE := 1.6
const LOOT_SEEK := 9.0         # how far players look for corpses
const REAGENT_PRICE := 2       # gold per reagent at the merchant
const MAX_REAGENTS := 60.0
const BANDAGE_PRICE := 2
const MAX_BANDAGES := 10
const MARKET_RANGE := 4.0          # the merchant trades with players this close
const PRIEST_RANGE := 4.0          # the priest serves players this close
const BLESS_PRICE := 25            # gold for the priest's blessing
const BLESS_SECONDS := 300.0       # how long a blessing lasts
const BLESS_DAMAGE := 1.1          # blessed: +10% damage dealt...
const BLESS_ARMOR := 0.9           # ...and -10% damage taken
const CONFESS_PRICE := 50          # gold to have one murder count lifted
const SCROLL_DROP_CHANCE := 0.12   # a monster that carries gold may carry a spell scroll
const HARMFUL_KINDS := ["attack", "poison", "paralyze", "curse", "drain"]
const MONSTER_KINDS := ["attack", "heal", "cure", "poison", "area", "paralyze", "curse", "drain"]
const BUFF_ORDER := ["polymorph", "bless", "strength", "agility", "protection", "reactive_armor", "magic_reflection"]
const CURSE_ORDER := ["curse", "weaken", "clumsy", "feeblemind"]
const SHOP_SCROLL_CIRCLES := 6     # merchants stock scrolls up to this circle
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
const TOOL_RESERVE := 8            # gold kept back when buying a missing tool
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
var hurt_timer := 0.0          # natural healing stops for a while after taking a blow
var bless_timer := 0.0         # seconds of the priest's blessing left
var spellbook := {}            # spell id -> true: the spells this character can cast
var paralyzed_timer := 0.0     # Paralyze: can't move or act until it wears off or a blow lands
var summoned := false          # an Earth Elemental: crumbles when summon_timer runs out
var summon_timer := 0.0
var summon: Entity = null      # the creature this caster has summoned, if any
var summon_name := ""
var effects := {}              # spell effects: name -> {"secs", "mods", "flag"}
var flags := {}                # flags of the active effects (invisible, protection...)
var cast_corpse: Corpse = null # the corpse a Telekinesis / Magic Lock / Unlock is aimed at
var last_curse_target: Entity = null
var drain_cd := 0.0
var field_cd := 0.0
var bank_gold := 0             # other players' own bank (the hero's is game.property.bank_gold)
var fame := 0
var karma := 0
var is_thief := false          # computer thieves: sneak up, snoop and steal
var mounted_on: Entity = null  # the pet this player is riding (parked out of the world meanwhile)
var parked := false            # a mount being ridden: not in the world until its rider gets off
var mount_speed := 1.0         # how much faster a rider of this animal goes
var is_boss := false
var auto_equip := true         # put on better gear by itself (off after a choice made by hand)
var retreating := false        # the Retreat button: break off, heal up, get to a healer
var minion_cd := 10.0
var stealth_left := 0.0        # metres you can still walk hidden
var thief_mark: Entity = null
var steal_cd := 0.0
var hide_cd := 0.0
var craft_cd := 0.0            # after a fruitless forge visit, wait before the next one
var _priest_timer := 0.0
var tame_walk := 0.0           # seconds spent walking after the animal being tamed
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
var rig: Node3D                # holds the model; moved by the procedural animation
var model := {}                # the Art model: root, legs, arm, spin, meshes
var look := "humanoid"
var visual_scale := 1.0
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
	# Every player (the hero and the computer players alike) starts from zero: no skills, level 1.
	# Only monsters and townsfolk come with the skills in their stat block.
	var skills: Dictionary = cfg.get("skills", {}) if p_kind != Kind.PLAYER else {}
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
	look = String(cfg.get("look", "humanoid"))
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
	if kind == Kind.PLAYER:
		start_bag = Bestiary.PLAYER_KIT.merged(start_bag, true)   # every player gets the hero's kit
	for k in start_bag:
		inventory[k] = int(start_bag[k])
	danger = float(cfg.get("danger", 1.0))
	poison_cfg = cfg.get("poison", [])
	stamina = float(stats.max_stamina())
	arrows = int(cfg.get("arrows", 0))
	fame = int(cfg.get("fame", 0)) if p_kind != Kind.PLAYER else 0
	is_thief = bool(cfg.get("thief", false))
	mount_speed = float(cfg.get("mount_speed", 1.0))
	is_boss = bool(cfg.get("boss", false))
	karma = int(cfg.get("karma", 0)) if p_kind != Kind.PLAYER else 0
	# Players start with the first four circles and copy the rest from scrolls; monsters (and
	# configs marked "all") know every spell.
	var book: Variant = cfg.get("spellbook", "all" if p_kind != Kind.PLAYER else Spells.STARTER)
	for id in (Spells.ORDER if typeof(book) == TYPE_STRING else book):
		spellbook[String(id)] = true
	crafter = bool(cfg.get("crafter", kind == Kind.PLAYER))   # players gather and craft like the hero
	stats.skill_gained.connect(_on_skill_gained)
	stats.level_up.connect(_on_level_up)
	stats.stat_gained.connect(_on_stat_gained)
	refresh_look()                       # now that gear and role are known


func _build_visual(color: Color, s: float) -> void:
	rig = Node3D.new()
	add_child(rig)
	anim_t = randf() * 10.0          # so idle creatures don't breathe in lockstep
	visual_scale = s                     # the model itself is built at the end of setup()
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
	if parked:
		position = mounted_by_position()    # carried along under its rider
		return
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
	hurt_timer = maxf(hurt_timer - delta, 0.0)
	if hurt_timer <= 0.0:
		hp = minf(hp + REGEN_PER_SEC * delta, float(stats.max_hp()))
	_regen_mana(delta)
	stamina = minf(stamina + STAMINA_REGEN * delta, float(stats.max_stamina()))
	potion_cd = maxf(potion_cd - delta, 0.0)
	poison_immune = maxf(poison_immune - delta, 0.0)
	tame_cd = maxf(tame_cd - delta, 0.0)
	track_cd = maxf(track_cd - delta, 0.0)
	bless_timer = maxf(bless_timer - delta, 0.0)
	drain_cd = maxf(drain_cd - delta, 0.0)
	steal_cd = maxf(steal_cd - delta, 0.0)
	if is_boss and target != null:
		minion_cd -= delta
		if minion_cd <= 0.0:
			minion_cd = 25.0
			game.raise_minions(self)
	hide_cd = maxf(hide_cd - delta, 0.0)
	field_cd = maxf(field_cd - delta, 0.0)
	if not effects.is_empty():
		_effects_tick(delta)
	craft_cd = maxf(craft_cd - delta, 0.0)
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
	if summoned:
		summon_timer -= delta
		if summon_timer <= 0.0:
			_unsummon()
			return
	if paralyzed_timer > 0.0:
		paralyzed_timer -= delta          # frozen: no moving, swinging or casting
		_refresh_label()
		return
	if role == "healer":
		_heal_aura(delta)
	elif role == "merchant":
		_market_aura(delta)
	elif role == "priest":
		_priest_aura(delta)
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
			if kind == Kind.PLAYER and (ai_enabled or not is_hero):
				_auto_mount()
	_think(delta)
	_follow_path(delta)
	_fight()
	_refresh_label()


# --- decisions -------------------------------------------------------------

func _think(delta: float) -> void:
	if role == "escort":
		_escort_follow()
		return
	if target != null and (not is_instance_valid(target) or target.dead or target.kind == Kind.NPC \
			or target.flags.has("invisible")):
		target = null
	if kind == Kind.PET:
		_pet_think()
		return
	if retreating:
		_retreat_step()
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
			target = null       # gave up: prey fled into the safe town, or too far from its lair
			pause = 3.0
			go_to(home)
	elif kind == Kind.PLAYER and autonomous and pause <= 0.0:
		if target != null and _outmatched(target) and target.target == self:
			start_retreat()                # it's coming for us and it's far too strong
			return
		if _try_resurrect_others():
			return
		if is_thief and _thief_step():
			return
		if is_hero and target == null and _quest_trip():
			return
		if _try_bard():
			return
		if _recover() or _resupply():
			return
		if target == null:
			target = _pick_target()
			# Lure a far-off monster away from its friends before fighting it.
			if target != null and position.distance_to(target.position) > 4.0 \
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
		if autonomous and pause <= 0.0 and _bank_trip():
			return
		if _tame_step(delta):
			return
		if _gather_step(delta):
			return
	if autonomous and pause <= 0.0 and path.is_empty():
		idle_timer -= delta
		if idle_timer <= 0.0:
			if kind == Kind.PLAYER and (_try_camp() or _try_beg() or _try_idle_magic()):
				idle_timer = randf_range(1.5, 4.0)
				return
			if not (crafter and randf() < 0.5 and _start_gathering_nearby()) \
					and not (kind == Kind.PLAYER and randf() < 0.3 and _start_taming_nearby()) \
					and not (kind == Kind.PLAYER and randf() < 0.5 and _track_hunt()):
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
	if casting_id == "" and cast_cd <= 0.0 and _try_escape_magic():
		return true
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
		if e == self or e.dead or e.parked or e.kind != k:
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
	var budget := speed * delta * (mounted_on.mount_speed if mounted_on != null else 1.0)
	if effects.has("hiding") and not path.is_empty():
		stealth_left -= budget
		if stealth_left < 0.0:
			_end_flag("invisible")
			_pop("revealed", Color(0.9, 0.9, 0.7))
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
			game.sound("bow", position)
	elif kind == Kind.PLAYER:
		lo = 1.0                           # bare hands
		hi = 4.0
	if flags.has("invisible"):
		_end_flag("invisible")              # attacking reveals you
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
			float(stats.eff_str()), tactics, anatomy)
		if bless_timer > 0.0:
			dmg *= BLESS_DAMAGE
		var dealt := target._absorb(dmg)
		if is_hero:
			game.count("hero_hits")
			game.count("hero_dmg_dealt", roundi(dealt))
		elif target.is_hero:
			game.count("hero_dmg_taken_melee", roundi(dealt))
		target.take_damage(dealt, self)
		if target.flags.has("reactive_armor") and not dead:
			_reflect_blow(dealt * 0.25, target)   # Reactive Armor sends part of a blow back
		if poison_cfg.size() == 2 and not target.dead and randf() < float(poison_cfg[1]):
			target.apply_poison(int(poison_cfg[0]), self)
		if kind == Kind.PLAYER:
			stats.try_gain(skill)
			stats.try_gain(Hero.Skill.TACTICS)
	else:
		if is_hero:
			game.count("hero_misses")
		game.sound("swing", position)
		target._pop("miss", Color(0.8, 0.8, 0.8))


## Armor soaks a random half-to-all of its rating, but a hit always does at least 1.
func _absorb(amount: float) -> float:
	if bless_timer > 0.0:
		amount *= BLESS_ARMOR
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
	# Towns are safe: nobody inside one can be hurt, and nobody can attack out of one.
	if _in_town() or (from != null and is_instance_valid(from) and from != self and from._in_town()):
		return
	# Hitting an innocent player makes the attacker a criminal and, if the victim dies soon
	# after, a murderer. The victim can fight back freely.
	if from != self and from.kind == Kind.PLAYER and kind == Kind.PLAYER and _trammel() and not from.at_war_with(self):
		return                             # Trammel: players can't hurt each other (guild wars aside)
	if from != self and from.kind == Kind.PLAYER and kind == Kind.PLAYER and notoriety() == Notoriety.BLUE \
			and not from.at_war_with(self):
		from.criminal_timer = CRIMINAL_SECONDS
		var aid := from.get_instance_id()
		if not attackers.has(aid):
			game.event_about("%s attacks %s!" % [from.display_name, display_name], is_hero or from.is_hero)
		attackers[aid] = MURDER_WINDOW
	hp -= amount
	if is_hero and amount >= float(stats.max_hp()) * 0.2:
		game.glitch(0.5, 0.25)             # a heavy blow jolts the picture
	hurt_timer = HURT_NO_REGEN
	if paralyzed_timer > 0.0:
		paralyzed_timer = 0.0               # a blow breaks Paralyze
	if peaced_timer > 0.0 or (enticed_timer > 0.0 and from == enticer):
		peaced_timer = 0.0                   # a blow breaks the spell of the music
		enticed_timer = 0.0
	game.sound("hit", position)
	if casting_id != "" and not flags.has("protection"):
		_fizzle("disrupted")      # taking damage breaks a spell in progress (not under Protection)
	if bandage_timer > 0.0:
		bandage_timer = 0.0
		_pop("interrupted", Color(0.75, 0.75, 0.75))
	if tame_timer > 0.0:
		tame_timer = 0.0
		tame_target = null
		_pop("interrupted", Color(0.75, 0.75, 0.75))
	_pop("-%d" % maxi(1, roundi(amount)), Color(1.0, 0.45, 0.4))
	if from != target and not retreating and _outmatched(from) and kind == Kind.PLAYER and (ai_enabled or not is_hero):
		start_retreat()                # mid-fight, something far stronger joins in: get out
	if target == null and not recovering and not retreating:
		if _outmatched(from) and (kind != Kind.PLAYER or ai_enabled or not is_hero):
			start_retreat()            # far too strong: run for a healer in a safe town
		else:
			target = from              # fight back
	if hp <= 0.0:
		_die(from)


func _die(killer: Entity) -> void:
	if mounted_on != null:
		dismount()                           # thrown from the saddle
	dead = true
	effects.clear()
	_recompute_effects()
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
	game.event_about("%s was slain by %s" % [display_name, killer.display_name], is_hero or killer.is_hero or (killer.kind == Kind.PET and killer.pet_owner != null and killer.pet_owner.is_hero))
	game.on_kill(killer, self)
	if is_hero:
		game.count("hero_deaths")
		game.glitch(1.0, 0.8)
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
	path.clear()                  # an old route (e.g. a ghost's walk to the healer) starts somewhere else
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
			hp = minf(hp, float(stats.max_hp()))
			game.event_about("%s was raised at a shrine (murderer: -20%% stats and skills)." % display_name, is_hero)
		else:
			game.event_about("%s was raised at a shrine (-10%% skills)." % display_name, is_hero)
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
	if tame_timer > 0.0 or (tame_target != null and target == null):
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
	if kind == Kind.PLAYER:
		var g := guild_abbr()
		text = "%s\n%sLv %d  HP %d/%d" % [title_name(), ("[%s] " % g) if g != "" else "", stats.level(), ceili(hp), stats.max_hp()]
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
	if effects.has("hiding"):
		text += "\n(hidden)"
	elif flags.has("invisible"):
		text += "\n(invisible)"
	if flags.has("incognito") and kind == Kind.PLAYER:
		text = text.replace(display_name, "Someone")
	if paralyzed_timer > 0.0:
		text += "\n(paralyzed)"
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
	return spellbook.has(id) and mana >= float(sp["mana"]) and reagents >= float(sp["reagents"]) \
		and _skill(Hero.Skill.MAGERY) >= float(sp["min"])


func _why_not(id: String) -> String:
	var sp: Dictionary = Spells.LIST[id]
	if not spellbook.has(id):
		return "%s is not in your spellbook: find or buy its scroll." % sp["name"]
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
	if flags.has("invisible") and String(sp["kind"]) in HARMFUL_KINDS:
		_end_flag("invisible")
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
	var raising := String(sp["kind"]) == "resurrect"
	if tgt == null or (tgt.dead != raising) or (tgt != self and position.distance_to(tgt.position) > SPELL_RANGE + 1.0):
		_pop("fizzle", Color(0.75, 0.75, 0.75))
		return
	if randf() >= Rules.cast_chance(_skill(Hero.Skill.MAGERY), float(sp["min"])):
		_pop("fizzle", Color(0.75, 0.75, 0.75))
		return
	var spell_kind := String(sp["kind"])
	# Magic Reflection turns one harmful spell back on its caster.
	if tgt != self and spell_kind in HARMFUL_KINDS and tgt.flags.has("magic_reflection"):
		tgt._end_flag("magic_reflection")
		tgt._pop("reflected", Color(0.9, 0.9, 1.0))
		tgt = self
	if spell_kind in ["paralyze", "resurrect", "summon", "buff", "curse", "drain", "field", "dispel", "util"]:
		match spell_kind:
			"paralyze":
				_paralyze(tgt)
			"resurrect":
				if tgt.ghost and tgt.notoriety() != Notoriety.RED:
					tgt._resurrect_free(self)
					add_karma(100)
					if is_hero:
						game.count("resurrected_others")
			"summon":
				game.summon_creature(self, id)
			"buff":
				add_effect(id, sp)
			"curse":
				_curse(tgt, id, sp)
			"drain":
				_drain(tgt, sp)
			"field":
				game.add_field(self, id, tgt.position)
			"dispel":
				_dispel(tgt, sp)
			"util":
				_util_spell(id, sp, tgt)
		if is_hero:
			game.count("spell_" + id)
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.MAGERY)
		return
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
		if not _spell_fire(id, tgt):
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
			if can_cast("arch_cure") and _poisoned_friends(5.0) > 0:
				cure_id = "arch_cure"
			return start_cast(cure_id, self)
	# Poison is an opener: cast once at a new target, then move on to damage spells.
	if target != null and target != last_poison_target and target.poison_level == 0 and d <= SPELL_RANGE:
		var poison_id := _best_spell("poison")
		if poison_id != "":
			last_poison_target = target
			return start_cast(poison_id, target)
	if _try_support_magic(d):
		return true
	# Losing a melee: freeze the foe, then heal or walk away while it can't follow.
	if hp < float(stats.max_hp()) * 0.5 and target != null and target.paralyzed_timer <= 0.0 \
			and target.attack_range() <= MELEE_RANGE and d <= SPELL_RANGE:
		var para_id := _best_spell("paralyze")
		if para_id != "":
			return start_cast(para_id, target)
	if hp < float(stats.max_hp()) * 0.5:
		var heal_id := _best_spell("heal")
		if heal_id != "":
			return start_cast(heal_id, self)
	# A tough foe: call up an Earth Elemental to fight beside you.
	if target != null and target.danger >= 4.0 and (summon == null or summon.dead) \
			and kind == Kind.PLAYER:
		var summon_id := _best_spell("summon")
		if summon_id != "":
			return start_cast(summon_id, self)
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
		if kind != Kind.PLAYER and k not in MONSTER_KINDS:
			continue                       # monsters stick to plain combat magic
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
	var m := _nearest_role("merchant")
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
		if is_hero and id == game.quest_item():
			continue                       # wanted for a fetch quest
		if Items.is_tool_item(id) or (id == "log" and int(inventory[id]) <= 2):
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
		if kind == Kind.PLAYER and not has_instrument() and gold >= lute + SUPPLY_RESERVE:
			_pay(s, lute)
			inventory["lute"] = 1
			if is_hero:
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
			if gold >= tp + TOOL_RESERVE:      # tools earn the gold back: a small reserve will do
				_pay(s, tp)
				inventory[tool] = 1
				tool_uses[tool] = TOOL_USES
				if is_hero:
					game.log_event("You buy a %s." % Items.item_name(tool))
		_buy_scroll(s)
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
		# Spell scrolls: tougher monsters carry higher circles.
		if int(loot_cfg.get("gold_max", 0)) > 0 and randf() < SCROLL_DROP_CHANCE:
			var hi := clampi(1 + int(danger), 1, 8)
			var spell := Spells.random_of_circles(maxi(1, hi - 3), hi)
			if spell != "":
				var sid := Spells.scroll_id(spell)
				items[sid] = int(items.get(sid, 0)) + 1
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
			if position.distance_to(loot_target.position) <= SPELL_RANGE and casting_id == "" \
					and cast_cd <= 0.0 and can_cast("telekinesis"):
				cast_corpse = loot_target          # pull it over with Telekinesis
				loot_target = null
				return start_cast("telekinesis", self)
			loot_target = null        # unreachable
			return false
		return true
	path.clear()
	_take(loot_target)
	loot_target = null
	return true


func _take(c: Corpse) -> void:
	var got: Dictionary = c.take_all()
	game.show_loot(c.position, self, got, c.title if c.title != "" else "%s's corpse" % c.owner_name)
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
	learn_scrolls()
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
## Off once the player has chosen gear by hand (the Bag screen can turn it back on).
func _manage_gear() -> void:
	if not auto_equip:
		return
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
	refresh_look()
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
		var me: Entity = game.hero
		if me != null and me != self:
			if me.at_war_with(self):
				return Color(1.0, 0.6, 0.15)    # orange: at war with your guild
			if me.friends_with(self):
				return Color(0.4, 1.0, 0.4)     # green: your guild or an ally
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
	game.event_about("%s is guilty of murdering %s." % [display_name, victim.display_name], is_hero or victim.is_hero)
	if murder_counts == MURDERER_COUNTS:
		game.event_about("%s is now a murderer!" % display_name, is_hero)


## On death: pay the bounty on a murderer and charge anyone who recently hit an innocent us.
func _settle_crimes(killer: Entity) -> void:
	if died_red and killer.kind == Kind.PLAYER and murder_counts > 0:
		var bounty := murder_counts * BOUNTY_PER_COUNT
		killer._earn(bounty)
		if killer.is_hero:
			game.count("bounties")
		game.event_about("%s collects a %d gold bounty on %s." % [killer.display_name, bounty, display_name], is_hero or killer.is_hero)
	for id in attackers.keys():
		var a := instance_from_id(int(id)) as Entity
		if a != null and not a.dead:
			a._add_murder(self)
	attackers.clear()


func _in_town() -> bool:
	return world.is_town(world.to_tile(position))


## Monsters keep out of the towns (and give up a chase at the edge). Players of any repute may
## come in: towns are safe for everyone.
func _avoids_town() -> bool:
	if dead:
		return false
	return kind == Kind.MONSTER


## Players fight monsters and criminals; player killers also prey on innocents.
## Nobody starts a fight in (or into, or out of) a town: towns are safe.
func _is_fair_target(e: Entity) -> bool:
	if e.parked:
		return false                       # a mount under its rider
	if _in_town() or e._in_town():
		return false
	if e.flags.has("invisible"):
		return false                       # can't fight what you can't see
	if kind == Kind.MONSTER:
		if passive or aggro_range <= 0.0:
			return false                   # wildlife that never starts a fight
		return e.kind == Kind.PLAYER or e.kind == Kind.PET   # monsters hit players and their pets
	if e.kind == Kind.MONSTER:
		return not e.passive or e.target == self   # leave grazing animals be unless they bite
	if e.kind != Kind.PLAYER or _in_town() or e._in_town():
		return false
	if at_war_with(e):
		return true                        # guild war: fair game anywhere outside town
	if friends_with(e) or _trammel():
		return false                       # guildmates and allies; and no PvP at all in Trammel
	if is_pk:
		return not e.is_young() and not e.flags.has("incognito")   # young or unrecognised: left alone
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
## A monster far stronger than this player (a player on Auto runs instead of fighting it).
func _outmatched(e: Entity) -> bool:
	return kind == Kind.PLAYER and e != null and e.kind == Kind.MONSTER and e.threat() > power() + 1.5


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
	for mi in model.get("meshes", []):
		(mi as MeshInstance3D).transparency = t


## Builds (or rebuilds, when gear changes) the low-poly model from the look, role and gear.
func refresh_look() -> void:
	if rig == null:
		return
	if model.has("root"):
		(model["root"] as Node3D).queue_free()
	if model.has("mount_root"):
		(model["mount_root"] as Node3D).queue_free()
	model = Art.creature(look, _look_style(), visual_scale)
	rig.add_child(model["root"])
	if look == "fire_elemental":
		var sparks := Fx.embers(0.5)
		sparks.position.y = 1.0
		(model["root"] as Node3D).add_child(sparks)
	if mounted_on != null:
		# Sitting in the saddle: the mount's legs do the walking, the rider's hang still.
		var m := Art.creature(mounted_on.look, {}, mounted_on.visual_scale)
		rig.add_child(m["root"])
		(model["root"] as Node3D).position.y = 0.62 * mounted_on.visual_scale
		for leg in model["legs"]:
			(leg as Node3D).rotation.x = -1.2
		model["legs"] = m["legs"]
		model["quad"] = true
		(model["meshes"] as Array).append_array(m["meshes"])
		model["mount_root"] = m["root"]
	if ghost or flags.has("invisible"):
		_set_ghost_look(true)


func _look_style() -> Dictionary:
	var mage := kind == Kind.PLAYER and _skill(Hero.Skill.MAGERY) >= 50.0 and armor_id == ""
	var st := {
		"skin": Art.pick(Art.SKINS, display_name), "hair": Art.pick(Art.HAIRS, display_name + "h"),
		"cloth": spawn_color, "armor": armor_id, "weapon": weapon, "shield": shield_id,
		"robe": mage or role == "healer" or role == "priest",
		"hat": "mage" if mage else "",
	}
	match role:
		"merchant", "banker", "vendor":
			st["hat"] = "cap"
		"priest":
			st["hat"] = "hood"
	return st


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
		return       # healers turn criminals and murderers away
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
	game.event_about("%s resurrects %s." % [healer.display_name, display_name], is_hero)


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


## Worth a trip to the forge: ore to smelt (no tool needed), or materials to craft with a tool kit.
func _has_craft_load() -> bool:
	if Crafting.ore_count(inventory) >= 5:
		return true
	if Crafting.count(inventory, "tool_kit") <= 0:
		return false
	return Crafting.ingot_count(inventory) >= 3 \
		or Crafting.count(inventory, "wolf_pelt") >= 3 or Crafting.count(inventory, "log") >= 5


## With enough materials, walk to the forge, smelt and craft. Returns true while busy.
func _craft_trip() -> bool:
	if not crafting_trip and craft_cd <= 0.0 and _has_craft_load() and gather_tile.x < 0:
		crafting_trip = true
	if not crafting_trip:
		return false
	if world.near_forge(position):
		crafting_trip = false
		var before := inventory.duplicate()
		craft_at_forge()
		if inventory == before:
			craft_cd = 120.0               # nothing could be made: don't keep coming back
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
	var banker := _nearest_role("banker")
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
		if String(sp["name"]) == "Meteor Swarm" and _near_hero():
			Fx.meteor(get_parent(), e.position, randf_range(0.0, 0.4))
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
	if not spellbook.has(id):
		return "it is not in your spellbook"
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
		game.property.mark_rune(world.to_tile(position))
		game.log_event("You mark a rune here, in %s (%d of %d in your runebook)." % [
			world.place_name(world.to_tile(position)), game.property.runes.size(), Property.MAX_RUNES])
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
	if is_hero:
		game.glitch(0.7, 0.35)


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
	if model.is_empty():
		return
	var stride := sin(anim_t * 11.0) * 0.6 if moving and not ghost else 0.0
	var legs: Array = model["legs"]
	for i in range(legs.size()):
		# two legs: left/right alternate; four: front-left with back-right, front-right with back-left
		var phase := 1.0 if (i % 2 == 0) == (i < 2 or not bool(model["quad"])) else -1.0
		(legs[i] as Node3D).rotation.x = stride * phase
	var arm: Node3D = model["arm"]
	if arm != null:
		var rest := float(model["arm_rest"])
		if swing_anim > 0.0:
			arm.rotation.x = rest - 1.5 * sin(swing_anim / SWING_ANIM * PI)
		elif casting_id != "":
			arm.rotation.x = rest - 1.2 - sin(anim_t * 8.0) * 0.2
		elif gather_tile.x >= 0:
			arm.rotation.x = rest - maxf(sin(anim_t * 6.0), 0.0) * 1.3
		else:
			arm.rotation.x = rest - stride * 0.5
	var spin: Node3D = model["spin"]
	if spin != null:
		spin.rotation.y += delta * 6.0


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
	elif hp < float(stats.max_hp()) * 0.6 and Crafting.count(inventory, "bread") > 0 \
			and _nearest(Kind.MONSTER, 4.0) == null:
		drink = "bread"
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
		"bread":
			hp = minf(hp + 10.0, float(stats.max_hp()))
			_pop("+10", Color(0.5, 1.0, 0.5))
	if is_hero:
		game.count("food_eaten" if drink == "bread" else "potions_drunk")
		game.log_event(("You eat a %s." if drink == "bread" else "You drink a %s.") % Items.item_name(drink))
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
func _tame_step(delta: float) -> bool:
	if tame_target == null:
		return false
	if not is_instance_valid(tame_target) or can_tame(tame_target) != "":
		tame_target = null
		return false
	if position.distance_to(tame_target.position) > 2.5:
		tame_walk += delta
		if tame_walk > 15.0:
			tame_walk = 0.0
			tame_target = null
			tame_cd = TAME_COOLDOWN              # it keeps wandering off: leave it be
			return false
		if path.is_empty() or repath_timer <= 0.0:
			repath_timer = 0.5
			if not go_to(tame_target.position) and position.distance_to(tame_target.position) > 2.5:
				tame_target = null
				tame_cd = TAME_COOLDOWN          # couldn't reach it: try something else for a while
				return false
		return true
	path.clear()
	tame_walk = 0.0
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
		if npc.kind != Kind.NPC:
			continue
		if beg_cd.has(npc.get_instance_id()) or position.distance_to(npc.position) > 3.0:
			continue
		beg_cd[npc.get_instance_id()] = now + 300000
		if randf() < Rules.beg_chance(_skill(Hero.Skill.BEGGING)):
			var coins := randi_range(2, 5 + int(_skill(Hero.Skill.BEGGING) / 10.0))
			_earn(coins)
			add_karma(-15)                   # begging is a little shameful
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


# --- the priest -------------------------------------------------------------

## The priest serves innocent players standing nearby (criminals and murderers are turned away).
func _priest_aura(delta: float) -> void:
	var list: Array = game.creatures
	for item in list:
		var other := item as Entity
		if other.dead or other.kind != Kind.PLAYER or other.notoriety() != Notoriety.BLUE:
			continue
		if position.distance_to(other.position) <= PRIEST_RANGE:
			other.visit_priest(delta, self)


## Standing by the priest: poison is cured for free, a blessing is bought when there is gold to
## spare, and murder counts can be confessed away one at a time.
func visit_priest(delta: float, priest: Entity) -> void:
	_priest_timer += delta
	if _priest_timer < 1.0:
		return
	_priest_timer = 0.0
	if poison_level > 0:
		_cure("cured by %s" % priest.display_name)
		if is_hero:
			game.log_event("%s draws the poison out of you." % priest.display_name)
			game.count("priest_cured")
		return
	if murder_counts > 0 and gold >= CONFESS_PRICE + SUPPLY_RESERVE:
		_spend(CONFESS_PRICE)
		add_karma(150)
		murder_counts -= 1
		murder_timer = MURDER_DECAY
		if is_hero:
			game.log_event("You confess to %s. One murder count is lifted (%d left)." % [priest.display_name, murder_counts])
			game.count("confessed")
		return
	if bless_timer <= 0.0 and gold >= BLESS_PRICE + SUPPLY_RESERVE:
		_spend(BLESS_PRICE)
		bless_timer = BLESS_SECONDS
		_pop("blessed", Color(1.0, 0.95, 0.6))
		if is_hero:
			game.log_event("%s blesses you: +10%% damage, -10%% damage taken for 5 minutes (%d gold)." % [priest.display_name, BLESS_PRICE])
			game.count("blessed")


# --- spellbook, scrolls, Paralyze, summons, Resurrection ---------------------

## Copies every scroll of a spell not yet known into the spellbook (the scroll is used up).
func learn_scrolls() -> void:
	for id in inventory.keys():
		var spell := Spells.spell_of_scroll(String(id))
		if spell == "" or spellbook.has(spell):
			continue
		spellbook[spell] = true
		Crafting.take_mats(inventory, {id: 1}, 1.0)
		if is_hero:
			game.log_event("You copy %s into your spellbook." % Spells.LIST[spell]["name"])
			game.count("scrolls_learned")


## At the merchant: a caster buys the cheapest scroll of a spell it could already cast.
func _buy_scroll(s: Shop) -> void:
	if kind != Kind.PLAYER or _skill(Hero.Skill.MAGERY) < 10.0:
		return
	var best := ""
	var best_price := 1 << 30
	for id in Spells.ORDER:
		var sp: Dictionary = Spells.LIST[id]
		if spellbook.has(id) or int(sp["circle"]) > SHOP_SCROLL_CIRCLES \
				or _skill(Hero.Skill.MAGERY) < float(sp["min"]):
			continue
		var p := s.price(Items.scroll_price(Spells.scroll_id(id)))
		if p < best_price:
			best_price = p
			best = id
	if best == "" or gold < best_price + SUPPLY_RESERVE:
		return
	_pay(s, best_price)
	inventory[Spells.scroll_id(best)] = 1
	if is_hero:
		game.log_event("You buy a %s for %d gold." % [Items.item_name(Spells.scroll_id(best)), best_price])
	learn_scrolls()


func _paralyze(tgt: Entity) -> void:
	if randf() < Rules.resist_chance(tgt._skill(Hero.Skill.RESISTING_SPELLS)):
		tgt._pop("resisted", Color(0.7, 0.9, 1.0))
		return
	tgt.paralyzed_timer = Spells.PARALYZE_BASE + _skill(Hero.Skill.MAGERY) / 25.0
	tgt.path.clear()
	if tgt.casting_id != "":
		tgt._fizzle("paralyzed")
	tgt._pop("paralyzed", Color(0.85, 0.7, 1.0))
	if is_hero:
		game.count("paralyzed")


## A ghost player close by (not a murderer) gets raised by anyone who knows Resurrection.
func _try_resurrect_others() -> bool:
	if casting_id != "" or cast_cd > 0.0 or not can_cast("resurrection"):
		return false
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == self or not e.ghost or e.kind != Kind.PLAYER or e.notoriety() == Notoriety.RED:
			continue
		if position.distance_to(e.position) <= SPELL_RANGE:
			return start_cast("resurrection", e)
	return false


## The summoned elemental crumbles: gone for good, like a dead pet.
func _unsummon() -> void:
	dead = true
	visible = false
	dead_timer = INF
	path.clear()
	target = null
	if pet_owner != null and is_instance_valid(pet_owner):
		pet_owner.pets.erase(self)
		if pet_owner.is_hero:
			game.log_event("Your %s fades away." % display_name)


# --- the full spell list: effects, curses, drains, dispels and one-off spells -------------

## A buff or curse from `id` (its "mods" and/or "flag"), replacing an earlier cast of it.
func add_effect(id: String, sp: Dictionary) -> void:
	effects[id] = {"secs": float(sp.get("secs", 60.0)), "mods": sp.get("mods", {}),
		"flag": String(sp.get("flag", ""))}
	_recompute_effects()
	_pop(String(sp["name"]), sp["color"])


func _effects_tick(delta: float) -> void:
	var changed := false
	for k in effects.keys():
		effects[k]["secs"] = float(effects[k]["secs"]) - delta
		if float(effects[k]["secs"]) <= 0.0:
			effects.erase(k)
			changed = true
	if changed:
		_recompute_effects()


## Sums the stat changes and flags of everything active, and keeps HP, mana and stamina in range.
func _recompute_effects() -> void:
	var m := {"str": 0, "dex": 0, "int": 0}
	flags.clear()
	for k in effects:
		var e: Dictionary = effects[k]
		var mods: Dictionary = e["mods"]
		for stat in mods:
			m[stat] = int(m.get(stat, 0)) + int(mods[stat])
		if String(e["flag"]) != "":
			flags[String(e["flag"])] = true
	stats.str_mod = int(m["str"])
	stats.dex_mod = int(m["dex"])
	stats.int_mod = int(m["int"])
	hp = minf(hp, float(stats.max_hp()))
	mana = minf(mana, float(stats.max_mana()))
	stamina = minf(stamina, float(stats.max_stamina()))
	if rig != null:
		rig.scale = Vector3.ONE * (1.25 if flags.has("polymorph") else 1.0)
	if not model.is_empty() and not ghost:
		_set_ghost_look(flags.has("invisible"))


func _end_flag(flag: String) -> void:
	for k in effects.keys():
		if String(effects[k]["flag"]) == flag:
			effects.erase(k)
	_recompute_effects()


## Reactive Armor: part of a blow comes back to the attacker (no crime: it is your armor).
func _reflect_blow(amount: float, from: Entity) -> void:
	hp -= amount
	_pop("-%d" % maxi(1, roundi(amount)), Color(1.0, 0.6, 0.3))
	if hp <= 0.0:
		_die(from)


## Stat buffs don't stack: one of Polymorph, Bless, Strength or Agility at a time.
func _buff_active(id: String) -> bool:
	if id in ["polymorph", "bless", "strength", "agility"]:
		for k in ["polymorph", "bless", "strength", "agility"]:
			if effects.has(k):
				return true
		return false
	return effects.has(id)


func _curse(tgt: Entity, id: String, sp: Dictionary) -> void:
	var victims: Array[Entity] = []
	if bool(sp.get("area", false)):
		var list: Array = game.creatures
		for item in list:
			var e := item as Entity
			if e != self and not e.dead and _is_fair_target(e) and position.distance_to(e.position) <= Spells.AREA_RADIUS:
				victims.append(e)
	elif tgt != self:
		victims.append(tgt)
	for v in victims:
		if randf() < Rules.resist_chance(v._skill(Hero.Skill.RESISTING_SPELLS)):
			v._pop("resisted", Color(0.7, 0.9, 1.0))
		else:
			v.add_effect(id, sp)


## Mana Drain takes a foe's mana; Mana Vampire keeps it.
func _drain(tgt: Entity, sp: Dictionary) -> void:
	var amount := randf_range(float(sp["min_dmg"]), float(sp["max_dmg"])) * (1.0 + _skill(Hero.Skill.MAGERY) / 200.0)
	if randf() < Rules.resist_chance(tgt._skill(Hero.Skill.RESISTING_SPELLS)):
		amount *= 0.5
		tgt._pop("resisted", Color(0.7, 0.9, 1.0))
	var took := minf(tgt.mana, amount)
	tgt.mana -= took
	tgt._pop("-%d mana" % roundi(took), Color(0.4, 0.5, 1.0))
	if bool(sp.get("steal", false)):
		mana = minf(mana + took, float(stats.max_mana()))


func _dispel(tgt: Entity, sp: Dictionary) -> void:
	match String(sp.get("field", "")):
		"trap":
			game.remove_fields(position, 3.0, ["trap"])
		"any":
			game.remove_fields(tgt.position, 3.0, [])
		"summon":
			if tgt.summoned:
				tgt._pop("dispelled", Color(0.7, 0.8, 1.0))
				tgt._unsummon()
			else:
				tgt._pop("nothing to dispel", Color(0.75, 0.75, 0.75))
		"all":
			var list: Array = game.creatures
			for item in list:
				var e := item as Entity
				if e.summoned and not e.dead and e.pet_owner != self and position.distance_to(e.position) <= Spells.AREA_RADIUS:
					e._pop("dispelled", Color(0.7, 0.8, 1.0))
					e._unsummon()
			game.remove_fields(position, Spells.AREA_RADIUS, [])


func _util_spell(id: String, sp: Dictionary, tgt: Entity) -> void:
	match id:
		"create_food":
			inventory["bread"] = mini(int(inventory.get("bread", 0)) + 1, 5)
			_pop("a loaf of bread", sp["color"])
		"telekinesis":
			var c := cast_corpse
			cast_corpse = null
			if c != null and is_instance_valid(c) and not c.is_empty() and c.can_loot(self) \
					and position.distance_to(c.position) <= SPELL_RANGE + 1.0:
				_take(c)
			else:
				_pop("nothing to take", Color(0.75, 0.75, 0.75))
		"magic_lock":
			var c := cast_corpse if cast_corpse != null and is_instance_valid(cast_corpse) else _nearest_corpse(SPELL_RANGE, false)
			cast_corpse = null
			if c != null:
				c.sealed_by = get_instance_id()
				_pop("sealed", sp["color"])
				if is_hero:
					game.log_event("You seal the corpse: only you can loot it now.")
		"unlock":
			var c := _nearest_corpse(SPELL_RANGE, true)
			if c != null:
				c.sealed_by = 0
				_pop("unsealed", sp["color"])
		"teleport":
			_teleport_away()
		"arch_cure":
			var list: Array = game.creatures
			for item in list:
				var e := item as Entity
				if e.dead or e.poison_level <= 0 or position.distance_to(e.position) > 5.0:
					continue
				if e == self or (e.kind == Kind.PLAYER and e.notoriety() == Notoriety.BLUE) or e.pet_owner == self:
					if randf() < Rules.cure_chance(_skill(Hero.Skill.MAGERY), e.poison_level):
						e._cure("cured")
		"arch_protection":
			var list: Array = game.creatures
			for item in list:
				var e := item as Entity
				if e.dead or position.distance_to(e.position) > 5.0:
					continue
				if e == self or (e.kind == Kind.PLAYER and e.notoriety() == Notoriety.BLUE) or e.pet_owner == self:
					e.add_effect("arch_protection", sp)
		"reveal":
			var list: Array = game.creatures
			for item in list:
				var e := item as Entity
				if e != self and e.flags.has("invisible") and position.distance_to(e.position) <= 8.0:
					e._end_flag("invisible")
					e._pop("revealed", Color(1.0, 1.0, 0.8))


## AI: dispel summoned foes, curse dangerous ones, drain casters, buff up, and lay fields
## under groups. Returns true if a spell was started.
func _try_support_magic(d: float) -> bool:
	if target == null or d > SPELL_RANGE:
		return false
	var magery := _skill(Hero.Skill.MAGERY)
	if target.summoned:
		for id in ["dispel", "mass_dispel"]:
			if can_cast(id):
				return start_cast(id, target)
	if target != last_curse_target and (target.danger >= 3.0 or target.kind == Kind.PLAYER):
		if _count_fair_targets(Spells.AREA_RADIUS) >= 3 and can_cast("mass_curse"):
			last_curse_target = target
			return start_cast("mass_curse", self)
		for id in CURSE_ORDER:
			if can_cast(id) and Rules.cast_chance(magery, float(Spells.LIST[id]["min"])) >= 0.3:
				last_curse_target = target
				return start_cast(id, target)
	if drain_cd <= 0.0 and target.mana >= 15.0 and target._skill(Hero.Skill.MAGERY) >= 30.0:
		for id in ["mana_vampire", "mana_drain"]:
			if can_cast(id):
				drain_cd = 12.0
				return start_cast(id, target)
	if kind != Kind.PLAYER:
		return false
	if mana >= float(stats.max_mana()) * 0.6:
		for id in BUFF_ORDER:
			if not can_cast(id) or _buff_active(id) or Rules.cast_chance(magery, float(Spells.LIST[id]["min"])) < 0.3:
				continue
			if id == "reactive_armor" and target.attack_range() > MELEE_RANGE:
				continue
			if id == "magic_reflection" and target._skill(Hero.Skill.MAGERY) < 30.0:
				continue
			return start_cast(id, self)
	if field_cd <= 0.0 and _foes_near(target.position, 2.5) >= 2:
		for id in ["paralyze_field", "poison_field", "fire_field"]:
			if can_cast(id):
				field_cd = 15.0
				return start_cast(id, target)
	return false


## Recovering with a foe close: vanish, blink away, or wall it off.
func _try_escape_magic() -> bool:
	var foe := _nearest_threat(5.0)
	if foe == null:
		return false
	if not flags.has("invisible") and can_cast("invisibility"):
		return start_cast("invisibility", self)
	if can_cast("teleport"):
		return start_cast("teleport", self)
	if field_cd <= 0.0:
		for id in ["energy_field", "wall_of_stone"]:
			if can_cast(id):
				field_cd = 12.0
				return start_cast(id, foe)
	return false


## Idle players: bake a loaf or two, and the hero lights up the night.
func _try_idle_magic() -> bool:
	if casting_id != "" or cast_cd > 0.0:
		return false
	if Crafting.count(inventory, "bread") < 2 and mana >= float(stats.max_mana()) * 0.9 and can_cast("create_food"):
		return start_cast("create_food", self)
	if is_hero and game.is_night() and not flags.has("night_sight") and can_cast("night_sight"):
		return start_cast("night_sight", self)
	return false


func _poisoned_friends(radius: float) -> int:
	var n := 0
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e != self and not e.dead and e.poison_level > 0 and e.kind == Kind.PLAYER \
				and e.notoriety() == Notoriety.BLUE and position.distance_to(e.position) <= radius:
			n += 1
	return n


func _foes_near(p: Vector3, radius: float) -> int:
	var n := 0
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e != self and not e.dead and _is_fair_target(e) and p.distance_to(e.position) <= radius:
			n += 1
	return n


## The closest creature that is after us.
func _nearest_threat(radius: float) -> Entity:
	var best: Entity = null
	var best_d := radius
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.dead or e == self or e.target != self:
			continue
		var dd := position.distance_to(e.position)
		if dd <= best_d:
			best = e
			best_d = dd
	return best


func _nearest_corpse(radius: float, sealed_only: bool) -> Corpse:
	var best: Corpse = null
	var best_d := radius
	var list: Array = game.corpses
	for item in list:
		var c := item as Corpse
		if c.is_empty() or (sealed_only and c.sealed_by == 0) or (not sealed_only and not c.can_loot(self)):
			continue
		var dd := position.distance_to(c.position)
		if dd <= best_d:
			best = c
			best_d = dd
	return best


## Teleport: blink up to 8 tiles away from whatever is chasing us (or towards a healer).
func _teleport_away() -> void:
	var foe := _nearest_threat(10.0)
	var dir := Vector3.ZERO
	if foe != null:
		dir = (position - foe.position).normalized()
	else:
		var h := _nearest_role("healer")
		if h != null:
			dir = (h.position - position).normalized()
	if dir.length() < 0.1:
		dir = Vector3(1, 0, 0)
	for k in range(8, 2, -1):
		var c := world.to_tile(position + dir * float(k))
		if world.is_blocked(c) or (_avoids_town() and world.is_town(c)):
			continue
		var dest := world.tile_center(c)
		if world.find_path(dest, position).is_empty() and world.to_tile(position) != c:
			continue
		_pop("teleport", Color(0.6, 0.8, 1.0))
		teleport_to(dest)
		return
	_pop("no room to teleport", Color(0.75, 0.75, 0.75))


## Menu > Travel & Spellbook: cast any known spell. Picks a sensible target for its kind.
func cast_from_book(id: String) -> void:
	var sp: Dictionary = Spells.LIST[id]
	if not can_cast(id):
		game.log_event(_why_not(id))
		return
	var k := String(sp["kind"])
	var tgt: Entity = self
	if k in ["attack", "poison", "paralyze", "drain"] or (k == "field" and id != "magic_trap") \
			or (k == "curse" and not bool(sp.get("area", false))):
		tgt = target if target != null and is_instance_valid(target) and not target.dead else _nearest_foe(SPELL_RANGE)
	elif k == "dispel" and String(sp.get("field", "")) == "summon":
		tgt = _nearest_summon(SPELL_RANGE)
	elif k == "resurrect":
		tgt = _nearest_ghost(SPELL_RANGE)
	elif id in ["telekinesis", "magic_lock", "unlock"]:
		cast_corpse = _nearest_corpse(SPELL_RANGE, id == "unlock")
		if cast_corpse == null:
			game.log_event("There is no corpse in range for that.")
			return
	if tgt == null:
		game.log_event("No target in range.")
		return
	if tgt != self and (k in HARMFUL_KINDS or k == "field"):
		target = tgt                        # a harmful spell starts a fight with its victim
	loot_target = null
	gather_tile = Vector2i(-1, -1)
	start_cast(id, tgt)


func _nearest_foe(radius: float) -> Entity:
	var best: Entity = null
	var best_d := radius
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == self or e.dead or not _is_fair_target(e):
			continue
		var dd := position.distance_to(e.position)
		if dd <= best_d:
			best = e
			best_d = dd
	return best


func _nearest_summon(radius: float) -> Entity:
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.summoned and not e.dead and e.pet_owner != self and position.distance_to(e.position) <= radius:
			return e
	return null


func _nearest_ghost(radius: float) -> Entity:
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e != self and e.ghost and e.kind == Kind.PLAYER and position.distance_to(e.position) <= radius:
			return e
	return null


# --- society: fame, karma, titles, guilds, rulesets ----------------------------------------

func _trammel() -> bool:
	return game.property.ruleset == "trammel"


func guild_id() -> String:
	return game.guilds.guild_of(display_name) if kind == Kind.PLAYER else ""


func guild_abbr() -> String:
	return game.guilds.abbr(guild_id())


## Same guild or allied guilds (players only).
func friends_with(e: Entity) -> bool:
	if e == self or kind != Kind.PLAYER or e.kind != Kind.PLAYER:
		return false
	return game.guilds.allied(guild_id(), e.guild_id())


func at_war_with(e: Entity) -> bool:
	if e == self or kind != Kind.PLAYER or e.kind != Kind.PLAYER:
		return false
	return game.guilds.at_war(guild_id(), e.guild_id())


func title() -> String:
	return Rules.title(fame, karma)


func title_name() -> String:
	var t := title()
	return display_name if t == "" else "%s the %s" % [display_name, t]


## Gains slow down near the top (and losses near the bottom), as in the classic game.
func add_fame(n: int) -> void:
	var before := title()
	if n > 0:
		n = maxi(1, roundi(n * (1.0 - float(fame) / 12000.0)))
	fame = clampi(fame + n, 0, Rules.FAME_MAX)
	_title_changed(before)


func add_karma(n: int) -> void:
	var before := title()
	if n > 0:
		n = maxi(1, roundi(n * (1.0 - float(maxi(karma, 0)) / 12000.0)))
	karma = clampi(karma + n, -Rules.KARMA_MAX, Rules.KARMA_MAX)
	_title_changed(before)


func _title_changed(before: String) -> void:
	if is_hero and title() != before:
		game.log_event("You are now known as %s." % title_name())
		game.count("title_changes")


## Fame and karma for a kill: monsters give fame (and karma, unless just an animal); criminals
## and murderers give karma; an innocent costs a lot of it; guild-war kills give fame only.
func reputation_for_kill(v: Entity) -> void:
	if v.kind == Kind.MONSTER or v.kind == Kind.PET:
		add_fame(roundi(v.danger * 30.0))
		if not v.passive and v.species == "":
			add_karma(roundi(v.danger * 20.0))
	elif v.kind == Kind.PLAYER:
		if at_war_with(v):
			add_fame(100)
		elif v.notoriety() != Notoriety.BLUE:
			add_fame(100)
			add_karma(150)
		else:
			add_fame(50)
			add_karma(-700)


# --- thieves: Hiding, Stealth, Detecting Hidden, Snooping, Stealing -----------------------

## Hiding: vanish from sight while standing still (Stealth lets you walk a little).
func try_hide() -> bool:
	if dead or hide_cd > 0.0 or effects.has("hiding"):
		return false
	hide_cd = 8.0
	if _nearest_threat(3.0) != null:
		_pop("they're watching you", Color(0.75, 0.75, 0.75))
		return false
	var ok := randf() < Rules.hide_chance(_skill(Hero.Skill.HIDING))
	if kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.HIDING)
	if not ok:
		_pop("you fail to hide", Color(0.75, 0.75, 0.75))
		return false
	effects["hiding"] = {"secs": 600.0, "mods": {}, "flag": "invisible"}
	_recompute_effects()
	stealth_left = Rules.stealth_distance(_skill(Hero.Skill.STEALTH))
	path.clear()
	target = null
	_pop("hidden", Color(0.8, 0.8, 0.7))
	if is_hero:
		game.count("hid")
	return true


## Detecting Hidden: look for anyone hiding close by.
func detect_hidden() -> int:
	var found := 0
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == self or e.dead or not e.flags.has("invisible") or position.distance_to(e.position) > 6.0:
			continue
		if randf() < Rules.detect_chance(_skill(Hero.Skill.DETECTING_HIDDEN), e._skill(Hero.Skill.HIDING)):
			e._end_flag("invisible")
			e._pop("revealed", Color(1.0, 1.0, 0.8))
			found += 1
	if kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.DETECTING_HIDDEN)
	return found


## Why we can't snoop on or steal from `v` right now, or "" if we can.
func theft_problem(v: Entity) -> String:
	if v == null or v.dead or v == self:
		return "there is nobody to rob"
	if v.kind == Kind.NPC or v.kind == Kind.MONSTER:
		return "only other players carry bags worth robbing"
	if _trammel():
		return "stealing from players is not allowed in Trammel"
	if friends_with(v):
		return "you won't rob your own guild"
	if position.distance_to(v.position) > 1.8:
		return "you must stand right next to them"
	return ""


## Snooping: peek into a player's bag. Failing gets you noticed (a criminal act).
func snoop(v: Entity) -> String:
	if kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.SNOOPING)
	if randf() >= Rules.snoop_chance(_skill(Hero.Skill.SNOOPING)):
		_caught_by(v, "snooping")
		return ""
	var parts: Array[String] = ["%d gold" % v.gold]
	for id in v.inventory:
		parts.append("%s x%d" % [Items.item_name(id), int(v.inventory[id])])
	return ", ".join(parts)


## Stealing: lift one thing (an item from the bag, or some gold) from a player next to you.
## Equipped gear can't be stolen. Getting caught makes you a criminal.
func steal_from(v: Entity) -> String:
	if kind == Kind.PLAYER:
		stats.try_gain(Hero.Skill.STEALING)
	var skill := _skill(Hero.Skill.STEALING)
	if randf() >= Rules.steal_chance(skill):
		_caught_by(v, "stealing")
		return ""
	var loot := ""
	var keys := v.inventory.keys()
	if not keys.is_empty() and (v.gold <= 0 or randf() < 0.6):
		var id: String = keys[randi() % keys.size()]
		Crafting.take_mats(v.inventory, {id: 1}, 1.0)
		inventory[id] = int(inventory.get(id, 0)) + 1
		loot = Items.item_name(id)
		learn_scrolls()
	elif v.gold > 0:
		var amount := mini(v.gold, randi_range(5, 10 + int(skill / 2.0)))
		v.gold -= amount
		gold += amount
		loot = "%d gold" % amount
	else:
		_pop("their bag is empty", Color(0.75, 0.75, 0.75))
		return ""
	if v.is_hero:
		game.count("stolen_from_hero")
		game.log_event("You feel your bag get lighter... (%s gone)" % loot)
	if is_hero:
		game.count("stole")
	if randf() < Rules.notice_chance(skill):
		_caught_by(v, "stealing")
	return loot


func _caught_by(v: Entity, what: String) -> void:
	criminal_timer = CRIMINAL_SECONDS
	if effects.has("hiding"):
		_end_flag("invisible")
	_pop("caught %s!" % what, Color(1.0, 0.5, 0.4))
	game.event_about("%s is caught %s from %s!" % [display_name, what, v.display_name], is_hero or v.is_hero)
	if v.target == null and not v.recovering:
		v.target = self                      # the victim turns on the thief
	if is_hero:
		game.count("caught")


## A computer thief: hide, sneak up on a player outside town, snoop, steal, slip away.
func _thief_step() -> bool:
	if target != null:
		return false                         # in a fight: fight
	if steal_cd > 0.0:
		if not effects.has("hiding") and _nearest_threat(3.0) == null:
			try_hide()
		return false
	if thief_mark == null or not is_instance_valid(thief_mark) or thief_mark.dead or thief_mark._in_town() \
			or theft_problem(thief_mark).begins_with("only") or position.distance_to(thief_mark.position) > 14.0:
		thief_mark = _pick_mark()
		if thief_mark == null:
			return false
	if not effects.has("hiding"):
		try_hide()
	var d := position.distance_to(thief_mark.position)
	if d > 1.6:
		if path.is_empty() or repath_timer <= 0.0:
			repath_timer = 0.6
			go_to(thief_mark.position)
		return true
	path.clear()
	var v := thief_mark
	thief_mark = null
	steal_cd = 90.0
	if theft_problem(v) != "":
		return true
	var seen := snoop(v)
	if seen != "" and criminal_timer <= 0.0:
		steal_from(v)
	_wander()                                # and off we go
	return true


func _pick_mark() -> Entity:
	var best: Entity = null
	var best_d := 12.0
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e == self or e.dead or e.kind != Kind.PLAYER or e._in_town() or e.is_thief:
			continue
		if friends_with(e) or _trammel() or e.flags.has("invisible"):
			continue
		var dd := position.distance_to(e.position)
		if dd < best_d:
			best = e
			best_d = dd
	return best


# --- mounts -----------------------------------------------------------------

func can_ride(p: Entity) -> bool:
	return p != null and p.kind == Kind.PET and p.pet_owner == self and not p.dead and not p.summoned \
		and p.mount_speed > 1.0


## Get on a pet horse or llama standing close by.
func mount(p: Entity) -> bool:
	if mounted_on != null or dead or not can_ride(p) or position.distance_to(p.position) > 3.0:
		return false
	mounted_on = p
	p.parked = true
	p.visible = false
	p.target = null
	p.path.clear()
	refresh_look()
	if is_hero:
		game.log_event("You mount your %s." % p.display_name)
		game.count("mounted")
	return true


func dismount() -> void:
	if mounted_on == null:
		return
	var p := mounted_on
	mounted_on = null
	if is_instance_valid(p):
		p.parked = false
		p.visible = true
		p.position = position + Vector3(0.6, 0.0, 0.0)
		if world.is_blocked(world.to_tile(p.position)):
			p.position = position
		p.path.clear()
	refresh_look()
	if is_hero:
		game.log_event("You get off your %s." % p.display_name)


func mounted_by_position() -> Vector3:
	return pet_owner.position if pet_owner != null and is_instance_valid(pet_owner) else position


## Players with a mount pet close by get on it (computer players and the hero on Auto).
func _auto_mount() -> void:
	if mounted_on != null or dead or kind != Kind.PLAYER:
		return
	for p in pets:
		if can_ride(p) and position.distance_to(p.position) <= 3.0:
			mount(p)
			return


# --- quests: escorts and the way back to the captain ----------------------------------------

## The traveller being escorted walks after the hero and tells the game when they arrive.
func _escort_follow() -> void:
	var h: Entity = game.hero
	if h == null:
		return
	var dest: Variant = game.escort_destination()
	if dest != null and position.distance_to(dest) <= 3.0:
		game.escort_arrived(self)
		return
	if position.distance_to(h.position) > 2.2:
		if path.is_empty() or repath_timer <= 0.0:
			repath_timer = 0.5
			go_to(h.position)
	else:
		path.clear()


## On Auto: lead an escort to its destination, and walk back to the captain once a quest is done.
func _quest_trip() -> bool:
	var dest: Variant = game.quest_walk_target()
	if dest == null:
		return false
	if position.distance_to(dest) <= 2.0:
		return false
	if path.is_empty() or repath_timer <= 0.0:
		repath_timer = 1.0
		if not go_to(dest):
			return false
	return true


# --- the Bag screen: equipping by hand ---------------------------------------

## Puts on a piece from the bag (what was worn goes into the bag). Returns false if it can't.
func equip_by_hand(id: String) -> bool:
	if dead or not inventory.has(id) or not Gear.has(id) or not _can_use(id):
		return false
	auto_equip = false
	_equip(id)
	return true


## Takes off what is worn in a slot ("weapon", "armor" or "shield") and puts it in the bag.
func unequip(slot: String) -> void:
	var id := _equipped_id(slot)
	if id == "":
		return
	auto_equip = false
	inventory[id] = int(inventory.get(id, 0)) + 1
	match slot:
		"weapon":
			weapon = ""
		"shield":
			shield_id = ""
		_:
			armor_id = ""
	refresh_look()
	if is_hero:
		game.log_event("You take off the %s." % Items.item_name(id))


## Why a piece from the bag can't be worn, or "" if it can.
func equip_problem(id: String) -> String:
	var g := Gear.stats(id)
	if stats.strength < int(g["str"]):
		return "needs %d Strength" % int(g["str"])
	if Gear.is_metal(id) and _skill(Hero.Skill.MAGERY) >= 30.0:
		return "metal would ruin your spellcasting"
	if String(g["slot"]) == "shield" and weapon != "" and bool(Gear.stats(weapon).get("two_handed", false)):
		return "your weapon needs both hands"
	if bool(g.get("two_handed", false)) and shield_id != "":
		return "needs both hands: take off the shield"
	return ""


# --- retreat and heal; attacking players by hand ------------------------------------------

## Retreat: drop the fight, use what heals (potions, bandages, healing spells, Spirit Speak) and
## head for the nearest healer, who stands in a safe town. Ends once healed and cured.
func start_retreat() -> void:
	retreating = true
	target = null
	loot_target = null
	gather_tile = Vector2i(-1, -1)
	crafting_trip = false
	if casting_id != "" and String(Spells.LIST[casting_id]["kind"]) in HARMFUL_KINDS:
		_fizzle("you break off")
	if is_hero:
		game.log_event("You break off and retreat to heal.")


func stop_retreat() -> void:
	retreating = false


func _retreat_step() -> void:
	target = null
	var max_hp := float(stats.max_hp())
	if hp >= max_hp * 0.95 and poison_level <= 0:
		retreating = false
		if is_hero:
			game.log_event("You are healed and ready.")
		return
	_try_potion()
	if casting_id == "" and cast_cd <= 0.0:
		if _nearest_threat(5.0) != null and _try_escape_magic():
			return
		if poison_level > 0 and _best_spell("cure") != "":
			start_cast(_best_spell("cure"), self)
			return
		var heal_id := _best_spell("heal")
		if heal_id != "":
			start_cast(heal_id, self)
			return
	if _try_bandage():
		return
	var healer := _nearest_role("healer")
	if healer != null and position.distance_to(healer.position) > 2.0:
		if path.is_empty() or repath_timer <= 0.0:
			repath_timer = 0.8
			go_to(healer.position)
	else:
		path.clear()                         # by the healer (or nowhere to go): rest


## Why the hero can't attack another player by hand, or "" if it can. Outside town in Felucca
## anyone is fair game; hitting an innocent makes you a criminal (and a murderer if they die).
func pvp_problem(v: Entity) -> String:
	if v == null or v.dead or v == self or v.kind != Kind.PLAYER:
		return "nobody to attack"
	if _in_town() or v._in_town():
		return "nobody fights in town"
	if _trammel() and not at_war_with(v):
		return "no player fighting in Trammel"
	if friends_with(v):
		return "they're in your guild or an ally"
	return ""


## A level gained: a pop above the head every time, a log line every 10 levels.
func _on_level_up(lv: int) -> void:
	_pop("Level %d!" % lv, Color(1.0, 0.85, 0.3))
	if is_hero:
		game.count("levels_gained")
		if lv % 10 == 0:
			game.glitch(0.35, 0.3)
			game.log_event("You reach level %d!" % lv)
			game.sound("gain", position)


# --- fire -------------------------------------------------------------------

func _near_hero() -> bool:
	return game.hero != null and position.distance_to(game.hero.position) <= 25.0


## Fire spells get real fire instead of a plain bolt. Returns true if it drew something.
func _spell_fire(id: String, tgt: Entity) -> bool:
	if not _near_hero():
		return id in ["fireball", "flamestrike", "explosion"]
	var up := Vector3(0.0, 1.0, 0.0)
	match id:
		"fireball":
			Fx.fireball(get_parent(), position + up, tgt.position + up)
		"flamestrike":
			Fx.pillar(get_parent(), tgt.position)
		"explosion":
			Fx.burst(get_parent(), tgt.position + up, 1.5)
		_:
			return false
	return true
