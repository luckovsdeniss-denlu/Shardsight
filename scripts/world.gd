class_name World
## Tile map: ASCII layout, collision lookup, A* pathfinding and 3D mesh building.
## Tile (x, y) maps to world (x, 0, y): the map lies on the XZ plane.
## Legend: . grass   # wall   ~ water   T tree (wood)   R rock (ore)   F forge.
## Only grass is walkable.

const TILE := 1.0  # one tile = one metre in 3D
enum Tile { GRASS, WALL, WATER, TREE, ROCK, FORGE, HOUSE }

## The towns: safe zones where nobody can be hurt and nobody can attack out of; monsters keep
## out of them. Everything else is open wilderness.
const TOWNS := [Rect2i(27, 2, 11, 12), Rect2i(106, 46, 9, 6), Rect2i(44, 30, 12, 9), Rect2i(104, 8, 11, 9), Rect2i(96, 100, 11, 9),
	Rect2i(7, 90, 11, 9), Rect2i(39, 102, 11, 9), Rect2i(80, 75, 11, 9), Rect2i(124, 44, 11, 9)]   # the main town, the outpost, Southmoor
## The dungeon: dark halls on the western shore of the great lake, with the toughest monsters. You can't Mark a rune here.
const DUNGEON := Rect2i(4, 67, 13, 11)
## Biomes: the frozen north, the desert of the south-east and the swamp round the southern lake.
## Each tints the land and has its own creatures (see Frontier).
## A biome can have more than one region: "snow_east" is snow, named on its own (the part before
## the "_" is the kind).
const BIOMES := {"snow": Rect2i(52, 1, 30, 9), "desert": Rect2i(56, 37, 39, 10), "swamp": Rect2i(24, 33, 19, 14), "ash": Rect2i(122, 1, 21, 16),
	"snow_east": Rect2i(118, 72, 24, 22), "desert_south": Rect2i(110, 110, 32, 24), "swamp_south": Rect2i(2, 104, 36, 22),
	"ash_south": Rect2i(40, 124, 30, 18)}
const BIOME_NAMES := {"snow": "the Frostmarch", "desert": "the Sunscar Wastes", "swamp": "the Blackwater Fen", "ash": "the Ashlands",
	"snow_east": "the Whitepeaks", "desert_south": "the Dunes of Kesh", "swamp_south": "the Reedmarsh", "ash_south": "the Cinderfields"}
## Caves: walled hollows with one way in, dark floors, rich ore and their own dwellers.
const CAVES := [
	{"name": "Frostfang Cavern", "rect": Rect2i(52, 3, 9, 7), "door": Vector2i(56, 9), "out": Vector2i(56, 10)},
	{"name": "Scorpion Hollow", "rect": Rect2i(60, 38, 9, 7), "door": Vector2i(64, 38), "out": Vector2i(64, 37)},
	{"name": "Goblin Warren", "rect": Rect2i(3, 39, 9, 7), "door": Vector2i(11, 42), "out": Vector2i(12, 42)},
	{"name": "Icejaw Grotto", "rect": Rect2i(128, 82, 9, 7), "door": Vector2i(132, 88), "out": Vector2i(132, 89)},     # the Whitepeaks
	{"name": "Tomb of Kesh", "rect": Rect2i(126, 117, 9, 7), "door": Vector2i(130, 123), "out": Vector2i(130, 124)},  # the Dunes
	{"name": "Bonedeep Hollow", "rect": Rect2i(62, 92, 9, 7), "door": Vector2i(66, 98), "out": Vector2i(66, 99)},     # the middle south
]
## The guild towers out in the wilds (each stands on one solid tile).
## Ravenhollow Cemetery, the walled graveyard in the far south, below Highmoor, where the restless dead walk.
const CEMETERY := Rect2i(98, 127, 12, 13)
const CEMETERY_NAME := "Ravenhollow Cemetery"
## The church, far in the south-west below the Reedmarsh: stone walls, a door to the north, the
## altar within.
const CHURCH := Rect2i(10, 126, 6, 7)
const CHURCH_DOORS := [Vector2i(12, 126), Vector2i(13, 126)]
const TOWER_TILES := [Vector2i(60, 22), Vector2i(35, 28), Vector2i(10, 26), Vector2i(30, 100), Vector2i(110, 60), Vector2i(120, 128)]

