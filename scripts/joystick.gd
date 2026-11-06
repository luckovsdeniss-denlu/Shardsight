class_name Joystick
extends Control
## An on-screen thumb stick: drag inside the circle to walk. `vector` is the stick position
## (length 0..1, y down = towards the bottom of the screen). Works with touch and the mouse.

const RADIUS := 90.0
const KNOB := 38.0

var vector := Vector2.ZERO
var _finger := -2               # touch index in use (-1: the mouse), -2: none


func _ready() -> void:
	custom_minimum_size = Vector2(RADIUS * 2.0 + 20.0, RADIUS * 2.0 + 20.0)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _center() -> Vector2:
	return size / 2.0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _finger == -2 and t.position.distance_to(_center()) <= RADIUS * 1.2:
			_finger = t.index
			_move(t.position)
		elif not t.pressed and t.index == _finger:
			_release()
		accept_event()
	elif event is InputEventScreenDrag:
		var dr := event as InputEventScreenDrag
		if dr.index == _finger:
			_move(dr.position)
		accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var b := event as InputEventMouseButton
		if b.pressed and _finger == -2:
			_finger = -1
			_move(b.position)
		elif not b.pressed and _finger == -1:
			_release()
		accept_event()
	elif event is InputEventMouseMotion and _finger == -1:
		_move((event as InputEventMouseMotion).position)
		accept_event()


func _move(p: Vector2) -> void:
	var v := (p - _center()) / RADIUS
	vector = v.limit_length(1.0)
	queue_redraw()


func _release() -> void:
	_finger = -2
	vector = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var c := _center()
	draw_circle(c, RADIUS, Color(0, 0, 0, 0.22))
	draw_arc(c, RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0)
	draw_circle(c + vector * RADIUS, KNOB, Color(1, 1, 1, 0.45 if _finger != -2 else 0.28))
