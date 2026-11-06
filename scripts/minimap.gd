class_name Minimap
extends Control
## A small overhead map: terrain, towns, the dungeon, houses, and everyone as dots
## (you in white, pets green, monsters and murderers red, criminals grey, other players blue,
## NPCs cream).

const MAX_WIDTH := 240.0         # the bigger the map, the smaller each tile on the minimap
var px := 4.0
const COLORS := {
	World.Tile.GRASS: Color(0.20, 0.36, 0.22),
	World.Tile.WALL: Color(0.45, 0.46, 0.50),
	World.Tile.WATER: Color(0.20, 0.40, 0.70),
	World.Tile.TREE: Color(0.10, 0.25, 0.12),
	World.Tile.ROCK: Color(0.50, 0.47, 0.42),
	World.Tile.FORGE: Color(1.00, 0.50, 0.15),
	World.Tile.HOUSE: Color(0.65, 0.48, 0.35),
}

var game
var world: World
var _timer := 0.0
var _terrain: ImageTexture       # the map itself, drawn once (and again when a house changes it)
var _revision := -1


## Paints the terrain into a small image, one pixel per tile, scaled up when drawn.
func _bake_terrain() -> void:
	var img := Image.create(world.cols, world.rows, false, Image.FORMAT_RGBA8)
	for y in range(world.rows):
		for x in range(world.cols):
			var c := Vector2i(x, y)
			var t: int = world.tiles[y * world.cols + x]
			var col: Color = COLORS.get(t, Color(0, 0, 0))
			if t == World.Tile.GRASS and world.is_town(c):
				col = Color(0.55, 0.50, 0.36)
			elif t == World.Tile.GRASS and world.is_dungeon(c):
				col = Color(0.17, 0.15, 0.14)
			col.a = 0.85
			img.set_pixel(x, y, col)
	_terrain = ImageTexture.create_from_image(img)
	_revision = world.revision


func setup(p_game, p_world: World) -> void:
	game = p_game
	world = p_world
	px = minf(4.0, MAX_WIDTH / float(world.cols))
	custom_minimum_size = Vector2(world.cols, world.rows) * px
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp tiles when the baked map is scaled up
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = 0.25
		queue_redraw()


func _draw() -> void:
	if world == null:
		return
	if _terrain == null or _revision != world.revision:
		_bake_terrain()
	draw_texture_rect(_terrain, Rect2(Vector2.ZERO, custom_minimum_size), false)
	var list: Array = game.creatures
	for item in list:
		var e := item as Entity
		if e.dead and not e.ghost:
			continue
		var p := Vector2(e.position.x, e.position.z) / World.TILE * px
		draw_circle(p, 3.0 if e.is_hero else 2.0, _dot_color(e))


func _dot_color(e: Entity) -> Color:
	if e.is_hero:
		return Color.WHITE
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
