class_name Art
## Procedural low-poly art, built entirely in code: creatures are made of primitive shapes merged
## into a handful of flat-shaded meshes (one draw call each) with vertex colours, so a figure
## costs 3-5 draw calls. Meshes are cached and shared by every creature that looks the same.
##
## A creature model is a Dictionary:
##   "root": Node3D (scaled), "legs": [Node3D pivots], "arm": Node3D pivot (weapon arm) or null,
##   "spin": Node3D (spun round for vortexes and blades) or null, "meshes": [MeshInstance3D],
##   "quad": bool (four-legged gait), "arm_rest": float (resting arm angle; zombies reach out).
## Forward is -Z, like the rest of the game.

const PLATE := Color(0.72, 0.74, 0.78)
const CHAIN := Color(0.52, 0.54, 0.58)
const STUDDED := Color(0.32, 0.23, 0.16)
const LEATHER := Color(0.5, 0.33, 0.19)
const STEEL := Color(0.78, 0.8, 0.84)
const WOOD := Color(0.45, 0.3, 0.16)
const DARK := Color(0.16, 0.13, 0.11)
const SKINS := [Color(0.96, 0.8, 0.66), Color(0.86, 0.66, 0.5), Color(0.66, 0.46, 0.32), Color(0.45, 0.31, 0.21)]
const HAIRS := [Color(0.2, 0.14, 0.09), Color(0.42, 0.27, 0.13), Color(0.75, 0.6, 0.3), Color(0.12, 0.12, 0.12), Color(0.6, 0.3, 0.15)]

static var _mesh_cache := {}
static var _mat_cache := {}


# --- materials ------------------------------------------------------------

## The shared material for merged meshes: albedo from the vertex (and instance) colours.
static func vc_mat(alpha := false) -> StandardMaterial3D:
	var key := "vc%s" % alpha
	if not _mat_cache.has(key):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		if alpha:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_cache[key] = m
	return _mat_cache[key]


## Something that glows (eyes, fire, energy).
static func glow_mat(c: Color) -> StandardMaterial3D:
	var key := "glow" + c.to_html()
	if not _mat_cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.6
		if c.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat_cache[key] = m
	return _mat_cache[key]


# --- shapes ---------------------------------------------------------------

static func box(x: float, y: float, z: float) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = Vector3(x, y, z)
	return m


static func ball(r: float, segments := 7, rings := 4) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = segments
	m.rings = rings
	return m


static func cone(bottom: float, height: float, top := 0.0, segments := 7) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = segments
	m.rings = 1
	return m


static func at(x: float, y: float, z: float, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot).scaled(scl), Vector3(x, y, z))


