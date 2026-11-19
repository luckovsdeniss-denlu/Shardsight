class_name Minimap
extends Control
## A small overhead map, painted like a map: grass with soft meadows, round tree crowns, water
## deep in the middle and pale in the shallows, sandy shores, shaded rocks, paved towns, the dark
## dungeon, glowing forges and house roofs; town names, ankh shrines, treasure chests, and
## everyone as outlined dots (you as a white arrow pointing where you face; pets green, monsters
## and murderers red, criminals grey, other players blue, NPCs cream). Framed in gold with a
## north mark.

const MAX_WIDTH := 264.0         # the bigger the map, the smaller each tile on the minimap
const SUB := 2                   # painted pixels per tile
var px := 4.0

const GRASS := Color(0.24, 0.40, 0.22)
const MEADOW := Color(0.34, 0.50, 0.26)
const TREE_DARK := Color(0.08, 0.20, 0.10)
const TREE_MID := Color(0.13, 0.31, 0.15)
const TREE_LIGHT := Color(0.24, 0.45, 0.22)
const DEEP := Color(0.12, 0.27, 0.52)
const SHALLOW := Color(0.30, 0.55, 0.75)
const SAND := Color(0.74, 0.67, 0.47)
const ROCK := Color(0.52, 0.49, 0.45)
const WALL := Color(0.50, 0.50, 0.54)
const PAVING := Color(0.64, 0.58, 0.44)
const DUNGEON_FLOOR := Color(0.16, 0.14, 0.13)
const FORGE := Color(1.0, 0.55, 0.18)
const ROOF := Color(0.62, 0.33, 0.24)
const FRAME := Color(0.06, 0.07, 0.09, 0.9)
const GOLD := Color(0.85, 0.71, 0.29)

var game
var world: World
var _timer := 0.0
var _terrain: ImageTexture       # the map itself, painted once (and again when a house changes it)
var _revision := -1


const BIOME_MAP := {"snow": Color("e2e8ef"), "desert": Color("c9a96c"), "swamp": Color("3a4a2c"), "ash": Color("4a4340")}

func setup(p_game, p_world: World) -> void:
	game = p_game
	world = p_world
	px = minf(4.0, MAX_WIDTH / float(world.cols))
	custom_minimum_size = Vector2(world.cols, world.rows) * px
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR    # smooth, like a painted map
	mouse_filter = Control.MOUSE_FILTER_STOP     # tap the map to travel there


func _gui_input(event: InputEvent) -> void:
	var pressed := false
	var at := Vector2.ZERO
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
		at = mb.position
	elif event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		pressed = st.pressed
		at = st.position
	if not pressed or game == null:
		return
	accept_event()
	game.hero_journey(Vector2i(floori(at.x / px), floori(at.y / px)))


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.5
		queue_redraw()


