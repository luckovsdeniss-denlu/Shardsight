class_name Dimension
extends Node
## The dimension car (the "Dimension car" experiment - on for everyone in experimental mode).
##
## Everyone gets the Riftrunner: a low open car of violet metal with a shard of crystal turning in
## its back. It drives itself after you when you walk, and you get in and out with the Car button
## (or Ride). It can't be hurt and never fights. Driving it, Rift jump opens a ring of light on
## the road ahead: the car runs into it and, in a white flash, through to the Shardveil - the same
## land in another dimension: a violet sky with ribbons of light, two moons and a great rift
## across it; the ground violet with veins of light; trees and grass of glassy teal; glowing
## water; motes of light drifting up round you; its own music; and gold that glitters twice
## (every coin found there counts double). Drive home the same way. Nothing of it is saved: a new
## start is always at home.

const CAR_NAME := "Riftrunner"
const TINT := Color(0.84, 0.74, 1.0)           # the Shardveil's light on everything
const VIOLET := Color(0.85, 0.45, 1.0)
const TEAL := Color(0.3, 0.95, 1.0)
const SKY_FAR := 140.0                         # how far off the moons and the rift hang

const DISC_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float swirl = sin(a * 3.0 + r * 9.0 - TIME * 5.0) * 0.5 + 0.5;
	ALBEDO = mix(vec3(0.9, 0.4, 1.0), vec3(0.3, 0.95, 1.0), r);
	ALPHA = (1.0 - smoothstep(0.82, 1.0, r)) * (0.3 + 0.45 * swirl);
}
"""

var game
var active := false                            # in the Shardveil
var veil := 0.0                                # how much the world looks it (0 home, 1 there)
var car: Entity = null
var _check := 0.0
var _told := false
var _jump_t := -1.0                            # seconds into a jump, or -1
var _cross_t := 0.0
var _crossed := false
var _cool := 0.0
var _spark := 0.0
var _jump_dir := Vector3.FORWARD
var _portal_pos := Vector3.ZERO
var _portal: Node3D
var _motes: CPUParticles3D
var _sky_things: Node3D
var _layer: CanvasLayer
var _flash: ColorRect


func setup(g) -> void:
	game = g
	Art.set_tint(Color.WHITE)                  # (always at home to begin with: these outlive a restart)
	game.world.set_veil(0.0)
	_layer = CanvasLayer.new()
	_layer.layer = 45
	add_child(_layer)
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.97, 1.0, 0.0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_flash)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_portal()
	_build_motes()
	_build_sky()
	_build_hud()


func enabled() -> bool:
	return Experiments.on("dimension_car")


# --- the pieces --------------------------------------------------------------------------------

## The ring of light the car drives through: a glowing violet ring standing on the road, a
## second, teal one inside it, and a swirling disc of light filling it.
func _build_portal() -> void:
	_portal = _new_portal()


var _ring_meshes: Array = []
var _disc_mesh: PlaneMesh
var _disc_mat: ShaderMaterial


## A ring of light (hidden, in the world): the hero's, or one an adventurer drives through.
func _new_portal() -> Node3D:
	if _disc_mat == null:
		for spec in [[1.45, 1.65], [1.2, 1.3]]:
			var t := TorusMesh.new()
			t.inner_radius = float(spec[0])
			t.outer_radius = float(spec[1])
			t.rings = 32
			t.ring_segments = 8
			_ring_meshes.append(t)
		var sh := Shader.new()
		sh.code = DISC_SHADER
		_disc_mat = ShaderMaterial.new()
		_disc_mat.shader = sh
		_disc_mesh = PlaneMesh.new()
		_disc_mesh.size = Vector2(3.0, 3.0)
	var portal := Node3D.new()
	portal.visible = false
	game.add_child(portal)
	for k in range(2):
		var ring := MeshInstance3D.new()
		ring.mesh = _ring_meshes[k]
		ring.material_override = Art.glow_mat(VIOLET if k == 0 else TEAL)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.rotation.x = PI * 0.5                 # standing up across the road
		portal.add_child(ring)
	var disc := MeshInstance3D.new()
	disc.mesh = _disc_mesh
	disc.material_override = _disc_mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.rotation.x = PI * 0.5
	portal.add_child(disc)
	return portal


## Motes of light drifting up round you in the Shardveil, violet fading to teal.
func _build_motes() -> void:
	_motes = CPUParticles3D.new()
	_motes.amount = 36
	_motes.lifetime = 4.5
	_motes.local_coords = false
	var q := QuadMesh.new()
	q.size = Vector2(0.08, 0.08)
	q.material = Fx.glow(Color.WHITE)
	_motes.mesh = q
	_motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_motes.emission_box_extents = Vector3(10.0, 0.5, 10.0)
	_motes.direction = Vector3.UP
	_motes.spread = 25.0
	_motes.gravity = Vector3(0.0, 0.12, 0.0)
	_motes.initial_velocity_min = 0.25
	_motes.initial_velocity_max = 0.7
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.7, 1.0])
	g.colors = PackedColorArray([Color(0.9, 0.5, 1.0, 0.0), Color(0.9, 0.5, 1.0, 1.0), Color(0.35, 0.95, 1.0, 0.8), Color(0.35, 0.95, 1.0, 0.0)])
	_motes.color_ramp = g
	_motes.emitting = false
	game.add_child(_motes)


## The Shardveil's sky: two moons - a great pale teal one and a small rose one - and a ring of
## violet light, the rift, hanging across the sky. They stay with the camera, far off.
func _build_sky() -> void:
	_sky_things = Node3D.new()
	_sky_things.visible = false
	game.add_child(_sky_things)
	for spec in [[Vector3(0.45, 0.5, -0.74), 9.0, Color(0.72, 0.95, 1.0)], [Vector3(-0.6, 0.42, -0.68), 5.0, Color(1.0, 0.62, 0.86)]]:
		var m := SphereMesh.new()
		m.radius = float(spec[1])
		m.height = float(spec[1]) * 2.0
		m.radial_segments = 24
		m.rings = 12
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = spec[2]
		var moon := MeshInstance3D.new()
		moon.mesh = m
		moon.material_override = mat
		moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		moon.position = (spec[0] as Vector3).normalized() * SKY_FAR
		_sky_things.add_child(moon)
	var t := TorusMesh.new()
	t.inner_radius = 30.0
	t.outer_radius = 31.5
	t.rings = 64
	t.ring_segments = 6
	var rift := MeshInstance3D.new()
	rift.mesh = t
	rift.material_override = Art.glow_mat(VIOLET)
	rift.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var dir := Vector3(0.1, 0.72, -0.68).normalized()
	rift.transform = Transform3D(Basis.looking_at(-dir, Vector3.UP) * Basis(Vector3.RIGHT, PI * 0.5), dir * SKY_FAR)
	_sky_things.add_child(rift)


# --- every frame ---------------------------------------------------------------------------------

func step(delta: float) -> void:
	var hero: Entity = game.hero
	if hero == null:
		return
	_check -= delta
	if _check <= 0.0:
		_check = 1.0
		_keep_car()
	if game.movie != null:
		if active or veil > 0.0:
			_set_world(false, false)               # (the trailers show the world as it is)
		if not _trips.is_empty():
			_end_trips()                           # (everyone home for the cameras)
		_chaos_step(delta)                         # (and no chaos: everyone's own weapons)
		_buttons(false)
		return
	_buttons(true)
	_npc_step(delta)
	_chaos_step(delta)
	_cool = maxf(_cool - delta, 0.0)
	if _jump_t >= 0.0:
		_jump_step(delta)
	if _flash.color.a > 0.0:
		_flash.color.a = move_toward(_flash.color.a, 0.0, delta * 1.1)
	if active:
		_motes.global_position = hero.position + Vector3(0.0, 0.6, 0.0)
		var cam: Camera3D = game.cam
		_sky_things.global_position = cam.global_position
		_sky_things.scale = Vector3.ONE * clampf(cam.far / 170.0, 0.25, 1.0)   # (always inside what the camera sees)


func _buttons(allowed: bool) -> void:
	if game.car_button == null or game.jump_button == null:
		return
	var hero: Entity = game.hero
	var show: bool = allowed and enabled() and car != null and is_instance_valid(car) and not hero.dead
	game.car_button.visible = show
	if show:
		game.car_button.text = "Get out" if hero.mounted_on == car else "Car"
	var driving: bool = show and hero.mounted_on == car
	game.jump_button.visible = driving
	if driving:
		game.jump_button.text = "Drive home" if active else "Rift jump"
		game.jump_button.disabled = _jump_t >= 0.0 or _cool > 0.0


# --- the car ---------------------------------------------------------------------------------------

## Everyone in experimental mode has the car (while the experiment is on): it's there from the
## start, and back again if it's ever lost; switched off, it goes.
func _keep_car() -> void:
	var hero: Entity = game.hero
	if enabled():
		if car == null or not is_instance_valid(car) or car.dead or not hero.pets.has(car):
			_give_car()
		elif not car.parked and car.position.distance_to(hero.position) > 40.0:
			car.position = _beside(hero)           # (left far behind - a Recall, a gate: it finds you)
			car.path.clear()
	else:
		if active or veil > 0.0:
			_set_world(false, false)
			_chaos_step(0.0)                       # (the chaos ends with it)
		if car != null:
			_take_car()


func _give_car() -> void:
	var hero: Entity = game.hero
	if hero.dead:
		return
	car = game._spawn(Entity.Kind.MONSTER, CAR_NAME, Bestiary.CAR, Color("6a3cc8"), game.world.to_tile(hero.position))
	hero.adopt_pet(car)
	car.position = _beside(hero)
	car.home = car.position
	car.show_name(game.property.names_on)
	Fx.sparkle(game, car.position + Vector3(0.0, 0.8, 0.0), VIOLET, 24)
	if not _told:
		_told = true
		game.log_event("A car of violet metal hums beside you: the %s. Tap Car to get in, then Rift jump to drive through to another dimension." % CAR_NAME)


func _take_car() -> void:
	var hero: Entity = game.hero
	if hero.mounted_on == car:
		hero.dismount()
	hero.pets.erase(car)
	if car != null and is_instance_valid(car):
		car.vanish()
	car = null


## A free spot beside the hero (their right, their left, behind them).
func _beside(hero: Entity) -> Vector3:
	var yaw: float = hero._face_yaw
	var right := Vector3(cos(yaw), 0.0, -sin(yaw))
	var back := Vector3(sin(yaw), 0.0, cos(yaw))
	for off: Vector3 in [right * 1.8, -right * 1.8, back * 2.0, right * 1.0]:
		var p: Vector3 = hero.position + off
		if not game.world.is_blocked(game.world.to_tile(p)):
			return Vector3(p.x, game.world.height_at(p), p.z)
	return hero.position


## The Car button: in, or out. If the car is far off, it comes to you through a little rift.
func car_pressed() -> void:
	var hero: Entity = game.hero
	if hero.dead or car == null or not is_instance_valid(car) or _jump_t >= 0.0:
		return
	if hero.mounted_on == car:
		hero.dismount()
		return
	if game.frontier != null and not game.frontier.sail.is_empty():
		game.log_event("Not out on the water.")
		return
	if hero.mounted_on != null:
		hero.dismount()                            # (off the horse, into the car)
	if car.position.distance_to(hero.position) > 3.0:
		car.position = _beside(hero)
		car.path.clear()
		Fx.sparkle(game, car.position + Vector3(0.0, 0.8, 0.0), VIOLET, 20)
	if not hero.mount(car):
		game.log_event("You can't get in just now.")


# --- the jump ----------------------------------------------------------------------------------------

## Rift jump: a ring of light opens on the road ahead and the car runs into it.
func jump() -> void:
	var hero: Entity = game.hero
	if _jump_t >= 0.0 or _cool > 0.0 or hero.dead or car == null or hero.mounted_on != car:
		return
	var t: Vector2i = game.world.to_tile(hero.position)
	if game.world.is_dungeon(t) or game.world.is_cave(t):
		game.log_event("There's no room to open a rift down here.")
		return
	var yaw: float = hero._face_yaw
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var way := fwd
	for turn in [0.0, 0.5, -0.5, 1.0, -1.0, 1.6, -1.6, PI]:   # (ahead, or the nearest clear way)
		var f := fwd.rotated(Vector3.UP, float(turn))
		if _clear_run(hero.position, f, 8.5):
			way = f
			break
	_jump_dir = way
	_portal_pos = hero.position + way * 6.0
	_portal_pos.y = game.world.height_at(_portal_pos)
	_portal.global_position = _portal_pos + Vector3(0.0, 1.25, 0.0)
	_portal.rotation = Vector3(0.0, atan2(-way.x, -way.z), 0.0)
	_portal.scale = Vector3.ONE * 0.05
	_portal.visible = true
	_jump_t = 0.0
	_crossed = false
	_spark = 0.0
	hero.target = null
	hero.path.clear()
	hero.go_to(_portal_pos + way * 2.5)
	_sound("riser", 1.0, -2.0)


func _clear_run(from: Vector3, dir: Vector3, length: float) -> bool:
	var d := 0.5
	while d <= length:
		if game.world.is_blocked(game.world.to_tile(from + dir * d)):
			return false
		d += 0.5
	return true


func _jump_step(delta: float) -> void:
	var hero: Entity = game.hero
	_jump_t += delta
	if not _crossed:
		if hero.dead or hero.mounted_on != car:
			_portal.visible = false                # (out of the car: the ring fades away)
			_jump_t = -1.0
			return
		_portal.scale = Vector3.ONE * lerpf(0.05, 1.0, smoothstep(0.0, 0.7, _jump_t))
		_spark -= delta
		if _spark <= 0.0:
			_spark = 0.22
			Fx.sparkle(game, _portal.global_position, VIOLET if randf() < 0.5 else TEAL, 10)
		hero.target = null
		if hero.path.is_empty():
			hero.go_to(_portal_pos + _jump_dir * 2.5)   # (straight on into it)
		var near := Vector2(hero.position.x - _portal_pos.x, hero.position.z - _portal_pos.z).length() < 1.3
		if (near and _jump_t > 0.45) or _jump_t > 2.4:
			_crossed = true
			_cross_t = _jump_t
			_flash.color.a = 1.0                   # through: a white flash...
			_sound("braam", 1.0, 0.0)
			_set_world(not active, true)           # ...and the other side
		return
	var k := clampf((_jump_t - _cross_t) / 0.7, 0.0, 1.0)   # the ring closes behind you
	_portal.scale = Vector3.ONE * lerpf(1.0, 0.02, k)
	if k >= 1.0:
		_portal.visible = false
		_jump_t = -1.0
		_cool = 2.5


# --- the other side --------------------------------------------------------------------------------

## The Shardveil (on) or home (off), all at once - under the flash, when it's a jump.
func _set_world(on: bool, announce: bool) -> void:
	active = on
	veil = 1.0 if on else 0.0
	game.world.set_veil(veil)
	if game.sky_mat != null:
		game.sky_mat.set_shader_parameter("veil", veil)
	Art.set_tint(TINT if on else Color.WHITE)
	_motes.emitting = on
	_sky_things.visible = on
	if not on:
		_portal.visible = false
	game._music_timer = 0.0                        # (its music at once)
	game._apply_daylight()
	if announce:
		var vs: Vector2 = game.get_viewport().get_visible_rect().size
		var word := Title3D.make_flying("THE SHARDVEIL" if on else "HOME", minf(vs.x * 0.75, 1100.0),
			Title3D.ICE if on else Title3D.GOLD, vs)
		_layer.add_child(word)
		word.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if on:
			game.log_event("You drive through the rift into the Shardveil, the land in another dimension. Gold found here counts double.")
		else:
			game.log_event("You drive back through the rift. Home again.")


func _sound(sound_name: String, pitch: float, db: float) -> void:
	if game.property.sound_on:
		game.sfx.play(sound_name, pitch, db)


# --- the other adventurers' cars ----------------------------------------------------------------
# Every computer adventurer has a car of their own too (while the experiment is on): it drives
# itself after them, and when they're idle - nothing to fight - they get in and drive. Now and
# then one of them, on screen near you, opens a rift on the road ahead and drives off through it
# into the Shardveil; a minute or two later they come back the same way, where they left.

var _npc_cars := {}                            # an adventurer's instance id -> their car
var _npc_check := 0.0
var _trips: Array = []                         # each: {"who", "phase", "t", "ring", "at", "dir", "back"}
var _trip_cd := 30.0


func _npc_step(delta: float) -> void:
	_npc_check -= delta
	if _npc_check <= 0.0:
		_npc_check = 2.0
		_keep_npc_cars()
	for trip: Dictionary in _trips.duplicate():
		_trip_step(trip, delta)
	if not enabled():
		return
	_trip_cd -= delta
	if _trip_cd <= 0.0:
		_trip_cd = 6.0
		var who := _trip_candidate()
		if who != null:
			_start_trip(who)
			_trip_cd = randf_range(35.0, 80.0)        # (one at a time, now and then)


## Every computer adventurer with their car (a few new ones at a time, so nothing stutters); a car
## left far behind (a Recall, a gate) finds its driver again. Switched off, the cars go.
func _keep_npc_cars() -> void:
	if not enabled():
		_end_trips()
		for id in _npc_cars.keys():
			var c: Entity = _npc_cars[id]
			var owner_obj := instance_from_id(id)
			if owner_obj != null and is_instance_valid(owner_obj):
				var o := owner_obj as Entity
				if o.mounted_on == c:
					o.dismount()
				o.pets.erase(c)
			if c != null and is_instance_valid(c):
				c.vanish()
		_npc_cars.clear()
		return
	var given := 0
	for item in game.creatures:
		var e := item as Entity
		if e == null or e.kind != Entity.Kind.PLAYER or e.is_hero:
			continue
		var id := e.get_instance_id()
		var c: Entity = _npc_cars.get(id, null)
		var has := c != null and is_instance_valid(c) and not c.dead and e.pets.has(c)
		if not has:
			if e.dead or e.parked or given >= 3:
				continue
			c = game._spawn(Entity.Kind.MONSTER, "%s's %s" % [e.display_name, CAR_NAME], Bestiary.CAR, Color("6a3cc8"), game.world.to_tile(e.position))
			e.adopt_pet(c)
			c.position = _beside(e)
			c.home = c.position
			c.show_name(game.property.names_on)
			_npc_cars[id] = c
			given += 1
		elif not c.parked and not e.parked and c.position.distance_to(e.position) > 30.0:
			c.position = _beside(e)
			c.path.clear()


func _on_trip(e: Entity) -> bool:
	for trip: Dictionary in _trips:
		if trip["who"] == e:
			return true
	return false


## Who might drive off through a rift: an adventurer in their car, on screen near you, with
## nothing to fight, out in the open (not in a town, the dungeon or a cave).
func _trip_candidate() -> Entity:
	var hero: Entity = game.hero
	var best: Entity = null
	var best_d := 30.0
	for id in _npc_cars.keys():
		var o := instance_from_id(id)
		if o == null or not is_instance_valid(o):
			continue
		var e := o as Entity
		var c: Entity = _npc_cars[id]
		if e == null or e.dead or e.parked or not e._near or e.mounted_on != c or e.target != null or hero.target == e:
			continue
		if _on_trip(e):
			continue
		var t: Vector2i = game.world.to_tile(e.position)
		if game.world.is_town(t) or game.world.is_dungeon(t) or game.world.is_cave(t):
			continue
		var d := e.position.distance_to(hero.position)
		if d < best_d:
			best = e
			best_d = d
	return best


func _start_trip(who: Entity) -> void:
	var yaw: float = who._face_yaw
	var fwd := Vector3(-sin(yaw), 0.0, -cos(yaw))
	var way := fwd
	for turn in [0.0, 0.5, -0.5, 1.0, -1.0, 1.6, -1.6, PI]:
		var f := fwd.rotated(Vector3.UP, float(turn))
		if _clear_run(who.position, f, 7.5):
			way = f
			break
	var at := who.position + way * 5.0
	at.y = game.world.height_at(at)
	var ring := _new_portal()
	ring.global_position = at + Vector3(0.0, 1.25, 0.0)
	ring.rotation = Vector3(0.0, atan2(-way.x, -way.z), 0.0)
	ring.scale = Vector3.ONE * 0.05
	ring.visible = true
	who.target = null
	who.path.clear()
	who.go_to(at + way * 2.5)
	_trips.append({"who": who, "phase": "in", "t": 0.0, "ring": ring, "at": at, "dir": way, "back": 0.0})


func _trip_step(trip: Dictionary, delta: float) -> void:
	var who: Entity = trip["who"]
	var ring: Node3D = trip["ring"]
	trip["t"] = float(trip["t"]) + delta
	var t := float(trip["t"])
	match String(trip["phase"]):
		"in":                                      # the ring opens; they drive into it
			if who.dead or who.mounted_on == null or who.target != null:
				if ring != null and is_instance_valid(ring):
					ring.queue_free()              # (something came up: the ring fades)
				_trips.erase(trip)
				return
			ring.scale = Vector3.ONE * lerpf(0.05, 1.0, smoothstep(0.0, 0.7, t))
			var at: Vector3 = trip["at"]
			if who.path.is_empty():
				who.go_to(at + (trip["dir"] as Vector3) * 2.5)
			var near := Vector2(who.position.x - at.x, who.position.z - at.z).length() < 1.3
			if (near and t > 0.45) or t > 2.6:
				_away(who)
				Fx.sparkle(game, ring.global_position, VIOLET, 20)
				trip["phase"] = "close"
				trip["t"] = 0.0
		"close":                                   # through: the ring closes behind them
			ring.scale = Vector3.ONE * lerpf(1.0, 0.02, clampf(t / 0.7, 0.0, 1.0))
			if t >= 0.7:
				ring.queue_free()
				trip["ring"] = null
				trip["phase"] = "away"
				trip["t"] = 0.0
				trip["back"] = randf_range(45.0, 120.0)
		"away":                                    # in the Shardveil a while; then back
			if t >= float(trip["back"]):
				_back(who, true)
				_trips.erase(trip)


## Gone through: out of this world for now (nobody can see, find or fight them).
func _away(who: Entity) -> void:
	who.parked = true
	who.visible = false
	who.path.clear()
	who.target = null
	for item in game.creatures:
		var e := item as Entity
		if e != null and e.target == who:
			e.target = null


## Back from the Shardveil, where they left: through a ring of light that closes behind them.
func _back(who: Entity, show: bool) -> void:
	who.parked = false
	who.visible = true
	if not show or not game.in_view(who.position + Vector3(0.0, 1.0, 0.0), 2.0):
		return
	var ring := _new_portal()
	ring.global_position = who.position + Vector3(0.0, 1.25, 0.0)
	ring.rotation = Vector3(0.0, who._face_yaw, 0.0)
	ring.visible = true
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3.ONE * 0.02, 0.9).from(Vector3.ONE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(ring.queue_free)
	Fx.sparkle(game, who.position + Vector3(0.0, 1.0, 0.0), TEAL, 20)


## Everyone home at once, every ring gone (the experiment switched off, or a trailer starting).
func _end_trips() -> void:
	for trip: Dictionary in _trips:
		var ring: Node3D = trip["ring"]
		if ring != null and is_instance_valid(ring):
			ring.queue_free()
		if String(trip["phase"]) != "in":
			_back(trip["who"], false)
	_trips.clear()


# --- the Shardveil's chaos (the "Shardveil chaos" experiment) ------------------------------------
# In the Shardveil it's every one for themselves. Round you (35 m), everyone has a gun - you,
# the adventurers, every monster (the orcs and skeletons in hand; the wolves, bears, spiders and
# other beasts strapped to their backs) and the pets too - and anyone fights anyone: the
# adventurers each other and the beasts, the beasts each other, everyone you; no town is a refuge
# and no blow is a crime. And meteors keep falling out of the violet sky, burning whoever they
# land near. Back home, everyone has their own weapons again.

const GUNS := ["rift_shotgun", "shard_rocket", "spike_gun", "arc_caster", "ember_launcher"]
const CHAOS_RADIUS := 35.0
var chaos := false
var _armed: Array = []
var _arm_check := 0.0
var _meteor_t := 1.5
var _meteor_src: Entity


func _chaos_step(delta: float) -> void:
	var want: bool = active and Experiments.on("veil_chaos") and game.movie == null
	if want != chaos:
		chaos = want
		if chaos:
			_arm_check = 0.0
			_meteor_t = 1.2
			_action_start()
			game.log_event("In the Shardveil it's every one for themselves: everyone has a gun, and the sky is falling.")
		else:
			_action_end()
			_disarm_all()
	if not chaos:
		return
	_arm_check -= delta
	if _arm_check <= 0.0:
		_arm_check = 1.0
		_arm_round()
	_car_turrets(delta)
	_meteor_t -= delta
	if _meteor_t <= 0.0:
		_meteor_t = randf_range(0.9, 2.2)
		_meteor()
	_action_step(delta)


## Everyone near you gets a gun (and keeps it while near) - every monster too, and the pets; a
## beast with no hands has it strapped to its back. Anyone who's gone far off gets their own weapon
## back.
func _arm_round() -> void:
	var hero: Entity = game.hero
	for item in game.creatures:
		var e := item as Entity
		if e == null or e.dead or e.parked or e.is_vehicle or e.kind == Entity.Kind.NPC:
			continue
		var d := e.position.distance_to(hero.position)
		if e.has_meta("veil_weapon"):
			if d > CHAOS_RADIUS + 6.0:
				_disarm(e)
			elif Gear.gun(e.weapon) == "":
				e.weapon = String(e.get_meta("veil_gun"))   # (put away: in the Shardveil the gun's back in hand)
				e.refresh_look()
		elif d <= CHAOS_RADIUS:
			_arm(e)
	# the cars (the adventurers', and yours): a gun on the bonnet that fires by itself
	for item in _all_cars():
		var c: Entity = item
		if c == null or not is_instance_valid(c) or c.dead:
			continue
		var driver: Entity = c.pet_owner
		var at: Vector3 = driver.position if (c.parked and driver != null and is_instance_valid(driver)) else c.position
		var dc := at.distance_to(hero.position)
		if c.has_meta("veil_weapon"):
			if dc > CHAOS_RADIUS + 6.0:
				_disarm(c)
		elif dc <= CHAOS_RADIUS:
			_arm(c)


func _arm(e: Entity) -> void:
	var gun: String = "shard_rocket" if e.is_hero else String(GUNS[absi(e.display_name.hash()) % GUNS.size()])
	if e.has_meta("veil_pref_gun"):
		gun = String(e.get_meta("veil_pref_gun"))
	e.set_meta("veil_weapon", e.weapon)
	e.set_meta("veil_gun", gun)
	if not e.is_hero:                              # (they all know how to aim one here)
		e.set_meta("veil_archery", float(e.stats.skills.get(Hero.Skill.ARCHERY, 0.0)))
		e.stats.skills[Hero.Skill.ARCHERY] = maxf(float(e.stats.skills.get(Hero.Skill.ARCHERY, 0.0)), 55.0)
	e.weapon = gun
	e.refresh_look()
	_refresh_driver(e)
	_armed.append(e)


## An armed (or disarmed) car someone is driving: its driver's model carries the car, so it's
## rebuilt too.
func _refresh_driver(e: Entity) -> void:
	if e.is_vehicle and e.pet_owner != null and is_instance_valid(e.pet_owner) and e.pet_owner.mounted_on == e:
		e.pet_owner.refresh_look()


func _disarm(e: Entity) -> void:
	if e != null and is_instance_valid(e) and e.has_meta("veil_weapon"):
		e.weapon = String(e.get_meta("veil_weapon"))
		if e.has_meta("veil_archery"):
			e.stats.skills[Hero.Skill.ARCHERY] = float(e.get_meta("veil_archery"))
			e.remove_meta("veil_archery")
		e.remove_meta("veil_weapon")
		e.remove_meta("veil_gun")
		e.refresh_look()
		_refresh_driver(e)
	_armed.erase(e)


func _disarm_all() -> void:
	for e in _armed.duplicate():
		_disarm(e)
	_armed.clear()


## A meteor out of the violet sky, somewhere near you (now and then very near): it burns
## everyone it lands by. Not underground.
func _meteor() -> void:
	var hero: Entity = game.hero
	var t: Vector2i = game.world.to_tile(hero.position)
	if game.world.is_dungeon(t) or game.world.is_cave(t):
		return
	var a := randf() * TAU
	var d := randf_range(2.0, 7.0) if randf() < 0.3 else randf_range(7.0, 24.0)
	var at := hero.position + Vector3(cos(a) * d, 0.0, sin(a) * d)
	at.y = game.world.height_at(at)
	Fx.meteor(game, at, 0.0)
	get_tree().create_timer(0.47).timeout.connect(_meteor_lands.bind(at))


func _meteor_lands(at: Vector3) -> void:
	if not chaos:
		return
	game.sound("impact", at, 0.8, 2.0)
	if _meteor_src == null or not is_instance_valid(_meteor_src):
		_meteor_src = _make_src("a meteor")
	_meteor_src.position = at
	if randf() < 0.35:
		_drop_pickup(at)                           # (a shard left glowing in the crater)
	for item in game.creatures:
		var e := item as Entity
		if e == null or e.dead or e.parked or e.is_vehicle or e.kind == Entity.Kind.NPC:
			continue
		if e.position.distance_to(at) <= 2.4:
			e.take_damage(randf_range(10.0, 24.0), _meteor_src)


## What the meteors' burns come from (so a fall reads "slain by a meteor"): out of sight, out of
## the world's lists, and nobody to chase.
func _make_src(src_name: String) -> Entity:
	var src := Entity.new()
	game.add_child(src)
	src.setup(game, Entity.Kind.MONSTER, src_name, {"look": "blades", "passive": true, "str": 10, "dex": 10, "int": 10,
		"aggro": 0.0, "loot": {"gold_min": 0, "gold_max": 0, "drops": []}}, Color.WHITE, game.world.to_tile(game.hero.position))
	src.visible = false
	src.parked = true
	src.dead = true
	return src


## How often an armed car's gun fires (seconds), by the kind of gun.
const TURRET_EVERY := {"shotgun": 1.6, "rocket": 2.6, "spike": 0.6, "arc": 0.8, "grenade": 2.2}
var _turret_cd := {}


## The adventurers' armed cars fire by themselves: at what their driver is fighting if it's in
## reach, else at the nearest fair target in sight - from under the driver if they're in it, or from
## the car as it drives after them. A hit counts as the driver's (so anyone shot turns on them).
## Every car there is: the adventurers', and yours.
func _all_cars() -> Array:
	var out: Array = _npc_cars.values()
	if car != null and is_instance_valid(car):
		out.append(car)
	return out


func _car_turrets(delta: float) -> void:
	for item in _all_cars():
		var c: Entity = item
		if c == null or not is_instance_valid(c) or c.dead or not c.has_meta("veil_gun"):
			continue
		var driver: Entity = c.pet_owner
		if driver == null or not is_instance_valid(driver) or driver.dead or driver.parked:
			continue
		var cid := c.get_instance_id()
		var cd := float(_turret_cd.get(cid, randf_range(0.2, 1.5))) - delta
		if cd > 0.0:
			_turret_cd[cid] = cd
			continue
		var g := Gear.gun(c.weapon)
		var st: Dictionary = Gear.stats(c.weapon)
		var shooter: Entity = driver if c.parked else c
		var tgt := _turret_target(driver, shooter.position, float(st.get("range", 6.0)))
		if tgt == null:
			_turret_cd[cid] = 0.4                       # (nothing in reach: look again soon)
			continue
		_turret_cd[cid] = float(TURRET_EVERY.get(g, 1.5)) * randf_range(0.85, 1.2)
		shooter._gun_fire(g, tgt)
		if randf() < 0.7:
			var dmg := randf_range(float(st["min"]), float(st["max"])) * 0.8
			var hit_at := tgt.position
			tgt.take_damage(dmg, driver)
			if g in ["rocket", "grenade"]:
				driver._splash(hit_at, dmg * 0.5, tgt)


func _turret_target(driver: Entity, from: Vector3, reach: float) -> Entity:
	var t: Entity = driver.target
	if t != null and is_instance_valid(t) and not t.dead and t.position.distance_to(from) <= reach and driver._chaos_fair(t):
		return t
	var best: Entity = null
	var best_d := reach
	for item in game.creatures:
		var e := item as Entity
		if e == null or e == driver or e.dead:
			continue
		var d := e.position.distance_to(from)
		if d <= best_d and driver._chaos_fair(e) and game.world.line_clear(from, e.position):
			best = e
			best_d = d
	return best


# --- more action in the Shardveil (part of "Shardveil chaos") -------------------------------------
# Rifts keep tearing open round you and the Veilborn - crystal-touched orcs, skeletons, zombies,
# spiders, wolves and archers - pour out of them; every few minutes the Veil Colossus climbs out of a
# great rift; violet lightning strikes out of the sky; glowing shards (mend, overcharge, haste) lie in
# the craters and where the Veilborn fall; and a run of kills is called out in flying letters. A
# line across the top keeps the count.

const VEILBORN := [["Orc", Bestiary.ORC], ["Skeleton", Bestiary.SKELETON], ["Zombie", Bestiary.ZOMBIE],
	["Wolf", Bestiary.WOLF], ["Spider", Bestiary.GIANT_SPIDER], ["Archer", Bestiary.SKELETON_ARCHER]]
const VEILBORN_MAX := 10
const PICKUPS := {"mend": Color(0.35, 1.0, 0.7), "overcharge": Color(1.0, 0.35, 0.9), "haste": Color(1.0, 0.85, 0.3),
	"nova": Color(1.0, 0.55, 0.2), "aegis": Color(0.5, 0.8, 1.0)}
const STREAK_WORDS := {2: "DOUBLE KILL", 3: "TRIPLE KILL", 4: "MULTI KILL", 5: "RAMPAGE", 7: "UNSTOPPABLE", 10: "LEGENDARY"}
var overcharge := 0.0                          # seconds of double damage left (the hero)
var haste := 0.0                               # seconds of extra speed left (the hero)
var _veilborn: Array = []
var _rift_t := 6.0
var _colossus: Entity = null
var _colossus_t := 75.0
var _bolt_t := 3.0
var _bolt_src: Entity
var _pickups: Array = []                       # each: {"node", "kind", "t", "base"}
var _gem: ArrayMesh
var _streak := 0
var _last_kill := -100.0
var _veil_kills := 0
var _hud: Label


func _build_hud() -> void:
	_hud = Label.new()
	_hud.add_theme_font_size_override("font_size", 22)
	_hud.add_theme_color_override("font_color", Color(0.92, 0.78, 1.0))
	_hud.add_theme_color_override("font_outline_color", Color.BLACK)
	_hud.add_theme_constant_override("outline_size", 8)
	_hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_hud)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_hud.offset_left = -360.0
	_hud.offset_right = 360.0
	_hud.offset_top = 10.0
	_hud.visible = false


func _action_start() -> void:
	_action2_start()
	_rift_t = 5.0
	_colossus_t = randf_range(60.0, 90.0)
	_bolt_t = 3.0
	_veil_kills = 0
	_streak = 0
	overcharge = 0.0
	haste = 0.0


func _action_step(delta: float) -> void:
	overcharge = maxf(overcharge - delta, 0.0)
	haste = maxf(haste - delta, 0.0)
	_rift_t -= delta
	if _rift_t <= 0.0:
		_rift_t = randf_range(9.0, 16.0)
		_spawn_rift()
	_colossus_t -= delta
	if _colossus_t <= 0.0:
		_colossus_t = randf_range(150.0, 210.0)
		if _colossus == null or not is_instance_valid(_colossus) or _colossus.dead:
			_summon_colossus()
	_bolt_t -= delta
	if _bolt_t <= 0.0:
		_bolt_t = randf_range(2.5, 5.0)
		_rift_bolt()
	_pickups_step(delta)
	_action2_step(delta)
	_hud_step()


## Back home: the Veilborn and the Colossus gone, the shards gone, the powers gone.
func _action_end() -> void:
	for e in _veilborn:
		if is_instance_valid(e) and not (e as Entity).dead:
			(e as Entity).vanish()
	_veilborn.clear()
	if _colossus != null and is_instance_valid(_colossus) and not _colossus.dead:
		_colossus.vanish()
	_colossus = null
	for p: Dictionary in _pickups:
		var node: Node3D = p["node"]
		if is_instance_valid(node):
			node.queue_free()
	_pickups.clear()
	overcharge = 0.0
	haste = 0.0
	_streak = 0
	_action2_end()
	if _hud != null:
		_hud.visible = false


## Somewhere open near you (not in a wall, a house, a tree or the water), or INF.
func _veil_spot(min_d: float, max_d: float) -> Vector3:
	var hero: Entity = game.hero
	for _try in range(10):
		var a := randf() * TAU
		var d := randf_range(min_d, max_d)
		var p: Vector3 = hero.position + Vector3(cos(a) * d, 0.0, sin(a) * d)
		var t: Vector2i = game.world.to_tile(p)
		if game.world.in_bounds(t) and not game.world.is_blocked(t) \
				and game.world.tiles[t.y * game.world.cols + t.x] != World.Tile.WATER:
			return Vector3(p.x, game.world.height_at(p), p.z)
	return Vector3.INF


## A rift tearing open for a moment (facing you), sparks flying out of it.
func _rift_at(at: Vector3, size: float) -> void:
	var ring := _new_portal()
	var to_hero: Vector3 = game.hero.position - at
	ring.global_position = at + Vector3(0.0, 1.25 * size, 0.0)
	ring.rotation = Vector3(0.0, atan2(to_hero.x, to_hero.z), 0.0)
	ring.scale = Vector3.ONE * 0.05
	ring.visible = true
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector3.ONE * size, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_property(ring, "scale", Vector3.ONE * 0.02, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(ring.queue_free)
	Fx.sparkle(game, at + Vector3(0.0, 1.0, 0.0), VIOLET, 22)


## A rift opens and two to four Veilborn step out of it (ten at most at a time).
func _spawn_rift() -> void:
	var alive: Array = []
	for e in _veilborn:
		if is_instance_valid(e) and not (e as Entity).dead:
			alive.append(e)
	_veilborn = alive
	if _veilborn.size() >= _veilborn_cap():
		return
	var at := _veil_spot(9.0, 16.0)
	if at == Vector3.INF:
		return
	_rift_at(at, 0.75)
	for k in range(randi_range(2, 4)):
		var pick: Array = VEILBORN[randi() % VEILBORN.size()]
		var cfg: Dictionary = (pick[1] as Dictionary).duplicate(true)
		cfg["aggro"] = 14.0
		cfg["leash"] = 40
		cfg["passive"] = false
		cfg["str"] = roundi(float(cfg.get("str", 30)) * _veilborn_toughness())   # (tougher with every surge)
		var spot := at + Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2))
		var e: Entity = game.pool_spawn("Veilborn " + String(pick[0]), cfg, Color(0.75, 0.45, 1.0), spot)
		_mark_veilborn(e, 1.0)
		_veilborn.append(e)


func _mark_veilborn(e: Entity, size: float) -> void:
	if e.has_meta("veilborn"):
		return
	e.set_meta("veilborn", true)
	var glow := Fx.cast_glow(VIOLET)                # (motes of violet light rising off them)
	glow.scale = Vector3.ONE * size
	e.add_child(glow)
	glow.emitting = true


## The Veil Colossus: a giant of the Shardveil climbs out of a great rift, an ember launcher in hand.
func _summon_colossus() -> void:
	var at := _veil_spot(12.0, 18.0)
	if at == Vector3.INF:
		return
	_rift_at(at, 1.8)
	var cfg: Dictionary = Bestiary.OGRE.duplicate(true)
	cfg["scale"] = 2.6
	cfg["str"] = 420
	cfg["danger"] = 12
	cfg["dmg_min"] = 18
	cfg["dmg_max"] = 34
	cfg["armor"] = 6.0
	cfg["aggro"] = 20.0
	cfg["leash"] = 60
	cfg["boss"] = true
	cfg["passive"] = false
	cfg["loot"] = {"gold_min": 400, "gold_max": 900, "drops": [["platemail", 0.5], ["heater_shield", 0.4], ["double_axe", 0.3]]}
	_colossus = game.pool_spawn("the Veil Colossus", cfg, Color(0.6, 0.35, 0.95), at)
	_colossus.set_meta("veil_pref_gun", "ember_launcher")
	_mark_veilborn(_colossus, 2.2)
	_colossus.target = game.hero
	_announce("THE VEIL COLOSSUS", Title3D.GOLD)
	_sound("braam", 0.8, 2.0)
	game.log_event("A great rift tears open: the Veil Colossus climbs out of it!")


## Violet lightning out of the Shardveil's sky, near you; it burns whoever it strikes by.
func _rift_bolt() -> void:
	var hero: Entity = game.hero
	var t: Vector2i = game.world.to_tile(hero.position)
	if game.world.is_dungeon(t) or game.world.is_cave(t):
		return
	var a := randf() * TAU
	var d := randf_range(2.0, 5.0) if randf() < 0.25 else randf_range(5.0, 20.0)
	var at := hero.position + Vector3(cos(a) * d, 0.0, sin(a) * d)
	at.y = game.world.height_at(at)
	Fx.lightning(game, at, Color(0.85, 0.55, 1.0))
	game.sound("thunder", at, 1.3, -6.0)
	if _bolt_src == null or not is_instance_valid(_bolt_src):
		_bolt_src = _make_src("violet lightning")
	_bolt_src.position = at
	for item in game.creatures:
		var e := item as Entity
		if e == null or e.dead or e.parked or e.is_vehicle or e.kind == Entity.Kind.NPC:
			continue
		if e.position.distance_to(at) <= 2.0:
			e.take_damage(randf_range(8.0, 18.0), _bolt_src)


## A glowing shard left lying: mend (half your health back), overcharge (double damage for 12 s)
## or haste (faster for 12 s). Walk (or drive) over it to take it; it fades after 25 s.
func _drop_pickup(at: Vector3) -> void:
	if _pickups.size() >= 6:
		return
	if _gem == null:
		_gem = Art.merge([[Art.cone(0.22, 0.3, 0.0, 6), Art.at(0, 0.15, 0), Color.WHITE],
			[Art.cone(0.22, 0.3, 0.0, 6), Art.at(0, -0.15, 0, Vector3(PI, 0, 0)), Color.WHITE]])
	var kinds: Array = PICKUPS.keys()
	var kind := String(kinds[randi() % kinds.size()])
	var col: Color = PICKUPS[kind]
	var node := Node3D.new()
	game.add_child(node)
	node.global_position = Vector3(at.x, game.world.height_at(at) + 0.6, at.z)
	var gem := MeshInstance3D.new()
	gem.mesh = _gem
	gem.material_override = Art.glow_mat(col)
	gem.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(gem)
	Fx.sparkle(game, node.global_position, col, 14)
	_pickups.append({"node": node, "kind": kind, "t": 25.0, "base": node.global_position.y})


func _pickups_step(delta: float) -> void:
	var hero: Entity = game.hero
	for p: Dictionary in _pickups.duplicate():
		var node: Node3D = p["node"]
		if not is_instance_valid(node):
			_pickups.erase(p)
			continue
		p["t"] = float(p["t"]) - delta
		var left := float(p["t"])
		node.rotation.y += delta * 2.5
		node.position.y = float(p["base"]) + sin(Time.get_ticks_msec() * 0.004) * 0.12
		node.visible = left > 5.0 or fmod(left, 0.4) > 0.2     # (blinking as it fades)
		var flat := Vector2(node.position.x - hero.position.x, node.position.z - hero.position.z).length()
		if not hero.dead and flat < 1.3:
			_take_pickup(String(p["kind"]), node.global_position)
			node.queue_free()
			_pickups.erase(p)
		elif left <= 0.0:
			node.queue_free()
			_pickups.erase(p)


func _take_pickup(kind: String, at: Vector3) -> void:
	var hero: Entity = game.hero
	var col: Color = PICKUPS[kind]
	Fx.sparkle(game, at, col, 24)
	match kind:
		"mend":
			hero.hp = minf(hero.hp + float(hero.stats.max_hp()) * 0.5, float(hero.stats.max_hp()))
			hero._pop("MEND!", col)
		"overcharge":
			overcharge = 12.0
			hero._pop("OVERCHARGE!", col)
		"haste":
			haste = 12.0
			hero._pop("HASTE!", col)
		"nova":
			hero._pop("NOVA!", col)
			_nova()
		"aegis":
			aegis = 6.0
			hero._pop("AEGIS!", col)
	_sound("gain", 1.2, -4.0)


## Every death in the Shardveil: the Veilborn may leave a shard, the Colossus leaves three - and a
## run of the hero's kills (each within 4 s of the last) is called out.
func on_kill(killer: Entity, victim: Entity) -> void:
	if not chaos or victim == null:
		return
	if victim == _champ:
		_champion_down(killer)
	if victim == _colossus:
		_announce("COLOSSUS DOWN", Title3D.GOLD)
		game.log_event("The Veil Colossus falls!")
		for k in range(3):
			_drop_pickup(victim.position + Vector3(cos(k * 2.1) * 1.5, 0.0, sin(k * 2.1) * 1.5))
	elif victim.has_meta("veilborn") and randf() < 0.3:
		_drop_pickup(victim.position)
	if killer == null or not killer.is_hero:
		return
	var now := Time.get_ticks_msec() / 1000.0
	_streak = _streak + 1 if now - _last_kill <= 4.0 else 1
	_last_kill = now
	_veil_kills += 1
	if STREAK_WORDS.has(_streak):
		_announce(String(STREAK_WORDS[_streak]), Title3D.ICE if _streak < 5 else Title3D.GOLD)
		_sound("braam", 1.0 + 0.08 * float(_streak), -2.0)


## Big words flying past (the Colossus coming, a run of kills).
func _announce(text: String, colour: Color) -> void:
	var vs: Vector2 = game.get_viewport().get_visible_rect().size
	var word := Title3D.make_flying(text, minf(vs.x * 0.6, 900.0), colour, vs)
	_layer.add_child(word)
	word.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## The line across the top: your kills here, the powers you have and for how long, the Colossus.
func _hud_step() -> void:
	if _hud == null:
		return
	var parts: Array[String] = ["THE SHARDVEIL", "kills %d" % _veil_kills]
	if overcharge > 0.0:
		parts.append("OVERCHARGE %ds" % ceili(overcharge))
	if haste > 0.0:
		parts.append("HASTE %ds" % ceili(haste))
	if aegis > 0.0:
		parts.append("AEGIS %ds" % ceili(aegis))
	if _surge_left > 0.0:
		parts.append("SURGE %d: %ds" % [_surge_n, ceili(_surge_left)])
	else:
		parts.append("next surge %ds" % ceili(_surge_t))
	if _champ != null and is_instance_valid(_champ) and not _champ.dead:
		parts.append("CHAMPION: %s" % _champ.display_name)
	if _colossus != null and is_instance_valid(_colossus) and not _colossus.dead:
		parts.append("COLOSSUS %d%%" % roundi(100.0 * _colossus.hp / maxf(float(_colossus.stats.max_hp()), 1.0)))
	_hud.text = "  ·  ".join(parts)
	_hud.visible = true


# --- still more action in the Shardveil (part of "Shardveil chaos") -------------------------------
# Rift surges: every minute or so the rifts go wild for a while - Veilborn pouring out every few
# seconds, more and tougher with every surge, meteors and lightning in a frenzy - and riding one
# out pays. Your own car is armed too (its gun fires by itself) and rams whatever you drive into at
# speed. Two more shards: Nova (a blast all round you) and Aegis (nothing touches you for a few
# seconds). And now and then someone near you rises as the Rift Champion - a gold glow, twice the
# life - with a bounty on their head.

var aegis := 0.0                               # seconds the hero can't be hurt (the aegis shard)
var _surge_t := 70.0                           # until the next surge
var _surge_left := 0.0                         # of the surge under way
var _surge_n := 0
var _surge_fx := 0.0
var _champ: Entity = null
var _champ_glow: Node3D
var _champ_t := 45.0
var _bubble: MeshInstance3D
var _ram_last := {}                            # who was rammed when (no ramming the same one twice in a second)
var _last_hero_pos := Vector3.INF


func _action2_start() -> void:
	_surge_t = randf_range(55.0, 75.0)
	_surge_left = 0.0
	_surge_n = 0
	_champ_t = randf_range(30.0, 50.0)
	aegis = 0.0
	_last_hero_pos = Vector3.INF


func _action2_end() -> void:
	_surge_left = 0.0
	aegis = 0.0
	if _bubble != null:
		_bubble.visible = false
	_clear_champion()


func _action2_step(delta: float) -> void:
	aegis = maxf(aegis - delta, 0.0)
	_bubble_step()
	_surge_step(delta)
	_champion_step(delta)
	_ram_step(delta)


## The surges: every 70-90 s the rifts go wild for 14 s (a little longer each time).
func _surge_step(delta: float) -> void:
	if _surge_left > 0.0:
		_surge_left -= delta
		_rift_t = minf(_rift_t, 2.5)               # (a rift every couple of seconds)
		_surge_fx -= delta
		if _surge_fx <= 0.0:
			_surge_fx = 0.6
			_meteor()                              # (meteors and lightning in a frenzy)
			if randf() < 0.5:
				_rift_bolt()
		if _surge_left <= 0.0:
			_surge_t = randf_range(70.0, 90.0)
			_announce("SURGE SURVIVED", Title3D.GOLD)
			_sound("braam", 1.15, 0.0)
			var hero: Entity = game.hero
			if not hero.dead:
				var purse := 100 * _surge_n
				hero._earn(purse)
				game.log_event("You ride out rift surge %d: %d gold, and shards." % [_surge_n, purse])
				for k in range(2):
					_drop_pickup(hero.position + Vector3(cos(k * PI + 0.7) * 2.0, 0.0, sin(k * PI + 0.7) * 2.0))
		return
	_surge_t -= delta
	if _surge_t <= 0.0:
		_surge_n += 1
		_surge_left = minf(14.0 + 2.0 * float(_surge_n), 24.0)
		_surge_fx = 0.0
		_announce("RIFT SURGE %d" % _surge_n, Title3D.ICE)
		_sound("braam", 0.7, 2.0)
		game.log_event("Rift surge %d! The rifts are tearing open all round you." % _surge_n)


## How many Veilborn may be about at once (more in a surge, more with every surge) and how tough.
func _veilborn_cap() -> int:
	return VEILBORN_MAX + (3 * _surge_n if _surge_left > 0.0 else 0)


func _veilborn_toughness() -> float:
	return 1.0 + 0.12 * float(_surge_n)


## Ramming: driving into someone at speed knocks them flying and hurts them.
func _ram_step(delta: float) -> void:
	var hero: Entity = game.hero
	if _last_hero_pos == Vector3.INF or delta <= 0.0:
		_last_hero_pos = hero.position
		return
	var move := hero.position - _last_hero_pos
	_last_hero_pos = hero.position
	move.y = 0.0
	if car == null or hero.mounted_on != car or hero.dead or move.length() / delta < 4.0:
		return
	var fwd := move.normalized()
	var front := hero.position + fwd * 0.9
	var now := Time.get_ticks_msec() / 1000.0
	for item in game.creatures:
		var e := item as Entity
		if e == null or e == hero or e.dead or e.position.distance_to(front) > 1.5 or not hero._chaos_fair(e):
			continue
		var eid := e.get_instance_id()
		if now - float(_ram_last.get(eid, -10.0)) < 1.0:
			continue
		_ram_last[eid] = now
		var dmg := randf_range(14.0, 26.0) * (2.0 if overcharge > 0.0 else 1.0)
		e.take_damage(dmg, hero)
		var to := e.position + fwd * 1.4
		if not e.dead and not game.world.is_blocked(game.world.to_tile(to)):
			var tw := e.create_tween()
			tw.tween_property(e, "position", Vector3(to.x, game.world.height_at(to), to.z), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		e._pop("RAMMED!", Color(1.0, 0.75, 0.3))
		Fx.sparkle(game, e.position + Vector3(0.0, 1.0, 0.0), Color(1.0, 0.75, 0.3), 14)
		game.sound("impact", e.position, 1.3, -6.0)


## The Rift Champion: someone near you (an adventurer or one of the Veilborn) rises, glowing gold,
## with twice their life - and a bounty: bring them down for gold and two shards.
func _champion_step(delta: float) -> void:
	if _champ != null and (not is_instance_valid(_champ) or _champ.dead):
		_clear_champion()
	if _champ != null:
		return
	_champ_t -= delta
	if _champ_t > 0.0:
		return
	_champ_t = randf_range(45.0, 70.0)
	var hero: Entity = game.hero
	var best: Entity = null
	var best_d := 25.0
	for item in game.creatures:
		var e := item as Entity
		if e == null or e == hero or e.dead or e.parked or e == _colossus or not hero._chaos_fair(e):
			continue
		if e.kind != Entity.Kind.PLAYER and not e.has_meta("veilborn"):
			continue
		var d := e.position.distance_to(hero.position)
		if d < best_d:
			best = e
			best_d = d
	if best == null:
		return
	_champ = best
	_champ.hp = float(_champ.stats.max_hp()) * 2.0
	_champ_glow = Fx.cast_glow(Color(1.0, 0.82, 0.3))
	_champ_glow.scale = Vector3.ONE * 1.6
	_champ.add_child(_champ_glow)
	(_champ_glow as CPUParticles3D).emitting = true
	_champ._pop("RIFT CHAMPION!", Color(1.0, 0.85, 0.35))
	_announce("A CHAMPION RISES", Title3D.GOLD)
	game.log_event("%s rises as the Rift Champion: bring them down for the bounty!" % _champ.display_name)


func _clear_champion() -> void:
	if _champ_glow != null and is_instance_valid(_champ_glow):
		_champ_glow.queue_free()
	_champ_glow = null
	_champ = null


## The champion is down: the bounty, if it was you.
func _champion_down(killer: Entity) -> void:
	var at := _champ.position
	_clear_champion()
	for k in range(2):
		_drop_pickup(at + Vector3(cos(k * PI) * 1.2, 0.0, sin(k * PI) * 1.2))
	if killer != null and killer.is_hero:
		killer._earn(250)
		_announce("CHAMPION SLAIN", Title3D.GOLD)
		game.log_event("You bring down the Rift Champion: 250 gold.")


## The aegis shard's bubble of light round the hero while it lasts.
func _bubble_step() -> void:
	var hero: Entity = game.hero
	if aegis <= 0.0:
		if _bubble != null:
			_bubble.visible = false
		return
	if _bubble == null or not is_instance_valid(_bubble):
		var m := SphereMesh.new()
		m.radius = 1.05
		m.height = 2.1
		m.radial_segments = 20
		m.rings = 10
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.5, 0.8, 1.0, 0.22)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_bubble = MeshInstance3D.new()
		_bubble.mesh = m
		_bubble.material_override = mat
		_bubble.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		game.add_child(_bubble)
	_bubble.visible = aegis > 1.5 or fmod(aegis, 0.3) > 0.15   # (flickering as it ends)
	_bubble.global_position = hero.position + Vector3(0.0, 0.95, 0.0)


## The nova shard: a blast all round you, burning everyone within 6 m.
func _nova() -> void:
	var hero: Entity = game.hero
	Fx.burst(game, hero.position + Vector3(0.0, 1.0, 0.0), 2.4)
	Fx.sparkle(game, hero.position + Vector3(0.0, 0.6, 0.0), Color(1.0, 0.6, 0.25), 40)
	game.sound("blast", hero.position, 0.8, 0.0)
	for item in game.creatures:
		var e := item as Entity
		if e == null or e == hero or e.dead or e.position.distance_to(hero.position) > 6.0 or not hero._chaos_fair(e):
			continue
		e.take_damage(randf_range(20.0, 35.0) * (2.0 if overcharge > 0.0 else 1.0), hero)