## Merges [mesh, transform, colour] parts into one flat-shaded mesh with vertex colours.
static func merge(parts: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	for p in parts:
		var arr: Array = (p[0] as PrimitiveMesh).get_mesh_arrays()
		var xf: Transform3D = p[1]
		var col: Color = p[2]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		for t in range(0, ix.size() - 2, 3):
			var a := xf * v[ix[t]]
			var b := xf * v[ix[t + 1]]
			var c := xf * v[ix[t + 2]]
			var n := (b - a).cross(c - a)
			if n.length_squared() < 1e-12:
				continue
			n = n.normalized()
			verts.append(a)
			verts.append(b)
			verts.append(c)
			for _k in range(3):
				norms.append(n)
				cols.append(col)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = norms
	out[Mesh.ARRAY_COLOR] = cols
	var am := ArrayMesh.new()
	if not verts.is_empty():
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	return am


static func _cached(key: String, parts_fn: Callable) -> ArrayMesh:
	if not _mesh_cache.has(key):
		_mesh_cache[key] = merge(parts_fn.call())
	return _mesh_cache[key]


static func _instance(parent: Node3D, mesh: Mesh, mat: Material, list: Array) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	parent.add_child(mi)
	list.append(mi)
	return mi


static func _pivot(parent: Node3D, p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = p
	parent.add_child(n)
	return n


# --- creatures ------------------------------------------------------------

## Builds the model for a look. `style` tunes humanoids: "skin", "hair", "cloth" (identity
## colour), "armor" (gear id), "weapon" (gear id), "shield" (gear id), "robe", "hat" ("mage",
## "helmet", "cap", "hood" or ""), "build" (1.0 normal).
static func creature(look: String, style: Dictionary, scale: float) -> Dictionary:
	var root := Node3D.new()
	root.scale = Vector3.ONE * scale
	var model := {"root": root, "legs": [], "arm": null, "spin": null, "meshes": [], "quad": false, "arm_rest": 0.0}
	match look:
		"rat", "wolf", "bear", "hind", "horse", "llama":
			_quadruped(model, look)
		"spider":
			_spider(model)
		"earth_elemental", "air_elemental", "fire_elemental", "water_elemental":
			_elemental(model, look)
		"vortex", "blades":
			_spinner(model, look)
		_:
			_humanoid(model, look, style)
	return model


static func _humanoid(model: Dictionary, look: String, style: Dictionary) -> void:
	var root: Node3D = model["root"]
	var meshes: Array = model["meshes"]
	var skin: Color = style.get("skin", SKINS[0])
	var hair: Color = style.get("hair", HAIRS[0])
	var cloth: Color = style.get("cloth", Color(0.4, 0.4, 0.6))
	var robe := bool(style.get("robe", false))
	var hat := String(style.get("hat", ""))
	var armor := String(style.get("armor", ""))
	var weapon := String(style.get("weapon", ""))
	var shield := String(style.get("shield", ""))
	var build := float(style.get("build", 1.0))
	var bony := look == "skeleton"
	var pants := Color(0.25, 0.2, 0.17)
	match look:
		"orc":
			skin = Color(0.36, 0.52, 0.25)
			hair = DARK
			cloth = Color(0.35, 0.25, 0.15)
			pants = Color(0.22, 0.18, 0.12)
		"zombie":
			skin = Color(0.48, 0.58, 0.42)
			hair = Color(0.2, 0.22, 0.16)
			cloth = Color(0.32, 0.3, 0.26)
			model["arm_rest"] = -1.4
		"skeleton":
			skin = Color(0.88, 0.86, 0.78)
			hair = skin
			cloth = skin
			pants = skin
		"ogre":
			skin = Color(0.62, 0.5, 0.36)
			hair = DARK
			cloth = Color(0.4, 0.3, 0.2)
			build = 1.35
			if weapon == "":
				weapon = "club"
		"evil_mage":
			cloth = Color(0.45, 0.08, 0.1)
			robe = true
			hat = "mage"
		"lich":
			skin = Color(0.7, 0.72, 0.6)
			cloth = Color(0.28, 0.16, 0.38)
			robe = true
			hat = "hood"
		"daemon":
			skin = Color(0.62, 0.12, 0.1)
			hair = DARK
			cloth = Color(0.3, 0.06, 0.05)
			build = 1.25
	var torso_col := cloth
	match Gear.base(armor):
		"platemail":
			torso_col = PLATE
		"chainmail":
			torso_col = CHAIN
		"studded_armor":
			torso_col = STUDDED
		"leather_armor":
			torso_col = LEATHER
	var w := 0.7 if bony else build
	var key := "hum|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [look, skin.to_html(), hair.to_html(), cloth.to_html(),
		torso_col.to_html(), robe, hat, shield, w]
	var body := _cached(key, func() -> Array:
		var p := []
		# torso, belt, tabard in the identity colour
		p.append([box(0.46 * w, 0.56, 0.28 * w), at(0, 1.0, 0), torso_col])
		p.append([box(0.48 * w, 0.08, 0.3 * w), at(0, 0.75, 0), DARK])
		if torso_col != cloth:
			p.append([box(0.2, 0.42, 0.02), at(0, 1.0, -0.15 * w), cloth])
		if bony:
			for i in range(3):
				p.append([box(0.5 * w, 0.04, 0.3 * w), at(0, 0.88 + 0.12 * i, 0), Color(0.3, 0.28, 0.24)])
		if look == "ogre":
			p.append([ball(0.3, 7, 4), at(0, 0.92, -0.12), skin])          # a big belly
		# head, hair, eyes
		p.append([ball(0.17, 8, 5), at(0, 1.43, 0), skin])
		if not bony and hat != "hood":
			p.append([box(0.32, 0.1, 0.32), at(0, 1.57, 0.02), hair])
			p.append([box(0.32, 0.18, 0.08), at(0, 1.47, 0.14), hair])
		p.append([box(0.05, 0.05, 0.03), at(-0.07, 1.45, -0.16), DARK])
		p.append([box(0.05, 0.05, 0.03), at(0.07, 1.45, -0.16), DARK])
		if look == "orc":
			p.append([box(0.03, 0.07, 0.03), at(-0.06, 1.33, -0.15), Color(0.95, 0.92, 0.8)])
			p.append([box(0.03, 0.07, 0.03), at(0.06, 1.33, -0.15), Color(0.95, 0.92, 0.8)])
		if look == "daemon":
			p.append([cone(0.05, 0.22), at(-0.11, 1.62, 0, Vector3(0, 0, 0.4)), Color(0.15, 0.1, 0.08)])
			p.append([cone(0.05, 0.22), at(0.11, 1.62, 0, Vector3(0, 0, -0.4)), Color(0.15, 0.1, 0.08)])
			p.append([box(0.04, 0.6, 0.5), at(-0.3, 1.15, 0.25, Vector3(0.3, 0.5, 0)), Color(0.35, 0.08, 0.08)])
			p.append([box(0.04, 0.6, 0.5), at(0.3, 1.15, 0.25, Vector3(0.3, -0.5, 0)), Color(0.35, 0.08, 0.08)])
		match hat:
			"mage":
				p.append([cone(0.3, 0.04, 0.3, 10), at(0, 1.58, 0), cloth.darkened(0.2)])
				p.append([cone(0.18, 0.42, 0.0, 8), at(0, 1.8, 0.03, Vector3(0.15, 0, 0)), cloth.darkened(0.2)])
			"helmet":
				p.append([ball(0.2, 8, 4), at(0, 1.5, 0), STEEL])
				p.append([box(0.04, 0.14, 0.04), at(0, 1.42, -0.19), STEEL])
			"cap":
				p.append([cone(0.2, 0.1, 0.18, 8), at(0, 1.6, 0), cloth.darkened(0.3)])
			"hood":
				p.append([ball(0.22, 8, 5), at(0, 1.46, 0.03), cloth])
		# left arm (with the shield) is part of the body; the right arm swings separately
		p.append([box(0.12 * w, 0.48, 0.14 * w), at(-0.3 * w, 0.98, 0), torso_col])
		p.append([ball(0.07, 6, 3), at(-0.3 * w, 0.71, 0), skin])
		if shield != "":
			var sc := WOOD
			match Gear.base(shield):
				"bronze_shield":
					sc = Color(0.72, 0.5, 0.25)
				"heater_shield":
					sc = Color(0.55, 0.6, 0.7)
			p.append([cone(0.22, 0.04, 0.22, 10), at(-0.41 * w, 0.95, 0, Vector3(0, 0, PI / 2)), sc])
			p.append([ball(0.05, 6, 3), at(-0.44 * w, 0.95, 0), STEEL])
		# legs: a robe, or the hips the legs hang from
		if robe:
			p.append([cone(0.36, 0.78, 0.2, 9), at(0, 0.39, 0), cloth])
		else:
			p.append([box(0.4 * w, 0.12, 0.24 * w), at(0, 0.7, 0), pants])
		return p)
	_instance(root, body, vc_mat(), meshes)
	if look == "lich":
		var eyes := _cached("lich_eyes", func() -> Array:
			return [[box(0.05, 0.04, 0.02), at(-0.07, 1.45, -0.19), Color(0.6, 1.0, 0.7)],
				[box(0.05, 0.04, 0.02), at(0.07, 1.45, -0.19), Color(0.6, 1.0, 0.7)]])
		_instance(root, eyes, glow_mat(Color(0.5, 1.0, 0.6)), meshes)
	# legs (pivot at the hip)
	if not robe:
		var leg := _cached("leg|%s|%s" % [pants.to_html(), w], func() -> Array:
			return [[box(0.15 * w, 0.62, 0.17 * w), at(0, -0.31, 0), pants],
				[box(0.17 * w, 0.1, 0.24 * w), at(0, -0.64, -0.03), DARK]])
		for side in [-1.0, 1.0]:
			var piv := _pivot(root, Vector3(0.11 * w * side, 0.7, 0))
			_instance(piv, leg, vc_mat(), meshes)
			model["legs"].append(piv)
	# right arm with the weapon (pivot at the shoulder)
	var arm_piv := _pivot(root, Vector3(0.3 * w, 1.22, 0))
	var arm := _cached("arm|%s|%s|%s|%s" % [torso_col.to_html(), skin.to_html(), weapon, w], func() -> Array:
		var p := [[box(0.12 * w, 0.48, 0.14 * w), at(0, -0.24, 0), torso_col],
			[ball(0.07, 6, 3), at(0, -0.51, 0), skin]]
		p.append_array(_weapon_parts(weapon))
		return p)
	_instance(arm_piv, arm, vc_mat(), meshes)
	arm_piv.rotation.x = float(model["arm_rest"])
	model["arm"] = arm_piv


## A weapon held in the right hand (the hand is at y -0.51 in the arm's space).
static func _weapon_parts(weapon: String) -> Array:
	var p := []
	var hy := -0.51
	match Gear.base(weapon):
		"dagger", "kryss":
			p.append([box(0.04, 0.03, 0.32), at(0, hy, -0.2), STEEL])
			p.append([box(0.14, 0.03, 0.03), at(0, hy, -0.04), DARK])
		"short_sword", "longsword", "broadsword", "bonecleaver":
			var length := 0.55 if Gear.base(weapon) == "short_sword" else 0.78
			p.append([box(0.05, 0.03, length), at(0, hy, -length / 2.0 - 0.05), STEEL])
			p.append([box(0.2, 0.04, 0.04), at(0, hy, -0.05), Color(0.6, 0.5, 0.2)])
			p.append([box(0.04, 0.04, 0.14), at(0, hy, 0.04), WOOD])
		"mace", "club":
			p.append([box(0.04, 0.04, 0.5), at(0, hy, -0.22), WOOD])
			var is_mace := Gear.base(weapon) == "mace"
			p.append([ball(0.09 if is_mace else 0.12, 6, 3), at(0, hy, -0.5), STEEL if is_mace else WOOD.darkened(0.2)])
		"war_hammer":
			p.append([box(0.04, 0.04, 0.7), at(0, hy, -0.3), WOOD])
			p.append([box(0.24, 0.12, 0.12), at(0, hy, -0.66), STEEL])
		"halberd":
			p.append([box(0.04, 1.5, 0.04), at(0, hy + 0.3, -0.06), WOOD])
			p.append([box(0.03, 0.26, 0.2), at(0, hy + 0.98, -0.14), STEEL])
		"bow":
			p.append([box(0.03, 0.4, 0.03), at(0, hy + 0.2, -0.12, Vector3(-0.35, 0, 0)), WOOD])
			p.append([box(0.03, 0.4, 0.03), at(0, hy - 0.2, -0.12, Vector3(0.35, 0, 0)), WOOD])
			p.append([box(0.01, 0.75, 0.01), at(0, hy, -0.01), Color(0.9, 0.9, 0.85)])
		"crossbow":
			p.append([box(0.06, 0.06, 0.55), at(0, hy, -0.22), WOOD])
			p.append([box(0.55, 0.04, 0.04), at(0, hy, -0.42), WOOD.darkened(0.3)])
	return p


static func _quadruped(model: Dictionary, look: String) -> void:
	var root: Node3D = model["root"]
	var meshes: Array = model["meshes"]
	model["quad"] = true
	var fur := Color(0.5, 0.5, 0.52)
	var length := 0.8
	var height := 0.55
	var girth := 0.36
	var leg_len := 0.45
	match look:
		"rat":
			fur = Color(0.42, 0.36, 0.32)
			length = 0.6
			height = 0.3
			girth = 0.3
			leg_len = 0.2
		"bear":
			fur = Color(0.4, 0.27, 0.16)
			length = 1.0
			height = 0.7
			girth = 0.6
			leg_len = 0.45
		"hind":
			fur = Color(0.66, 0.48, 0.3)
			length = 0.8
			height = 0.8
			girth = 0.32
			leg_len = 0.62
		"horse":
			fur = Color(0.48, 0.32, 0.2)
			length = 1.15
			girth = 0.42
			leg_len = 0.7
		"llama":
			fur = Color(0.9, 0.86, 0.78)
			length = 0.85
			girth = 0.4
			leg_len = 0.62
	var top := leg_len + girth / 2.0
	var necked := look in ["hind", "horse", "llama"]
	var neck := 0.6 if look == "llama" else (0.42 if look == "horse" else 0.32)
	var key := "quad|" + look
	var body := _cached(key, func() -> Array:
		var p := [[box(girth, girth, length), at(0, top, 0), fur]]
		var head_y := top + (neck if necked else 0.08)
		var head_z := -length / 2.0 - 0.12
		if necked:
			p.append([box(girth * 0.45, neck + 0.15, girth * 0.45), at(0, top + neck * 0.5, -length / 2.0 + 0.02, Vector3(0.45 if look != "llama" else 0.15, 0, 0)), fur])
		if look == "horse":
			p.append([box(0.05, neck + 0.1, 0.12), at(0, top + neck * 0.6, -length / 2.0 + 0.1, Vector3(0.45, 0, 0)), DARK])
			p.append([cone(0.07, 0.5, 0.02, 5), at(0, top + 0.02, length / 2.0 + 0.22, Vector3(-0.9, 0, 0)), DARK])
			p.append([box(girth * 1.02, 0.12, 0.4), at(0, top + girth * 0.5, 0), Color(0.35, 0.2, 0.1)])   # saddle
		p.append([box(girth * 0.75, girth * 0.7, girth * 0.8), at(0, head_y, head_z), fur])
		p.append([box(girth * 0.4, girth * 0.35, girth * 0.5), at(0, head_y - 0.04, head_z - girth * 0.55), fur.lightened(0.15)])
		p.append([box(0.04, 0.04, 0.02), at(-girth * 0.2, head_y + 0.05, head_z - girth * 0.41), DARK])
		p.append([box(0.04, 0.04, 0.02), at(girth * 0.2, head_y + 0.05, head_z - girth * 0.41), DARK])
		match look:
			"wolf":
				p.append([cone(0.06, 0.14, 0.0, 4), at(-0.09, head_y + 0.18, head_z + 0.04), fur])
				p.append([cone(0.06, 0.14, 0.0, 4), at(0.09, head_y + 0.18, head_z + 0.04), fur])
				p.append([cone(0.09, 0.45, 0.03, 5), at(0, top + 0.02, length / 2.0 + 0.2, Vector3(-1.1, 0, 0)), fur.lightened(0.1)])
			"bear":
				p.append([ball(0.06, 5, 3), at(-0.14, head_y + 0.16, head_z + 0.04), fur])
				p.append([ball(0.06, 5, 3), at(0.14, head_y + 0.16, head_z + 0.04), fur])
				p.append([ball(0.07, 5, 3), at(0, top + 0.05, length / 2.0 + 0.02), fur])
			"hind":
				p.append([cone(0.04, 0.16, 0.0, 4), at(-0.07, head_y + 0.14, head_z + 0.05, Vector3(0, 0, 0.4)), fur])
				p.append([cone(0.04, 0.16, 0.0, 4), at(0.07, head_y + 0.14, head_z + 0.05, Vector3(0, 0, -0.4)), fur])
				p.append([ball(0.05, 5, 3), at(0, top + 0.04, length / 2.0 + 0.03), Color(0.95, 0.92, 0.88)])
			"rat":
				p.append([ball(0.04, 5, 3), at(-0.07, head_y + 0.08, head_z + 0.04), Color(0.85, 0.6, 0.6)])
				p.append([ball(0.04, 5, 3), at(0.07, head_y + 0.08, head_z + 0.04), Color(0.85, 0.6, 0.6)])
				p.append([cone(0.025, 0.55, 0.005, 4), at(0, top - 0.04, length / 2.0 + 0.26, Vector3(-1.45, 0, 0)), Color(0.85, 0.65, 0.62)])
		return p)
	_instance(root, body, vc_mat(), meshes)
	var leg := _cached("qleg|" + look, func() -> Array:
		return [[box(girth * 0.32, leg_len, girth * 0.32), at(0, -leg_len / 2.0, 0), fur.darkened(0.15)],
			[box(girth * 0.34, 0.05, girth * 0.36), at(0, -leg_len + 0.02, -0.01), DARK]])
	# front left, front right, back left, back right
	for pos in [Vector3(-girth * 0.32, leg_len, -length * 0.36), Vector3(girth * 0.32, leg_len, -length * 0.36),
			Vector3(-girth * 0.32, leg_len, length * 0.36), Vector3(girth * 0.32, leg_len, length * 0.36)]:
		var piv := _pivot(root, pos)
		_instance(piv, leg, vc_mat(), meshes)
		model["legs"].append(piv)


static func _spider(model: Dictionary) -> void:
	var root: Node3D = model["root"]
	var body := _cached("spider", func() -> Array:
		var dark := Color(0.2, 0.19, 0.14)
		var p := [[ball(0.38, 8, 5), at(0, 0.45, 0.3, Vector3.ZERO, Vector3(1, 0.8, 1.15)), dark],
			[ball(0.22, 7, 4), at(0, 0.4, -0.2), dark.lightened(0.1)],
			[box(0.08, 0.06, 0.03), at(-0.08, 0.45, -0.41), Color(0.8, 0.1, 0.1)],
			[box(0.08, 0.06, 0.03), at(0.08, 0.45, -0.41), Color(0.8, 0.1, 0.1)]]
		for side in [-1.0, 1.0]:
			for i in range(4):
				var z := -0.32 + 0.16 * i
				p.append([box(0.55, 0.05, 0.05), at(side * 0.38, 0.5, z, Vector3(0, 0.25 * (i - 1.5), side * -0.45)), dark])
				p.append([box(0.05, 0.42, 0.05), at(side * 0.66, 0.24, z), dark])
		return p)
	_instance(root, body, vc_mat(), model["meshes"])


static func _elemental(model: Dictionary, look: String) -> void:
	var root: Node3D = model["root"]
	var meshes: Array = model["meshes"]
	match look:
		"earth_elemental":
			var rock := Color(0.48, 0.38, 0.28)
			var body := _cached("earth_el", func() -> Array:
				return [[box(0.6, 0.7, 0.45), at(0, 0.95, 0, Vector3(0.1, 0.3, 0.05)), rock],
					[box(0.35, 0.32, 0.32), at(0, 1.5, -0.02, Vector3(0.2, -0.3, 0.1)), rock.lightened(0.1)],
					[box(0.3, 0.55, 0.3), at(-0.48, 0.95, 0, Vector3(0, 0.2, 0.3)), rock.darkened(0.1)],
					[box(0.3, 0.55, 0.3), at(0.48, 0.95, 0, Vector3(0, -0.2, -0.3)), rock.darkened(0.1)],
					[box(0.28, 0.55, 0.3), at(-0.17, 0.3, 0), rock.darkened(0.2)],
					[box(0.28, 0.55, 0.3), at(0.17, 0.3, 0), rock.darkened(0.2)]])
			_instance(root, body, vc_mat(), meshes)
		"air_elemental", "water_elemental":
			var c := Color(0.85, 0.92, 1.0, 0.55) if look == "air_elemental" else Color(0.25, 0.5, 0.95, 0.7)
			var spin := _pivot(root, Vector3.ZERO)
			var body := _cached(look, func() -> Array:
				return [[ball(0.38, 8, 5), at(0, 0.5, 0), c], [ball(0.3, 8, 5), at(0.1, 1.0, 0.05), c],
					[ball(0.22, 8, 4), at(-0.05, 1.42, 0), c], [ball(0.14, 6, 3), at(0.35, 1.05, -0.1), c],
					[ball(0.14, 6, 3), at(-0.35, 1.05, 0.1), c]])
			_instance(spin, body, vc_mat(true), meshes)
			model["spin"] = spin
		"fire_elemental":
			var spin := _pivot(root, Vector3.ZERO)
			var flames := _cached("fire_el", func() -> Array:
				var orange := Color(1.0, 0.5, 0.1)
				return [[cone(0.4, 1.1, 0.05, 7), at(0, 0.6, 0), orange],
					[cone(0.22, 0.7, 0.0, 6), at(0.25, 1.1, 0.05, Vector3(0, 0, -0.3)), Color(1.0, 0.75, 0.2)],
					[cone(0.22, 0.7, 0.0, 6), at(-0.25, 1.05, -0.05, Vector3(0, 0, 0.3)), Color(1.0, 0.75, 0.2)],
					[cone(0.18, 0.6, 0.0, 6), at(0, 1.45, 0), Color(1.0, 0.9, 0.4)]])
			_instance(spin, flames, glow_mat(Color(1.0, 0.55, 0.15)), meshes)
			model["spin"] = spin


static func _spinner(model: Dictionary, look: String) -> void:
	var root: Node3D = model["root"]
	var spin := _pivot(root, Vector3.ZERO)
	if look == "vortex":
		var torus := TorusMesh.new()
		torus.inner_radius = 0.25
		torus.outer_radius = 0.45
		torus.rings = 10
		torus.ring_segments = 6
		var v := _cached("vortex", func() -> Array:
			return [[torus, at(0, 0.4, 0), Color(0.5, 0.6, 1.0)],
				[torus, at(0, 0.9, 0, Vector3(0, 0, 0), Vector3(0.75, 1, 0.75)), Color(0.6, 0.7, 1.0)],
				[ball(0.2, 7, 4), at(0, 1.3, 0), Color(0.9, 0.95, 1.0)]])
		_instance(spin, v, glow_mat(Color(0.5, 0.65, 1.0)), model["meshes"])
	else:
		var blades := _cached("blades", func() -> Array:
			var p := []
			for i in range(4):
				var a := TAU * i / 4.0
				p.append([box(0.06, 0.04, 0.7), at(cos(a) * 0.3, 0.8 + 0.1 * (i % 2), sin(a) * 0.3, Vector3(0, -a, 0)), STEEL])
			return p)
		_instance(spin, blades, vc_mat(), model["meshes"])
	model["spin"] = spin


## A deterministic colour pick for a name (skin and hair of players and townsfolk).
static func pick(list: Array, seed_text: String) -> Color:
	return list[absi(seed_text.hash()) % list.size()]
