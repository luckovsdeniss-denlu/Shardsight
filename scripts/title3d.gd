class_name Title3D
extends SubViewportContainer
## The game's name in 3D: raised gold letters with real depth, lit from above, a bright light
## sweeping across them, a soft gold glow, sparks rising round them and a slow sway that shows the
## sides of the letters. Drawn in its own little 3D world (its own camera, lights and glow), so it
## sits in the interface like a picture - over the title card, over the movie's dimming - and the
## time of day or the weather never changes how it looks.

const GOLD := Color(0.98, 0.76, 0.3)
var _text: MeshInstance3D
var _shine: OmniLight3D
var _t := 0.0
var _colour := GOLD
var _fly := false                      # a flying word: swoops in, hangs, flies past and is gone
const FLY_LIFE := 2.7
const ICE := Color(0.7, 0.88, 1.0)


## A flying word for the trailer: in `colour`, it swoops in from the distance spinning, hangs a
## moment swaying in the light, then rushes past the camera and is gone (about 2.7 seconds).
## It takes the whole screen (`screen`), so nothing of its flight is cut off at an edge: the
## letters come out the size a `width`-wide title would have, a little above the middle.
static func make_flying(text: String, width: float, colour := GOLD, screen := Vector2.ZERO) -> Title3D:
	var t := Title3D.new()
	t._colour = colour
	t._fly = true
	if screen.x > 0.0:
		t._full = screen
	t._build(text, width, 0.4)
	return t


var _full := Vector2.ZERO              # a flying word's frame: the whole screen (no edges to hit)
var _lift := 0.0                       # how far up from the middle the word flies (metres)


## A title `width` pixels wide (the height follows), fading and growing in over `intro` seconds.
static func make(text: String, width: float, intro := 1.2) -> Title3D:
	var t := Title3D.new()
	t._colour = GOLD
	t._build(text, width, intro)
	return t


func _build(text: String, width: float, intro: float) -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(width, width * 0.3) if _full == Vector2.ZERO else _full
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.4, 0.35)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true                           # the gold glows
	for lv in range(7):
		env.set_glow_level(lv, lv in [1, 2, 3])
	env.glow_intensity = 1.1
	env.glow_bloom = 0.08
	env.glow_hdr_threshold = 0.9
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 28.0
	if _full != Vector2.ZERO:
		# the same size of letters as in a `width`-wide frame, but the view as big as the screen
		var half := tan(deg_to_rad(14.0)) * _full.y / (width * 0.3)
		cam.fov = rad_to_deg(2.0 * atan(half))
		_lift = 4.2 * half * 0.3                       # a little above the middle
	cam.position = Vector3(0, 0, 4.2)
	vp.add_child(cam)
	# the letters: extruded, in polished gold (no emboldening: it broke the A when made solid)
	var font := FontVariation.new()
	font.base_font = ThemeDB.fallback_font
	font.spacing_glyph = 8
	var tm := TextMesh.new()
	tm.text = text
	tm.font = font
	tm.font_size = 96
	tm.pixel_size = minf(0.0068, 6.4 / (maxf(float(text.length()), 1.0) * 67.5))   # big; a long line still fits
	tm.depth = 0.22
	tm.curve_step = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _colour
	mat.metallic = 0.85
	mat.roughness = 0.28
	mat.emission_enabled = true
	mat.emission = _colour.lerp(Color(1.0, 0.62, 0.2), 0.5) if _colour == GOLD else _colour.darkened(0.2)
	mat.emission_energy_multiplier = 0.5
	tm.material = mat
	_text = MeshInstance3D.new()
	_text.mesh = tm
	vp.add_child(_text)
	# the light: a warm key from above, a cool rim from behind, and the sweep
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35), deg_to_rad(-25), 0)
	key.light_energy = 1.6
	key.light_color = Color(1.0, 0.92, 0.8)
	vp.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(0, 0.6, -1.2)
	rim.light_color = Color(0.55, 0.7, 1.0)
	rim.light_energy = 2.0
	rim.omni_range = 4.0
	vp.add_child(rim)
	_shine = OmniLight3D.new()
	_shine.light_color = Color(1.0, 0.95, 0.85)
	_shine.light_energy = 6.0
	_shine.omni_range = 1.1
	vp.add_child(_shine)
	# sparks rising round the letters
	var sparks := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.025)
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.vertex_color_use_as_albedo = true
	smat.albedo_color = Color(1.6, 1.2, 0.5)
	quad.material = smat
	sparks.mesh = quad
	sparks.amount = 40
	sparks.lifetime = 2.2
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sparks.emission_box_extents = Vector3(1.9, 0.15, 0.3)
	sparks.position = Vector3(0, -0.35 + _lift, 0)
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 20.0
	sparks.gravity = Vector3.ZERO
	sparks.initial_velocity_min = 0.25
	sparks.initial_velocity_max = 0.6
	sparks.scale_amount_min = 0.6
	sparks.scale_amount_max = 1.6
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.45, 0.0))
	ramp.add_point(0.2, Color(1.0, 0.85, 0.45, 1.0))
	ramp.set_color(ramp.get_point_count() - 1, Color(1.0, 0.6, 0.2, 0.0))
	sparks.color_ramp = ramp
	vp.add_child(sparks)
	# in: grow and fade up
	modulate.a = 0.0
	if _fly:
		return                                         # (a flying word moves itself)
	_text.scale = Vector3.ONE * 0.7
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, intro * 0.8)
	tw.tween_property(_text, "scale", Vector3.ONE, intro).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_t += delta
	if _fly:
		_fly_step()
		return
	# a slow sway: the sides of the letters catch the light
	_text.rotation = Vector3(sin(_t * 0.45) * 0.06, sin(_t * 0.6) * 0.22, 0.0)
	# the sweep: a bright light glides across the front every three and a half seconds
	var k := fmod(_t, 3.5) / 3.5
	_shine.position = Vector3(lerpf(-2.6, 2.6, k), 0.15, 0.55)
	_shine.visible = k < 0.75


