class_name MoviePhone
extends Movie
## The first trailer in phone format ("Phone format" on the start screen): upright, 9:16, for
## Shorts, Reels and TikTok. The screen turns upright for it (on a phone; on a computer the window
## does), the camera keeps the hero in the middle of the narrow picture, the bars are thinner and
## the titles smaller and wrapped to fit; at the end the screen turns back.
## It's its own script, so nothing here changes the first trailer.

var _old_size := Vector2i.ZERO


func start(p_game) -> void:
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)
	elif DisplayServer.get_name() != "headless":
		_old_size = DisplayServer.window_get_size()
		var h := mini(DisplayServer.screen_get_usable_rect().size.y - 80, 1280)
		DisplayServer.window_set_size(Vector2i(int(h * 9.0 / 16.0), h))
	# wait (a moment at most) for the screen to turn, so everything is laid out upright
	var tree: SceneTree = p_game.get_tree()
	for k in range(90):
		var s: Vector2 = p_game.get_viewport().get_visible_rect().size
		if s.y > s.x:
			break
		await tree.process_frame
	super.start(p_game)
	game.cam.keep_aspect = Camera3D.KEEP_WIDTH        # the scene's width of view, the height to spare


## The hero always in the middle of the narrow picture.
func _min_lean() -> float:
	return 0.9


func _bar_frac() -> float:
	return 0.07


## Titles that fit an upright screen: smaller, and the line under them wraps.
func _extra_ui() -> void:
	var vs := get_viewport().get_visible_rect().size
	_title.add_theme_font_size_override("font_size", 26)
	_sub.add_theme_font_size_override("font_size", 18)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size.x = vs.x - 80.0
	_sub.custom_minimum_size.x = vs.x - 80.0


## Back to the title: the screen turns back first, then the title comes up the right way round.
func _back_to_title() -> void:
	game.cam.keep_aspect = Camera3D.KEEP_HEIGHT
	if OS.has_feature("mobile"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	elif _old_size != Vector2i.ZERO:
		DisplayServer.window_set_size(_old_size)
	var tree := get_tree()
	for k in range(90):
		var s := get_viewport().get_visible_rect().size
		if s.x >= s.y:
			break
		await tree.process_frame
	super._back_to_title()
