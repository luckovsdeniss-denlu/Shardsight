class_name Dimension
extends Node
## The dimension car (the "Dimension car" experiment - on for everyone in experimental mode).
##
## Everyone gets the Riftrunner: a low open car of violet metal with a shard of crystal turning in
## its back. It drives itself after you when you walk, and you get in and out with the Car button
## (or Ride). It can't be hurt and never fights. Driving it, Rift jump changes the car - wheels
## folding into hover pads, wings out, the shard rising, lifting off - and it shoots ahead and, in
## a white flash, through to the Shardveil - the same
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
	_sweep_changes(delta)
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

## Rift jump: the car changes. It stops; its wheels fold up flat into glowing hover pads; wings of
## violet metal swing out from its sides with thrusters behind; the shard rises from its cradle,
## swelling and spinning fast; the car lifts off the ground, rings of light whirling round it -
## then it shoots ahead and, in a white flash, it's through to the other side, where it settles
## back down, folds its wings and drops onto its wheels again.
const TF_RISE := 1.5                           # seconds of changing before the dash
const TF_CROSS := 2.35                         # when it's through
const TF_SETTLE := 1.3                         # changing back on the other side


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
	_portal_pos = hero.position + way * 9.0
	_jump_t = 0.0
	_crossed = false
	_spark = 0.0
	_dashing = false
	hero.target = null
	hero.path.clear()
	_sound("riser", 0.8, -6.0)


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
			_tf_clear()                            # (out of the car: it's just a car again)
			_jump_t = -1.0
			return
		hero.target = null
		if _jump_t < TF_RISE:
			hero.path.clear()                      # (standing still while it changes)
		elif not _dashing or hero.path.is_empty():
			_dashing = true
			hero.go_to(_portal_pos + _jump_dir * 6.0)   # (and then away, straight ahead)
		if _change == null:
			_change = _new_change(hero)
		_change.pose_out(delta, _jump_t)
		var k_lift := smoothstep(0.6, 1.4, _jump_t)
		_spark -= delta
		if _spark <= 0.0:
			_spark = 0.12 if _jump_t > 0.9 else 0.25
			Fx.sparkle(game, hero.position + Vector3(randf_range(-1.0, 1.0), 0.6 + k_lift, randf_range(-1.0, 1.0)),
				VIOLET if randf() < 0.5 else TEAL, 8)
		if _jump_t >= TF_CROSS:
			_crossed = true
			_cross_t = _jump_t
			_flash.color.a = 1.0                   # through: a white flash...
			_sound("braam", 1.0, -4.0)
			_set_world(not active, true)           # ...and the other side
		return
	# the other side: it slows, settles down, folds its wings and drops back onto its wheels
	var k := clampf((_jump_t - _cross_t) / TF_SETTLE, 0.0, 1.0)
	if k < 0.35 and hero.mounted_on == car:
		hero.target = null
	if _change == null:
		_change = _new_change(hero)
	_change.pose_back(delta, _jump_t, k)
	if k >= 1.0 or hero.mounted_on != car:
		_tf_clear()
		_jump_t = -1.0
		_cool = 2.5


# --- the car changing (its parts, on the driver's model while they drive it) ---

var _dashing := false
var _change: CarChange = null                  # the hero's car changing