const LAYOUT := [
	"################################################################################################################################################",
	"#......................................#...........#.......TT......T..T.....................T..................T............T....T...........R.#",
	"#......................................#.....................T..........T.........###########......T.......T......T......................T.....#",
	"#..TT....T...............RR.#########..#....TT....................................#.........#.................................R.RR.....R..R.TT.#",
	"#..T........................#.......#.......T.....................................#.........#........T..T...............T.......R......TTRT..T.#",
	"#.............TT............#F......#................................R............#.........#.............T....................RTR.......TRR.T.#",
	"#..............T............#.......#..#........TT............T...............T...#.........#............T..T......R...........RR.R.....RTRT...#",
	"#...........................#.......#..#......................................T..T#.........#.................................T.....R..R...TT..#",
	"#.R.........................#.......#..#...........#.............R......~......T..#.........#.................................R...........R....#",
	"#.RR........................####.####..#...........#.................~~~~~~~......####...####..........................................R.......#",
	"#......................................#..........................T.~~~~~~~~~.....T.................T................................RT.T......#",
	"#......................................#......................TT...~~~~~~~~~~~.............T........................................R...R......#",
	"#...............T........T..........................................~~~~~~~~~.T..........................................T.......R.............#",
	"#.............................................................T......~~~~~~~......T.......R..........................T............R.T.RR.......#",
	"#......~~~~~R....................................................R......~.R.............R...........T.R..............................TTT......T#",
	"#.....~~~~~~~.........TT....................................T...T................................T.....R...........................T...T.......#",
	"#.....~~~~~~~..........T....................................T....T.TT.R................T...T..........R................................T.....T.#",
	"#......~~~~~..................................................T..T...................T...............T..R.......T.........T............T.......#",
	"#............................................................TT...T..............................R....R.T...................T..................#",
	"#.T.......................TT...........................T..T..TT.TT............T................................................................#",
	"#.TT.....RR...................................................T.TTTT......T.......................T............................................#",
	"#..........................RR................................T..TT.T...........................................................................#",
	"#...........................R.........................T.......................................................T.......................R........#",
	"####....############.........................................................................................................................T.#",
	"#...........................................................................................T.........................................T........#",
	"#........TT.......TT.....T............R.........................................T....T........................T................................#",
	"#.T..........T..TT..........T..R.............................T...........T................................R................R...................#",
	"#.........T...TTT...........T.T...............................................................T.............................T..................#",
	"#........T....T.TT.......T...........................................T......T............................R...............T.....T...............#",
	"#.T.............T..T..........T..........................TT.T......T...................................................RR..TT.T................#",
	"#..............T............T......RR................................................................................T~...R...T.T...T..........#",
	"#..........T.TT..T.T..TT..T.T.T...................................................................................~~~~~~~~~..TTTTT.............#",
	"#..TT.TT.TTT..TTTT.....T.TT........................................T......T................................T....~~~~~~~~~~~~~...R...T......T...#",
	"#....TTTTT....T.T.......TTT......................##.....T.......................................................~~~~~~~~~~~~~....T...T.........#",
	"#.....TTT.....T..T.......T.......................##............................................................~~~~~~~~~~~~~~~.................#",
	"#.....T.T..TT......T.........T.....R........................T...................................................~~~~~~~~~~~~~T..TT.............#",
	"#..TTT...........T....T..T..T.......~.....................................T..........................RR..R.....R~~~~~~~~~~~~~...T..............#",
	"#...T.T......TT...T.T.TTTTT..T....~~~~~......................T.........T.T.......................T.R..............~~~~~~~~~...T..TT............#",
	"#.T.................T..T.T.T..T..~~~~~~~.......................RR....R.....R....R.........................T......R....~.......TT....T..........#",
	"#.TTT....T......T....TT.....T...~~~~~~~~~........................R..R..R....R...R............................................TT..TT.........T..#",
	"#..T...............T.....TT.TT...~~~~~~~............................R...RRR.R.............................................T..T.................#",
	"#..T..T........T.T............T...~~~~~.......................T..R.R........R...R..........T........T.........................T.........T.T....#",
	"#......T.T........T.........TTT.....~......................T.....R.R.R........R.R........................T...............T....TT.........TTR...#",
	"#.........T.T...T...........................................................RR............................................................T....#",
	"#...............TTT.T.......T.....................................RR......................................................................T....#",
	"#..T.......TTT.......................................................R......R..T.......................................................T.......#",
	"#.....................................................................RR......................................................................T#",
	"#.............................R........................................................................T.......................................#",
	"#..........................................T.T................T...................................R............................................#",
	"#.........................................T...R.......T..............T.........................................................................#",
	"#....................R..................R..R....R...TTTTTTT........R...R...............................R..............T.T..............T.......#",
	"#.........T...........T.....................R.R...T.....T.......T.......T....................T........RT...............TTT.....................#",
	"#.........T...........................T........RR...T..T...T.T..T....T.................................R.............TTTTT.T...................#",
	"#........T...TT................................R.T...T.T....RT...................T.................T...................TT.TT................R..#",
	"#.........TT..T.T..............T.T............R.....T...T.TTTT......R.............T........T..........................TTT............R.........#",
	"#.......TTT..TT...................................TRTT...TTTTR.R............T...............T.............T....R........T.TT.T.................#",
	"#.......TT.T.TTT................................~..TT.....TRT......................................T......T...........T...T........R.....T.....#",
	"#..........TT.TTT..........T...........~~~~~~~~~~~~~~~~~~~TTRT..T...........RT.T.......................R..............R..T.....................#",
	"#.........TT...T.......T.....R.....~~~~~~~~~~~~~~~~~~~~~~~~~~~.....................R....................T......................................#",
	"#.T.....TTTT.T.TT.....TT..T..T...~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............TTTT......T..T..T...R.......T.............R.......................#",
	"#T........T..T.T......TT.T.....~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..........TTTTT.....TTT..T.....T.T...................R.........T.............#",
	"#.........TT..T.....T..TTTTT.~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....T.TTTTTTT.T..TTTT.T..T..TT....................RR...T.........TT.......#",
	"#......T.TT.T..T.T......TTTT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.......TTTTT...TT.TTT....T.TTTT...........................................#",
	"#.....................TTTTT~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............TT...TTTT....TTT..T................RT..............T........#",
	"#......................TTT~~~~~~~~~~~~~~...T..T...TT..RTT~~~~~~~~~~~~~~........R....T.T.T.....T..T...T...............TRR.......................#",
	"#.....................T..~~~~~~~~~~~~....T...R.......TTTTTTT~~~~~~~~~~~~........T..RTTT.TT.T.TTTT..TT..........................T.............T.#",
	"#..################....T.~~~~~~~~~~...........R....T.######TTT~~~~~~~~~~............T.T..T..T..TT.T....T.................T....T.........T......#",
	"#..#.....#.......##......~~~~~~~~~...T.......T.....R.#....#TTTT~~~~~~~~~..............T..T....TTTTTT..T................TT......TT............T.#",
	"#..#.....#.......##....T~~~~~~~~~~..........T.............#TRTT~~~~~~~~~~...............T.T..TTTTTTTT.TT.TT..R............T...TTT..............#",
	"#..#.....#.......##......~~~~~~~~~~T...TT.R.T......R.#....#TTT~~~~~~~~~~....................TT..TTTTTTTT..................TTT.TTT.T............#",
	"#..#.....#...#...##......~~~~~~~~~~~~T....T..........######T~~~~~~~~~~~~.....T..............T..TTTTTTTTTT..............T.......T.......T.TT....#",
	"#..#.....#...#...##......~~~~~~~~~~~~~~~....TT...........~~~~~~~~~~~~~~~.....T...................TTTTTTTTTT..........T....TTTTT..T....T.TTTTT.T#",
	"#........#...#...##.......~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~......T.................T...TTTTTT.T..............RT.T....TT...T....T...#",
	"#..#.....#...#...##........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....T....T.................TTTTTTT.................T...T.T...T.....TTT..#",
	"#..#.....#...#...##.........~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.....T.............T........TTTTT..........T...........T....T...T..TT...T.#",
	"#..#.........#...##.......T..~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~...................................T..T..............T....T...T..TT.TT.T...#",
	"#..#.........#...##............~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.............................T.......TT......................TTT..TTTTTT..T..#",
	"#..#.........#...##..............~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~..T......................................T.....................T.....TTT.T.....#",
	"#..################.............R..~~~~~~~~~~~~~~~~~~~~~~~~~~~.......T.......................T.............................T.........T...T.....#",
	"#..################....................~~~~~~~~~~~~~~~~~~~.T...........T....................................................T............TT....#",
	"#.........................R.....................~......R................................................................................T...T..#",
	"#...........................................T.....................R........................................................R...................#",
	"#......T.T..............T.R......................................R.............................T...........T...................................#",
	"#.T...................RR........................................RRR.........................................R..................................#",
	"#......................RRR..................................................R..................................................................#",
	"#.............T.....R.R.R...................................R..................................................................................#",
	"#.........T.........R........R.....................................T.............T............................T...RR...........................#",
	"#.......................R............................................T..........................................~............T.................#",
	"#..............R.........................T......T.............T.............................................~~~~~~~~~..........................#",
	"#..........T..............................................................................................~~~~~~~~~~~~~T....................R..#",
	"#...................................R...........T.....................T..........R.......................~~~~~~~~~~~~~~~...T...........T.......#",
	"#..................................T........................................T............................~~~~~~~~~~~~~~~..T.....R..............#",
	"#.......................................................................................................~~~~~~~~~~~~~~~~~............T.........#",
	"#.....R..............R......T..T.......................T.................................................~~~~~~~~~~~~~~~.......................#",
	"#...R............................................T.......................................................~~~~~~~~~~~~~~~.......................#",
	"#...T.....................T................................R..................R...........................~~~~~~~~~~~~~T.......................#",
	"#.........................................T..............................................................T..~~~~~~~~~..........................#",
	"#.................................T........................T.................................................TTT~..T...T.......................#",
	"#...........................................T..T...........T................................................RTTTT.TT.........................T.#",
	"#..............................................T.............................T...............................TTTT..............................#",
	"#............................................................T....T.............R..T..T......R...............T.T..T.T.............TTT..........#",
	"#..............T...................T..........T..T.....R.T....T..............T..T....T.T........................T...R..........................#",
	"#..................T..............T................T......R.......RT....T.....T..TT....T....T...................TT.T......T.....T..T...........#",
	"#....................T...............................RR.TR.T...........T.....TTT.............T..................T................T.T..T........#",
	"#.....................................R.......................T.......R.......T..TTT.................................T...........T.....T.......#",
	"#.R...T.........................T....................................T..TTTT.T...T.T...T.......T.............T..R............T.......TT....T...#",
	"#..R..............T.R...R............................R.RR.R.T.........T.T......TT....TT............................R...........................#",
	"#.......T........T.................................RRTR.................TTT.......T...T................................T.......................#",
	"#....................................................RR...R........R.....T..T....T..T..................................................R.......#",
	"#.................................T.................T...................T..........T................T.........T...........RR...................#",
	"#T............................T....................T....................T...T..........................................................T.T.....#",
	"#...................~......R....TT..T.T...........R....R............................................RR.........................................#",
	"#T......T.......~~~~~~~~~.......TT....................T..R..................T...T..............T.R.R...R.....................R...............RT#",
	"#..............~~~~~~~~~~~.....T..TTT....................................T........................R............................................#",
	"#.............~~~~~~~~~~~~~...T.T..T....................................R.............T...........R..........T.................................#",
	"#....T........~~~~~~~~~~~~~..R..T.....................T.....................R...T..................R...................................TR......#",
	"#......R.....~~~~~~~~~~~~~~~.....T...T............T..........................TT.............R..................................................#",
	"#.............~~~~~~~~~~~~~.....................................................T...........TT..T....T..........T...T...T......................#",
	"#.T..........T~~~~~~~~~~~~~...........................T.................T...T.T.T.T.............TT......................R......................#",
	"#..............~~~~~~~~~~~.................T..T....T..R.................TTTTTTT...T.......T.......TT................T.T.TT.T.................T.#",
	"#...............~~~~~~~~~..............................................TT........T..T........TTT.T..T..............TT..TTT.....................#",
	"#.................R.~...............T.....................T...........TTTT..T.T............T.T.....T..................TTT......................#",
	"#.........................................TT.........................TTTTTT....TTTTTTT.....T.T..T......................TT.T....................#",
	"#...............R..................T..T..........................R...TTTTTT.R....TTT~......T.TT.TT.T.....................T..T..................#",
	"#......................................TT......T.........T............RTTTT....~~~~~~~~~~~TT...T.TT..T...............T..T.T....................#",
	"#..............................R....T...TT...TTT.TT.T................TTTTTTT.~~~~~~~~~~~~~~~T.......TT.............................T...........#",
	"#.................T............T.....TTTT...........T..T..............TT..T.~~~~~~~~~~~~~~~~~...T...............R..............................#",
	"#....T.................T.............T.TT......TTTT......................T..~~~~~~~~~~~~~~~~~...T.############...T...R.........................#",
	"#....................................T.....T..TTT.................T........~~~~~~~~~~~~~~~~~~~.T..#..........#.......R................T........#",
	"#...........................T..................TTTTT.T......................~~~~~~~~~~~~~~~~~.....#..........#.................................#",
	"#....T........................................TT......T...............T...T.~~~~~~~~~~~~~~~~~T....#..#..#..#.#.....................T...........#",
	"#.................................T...........TTTT...........................~~~~~~~~~~~~~~~......#..........#...T...TT...............T..R.....#",
	"#T...T.T.....................T................TTTT..T........T.................~~~~~~~~~~~...R...............#.....T..TR..................RR...#",
	"#..............................................T.....................T..............~.......R................#...T.TT..T...T...T....R......R...#",
	"#..T.T........T.................................T.......................................R...T...R............#....TTT.TTTTT..........R.....T..R#",
	"#............................T.....................T......................R....T........RRR....T..#..........#.TTTTTTTTT..T....R.........R.R...#",
	"#..T.........T............T..................T..............R....................T........T....R..#..#..#..#.#...TTTTTTTT.TTRT.................#",
	"#................................................T...........R..T.......R......T...RT.....T.......#..........#...TTTTTTT...T...................#",
	"#...................T..T................................R...R................T......R.........R...#..........#....T..TTT.......................#",
	"#....................................................T.........R.......................T..........############.T...T.TTT................R......#",
	"#.........T......................................................................T.....................................T.T..........T.T........#",
	"#............................................TT.................................................T.................R...T..T.....................#",
	"#............................................T........T............................................T..........T.......T........................#",
	"################################################################################################################################################",
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
var ground_mesh: PlaneMesh            # the land (finer on Medium and High graphics)
var ground_material: ShaderMaterial    # the painted ground (its cloud shadows follow the weather)
var dungeon_floor_mat: StandardMaterial3D   # tinted by the depth you have gone down to
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
	_stamp_caves()
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


## Carves the caves into the map: a ring of rock wall with one opening, an open floor inside
## with ore at its corners. The guild towers' tiles are made solid too.
func _stamp_caves() -> void:
	for cave in CAVES:
		var r: Rect2i = cave["rect"]
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var edge := x == r.position.x or y == r.position.y or x == r.end.x - 1 or y == r.end.y - 1
				tiles[y * cols + x] = Tile.WALL if edge else Tile.GRASS
		for corner in [Vector2i(1, 1), Vector2i(r.size.x - 2, 1), Vector2i(1, r.size.y - 2), Vector2i(r.size.x - 2, r.size.y - 2)]:
			var c: Vector2i = r.position + corner
			tiles[c.y * cols + c.x] = Tile.ROCK
		var door: Vector2i = cave["door"]
		var out: Vector2i = cave["out"]
		tiles[door.y * cols + door.x] = Tile.GRASS
		tiles[out.y * cols + out.x] = Tile.GRASS
	for t in TOWER_TILES:
		tiles[t.y * cols + t.x] = Tile.WALL
	for y in range(CHURCH.position.y, CHURCH.end.y):
		for x in range(CHURCH.position.x, CHURCH.end.x):
			var rim := x == CHURCH.position.x or y == CHURCH.position.y or x == CHURCH.end.x - 1 or y == CHURCH.end.y - 1
			tiles[y * cols + x] = Tile.WALL if rim else Tile.GRASS
	for d in CHURCH_DOORS:
		tiles[d.y * cols + d.x] = Tile.GRASS


func in_church(c: Vector2i) -> bool:
	return CHURCH.has_point(c)


## The Isle of Tides lies across the sea to the south, reached only by ship.
const ISLAND := Rect2i(30, 62, 36, 12)     # the isle, in the middle of the Tidewater
const ISLAND_NAME := "the Isle of Tides"


func on_island(c: Vector2i) -> bool:
	return ISLAND.has_point(c)


func is_cave(c: Vector2i) -> bool:
	return cave_at(c) >= 0


## Which cave (index into CAVES) a tile is in, or -1.
func cave_at(c: Vector2i) -> int:
	for i in range(CAVES.size()):
		if (CAVES[i]["rect"] as Rect2i).has_point(c):
			return i
	return -1


## The biome a tile lies in ("snow", "desert", "swamp"), or "" for the green lands.
func biome_at(c: Vector2i) -> String:
	return biome_key_at(c).get_slice("_", 0)


## Which biome region a tile lies in ("snow", "snow_east", ...), or "".
func biome_key_at(c: Vector2i) -> String:
	if is_town(c) or is_dungeon(c):
		return ""
	for k in BIOMES:
		if (BIOMES[k] as Rect2i).has_point(c):
			return String(k)
	return ""


## How much of a biome a tile has: 1 inside, fading to 0 three tiles out (for soft edges).
func biome_weight(c: Vector2i, k: String) -> float:
	if is_town(c):
		return 0.0
	var best := 0.0
	for key in BIOMES:
		if String(key).get_slice("_", 0) != k:
			continue
		var r: Rect2i = BIOMES[key]
		var dx := maxi(maxi(r.position.x - c.x, c.x - (r.end.x - 1)), 0)
		var dy := maxi(maxi(r.position.y - c.y, c.y - (r.end.y - 1)), 0)
		best = maxf(best, clampf(1.0 - Vector2(dx, dy).length() / 3.0, 0.0, 1.0))
	return best


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


const TOWN_NAMES := ["town", "the outpost", "Southmoor", "Dawnport", "Highmoor", "Westford", "Reedwick", "Midmark", "Stormhold"]   # same order as TOWNS


## A rough name for where a tile is: a town, the dungeon or the wilds.
func place_name(c: Vector2i) -> String:
	for i in range(TOWNS.size()):
		if (TOWNS[i] as Rect2i).has_point(c):
			return TOWN_NAMES[i]
	if is_dungeon(c):
		return "the dungeon"
	if on_island(c):
		return ISLAND_NAME
	if CEMETERY.has_point(c):
		return CEMETERY_NAME
	var cv := cave_at(c)
	if cv >= 0:
		return String(CAVES[cv]["name"])
	var bk := biome_key_at(c)
	if bk != "":
		return String(BIOME_NAMES[bk])
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
const ZONE_COLS := 6
const ZONE_ROWS := 6
const SPAWN_CHECK_TILE := Vector2i(32, 11)   # in the main town, by the healer


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
	var steps := int(d.length() / 0.2) + 1
	var last := Vector2i(-1, -1)
	for i in range(1, steps):
		var p := a.lerp(b, float(i) / steps)
		var c := Vector2i(clampi(floori(p.x / TILE), 0, cols - 1), clampi(floori(p.z / TILE), 0, rows - 1))
		var t := tiles[c.y * cols + c.x]
		if t == Tile.WALL or t == Tile.HOUSE:
			return false
		if last.x >= 0 and c.x != last.x and c.y != last.y:   # a diagonal step: both corner tiles count
			var t1 := tiles[last.y * cols + c.x]
			var t2 := tiles[c.y * cols + last.x]
			if (t1 == Tile.WALL or t1 == Tile.HOUSE) and (t2 == Tile.WALL or t2 == Tile.HOUSE):
				return false
		last = c
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
			var flat := is_town(c) or is_dungeon(c) or is_cave(c) or in_church(c) or t == Tile.WATER or t == Tile.WALL or t == Tile.FORGE or t == Tile.HOUSE
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


## Two quads a tile for smooth hills, or one on Low graphics (a quarter of the triangles).
func set_ground_detail(fine: bool) -> void:
	if ground_mesh == null:
		return
	var per := 1                               # (the land is big now: one quad a tile carries the hills well enough)
	if fine and cols * rows <= 8000:
		per = 2
	ground_mesh.subdivide_width = cols * per - 1
	ground_mesh.subdivide_depth = rows * per - 1


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
uniform vec4 deep : source_color = vec4(0.05, 0.15, 0.24, 1.0);
uniform vec4 shallow : source_color = vec4(0.16, 0.36, 0.42, 1.0);
uniform float veil = 0.0;               // the Shardveil: water that glows violet and teal
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
	// dark, deep water with soft ripples; the sky's pale light along the far edge; fewer, finer glints
	ALBEDO = mix(deep.rgb, shallow.rgb, 0.3 + 0.2 * w + 0.08 * w2) + vec3(sparkle * 0.3) + vec3(0.55, 0.65, 0.72) * rim * 0.4;
	if (veil > 0.0) {
		vec3 glow = mix(vec3(0.32, 0.06, 0.48), vec3(0.08, 0.6, 0.62), 0.5 + 0.5 * w);
		ALBEDO = mix(ALBEDO, glow * 0.6 + vec3(sparkle * 0.5), veil);
		EMISSION = glow * (0.35 + 0.4 * w2) * veil;
	}
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
}
"""


## Richer graphics: walls laid in courses of stone - each block its own shade, the mortar between
## them dark - on their sides; their tops plain.
const MASONRY_SHADER := """
shader_type spatial;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 uv = abs(wn.x) > 0.5 ? wp.zy : wp.xy;
	uv *= vec2(2.6, 4.4);
	float row = floor(uv.y);
	uv.x += mod(row, 2.0) * 0.5;
	vec2 f = fract(uv);
	float mortar = smoothstep(0.0, 0.07, f.x) * smoothstep(1.0, 0.93, f.x) * smoothstep(0.0, 0.11, f.y) * smoothstep(1.0, 0.89, f.y);
	float hsh = fract(sin(dot(floor(uv), vec2(12.9898, 78.233))) * 43758.5453);
	vec3 col = COLOR.rgb * (0.84 + 0.26 * hsh) * mix(0.55, 1.0, mortar);
	if (abs(wn.y) > 0.6) {
		col = COLOR.rgb * (0.92 + 0.1 * hsh);
	}
	ALBEDO = col;
	ROUGHNESS = 0.93;
}
"""
## Richer graphics: windows in the town walls - dark glass and a wooden frame by day, a warm glow
## of lamplight at night (`glow` follows the dark).
const WINDOW_SHADER := """
shader_type spatial;
uniform float glow = 0.0;
void fragment() {
	vec2 u = UV;
	float bar = step(abs(u.x - 0.5), 0.045) + step(abs(u.y - 0.45), 0.04);
	float edge = step(u.x, 0.09) + step(0.91, u.x) + step(u.y, 0.08) + step(0.9, u.y);
	float frame = clamp(bar + edge, 0.0, 1.0);
	vec3 glass = mix(vec3(0.1, 0.12, 0.16), vec3(1.0, 0.72, 0.38), glow);
	ALBEDO = mix(glass, vec3(0.24, 0.15, 0.08), frame);
	EMISSION = (1.0 - frame) * vec3(1.0, 0.62, 0.26) * glow * 2.4;
	ROUGHNESS = mix(0.25, 0.8, frame);
}
"""
var window_mat: ShaderMaterial          # (richer graphics) the windows' shared glass: lit at night
var water_material: ShaderMaterial      # the lakes' shared water


## The other dimension (the Shardveil) over the land: 0 the world as it is, 1 all the way there -
## the ground violet with veins of light, the trees and grass glassy teal and glowing, the water
## glowing violet and teal.
func set_veil(v: float) -> void:
	if ground_material != null:
		ground_material.set_shader_parameter("veil", v)
	_foliage_mat().set_shader_parameter("veil", v)
	if water_material != null:
		water_material.set_shader_parameter("veil", v)
var _masonry_mat: ShaderMaterial
var _plain_wall_mat: Material
var _wall_chunks: Array = []
var _window_chunks: Array = []


## The richer graphics on or off while the game runs (a trailer shows them off): the walls' stone
## courses, the town windows and the ground's fine grain.
func set_rich(on: bool) -> void:
	for n in _wall_chunks:
		if is_instance_valid(n):
			(n as GeometryInstance3D).material_override = _masonry_mat if on else _plain_wall_mat
	for n in _window_chunks:
		if is_instance_valid(n):
			(n as Node3D).visible = on
	if ground_material != null:
		ground_material.set_shader_parameter("detail", 1.0 if on else 0.0)


## Richer graphics: now and then a window on the open side of a straight run of town wall - a
## pane in the wall's face at a little above head height (never at a corner or an end).
func _add_windows(t: Vector2i, c: Vector3, out: Array[Transform3D]) -> void:
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n := t + d
		if not in_bounds(n) or tiles[n.y * cols + n.x] != Tile.GRASS:
			continue
		var side := Vector2i(d.y, d.x)                 # along the wall
		var a := t + side
		var b := t - side
		if not (in_bounds(a) and in_bounds(b) and tiles[a.y * cols + a.x] == Tile.WALL and tiles[b.y * cols + b.x] == Tile.WALL):
			continue
		if (t.x * 31 + t.y * 17 + d.x * 7 + d.y * 3) % 4 != 0:
			continue
		var out_dir := Vector3(d.x, 0.0, d.y)
		out.append(Transform3D(Basis.looking_at(-out_dir, Vector3.UP), c + out_dir * (TILE * 0.51) + Vector3(0.0, 0.85, 0.0)))


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
uniform vec3 season_tint = vec3(1.0);
uniform float frost = 0.0;
uniform float veil = 0.0;                      // the Shardveil: leaves of glassy teal and violet, glowing
void fragment() {
	vec3 a = mix(COLOR.rgb * season_tint, vec3(0.88, 0.92, 0.96), frost * smoothstep(0.2, 0.8, NORMAL.y * 0.5 + 0.5));
	if (veil > 0.0) {
		vec3 crystal = a.gbr * vec3(0.7, 1.15, 1.45) + vec3(0.03, 0.06, 0.14);
		a = mix(a, crystal, veil);
		EMISSION = crystal * 0.35 * veil;
	}
	ALBEDO = a;
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
uniform vec3 season_tint = vec3(1.0);          // the seasons: golden summer, russet autumn...
uniform float veil = 0.0;                      // the Shardveil: the land in violet, veins of light through it
uniform float snow = 0.0;                      // ...and winter's snow, lying on the flatter ground
uniform float detail = 0.0;                    // richer graphics: a finer grain, and the light catching it
varying float up;

float land(vec2 uv) {
	return texture(heightmap, (uv * grid + 0.5) / (grid + 1.0)).r * hmax;
}

void vertex() {
	VERTEX.y += land(UV);                       // the hills
	vec2 e = vec2(1.0) / grid;
	float hx = land(UV + vec2(e.x, 0.0)) - land(UV - vec2(e.x, 0.0));
	float hz = land(UV + vec2(0.0, e.y)) - land(UV - vec2(0.0, e.y));
	NORMAL = normalize(vec3(-hx / (2.0 * tile), 1.0, -hz / (2.0 * tile)));   // lit as slopes
	up = NORMAL.y;
}

void fragment() {
	vec3 base = texture(paint, UV).rgb;
	float g = texture(grain, UV * grain_scale).r;
	float cl = texture(clouds, UV * vec2(3.0, 1.5) + TIME * vec2(0.006, 0.0035)).r;
	vec3 col = base * season_tint * (0.8 + 0.4 * g);
	col *= mix(0.72, 1.0, smoothstep(0.86, 0.995, up));   // slopes fall into shade: the hills get weight
	float cover = snow * smoothstep(0.35, 0.75, g * 0.6 + snow * 0.6) * smoothstep(0.8, 0.97, up);
	col = mix(col, vec3(0.9, 0.93, 0.97) * (0.92 + 0.12 * g), cover);
	if (detail > 0.0) {
		// a second, finer grain - blades, grit and pebbles - and its little bumps catching the sun
		vec2 duv = UV * grain_scale * 5.0;
		float d1 = texture(grain, duv).r;
		float dx = texture(grain, duv + vec2(0.02, 0.0)).r - d1;
		float dz = texture(grain, duv + vec2(0.0, 0.02)).r - d1;
		col *= mix(1.0, 0.82 + 0.36 * d1, detail);
		NORMAL_MAP = normalize(vec3(-dx * 7.0, -dz * 7.0, 1.0)) * 0.5 + 0.5;
		NORMAL_MAP_DEPTH = detail;
	}
	if (veil > 0.0) {
		float vein = 1.0 - smoothstep(0.0, 0.04, abs(g - 0.5));   // thin veins along the grain's middle
		col = mix(col, col * vec3(0.62, 0.52, 0.95) + vec3(0.04, 0.0, 0.08), veil);
		EMISSION = vec3(0.75, 0.35, 1.0) * vein * veil * 0.9;
	}
	ALBEDO = col * (1.0 - cloud_amount * 0.24 * smoothstep(0.52, 0.74, cl));
	ROUGHNESS = 1.0;
}
"""
const PAINT_PX := 3                     # painted pixels a tile (the grain adds the fine detail)
const ROAD_STOPS := [Vector2i(32, 11), Vector2i(109, 49), Vector2i(48, 33), Vector2i(2, 72),
	Vector2i(103, 133), Vector2i(87, 10), Vector2i(8, 30), Vector2i(109, 12), Vector2i(101, 104),
	Vector2i(31, 102), Vector2i(110, 62), Vector2i(120, 126), Vector2i(20, 110), Vector2i(132, 90), Vector2i(67, 100),
	Vector2i(12, 94), Vector2i(44, 106), Vector2i(85, 79), Vector2i(129, 48), Vector2i(12, 124), Vector2i(89, 86)]
