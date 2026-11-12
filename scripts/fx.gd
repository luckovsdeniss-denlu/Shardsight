class_name Fx
## Fire and other particle effects, built in code. CPU particles (they work everywhere, phones
## included) with a glowing, additive material, so overlapping flames brighten like real fire.

static var _mats := {}


## A glowing, additive particle material in `c` (faces the camera).
static func glow(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.vertex_color_use_as_albedo = true
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true              # so particles can grow and shrink
		m.albedo_color = c
		_mats[key] = m
	return _mats[key]


## The colours of a flame over a particle's life: white-yellow core to orange to dark red smoke.
static func _fire_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color(1.0, 0.95, 0.6, 1.0), Color(1.0, 0.6, 0.15, 0.9),
		Color(0.85, 0.2, 0.05, 0.6), Color(0.2, 0.05, 0.02, 0.0)])
	return g


static func _quad(size: float, c: Color) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	q.material = glow(c)
	return q


## A steady flame (campfires, braziers, the forge, fire fields): `width` across, licking up.
static func flame(width: float, amount := 24, height := 1.0) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(int(amount * 0.7), 4)          # (lighter on the phone, much the same to the eye)
	p.lifetime = 0.7 * height
	p.mesh = _quad(0.28 * maxf(width, 0.6), Color.WHITE)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = width * 0.45
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0.0, 1.5 * height, 0.0)
	p.initial_velocity_min = 0.4 * height
	p.initial_velocity_max = 1.1 * height
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.5))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 0.1))
	p.scale_amount_curve = curve
	p.color_ramp = _fire_ramp()
	return p


## Sparks drifting up (fire elementals, a burst's afterglow).
static func embers(radius: float, amount := 14) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = maxi(int(amount * 0.7), 4)          # (lighter on the phone, much the same to the eye)
	p.lifetime = 1.2
	p.mesh = _quad(0.08, Color.WHITE)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = radius
	p.direction = Vector3.UP
	p.spread = 35.0
	p.gravity = Vector3(0.0, 0.8, 0.0)
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 1.2
	p.color_ramp = _fire_ramp()
	return p


## A one-shot fiery blast at `at` that frees itself.
static func burst(parent: Node, at: Vector3, size := 1.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = int(28 * size)
	p.lifetime = 0.6
	p.mesh = _quad(0.45 * size, Color.WHITE)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.2 * size
	p.direction = Vector3.UP
	p.spread = 180.0
	p.gravity = Vector3(0.0, 1.0, 0.0)
	p.initial_velocity_min = 1.5 * size
	p.initial_velocity_max = 3.5 * size
	p.damping_min = 3.0
	p.damping_max = 5.0
	p.color_ramp = _fire_ramp()
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 3.0 * size
	light.omni_range = 4.0 * size
	p.add_child(light)
	var tw := p.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.5)
	tw.tween_interval(0.4)
	tw.tween_callback(p.queue_free)


## A fireball flying from `from` to `to` with a flame trail, bursting on arrival.
static func fireball(parent: Node, from: Vector3, to: Vector3, size := 1.0, seconds := 0.35) -> void:
	var ball := Node3D.new()
	parent.add_child(ball)
	ball.global_position = from
	var trail := flame(0.25 * size, 30, 0.6)
	trail.local_coords = false
	trail.gravity = Vector3.ZERO
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.3
	trail.lifetime = 0.35
	ball.add_child(trail)
	var core := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.16 * size
	s.height = 0.32 * size
	core.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.4)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.55, 0.15)
	m.emission_energy_multiplier = 3.0
	core.material_override = m
	ball.add_child(core)
	var tw := ball.create_tween()
	tw.tween_property(ball, "global_position", to, seconds)
	tw.tween_callback(func() -> void:
		burst(parent, to, size)
		trail.emitting = false
		core.visible = false)
	tw.tween_interval(0.4)
	tw.tween_callback(ball.queue_free)


## A pillar of fire rising out of the ground (Flamestrike).
static func pillar(parent: Node, at: Vector3) -> void:
	var p := flame(0.6, 60, 2.6)
	p.one_shot = true
	p.explosiveness = 0.6
	p.lifetime = 0.9
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	burst(parent, at + Vector3(0, 0.3, 0), 0.8)
	var tw := p.create_tween()
	tw.tween_interval(1.4)
	tw.tween_callback(p.queue_free)


## A meteor falling from the sky onto `at` (Meteor Swarm).
static func meteor(parent: Node, at: Vector3, delay: float) -> void:
	var t := parent.get_tree().create_timer(delay)
	t.timeout.connect(func() -> void:
		fireball(parent, at + Vector3(-2.5, 9.0, -1.5), at + Vector3(0, 0.3, 0), 1.3, 0.45))


# --- magic --------------------------------------------------------------------

## A colour that fades out over a particle's life.
static func _fade_ramp(c: Color) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 0.9).lerp(c, 0.4), c, Color(c.r, c.g, c.b, 0.0)])
	return g


