class_name Wildlife
extends Node3D
## Life in the wild (the "Wild life" experiment; always in the trailers): deer grazing at the
## edges of the woods, rabbits nibbling and hopping in the meadows, ducks paddling on the lakes,
## fish leaping out of the water, and bats in place of the birds at night. They are scenery, not
## creatures: no fighting, taming or loot - they live round you, and the deer and rabbits bolt
## when you come close. A handful at a time, near you, so they cost next to nothing.

const DEER_N := 3
const RABBIT_N := 4
const DUCK_N := 3
const NEAR := 12.0                     # they turn up between these distances from you...
const FAR := 26.0
const GONE := 34.0                     # ...and go when you've left them this far behind

var game
var world: World
var _deer: Array = []                  # each: {"node", "legs", "state", "timer", "dir", "phase"}
var _rabbits: Array = []
var _ducks: Array = []
var _fish: Node3D
var _fish_t := 0.0                     # the fish's leap under way (seconds into it), or -1
var _fish_from := Vector3.ZERO
var _fish_dir := Vector3.FORWARD
var _fish_wait := 3.0
var _rng := RandomNumberGenerator.new()


func setup(g) -> void:
	game = g
	world = g.world
	_rng.seed = 4242
	for k in range(DEER_N):
		var m: Dictionary = Art.creature("hind", {}, 0.95)
		var n := Node3D.new()
		n.add_child(m["root"])
		add_child(n)
		_deer.append({"node": n, "legs": m["legs"], "state": "off", "timer": 0.0, "dir": Vector3.FORWARD, "phase": 0.0})
	var rabbit := _rabbit_mesh()
	for k in range(RABBIT_N):
		var n := MeshInstance3D.new()
		n.mesh = rabbit
		n.material_override = Art.vc_mat()
		add_child(n)
		_rabbits.append({"node": n, "state": "off", "timer": 0.0, "dir": Vector3.FORWARD, "phase": 0.0, "hops": 0})
	var duck := _duck_mesh()
	for k in range(DUCK_N):
		var n := MeshInstance3D.new()
		n.mesh = duck
		n.material_override = Art.vc_mat()
		add_child(n)
		_ducks.append({"node": n, "state": "off", "timer": 0.0, "dir": Vector3.FORWARD, "phase": _rng.randf() * TAU})
	_fish = MeshInstance3D.new()
	(_fish as MeshInstance3D).mesh = Art.merge([
		[Art.ball(0.1, 8, 5), Art.at(0, 0, 0, Vector3.ZERO, Vector3(0.7, 0.8, 2.0)), Color(0.55, 0.62, 0.6)],
		[Art.cone(0.09, 0.14, 0.0, 4), Art.at(0, 0, 0.24, Vector3(-PI * 0.5, 0, 0), Vector3(0.3, 1.0, 1.0)), Color(0.45, 0.5, 0.5)]])
	(_fish as MeshInstance3D).material_override = Art.vc_mat()
	add_child(_fish)
	_fish.visible = false
	_fish_t = -1.0
	for list in [_deer, _rabbits, _ducks]:
		for c: Dictionary in list:
			(c["node"] as Node3D).visible = false


static func _rabbit_mesh() -> ArrayMesh:
	var fur := Color(0.55, 0.42, 0.3)
	return Art.merge([[Art.ball(0.12, 8, 5), Art.at(0, 0.11, 0.02, Vector3.ZERO, Vector3(0.9, 0.85, 1.2)), fur],
		[Art.ball(0.075, 8, 5), Art.at(0, 0.2, -0.12), fur.lightened(0.05)],
		[Art.box(0.03, 0.13, 0.02), Art.at(-0.03, 0.31, -0.11, Vector3(0.2, 0, -0.15)), fur],
		[Art.box(0.03, 0.13, 0.02), Art.at(0.03, 0.31, -0.11, Vector3(0.2, 0, 0.15)), fur],
		[Art.ball(0.04, 6, 4), Art.at(0, 0.13, 0.16), Color(0.95, 0.93, 0.9)],             # the white tail
		[Art.ball(0.012, 4, 3), Art.at(-0.04, 0.22, -0.18), Color(0.05, 0.05, 0.05)],
		[Art.ball(0.012, 4, 3), Art.at(0.04, 0.22, -0.18), Color(0.05, 0.05, 0.05)]])


