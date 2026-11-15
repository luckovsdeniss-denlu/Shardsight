class_name LoadingScreen
extends CanvasLayer
## The loading screen, drawn in code: a dark field of glowing hexagons with a pulse rolling out
## from the middle and a scan line sweeping down; at the centre the Shard spins inside rings of
## light; under it the name, a segmented progress bar with a bright leading edge, the step being
## loaded (typed out) and a column of system lines. Shown while Main builds the world, a step at
## a time; it fades away when done.

const BG_SHADER := """
shader_type canvas_item;
uniform float aspect = 1.78;
uniform float progress = 0.0;
uniform float ring_r = 0.18;
uniform float center_y = 0.5;         // where the circle's middle is (a fraction of the height)          // the glow ring's radius (screen heights): set to sit on the gold ring

vec2 hex_cell(vec2 p) {
	vec2 r = vec2(1.0, 1.7320508);
	vec2 h = r * 0.5;
	vec2 a = mod(p, r) - h;
	vec2 b = mod(p - h, r) - h;
	return dot(a, a) < dot(b, b) ? a : b;
}

float hex_dist(vec2 p) {
	p = abs(p);
	return max(dot(p, normalize(vec2(1.0, 1.7320508))), p.x);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	vec2 p = (uv - vec2(0.5, center_y)) * vec2(aspect, 1.0);   // the same middle as the rings and the Shard
	float r = length(p);
	// a deep blue field, lighter at the heart
	vec3 col = mix(vec3(0.03, 0.07, 0.14), vec3(0.005, 0.01, 0.03), smoothstep(0.0, 0.9, r));
	// the hexagons: thin lines, and a pulse rolling out from the middle
	vec2 hp = p * 14.0;
	vec2 gv = hex_cell(hp);
	vec2 id = hp - gv;
	float edge = 0.5 - hex_dist(gv);
	float line = smoothstep(0.045, 0.0, edge);
	float pulse = pow(0.5 + 0.5 * sin(r * 18.0 - TIME * 3.0), 6.0);
	float flick = step(0.985, hash(id + floor(TIME * 2.0)));      // a few cells light up now and then
	vec3 cyan = vec3(0.2, 0.75, 1.0);
	col += cyan * line * (0.08 + 0.35 * pulse) * (1.0 - smoothstep(0.3, 1.0, r));
	col += cyan * flick * smoothstep(0.25, 0.0, hex_dist(gv)) * 0.25;
	// a glow ring that grows with the loading
	float ring = smoothstep(0.012, 0.0, abs(r - (ring_r + progress * 0.008)));
	col += vec3(0.95, 0.75, 0.3) * ring * 0.25;
	// a scan line sweeping down, and the fine lines of a screen
	float scan = smoothstep(0.06, 0.0, abs(uv.y - fract(TIME * 0.25)));
	col += cyan * scan * 0.07;
	col *= 0.93 + 0.07 * sin(uv.y * 900.0);
	// dark corners
	col *= 1.0 - smoothstep(0.55, 1.1, length((uv - 0.5) * vec2(1.3, 1.0)));
	COLOR = vec4(col, 1.0);
}
"""

const STEPS_LOG := [
	"SHARD MATRIX ......... ONLINE",
	"TERRAIN LATTICE ...... SYNCED",
	"BESTIARY INDEX ....... LOADED",
	"SPELL CIRCLES ........ ARMED",
	"TOWNS & ROADS ........ MAPPED",
	"MEMORY OF THE HERO ... RESTORED",
	"THE WIDER WORLD ...... AWAKE",
]

var _root: Control
var _bg: ColorRect
var _bg_mat: ShaderMaterial
var _fg: Control
var _target := 0.0                 # where the bar is going
var _shown := 0.0                  # where it is (eased)
var _creep := 0.0                  # a slow drift past the target while a step runs
var _status := ""
var _typed := 0.0                  # characters of the status shown so far
var _log: Array[String] = []
var _t := 0.0
var _closing := false


func _init() -> void:
	layer = 100
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP     # nothing behind can be tapped meanwhile
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg = ColorRect.new()
	var sh := Shader.new()
	sh.code = BG_SHADER
	_bg_mat = ShaderMaterial.new()
	_bg_mat.shader = sh
	_bg.material = _bg_mat
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fg = Control.new()
	_fg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fg)
	_fg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fg.draw.connect(_draw_fg)
	_build_logo3d()