func _tile(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= world.cols or y >= world.rows:
		return World.Tile.WALL
	return world.tiles[y * world.cols + x]


## Paints the terrain at SUB pixels a tile.
func _bake_terrain() -> void:
	var w := world.cols * SUB
	var h := world.rows * SUB
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 77
	noise.frequency = 0.06
	var fine := FastNoiseLite.new()
	fine.seed = 13
	fine.frequency = 0.35
	for py in range(h):
		for pxl in range(w):
			var tx := pxl / SUB
			var ty := py / SUB
			var fx := (float(pxl % SUB) + 0.5) / SUB     # where in the tile, 0..1
			var fy := (float(py % SUB) + 0.5) / SUB
			var t := _tile(tx, ty)
			var c := Vector2i(tx, ty)
			var n := noise.get_noise_2d(pxl, py) * 0.5 + 0.5       # 0..1, broad patches
			var f := fine.get_noise_2d(pxl, py) * 0.5 + 0.5        # 0..1, grain
			var col: Color
			match t:
				World.Tile.GRASS:
					if world.is_town(c):
						col = PAVING.lerp(PAVING.darkened(0.18), f)
						if (pxl + py * 2) % 5 == 0:
							col = col.darkened(0.12)                 # cobble joints
					elif world.is_dungeon(c) or world.is_cave(c):
						col = DUNGEON_FLOOR.lerp(DUNGEON_FLOOR.lightened(0.15), f)
					else:
						col = GRASS.lerp(MEADOW, smoothstep(0.45, 0.8, n)).lerp(GRASS.darkened(0.15), f * 0.35)
						var bio := world.biome_at(c)
						if bio != "":
							col = col.lerp(Color(BIOME_MAP[bio]).lerp(Color(BIOME_MAP[bio]).darkened(0.12), f), 0.8)
						if _near(tx, ty, World.Tile.WATER, fx, fy):
							col = SAND.lerp(col, 0.25)               # a sandy shore
				World.Tile.TREE:
					var under := GRASS.darkened(0.1)
					var d := Vector2(fx - 0.5, fy - 0.5).length()
					if d < 0.48:
						col = TREE_MID.lerp(TREE_DARK, smoothstep(0.2, 0.48, d))
						if fx < 0.45 and fy < 0.45:
							col = col.lerp(TREE_LIGHT, 0.55)         # a sunlit top-left
					else:
						col = under
				World.Tile.WATER:
					var shore := _shore_distance(tx, ty)
					col = SHALLOW.lerp(DEEP, clampf(shore / 3.0, 0.0, 1.0))
					if f > 0.78:
						col = col.lightened(0.25)                  # glints
				World.Tile.ROCK:
					col = ROCK.lerp(ROCK.lightened(0.25), clampf(1.2 - fx - fy, 0.0, 1.0))   # lit from the top-left
					col = col.darkened(f * 0.15)
				World.Tile.WALL:
					col = WALL.lerp(WALL.darkened(0.25), f * 0.6)
					if world.is_dungeon(c):
						col = col.darkened(0.35)
				World.Tile.FORGE:
					col = FORGE.lerp(Color(1.0, 0.9, 0.4), 1.0 - Vector2(fx - 0.5, fy - 0.5).length() * 2.0)
				World.Tile.HOUSE:
					col = ROOF.lerp(ROOF.darkened(0.25), 0.5 if (py % SUB) == 0 else f * 0.3)   # roof ridges
				_:
					col = Color(0.1, 0.1, 0.1)
			# a dark line where open ground meets anything solid, so shapes read clearly
			if t != World.Tile.GRASS and t != World.Tile.TREE and t != World.Tile.WATER and _edge(tx, ty, fx, fy):
				col = col.darkened(0.35)
			col.a = 0.95
			img.set_pixel(pxl, py, col)
	_terrain = ImageTexture.create_from_image(img)
	_revision = world.revision


## Whether this edge pixel of a tile touches a `kind` tile next to it.
func _near(tx: int, ty: int, kind: int, fx: float, fy: float) -> bool:
	return (fx < 0.34 and _tile(tx - 1, ty) == kind) or (fx > 0.66 and _tile(tx + 1, ty) == kind) \
		or (fy < 0.34 and _tile(tx, ty - 1) == kind) or (fy > 0.66 and _tile(tx, ty + 1) == kind)


## Whether this edge pixel of a solid tile borders open ground.
func _edge(tx: int, ty: int, fx: float, fy: float) -> bool:
	return _near(tx, ty, World.Tile.GRASS, fx, fy)


## How many tiles to the nearest shore (up to 3).
func _shore_distance(tx: int, ty: int) -> float:
	for r in range(1, 4):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dy) != r:
					continue
				if _tile(tx + dx, ty + dy) != World.Tile.WATER:
					return float(r - 1)
	return 3.0


func _to_map(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) / World.TILE * px


## What never moves - the frame, the land, the town names, north and the shrines - painted once
## into a picture of its own (again only when the land changes), and drawn as that one picture:
## drawn bit by bit, it was dozens of draws every frame.
var _static_vp: SubViewport = null
var _static_draw: Control = null
var _static_rev := -2
const PAD := 4.0


