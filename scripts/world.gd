class_name World
## Tile map: ASCII layout, collision lookup, A* pathfinding and 3D mesh building.
## Tile (x, y) maps to world (x, 0, y): the map lies on the XZ plane.
## Legend: . grass   # wall   ~ water   T tree (wood)   R rock (ore)   F forge.
## Only grass is walkable.

const TILE := 1.0  # one tile = one metre in 3D
enum Tile { GRASS, WALL, WATER, TREE, ROCK, FORGE, HOUSE }

## The towns: safe zones where nobody can be hurt and nobody can attack out of; monsters keep
## out of them. Everything else is open wilderness.
const TOWNS := [Rect2i(19, 2, 11, 12), Rect2i(33, 2, 9, 6), Rect2i(44, 30, 12, 9)]   # the main town, the outpost, Southmoor
## The dungeon: dark halls in the east with the toughest monsters. You can't Mark a rune here.
const DUNGEON := Rect2i(37, 11, 13, 11)

const LAYOUT := [
	"################################################################################################",
	"#..............................#...................#.......TT......T..T.....................T..#",
	"#..............................#.............................T..........T.........###########..#",
	"#..TT....T.......RR.#########..#............TT....................................#.........#..#",
	"#..T................#.......#...............T.....................................#.........#..#",
	"#.............TT....#F......#........................................R............#.........#..#",
	"#..............T....#.......#..#................TT............T...............T...#.........#..#",
	"#...................#.......#..#.......RR.....................................T..T#.........#..#",
	"#.R.................#.......#..#...................#.............R......~......T..#.........#..#",
	"#.RR................####.####..#...................#.................~~~~~~~......####...####..#",
	"#..............................#....################..............T.~~~~~~~~~.....T............#",
	"#..............................#....#.....#.......##....T.....TT...~~~~~~~~~~~.............T...#",
	"#.............##TT.#####.......#.T..#.....#.......##................~~~~~~~~~.T................#",
	"#..............................#.T..#.....#.......##..........T......~~~~~~~......T.......R....#",
	"#......~~~~~R..................#....#.....#...#...##.............R......~.R.............R......#",
	"#.....~~~~~~~.........TT.......#....#.....#...#...##........T...T..............................#",
	"#.....~~~~~~~..........T..................#...#...##........T....T.TT.R................T...T...#",
	"#......~~~~~........................#.....#...#...##..........T..T...................T.........#",
	"#..............................#....#.....#...#...##.........TT...T............................#",
	"#.T.......................TT...#....#.........#...##...T..T..TT.TT............T................#",
	"#.TT.....RR....................#....#.........#...##..........T.TTTT......T....................#",
	"#..........................RR..#....#.........#...##.........T..TT.T...........................#",
	"#...........................R..#....################..T........................................#",
	"####....############.....########...################...........................................#",
	"#...........................................................................................T..#",
	"#........TT.......TT.....T............R.........................................T....T.........#",
	"#.T..........T..TT..........T..R.............................T...........T.....................#",
	"#.........T...TTT...........T.T...............................................................T#",
	"#........T....T.TT.......T...........................................T......T.....############.#",
	"#.T.............T..T..........T..........................TT.T......T..............#..........#.#",
	"#..............T............T......RR.............................................#..........#.#",
	"#..........T.TT..T.T..TT..T.T.T...................................................#..#..#..#.#.#",
	"#..TT.TT.TTT..TTTT.....T.TT........................................T......T.......#..........#.#",
	"#....TTTTT....T.T.......TTT......................##.....T....................................#.#",
	"#.....TTT.....T..T.......T.......................##..........................................#.#",
	"#.....T.T..TT......T.........T.....R........................T................................#.#",
	"#..TTT...........T....T..T..T.......~.....................................T.......#..........#.#",
	"#...T.T......TT...T.T.TTTTT..T....~~~~~......................T.........T.T........#..#..#..#.#.#",
	"#.T.................T..T.T.T..T..~~~~~~~.......................RR....R.....R....R.#..........#.#",
	"#.TTT....T......T....TT.....T...~~~~~~~~~........................R..R..R....R...R.#..........#.#",
	"#..T...............T.....TT.TT...~~~~~~~............................R...RRR.R.....############.#",
	"#..T..T........T.T............T...~~~~~.......................T..R.R........R...R..........T...#",
	"#......T.T........T.........TTT.....~......................T.....R.R.R........R.R..............#",
	"#.........T.T...T...........................................................RR.................#",
	"#...............TTT.T.......T.....................................RR...........................#",
	"#..T.......TTT.......................................................R......R..T...............#",
	"#.....................................................................RR.......................#",
	"################################################################################################",
]
const COLORS := {
	Tile.GRASS: Color("2f5d34"),
	Tile.WALL: Color("6b6f7a"),
	Tile.WATER: Color("2a5f9e"),
	Tile.TREE: Color("2f5d34"),
	Tile.ROCK: Color("7a7268"),
	Tile.FORGE: Color("3b3b3b"),
	Tile.HOUSE: Color("a0785a"),
}

const HARVEST_PER_NODE := 6      # a rock or tree gives this many tries before it is exhausted
const REGROW_MS := 60000         # ... and then it recovers after a minute

var cols := 0
var rows := 0
var tiles: Array[int] = []
var astar := AStarGrid2D.new()
var astar_outside := AStarGrid2D.new()   # same grid, but the towns are walled off (for monsters)
var forge_tile := Vector2i(-1, -1)
var house_nodes := {}            # house origin -> Node3D holding its meshes
var decor: Array = []            # the grass tufts and flowers (hidden on Low graphics)
var ground_material: ShaderMaterial    # the painted ground (its cloud shadows follow the weather)
var revision := 0                # bumped when tiles change (houses), so the minimap redraws them
var _harvest_left := {}          # tile -> tries left
var _regrow_at := {}             # tile -> Time.get_ticks_msec() when an exhausted node recovers


