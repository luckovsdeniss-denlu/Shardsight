class_name MovieAction
extends Movie
## The action trailer ("Action trailer" on the start screen): about a minute of the game at its
## loudest - the hero never fighting alone. The world's other adventurers charge in at the hero's
## side against an orc warband, a named wolf and its pack, the dead of Ravenhollow at night, a raid
## in the snow; the townsfolk cry the alarm; a champion in the arena; the Shardveil's free-for-all
## with guns; and the whole land against a giant. Then the logo.
## It's its own script (MovieActionShort cuts it down to half a minute), so nothing here changes
## the other trailers. The adventurers it borrows go back where they were when it ends.

var _exp_was := false
var _stay_out_was := false
var _allies: Array[Entity] = []        # the adventurers fighting at the hero's side this scene
var _ally_home := {}                   # each borrowed adventurer -> where it was before the trailer

const MEADOW := Vector2i(45, 92)
const VEIL_SPOT := Vector2i(50, 89)    # (open meadow there too: nothing between the camera and the fight)


func start(p_game) -> void:
	_exp_was = Experiments.active
	Experiments.active = true          # (for the Shardveil's scene: its world and its chaos)
	_stay_out_was = p_game.hero.stay_out
	p_game.hero.stay_out = true        # (on foot all through: no climbing into the dimension car mid-fight)
	if p_game.hero.mounted_on != null:
		p_game.hero.dismount()
	super.start(p_game)


## The Shardveil plays out for the scene that asks for it.
func shows_veil() -> bool:
	return running and i >= 0 and i < shots.size() and bool(shots[i].get("veil", false))


