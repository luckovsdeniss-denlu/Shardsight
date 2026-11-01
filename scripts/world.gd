class_name World
## Tile map: ASCII layout, collision lookup and A* pathfinding.
## Legend: . grass   # wall   ~ water   T tree. Only grass is walkable.

const TILE := 96
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


func pixel_size() -> Vector2:
	return Vector2(cols, rows) * TILE


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < cols and c.y < rows


## Collision: anything that is not grass, and everything outside the map, blocks.
func is_blocked(c: Vector2i) -> bool:
	return not in_bounds(c) or tiles[c.y * cols + c.x] != Tile.GRASS


func to_tile(p: Vector2) -> Vector2i:
	return Vector2i((p / float(TILE)).floor())


func tile_center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * TILE


## Waypoints (tile centres) from the tile under `from_px` to the tile under `to_px`,
## not including the start tile. Empty if the target is blocked or unreachable.
func find_path(from_px: Vector2, to_px: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var a := to_tile(from_px)
	var b := to_tile(to_px)
	if is_blocked(a) or is_blocked(b) or a == b:
		return out
	var ids := astar.get_id_path(a, b)
	for i in range(1, ids.size()):
		out.append(tile_center(ids[i]))
	return out


func draw_tiles(canvas: CanvasItem) -> void:
	for y in range(rows):
		for x in range(cols):
			var t: int = tiles[y * cols + x]
			var r := Rect2(Vector2(x, y) * TILE, Vector2(TILE, TILE))
			canvas.draw_rect(r, COLORS[t])
			canvas.draw_rect(r, Color(0, 0, 0, 0.15), false, 1.0)
			if t == Tile.TREE:
				canvas.draw_rect(Rect2(r.position + Vector2(40, 54), Vector2(16, 30)), Color("5a3d1e"))
				canvas.draw_circle(r.position + Vector2(48, 38), 30.0, Color("1d4a22"))