static func _duck_mesh() -> ArrayMesh:
	var brown := Color(0.48, 0.36, 0.24)
	return Art.merge([[Art.ball(0.13, 8, 5), Art.at(0, 0.06, 0.02, Vector3.ZERO, Vector3(0.85, 0.65, 1.3)), brown],
		[Art.ball(0.07, 8, 5), Art.at(0, 0.17, -0.12), Color(0.12, 0.42, 0.22)],               # the green head
		[Art.box(0.05, 0.025, 0.07), Art.at(0, 0.16, -0.2), Color(0.95, 0.65, 0.15)],          # the bill
		[Art.box(0.1, 0.03, 0.02), Art.at(0, 0.12, -0.08), Color(0.95, 0.95, 0.95)],           # the white collar
		[Art.cone(0.05, 0.08, 0.0, 4), Art.at(0, 0.1, 0.18, Vector3(-1.1, 0, 0)), brown.darkened(0.2)]])


## Every frame (when on): each animal lives its little life; ones left far behind turn up again
## elsewhere near you, out of sight, when the land there suits them.
func step(delta: float, on: bool) -> void:
	visible = on
	if not on or game.hero == null:
		return
	var hero_p: Vector3 = game.hero.position
	var day: bool = not game.is_night()
	var here: Vector2i = world.to_tile(hero_p)
	var wild: bool = not world.is_town(here) and not world.is_dungeon(here)
	var placed := false                                   # (one new animal a frame at most)
	for c: Dictionary in _deer:
		if not placed and _needs_place(c, hero_p, day and wild):
			placed = _place(c, hero_p, "deer")
		_deer_step(c, delta, hero_p)
	for c: Dictionary in _rabbits:
		if not placed and _needs_place(c, hero_p, day and wild):
			placed = _place(c, hero_p, "rabbit")
		_rabbit_step(c, delta, hero_p)
	for c: Dictionary in _ducks:
		if not placed and _needs_place(c, hero_p, day and String(game.weather) != "storm"):
			placed = _place(c, hero_p, "duck")
		_duck_step(c, delta)
	_fish_step(delta, hero_p, String(game.weather) != "storm")


func _needs_place(c: Dictionary, hero_p: Vector3, allowed: bool) -> bool:
	var n: Node3D = c["node"]
	if not allowed:
		if c["state"] != "off":
			c["state"] = "off"
			n.visible = false
		return false
	return c["state"] == "off" or n.position.distance_to(hero_p) > GONE


## Somewhere near you, out of sight, that suits the animal: a deer on grass at the edge of the
## trees, a rabbit on open grass, a duck on a lake (water all round).
func _place(c: Dictionary, hero_p: Vector3, kind: String) -> bool:
	for _try in range(10):
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(NEAR, FAR)
		var p := hero_p + Vector3(cos(a) * d, 0.0, sin(a) * d)
		var t := world.to_tile(p)
		if not world.in_bounds(t) or world.is_town(t) or world.is_dungeon(t) or world.is_cave(t):
			continue
		var tile: int = world.tiles[t.y * world.cols + t.x]
		var ok := false
		match kind:
			"deer":
				ok = tile == World.Tile.GRASS and world._next_to(t, World.Tile.TREE) and world.biome_at(t) != "ash"
			"rabbit":
				ok = tile == World.Tile.GRASS and not world._next_to(t, World.Tile.TREE) and world.biome_at(t) == ""
			"duck":
				ok = tile == World.Tile.WATER and not world._next_to(t, World.Tile.GRASS)
		if not ok:
			continue
		var at := world.tile_center(t)
		if game.in_view(at + Vector3(0.0, 0.5, 0.0), 1.0):
			continue                                      # (never popping up in plain sight)
		var n: Node3D = c["node"]
		n.position = at + (Vector3(0.0, 0.04, 0.0) if kind == "duck" else Vector3.ZERO)
		n.rotation.y = _rng.randf() * TAU
		n.visible = true
		c["state"] = "swim" if kind == "duck" else "graze"
		c["timer"] = _rng.randf_range(1.5, 4.0)
		c["dir"] = Vector3(cos(a + PI), 0.0, sin(a + PI))
		return true
	return false