## pairs of ROAD_STOPS: the old lands, and out to the towers, lakes and caves of the south and east
const ROADS := [[0, 1], [0, 2], [0, 3], [8, 4], [1, 5], [0, 6], [5, 7], [2, 8],
	[8, 9], [9, 12], [7, 10], [10, 8], [8, 11], [10, 13], [8, 14],
	[15, 6], [15, 12], [16, 9], [16, 14], [17, 2], [17, 8], [17, 10], [18, 7], [18, 10], [16, 19], [12, 19], [17, 20]]   # and the four new towns


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
	var snow := PackedFloat32Array()
	var desert := PackedFloat32Array()
	var swamp := PackedFloat32Array()
	var ash := PackedFloat32Array()
	ash.resize(cols * rows)
	snow.resize(cols * rows)
	desert.resize(cols * rows)
	swamp.resize(cols * rows)
	for y in range(rows):
		for x in range(cols):
			var t := Vector2i(x, y)
			snow[y * cols + x] = biome_weight(t, "snow")
			desert[y * cols + x] = biome_weight(t, "desert")
			swamp[y * cols + x] = biome_weight(t, "swamp")
			ash[y * cols + x] = biome_weight(t, "ash")
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
	# an earthier palette: olive and moss rather than bright green, worn earth, pale dry sand
	var grass_a := Color("2f4a2a")
	var grass_b := Color("5c6e3c")
	var dirt := Color("6e5a42")
	var sand_c := Color("a89a78")
	var floor_c := Color("26301f")
	var snow_c := Color("dfe6ee")
	var desert_c := Color("c9aa70")
	var swamp_c := Color("33422a")
	var ash_c := Color("3f3a38")
	for py in range(h):
		await _breathe(0.2 + 0.5 * float(py) / h)        # painting the land: the longest part
		var fy := (py + 0.5) / PAINT_PX - 0.5
		for px in range(w):
			var fx := (px + 0.5) / PAINT_PX - 0.5
			var n := noise.get_noise_2d(px, py) * 0.5 + 0.5
			var col := grass_a.lerp(grass_b, smoothstep(0.3, 0.8, n))
			col = col.lerp(floor_c, _sample(forest, fx, fy) * 0.75)
			col = col.lerp(swamp_c.lerp(swamp_c.darkened(0.3), n), _sample(swamp, fx, fy) * 0.85)
			col = col.lerp(desert_c.lerp(desert_c.darkened(0.12), n), _sample(desert, fx, fy))
			col = col.lerp(snow_c.lerp(snow_c.darkened(0.1), n), _sample(snow, fx, fy))
			col = col.lerp(ash_c.lerp(Color("6a3324"), smoothstep(0.62, 0.9, n)), _sample(ash, fx, fy))   # grey ash veined with embers
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
	m.set_shader_parameter("detail", 1.0 if Art.rich else 0.0)
	ground_material = m
	return m