func _ensure_static() -> void:
	if _terrain == null or _revision != world.revision:
		_bake_terrain()
	if _static_vp == null:
		_static_vp = SubViewport.new()
		_static_vp.transparent_bg = true
		_static_vp.disable_3d = true
		_static_vp.size = Vector2i(custom_minimum_size + Vector2(PAD * 2.0, PAD * 2.0))
		add_child(_static_vp)
		_static_draw = Control.new()
		_static_draw.size = Vector2(_static_vp.size)
		_static_draw.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_static_draw.draw.connect(_draw_static)
		_static_vp.add_child(_static_draw)
	if _static_rev != world.revision or (_static_rev == -2):
		_static_rev = world.revision
		_static_draw.queue_redraw()
		_static_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _draw_static() -> void:
	var c := _static_draw
	var o := Vector2(PAD, PAD)
	var vsize := custom_minimum_size
	# the frame: a dark border with a thin gold line
	c.draw_rect(Rect2(Vector2.ZERO, vsize + Vector2(PAD * 2.0, PAD * 2.0)), FRAME)
	c.draw_texture_rect(_terrain, Rect2(o, vsize), false)
	c.draw_rect(Rect2(o - Vector2(1, 1), vsize + Vector2(2, 2)), GOLD, false, 1.5)
	var font := ThemeDB.fallback_font
	# town names and the dungeon
	for i in range(World.TOWNS.size()):
		var r: Rect2i = World.TOWNS[i]
		_label_on(c, font, String(World.TOWN_NAMES[i]).capitalize(), o + (Vector2(r.position) + Vector2(r.size) / 2.0) * px)
	_label_on(c, font, "Dungeon", o + (Vector2(World.DUNGEON.position) + Vector2(World.DUNGEON.size) / 2.0) * px)
	_label_on(c, font, "Cemetery", o + (Vector2(World.CEMETERY.position) + Vector2(World.CEMETERY.size) / 2.0) * px)
	# north
	c.draw_string_outline(font, o + Vector2(4, 13), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
	c.draw_string(font, o + Vector2(4, 13), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	# ankh shrines: little glowing ankhs
	for s in game.shrines:
		var sp := o + _to_map(s)
		var glow := Color(0.7, 0.88, 1.0)
		c.draw_circle(sp, 4.5, Color(0.5, 0.75, 1.0, 0.25))
		c.draw_line(sp + Vector2(0, -1), sp + Vector2(0, 4), glow, 1.5)
		c.draw_line(sp + Vector2(-2.5, 0), sp + Vector2(2.5, 0), glow, 1.5)
		c.draw_arc(sp + Vector2(0, -2.5), 1.5, 0.0, TAU, 8, glow, 1.2)


func _label_on(c: Control, font: Font, text: String, centre: Vector2) -> void:
	var fs := 10
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := centre + Vector2(-w / 2.0, 4.0)
	c.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.85))
	c.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.94, 0.78))