## The next step: the bar heads for `frac` (0..1) and `text` is typed out under it.
func step(frac: float, text: String) -> void:
	_target = clampf(frac, 0.0, 1.0)
	if text != _status:
		if _status != "" and _log.size() < STEPS_LOG.size():
			_log.append(String(STEPS_LOG[_log.size()]))
		_status = text
		_typed = 0.0


## Done: the bar fills, then the screen fades out and frees itself.
func finish() -> void:
	if _closing:
		return
	_closing = true
	_target = 1.0
	while _log.size() < STEPS_LOG.size():
		_log.append(String(STEPS_LOG[_log.size()]))
	_status = "READY"
	_typed = 99.0
	var tw := _root.create_tween()
	tw.tween_interval(0.45)
	tw.tween_property(_root, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(queue_free)


func _process(delta: float) -> void:
	_t += delta
	# The bar glides: it eases towards where it's been told to go, and while it waits there it keeps
	# creeping on a little (never past the next few per cent), so it never sits dead still.
	_creep = minf(maxf(_creep, _target) + delta * 0.012, minf(_target + 0.06, 0.995))
	var goal := maxf(_target, _creep)
	_shown = lerpf(_shown, goal, 1.0 - exp(-delta * 4.0))
	_typed += delta * 40.0
	var vs := _root.get_viewport_rect().size
	_bg_mat.set_shader_parameter("aspect", vs.x / maxf(vs.y, 1.0))
	_bg_mat.set_shader_parameter("progress", _shown)
	_bg_mat.set_shader_parameter("center_y", CENTER_Y)
	_bg_mat.set_shader_parameter("ring_r", 132.0 * minf(vs.x, vs.y) / 720.0 / maxf(vs.y, 1.0))   # on the gold ring
	_layout(vs)
	_fg.queue_redraw()


const CENTER_Y := 0.36                                 # the circle's middle, as a fraction of the height


func _draw_fg() -> void:
	var vs := _root.get_viewport_rect().size            # (the screen's own size: centred from the first frame)
	var c := Vector2(vs.x / 2.0, vs.y * CENTER_Y)      # the circle and the words a little high, the bar below
	var font := ThemeDB.fallback_font
	var cyan := Color(0.3, 0.8, 1.0)
	var gold := Color(0.95, 0.78, 0.35)
	var u := minf(vs.x, vs.y) / 720.0                 # scale everything with the screen
	# (the Shard, its rings and the name are 3D now: see _build_logo3d; only the line under them is drawn)
	_spaced(font, "A WORLD OF SWORDS, SPELLS AND SKILL", Vector2(c.x, c.y + 244.0 * u), int(16 * u), 4.0 * u, Color(0.6, 0.75, 0.9))
	# The bar: a slim capsule. A dark rounded track; the fill a soft gradient from cyan to gold
	# with rounded ends, drawn a pixel at a time so there are no steps; a gentle glow under it, a
	# light gliding along it, and a bright pearl at its head. The per cent sits above, at the right.
	var bw := minf(vs.x * 0.55, 600.0 * u)
	var bh := 8.0 * u
	var bx := c.x - bw / 2.0
	var by := c.y + 284.0 * u
	var rad := bh / 2.0
	var mid_y := by + rad
	_capsule(bx - 3 * u, mid_y, bw + 6 * u, rad + 3 * u, Color(0.0, 0.02, 0.05, 0.75))   # the track's shadow edge
	_capsule(bx, mid_y, bw, rad, Color(cyan, 0.1))                                      # the track
	var fill := maxf(bw * _shown, bh)
	for k in range(3):                                                                    # the glow under the fill
		_capsule(bx - k * 2 * u, mid_y, fill + k * 4 * u, rad + (k + 1) * 3 * u, Color(gold.lerp(cyan, 0.4), 0.05))
	var px := int(fill)
	for x in range(px):                                                                   # the fill, pixel by pixel
		var f := float(x) / maxf(bw, 1.0)
		var col := cyan.lerp(gold, smoothstep(0.0, 1.0, f))
		var h := rad
		if x < rad:                                                                       # rounded left end
			h = sqrt(maxf(rad * rad - (rad - x) * (rad - x), 0.0))
		elif x > px - rad:                                                                # rounded head
			var dx := x - (px - rad)
			h = sqrt(maxf(rad * rad - dx * dx, 0.0))
		var shine := exp(-pow((x - fmod(_t * 220.0 * u, fill + 120.0 * u) + 60.0 * u) / (28.0 * u), 2.0))
		_fg.draw_line(Vector2(bx + x, mid_y - h), Vector2(bx + x, mid_y + h), col.lerp(Color.WHITE, 0.55 * shine), 1.0)
	var head := Vector2(bx + fill - rad, mid_y)                                           # a pearl of light at the head
	var pulse := 0.85 + 0.15 * sin(_t * 4.0)
	for k in range(4):
		_fg.draw_circle(head, (rad + 2.0 * u) * (1.0 + k * 0.6), Color(1.0, 0.95, 0.8, 0.12 * pulse / (k + 1)))
	_fg.draw_circle(head, rad * 0.7, Color(1, 1, 1, 0.9))
	var pct := "%d%%" % roundi(_shown * 100.0)
	var pw := font.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * u)).x
	_fg.draw_string(font, Vector2(bx + bw - pw, by - 10 * u), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, int(20 * u), gold)
	# the step being loaded, typed out, with a blinking cursor
	var shown_text := _status.substr(0, int(_typed))
	if int(_t * 2.0) % 2 == 0:
		shown_text += "_"
	_fg.draw_string(font, Vector2(bx, by + bh + 26 * u), shown_text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, int(18 * u), Color(0.85, 0.92, 1.0))
	# the system lines, lower left
	for i in range(_log.size()):
		var a := clampf(1.0 - (_log.size() - 1 - i) * 0.12, 0.3, 1.0)
		_fg.draw_string(font, Vector2(24 * u, vs.y - 24 * u - (_log.size() - 1 - i) * 20 * u), "> " + _log[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, int(14 * u), Color(0.4, 0.9, 0.6, a))
	# corner brackets, like a viewfinder
	var m := 18.0 * u
	var l := 40.0 * u
	for corner in [Vector2(m, m), Vector2(vs.x - m, m), Vector2(m, vs.y - m), Vector2(vs.x - m, vs.y - m)]:
		var sx := 1.0 if corner.x < vs.x / 2.0 else -1.0
		var sy := 1.0 if corner.y < vs.y / 2.0 else -1.0
		_fg.draw_line(corner, corner + Vector2(l * sx, 0), Color(cyan, 0.6), 2.0 * u)
		_fg.draw_line(corner, corner + Vector2(0, l * sy), Color(cyan, 0.6), 2.0 * u)
	_fg.draw_string(font, Vector2(vs.x - 220 * u, vs.y - 24 * u), "v" + String(ProjectSettings.get_setting("application/config/version", "")),
		HORIZONTAL_ALIGNMENT_RIGHT, 196 * u, int(14 * u), Color(0.5, 0.6, 0.75))


## A capsule: a bar with round ends, centred on `y`, `r` the half-height.
func _capsule(x: float, y: float, w: float, r: float, col: Color) -> void:
	if w <= 2.0 * r:
		_fg.draw_circle(Vector2(x + w / 2.0, y), w / 2.0, col)
		return
	_fg.draw_rect(Rect2(x + r, y - r, w - 2.0 * r, 2.0 * r), col)
	_fg.draw_circle(Vector2(x + r, y), r, col)
	_fg.draw_circle(Vector2(x + w - r, y), r, col)


# --- the 3D logo ----------------------------------------------------------------------------

var _logo: SubViewportContainer
var _name3d: Title3D
var _crystal: Node3D
var _ring_nodes: Array[Node3D] = []


## The Shard in 3D: a glowing six-sided crystal turning slowly inside three rings of light (gold
## and blue, each spinning on its own axis), lit warm and cool, with a soft glow - and below it the
## name in the 3D gold letters of the title. Hidden until laid out, so the first frame is centred.
func _build_logo3d() -> void:
	_logo = SubViewportContainer.new()
	_logo.stretch = true
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.visible = false
	_root.add_child(_logo)
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	_logo.add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.5, 0.6)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	for lv in range(7):
		env.set_glow_level(lv, lv in [1, 2, 3])
	env.glow_intensity = 1.2
	env.glow_bloom = 0.1
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 34.0
	cam.position = Vector3(0, 0.25, 5.2)
	cam.look_at_from_position(cam.position, Vector3.ZERO, Vector3.UP)
	vp.add_child(cam)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-40), deg_to_rad(-30), 0)
	key.light_energy = 1.4
	key.light_color = Color(1.0, 0.93, 0.82)
	vp.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-1.5, 1.0, -1.5)
	rim.light_color = Color(0.4, 0.75, 1.0)
	rim.light_energy = 3.0
	rim.omni_range = 5.0
	vp.add_child(rim)
	# the crystal: two six-sided points, one up and one down, glowing blue from within
	_crystal = Node3D.new()
	vp.add_child(_crystal)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = Color(0.55, 0.85, 1.0)
	cmat.metallic = 0.3
	cmat.roughness = 0.12
	cmat.emission_enabled = true
	cmat.emission = Color(0.3, 0.75, 1.0)
	cmat.emission_energy_multiplier = 0.9
	for up in [true, false]:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0 if up else 0.42
		cone.bottom_radius = 0.42 if up else 0.0
		cone.height = 0.95 if up else 0.6
		cone.radial_segments = 6
		cone.rings = 1
		cone.material = cmat
		var mi := MeshInstance3D.new()
		mi.mesh = cone
		mi.position = Vector3(0, 0.475 if up else -0.3, 0)
		_crystal.add_child(mi)
	# three rings of light round it
	for r: Array in [[1.05, 0.025, Color(0.3, 0.8, 1.0)], [1.25, 0.018, Color(0.98, 0.76, 0.3)], [1.45, 0.03, Color(0.3, 0.8, 1.0)]]:
		var tm := TorusMesh.new()
		tm.inner_radius = float(r[0]) - float(r[1])
		tm.outer_radius = float(r[0]) + float(r[1])
		tm.rings = 48
		tm.ring_segments = 8
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = r[2]
		m.emission_enabled = true
		m.emission = r[2]
		m.emission_energy_multiplier = 1.5
		tm.material = m
		var ring := MeshInstance3D.new()
		ring.mesh = tm
		vp.add_child(ring)
		_ring_nodes.append(ring)
	# the name, in 3D gold
	_name3d = Title3D.make("SHARDSIGHT", 900.0, 0.8)
	_name3d.visible = false
	_root.add_child(_name3d)