func _face(n: Node3D, dir: Vector3) -> void:
	if dir.length() > 0.001:
		n.rotation.y = lerp_angle(n.rotation.y, atan2(-dir.x, -dir.z), 0.25)


func _walkable(p: Vector3) -> bool:
	var t := world.to_tile(p)
	return world.in_bounds(t) and not world.is_blocked(t) and world.tiles[t.y * world.cols + t.x] == World.Tile.GRASS


## A deer: grazes (head down, a slow sway), wanders a few steps, grazes again - and bolts
## from you when you come within 8 m, bounding off into the distance.
func _deer_step(c: Dictionary, delta: float, hero_p: Vector3) -> void:
	var n: Node3D = c["node"]
	if c["state"] == "off":
		return
	var away := n.position - hero_p
	away.y = 0.0
	if c["state"] != "flee" and away.length() < 8.0:
		c["state"] = "flee"
		c["timer"] = 3.0
		c["dir"] = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	c["timer"] = float(c["timer"]) - delta
	var speed := 0.0
	match String(c["state"]):
		"graze":
			n.rotation.x = lerpf(n.rotation.x, 0.18, delta * 3.0)    # head down to the grass
			if float(c["timer"]) <= 0.0:
				c["state"] = "walk"
				c["timer"] = _rng.randf_range(1.2, 2.5)
				c["dir"] = Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
		"walk":
			n.rotation.x = lerpf(n.rotation.x, 0.0, delta * 4.0)
			speed = 0.9
			if float(c["timer"]) <= 0.0:
				c["state"] = "graze"
				c["timer"] = _rng.randf_range(2.5, 5.0)
		"flee":
			n.rotation.x = lerpf(n.rotation.x, -0.08, delta * 6.0)
			speed = 6.5
			if float(c["timer"]) <= 0.0:
				c["state"] = "off"                        # (gone off into the woods)
				n.visible = false
				return
	if speed > 0.0:
		var dir: Vector3 = c["dir"]
		var next := n.position + dir * speed * delta
		if _walkable(next) or c["state"] == "flee":
			n.position = next
		else:
			c["dir"] = -dir                               # (turned back from the trees or the water)
		n.position.y = world.height_at(n.position) + (absf(sin(float(c["phase"]) * 0.5)) * 0.25 if c["state"] == "flee" else 0.0)
		_face(n, c["dir"])
	c["phase"] = float(c["phase"]) + delta * (2.0 + speed * 2.2)
	var legs: Array = c["legs"]
	for k in range(legs.size()):                          # the legs in their gait
		var swing := sin(float(c["phase"]) + (PI if k % 2 == 1 else 0.0)) * minf(speed * 0.25, 0.7)
		(legs[k] as Node3D).rotation.x = swing


