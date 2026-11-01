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
const SPELL_RANGE := 7.0
const CAST_RECOVERY := 0.8     # seconds between casts
const LOOT_RANGE := 1.6
const LOOT_SEEK := 9.0         # how far players look for corpses
const REAGENT_PRICE := 2       # gold per reagent at the merchant
const MAX_REAGENTS := 60.0

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
var _gear_timer := 0.0
var _trade_timer := 0.0
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
	mana = float(stats.max_mana())
	reagents = float(cfg.get("reagents", 0))
	gold = int(cfg.get("gold", 0))
	loot_cfg = cfg.get("loot", {})
	weapon = String(cfg.get("weapon", ""))
	armor_id = String(cfg.get("wear", ""))


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
	cast_cd = maxf(cast_cd - delta, 0.0)
	pause = maxf(pause - delta, 0.0)
	repath_timer -= delta
	hp = minf(hp + REGEN_PER_SEC * delta, float(stats.max_hp()))
	_regen_mana(delta)
	if role == "healer":
		_heal_aura(delta)
	elif role == "merchant":
		_market_aura(delta)
	if casting_id != "":
		_cast_step(delta)
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
		if _recover() or _resupply():
			return
		if target == null:
			target = _nearest(Kind.MONSTER, aggro_range)
	if target != null:
		_chase()
		return
	if kind == Kind.PLAYER:
		if _loot_step():
			return
		if autonomous and pause <= 0.0 and _seek_loot():
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
	if casting_id == "" and cast_cd <= 0.0:
		var heal_id := _best_spell("heal")
		if heal_id != "":
			start_cast(heal_id, self)
			return true
	var healer := _find_role("healer")
	if healer != null and position.distance_to(healer.position) > 2.0 and path.is_empty():
		go_to(healer.position)
	return true


func _chase() -> void:
	var reach := MELEE_RANGE
	if (kind != Kind.PLAYER or ai_enabled) and _best_spell("attack") != "":
		reach = SPELL_RANGE            # casters keep their distance
	if position.distance_to(target.position) > reach:
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
	if target == null:
		return
	var d := position.distance_to(target.position)
	if (kind != Kind.PLAYER or ai_enabled) and _try_auto_cast(d):
		return
	if swing_cd > 0.0 or d > MELEE_RANGE:
		return
	var ws := weapon_speed
	var lo := dmg_min
	var hi := dmg_max
	if weapon != "":
		var w: Dictionary = Gear.LIST[weapon]
		ws = int(w["speed"])
		lo = float(w["min"])
		hi = float(w["max"])
	swing_cd = Rules.swing_seconds(stats.max_stamina(), ws)
	var atk: float = stats.skills.get(Hero.Skill.SWORDSMANSHIP, 0.0)
	var def: float = target.stats.skills.get(Hero.Skill.SWORDSMANSHIP, 0.0)
	if randf() < Rules.hit_chance(atk, def):
		var tactics: float = stats.skills.get(Hero.Skill.TACTICS, 0.0)
		var anatomy: float = stats.skills.get(Hero.Skill.ANATOMY, 0.0)
		var dmg := randf_range(lo, hi) * Rules.damage_multiplier(
			float(stats.strength), tactics, anatomy)
		target.take_damage(target._absorb(dmg), self)
		if kind == Kind.PLAYER:
			stats.try_gain(Hero.Skill.SWORDSMANSHIP)
			stats.try_gain(Hero.Skill.TACTICS)
	else:
		target._pop("miss", Color(0.8, 0.8, 0.8))


## Armor soaks a random half-to-all of its rating, but a hit always does at least 1.
func _absorb(amount: float) -> float:
	var rating := _armor_rating()
	if rating <= 0.0:
		return amount
	return maxf(1.0, amount - randf_range(0.5, 1.0) * rating)


## Natural armor (monster hide) plus whatever is worn.
func _armor_rating() -> float:
	var worn := 0.0
	if armor_id != "":
		worn = float(Gear.LIST[armor_id]["rating"])
	return armor + worn


func take_damage(amount: float, from: Entity) -> void:
	if dead or kind == Kind.NPC:
		return
	hp -= amount
	if casting_id != "":
		_fizzle("disrupted")      # taking damage breaks a spell in progress
	_pop("-%d" % maxi(1, roundi(amount)), Color(1.0, 0.45, 0.4))
	if target == null and not recovering:
		target = from                  # fight back
	if hp <= 0.0:
		_die(from)


