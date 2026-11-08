class_name TouchScroll
extends ScrollContainer
## A scrolling list that follows your finger: drag anywhere in it, even starting on a button, and
## it scrolls (the button isn't pressed); flick it and it glides on and slows to a stop. A short
## tap without moving still presses buttons as usual. The mouse wheel works too.

const DRAG_START := 12.0          # pixels the finger must move before it counts as a scroll
const FRICTION := 2400.0          # how quickly a flick slows down (pixels a second, a second)

var _down := false
var _dragging := false
var _start := Vector2.ZERO
var _last_y := 0.0
var _last_t := 0.0
var _vel := 0.0                   # pixels a second, for the glide after a flick


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	get_v_scroll_bar().custom_minimum_size.x = 14.0     # a scroll bar you can see


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if get_global_rect().has_point(mb.position):
				_down = true
				_dragging = false
				_start = mb.position
				_last_y = mb.position.y
				_last_t = Time.get_ticks_msec() / 1000.0
				_vel = 0.0
		else:
			if _down and _dragging:
				get_viewport().set_input_as_handled()     # it was a scroll, not a tap
			_down = false
			_dragging = false
	elif event is InputEventMouseMotion and _down:
		var mm := event as InputEventMouseMotion
		var dy := mm.position.y - _last_y
		var now := Time.get_ticks_msec() / 1000.0
		var dt := maxf(now - _last_t, 0.001)
		_last_y = mm.position.y
		_last_t = now
		if not _dragging and absf(mm.position.y - _start.y) > DRAG_START:
			_dragging = true
		if _dragging:
			scroll_vertical -= roundi(dy)
			_vel = lerpf(_vel, -dy / dt, 0.5)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _down or absf(_vel) < 20.0:
		return
	scroll_vertical += roundi(_vel * delta)
	_vel = move_toward(_vel, 0.0, FRICTION * delta)
