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
	_portal = Node3D.new()
	_portal.visible = false
	game.add_child(_portal)
	for spec in [[1.45, 1.65, VIOLET], [1.2, 1.3, TEAL]]:
		var t := TorusMesh.new()
		t.inner_radius = float(spec[0])
		t.outer_radius = float(spec[1])
		t.rings = 32
		t.ring_segments = 8
		var ring := MeshInstance3D.new()
		ring.mesh = t
		ring.material_override = Art.glow_mat(spec[2])
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.rotation.x = PI * 0.5                 # standing up across the road
		_portal.add_child(ring)
	var sh := Shader.new()
	sh.code = DISC_SHADER
	var disc_mat := ShaderMaterial.new()
	disc_mat.shader = sh
	var plane := PlaneMesh.new()
	plane.size = Vector2(3.0, 3.0)
	var disc := MeshInstance3D.new()
	disc.mesh = plane
	disc.material_override = disc_mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.rotation.x = PI * 0.5
	_portal.add_child(disc)


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
		_buttons(false)
		return
	_buttons(true)
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
	else:
		if active or veil > 0.0:
			_set_world(false, false)
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