## Trees take on their biome's colour: frosted in the snow, dry in the desert, dark in the swamp.
static func _biome_tint(b: String) -> Color:
	match b:
		"snow":
			return Color(0.85, 0.95, 1.1)
		"desert":
			return Color(1.05, 0.9, 0.6)
		"swamp":
			return Color(0.7, 0.8, 0.6)
		"ash":
			return Color(0.42, 0.36, 0.34)
	return Color.WHITE


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
## Builds the land, a slice at a time: between slices it hands back a frame (so the loading
## screen keeps moving) and reports how far it has got (0..1) through `progress`.
var _progress := Callable()
var _tree: SceneTree


func _report(frac: float) -> void:
	if _progress.is_valid():
		_progress.call(frac)


## Hands back a frame if this slice has run long enough (about 1/30 s), so nothing stalls.
var _slice_from := 0


func _breathe(frac: float) -> void:
	if _tree == null or Time.get_ticks_msec() - _slice_from < 33:
		return
	_report(frac)
	await _tree.process_frame
	_slice_from = Time.get_ticks_msec()


func build(parent: Node3D, progress := Callable()) -> void:
	_progress = progress
	_tree = parent.get_tree()
	_slice_from = Time.get_ticks_msec()
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 4242                        # the same forest every time
	_build_heights()
	await _breathe(0.15)
	ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(cols, rows) * TILE
	ground_mesh.subdivide_width = cols - 1            # a quad a tile, to carry the hills
	ground_mesh.subdivide_depth = rows - 1
	var gm: ShaderMaterial = await _ground_mat()
	_add(parent, ground_mesh, gm, Vector3(cols, 0.0, rows) * TILE / 2.0)
	for r in TOWNS:
		_add_floor(parent, r, Color("8a7f5a"),
			_noise_mat([Color("a49678"), Color("8c7f63"), Color("5a5142")], 0.04, true, Vector2(r.size) / 3.0))
	dungeon_floor_mat = _noise_mat([Color("3a342d"), Color("2a2521"), Color("141210")], 0.04, true, Vector2(DUNGEON.size) / 3.0)
	_add_floor(parent, DUNGEON, Color("2b2622"), dungeon_floor_mat)

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
	water_material = water_mat
	var water_shader := Shader.new()
	water_shader.code = WATER_SHADER
	water_mat.shader = water_shader

	var walls: Array[Transform3D] = []
	var wall_tints: Array[Color] = []
	var windows: Array[Transform3D] = []
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
		await _breathe(0.72 + 0.2 * float(y) / rows)     # trees, rocks, water and walls
		for x in range(cols):
			var t := Vector2i(x, y)
			var c := tile_center(t)
			var turn := Basis(Vector3.UP, rnd.randf() * TAU)
			var v := rnd.randf_range(0.88, 1.1)
			match tiles[y * cols + x]:
				Tile.WALL:
					walls.append(Transform3D(Basis(), c))
					if is_town(t):
						_add_windows(t, c, windows)
					var k := v * (0.62 if is_dungeon(t) else 1.0)   # the dungeon's stone is darker
					wall_tints.append(Color(k, k, k))
				Tile.WATER:
					waters.append(Transform3D(Basis(), c + Vector3(0, 0.02, 0)))
					water_tints.append(Color.WHITE)
				Tile.TREE:
					var size := rnd.randf_range(0.85, 1.25)
					var tint := Color(v * rnd.randf_range(0.92, 1.05), v, v * rnd.randf_range(0.9, 1.0))
					tint *= _biome_tint(biome_at(t))
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
					if is_town(t) or is_dungeon(t) or is_cave(t) or in_church(t):
						continue
					var bio := biome_at(t)
					if bio == "snow" or bio == "ash" or (bio == "desert" and rnd.randf() < 0.7):
						continue                       # no grass in the snow; little in the sand
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
	# the caves: dark rock floors and a dim glow of crystals
	for cave in CAVES:
		var cr: Rect2i = cave["rect"]
		var inner := Rect2i(cr.position + Vector2i(1, 1), cr.size - Vector2i(2, 2))
		_add_floor(parent, inner, Color("2b2724"),
			_noise_mat([Color("3a3530"), Color("26221e"), Color("121010")], 0.05, true, Vector2(inner.size) / 3.0))
		var glow := OmniLight3D.new()
		glow.light_color = Color(0.55, 0.75, 1.0)
		glow.omni_range = 5.0
		glow.light_energy = 0.8
		glow.position = tile_center(Vector2i(cr.get_center())) + Vector3(0, 1.6, 0)
		parent.add_child(glow)
	var vc := Art.vc_mat()
	var leafy := _foliage_mat()                 # trees, bushes, grass and flowers sway in the wind
	# the walls (in stone courses when the graphics are richer) and the town windows (only then)
	var msh := Shader.new()
	msh.code = MASONRY_SHADER
	_masonry_mat = ShaderMaterial.new()
	_masonry_mat.shader = msh
	_plain_wall_mat = vc
	_wall_chunks = _add_batch(parent, _wall_piece(), _masonry_mat if Art.rich else vc, walls, wall_tints)
	var wsh := Shader.new()
	wsh.code = WINDOW_SHADER
	window_mat = ShaderMaterial.new()
	window_mat.shader = wsh
	var pane := QuadMesh.new()
	pane.size = Vector2(0.3, 0.42)
	var wt: Array[Color] = []
	for _w in windows:
		wt.append(Color.WHITE)
	_window_chunks = _add_batch(parent, pane, window_mat, windows, wt)
	for n in _window_chunks:
		(n as Node3D).visible = Art.rich
	_add_batch(parent, water_mesh, water_mat, waters, water_tints)
	_add_batch(parent, _pine(), leafy, pines, pine_tints)
	_add_batch(parent, _oak(), leafy, oaks, oak_tints)
	_add_batch(parent, _rock_piece(), vc, rocks, rock_tints)
	decor = _add_batch(parent, _tuft(), leafy, tufts, tuft_tints) + _add_batch(parent, _flower(), leafy, flowers, flower_tints) \
		+ _add_batch(parent, _bush(), leafy, bushes, bush_tints) + _add_batch(parent, _pebbles(), vc, pebbles, pebble_tints)
