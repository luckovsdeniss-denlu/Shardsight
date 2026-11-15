class_name MovieFlight
extends Movie
## The second trailer ("Trailer 2"): the first trailer's places, titles, words, talk and fights,
## filmed as one long flight - no cuts. It opens on a single line over the whole map, travels the
## land from the starting town to the far south, rising and swooping from each place to the next,
## and shows the journey on a long map across the top of the screen. It's its own script, so
## nothing here changes the first trailer.

## The second trailer: one long flight. The camera never cuts: it travels the whole map from
## the starting town to the far south, landing at every place of the first trailer in turn (its
## titles, words, talk, fights, weather and light as before), rising and swooping from each to
## the next - the farther, the higher and longer the flight - and ends high over the land.
const LONG_LINE := ["SHARDSIGHT", "Living towns", "Quests", "Bounties", "Fight", "Magic", "Seasons and storms",
	"World bosses", "Boats", "The Frostmarch", "The Drunken Shard", "Caves and deserts", "The Arena",
	"Help the townsfolk", "Ravenhollow", "The Shattered Sight", "The dungeon's depths", "Your story"]


func _shape_shots() -> void:
	var by_title := {}
	for sh: Dictionary in shots:
		by_title[String(sh["title"])] = sh
	var line: Array = []
	for title in LONG_LINE:
		if by_title.has(title):
			line.append(by_title[title])
	var last: Dictionary = line[line.size() - 1]           # the end: high over the middle of the land
	last["at"] = _tc(Vector2i(64, 80))
	last["r"] = 38.0
	last["h"] = 34.0
	last["cam"] = "orbit"
	last["no_hero"] = true                                 # (the land alone at the end)
	var first: Dictionary = line[0]                        # the start: one line over the whole land
	first["line"] = [_tc(Vector2i(136, 136)), _tc(Vector2i(32, 12))]
	first["line_h"] = 26.0
	first["dur"] = 16.0
	first["sub"] = "One world, from the sands of the south to the snows of the north."
	shots = line



## Each place: fly in from where the camera was, up in an arc and down - the farther, the higher
## and longer - and the place gets its full time once landed; its talk and words wait for the landing.
func _plan_scene(sh: Dictionary) -> void:
	if i == 0:
		return
	_fly_from_pos = game.cam.position
	_fly_from_look = _look_last
	var dist := _fly_from_pos.distance_to(sh["at"] as Vector3)
	_fly_dur = clampf(dist / 22.0, 2.2, 6.0)
	_fly_arc = clampf(dist * 0.1, 2.0, 12.0)              # (low over the land, not high in the sky)
	sh["dur"] = float(sh["dur"]) + _fly_dur
	_delay = _fly_dur


## One flight: never a dip to black between places.
func _continuous() -> bool:
	return true


func _extra_ui() -> void:
	_route = Control.new()                          # the map of the journey, across the top
	_route.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_route)
	_route.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_route.draw.connect(_draw_route)


func _redraw_extra() -> void:
	if _route != null:
		_route.queue_redraw()


# --- the map of the journey (trailer 2) ---------------------------------------------------

var _route: Control


