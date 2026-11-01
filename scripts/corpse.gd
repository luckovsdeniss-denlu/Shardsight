class_name Corpse
extends Node3D
## What a creature leaves behind: gold, reagents and trophy items for anyone to loot.
## Monster, criminal and murderer corpses (and your own) are fair game; innocents' are not.

const LIFETIME := 60.0           # seconds before a corpse rots away
const PLAYER_LIFETIME := 120.0   # player corpses last longer so they can be recovered

var owner_name := ""
var owner_open := true       # monsters, criminals and murderers: anyone may loot
var owner_id := 0
var gold := 0
var reagents := 0
var items := {}
var life := LIFETIME
var label: Label3D
var _last_text := ""


func setup(p_name: String, p_open: bool, p_is_player: bool, p_owner_id: int,
		pos: Vector3, loot: Dictionary) -> void:
	owner_name = p_name
	owner_open = p_open
	owner_id = p_owner_id
	position = pos
	gold = int(loot["gold"])
	reagents = int(loot["reagents"])
	items = loot["items"]
	if p_is_player:
		life = PLAYER_LIFETIME
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.12, 0.5)
	body.mesh = mesh
	body.material_override = World._mat(Color("4a4038"))
	body.position = Vector3(0.0, 0.06, 0.0)
	body.rotation.y = randf() * TAU
	add_child(body)
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.008
	label.font_size = 36
	label.outline_size = 10
	label.no_depth_test = true
	label.modulate = Color(0.8, 0.78, 0.7)
	label.position = Vector3(0.0, 0.6, 0.0)
	add_child(label)
	_refresh_label()


func is_empty() -> bool:
	return gold <= 0 and reagents <= 0 and items.is_empty()


func can_loot(by: Node3D) -> bool:
	return owner_open or by.get_instance_id() == owner_id


## Removes and returns everything: {"gold": int, "reagents": int, "items": {id: count}}.
func take_all() -> Dictionary:
	var out := {"gold": gold, "reagents": reagents, "items": items.duplicate()}
	gold = 0
	reagents = 0
	items.clear()
	_refresh_label()
	return out


func tick(delta: float) -> void:
	life -= delta


func _refresh_label() -> void:
	var text := "%s's corpse" % owner_name
	if not is_empty():
		text += "\n(loot)"
	if text != _last_text:
		_last_text = text
		label.text = text
