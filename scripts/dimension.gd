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
			game.log_event("In the Shardveil it's every one for themselves: everyone has a gun, and the sky is falling.")
		else:
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
	# the adventurers' cars: a gun on the bonnet that fires by itself (driven or driving after them)
	for id in _npc_cars.keys():
		var c: Entity = _npc_cars[id]
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
		_make_meteor_src()
	_meteor_src.position = at
	for item in game.creatures:
		var e := item as Entity
		if e == null or e.dead or e.parked or e.is_vehicle or e.kind == Entity.Kind.NPC:
			continue
		if e.position.distance_to(at) <= 2.4:
			e.take_damage(randf_range(10.0, 24.0), _meteor_src)


## What the meteors' burns come from (so a fall reads "slain by a meteor"): out of sight, out of
## the world's lists, and nobody to chase.
func _make_meteor_src() -> void:
	_meteor_src = Entity.new()
	game.add_child(_meteor_src)
	_meteor_src.setup(game, Entity.Kind.MONSTER, "a meteor", {"look": "blades", "passive": true, "str": 10, "dex": 10, "int": 10,
		"aggro": 0.0, "loot": {"gold_min": 0, "gold_max": 0, "drops": []}}, Color.WHITE, game.world.to_tile(game.hero.position))
	_meteor_src.visible = false
	_meteor_src.parked = true
	_meteor_src.dead = true


## How often an armed car's gun fires (seconds), by the kind of gun.
const TURRET_EVERY := {"shotgun": 1.6, "rocket": 2.6, "spike": 0.6, "arc": 0.8, "grenade": 2.2}
var _turret_cd := {}


## The adventurers' armed cars fire by themselves: at what their driver is fighting if it's in
## reach, else at the nearest fair target in sight - from under the driver if they're in it, or from
## the car as it drives after them. A hit counts as the driver's (so anyone shot turns on them).
func _car_turrets(delta: float) -> void:
	for id in _npc_cars.keys():
		var c: Entity = _npc_cars[id]
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