func _init() -> void:
	rows = LAYOUT.size()
	cols = String(LAYOUT[0]).length()
	tiles.resize(cols * rows)
	for y in range(rows):
		for x in range(cols):
			tiles[y * cols + x] = _parse(String(LAYOUT[y])[x])
			if tiles[y * cols + x] == Tile.FORGE:
				forge_tile = Vector2i(x, y)
	astar.region = Rect2i(0, 0, cols, rows)
	astar.cell_size = Vector2(TILE, TILE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	astar_outside.region = astar.region
	astar_outside.cell_size = astar.cell_size
	astar_outside.diagonal_mode = astar.diagonal_mode
	astar_outside.update()
	for y in range(rows):
		for x in range(cols):
			var c := Vector2i(x, y)
			if is_blocked(c):
				astar.set_point_solid(c, true)
				astar_outside.set_point_solid(c, true)
			elif is_town(c):
				astar_outside.set_point_solid(c, true)


static func _parse(ch: String) -> int:
	match ch:
		"#":
			return Tile.WALL
		"~":
			return Tile.WATER
		"T":
			return Tile.TREE
		"R":
			return Tile.ROCK
		"F":
			return Tile.FORGE
		_:
			return Tile.GRASS


func is_town(c: Vector2i) -> bool:
	for r in TOWNS:
		if (r as Rect2i).has_point(c):
			return true
	return false


const TOWN_NAMES := ["town", "the outpost", "Southmoor"]   # same order as TOWNS


## A rough name for where a tile is: a town, the dungeon or the wilds.
func place_name(c: Vector2i) -> String:
	for i in range(TOWNS.size()):
		if (TOWNS[i] as Rect2i).has_point(c):
			return TOWN_NAMES[i]
	if is_dungeon(c):
		return "the dungeon"
	return "the wilds"


func is_dungeon(c: Vector2i) -> bool:
	return DUNGEON.has_point(c)


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


## Collision: anything that is not grass, and everything outside the map, blocks.
## "ore" for rocks, "wood" for trees, "" for anything else.
func resource_kind(c: Vector2i) -> String:
	if not in_bounds(c):
		return ""
	match tiles[c.y * cols + c.x]:
		Tile.ROCK:
			return "ore"
		Tile.TREE:
			return "wood"
		Tile.WATER:
			return "fish"
	return ""


func can_harvest(c: Vector2i) -> bool:
	if resource_kind(c) == "":
		return false
	if _regrow_at.has(c):
		if Time.get_ticks_msec() < int(_regrow_at[c]):
			return false
		_regrow_at.erase(c)
		_harvest_left.erase(c)
	return true


func take_harvest(c: Vector2i) -> void:
	var left := int(_harvest_left.get(c, HARVEST_PER_NODE)) - 1
	if left <= 0:
		_harvest_left.erase(c)
		_regrow_at[c] = Time.get_ticks_msec() + REGROW_MS
	else:
		_harvest_left[c] = left


## The walkable neighbour of `c` (including diagonals) closest to `from_p`, or (-1, -1).
func stand_tile_for(c: Vector2i, from_p: Vector3) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := INF
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var n := c + Vector2i(dx, dy)
			if (dx == 0 and dy == 0) or is_blocked(n):
				continue
			var d := tile_center(n).distance_to(from_p)
			if d < best_d:
				best = n
				best_d = d
	return best


## Closest harvestable node of `kind` within `radius` tiles that has somewhere to stand.
func find_harvest_near(p: Vector3, kind: String, radius: int) -> Vector2i:
	var here := to_tile(p)
	var best := Vector2i(-1, -1)
	var best_d := INF
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var c := here + Vector2i(dx, dy)
			if resource_kind(c) != kind or not can_harvest(c):
				continue
			if stand_tile_for(c, p).x < 0:
				continue
			var d := tile_center(c).distance_to(p)
			if d < best_d:
				best = c
				best_d = d
	return best


func near_forge(p: Vector3) -> bool:
	return forge_tile.x >= 0 and p.distance_to(tile_center(forge_tile)) <= 2.0


# --- player houses ---------------------------------------------------------
# A house is size x size tiles (3, 5 or 7): walls all round, open floor inside with the chest in
# the middle, and a door in the middle of the bottom wall.

func house_tiles(o: Vector2i, size := 3) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(size):
		for dx in range(size):
			out.append(o + Vector2i(dx, dy))
	return out


static func house_door(o: Vector2i, size := 3) -> Vector2i:
	return o + Vector2i(size / 2, size - 1)


static func house_center(o: Vector2i, size := 3) -> Vector2i:
	return o + Vector2i(size / 2, size / 2)


func house_wall_tiles(o: Vector2i, size := 3) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var door := house_door(o, size)
	for c in house_tiles(o, size):
		var rel := c - o
		var edge := rel.x == 0 or rel.y == 0 or rel.x == size - 1 or rel.y == size - 1
		if edge and c != door:
			out.append(c)
	return out


## Free grass outside town, nobody standing on it, and open ground in front of the door.
func can_place_house(o: Vector2i, occupied: Dictionary, size := 3) -> bool:
	for c in house_tiles(o, size):
		if is_blocked(c) or is_town(c) or occupied.has(c):
			return false
	var outside := house_door(o, size) + Vector2i(0, 1)
	return not is_blocked(outside) and not is_town(outside)


func place_house(parent: Node3D, o: Vector2i, size := 3) -> void:
	revision += 1
	_flatten(Rect2i(o, Vector2i(size, size)), height_at(tile_center(house_center(o, size))))   # level ground
	for c in house_wall_tiles(o, size):
		tiles[c.y * cols + c.x] = Tile.HOUSE
		astar.set_point_solid(c, true)
		astar_outside.set_point_solid(c, true)
	var node := Node3D.new()
	parent.add_child(node)
	house_nodes[o] = node
	# Timber framing: pale plaster between dark beams, and a banded chest.
	var plaster := Color(0.86, 0.8, 0.66)
	var beam := Color(0.33, 0.22, 0.12)
	var wall_mesh := Art.merge([[Art.box(TILE, 1.4, TILE), Art.at(0, 0.7, 0), plaster],
		[Art.box(TILE * 1.02, 0.1, TILE * 1.02), Art.at(0, 1.4, 0), beam],
		[Art.box(TILE * 1.02, 0.08, TILE * 1.02), Art.at(0, 0.05, 0), beam],
		[Art.box(0.1, 1.4, TILE * 1.02), Art.at(-0.45, 0.7, 0), beam],
		[Art.box(0.1, 1.4, TILE * 1.02), Art.at(0.45, 0.7, 0), beam],
		[Art.box(TILE * 1.02, 1.4, 0.1), Art.at(0, 0.7, -0.45), beam],
		[Art.box(TILE * 1.02, 1.4, 0.1), Art.at(0, 0.7, 0.45), beam]])
	var vc := Art.vc_mat()
	for c in house_wall_tiles(o, size):
		_add(node, wall_mesh, vc, tile_center(c))
	var wood := Color(0.42, 0.27, 0.14)
	var chest_mesh := Art.merge([[Art.box(0.5, 0.32, 0.35), Art.at(0, 0.16, 0), wood],
		[Art.box(0.52, 0.1, 0.37), Art.at(0, 0.37, 0), wood.lightened(0.1)],
		[Art.box(0.06, 0.44, 0.38), Art.at(-0.17, 0.21, 0), Art.DARK],
		[Art.box(0.06, 0.44, 0.38), Art.at(0.17, 0.21, 0), Art.DARK],
		[Art.box(0.08, 0.08, 0.02), Art.at(0, 0.3, -0.19), Color(0.8, 0.65, 0.2)]])
	_add(node, chest_mesh, vc, tile_center(house_center(o, size)) + Vector3(0, 0, -0.25))
	if size > 3:                           # bigger houses get a floor
		_add_floor(node, Rect2i(o + Vector2i(1, 1), Vector2i(size - 2, size - 2)), Color("8b6b4a"))


func remove_house(o: Vector2i, size := 3) -> void:
	revision += 1
	for c in house_wall_tiles(o, size):
		tiles[c.y * cols + c.x] = Tile.GRASS
		astar.set_point_solid(c, false)
		astar_outside.set_point_solid(c, is_town(c))
	if house_nodes.has(o):
		var node: Node3D = house_nodes[o]
		node.queue_free()
		house_nodes.erase(o)


## Wall of Stone / Energy Field: a tile paths must go round for a while (the tile itself stays
## grass, so nothing standing on it is ever "inside a wall").
func set_temp_block(c: Vector2i, on: bool) -> void:
	if not in_bounds(c):
		return
	astar.set_point_solid(c, on or is_blocked(c))
	astar_outside.set_point_solid(c, on or is_blocked(c) or is_town(c))


func reachable_count(start: Vector2i, extra_blocked: Dictionary) -> int:
	if is_blocked(start) or extra_blocked.has(start):
		return 0
	var seen := {start: true}
	var stack: Array[Vector2i] = [start]
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	while not stack.is_empty():
		var c: Vector2i = stack.pop_back()
		for d in dirs:
			var n := c + d
			if seen.has(n) or is_blocked(n) or extra_blocked.has(n):
				continue
			seen[n] = true
			stack.append(n)
	return seen.size()


## Nearest spot within `radius` of `near` where a house fits without cutting off any part
## of the map. Returns (-1, -1) if there is none.
func find_house_spot(near: Vector2i, occupied: Dictionary, size := 3, radius := 6) -> Vector2i:
	var base := reachable_count(near, {})
	for r in range(radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var o := near + Vector2i(dx, dy) - Vector2i(size / 2, size / 2)
				if not can_place_house(o, occupied, size):
					continue
				var walls := {}
				for c in house_wall_tiles(o, size):
					walls[c] = true
				if reachable_count(near, walls) == base - walls.size():
					return o
	return Vector2i(-1, -1)


## A flat coloured patch over a rectangle of tiles (town paving, dungeon floor).
func _add_floor(parent: Node3D, r: Rect2i, color: Color, mat: Material = null) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(r.size) * TILE
	var at := Vector3(r.position.x + r.size.x / 2.0, 0.0, r.position.y + r.size.y / 2.0) * TILE
	at.y = height_at(at) + 0.01 * TILE
	_add(parent, mesh, mat if mat != null else _mat(color), at)


## The map split into equal regions (4 across, 2 down) so players and monsters can be spread
## evenly over all of it.
const ZONE_COLS := 4
const ZONE_ROWS := 2
const SPAWN_CHECK_TILE := Vector2i(24, 11)   # in the main town, by the healer


func zone_count() -> int:
	return ZONE_COLS * ZONE_ROWS


func zone_rect(i: int) -> Rect2i:
	var w := cols / ZONE_COLS
	var h := rows / ZONE_ROWS
	var zx := i % ZONE_COLS
	var zy := (i / ZONE_COLS) % ZONE_ROWS
	return Rect2i(zx * w, zy * h, w, h)


## A random open tile in `r`, outside the towns and the dungeon (for spawning).
func open_tile_in(r: Rect2i, rng: RandomNumberGenerator) -> Vector2i:
	for _i in range(300):
		var c := r.position + Vector2i(rng.randi_range(0, r.size.x - 1), rng.randi_range(0, r.size.y - 1))
		if not is_blocked(c) and not is_town(c) and not is_dungeon(c) \
				and not find_path(tile_center(c), tile_center(SPAWN_CHECK_TILE)).is_empty():
			return c                           # reachable from town, not a walled-off pocket
	return r.get_center()


func is_blocked(c: Vector2i) -> bool:
	return not in_bounds(c) or tiles[c.y * cols + c.x] != Tile.GRASS


## Line of sight: no wall (or house wall) on the straight line between two points.
func line_clear(a: Vector3, b: Vector3) -> bool:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var steps := int(d.length() / 0.4) + 1
	for i in range(1, steps):
		var p := a.lerp(b, float(i) / steps)
		var t := tiles[clampi(floori(p.z / TILE), 0, rows - 1) * cols + clampi(floori(p.x / TILE), 0, cols - 1)]
		if t == Tile.WALL or t == Tile.HOUSE:
			return false
	return true


## Whether a body can walk straight from `a` to `b`: no blocked tile on the line, nor just to
## either side of it (so corners aren't clipped).
func walk_clear(a: Vector3, b: Vector3) -> bool:
	var d := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var length := d.length()
	if length < 0.01:
		return true
	var side := Vector3(-d.z, 0.0, d.x) / length * 0.28 * TILE
	var steps := int(length / (0.34 * TILE)) + 1
	for i in range(1, steps + 1):
		var p := a.lerp(b, float(i) / steps)
		if is_blocked(to_tile(p)) or is_blocked(to_tile(p + side)) or is_blocked(to_tile(p - side)):
			return false
	return true


func to_tile(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.z / TILE))


func tile_center(c: Vector2i) -> Vector3:
	var p := Vector3(c.x + 0.5, 0.0, c.y + 0.5) * TILE
	p.y = height_at(p)
	return p


# --- hills and hollows ---------------------------------------------------------------

## The land rises into hills out in the wilds (higher in the rocky country) and lies flat in the
## towns, the dungeon, by the water and beside walls, sloping gently between. Heights are kept
## at the tile corners and read smoothly in between.
const HILL_HEIGHT := 3.0
const HEIGHT_MAX := 4.0                 # the scale the height texture is stored at
var heights := PackedFloat32Array()     # (cols + 1) x (rows + 1) corner heights
var height_tex: ImageTexture
var _height_img: Image


func _build_heights() -> void:
	# how far (in tiles, up to 4) each tile is from anything that must stay flat
	var dist := PackedInt32Array()
	dist.resize(cols * rows)
	for y in range(rows):
		for x in range(cols):
			var c := Vector2i(x, y)
			var t := tiles[y * cols + x]
			var flat := is_town(c) or is_dungeon(c) or t == Tile.WATER or t == Tile.WALL or t == Tile.FORGE or t == Tile.HOUSE
			dist[y * cols + x] = 0 if flat else 99
	for _pass in range(4):
		for y in range(rows):
			for x in range(cols):
				var i := y * cols + x
				var best := dist[i]
				if x > 0:
					best = mini(best, dist[i - 1] + 1)
				if x < cols - 1:
					best = mini(best, dist[i + 1] + 1)
				if y > 0:
					best = mini(best, dist[i - cols] + 1)
				if y < rows - 1:
					best = mini(best, dist[i + cols] + 1)
				dist[i] = best
	var noise := FastNoiseLite.new()
	noise.seed = 99
	noise.frequency = 0.07
	noise.fractal_octaves = 3
	heights.resize((cols + 1) * (rows + 1))
	for j in range(rows + 1):
		for i in range(cols + 1):
			var d := 99
			var rocky := false
			for dy in [-1, 0]:
				for dx in [-1, 0]:
					var tx: int = i + dx
					var ty: int = j + dy
					if tx >= 0 and ty >= 0 and tx < cols and ty < rows:
						d = mini(d, dist[ty * cols + tx])
						rocky = rocky or tiles[ty * cols + tx] == Tile.ROCK
					else:
						d = 0                          # the map's edge stays low
			var mask := smoothstep(0.5, 4.0, float(d))
			var n := noise.get_noise_2d(i, j) * 0.5 + 0.5
			var h := maxf(n - 0.36, 0.0) / 0.64
			if rocky:
				h += 0.3                               # the rocky country stands higher
			heights[j * (cols + 1) + i] = clampf(h, 0.0, 1.0) * HILL_HEIGHT * mask
	_upload_heights()


func _upload_heights() -> void:
	if _height_img == null:
		_height_img = Image.create(cols + 1, rows + 1, false, Image.FORMAT_R8)
	for j in range(rows + 1):
		for i in range(cols + 1):
			_height_img.set_pixel(i, j, Color(clampf(heights[j * (cols + 1) + i] / HEIGHT_MAX, 0.0, 1.0), 0.0, 0.0))
	if height_tex == null:
		height_tex = ImageTexture.create_from_image(_height_img)
	else:
		height_tex.update(_height_img)


## The height of the land at `p` (read smoothly between tile corners).
func height_at(p: Vector3) -> float:
	if heights.is_empty():
		return 0.0
	var fx := p.x / TILE
	var fz := p.z / TILE
	var i0 := clampi(floori(fx), 0, cols - 1)
	var j0 := clampi(floori(fz), 0, rows - 1)
	var tx := clampf(fx - i0, 0.0, 1.0)
	var tz := clampf(fz - j0, 0.0, 1.0)
	var w := cols + 1
	var top := lerpf(heights[j0 * w + i0], heights[j0 * w + i0 + 1], tx)
	var bottom := lerpf(heights[(j0 + 1) * w + i0], heights[(j0 + 1) * w + i0 + 1], tx)
	return lerpf(top, bottom, tz)


## Levels the land under (and just round) a house, at the height of its middle.
func _flatten(r: Rect2i, h: float) -> void:
	for j in range(maxi(r.position.y - 1, 0), mini(r.end.y + 1, rows) + 1):
		for i in range(maxi(r.position.x - 1, 0), mini(r.end.x + 1, cols) + 1):
			heights[j * (cols + 1) + i] = h
	_upload_heights()


## Where a ray from the camera meets the land (hills included), or null.
func ray_ground(o: Vector3, d: Vector3) -> Variant:
	var step := 0.3
	var t := 0.0
	for _i in range(500):
		t += step
		var p := o + d * t
		if p.y <= height_at(p):
			var a := t - step
			var b := t
			for _k in range(10):
				var m := (a + b) / 2.0
				var q := o + d * m
				if q.y <= height_at(q):
					b = m
				else:
					a = m
			return o + d * b
		if p.y < -2.0:
			break
	return Plane(Vector3.UP, 0.0).intersects_ray(o, d)


## Waypoints (tile centres) from the tile under `from_p` to the tile under `to_p`,
## not including the start tile. Empty if the target is blocked or unreachable.
## With `avoid_town`, the path never enters a town (for monsters, which keep out of them).
## Someone already inside town may still path out of it.
func find_path(from_p: Vector3, to_p: Vector3, avoid_town := false) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a := to_tile(from_p)
	var b := to_tile(to_p)
	if is_blocked(a) or is_blocked(b) or a == b:
		return out
	if avoid_town and is_town(b):
		return out
	var grid := astar_outside if avoid_town and not is_town(a) else astar
	var ids := grid.get_id_path(a, b)
	if ids.size() > 1 and from_p.distance_to(tile_center(a)) > 0.05:
		out.append(tile_center(a))     # back onto the grid first, so no corner gets clipped
	for i in range(1, ids.size()):
		out.append(tile_center(ids[i]))
	return out


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


func _add(parent: Node3D, mesh: Mesh, mat: Material, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)


const CHUNK := 12                # tiles per side of a scenery chunk (each chunk is culled on its own)


## Draws `mesh` once per transform, each tinted by its colour (the material multiplies its vertex
## colours by the instance colour). The instances are split into square chunks of the map, one
## MultiMeshInstance3D each, so the renderer only draws the chunks the camera can see (one
## whole-map batch would always be drawn in full). Returns the chunks.
func _add_batch(parent: Node3D, mesh: Mesh, mat: Material, xforms: Array[Transform3D], tints: Array[Color]) -> Array:
	var groups := {}                     # chunk -> [transforms, tints]
	for i in range(xforms.size()):
		var o := xforms[i].origin
		var key := Vector2i(int(o.x / (TILE * CHUNK)), int(o.z / (TILE * CHUNK)))
		if not groups.has(key):
			groups[key] = [[], []]
		var g: Array = groups[key]
		(g[0] as Array).append(xforms[i])
		(g[1] as Array).append(tints[i])
	var out := []
	for key: Vector2i in groups:
		var g: Array = groups[key]
		var ts: Array[Transform3D] = []
		ts.assign(g[0])
		var cs: Array[Color] = []
		cs.assign(g[1])
		out.append(_add_chunk(parent, mesh, mat, ts, cs))
	return out


func _add_chunk(parent: Node3D, mesh: Mesh, mat: Material, xforms: Array[Transform3D], tints: Array[Color]) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, tints[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	parent.add_child(mmi)
	return mmi


## A tiling texture made from noise: smooth blobs (grass) or cells (cobbles, flagstones).
static func _noise_mat(colors: Array, freq: float, cellular: bool, uv_scale: Vector2) -> StandardMaterial3D:
	var noise := FastNoiseLite.new()
	noise.frequency = freq
	noise.seed = 7
	if cellular:
		noise.noise_type = FastNoiseLite.TYPE_CELLULAR
		noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	ramp.colors = PackedColorArray(colors)
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.noise = noise
	tex.color_ramp = ramp
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)
	m.roughness = 1.0
	return m


const WATER_SHADER := """
shader_type spatial;
uniform vec4 deep : source_color = vec4(0.12, 0.3, 0.56, 1.0);
uniform vec4 shallow : source_color = vec4(0.32, 0.58, 0.82, 1.0);
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// gentle swell: the surface rises and falls in slow, crossing waves
	VERTEX.y += (sin(wpos.x * 1.3 + TIME * 1.4) + sin(wpos.z * 1.1 - TIME * 1.1)) * 0.025;
}
void fragment() {
	float w = sin(wpos.x * 2.1 + TIME * 1.3) * 0.5 + sin(wpos.z * 1.7 - TIME * 1.1) * 0.5;
	float w2 = sin((wpos.x + wpos.z) * 3.3 - TIME * 1.9) * 0.5 + 0.5;
	float sparkle = pow(max(sin(wpos.x * 5.0 + wpos.z * 3.0 + TIME * 2.0), 0.0), 12.0)
		* pow(max(sin(wpos.x * 2.3 - wpos.z * 4.1 - TIME * 1.6), 0.0), 6.0);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);   // brighter towards the horizon
	ALBEDO = mix(deep.rgb, shallow.rgb, 0.45 + 0.25 * w + 0.1 * w2) + vec3(sparkle * 0.6) + shallow.rgb * rim * 0.35;
	ROUGHNESS = 0.15;
	SPECULAR = 0.75;
}
"""


## Leaves and grass that sway in the wind: vertex colour (with each instance's tint), the top of
## the plant swinging more than its base, each plant on its own beat.
const FOLIAGE_SHADER := """
shader_type spatial;
render_mode cull_disabled;
void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float h = max(VERTEX.y, 0.0);
	float sway = sin(TIME * 1.7 + o.x * 0.8 + o.z * 0.55) + 0.4 * sin(TIME * 3.1 + o.z * 1.3);
	VERTEX.x += sway * 0.035 * h * h;
	VERTEX.z += cos(TIME * 1.3 + o.x * 0.6) * 0.02 * h * h;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.9;
}
"""
static var _foliage: ShaderMaterial


static func _foliage_mat() -> ShaderMaterial:
	if _foliage == null:
		var sh := Shader.new()
		sh.code = FOLIAGE_SHADER
		_foliage = ShaderMaterial.new()
		_foliage.shader = sh
	return _foliage


func _next_to(t: Vector2i, kind: int) -> bool:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n := t + d
		if in_bounds(n) and tiles[n.y * cols + n.x] == kind:
			return true
	return false


## The ground, painted once: grass with meadows, sandy shores by the water, a dark forest floor
## under the trees and dirt roads between the towns and out to the dungeon, the graveyard, the
## orc fort and the western woods, all blending softly; a fine grain on top.
const GROUND_SHADER := """
shader_type spatial;
uniform sampler2D paint : source_color, filter_linear;
uniform sampler2D grain : filter_linear, repeat_enable;
uniform vec2 grain_scale = vec2(24.0, 12.0);
uniform sampler2D clouds : filter_linear, repeat_enable;
uniform float cloud_amount = 1.0;              // the shadows of clouds drifting over the land
uniform sampler2D heightmap : filter_linear;
uniform float hmax = 4.0;
uniform vec2 grid = vec2(96.0, 48.0);          // the map in tiles
uniform float tile = 1.0;

float land(vec2 uv) {
	return texture(heightmap, (uv * grid + 0.5) / (grid + 1.0)).r * hmax;
}

void vertex() {
	VERTEX.y += land(UV);                       // the hills
	vec2 e = vec2(1.0) / grid;
	float hx = land(UV + vec2(e.x, 0.0)) - land(UV - vec2(e.x, 0.0));
	float hz = land(UV + vec2(0.0, e.y)) - land(UV - vec2(0.0, e.y));
	NORMAL = normalize(vec3(-hx / (2.0 * tile), 1.0, -hz / (2.0 * tile)));   // lit as slopes
}

void fragment() {
	vec3 base = texture(paint, UV).rgb;
	float g = texture(grain, UV * grain_scale).r;
	float cl = texture(clouds, UV * vec2(3.0, 1.5) + TIME * vec2(0.006, 0.0035)).r;
	ALBEDO = base * (0.86 + 0.28 * g) * (1.0 - cloud_amount * 0.24 * smoothstep(0.52, 0.74, cl));
	ROUGHNESS = 1.0;
}
"""
const PAINT_PX := 4                     # painted pixels a tile (the grain adds the fine detail)
const ROAD_STOPS := [Vector2i(24, 11), Vector2i(36, 5), Vector2i(48, 33), Vector2i(35, 16),
	Vector2i(87, 34), Vector2i(87, 10), Vector2i(8, 30)]
const ROADS := [[0, 1], [0, 2], [0, 3], [2, 4], [1, 5], [0, 6]]   # pairs of ROAD_STOPS


func _ground_mat() -> ShaderMaterial:
	# weights per tile, sampled smoothly between tiles
	var road := PackedFloat32Array()
	var sand := PackedFloat32Array()
	var forest := PackedFloat32Array()
	road.resize(cols * rows)
	sand.resize(cols * rows)
	forest.resize(cols * rows)
	for pair in ROADS:
		var a: Vector2i = ROAD_STOPS[int(pair[0])]
		var b: Vector2i = ROAD_STOPS[int(pair[1])]
		for p in find_path(tile_center(a), tile_center(b)):
			var t := to_tile(p)
			road[t.y * cols + t.x] = 1.0
	for y in range(rows):
		for x in range(cols):
			var t := Vector2i(x, y)
			if tiles[y * cols + x] == Tile.WATER or _next_to(t, Tile.WATER):
				sand[y * cols + x] = 1.0
			if tiles[y * cols + x] == Tile.TREE:
				forest[y * cols + x] = 1.0
			elif _next_to(t, Tile.TREE):
				forest[y * cols + x] = 0.6
	var w := cols * PAINT_PX
	var h := rows * PAINT_PX
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var noise := FastNoiseLite.new()
	noise.seed = 21
	noise.frequency = 0.015
	var grass_a := Color("2c552f")
	var grass_b := Color("4a7a3c")
	var dirt := Color("7a6345")
	var sand_c := Color("b8a57a")
	var floor_c := Color("2a3a22")
	for py in range(h):
		var fy := (py + 0.5) / PAINT_PX - 0.5
		for px in range(w):
			var fx := (px + 0.5) / PAINT_PX - 0.5
			var n := noise.get_noise_2d(px, py) * 0.5 + 0.5
			var col := grass_a.lerp(grass_b, smoothstep(0.3, 0.8, n))
			col = col.lerp(floor_c, _sample(forest, fx, fy) * 0.75)
			col = col.lerp(sand_c, smoothstep(0.2, 0.9, _sample(sand, fx, fy)))
			col = col.lerp(dirt.lerp(dirt.darkened(0.15), n), smoothstep(0.25, 0.85, _sample(road, fx, fy)))
			img.set_pixel(px, py, col)
	var grain := NoiseTexture2D.new()
	grain.width = 128
	grain.height = 128
	grain.seamless = true
	var gn := FastNoiseLite.new()
	gn.frequency = 0.08
	grain.noise = gn
	var sh := Shader.new()
	sh.code = GROUND_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("paint", ImageTexture.create_from_image(img))
	m.set_shader_parameter("grain", grain)
	m.set_shader_parameter("grain_scale", Vector2(cols, rows) / 4.0)
	var clouds := NoiseTexture2D.new()
	clouds.width = 256
	clouds.height = 256
	clouds.seamless = true
	var cn := FastNoiseLite.new()
	cn.frequency = 0.012
	cn.fractal_octaves = 3
	clouds.noise = cn
	m.set_shader_parameter("clouds", clouds)
	m.set_shader_parameter("heightmap", height_tex)
	m.set_shader_parameter("hmax", HEIGHT_MAX)
	m.set_shader_parameter("grid", Vector2(cols, rows))
	m.set_shader_parameter("tile", TILE)
	ground_material = m
	return m


## A per-tile weight read smoothly at a fractional tile position (bilinear).
func _sample(grid: PackedFloat32Array, fx: float, fy: float) -> float:
	var x0 := clampi(floori(fx), 0, cols - 1)
	var y0 := clampi(floori(fy), 0, rows - 1)
	var x1 := mini(x0 + 1, cols - 1)
	var y1 := mini(y0 + 1, rows - 1)
	var tx := clampf(fx - x0, 0.0, 1.0)
	var ty := clampf(fy - y0, 0.0, 1.0)
	var top := lerpf(grid[y0 * cols + x0], grid[y0 * cols + x1], tx)
	var bottom := lerpf(grid[y1 * cols + x0], grid[y1 * cols + x1], tx)
	return lerpf(top, bottom, ty)


## The low-poly scenery pieces (flat-shaded, vertex-coloured, shared by every instance).
static func _wall_piece() -> ArrayMesh:
	var stone := Color(0.46, 0.47, 0.5)
	return Art.merge([[Art.box(TILE, 1.5, TILE), Art.at(0, 0.75, 0), stone],
		[Art.box(TILE * 1.02, 0.12, TILE * 1.02), Art.at(0, 1.55, 0), stone.lightened(0.18)],
		[Art.box(TILE * 1.01, 0.05, TILE * 1.01), Art.at(0, 0.5, 0), stone.darkened(0.15)],
		[Art.box(TILE * 1.01, 0.05, TILE * 1.01), Art.at(0, 1.0, 0), stone.darkened(0.15)],
		# battlements: a merlon on each corner, crenels between
		[Art.box(TILE * 0.3, 0.26, TILE * 0.3), Art.at(-TILE * 0.35, 1.74, -TILE * 0.35), stone.lightened(0.1)],
		[Art.box(TILE * 0.3, 0.26, TILE * 0.3), Art.at(TILE * 0.35, 1.74, -TILE * 0.35), stone.lightened(0.05)],
		[Art.box(TILE * 0.3, 0.26, TILE * 0.3), Art.at(-TILE * 0.35, 1.74, TILE * 0.35), stone.lightened(0.05)],
		[Art.box(TILE * 0.3, 0.26, TILE * 0.3), Art.at(TILE * 0.35, 1.74, TILE * 0.35), stone.lightened(0.1)]])


static func _pine() -> ArrayMesh:
	var bark := Color(0.38, 0.25, 0.13)
	var needles := Color(0.15, 0.36, 0.2)
	return Art.merge([[Art.cone(0.1, 0.6, 0.07, 6), Art.at(0, 0.3, 0), bark],
		[Art.cone(0.48, 0.65, 0.0, 7), Art.at(0, 0.8, 0), needles],
		[Art.cone(0.38, 0.55, 0.0, 7), Art.at(0, 1.15, 0), needles.lightened(0.08)],
		[Art.cone(0.26, 0.45, 0.0, 7), Art.at(0, 1.48, 0), needles.lightened(0.16)]])


static func _oak() -> ArrayMesh:
	var bark := Color(0.4, 0.27, 0.14)
	var leaves := Color(0.22, 0.45, 0.2)
	return Art.merge([[Art.cone(0.12, 0.75, 0.08, 6), Art.at(0, 0.37, 0), bark],
		[Art.ball(0.46, 7, 4), Art.at(0, 1.05, 0), leaves],
		[Art.ball(0.3, 6, 4), Art.at(0.22, 1.3, 0.1), leaves.lightened(0.1)],
		[Art.ball(0.28, 6, 4), Art.at(-0.2, 1.22, -0.12), leaves.darkened(0.08)]])


static func _rock_piece() -> ArrayMesh:
	var grey := Color(0.5, 0.48, 0.45)
	return Art.merge([[Art.ball(0.45, 6, 3), Art.at(0, 0.22, 0, Vector3.ZERO, Vector3(1, 0.7, 0.9)), grey],
		[Art.ball(0.25, 5, 3), Art.at(0.25, 0.35, 0.15, Vector3(0.4, 0.3, 0)), grey.lightened(0.1)],
		[Art.ball(0.18, 5, 3), Art.at(-0.22, 0.12, 0.25), grey.darkened(0.1)]])


static func _bush() -> ArrayMesh:
	var leaves := Color(0.2, 0.42, 0.2)
	return Art.merge([[Art.ball(0.32, 6, 4), Art.at(0, 0.24, 0, Vector3.ZERO, Vector3(1.1, 0.8, 1.0)), leaves],
		[Art.ball(0.22, 6, 3), Art.at(0.22, 0.2, 0.1), leaves.lightened(0.1)],
		[Art.ball(0.2, 6, 3), Art.at(-0.2, 0.18, -0.08), leaves.darkened(0.1)],
		[Art.ball(0.05, 4, 2), Art.at(0.1, 0.42, -0.12), Color(0.85, 0.2, 0.25)],      # a few berries
		[Art.ball(0.05, 4, 2), Art.at(-0.12, 0.36, 0.14), Color(0.85, 0.2, 0.25)]])


static func _pebbles() -> ArrayMesh:
	var grey := Color(0.56, 0.54, 0.5)
	return Art.merge([[Art.ball(0.1, 5, 3), Art.at(0, 0.04, 0, Vector3.ZERO, Vector3(1.2, 0.6, 1.0)), grey],
		[Art.ball(0.07, 5, 3), Art.at(0.14, 0.03, 0.06, Vector3.ZERO, Vector3(1.0, 0.6, 1.2)), grey.darkened(0.1)],
		[Art.ball(0.05, 4, 2), Art.at(-0.1, 0.02, 0.1), grey.lightened(0.1)]])


static func _tuft() -> ArrayMesh:
	var g := Color(0.3, 0.55, 0.26)
	return Art.merge([[Art.cone(0.05, 0.28, 0.0, 4), Art.at(0, 0.14, 0, Vector3(0.2, 0, 0.1)), g],
		[Art.cone(0.05, 0.22, 0.0, 4), Art.at(0.08, 0.11, 0.04, Vector3(-0.2, 0, -0.3)), g.lightened(0.1)],
		[Art.cone(0.05, 0.25, 0.0, 4), Art.at(-0.07, 0.12, -0.05, Vector3(0.1, 0, 0.35)), g.darkened(0.1)]])


static func _flower() -> ArrayMesh:
	return Art.merge([[Art.box(0.02, 0.22, 0.02), Art.at(0, 0.11, 0), Color(0.25, 0.5, 0.22)],
		[Art.ball(0.06, 5, 3), Art.at(0, 0.24, 0), Color(1, 1, 1)],
		[Art.box(0.02, 0.16, 0.02), Art.at(0.12, 0.08, 0.06), Color(0.25, 0.5, 0.22)],
		[Art.ball(0.05, 5, 3), Art.at(0.12, 0.17, 0.06), Color(1, 1, 1)]])


## Builds the 3D scenery as children of `parent`: noise-textured ground and paving, then every
## wall, tree, rock and pool in batches (one MultiMesh per kind, each instance a little turned,
## sized and tinted), plus grass tufts and flowers for detail.
func build(parent: Node3D) -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 4242                        # the same forest every time
	_build_heights()
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(cols, rows) * TILE
	ground_mesh.subdivide_width = cols * 2 - 1        # two quads a tile, to carry the hills
	ground_mesh.subdivide_depth = rows * 2 - 1
	_add(parent, ground_mesh, _ground_mat(), Vector3(cols, 0.0, rows) * TILE / 2.0)
	for r in TOWNS:
		_add_floor(parent, r, Color("8a7f5a"),
			_noise_mat([Color("a49678"), Color("8c7f63"), Color("5a5142")], 0.04, true, Vector2(r.size) / 3.0))
	_add_floor(parent, DUNGEON, Color("2b2622"),
		_noise_mat([Color("3a342d"), Color("2a2521"), Color("141210")], 0.04, true, Vector2(DUNGEON.size) / 3.0))

	var forge_mesh := BoxMesh.new()
	forge_mesh.size = Vector3(0.9, 0.8, 0.9)
	var coals_mesh := BoxMesh.new()
	coals_mesh.size = Vector3(0.6, 0.08, 0.6)
	var coals_mat := _mat(Color(1.0, 0.45, 0.1))
	coals_mat.emission_enabled = true
	coals_mat.emission = Color(1.0, 0.4, 0.05)
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(TILE, TILE)
	water_mesh.subdivide_width = 2                 # a few vertices to carry the swell
	water_mesh.subdivide_depth = 2
	var water_mat := ShaderMaterial.new()
	var water_shader := Shader.new()
	water_shader.code = WATER_SHADER
	water_mat.shader = water_shader

	var walls: Array[Transform3D] = []
	var wall_tints: Array[Color] = []
	var waters: Array[Transform3D] = []
	var water_tints: Array[Color] = []
	var pines: Array[Transform3D] = []
	var pine_tints: Array[Color] = []
	var oaks: Array[Transform3D] = []
	var oak_tints: Array[Color] = []
	var rocks: Array[Transform3D] = []
	var rock_tints: Array[Color] = []
	var tufts: Array[Transform3D] = []
	var tuft_tints: Array[Color] = []
	var flowers: Array[Transform3D] = []
	var flower_tints: Array[Color] = []
	var petals := [Color(0.95, 0.9, 0.3), Color(0.95, 0.95, 0.95), Color(0.85, 0.35, 0.6), Color(0.55, 0.6, 1.0)]
	for y in range(rows):
		for x in range(cols):
			var t := Vector2i(x, y)
			var c := tile_center(t)
			var turn := Basis(Vector3.UP, rnd.randf() * TAU)
			var v := rnd.randf_range(0.88, 1.1)
			match tiles[y * cols + x]:
				Tile.WALL:
					walls.append(Transform3D(Basis(), c))
					var k := v * (0.62 if is_dungeon(t) else 1.0)   # the dungeon's stone is darker
					wall_tints.append(Color(k, k, k))
				Tile.WATER:
					waters.append(Transform3D(Basis(), c + Vector3(0, 0.02, 0)))
					water_tints.append(Color.WHITE)
				Tile.TREE:
					var size := rnd.randf_range(0.85, 1.25)
					var tint := Color(v * rnd.randf_range(0.92, 1.05), v, v * rnd.randf_range(0.9, 1.0))
					if (x * 7 + y * 13) % 5 < 2:
						pines.append(Transform3D(turn.scaled(Vector3(size, size * rnd.randf_range(0.9, 1.15), size)), c))
						pine_tints.append(tint)
					else:
						oaks.append(Transform3D(turn.scaled(Vector3.ONE * size), c))
						oak_tints.append(tint)
				Tile.ROCK:
					var size := rnd.randf_range(0.8, 1.15)
					rocks.append(Transform3D(turn.scaled(Vector3(size, size * rnd.randf_range(0.75, 1.0), size)), c))
					rock_tints.append(Color(v, v * 0.98, v * 0.95))
				Tile.FORGE:
					_add(parent, forge_mesh, _mat(COLORS[Tile.FORGE]), c + Vector3(0, 0.4, 0))
					_add(parent, coals_mesh, coals_mat, c + Vector3(0, 0.84, 0))
					var forge_fire := Fx.flame(0.45, 18, 0.7)    # the forge's fire
					forge_fire.position = c + Vector3(0, 0.9, 0)
					parent.add_child(forge_fire)
					forge_fire.add_to_group("view_fx")      # only burns while on screen
					var forge_smoke := Fx.smoke(10, 1.2)
					forge_smoke.position = c + Vector3(0, 1.3, 0)
					parent.add_child(forge_smoke)
					forge_smoke.add_to_group("view_fx")
				Tile.GRASS:
					if is_town(t) or is_dungeon(t):
						continue
					var roll := rnd.randf()
					var off := Vector3(rnd.randf_range(-0.35, 0.35), 0, rnd.randf_range(-0.35, 0.35))
					if roll < 0.1:
						tufts.append(Transform3D(turn.scaled(Vector3.ONE * rnd.randf_range(0.8, 1.3)), c + off))
						tuft_tints.append(Color(v, v, v))
					elif roll < 0.13:
						flowers.append(Transform3D(turn, c + off))
						flower_tints.append(petals[rnd.randi() % petals.size()])
	# Bushes at the forest edges and pebbles across the fields.
	var bushes: Array[Transform3D] = []
	var bush_tints: Array[Color] = []
	var pebbles: Array[Transform3D] = []
	var pebble_tints: Array[Color] = []
	for y in range(rows):
		for x in range(cols):
			var t := Vector2i(x, y)
			if tiles[y * cols + x] != Tile.GRASS or is_town(t) or is_dungeon(t):
				continue
			var off := Vector3(rnd.randf_range(-0.3, 0.3), 0, rnd.randf_range(-0.3, 0.3))
			if _next_to(t, Tile.TREE) and rnd.randf() < 0.3:
				var k := rnd.randf_range(0.7, 1.2)
				bushes.append(Transform3D(Basis(Vector3.UP, rnd.randf() * TAU).scaled(Vector3(k, k * rnd.randf_range(0.8, 1.1), k)), tile_center(t) + off))
				bush_tints.append(Color(rnd.randf_range(0.85, 1.05), rnd.randf_range(0.9, 1.08), rnd.randf_range(0.85, 1.0)))
			elif rnd.randf() < 0.04:
				pebbles.append(Transform3D(Basis(Vector3.UP, rnd.randf() * TAU).scaled(Vector3.ONE * rnd.randf_range(0.6, 1.2)), tile_center(t) + off))
				var g := rnd.randf_range(0.85, 1.1)
				pebble_tints.append(Color(g, g, g * 0.97))
	var vc := Art.vc_mat()
	var leafy := _foliage_mat()                 # trees, bushes, grass and flowers sway in the wind
	_add_batch(parent, _wall_piece(), vc, walls, wall_tints)
	_add_batch(parent, water_mesh, water_mat, waters, water_tints)
	_add_batch(parent, _pine(), leafy, pines, pine_tints)
	_add_batch(parent, _oak(), leafy, oaks, oak_tints)
	_add_batch(parent, _rock_piece(), vc, rocks, rock_tints)
	decor = _add_batch(parent, _tuft(), leafy, tufts, tuft_tints) + _add_batch(parent, _flower(), leafy, flowers, flower_tints) \
		+ _add_batch(parent, _bush(), leafy, bushes, bush_tints) + _add_batch(parent, _pebbles(), vc, pebbles, pebble_tints)
