extends Node2D
## Placeholder world: tile grid, tap or drag to walk there. Camera follows the player.

const TILE := 96
const COLS := 40
const ROWS := 40
const SPEED := 4.0 * TILE  # pixels per second

var hero := Hero.new()
var pos := Vector2(COLS, ROWS) * TILE / 2.0
var target := pos
var held := false
var cam := Camera2D.new()


func _ready() -> void:
	add_child(cam)
	var layer := CanvasLayer.new()
	add_child(layer)
	var hud := Label.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 28)
	hud.text = "HP %d   Stam %d   Mana %d\nHit chance 100 vs 100: %d%%" % [
		hero.max_hp(), hero.max_stamina(), hero.max_mana(),
		roundi(Rules.hit_chance(100.0, 100.0) * 100.0)]
	layer.add_child(hud)


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		held = button.pressed
		if held:
			_set_target()
	elif event is InputEventMouseMotion and held:
		_set_target()


func _set_target() -> void:
	target = get_global_mouse_position().clamp(Vector2.ZERO, Vector2(COLS - 1, ROWS - 1) * TILE)


func _process(delta: float) -> void:
	pos = pos.move_toward(target, SPEED * delta)
	cam.position = pos
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(COLS, ROWS) * TILE), Color("0e1018"))
	var line := Color("3c465a")
	for i in range(COLS + 1):
		draw_line(Vector2(i * TILE, 0), Vector2(i * TILE, ROWS * TILE), line, 2.0)
	for j in range(ROWS + 1):
		draw_line(Vector2(0, j * TILE), Vector2(COLS * TILE, j * TILE), line, 2.0)
	draw_circle(target, 10.0, Color(0.35, 0.78, 1.0, 0.5))
	draw_circle(pos, 26.0, Color("f0c850"))
