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
var title := ""                  # overrides "<name>'s corpse" (e.g. house ruins)
var sealed_by := 0               # Magic Lock: only this creature may loot it (0: not sealed)


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
	# A dropped sack with a couple of bones beside it.
	var body := MeshInstance3D.new()
	var bone := Color(0.86, 0.84, 0.76)
	body.mesh = Art.merge([[Art.ball(0.22, 7, 4), Art.at(0, 0.16, 0, Vector3.ZERO, Vector3(1, 0.75, 1)), Color(0.45, 0.35, 0.22)],
		[Art.box(0.08, 0.1, 0.08), Art.at(0, 0.32, 0), Color(0.32, 0.24, 0.14)],
		[Art.box(0.45, 0.05, 0.06), Art.at(0.28, 0.03, 0.12, Vector3(0, 0.6, 0)), bone],
		[Art.box(0.38, 0.05, 0.06), Art.at(0.25, 0.03, -0.12, Vector3(0, -0.5, 0)), bone],
		[Art.ball(0.08, 6, 3), Art.at(-0.28, 0.07, 0.1), bone]])
	body.material_override = Art.vc_mat()
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


## What's inside, for the label: "23 gold, Orc Ear, Longsword +2 more".
func contents_text(max_entries: int) -> String:
	var parts: Array[String] = []
	if gold > 0:
		parts.append("%d gold" % gold)
	if reagents > 0:
		parts.append("%d reagents" % reagents)
	for id in items:
		var n := int(items[id])
		parts.append(Items.item_name(id) + (" x%d" % n if n > 1 else ""))
	if parts.size() <= max_entries:
		return ", ".join(parts)
	return ", ".join(parts.slice(0, max_entries)) + " +%d more" % (parts.size() - max_entries)


func is_empty() -> bool:
	return gold <= 0 and reagents <= 0 and items.is_empty()


func can_loot(by: Node3D) -> bool:
	if sealed_by != 0 and by.get_instance_id() != sealed_by:
		return false
	return owner_open or by.get_instance_id() == owner_id


## Removes and returns everything: {"gold": int, "reagents": int, "items": {id: count}}.
func take_all() -> Dictionary:
	var out := {"gold": gold, "reagents": reagents, "items": items.duplicate()}
	gold = 0
	reagents = 0
	items.clear()
	_refresh_label()
	return out


func set_title(t: String) -> void:
	title = t
	_last_text = ""
	_refresh_label()


func tick(delta: float) -> void:
	life -= delta


func _refresh_label() -> void:
	var text := title if title != "" else "%s's corpse" % owner_name
	if not is_empty():
		text += "\n" + contents_text(3)
	if text != _last_text:
		_last_text = text
		label.text = text