## A car changing under its driver: finds the car's parts on the driver's model and fits the new
## ones on (again, if the model was rebuilt meanwhile - a refresh makes it afresh, plain), then
## poses it at a point in the change; clear() makes it a plain car again.
class CarChange:
	var who: Entity
	var rings_from: Array                      # the ring meshes to whirl round it
	var root: Node3D = null
	var rider: Node3D = null
	var rider_y := 0.0
	var wheel_base: Array = []
	var spin_base := Vector3.ZERO
	var wings: Array = []
	var jets: Array = []
	var rings: Node3D = null
	static var wing_mesh: ArrayMesh = null
	static var jet_mesh: ArrayMesh = null
	static var cyber_shader: Shader = null
	static var chunk_mesh: BoxMesh = null
	var sound: Callable                        # (name, pitch, dB): heard as the car changes
	var world: Node                            # where the bursts of dust, sparks and shards fly
	var cyber: ShaderMaterial = null           # the cyber skin spreading over the car
	var swapped: Array = []                    # [mesh, its own material] while it wears the skin
	var inflow: CPUParticles3D = null          # energy pulled in, swirling, as it charges
	var sparks: CPUParticles3D = null          # sparks off the folding wheels, falling
	var trail: CPUParticles3D = null           # a streaming trail behind it as it shoots away
	var last_t := -1.0
	var last_k := -1.0
	var scar: Node3D = null                    # the marks it leaves on the ground (they outlive the change)
	var scar_mat: ShaderMaterial = null          # the tracks
	var ring_mat: ShaderMaterial = null          # the rings
	var last_drop := Vector3.INF
	static var scar_shader: Shader = null

	func _init(p_who: Entity, p_rings: Array, p_sound: Callable, p_world: Node) -> void:
		who = p_who
		rings_from = p_rings
		sound = p_sound
		world = p_world

	func _attach() -> bool:
		if who == null or not is_instance_valid(who):
			return false
		var m: Dictionary = who.model
		var r: Variant = m.get("mount_root")
		if r == null or not is_instance_valid(r):
			return false
		if r == root:
			return true
		root = r as Node3D
		rider = m.get("root") as Node3D
		rider_y = rider.position.y if rider != null else 0.0
		wheel_base.clear()
		for w in m.get("wheels", []):
			wheel_base.append([w, (w as Node3D).position])
		var spin: Node3D = m.get("spin") as Node3D
		spin_base = spin.position if spin != null else Vector3.ZERO
		if wing_mesh == null:
			var paint := Color(0.36, 0.16, 0.62)
			wing_mesh = Art.merge([[Art.box(1.1, 0.05, 0.55), Art.at(-0.55, 0, 0.0), paint.lightened(0.05)],
				[Art.box(0.7, 0.05, 0.3), Art.at(-1.0, 0.0, 0.32, Vector3(0, 0.5, 0)), paint.darkened(0.15)],
				[Art.box(1.05, 0.07, 0.06), Art.at(-0.55, 0.01, -0.27), Color(0.78, 0.8, 0.86)]])
			jet_mesh = Art.merge([[Art.cone(0.13, 0.3, 0.09, 8), Art.at(0, 0, 0, Vector3(PI * 0.5, 0, 0)), Color(0.25, 0.25, 0.3)]])
		wings.clear()
		jets.clear()
		for side: float in [-1.0, 1.0]:
			var piv := Node3D.new()                # hinged at the car's side, swinging out
			piv.position = Vector3(side * 0.56, 0.5, 0.1)
			root.add_child(piv)
			var wing := MeshInstance3D.new()
			wing.mesh = wing_mesh
			wing.material_override = Art.vc_mat()
			wing.scale = Vector3(-side, 1.0, 1.0)  # (mirrored on the right)
			piv.add_child(wing)
			var edge := MeshInstance3D.new()       # a glowing line along the wing's back edge
			var em := BoxMesh.new()
			em.size = Vector3(1.0, 0.03, 0.04)
			edge.mesh = em
			edge.material_override = Art.glow_mat(TEAL if side < 0.0 else VIOLET)
			edge.position = Vector3(side * 0.55, 0.03, 0.28)
			edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			piv.add_child(edge)
			wings.append(piv)
			var jet := Node3D.new()                # a thruster behind, sliding out of the back
			jet.position = Vector3(side * 0.34, 0.45, 1.05)
			root.add_child(jet)
			var body := MeshInstance3D.new()
			body.mesh = jet_mesh
			body.material_override = Art.vc_mat()
			jet.add_child(body)
			var fire := Fx.flame(0.09, 16, 0.5)
			fire.rotation.x = PI * 0.5             # (blowing out behind)
			fire.position.z = 0.16
			fire.gravity = Vector3.ZERO
			var ramp := Gradient.new()             # (rift fire: white, violet, teal, gone)
			ramp.set_color(0, Color(1.0, 0.95, 1.0, 1.0))
			ramp.set_color(1, Color(0.3, 0.95, 1.0, 0.0))
			ramp.add_point(0.35, Color(0.85, 0.45, 1.0, 0.9))
			fire.color_ramp = ramp
			jet.add_child(fire)
			jets.append(jet)
		rings = Node3D.new()
		root.add_child(rings)
		for i in range(3):
			var ring := MeshInstance3D.new()
			ring.mesh = rings_from[i % rings_from.size()]
			ring.material_override = Art.glow_mat(VIOLET if i != 1 else TEAL)
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			rings.add_child(ring)
		# the cyber skin: every plain-painted part of the car (its new wings too) wears it
		if cyber_shader == null:
			cyber_shader = Shader.new()
			cyber_shader.code = CYBER_SHADER
		cyber = ShaderMaterial.new()
		cyber.shader = cyber_shader
		cyber.set_shader_parameter("tint", Art.tint)
		swapped.clear()
		var stack: Array = [root]
		while not stack.is_empty():
			var n: Node = stack.pop_back()
			stack.append_array(n.get_children())
			var mi := n as MeshInstance3D
			if mi != null and mi.material_override is StandardMaterial3D \
					and (mi.material_override as StandardMaterial3D).vertex_color_use_as_albedo \
					and not (mi.material_override as StandardMaterial3D).emission_enabled:
				swapped.append([mi, mi.material_override])
				mi.material_override = cyber
		# the particles: thrown into the world (they don't follow the car once they're out)
		inflow = _emitter(48, 0.55, 0.11)
		inflow.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		inflow.emission_sphere_radius = 2.6
		inflow.radial_accel_min = -14.0            # pulled in to the car...
		inflow.radial_accel_max = -10.0
		inflow.tangential_accel_min = 6.0          # ...swirling round it
		inflow.tangential_accel_max = 9.0
		inflow.gravity = Vector3.ZERO
		inflow.color_ramp = _ramp([Color(0.3, 0.95, 1.0, 0.0), Color(0.6, 0.7, 1.0, 1.0), Color(1.0, 0.6, 1.0, 1.0)])
		inflow.position = Vector3(0.0, 0.6, 0.0)
		sparks = _emitter(40, 0.45, 0.07)        # (short-lived: gone before they reach the ground)
		sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		sparks.emission_box_extents = Vector3(0.7, 0.05, 0.8)
		sparks.direction = Vector3.UP
		sparks.spread = 65.0
		sparks.initial_velocity_min = 2.0
		sparks.initial_velocity_max = 4.5
		sparks.gravity = Vector3(0.0, -6.0, 0.0)   # (real arcs: up and over, fading as they fall)
		sparks.color_ramp = _ramp([Color(1.0, 1.0, 0.9, 1.0), Color(1.0, 0.75, 0.3, 0.8), Color(1.0, 0.3, 0.1, 0.0)])
		sparks.position = Vector3(0.0, 0.3, 0.0)
		trail = _emitter(60, 0.35, 0.16)
		trail.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		trail.emission_box_extents = Vector3(0.45, 0.12, 0.1)
		trail.direction = Vector3(0.0, 0.0, 1.0)   # out behind
		trail.spread = 12.0
		trail.initial_velocity_min = 3.0
		trail.initial_velocity_max = 6.0
		trail.gravity = Vector3(0.0, 0.6, 0.0)
		trail.damping_min = 2.0
		trail.damping_max = 4.0
		trail.color_ramp = _ramp([Color(1.0, 1.0, 1.0, 1.0), Color(0.9, 0.45, 1.0, 0.9), Color(0.3, 0.95, 1.0, 0.0)])
		trail.position = Vector3(0.0, 0.45, 1.2)
		return true

	## A stream of glowing motes on the car, left behind in the world.
	func _emitter(n: int, life: float, size: float) -> CPUParticles3D:
		var p := CPUParticles3D.new()
		p.amount = n
		p.lifetime = life
		p.local_coords = false
		p.mesh = Fx._quad(size, Color.WHITE)
		p.emitting = false
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.4
		root.add_child(p)
		return p

	static func _ramp(cols: Array) -> Gradient:
		var g := Gradient.new()
		var offs := PackedFloat32Array()
		var cs := PackedColorArray()
		for i in range(cols.size()):
			offs.append(float(i) / float(cols.size() - 1))
			cs.append(cols[i])
		g.offsets = offs
		g.colors = cs
		return g

	## A one-off burst into the world: dust thrown out flat along the ground, or sparks and
	## shards of crystal flung up that tumble and fall back under their weight.
	func _burst(at: Vector3, cols: Array, n: int, speed: float, grav: float, life: float, size: float, flat: bool, shards := false) -> void:
		if world == null or not is_instance_valid(world):
			return
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.explosiveness = 0.95
		p.amount = n
		p.lifetime = life
		p.local_coords = false
		if shards:
			if chunk_mesh == null:
				chunk_mesh = BoxMesh.new()
				chunk_mesh.size = Vector3(0.09, 0.16, 0.06)
				var m := StandardMaterial3D.new()
				m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				m.vertex_color_use_as_albedo = true
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				chunk_mesh.material = m
			p.mesh = chunk_mesh
			p.angular_velocity_min = -720.0
			p.angular_velocity_max = 720.0
			p.angle_min = 0.0
			p.angle_max = 360.0
		else:
			p.mesh = Fx._quad(size, Color.WHITE)
		if flat:                                   # out along the ground, every way
			p.direction = Vector3(1.0, 0.0, 0.0)
			p.spread = 180.0
			p.flatness = 1.0
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
			p.emission_ring_axis = Vector3.UP
			p.emission_ring_radius = 0.9
			p.emission_ring_inner_radius = 0.5
			p.emission_ring_height = 0.05
			p.damping_min = speed * 0.9
			p.damping_max = speed * 1.3
		else:
			p.direction = Vector3.UP
			p.spread = 75.0
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 0.5
		p.initial_velocity_min = speed * 0.5
		p.initial_velocity_max = speed
		p.gravity = Vector3(0.0, -grav, 0.0)
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.5
		p.color_ramp = _ramp(cols)
		world.add_child(p)
		p.global_position = at
		p.emitting = true
		var tw := p.create_tween()
		tw.tween_interval(life + 0.1)
		tw.tween_callback(p.queue_free)            # (gone the moment it's done: no trace)

	# --- the marks on the ground: two glowing tracks behind it as it shoots away, and a burnt ring
	# of cracks where it lifts off and where it lands - violet-hot at first, cooling to a dark
	# scorch, then gone

	func _scar_root() -> Node3D:
		if scar != null and is_instance_valid(scar):
			return scar
		if world == null or not is_instance_valid(world):
			return null
		if scar_shader == null:
			scar_shader = Shader.new()
			scar_shader.code = SCAR_SHADER
		scar = Node3D.new()
		world.add_child(scar)
		var tw := scar.create_tween()            # hot, cooling, then fading away
		var first := true
		for r: float in [0.0, 1.0]:
			var m := ShaderMaterial.new()
			m.shader = scar_shader
			m.set_shader_parameter("ring", r)
			m.set_shader_parameter("heat", 1.0)
			m.set_shader_parameter("fade", 1.0)
			if r > 0.5:
				ring_mat = m
			else:
				scar_mat = m
			if not first:
				tw.parallel()
			tw.tween_property(m, "shader_parameter/heat", 0.0, 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			first = false
		tw.tween_interval(10.0)
		tw.tween_property(scar_mat, "shader_parameter/fade", 0.0, 6.0)
		tw.parallel().tween_property(ring_mat, "shader_parameter/fade", 0.0, 6.0)
		tw.tween_callback(scar.queue_free)
		return scar

	func _ground(p: Vector3) -> Vector3:
		return Vector3(p.x, who.world.height_at(p) + 0.025, p.z)

	## A flat mark on the ground: a ring of cracks (`ring`), or a stretch of track.
	func _mark(at: Vector3, size: Vector2, yaw: float, ring: bool) -> void:
		var root := _scar_root()
		if root == null:
			return
		var q := QuadMesh.new()
		q.size = size
		q.orientation = PlaneMesh.FACE_Y
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = ring_mat if ring else scar_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		mi.global_position = _ground(at) + Vector3(0.0, 0.004 if ring else 0.0, 0.0)
		mi.rotation.y = yaw

	## While it shoots away: the two tracks under its hover pads, a stretch at a time.
	func _drop_tracks() -> void:
		var p := who.position
		if last_drop == Vector3.INF:
			last_drop = p
			return
		var step := Vector3(p.x - last_drop.x, 0.0, p.z - last_drop.z)
		var d := step.length()
		if d < 0.3:
			return
		var dir := step / d
		var right := Vector3(-dir.z, 0.0, dir.x)
		var mid := (p + last_drop) * 0.5
		var yaw := atan2(dir.x, dir.z)
		for side: float in [-0.62, 0.62]:
			_mark(mid + right * side, Vector2(0.2, d + 0.06), yaw, false)
		last_drop = p

	func _play(sound_name: String, pitch: float, db: float) -> void:
		if sound.is_valid():
			sound.call(sound_name, pitch, db)

	## The car at a point in its change: wheels folded flat (0-1), wings out, lifted, rings of
	## light, thrusters burning.
	func pose(delta: float, t: float, k_fold: float, k_wing: float, k_lift: float, k_ring: float, burning: bool,
			k_skin := 0.0, charging := false, folding := false) -> void:
		if not _attach():
			return
		cyber.set_shader_parameter("amount", k_skin)
		inflow.emitting = charging
		sparks.emitting = folding
		trail.emitting = burning and k_wing > 0.5
		var lift := k_lift * 0.75 + sin(t * 5.0) * 0.06 * k_lift
		root.position.y = lift
		if rider != null and is_instance_valid(rider):
			rider.position.y = rider_y + lift
		for pair in wheel_base:                    # the wheels fold up flat, out from the body: hover pads
			var w: Node3D = pair[0]
			if not is_instance_valid(w):
				continue
			var base: Vector3 = pair[1]
			var side := signf(base.x)
			w.position = base + Vector3(side * 0.12 * k_fold, 0.06 * k_fold, 0.0)
			if k_fold > 0.0:
				w.rotation = Vector3(w.rotation.x * (1.0 - k_fold), 0.0, side * k_fold * PI * 0.5)
			else:
				w.rotation.z = 0.0
		var spin: Node3D = who.model.get("spin") as Node3D
		if spin != null and is_instance_valid(spin):   # the shard rises, swells and spins fast
			spin.position = spin_base + Vector3(0.0, 0.45 * k_wing, 0.0)
			spin.scale = Vector3.ONE * (1.0 + 0.8 * k_wing)
			spin.rotation.y += delta * 18.0 * k_wing
		for i in range(wings.size()):
			var piv: Node3D = wings[i]
			var side := -1.0 if i == 0 else 1.0
			piv.visible = k_wing > 0.01
			piv.scale = Vector3(maxf(k_wing, 0.01), 1.0, maxf(k_wing, 0.01))
			piv.rotation = Vector3(0.0, side * (1.0 - k_wing) * 1.2, side * -0.12 * k_wing)   # (swept back, then out)
		for jet in jets:
			var j: Node3D = jet
			j.visible = k_wing > 0.05
			j.scale = Vector3.ONE * maxf(k_wing, 0.01)
			var fire := j.get_child(1) as CPUParticles3D
			if fire != null:
				fire.emitting = k_wing > 0.5
				fire.scale = Vector3.ONE * (1.8 if burning else 1.0)
		rings.visible = k_ring > 0.01
		for i in range(rings.get_child_count()):   # rings of light whirling round it
			var ring := rings.get_child(i) as Node3D
			var r := (1.25 - 0.18 * i) * (0.6 + 0.4 * k_ring)
			ring.scale = Vector3.ONE * r * k_ring
			ring.position = Vector3(0.0, 0.25 + 0.3 * i + 0.1 * sin(t * 4.0 + i), 0.0)
			ring.rotation = Vector3(0.25 * sin(t * 3.0 + i * 2.0), t * (4.0 + i * 1.5) * (1.0 if i % 2 == 0 else -1.0), 0.2 * cos(t * 2.5 + i))

	## The change at time t of the way out (t up to TF_CROSS).
	func pose_out(delta: float, t: float) -> void:
		var k_ring := smoothstep(0.9, 1.5, t) * (1.0 - smoothstep(TF_CROSS - 0.15, TF_CROSS, t) * 0.5)
		pose(delta, t, smoothstep(0.1, 0.7, t), smoothstep(0.45, 1.15, t), smoothstep(0.6, 1.4, t), k_ring, t >= TF_RISE,
			smoothstep(0.0, 0.9, t), t > 0.6 and t < TF_CROSS - 0.1, t > 0.1 and t < 0.75)
		var prev := last_t
		last_t = t
		if root == null:
			return
		var at := who.position
		if prev < 0.0:                             # it starts: the servos whine, plates shift
			_play("car_servo", 1.0, -2.0)
			_burst(at + Vector3(0.0, 0.5, 0.0), [Color(0.3, 0.95, 1.0, 1.0), Color(0.85, 0.45, 1.0, 0.0)], 24, 3.0, 0.0, 0.5, 0.1, false)
		if prev < 0.6 and t >= 0.6:                # wheels locked flat: it charges
			_play("car_charge", 1.0, -3.0)
		if prev < 0.75 and t >= 0.75:              # lift-off: a burnt ring of cracks left under it
			_mark(at, Vector2(2.6, 2.6), randf() * TAU, true)
		if t >= TF_RISE:
			_drop_tracks()                         # (and two glowing tracks as it shoots away)
		if prev < 0.75 and t >= 0.75:              # lift-off: dust blown out flat all round
			_burst(at + Vector3(0.0, 0.35, 0.0), [Color(0.6, 0.52, 0.42, 0.7), Color(0.5, 0.42, 0.55, 0.25), Color(0.4, 0.35, 0.45, 0.0)],
				30, 6.0, -1.5, 0.6, 0.35, true)   # (rising as it spreads, gone in a moment: nothing left on the ground)
		if prev < TF_RISE and t >= TF_RISE:        # the thrusters fire: away
			_play("car_jet", 1.0, -1.0)
			_burst(at + Vector3(0.0, 0.6, 0.0) - who.basis.z * -1.2, [Color(1.0, 1.0, 1.0, 1.0), Color(0.85, 0.45, 1.0, 0.8), Color(0.3, 0.95, 1.0, 0.0)],
				30, 5.0, 0.0, 0.5, 0.25, false)
		if prev < TF_CROSS - 0.12 and t >= TF_CROSS - 0.12:   # through: crystal shards and sparks fly everywhere
			_play("car_warp", 1.0, 0.0)
			_mark(at, Vector2(3.4, 3.4), randf() * TAU, true)  # (the rift's scar where it went through)
			_burst(at + Vector3(0.0, 0.8, 0.0), [Color(0.95, 0.75, 1.0, 1.0), Color(0.3, 0.95, 1.0, 1.0), Color(0.5, 0.3, 0.9, 0.0)],
				30, 7.0, 9.8, 0.7, 0.1, false, true)
			_burst(at + Vector3(0.0, 0.8, 0.0), [Color(1.0, 1.0, 1.0, 1.0), Color(0.85, 0.45, 1.0, 0.8), Color(0.3, 0.95, 1.0, 0.0)],
				50, 9.0, 4.0, 0.6, 0.16, false)

	## The change back, k from 0 (just through) to 1 (a plain car).
	func pose_back(delta: float, t: float, k: float) -> void:
		pose(delta, t, 1.0 - smoothstep(0.55, 1.0, k), 1.0 - smoothstep(0.3, 0.85, k), 1.0 - smoothstep(0.1, 0.7, k),
			1.0 - smoothstep(0.0, 0.35, k), k < 0.4, 1.0 - smoothstep(0.45, 1.0, k), false, k > 0.55 and k < 0.9)
		var prev := last_k
		last_k = k
		if root == null:
			return
		var at := who.position
		if prev < 0.0:                             # out the other side in a spray of light
			_burst(at + Vector3(0.0, 0.8, 0.0), [Color(1.0, 1.0, 1.0, 1.0), Color(0.3, 0.95, 1.0, 0.8), Color(0.85, 0.45, 1.0, 0.0)],
				50, 8.0, 3.0, 0.6, 0.16, false)
			_burst(at + Vector3(0.0, 0.8, 0.0), [Color(0.95, 0.75, 1.0, 1.0), Color(0.5, 0.3, 0.9, 0.0)], 18, 5.0, 9.8, 0.6, 0.1, false, true)
		if prev < 0.4 and k >= 0.4:                # folding back up: the servos again, lower
			_play("car_servo", 0.85, -3.0)
		if prev < 0.7 and k >= 0.7:                # down on its wheels: a hiss, a clunk, dust
			_play("car_land", 1.0, -2.0)
			scar = null                            # (a fresh set of marks on this side)
			_mark(at, Vector2(2.4, 2.4), randf() * TAU, true)
			_burst(at + Vector3(0.0, 0.35, 0.0), [Color(0.6, 0.52, 0.42, 0.7), Color(0.4, 0.35, 0.45, 0.0)], 24, 5.0, -1.5, 0.55, 0.3, true)

	## Back to a plain car: the new parts off, the rest as it was.
	func clear() -> void:
		for pair in swapped:
			if is_instance_valid(pair[0]):
				(pair[0] as MeshInstance3D).material_override = pair[1]
		swapped.clear()
		for p in [inflow, sparks, trail]:
			if p != null and is_instance_valid(p):
				(p as Node).queue_free()
		inflow = null
		sparks = null
		trail = null
		last_t = -1.0
		last_k = -1.0
		last_drop = Vector3.INF
		scar = null                                # (the marks stay, fading on their own)
		if root != null and is_instance_valid(root):
			root.position.y = 0.0
			for n in wings + jets:
				if is_instance_valid(n):
					(n as Node).queue_free()
			if rings != null and is_instance_valid(rings):
				rings.queue_free()
			if rider != null and is_instance_valid(rider):
				rider.position.y = rider_y
			for pair in wheel_base:
				var w: Node3D = pair[0]
				if is_instance_valid(w):
					w.position = pair[1]
					w.rotation.z = 0.0
			if who != null and is_instance_valid(who):
				var spin: Node3D = who.model.get("spin") as Node3D
				if spin != null and is_instance_valid(spin):
					spin.position = spin_base
					spin.scale = Vector3.ONE
		root = null
		rider = null
		wings.clear()
		jets.clear()
		rings = null
		wheel_base.clear()


var _changes: Array = []                       # every car change made, until it's put away
var _sweep_t := 0.0


## Every two seconds: any car change no longer in use (its jump or trip ended some other way) is
## put away - its wings, thrusters, rings and particles off - so nothing is ever left behind.
func _sweep_changes(delta: float) -> void:
	_sweep_t -= delta
	if _sweep_t > 0.0:
		return
	_sweep_t = 2.0
	var live: Array = []
	if _change != null and _jump_t >= 0.0:
		live.append(_change)
	for trip: Dictionary in _trips:
		if trip.get("change") != null:
			live.append(trip["change"])
	for c in _changes.duplicate():
		if not live.has(c):
			(c as CarChange).clear()
			_changes.erase(c)
	if _change != null and not live.has(_change):
		_change = null


func _new_change(who: Entity) -> CarChange:
	if _ring_meshes.is_empty():
		_new_portal().queue_free()                 # (makes the ring meshes)
	var snd := func(sound_name: String, pitch: float, db: float) -> void:
		if who == game.hero:
			_sound(sound_name, pitch, db)
		elif is_instance_valid(who):
			game.sound(sound_name, who.position, pitch, db - 4.0)
	var change := CarChange.new(who, _ring_meshes, snd, game)
	_changes.append(change)
	return change


## The marks the Riftrunner leaves on the ground: a track (glowing in the middle, soft at its
## edges, flickering with energy) or a ring of cracks (a burnt circle with jagged cracks running
## out of it). `heat` cools them from violet-hot to a dark scorch; `fade` takes them away.
const SCAR_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform float heat = 1.0;
uniform float fade = 1.0;
uniform float ring = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float a;
	float glow;
	if (ring > 0.5) {
		float r = length(uv);
		float ang = atan(uv.y, uv.x);
		float band = smoothstep(0.62, 0.72, r) * (1.0 - smoothstep(0.82, 0.95, r));
		float cracks = pow(abs(sin(ang * 7.0 + sin(ang * 3.0) * 1.5)), 40.0) * (1.0 - smoothstep(0.3, 1.0, r)) * smoothstep(0.15, 0.3, r);
		float inner = (1.0 - smoothstep(0.0, 0.65, r)) * 0.35;
		a = max(max(band, cracks), inner);
		glow = max(band, cracks);
	} else {
		float across = 1.0 - smoothstep(0.35, 1.0, abs(uv.x));
		float flick = 0.75 + 0.25 * sin(uv.y * 9.0 + TIME * 12.0);
		a = across;
		glow = across * flick * (1.0 - smoothstep(0.0, 0.6, abs(uv.x)));
	}
	vec3 hot = mix(vec3(0.95, 0.45, 1.0), vec3(0.3, 0.95, 1.0), 0.5 + 0.5 * sin(TIME * 2.0 + UV.y * 4.0));
	vec3 scorch = vec3(0.06, 0.04, 0.08);
	ALBEDO = mix(scorch, hot * (1.0 + glow), heat * (0.4 + 0.6 * glow));
	ALPHA = a * fade * mix(0.55, 0.95, heat);
}
"""


## The cyber skin the Riftrunner wears while it changes: a wipe of white light runs from bonnet to
## tail, and behind it the paint turns to dark chrome laced with a glowing grid of circuit lines,
## pulses of violet and teal running along them.
const CYBER_SHADER := """
shader_type spatial;
uniform float amount = 0.0;
uniform vec4 tint : source_color = vec4(1.0);
varying vec3 p;
void vertex() {
	p = VERTEX;
}
void fragment() {
	vec3 base = COLOR.rgb * tint.rgb;
	float edge = mix(-1.5, 1.7, amount);
	float on = step(p.z, edge);
	float band = (1.0 - smoothstep(0.0, 0.12, abs(p.z - edge))) * step(0.001, amount) * step(amount, 0.999);
	vec3 g = abs(fract(p * 6.0) - 0.5);
	float line = 1.0 - smoothstep(0.0, 0.06, min(min(g.x, g.y), g.z));
	float pulse = 0.5 + 0.5 * sin(p.z * 14.0 - TIME * 9.0 + p.y * 6.0);
	float lum = dot(base, vec3(0.3, 0.59, 0.11));
	vec3 skin = mix(vec3(0.03, 0.02, 0.07), vec3(0.16, 0.12, 0.26), lum);
	vec3 neon = mix(vec3(0.3, 0.95, 1.0), vec3(0.95, 0.35, 1.0), 0.5 + 0.5 * sin(p.x * 5.0 + TIME * 2.0));
	ALBEDO = mix(base, skin, on);
	METALLIC = 0.8 * on;
	ROUGHNESS = mix(0.9, 0.25, on);
	EMISSION = neon * line * (0.5 + 1.5 * pulse) * on * 1.4 + vec3(1.0, 0.9, 1.0) * band * 3.0;
}
"""


func _tf_clear() -> void:
	if _change != null:
		_change.clear()
	_change = null
	_dashing = false


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
		game.score.sting("rift")
		var vs: Vector2 = game.get_viewport().get_visible_rect().size
		var word := Title3D.make_flying("THE SHARDVEIL" if on else "HOME", minf(vs.x * 0.75, 1100.0),
			Title3D.ICE if on else Title3D.GOLD, vs)
		_layer.add_child(word)
		word.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if on:
			game.log_event("The Riftrunner tears through into the Shardveil, the land in another dimension. Gold found here counts double.")
		else:
			game.log_event("The Riftrunner tears back through. Home again.")


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
var _trips: Array = []                         # each: {"who", "phase" (in, away, settle), "t", "change", ...}
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
	var at := who.position + way * 9.0
	at.y = game.world.height_at(at)
	who.target = null
	who.path.clear()
	_trips.append({"who": who, "phase": "in", "t": 0.0, "change": _new_change(who), "at": at, "dir": way, "back": 0.0,
		"spark": 0.0, "dash": false})


func _trip_step(trip: Dictionary, delta: float) -> void:
	var who: Entity = trip["who"]
	var change: CarChange = trip.get("change") as CarChange
	trip["t"] = float(trip["t"]) + delta
	var t := float(trip["t"])
	match String(trip["phase"]):
		"in":                                      # the car changes, lifts off and shoots away
			if who.dead or who.mounted_on == null or who.target != null:
				if change != null:
					change.clear()                 # (something came up: just a car again)
				_trips.erase(trip)
				return
			if t < TF_RISE:
				who.path.clear()
			elif not bool(trip["dash"]) or who.path.is_empty():
				trip["dash"] = true
				who.go_to((trip["at"] as Vector3) + (trip["dir"] as Vector3) * 6.0)
			change.pose_out(delta, t)
			trip["spark"] = float(trip["spark"]) - delta
			if float(trip["spark"]) <= 0.0:
				trip["spark"] = 0.15 if t > 0.9 else 0.3
				Fx.sparkle(game, who.position + Vector3(randf_range(-1.0, 1.0), 1.0, randf_range(-1.0, 1.0)),
					VIOLET if randf() < 0.5 else TEAL, 6)
			if t >= TF_CROSS:
				var at := who.position + Vector3(0.0, 1.2, 0.0)
				Fx.sparkle(game, at, VIOLET, 30)   # gone in a burst of light
				Fx.sparkle(game, at, TEAL, 20)
				change.clear()
				_away(who)
				trip["change"] = null
				trip["phase"] = "away"
				trip["t"] = 0.0
				trip["back"] = randf_range(45.0, 120.0)
		"away":                                    # in the Shardveil a while; then back
			if t >= float(trip["back"]):
				_trips.erase(trip)
				_back(who, true)
		"settle":                                  # back: settling down, folding up, onto its wheels
			var k := clampf(t / TF_SETTLE, 0.0, 1.0)
			if change != null:
				change.pose_back(delta, t, k)
			if k >= 1.0 or who.dead or who.mounted_on == null:
				if change != null:
					change.clear()
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
	var at := who.position + Vector3(0.0, 1.2, 0.0)
	Fx.sparkle(game, at, TEAL, 30)                 # out of a burst of light, wings out, still changed
	Fx.sparkle(game, at, VIOLET, 20)
	if who.mounted_on != null and who.mounted_on.is_vehicle:
		_trips.append({"who": who, "phase": "settle", "t": 0.0, "change": _new_change(who)})


## Everyone home at once, every ring gone (the experiment switched off, or a trailer starting).
func _end_trips() -> void:
	var trips := _trips.duplicate()
	_trips.clear()
	for trip: Dictionary in trips:
		var change: CarChange = trip.get("change") as CarChange
		if change != null:
			change.clear()
		if String(trip["phase"]) == "away":
			_back(trip["who"], false)


# --- the Shardveil's chaos (the "Shardveil chaos" experiment) ------------------------------------
# In the Shardveil it's every one for themselves. Round you (35 m), everyone has a gun - you,
# the adventurers, every monster (the orcs and skeletons in hand; the wolves, bears, spiders and
# other beasts strapped to their backs) and the pets too - and anyone fights anyone: the
# adventurers each other and the beasts, the beasts each other, everyone you; but the towns keep the peace
# and no blow is a crime. And meteors keep falling out of the violet sky, burning whoever they
# land near. Back home, everyone has their own weapons again.

const GUNS := ["veil_pistol", "rift_shotgun", "shard_rocket", "spike_gun", "arc_caster", "ember_launcher", "veil_pistol"]
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
		if e == null or e.dead or e.parked or e.is_vehicle:
			continue
		var d := e.position.distance_to(hero.position)
		if e.kind == Entity.Kind.NPC:              # the townsfolk: the look, but no gun
			if e.has_meta("veil_look") and d > CHAOS_RADIUS + 6.0:
				_undress(e)
			elif not e.has_meta("veil_look") and d <= CHAOS_RADIUS:
				e.set_meta("veil_look", true)
				e.refresh_look()
				_dressed.append(e)
			continue
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
	for e in _dressed.duplicate():
		_undress(e)
	_dressed.clear()


var _dressed: Array = []


func _undress(e: Entity) -> void:
	if e != null and is_instance_valid(e) and e.has_meta("veil_look"):
		e.remove_meta("veil_look")
		e.refresh_look()
	_dressed.erase(e)


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
const TURRET_EVERY := {"pistol": 0.9, "shotgun": 1.6, "rocket": 2.6, "spike": 0.6, "arc": 0.8, "grenade": 2.2}
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
	if _streak == 5:
		_drop_pickup(victim.position)                  # (a rampage leaves a shard behind)
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
	_hound_t = randf_range(30.0, 40.0)
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
	_gauntlet_step(delta)
	_hound_t -= delta
	if _hound_t <= 0.0:
		_hound_t = randf_range(40.0, 60.0)
		_hound_pack()
	_bubble_step()
	_surge_step(delta)
	_champion_step(delta)
	_ram_step(delta)


var _hound_t := 35.0
var _gauntlet: Array = []                      # rift beacons still to capture: [{"node", "at"}]
var _gauntlet_t := 90.0
var _gauntlet_left := 0.0


## The Veil Gauntlet: three rift beacons light up across the land; drive or walk through all three
## within 40 s for 300 gold and a nova shard. Miss one and the beacons fade.
func _gauntlet_step(delta: float) -> void:
	var hero: Entity = game.hero
	if _gauntlet.is_empty():
		_gauntlet_t -= delta
		if _gauntlet_t <= 0.0:
			_gauntlet_t = randf_range(90.0, 120.0)
			_start_gauntlet()
		return
	_gauntlet_left -= delta
	for b: Dictionary in _gauntlet.duplicate():
		var n: Node3D = b["node"]
		n.rotation.y += delta * 3.0
		if hero.position.distance_to(b["at"]) < 2.5:
			n.queue_free()
			_gauntlet.erase(b)
			Fx.sparkle(game, b["at"] + Vector3(0.0, 1.0, 0.0), VIOLET, 20)
			_sound("gain", 1.0 + 0.1 * float(3 - _gauntlet.size()), -4.0)
	if _gauntlet.is_empty():
		hero._earn(300)
		_drop_pickup(hero.position + Vector3(1.5, 0.0, 0.0))
		_announce("GAUNTLET CLEARED", Title3D.GOLD)
		game.log_event("You capture every rift beacon of the Veil Gauntlet: 300 gold and a shard.")
	elif _gauntlet_left <= 0.0:
		for b: Dictionary in _gauntlet:
			(b["node"] as Node3D).queue_free()
		_gauntlet.clear()
		game.log_event("The Veil Gauntlet fades: too slow.")


func _start_gauntlet() -> void:
	var hero: Entity = game.hero
	for k in range(3):
		var at := _veil_spot(14.0 + 4.0 * k, 22.0 + 4.0 * k)
		if at == Vector3.INF:
			continue
		var n := Node3D.new()
		game.add_child(n)
		n.global_position = at
		var ring := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 1.6
		t.outer_radius = 1.9
		t.rings = 24
		t.ring_segments = 6
		ring.mesh = t
		ring.material_override = Art.glow_mat(TEAL)
		ring.rotation.x = PI * 0.5
		ring.position.y = 1.4
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(ring)
		var glow := Fx.cast_glow(VIOLET)
		glow.scale = Vector3.ONE * 2.0
		n.add_child(glow)
		glow.emitting = true
		_gauntlet.append({"node": n, "at": at})
	if _gauntlet.is_empty():
		return
	_gauntlet_left = 40.0
	_announce("VEIL GAUNTLET", Title3D.ICE)
	game.log_event("The Veil Gauntlet: drive through all three rift beacons within 40 seconds.")


## A Rift Hound pack: four fast violet wolves tear out of the ground at the hero from every side,
## and they go for whoever is nearest (not the one who raised them), then fade when they fall.
func _hound_pack() -> void:
	var hero: Entity = game.hero
	if hero.dead:
		return
	for k in range(4):
		var ang := TAU * float(k) / 4.0 + randf() * 0.4
		var at := hero.position + Vector3(cos(ang), 0.0, sin(ang)) * randf_range(10.0, 13.0)
		at.y = game.world.height_at(at)
		var cfg: Dictionary = Bestiary.WOLF.duplicate(true)
		cfg["move"] = 6.5
		cfg["aggro"] = 30.0
		cfg["leash"] = 50
		cfg["passive"] = false
		cfg["scale"] = 1.0
		cfg["str"] = roundi(float(cfg.get("str", 28)) * _veilborn_toughness())
		var h: Entity = game.pool_spawn("Rift Hound", cfg, Color(0.6, 0.3, 1.0), at)
		_mark_veilborn(h, 1.0)
		h.target = hero
		_veilborn.append(h)
	_announce("RIFT HOUNDS", Title3D.ICE)
	_sound("howl" if false else "wail", 1.4, -4.0)
	game.log_event("A pack of Rift Hounds tears out of the ground!")


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
