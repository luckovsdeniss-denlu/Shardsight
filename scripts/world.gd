class_name World
## Tile map: ASCII layout, collision lookup, A* pathfinding and 3D mesh building.
## Tile (x, y) maps to world (x, 0, y): the map lies on the XZ plane.
## Legend: . grass   # wall   ~ water   T tree. Only grass is walkable.

const TILE := 1.0  # one tile = one metre in 3D
enum Tile { GRASS, WALL, WATER, TREE }

const LAYOUT := [
	"################################",
	"#..............................#",
	"#..............................#",
	"#..TT....T..........#########..#",
	"#..T................#.......#..#",
	"#.............TT....#.......#..#",
	"#..............T....#.......#..#",
	"#...................#.......#..#",
	"#...................#.......#..#",
	"#...................####.####..#",
	"#..............................#",
	"#..............................#",
	"#.............##TT.#####.......#",
	"#..............................#",
	"#......~~~~~...................#",
	"#.....~~~~~~~.........TT.......#",
	"#.....~~~~~~~..........T.......#",
	"#......~~~~~...................#",
	"#..............................#",
	"#.T.......................TT...#",
	"#.TT...........................#",
	"#..............................#",
	"#..............................#",
	"################################"
]
const COLORS := {
	Tile.GRASS: Color("2f5d34"),
	Tile.WALL: Color("6b6f7a"),
	Tile.WATER: Color("2a5f9e"),
	Tile.TREE: Color("2f5d34"),
}

var cols := 0
var rows := 0
var tiles: Array[int] = []
var astar := AStarGrid2D.new()


func _init() -> void:
	rows = LAYOUT.size()
	cols = String(LAYOUT[0]).length()
	tiles.resize(cols * rows)
	for y in range(rows):
		for x in range(cols):
			tiles[y * cols + x] = _parse(String(LAYOUT[y])[x])
	astar.region = Rect2i(0, 0, cols, rows)
	astar.cell_size = Vector2(TILE, TILE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	for y in range(rows):
		for x in range(cols):
			if is_blocked(Vector2i(x, y)):
				astar.set_point_solid(Vector2i(x, y), true)


static func _parse(ch: String) -> int:
	match ch:
		"#":
			return Tile.WALL
		"~":
			return Tile.WATER
		"T":
			return Tile.TREE
		_:
			return Tile.GRASS


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


## Collision: anything that is not grass, and everything outside the map, blocks.
func is_blocked(c: Vector2i) -> bool:
	return not in_bounds(c) or tiles[c.y * cols + c.x] != Tile.GRASS


func to_tile(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.z / TILE))


func tile_center(c: Vector2i) -> Vector3:
	return Vector3(c.x + 0.5, 0.0, c.y + 0.5) * TILE


## Waypoints (tile centres) from the tile under `from_p` to the tile under `to_p`,
## not including the start tile. Empty if the target is blocked or unreachable.
func find_path(from_p: Vector3, to_p: Vector3) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var a := to_tile(from_p)
	var b := to_tile(to_p)
	if is_blocked(a) or is_blocked(b) or a == b:
		return out
	var ids := astar.get_id_path(a, b)
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
