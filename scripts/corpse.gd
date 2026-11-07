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
var is_chest := false            # a treasure chest fallen from the sky (with an artifact inside)
var _body: MeshInstance3D
var _beam: MeshInstance3D
const CHEST_LIFETIME := 180.0


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
	_body = body
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
	if is_chest:
		life = minf(life, 3.0)           # an emptied chest soon vanishes
		if _beam != null:
			_beam.visible = false
	_refresh_label()
	return out


## Turns this into a treasure chest on the ground, appearing in a burst of gold sparkles, with a
## golden beam up to the sky and a warm light round it until it's emptied.
func make_chest() -> void:
	is_chest = true
	life = CHEST_LIFETIME
	if _body != null:
		_body.queue_free()
	var model := Node3D.new()
	add_child(model)
	var wood := Color(0.42, 0.26, 0.12)
	var gold_c := Color(0.95, 0.78, 0.3)
	var chest := MeshInstance3D.new()
	chest.mesh = Art.merge([[Art.box(0.72, 0.4, 0.46), Art.at(0, 0.2, 0), wood],
		[Art.box(0.74, 0.18, 0.48), Art.at(0, 0.49, 0), wood.darkened(0.15)],     # the lid
		[Art.box(0.08, 0.6, 0.5), Art.at(-0.26, 0.3, 0), gold_c],                  # gold bands
		[Art.box(0.08, 0.6, 0.5), Art.at(0.26, 0.3, 0), gold_c],
		[Art.box(0.12, 0.14, 0.04), Art.at(0, 0.36, -0.25), gold_c.lightened(0.2)]])   # the lock
	chest.material_override = Art.vc_mat()
	chest.rotation.y = randf() * TAU
	model.add_child(chest)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.85, 0.45)
	light.light_energy = 1.2
	light.omni_range = 3.5
	light.position = Vector3(0.0, 0.8, 0.0)
	model.add_child(light)
	_beam = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.18
	cyl.height = 7.0
	_beam.mesh = cyl
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.albedo_color = Color(1.0, 0.82, 0.4, 0.35)
	_beam.material_override = bm
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.position = Vector3(0.0, 3.5, 0.0)
	add_child(_beam)
	label.modulate = Color(1.0, 0.85, 0.45)
	label.position.y = 1.0
	title = "Treasure Chest"
	_last_text = ""
	_refresh_label()
	Fx.sparkle(get_parent(), global_position + Vector3(0.0, 0.3, 0.0), Color(1.0, 0.85, 0.45), 26)


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