func _die(killer: Entity) -> void:
	dead = true
	hp = 0.0
	casting_id = ""
	loot_target = null
	target = null
	recovering = false
	path.clear()
	dead_timer = respawn_time
	visible = false
	game.spawn_corpse(self)
	game.log_event("%s was slain by %s" % [display_name, killer.display_name])


func _respawn() -> void:
	dead = false
	visible = true
	position = home
	hp = float(stats.max_hp())
	mana = float(stats.max_mana())
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
	if casting_id != "":
		return "casting " + String(Spells.LIST[casting_id]["name"])
	if loot_target != null:
		return "looting"
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
	if hp < float(stats.max_hp()) * 0.5:
		var heal_id := _best_spell("heal")
		if heal_id != "":
			return start_cast(heal_id, self)
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
		var avg := (float(sp["min_dmg"]) + float(sp["max_dmg"])) / 2.0
		var score := chance * avg / float(sp["mana"])
		if score > best_score:
			best_score = score
			best = id
	return best


func _regen_mana(delta: float) -> void:
	var metal := Gear.is_metal(armor_id)      # metal armor kills Meditation's benefit
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
	if reagents < 3.0 and gold >= REAGENT_PRICE * 2:
		restocking = true
	elif reagents >= 15.0 or gold < REAGENT_PRICE * 2:
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
		if position.distance_to(other.position) <= HEAL_RANGE:
			other.trade(delta)


func trade(delta: float) -> void:
	var earned := 0
	for id in inventory.keys():
		if _is_usable_upgrade(id):
			continue                       # keep gear we are about to wear
		earned += Items.value(id) * int(inventory[id])
		inventory.erase(id)
	if earned > 0:
		gold += earned
		if is_hero:
			game.log_event("You sell your spare loot for %d gold." % earned)
	_trade_timer += delta
	if _trade_timer >= 0.5:
		_trade_timer = 0.0
		if reagents < 30.0 and gold >= REAGENT_PRICE * 2:
			gold -= REAGENT_PRICE * 2
			reagents = minf(reagents + 2.0, MAX_REAGENTS)
		_buy_gear()


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
	gold += int(got["gold"])
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
	if stats.strength < int(Gear.LIST[id]["str"]):
		return false
	# Mages stay in cloth: metal armor would ruin their Meditation.
	if Gear.is_metal(id) and _skill(Hero.Skill.MAGERY) >= 30.0:
		return false
	return true


func _is_usable_upgrade(id: String) -> bool:
	if not Gear.LIST.has(id) or not _can_use(id):
		return false
	return Gear.score(id) > _equipped_score(String(Gear.LIST[id]["slot"]))


func _equipped_score(slot: String) -> float:
	return Gear.score(weapon if slot == "weapon" else armor_id)


## Equips any carried piece that beats what is worn (and the old piece goes into the bag).
func _manage_gear() -> void:
	for id in inventory.keys():
		if _is_usable_upgrade(id):
			_equip(id)


func _equip(id: String) -> void:
	var slot := String(Gear.LIST[id]["slot"])
	var old := weapon if slot == "weapon" else armor_id
	inventory[id] = int(inventory.get(id, 0)) - 1
	if int(inventory[id]) <= 0:
		inventory.erase(id)
	if slot == "weapon":
		weapon = id
	else:
		armor_id = id
	if old != "":
		inventory[old] = int(inventory.get(old, 0)) + 1
	if is_hero:
		game.log_event("You equip the %s." % Items.item_name(id))


## At the merchant: buy the best usable upgrade we can afford, keeping a little gold spare.
func _buy_gear() -> void:
	var best := ""
	var best_gain := 0.0
	for id in Gear.ORDER:
		var g: Dictionary = Gear.LIST[id]
		var price := int(g["value"])
		if price + 8 > gold or not _can_use(id) or inventory.has(id):
			continue
		var gain := Gear.score(id) - _equipped_score(String(g["slot"]))
		if gain > best_gain:
			best_gain = gain
			best = id
	if best == "":
		return
	gold -= int(Gear.LIST[best]["value"])
	inventory[best] = int(inventory.get(best, 0)) + 1
	_manage_gear()
	if is_hero:
		game.log_event("You buy a %s for %d gold." % [Items.item_name(best), int(Gear.LIST[best]["value"])])


func gear_text() -> String:
	var w := "fists"
	if weapon != "":
		var g: Dictionary = Gear.LIST[weapon]
		w = "%s %d-%d" % [g["name"], int(g["min"]), int(g["max"])]
	var a := "none"
	if armor_id != "":
		a = "%s (AR %d)" % [Gear.LIST[armor_id]["name"], int(Gear.LIST[armor_id]["rating"])]
	return "Weapon: %s   Armor: %s" % [w, a]