## The flight: in from far off and to the side, turning to face us; a moment's hang; then past us.
func _fly_step() -> void:
	var k := _t / FLY_LIFE
	if k >= 1.0:
		queue_free()
		return
	var pos: Vector3
	var rot: Vector3
	if k < 0.22:                                       # swooping in
		var u := k / 0.22
		var e := 1.0 - pow(1.0 - u, 3.0)
		pos = Vector3(lerpf(2.5, 0.0, e), lerpf(-0.6, 0.0, e), lerpf(-9.0, 0.0, e))
		rot = Vector3(lerpf(0.5, 0.0, e), lerpf(-1.4, 0.0, e), lerpf(0.25, 0.0, e))
		modulate.a = minf(u * 2.0, 1.0)
	elif k < 0.8:                                      # hanging, swaying in the light
		var h := (k - 0.22) / 0.58
		pos = Vector3(0.0, sin(h * PI) * 0.06, h * 0.35)
		rot = Vector3(sin(_t * 1.3) * 0.05, sin(_t * 1.1) * 0.16, 0.0)
		modulate.a = 1.0
	else:                                              # rushing past the camera
		var u := (k - 0.8) / 0.2
		var e := u * u
		pos = Vector3(lerpf(0.0, -1.2, e), lerpf(0.0, 0.3, e), lerpf(0.35, 3.6, e))
		rot = Vector3(0.0, lerpf(0.0, 0.7, e), 0.0)
		modulate.a = 1.0 - u
	_text.position = pos + Vector3(0.0, _lift, 0.0)
	_text.rotation = rot
	_text.scale = Vector3.ONE
	var s := fmod(_t, 1.6) / 1.6                       # the light sweeps across faster
	_shine.position = Vector3(lerpf(-2.6, 2.6, s), 0.15 + _lift, pos.z + 0.55)
	_shine.visible = true


## Fades out, then goes.
func fade_out(secs := 0.6) -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, secs)
	tw.tween_callback(queue_free)
