extends Node3D
## Third-person 3D view of the tile world. Tap or drag on the ground to walk there.
## Blocked tiles (walls, water, trees) are routed around with A*; taps on them are ignored.

const SPEED := 5.0  # metres per second
const CAM_OFFSET := Vector3(0.0, 9.0, 7.0)
const WANDER_RADIUS := 8       # tiles
const MANUAL_PAUSE := 4.0      # seconds auto mode waits after a tap

var version: String = ProjectSettings.get_setting("application/config/version", "dev")
var world := World.new()
var hero := Hero.new()
var player := Node3D.new()
var cam := Camera3D.new()
var marker := MeshInstance3D.new()
var hud := Label.new()
var path: Array[Vector3] = []
var held := false
var auto := true              # the character acts on its own
var idle_time := 0.0          # seconds standing still (negative = extra pause)
var wait_time := 1.5          # how long to idle before the next wander
var auto_button := Button.new()


func _ready() -> void:
	world.build(self)
	_build_environment()
	_build_player()
	_build_marker()

	cam.fov = 50.0
	add_child(cam)
	cam.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 28)
	layer.add_child(hud)

	auto_button.custom_minimum_size = Vector2(240, 80)
	auto_button.add_theme_font_size_override("font_size", 28)
	auto_button.pressed.connect(_toggle_auto)
	layer.add_child(auto_button)
	auto_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 16)
	_update_button()

	player.position = world.tile_center(Vector2i(5, 5))
	_follow_camera()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("87a8c9")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.76)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)


func _build_player() -> void:
	add_child(player)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.2
	body.mesh = capsule
	body.material_override = World._mat(Color("f0c850"))
	body.position = Vector3(0.0, 0.6, 0.0)
	player.add_child(body)
	# A small "nose" so the facing direction is visible.
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.16, 0.16, 0.28)
	nose.mesh = nose_mesh
	nose.material_override = World._mat(Color("8a5a12"))
	nose.position = Vector3(0.0, 0.95, -0.32)
	player.add_child(nose)


func _build_marker() -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = 0.3
	ring.bottom_radius = 0.3
	ring.height = 0.04
	marker.mesh = ring
	marker.material_override = World._mat(Color(0.35, 0.78, 1.0))
	marker.visible = false
	add_child(marker)


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		held = button.pressed
		if held:
			_walk_to_screen(button.position)
	elif event is InputEventMouseMotion and held:
		_walk_to_screen((event as InputEventMouseMotion).position)


## Intersects the camera ray through `screen` with the ground plane (y = 0).
func _walk_to_screen(screen: Vector2) -> void:
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(
		cam.project_ray_origin(screen), cam.project_ray_normal(screen))
	if hit == null:
		return
	idle_time = -MANUAL_PAUSE  # player input wins; auto resumes after a pause
	_go_to(hit)


## Sets a path to `dest`. Returns false if the tile is blocked or unreachable.
func _go_to(dest: Vector3) -> bool:
	if world.is_blocked(world.to_tile(dest)):
		return false
	var p := world.find_path(player.position, dest)
	if p.is_empty():
		return false
	path = p
	marker.visible = true
	marker.position = path[path.size() - 1] + Vector3(0.0, 0.03, 0.0)
	return true


func _toggle_auto() -> void:
	auto = not auto
	idle_time = 0.0
	_update_button()


func _update_button() -> void:
	auto_button.text = "Auto: ON" if auto else "Auto: OFF"


## Autonomous behaviour: stand idle for a moment, then walk to a random reachable tile nearby.
func _think(delta: float) -> void:
	if not auto:
		return
	if not path.is_empty():
		idle_time = minf(idle_time, 0.0)  # keep any manual pause while walking
		return
	idle_time += delta
	if idle_time < wait_time:
		return
	var here := world.to_tile(player.position)
	for _i in range(12):
		var c := here + Vector2i(
			randi_range(-WANDER_RADIUS, WANDER_RADIUS), randi_range(-WANDER_RADIUS, WANDER_RADIUS))
		if c != here and _go_to(world.tile_center(c)):
			break
	idle_time = 0.0
	wait_time = randf_range(1.0, 3.5)


func _process(delta: float) -> void:
	_think(delta)
	var budget := SPEED * delta
	while budget > 0.0 and not path.is_empty():
		var to_next := path[0] - player.position
		var dist := to_next.length()
		if dist > 0.001:
			player.rotation.y = atan2(-to_next.x, -to_next.z)
		if dist <= budget:
			player.position = path[0]
			path.remove_at(0)
			budget -= dist
		else:
			player.position += to_next / dist * budget
			budget = 0.0
	if path.is_empty():
		marker.visible = false
	_follow_camera()

	var tile := world.to_tile(player.position)
	var mode := "manual"
	if auto:
		mode = "walking" if not path.is_empty() else "idle"
	hud.text = "Shardsight v%s   [%s]\nHP %d   Stam %d   Mana %d\nTile %d, %d   Hit chance 100 vs 100: %d%%" % [
		version, mode, hero.max_hp(), hero.max_stamina(), hero.max_mana(), tile.x, tile.y,
		roundi(Rules.hit_chance(100.0, 100.0) * 100.0)]


func _follow_camera() -> void:
	cam.position = player.position + CAM_OFFSET
	cam.look_at(player.position + Vector3(0.0, 0.5, 0.0), Vector3.UP)
