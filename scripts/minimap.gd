class_name Minimap
extends Control
## A small overhead map, painted like a map: grass with soft meadows, round tree crowns, water
## deep in the middle and pale in the shallows, sandy shores, shaded rocks, paved towns, the dark
## dungeon, glowing forges and house roofs; town names, ankh shrines, treasure chests, and
## everyone as outlined dots (you as a white arrow pointing where you face; pets green, monsters
## and murderers red, criminals grey, other players blue, NPCs cream). Framed in gold with a
## north mark.

const MAX_WIDTH := 320.0         # the bigger the map, the smaller each tile on the minimap
const SUB := 3                   # painted pixels per tile
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


func _draw() -> void:
	if world == null:
		return
	if _terrain == null or _revision != world.revision:
		_bake_terrain()
	var vsize := custom_minimum_size
	# the frame: a dark border with a thin gold line
	draw_rect(Rect2(Vector2(-4, -4), vsize + Vector2(8, 8)), FRAME)
	draw_texture_rect(_terrain, Rect2(Vector2.ZERO, vsize), false)
	draw_rect(Rect2(Vector2(-1, -1), vsize + Vector2(2, 2)), GOLD, false, 1.5)
	var font := ThemeDB.fallback_font
	# town names and the dungeon
	for i in range(World.TOWNS.size()):
		var r: Rect2i = World.TOWNS[i]
		_label(font, String(World.TOWN_NAMES[i]).capitalize(), (Vector2(r.position) + Vector2(r.size) / 2.0) * px)
	_label(font, "Dungeon", (Vector2(World.DUNGEON.position) + Vector2(World.DUNGEON.size) / 2.0) * px)
	# north
	draw_string_outline(font, Vector2(4, 13), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, 3, Color.BLACK)
	draw_string(font, Vector2(4, 13), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, GOLD)
	# ankh shrines: little glowing ankhs
	for s in game.shrines:
		var sp := _to_map(s)
		var glow := Color(0.7, 0.88, 1.0)
		draw_circle(sp, 4.5, Color(0.5, 0.75, 1.0, 0.25))
		draw_line(sp + Vector2(0, -1), sp + Vector2(0, 4), glow, 1.5)
		draw_line(sp + Vector2(-2.5, 0), sp + Vector2(2.5, 0), glow, 1.5)
		draw_arc(sp + Vector2(0, -2.5), 1.5, 0.0, TAU, 8, glow, 1.2)
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
	# everyone else, then the hero on top
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.is_hero or (e.dead and not e.ghost) or e.parked:
			continue
		var p := _to_map(e.position)
		if e.is_boss:                              # champions, warlords, the Bone King
			draw_circle(p, 4.2, Color(0.0, 0.0, 0.0, 0.6))
			draw_circle(p, 3.2, Color(1.0, 0.55, 0.15))
			continue
		draw_circle(p, 2.6, Color(0.0, 0.0, 0.0, 0.55))
		draw_circle(p, 1.8, _dot_color(e))
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