## The whole world as a map in the corner, with the journey drawn across it as one long gold
## line through every place, in order: the stretch already travelled bright, the rest faint and
## dashed, a dot at each place, a glowing marker where the camera is now, and the name of the
## place being visited. The line draws itself in during the opening flight.
func _draw_route() -> void:
	if shots.is_empty() or i < 0:
		return
	var mm = game.minimap
	if mm._terrain == null:
		mm._bake_terrain()
	var vs := get_viewport().get_visible_rect().size
	# a long map: stretched across the whole top bar, the width of the screen and low
	var bar := vs.y * 0.12
	var origin := Vector2(24.0, 6.0)
	var msize := Vector2(vs.x - 48.0, maxf(bar - 12.0, 40.0))
	var to_map := func(p: Vector3) -> Vector2:
		return origin + Vector2(p.x / float(world.cols), p.z / float(world.rows)) / World.TILE * msize
	# the map, framed
	_route.draw_rect(Rect2(origin - Vector2(4, 4), msize + Vector2(8, 8)), Color(0.04, 0.05, 0.08, 0.85))
	_route.draw_texture_rect(mm._terrain, Rect2(origin, msize), false, Color(1, 1, 1, 0.92))
	_route.draw_rect(Rect2(origin - Vector2(1, 1), msize + Vector2(2, 2)), Color(0.85, 0.71, 0.29), false, 1.5)
	# the stops: the start of the opening line, then every place
	var pts: Array[Vector2] = []
	for k in range(shots.size()):
		var sh: Dictionary = shots[k]
		if sh.has("line"):
			pts.append(to_map.call(sh["line"][0]))
			pts.append(to_map.call(sh["line"][1]))
		else:
			pts.append(to_map.call(sh["at"]))
	# how far along: the stops reached so far, then the marker where the camera looks now
	var reached := clampi(i + 1 + (1 if (shots[0] as Dictionary).has("line") else 0), 1, pts.size())
	if i == 0 and (shots[0] as Dictionary).has("line"):
		reached = 1
	var here: Vector2 = to_map.call(_look_last)
	var gold := Color(1.0, 0.82, 0.35)
	for k in range(pts.size() - 1):                                # the way ahead: faint, dashed
		var a := pts[k]
		var b := pts[k + 1]
		var n := int(a.distance_to(b) / 6.0) + 1
		for d in range(0, n, 2):
			_route.draw_line(a.lerp(b, float(d) / n), a.lerp(b, minf(float(d + 1) / n, 1.0)), Color(1, 1, 1, 0.35), 1.5, true)
	var travelled := PackedVector2Array()                          # the way behind: bright gold
	for k in range(reached):
		travelled.append(pts[k])
	travelled.append(here)
	if travelled.size() >= 2:
		_route.draw_polyline(travelled, Color(0, 0, 0, 0.6), 5.0, true)
		_route.draw_polyline(travelled, gold, 2.5, true)
	for k in range(pts.size()):                                    # the stops
		_route.draw_circle(pts[k], 3.5 if k < reached else 2.5, gold if k < reached else Color(1, 1, 1, 0.6))
	var pulse := 1.0 + 0.3 * sin(t * 6.0)                          # where the camera looks now
	_route.draw_circle(here, 7.0 * pulse, Color(1.0, 0.85, 0.4, 0.3))
	_route.draw_circle(here, 3.5, Color(1, 1, 1))
	# the camera itself, flying by: its place, and a cone of light showing where it looks
	var cpos: Vector2 = to_map.call(game.cam.global_position)
	var fwd3 := -game.cam.global_transform.basis.z
	var fwd := Vector2(fwd3.x / float(world.cols) * msize.x, fwd3.z / float(world.rows) * msize.y)
	if fwd.length() > 0.0001:
		fwd = fwd.normalized()
		var reach := 26.0
		var half := deg_to_rad(game.cam.fov * 0.5)
		var cone := PackedVector2Array([cpos, cpos + fwd.rotated(-half) * reach, cpos + fwd.rotated(half) * reach])
		_route.draw_colored_polygon(cone, Color(0.6, 0.85, 1.0, 0.28))
		_route.draw_polyline(PackedVector2Array([cone[1], cpos, cone[2]]), Color(0.7, 0.9, 1.0, 0.8), 1.2, true)
	_route.draw_circle(cpos, 4.5, Color(0.15, 0.2, 0.3))
	_route.draw_circle(cpos, 3.0, Color(0.7, 0.9, 1.0))
	var font := ThemeDB.fallback_font
	var place := String((shots[i] as Dictionary)["title"])
	if i == 0:
		place = "The whole land"
	var at := origin + Vector2(8.0, msize.y - 6.0)                 # the place's name, in the map's corner
	_route.draw_string_outline(font, at, place.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color.BLACK)
	_route.draw_string(font, at, place.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, gold)