## Motes of the spell's colour swirling up round a caster while the spell is spoken. The caller
## frees it when the cast ends.
static func cast_glow(c: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 16
	p.lifetime = 0.7
	p.mesh = _quad(0.12, Color.WHITE)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 0.55
	p.emission_ring_inner_radius = 0.4
	p.emission_ring_height = 0.1
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3(0.0, 0.6, 0.0)
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.3
	p.color_ramp = _fade_ramp(c)
	return p


## A one-shot burst of sparkles rising from `at` (heals, blessings, a bolt striking home).
static func sparkle(parent: Node, at: Vector3, c: Color, amount := 20) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.7
	p.amount = maxi(int(amount * 0.7), 4)          # (lighter on the phone, much the same to the eye)
	p.lifetime = 0.9
	p.mesh = _quad(0.14, Color.WHITE)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.45
	p.direction = Vector3.UP
	p.spread = 30.0
	p.gravity = Vector3(0.0, 0.5, 0.0)
	p.initial_velocity_min = 0.6
	p.initial_velocity_max = 1.6
	p.color_ramp = _fade_ramp(c)
	parent.add_child(p)
	p.global_position = at
	p.emitting = true
	var tw := p.create_tween()
	tw.tween_interval(1.3)
	tw.tween_callback(p.queue_free)


## A glowing orb in the spell's colour flying from `from` to `to` with a trail, sparkling on arrival
## (Magic Arrow, Harm, Mind Blast, Energy Bolt...).
static func orb(parent: Node, from: Vector3, to: Vector3, c: Color, size := 1.0, seconds := 0.3) -> void:
	var ball := Node3D.new()
	parent.add_child(ball)
	ball.global_position = from
	var trail := CPUParticles3D.new()
	trail.amount = 24
	trail.lifetime = 0.3
	trail.local_coords = false
	trail.mesh = _quad(0.18 * size, Color.WHITE)
	trail.gravity = Vector3.ZERO
	trail.initial_velocity_min = 0.0
	trail.initial_velocity_max = 0.2
	trail.color_ramp = _fade_ramp(c)
	ball.add_child(trail)
	var core := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.13 * size
	s.height = 0.26 * size
	core.mesh = s
	var m := StandardMaterial3D.new()
	m.albedo_color = c.lightened(0.4)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 3.0
	core.material_override = m
	ball.add_child(core)
	var tw := ball.create_tween()
	tw.tween_property(ball, "global_position", to, seconds)
	tw.tween_callback(func() -> void:
		sparkle(parent, to, c, 14)
		trail.emitting = false
		core.visible = false)
	tw.tween_interval(0.35)
	tw.tween_callback(ball.queue_free)


## A jagged bolt of lightning from the sky onto `at`, with a flash of light.
static func lightning(parent: Node, at: Vector3, c := Color(0.85, 0.9, 1.0)) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = Vector3.ZERO
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 4.0
	var pts: Array[Vector3] = []
	var top := at + Vector3(randf_range(-1.0, 1.0), 9.0, randf_range(-1.0, 1.0))
	for i in range(7):
		var t := float(i) / 6.0
		var jitter := Vector3(randf_range(-0.45, 0.45), 0.0, randf_range(-0.45, 0.45)) * (1.0 if i > 0 and i < 6 else 0.0)
		pts.append(top.lerp(at + Vector3(0.0, 0.2, 0.0), t) + jitter)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.07, 0.07, a.distance_to(b))
		seg.mesh = box
		seg.material_override = mat
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(seg)
		seg.look_at_from_position((a + b) / 2.0, b, Vector3.RIGHT)
	var light := OmniLight3D.new()
	light.light_color = c
	light.light_energy = 4.0
	light.omni_range = 7.0
	root.add_child(light)
	light.global_position = at + Vector3(0.0, 1.5, 0.0)
	sparkle(parent, at + Vector3(0.0, 0.3, 0.0), c, 16)
	var tw := root.create_tween()
	tw.tween_property(light, "light_energy", 0.0, 0.25)
	tw.tween_callback(root.queue_free)


# --- smoke ----------------------------------------------------------------------

static var _smoke_mat: StandardMaterial3D


## Grey smoke drifting up from a fire, spreading and fading (`amount` puffs at a time).
static func smoke(amount := 8, size := 1.0) -> CPUParticles3D:
	if _smoke_mat == null:
		_smoke_mat = StandardMaterial3D.new()
		_smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_smoke_mat.vertex_color_use_as_albedo = true
		_smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_smoke_mat.billboard_keep_scale = true
	var p := CPUParticles3D.new()
	p.amount = maxi(int(amount * 0.7), 4)          # (lighter on the phone, much the same to the eye)
	p.lifetime = 3.0
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4) * size
	q.material = _smoke_mat
	p.mesh = q
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.12 * size
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0.25, 0.35, 0.1)          # rising, and drifting with the wind
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.6
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(1.0, 1.6))
	p.scale_amount_curve = curve
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	g.colors = PackedColorArray([Color(0.35, 0.33, 0.32, 0.0), Color(0.4, 0.38, 0.36, 0.35), Color(0.55, 0.55, 0.55, 0.0)])
	p.color_ramp = g
	return p