## Places the logo and the name round the circle's centre, and turns them.
func _layout(vs: Vector2) -> void:
	if _logo == null:
		return
	var u := minf(vs.x, vs.y) / 720.0
	var c := Vector2(vs.x / 2.0, vs.y * CENTER_Y)
	var side := 360.0 * u
	_logo.size = Vector2(side, side)
	_logo.position = c - Vector2(side, side) / 2.0
	_logo.visible = true
	var nw := minf(vs.x * 0.85, 1000.0 * u)
	_name3d.custom_minimum_size = Vector2(nw, nw * 0.3)
	_name3d.size = Vector2(nw, nw * 0.3)
	_name3d.position = Vector2(c.x - nw / 2.0, c.y + 210.0 * u - nw * 0.15)
	_name3d.visible = true
	_crystal.rotation = Vector3(0.12 * sin(_t * 0.7), _t * 0.8, 0.0)
	_crystal.position.y = 0.06 * sin(_t * 1.6)          # it floats
	var axes: Array[Vector3] = [Vector3(1, 0.2, 0).normalized(), Vector3(0.3, 1, 0.2).normalized(), Vector3(0.2, 0.4, 1).normalized()]
	for i in range(_ring_nodes.size()):
		var tilt := Basis(Vector3(1, 0, 0), deg_to_rad(70.0 - i * 20.0))
		_ring_nodes[i].basis = Basis(axes[i], _t * (0.6 - i * 0.25) * (1.0 if i % 2 == 0 else -1.0)) * tilt
		var sc := 1.0 + 0.02 * sin(_t * 2.0 + i) + (_shown * 0.05 if i == 1 else 0.0)   # the gold ring swells with the loading
		_ring_nodes[i].scale = Vector3.ONE * sc


## A ring of `n` arcs with gaps between, turned by `turn`.
func _rings(c: Vector2, radius: float, n: int, turn: float, width: float, col: Color) -> void:
	var each := TAU / n
	for i in range(n):
		var a := turn + i * each
		_fg.draw_arc(c, radius, a, a + each * 0.62, 24, col, width, true)


## Text drawn a letter at a time, spaced out and centred on `at`, with a soft glow behind.
func _spaced(font: Font, text: String, at: Vector2, px: int, spacing: float, col: Color) -> void:
	var total := 0.0
	for ch in text:
		total += font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x + spacing
	total -= spacing
	var x := at.x - total / 2.0
	for ch in text:
		var adv := font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		_fg.draw_string_outline(font, Vector2(x, at.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, int(px * 0.25), Color(col, 0.18))
		_fg.draw_string(font, Vector2(x, at.y), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
		x += adv + spacing