func _make_shots() -> void:
	shots = [
		{"title": "SHARDSIGHT", "sub": "A world at war - and you're not alone in it.", "dur": 5.0, "no_hero": true, "day": 0.38, "weather": "clear",
			"at": _tc(Vector2i(32, 9)), "r": 20.0, "h": 15.0, "a0": 0.5, "a1": 1.3},
		{"title": "Side by side", "story": [["hero", "\"With me!\""], ["foe", "\"WAAAGH!\""]], "words": ["FIGHT TOGETHER", "ADVENTURERS AT YOUR SIDE"],
			"sub": "The land's other adventurers charge in beside you - an orc warband meets the lot of you.", "dur": 7.0, "day": 0.4,
			"at": _tc(Vector2i(14, 19)), "r": 7.5, "h": 4.5, "a0": 0.2, "a1": 1.4, "cam": "orbit",
			"setup": _brawl.bind(Vector2i(14, 19), "Orc", Bestiary.ORC, 5, 3)},
		{"title": "The alarm", "story": [["Elara", "\"Orcs on the north road!\""], ["hero", "\"Then let's meet them there.\""]], "words": ["A LIVING WORLD", "EVERYONE HAS A PART"],
			"sub": "Healers, merchants, guards and townsfolk - and every one of them has something to say.", "dur": 5.5, "day": 0.42, "cam": "track",
			"at": _tc(Vector2i(32, 10)), "r": 8.0, "h": 5.0, "a0": 2.4, "a1": 3.2, "setup": _stage_alarm},
		{"title": "Bounty hunters", "story": [["foe", "\"Grrrr...\""], ["hero", "\"Split the reward?\""]], "words": ["HUNT TOGETHER", "SHARE THE SPOILS"],
			"sub": "A named wolf and its pack - and two hunters who heard of the price on its head.", "dur": 6.5, "day": 0.36, "cam": "orbit",
			"at": _tc(MEADOW), "r": 8.5, "h": 5.0, "a0": 3.0, "a1": 4.1, "setup": _stage_pack},
		{"title": "Night of the dead", "story": [["foe", "\"Braaaains...\""], ["hero", "\"Back to back!\""]], "words": ["THE DEAD RISE", "STAND YOUR GROUND"],
			"sub": "Ravenhollow at midnight: the graves open, and four of you hold the line.", "dur": 7.0, "day": 0.02, "cam": "spiral",
			"at": _tc(Vector2i(103, 133)), "r": 7.0, "h": 8.0, "a0": 5.0, "a1": 6.0,
			"setup": _brawl.bind(Vector2i(103, 133), "Zombie", Bestiary.ZOMBIE, 5, 3)},
		{"title": "The Arena", "story": [["foe", "\"The crowd wants blood.\""], ["hero", "\"The crowd gets a show.\""]], "words": ["CHALLENGE CHAMPIONS", "THE CROWD ROARS"],
			"sub": "One on one before the stands - a champion's purse to win, and your own gold on yourself.", "dur": 6.0, "day": 0.45,
			"at": _tc(Vector2i(89, 91)), "r": 5.5, "h": 3.5, "a0": 2.0, "a1": 3.3, "setup": _stage_fight.bind(Vector2i(89, 91), "Valka the Undefeated", Bestiary.WARRIOR, 1)},
		{"title": "Frost raid", "story": [["foe", "\"ROOOAAAR!\""], ["hero", "\"Keep moving - keep swinging!\""]], "words": ["EVERY LAND A BATTLE", "SNOW · SAND · ASH"],
			"sub": "Yetis out of the blizzard, and a war party to meet them.", "dur": 6.0, "snow": true, "close": true,
			"at": _tc(Vector2i(71, 4)), "r": 7.0, "h": 5.0, "a0": 3.6, "a1": 4.6, "setup": _brawl.bind(Vector2i(71, 4), "Yeti", Bestiary.YETI, 2, 2)},
		{"title": "The Shardveil", "veil": true, "story": [["foe", "\"Nice coat. Mine now.\""], ["hero", "\"Come and take it.\""]], "words": ["EVERYONE HAS A GUN", "TOTAL CHAOS"],
			"sub": "In another dimension it's every one for themselves: guns, meteors, the sky splitting open.", "dur": 7.0, "cam": "orbit",
			"at": _tc(VEIL_SPOT), "r": 8.5, "h": 5.0, "a0": 2.0, "a1": 3.2, "setup": _stage_veil},
		{"title": "World bosses", "no_run": true, "story": [["foe", "\"I AM THAROK, THE WORLD-EATER!\""], ["hero", "\"And we're the whole world.\""], ["foe", "\"...urk.\""]], "words": ["THE WHOLE LAND", "AGAINST ONE GIANT"],
			"sub": "Now and then a giant wakes, and everyone who can lift a sword comes running.", "dur": 8.0, "day": 0.55, "weather": "clear", "white": true,
			"at": _tc(Vector2i(60, 26)), "r": 11.0, "h": 6.5, "a0": 0.2, "a1": 1.5, "setup": _stage_war},
		{"title": "Join the fight", "words": ["YOUR FIGHT", "BEGINS NOW"], "sub": "Quests, bounties, guilds, the arena, another dimension. Bring friends.", "dur": 5.5, "no_hero": true,
			"at": _tc(Vector2i(32, 9)), "r": 22.0, "h": 17.0, "a0": 1.3, "a1": 1.9},
	]
	_shape_shots()


# --- the staging -----------------------------------------------------------------------------

## A fight with company: the foes come at the hero, and `allies` of the land's adventurers charge
## in beside them.
func _brawl(tile: Vector2i, foe_name: String, cfg: Dictionary, n: int, allies: int) -> void:
	_stage_fight(tile, foe_name, cfg, n)
	_fight[3] = n                                    # (exactly this many, wave after wave)
	_bring_allies(allies)
	_company_framing()


## The whole company in the picture: the camera further out, and the fight all blades (a spell's
## glare would white out the crowd).
func _company_framing() -> void:
	shots[i]["wide"] = not bool(shots[i].get("close", false))
	shots[i]["magic"] = false
	shots[i]["hero_intro"] = false


## The town: an alarm cried, the hero and two adventurers already setting off at a run.
func _stage_alarm() -> void:
	_stage_town()
	_bring_allies(2)
	var away := _tc(Vector2i(32, 4))
	hero.set_journey(away)
	for a in _allies:
		a.go_to(away + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.0, 1.0)))


## The bounty: a named wolf and its pack against three.
func _stage_pack() -> void:
	_stage_fight(MEADOW, "Grimfang the Wolf", _elite(Bestiary.WOLF), 1)
	var c := Bestiary.WOLF.duplicate(true)
	for k in range(3):                               # (and its pack)
		c["passive"] = false
		c["aggro"] = 15.0
		var e: Entity = game.pool_spawn("Wolf ", c, Color(0.6, 0.6, 0.62), _foe_spot(k + 1, 4))
		e.target = hero
		_actors.append(e)
	_bring_allies(2)
	_company_framing()


