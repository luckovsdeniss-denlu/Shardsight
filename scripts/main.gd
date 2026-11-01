extends Node2D
## Tap or drag to walk. The world is a tile map; blocked tiles (walls, water, trees)
## are routed around with A*, and taps on blocked tiles are ignored.

const SPEED := 5.0 * World.TILE  # pixels per second

var version: String = ProjectSettings.get_setting("application/config/version", "dev")
var world := World.new()
var hero := Hero.new()
var pos := Vector2.ZERO
var path: Array[Vector2] = []
var held := false
var cam := Camera2D.new()
var hud := Label.new()


func _ready() -> void:
	pos = world.tile_center(Vector2i(5, 5))
	var size := world.pixel_size()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(size.x)
	cam.limit_bottom = int(size.y)
	add_child(cam)
	var layer := CanvasLayer.new()
	add_child(layer)
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 28)
	layer.add_child(hud)


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		held = button.pressed
		if held:
			_walk_to(get_global_mouse_position())
	elif event is InputEventMouseMotion and held:
		_walk_to(get_global_mouse_position())


func _walk_to(dest: Vector2) -> void:
	if world.is_blocked(world.to_tile(dest)):
		return
	path = world.find_path(pos, dest)


func _process(delta: float) -> void:
	var budget := SPEED * delta
	while budget > 0.0 and not path.is_empty():
		var to_next := path[0] - pos
		var dist := to_next.length()
		if dist <= budget:
			pos = path[0]
			path.remove_at(0)
			budget -= dist
		else:
			pos += to_next / dist * budget
			budget = 0.0
	cam.position = pos
	var tile := world.to_tile(pos)
	hud.text = "Shardsight v%s\nHP %d   Stam %d   Mana %d\nTile %d, %d   Hit chance 100 vs 100: %d%%" % [
		version, hero.max_hp(), hero.max_stamina(), hero.max_mana(), tile.x, tile.y,
		roundi(Rules.hit_chance(100.0, 100.0) * 100.0)]
	queue_redraw()


func _draw() -> void:
	world.draw_tiles(self)
	if not path.is_empty():
		var prev := pos
		for p in path:
			draw_line(prev, p, Color(0.35, 0.78, 1.0, 0.5), 4.0)
			prev = p
		draw_circle(path[path.size() - 1], 12.0, Color(0.35, 0.78, 1.0, 0.6))
	draw_circle(pos, 26.0, Color("f0c850"))
