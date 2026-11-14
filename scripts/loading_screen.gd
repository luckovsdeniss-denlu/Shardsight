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
	_fg.queue_redraw()


const CENTER_Y := 0.36                                 # the circle's middle, as a fraction of the height


func _draw_fg() -> void:
	var vs := _fg.size
	var c := Vector2(vs.x / 2.0, vs.y * CENTER_Y)      # the circle and the words a little high, the bar below
	var font := ThemeDB.fallback_font
	var cyan := Color(0.3, 0.8, 1.0)
	var gold := Color(0.95, 0.78, 0.35)
	var u := minf(vs.x, vs.y) / 720.0                 # scale everything with the screen
	# rings of light round the Shard, broken into arcs, turning at different speeds
	_rings(c, 112.0 * u, 6, _t * 0.6, 2.5 * u, Color(cyan, 0.55))
	_rings(c, 132.0 * u, 3, -_t * 0.35, 1.5 * u, Color(gold, 0.6))
	_rings(c, 150.0 * u, 12, _t * 0.15, 3.0 * u, Color(cyan, 0.25))
	# the progress arc on the inner ring
	_fg.draw_arc(c, 96.0 * u, -PI / 2.0, -PI / 2.0 + TAU * _shown, 64, Color(gold, 0.95), 3.5 * u, true)
	# tick marks round the outside
	for i in range(48):
		var a := TAU * i / 48.0
		var d := Vector2(cos(a), sin(a))
		var long := i % 4 == 0
		_fg.draw_line(c + d * 162.0 * u, c + d * (162.0 + (10.0 if long else 5.0)) * u, Color(cyan, 0.5 if long else 0.25), 1.5 * u)
	# the Shard: a crystal spinning slowly, with a glow
	var spin := _t * 0.8
	var w := absf(cos(spin)) * 30.0 * u + 6.0 * u
	var hgt := 62.0 * u
	var glow_r := 58.0 * u * (1.0 + 0.06 * sin(_t * 3.0))
	for k in range(6):
		_fg.draw_circle(c, glow_r * (1.0 - k * 0.14), Color(0.3, 0.7, 1.0, 0.035))
	var shard := PackedVector2Array([c + Vector2(0, -hgt), c + Vector2(w, -hgt * 0.15), c + Vector2(0, hgt * 0.7), c + Vector2(-w, -hgt * 0.15)])
	_fg.draw_colored_polygon(shard, Color(0.55, 0.85, 1.0, 0.85))
	var facet := PackedVector2Array([c + Vector2(0, -hgt), c + Vector2(w * (0.5 if cos(spin) > 0.0 else -0.5), -hgt * 0.15), c + Vector2(0, hgt * 0.7)])
	_fg.draw_colored_polygon(facet, Color(0.9, 0.97, 1.0, 0.7))
	shard.append(shard[0])
	_fg.draw_polyline(shard, Color(1, 1, 1, 0.9), 1.5 * u, true)
	# the name, spaced out, with a gold glow
	_spaced(font, "SHARDSIGHT", Vector2(c.x, c.y + 210.0 * u), int(54 * u), 14.0 * u, gold)
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