## The Shardveil: the other world all round, the free-for-all - foes, and adventurers with guns.
func _stage_veil() -> void:
	var d: Dimension = game.dimension
	if d != null and not d.active:
		d._set_world(true, false)
	_brawl(VEIL_SPOT, "Orc", Bestiary.ORC, 3, 3)


## The giant, and everyone who can lift a sword.
func _stage_war() -> void:
	_stage_boss()
	_bring_allies(5)
	shots[i]["wide"] = true
	shots[i]["hero_intro"] = false


## Borrows the nearest of the land's adventurers and sets them in the fight round the hero (they
## go back where they were when the trailer ends).
func _bring_allies(k: int) -> void:
	_allies.clear()
	var cands: Array = []
	for item in game.creatures:
		var e := item as Entity
		if e == null or e.is_hero or e.dead or e.parked or e.kind != Entity.Kind.PLAYER or e.is_thief:
			continue
		cands.append(e)
	cands.sort_custom(func(a, b) -> bool: return a.position.distance_squared_to(hero.position) < b.position.distance_squared_to(hero.position))
	var spots := [Vector2(-1.8, 0.6), Vector2(1.8, 0.4), Vector2(-0.9, -1.6), Vector2(1.0, -1.7), Vector2(-2.6, -0.8), Vector2(2.6, -0.9)]
	for idx in range(mini(k, cands.size())):
		var e: Entity = cands[idx]
		if not _ally_home.has(e):
			_ally_home[e] = e.position
		if e.mounted_on != null:
			e.dismount()
		var off: Vector2 = spots[idx % spots.size()]
		var p := hero.position + Vector3(off.x, 0.0, off.y)
		if world.is_blocked(world.to_tile(p)):
			p = hero.position + Vector3(off.x * 0.5, 0.0, off.y * 0.5)
		e.position = Vector3(p.x, world.height_at(p), p.z)
		e.path.clear()
		e.has_journey = false
		e.trailer_held = false
		e.visible = true
		e.ai_enabled = true
		e.retreating = false
		e.roam_timer = 1.0e9
		e.hp = float(e.stats.max_hp())
		_allies.append(e)
	_aim_allies()


## Each adventurer at the nearest foe still standing.
func _aim_allies() -> void:
	for a in _allies:
		if not is_instance_valid(a) or a.dead:
			continue
		if a.target != null and is_instance_valid(a.target) and not a.target.dead and a.target in _actors:
			continue
		var best: Entity = null
		var best_d := INF
		for f in _actors:
			if is_instance_valid(f) and not f.dead:
				var d := a.position.distance_to(f.position)
				if d < best_d:
					best = f
					best_d = d
		a.target = best


## The borrowed adventurers are in the scene: the stage doesn't hold them still or hide them.
func _clear_stage(sh: Dictionary) -> void:
	super._clear_stage(sh)
	for a in _allies:
		if is_instance_valid(a):
			a.trailer_held = false
			a.visible = true
			_held.erase(a)
	var d: Dimension = game.dimension
	if d != null and d.car != null and is_instance_valid(d.car) and not d.car.parked:
		d.car.visible = false                        # (the dimension car stays out of this trailer)


func _next() -> void:
	_allies.clear()                                  # (each scene brings its own company)
	super._next()


func tick(delta: float) -> bool:
	for a in _allies:                                # the company can't fall, nor run, mid-scene
		if is_instance_valid(a) and not a.dead:
			a.hp = float(a.stats.max_hp())
			a.retreating = false
			a.recovering = false
	if running and int(t * 4.0) != int((t - delta) * 4.0):
		_aim_allies()
	return super.tick(delta)


## The end: home from the Shardveil, the borrowed adventurers back where they were, and the
## experiments' switches as they were.
func _back_to_title() -> void:
	var d: Dimension = game.dimension
	if d != null:
		if d.active:
			d._set_world(false, false)
		d._chaos_step(0.0)
	for e in _ally_home:
		if is_instance_valid(e) and not e.dead:
			e.position = _ally_home[e]
			e.path.clear()
			e.target = null
			e.roam_timer = randf_range(30.0, 90.0)
	_ally_home.clear()
	Experiments.active = _exp_was
	hero.stay_out = _stay_out_was
	super._back_to_title()