## A rabbit: sits nibbling (a twitchy bob), hops a few hops, sits again - and from 5 m off it
## shoots away in long hops and is gone.
func _rabbit_step(c: Dictionary, delta: float, hero_p: Vector3) -> void:
	var n: Node3D = c["node"]
	if c["state"] == "off":
		return
	var away := n.position - hero_p
	away.y = 0.0
	if c["state"] != "flee" and away.length() < 5.0:
		c["state"] = "flee"
		c["hops"] = 9
		c["phase"] = 0.0
		c["dir"] = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
	c["timer"] = float(c["timer"]) - delta
	var ground := world.height_at(n.position)
	match String(c["state"]):
		"graze":
			n.position.y = ground + absf(sin(Time.get_ticks_msec() * 0.012)) * 0.012   # nibbling
			if float(c["timer"]) <= 0.0:
				c["state"] = "hop"
				c["hops"] = _rng.randi_range(2, 4)
				c["phase"] = 0.0
				c["dir"] = Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
		"hop", "flee":
			var fast: bool = c["state"] == "flee"
			var hop_len := 0.3 if fast else 0.38                # seconds a hop
			c["phase"] = float(c["phase"]) + delta / hop_len
			var dir: Vector3 = c["dir"]
			var next := n.position + dir * (2.4 if fast else 0.9) * delta
			if _walkable(next):
				n.position = next
			else:
				c["dir"] = dir.rotated(Vector3.UP, PI * 0.6)
			n.position.y = world.height_at(n.position) + sin(fmod(float(c["phase"]), 1.0) * PI) * (0.22 if fast else 0.14)
			_face(n, c["dir"])
			if float(c["phase"]) >= float(c["hops"]):
				if fast:
					c["state"] = "off"                    # (into a burrow, or over the hill)
					n.visible = false
				else:
					c["state"] = "graze"
					c["timer"] = _rng.randf_range(1.2, 3.5)
					n.position.y = world.height_at(n.position)


## A duck: paddles slowly about the lake, bobbing on the ripples, turning back at the shore.
func _duck_step(c: Dictionary, delta: float) -> void:
	var n: Node3D = c["node"]
	if c["state"] == "off":
		return
	c["timer"] = float(c["timer"]) - delta
	if float(c["timer"]) <= 0.0:
		c["timer"] = _rng.randf_range(2.0, 5.0)
		c["dir"] = (c["dir"] as Vector3).rotated(Vector3.UP, _rng.randf_range(-1.2, 1.2))
	var dir: Vector3 = c["dir"]
	var next := n.position + dir * 0.35 * delta
	var t := world.to_tile(next)
	if world.in_bounds(t) and world.tiles[t.y * world.cols + t.x] == World.Tile.WATER and not world._next_to(t, World.Tile.GRASS):
		n.position.x = next.x
		n.position.z = next.z
	else:
		c["dir"] = -dir
	c["phase"] = float(c["phase"]) + delta
	n.position.y = world.height_at(n.position) + 0.04 + sin(float(c["phase"]) * 2.2) * 0.02
	n.rotation.z = sin(float(c["phase"]) * 1.7) * 0.06
	_face(n, c["dir"])


## Now and then, on water in sight near you, a fish leaps clear - an arc out and back in, a
## splash where it leaves the water and where it comes down.
func _fish_step(delta: float, hero_p: Vector3, allowed: bool) -> void:
	if _fish_t >= 0.0:
		_fish_t += delta
		var k := _fish_t / 0.75
		if k >= 1.0:
			_fish_t = -1.0
			_fish.visible = false
			Fx.sparkle(game, _fish_from + _fish_dir * 1.1, Color(0.75, 0.88, 1.0), 10)   # the splash back in
			return
		_fish.position = _fish_from + _fish_dir * (1.1 * k) + Vector3(0.0, sin(k * PI) * 0.7, 0.0)
		_fish.rotation = Vector3(lerpf(0.9, -0.9, k), atan2(-_fish_dir.x, -_fish_dir.z), 0.0)
		return
	_fish_wait -= delta
	if _fish_wait > 0.0 or not allowed:
		return
	_fish_wait = _rng.randf_range(2.5, 6.0)
	for _try in range(8):
		var a := _rng.randf() * TAU
		var d := _rng.randf_range(4.0, 16.0)
		var p := hero_p + Vector3(cos(a) * d, 0.0, sin(a) * d)
		var t := world.to_tile(p)
		if not world.in_bounds(t) or world.tiles[t.y * world.cols + t.x] != World.Tile.WATER or world._next_to(t, World.Tile.GRASS):
			continue
		var at := world.tile_center(t)
		if not game.in_view(at, 0.5):
			continue
		_fish_from = at + Vector3(0.0, 0.02, 0.0)
		_fish_dir = Vector3.FORWARD.rotated(Vector3.UP, _rng.randf() * TAU)
		_fish_t = 0.0
		_fish.visible = true
		Fx.sparkle(game, _fish_from, Color(0.75, 0.88, 1.0), 8)                       # the splash out
		return