func _draw() -> void:
	if world == null:
		return
	_ensure_static()
	draw_texture(_static_vp.get_texture(), Vector2(-PAD, -PAD))
	# where the story leads: a violet diamond
	if game.has_story_target and not game.property.story_done:
		var sp2 := _to_map(game.story_target)
		var dia := PackedVector2Array([sp2 + Vector2(0, -5), sp2 + Vector2(4, 0), sp2 + Vector2(0, 5), sp2 + Vector2(-4, 0)])
		draw_colored_polygon(dia, Color(0.75, 0.5, 1.0))
		dia.append(sp2 + Vector2(0, -5))
		draw_polyline(dia, Color.BLACK, 1.0)
	# the wider world: towers, the arena, the tavern, the landings, a hunted elite
	if game.frontier != null:
		game.frontier.draw_marks(self)
	# where the hero is walking to: a gold flag
	var h: Entity = game.hero
	if h != null and h.has_journey:
		var jp := _to_map(h.journey)
		draw_line(jp, jp + Vector2(0, -9), Color.BLACK, 2.5)
		draw_line(jp, jp + Vector2(0, -9), Color(0.9, 0.85, 0.7), 1.2)
		draw_colored_polygon(PackedVector2Array([jp + Vector2(0, -9), jp + Vector2(6, -7), jp + Vector2(0, -5)]), GOLD)
	# the treasure map's spot: a red X
	if game.map_mark.x >= 0:
		var mp: Vector2 = (Vector2(game.map_mark) + Vector2(0.5, 0.5)) * px
		draw_line(mp + Vector2(-4, -4), mp + Vector2(4, 4), Color(0, 0, 0, 0.7), 3.0)
		draw_line(mp + Vector2(-4, 4), mp + Vector2(4, -4), Color(0, 0, 0, 0.7), 3.0)
		draw_line(mp + Vector2(-3.5, -3.5), mp + Vector2(3.5, 3.5), Color(0.95, 0.2, 0.15), 2.0)
		draw_line(mp + Vector2(-3.5, 3.5), mp + Vector2(3.5, -3.5), Color(0.95, 0.2, 0.15), 2.0)
	# treasure chests
	for c in game.corpses:
		if c.is_chest and not c.is_empty():
			var cp := _to_map(c.position)
			draw_circle(cp, 3.0, Color(0.0, 0.0, 0.0, 0.6))
			draw_circle(cp, 2.2, Color(1.0, 0.82, 0.3))
	# everyone else, then the hero on top - all the dots in one batch (one draw for the lot: a
	# circle each was two draws a creature, hundreds a frame, the most of the screen's whole cost)
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.is_hero or (e.dead and not e.ghost) or e.parked:
			continue
		var p := _to_map(e.position)
		if e.is_boss:                              # champions, warlords, the Bone King
			_dot(verts, cols, p, 4.2, Color(0.0, 0.0, 0.0, 0.6))
			_dot(verts, cols, p, 3.2, Color(1.0, 0.55, 0.15))
			continue
		_dot(verts, cols, p, 2.6, Color(0.0, 0.0, 0.0, 0.55))
		_dot(verts, cols, p, 1.8, _dot_color(e))
	if not verts.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_COLOR] = cols
		_dots_mesh.clear_surfaces()
		_dots_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		draw_mesh(_dots_mesh, null)
	var hero: Entity = game.hero
	if hero != null:
		var hp := _to_map(hero.position)
		var fwd := Vector2(-sin(hero.rotation.y), -cos(hero.rotation.y))   # where the hero faces
		var side := Vector2(-fwd.y, fwd.x)
		var tip := hp + fwd * 5.5
		var pts := PackedVector2Array([tip, hp - fwd * 3.0 + side * 3.5, hp - fwd * 1.5, hp - fwd * 3.0 - side * 3.5])
		draw_colored_polygon(pts, Color.WHITE if not hero.dead else Color(0.75, 0.88, 1.0))
		pts.append(tip)
		draw_polyline(pts, Color.BLACK, 1.0)


var _dots_mesh := ArrayMesh.new()


## A round dot (an octagon of triangles) added to the batch.
func _dot(verts: PackedVector2Array, cols: PackedColorArray, at: Vector2, r: float, c: Color) -> void:
	for i in range(8):
		var a0 := TAU * i / 8.0
		var a1 := TAU * (i + 1) / 8.0
		verts.append(at)
		verts.append(at + Vector2(cos(a0), sin(a0)) * r)
		verts.append(at + Vector2(cos(a1), sin(a1)) * r)
		cols.append(c)
		cols.append(c)
		cols.append(c)


func _label(font: Font, text: String, centre: Vector2) -> void:
	var fs := 10
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := centre + Vector2(-w / 2.0, 4.0)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 3, Color(0, 0, 0, 0.85))
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.94, 0.78))


func _dot_color(e: Entity) -> Color:
	if e.kind == Entity.Kind.PET:
		return Color(0.5, 1.0, 0.5)
	if e.kind == Entity.Kind.NPC:
		return Color(0.95, 0.9, 0.7)
	match e.notoriety():
		Entity.Notoriety.RED:
			return Color(1.0, 0.3, 0.3)
		Entity.Notoriety.GREY:
			return Color(0.7, 0.7, 0.7)
	return Color(0.4, 0.6, 1.0)
