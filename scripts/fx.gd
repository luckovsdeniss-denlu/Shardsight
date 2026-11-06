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
	p.amount = amount
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
	p.amount = amount
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
