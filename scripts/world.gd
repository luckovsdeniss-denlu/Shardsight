class_name World
## Tile map: ASCII layout, collision lookup, A* pathfinding and 3D mesh building.
## Tile (x, y) maps to world (x, 0, y): the map lies on the XZ plane.
## Legend: . grass   # wall   ~ water   T tree (wood)   R rock (ore)   F forge.
## Only grass is walkable.

const TILE := 1.0  # one tile = one metre in 3D
enum Tile { GRASS, WALL, WATER, TREE, ROCK, FORGE, HOUSE }

## The guarded towns: no player-versus-player here, and guards strike down criminals,
## murderers and monsters on sight. Everything else is open wilderness.
const TOWNS := [Rect2i(19, 2, 11, 12), Rect2i(33, 2, 9, 6)]   # the main town and the outpost
## The dungeon: dark halls in the east with the toughest monsters. You can't Mark a rune here.
const DUNGEON := Rect2i(37, 11, 13, 11)

const LAYOUT := [
	"####################################################",
	"#..............................#...................#",
	"#..............................#...................#",
	"#..TT....T.......RR.#########..#............TT.....#",
	"#..T................#.......#...............T......#",
	"#.............TT....#F......#......................#",
	"#..............T....#.......#..#................TT.#",
	"#...................#.......#..#.......RR..........#",
	"#.R.................#.......#..#...................#",
	"#.RR................####.####..#...................#",
	"#..............................#....################",
	"#..............................#....#.....#.......##",
	"#.............##TT.#####.......#.T..#.....#.......##",
	"#..............................#.T..#.....#.......##",
	"#......~~~~~R..................#....#.....#...#...##",
	"#.....~~~~~~~.........TT.......#....#.....#...#...##",
	"#.....~~~~~~~..........T..................#...#...##",
	"#......~~~~~........................#.....#...#...##",
	"#..............................#....#.....#...#...##",
	"#.T.......................TT...#....#.........#...##",
	"#.TT.....RR....................#....#.........#...##",
	"#..........................RR..#....#.........#...##",
	"#...........................R..#....################",
	"####################################################",
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
var astar_outside := AStarGrid2D.new()   # same grid, but the guarded town is walled off
var forge_tile := Vector2i(-1, -1)
var house_nodes := {}            # house origin -> Node3D holding its meshes
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
# A house is 3x3: walls all round, one tile inside (with the chest) and a door below it.

func house_tiles(o: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dy in range(3):
		for dx in range(3):
			out.append(o + Vector2i(dx, dy))
	return out


func house_wall_tiles(o: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in house_tiles(o):
		var rel := c - o
		if rel != Vector2i(1, 1) and rel != Vector2i(1, 2):
			out.append(c)
	return out


## Free grass outside town, nobody standing on it, and open ground in front of the door.
func can_place_house(o: Vector2i, occupied: Dictionary) -> bool:
	for c in house_tiles(o):
		if is_blocked(c) or is_town(c) or occupied.has(c):
			return false
	var outside := o + Vector2i(1, 3)
	return not is_blocked(outside) and not is_town(outside)


func place_house(parent: Node3D, o: Vector2i) -> void:
	for c in house_wall_tiles(o):
		tiles[c.y * cols + c.x] = Tile.HOUSE
		astar.set_point_solid(c, true)
		astar_outside.set_point_solid(c, true)
	var node := Node3D.new()
	parent.add_child(node)
	house_nodes[o] = node
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(TILE, 1.4, TILE)
	var wall_mat := _mat(COLORS[Tile.HOUSE])
	for c in house_wall_tiles(o):
		_add(node, wall_mesh, wall_mat, tile_center(c) + Vector3(0, 0.7, 0))
	var chest_mesh := BoxMesh.new()
	chest_mesh.size = Vector3(0.5, 0.4, 0.35)
	_add(node, chest_mesh, _mat(Color("6b4423")), tile_center(o + Vector2i(1, 1)) + Vector3(0, 0.2, -0.25))


func remove_house(o: Vector2i) -> void:
	for c in house_wall_tiles(o):
		tiles[c.y * cols + c.x] = Tile.GRASS
		astar.set_point_solid(c, false)
		astar_outside.set_point_solid(c, is_town(c))
	if house_nodes.has(o):
		var node: Node3D = house_nodes[o]
		node.queue_free()
		house_nodes.erase(o)


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
func find_house_spot(near: Vector2i, occupied: Dictionary, radius := 6) -> Vector2i:
	var base := reachable_count(near, {})
	for r in range(radius + 1):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var o := near + Vector2i(dx, dy) - Vector2i(1, 1)
				if not can_place_house(o, occupied):
					continue
				var walls := {}
				for c in house_wall_tiles(o):
					walls[c] = true
				if reachable_count(near, walls) == base - walls.size():
					return o
	return Vector2i(-1, -1)


## A flat coloured patch over a rectangle of tiles (town paving, dungeon floor).
func _add_floor(parent: Node3D, r: Rect2i, color: Color) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(r.size) * TILE
	_add(parent, mesh, _mat(color),
		Vector3(r.position.x + r.size.x / 2.0, 0.01, r.position.y + r.size.y / 2.0) * TILE)


func is_blocked(c: Vector2i) -> bool:
	return not in_bounds(c) or tiles[c.y * cols + c.x] != Tile.GRASS


func to_tile(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.z / TILE))


func tile_center(c: Vector2i) -> Vector3:
	return Vector3(c.x + 0.5, 0.0, c.y + 0.5) * TILE


## Waypoints (tile centres) from the tile under `from_p` to the tile under `to_p`,
## not including the start tile. Empty if the target is blocked or unreachable.
## With `avoid_town`, the path never enters the guarded town (for monsters and outlaws, whom
## the guards would kill). Someone already inside town may still path out of it.
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


## Builds the 3D scenery as children of `parent`.
func build(parent: Node3D) -> void:
	var ground_mesh := PlaneMesh.new()
	ground_mesh.size = Vector2(cols, rows) * TILE
	_add(parent, ground_mesh, _mat(COLORS[Tile.GRASS]),
		Vector3(cols, 0.0, rows) * TILE / 2.0)

	for r in TOWNS:
		_add_floor(parent, r, Color("8a7f5a"))
	_add_floor(parent, DUNGEON, Color("2b2622"))

	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(TILE, 1.6, TILE)
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(TILE, TILE)
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.08
	trunk_mesh.bottom_radius = 0.12
	trunk_mesh.height = 0.7
	var crown_mesh := SphereMesh.new()
	crown_mesh.radius = 0.42
	crown_mesh.height = 0.84
	var wall_mat := _mat(COLORS[Tile.WALL])
	var water_mat := _mat(COLORS[Tile.WATER])
	var trunk_mat := _mat(Color("5a3d1e"))
	var crown_mat := _mat(Color("1d4a22"))
	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 0.48
	rock_mesh.height = 0.7
	var rock_mat := _mat(COLORS[Tile.ROCK])
	var forge_mesh := BoxMesh.new()
	forge_mesh.size = Vector3(0.9, 0.8, 0.9)
	var coals_mesh := BoxMesh.new()
	coals_mesh.size = Vector3(0.6, 0.08, 0.6)
	var coals_mat := _mat(Color(1.0, 0.45, 0.1))
	coals_mat.emission_enabled = true
	coals_mat.emission = Color(1.0, 0.4, 0.05)

	for y in range(rows):
		for x in range(cols):
			var c := tile_center(Vector2i(x, y))
			match tiles[y * cols + x]:
				Tile.WALL:
					_add(parent, wall_mesh, wall_mat, c + Vector3(0, 0.8, 0))
				Tile.WATER:
					_add(parent, water_mesh, water_mat, c + Vector3(0, 0.02, 0))
				Tile.TREE:
					_add(parent, trunk_mesh, trunk_mat, c + Vector3(0, 0.35, 0))
					_add(parent, crown_mesh, crown_mat, c + Vector3(0, 1.0, 0))
				Tile.ROCK:
					_add(parent, rock_mesh, rock_mat, c + Vector3(0, 0.3, 0))
				Tile.FORGE:
					_add(parent, forge_mesh, _mat(COLORS[Tile.FORGE]), c + Vector3(0, 0.4, 0))
					_add(parent, coals_mesh, coals_mat, c + Vector3(0, 0.84, 0))
