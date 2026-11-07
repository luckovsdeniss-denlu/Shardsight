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
const TRIM := Color(0.92, 0.74, 0.25)       # gold trim on exceptional (master-made) armor
## Gear made from coloured ingots ("longsword@valorite") shows the colour of its metal.
const METAL_TINT := {
	"dull_copper": Color(0.62, 0.48, 0.38), "shadow_iron": Color(0.36, 0.36, 0.42),
	"copper": Color(0.8, 0.5, 0.3), "bronze": Color(0.76, 0.56, 0.3), "golden": Color(0.92, 0.78, 0.32),
	"agapite": Color(0.78, 0.5, 0.5), "verite": Color(0.45, 0.66, 0.45), "valorite": Color(0.48, 0.58, 0.9),
}


## The metal colour of an item id, or `fallback` if it's plain iron/steel.
static func metal_of(id: String, fallback: Color) -> Color:
	for part in id.split("@"):
		if METAL_TINT.has(part):
			return METAL_TINT[part]
		if Gear.ARTIFACTS.has(part):
			return Gear.ARTIFACTS[part]["color"]      # artifacts show in their own colour
	return fallback
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


## A thin flat ring (a halo).
static func ring_mesh(inner: float, outer: float) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = 20
	t.ring_segments = 5
	return t


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
		"rat", "wolf", "bear", "hind", "horse", "llama", "nightmare", "swamp_dragon", "beetle":
			_quadruped(model, look)
		"ostard":
			_ostard(model)
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
	var holy := bool(style.get("holy", false))     # a priest: white robes, gold, a halo
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
	var ab := Gear.base(armor)                  # armor kind
	var ex := armor.contains("@ex")             # exceptional: gold trim
	var belt := TRIM if ex else DARK
	var boots := DARK
	var hands := skin
	match ab:
		"platemail":
			torso_col = metal_of(armor, PLATE)
			pants = torso_col.darkened(0.08)
			boots = torso_col.darkened(0.2)
			hands = torso_col
			if hat == "":
				hat = "plate_helm"
		"chainmail":
			torso_col = metal_of(armor, CHAIN)
			pants = torso_col.darkened(0.12)
			if hat == "":
				hat = "coif"
		"studded_armor":
			torso_col = STUDDED
			pants = STUDDED.darkened(0.15)
		"leather_armor":
			torso_col = LEATHER
			pants = LEATHER.darkened(0.25)
	var ranged := Gear.is_ranged(weapon)
	var w := 0.7 if bony else build
	var key := "hum|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [look, skin.to_html(), hair.to_html(), cloth.to_html(),
		torso_col.to_html(), robe, hat, shield, w, ab, ex, ranged, holy]
	var body := _cached(key, func() -> Array:
		var p := []
		# torso, belt, tabard in the identity colour
		p.append([box(0.46 * w, 0.56, 0.28 * w), at(0, 1.0, 0), torso_col])
		p.append([box(0.48 * w, 0.08, 0.3 * w), at(0, 0.75, 0), belt])
		if torso_col != cloth:
			p.append([box(0.2, 0.42, 0.02), at(0, 1.0, -0.15 * w), cloth])
		_armor_parts(p, ab, torso_col, cloth, w, ex)
		if holy:                                       # a gold ankh, a stole and trim on the hood
			p.append([box(0.04, 0.2, 0.02), at(0, 1.02, -0.16 * w), TRIM])
			p.append([box(0.14, 0.04, 0.02), at(0, 1.08, -0.16 * w), TRIM])
			p.append([ball(0.04, 6, 3), at(0, 1.15, -0.16 * w), TRIM])
			p.append([box(0.07, 0.62, 0.02), at(-0.12, 0.72, -0.17 * w), TRIM.darkened(0.15)])
			p.append([box(0.07, 0.62, 0.02), at(0.12, 0.72, -0.17 * w), TRIM.darkened(0.15)])
			p.append([box(0.3, 0.04, 0.1), at(0, 1.3, -0.12), TRIM])
		if ranged:                                     # a quiver of arrows on the back
			p.append([box(0.11, 0.44, 0.11), at(0.1, 1.05, 0.19, Vector3(0, 0, 0.3)), LEATHER.darkened(0.1)])
			for i in range(3):
				p.append([box(0.03, 0.08, 0.03), at(0.17 + 0.03 * i, 1.3, 0.19 + 0.02 * (i - 1), Vector3(0, 0, 0.3)), Color(0.92, 0.92, 0.88)])
		if bony:
			for i in range(3):
				p.append([box(0.5 * w, 0.04, 0.3 * w), at(0, 0.88 + 0.12 * i, 0), Color(0.3, 0.28, 0.24)])
		if look == "ogre":
			p.append([ball(0.3, 7, 4), at(0, 0.92, -0.12), skin])          # a big belly
		# head, hair, eyes
		p.append([ball(0.17, 8, 5), at(0, 1.43, 0), skin])
		if not bony and not hat in ["hood", "plate_helm", "coif"]:
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
			"plate_helm":                                # a closed helm, eye slit and a plume
				p.append([ball(0.215, 8, 5), at(0, 1.46, 0), torso_col])
				p.append([box(0.3, 0.2, 0.06), at(0, 1.42, -0.17), torso_col.darkened(0.1)])
				p.append([box(0.24, 0.035, 0.02), at(0, 1.46, -0.205), DARK])
				p.append([box(0.05, 0.14, 0.3), at(0, 1.7, 0.04), cloth])
				if ex:
					p.append([box(0.32, 0.03, 0.08), at(0, 1.33, -0.15), TRIM])
			"coif":                                      # a mail hood, the face showing
				p.append([ball(0.215, 8, 5), at(0, 1.47, 0.04), torso_col])
				p.append([box(0.36, 0.12, 0.34), at(0, 1.25, 0.0), torso_col])
		# left arm (with the shield) is part of the body; the right arm swings separately
		p.append([box(0.12 * w, 0.48, 0.14 * w), at(-0.3 * w, 0.98, 0), torso_col])
		p.append([ball(0.07, 6, 3), at(-0.3 * w, 0.71, 0), hands])
		if shield != "":
			_shield_parts(p, shield, cloth, w)
		# legs: a robe, or the hips the legs hang from
		if robe:
			p.append([cone(0.36, 0.78, 0.2, 9), at(0, 0.39, 0), cloth])
		else:
			p.append([box(0.4 * w, 0.12, 0.24 * w), at(0, 0.7, 0), pants])
		return p)
	_instance(root, body, vc_mat(), meshes)
	if holy:                                           # a glowing halo over the hood
		var halo := _cached("halo", func() -> Array:
			return [[ring_mesh(0.17, 0.2), at(0, 1.78, 0.02), Color(1.0, 0.86, 0.4)]])
		_instance(root, halo, glow_mat(Color(1.0, 0.82, 0.35)), meshes)
	if look == "lich":
		var eyes := _cached("lich_eyes", func() -> Array:
			return [[box(0.05, 0.04, 0.02), at(-0.07, 1.45, -0.19), Color(0.6, 1.0, 0.7)],
				[box(0.05, 0.04, 0.02), at(0.07, 1.45, -0.19), Color(0.6, 1.0, 0.7)]])
		_instance(root, eyes, glow_mat(Color(0.5, 1.0, 0.6)), meshes)
	# legs (pivot at the hip)
	if not robe:
		var leg := _cached("leg|%s|%s|%s|%s" % [pants.to_html(), w, ab, boots.to_html()], func() -> Array:
			var lp := [[box(0.15 * w, 0.62, 0.17 * w), at(0, -0.31, 0), pants],
				[box(0.17 * w, 0.1, 0.24 * w), at(0, -0.64, -0.03), boots]]
			match ab:
				"platemail":                         # knee cop and a tall greave
					lp.append([ball(0.075, 6, 3), at(0, -0.33, -0.08), pants.lightened(0.1)])
					lp.append([box(0.17 * w, 0.22, 0.19 * w), at(0, -0.5, 0), boots])
				"leather_armor", "studded_armor":   # tall boots
					lp.append([box(0.165 * w, 0.2, 0.185 * w), at(0, -0.52, 0), Color(0.22, 0.15, 0.1)])
			return lp)
		for side in [-1.0, 1.0]:
			var piv := _pivot(root, Vector3(0.11 * w * side, 0.7, 0))
			_instance(piv, leg, vc_mat(), meshes)
			model["legs"].append(piv)
	# right arm with the weapon (pivot at the shoulder)
	var arm_piv := _pivot(root, Vector3(0.3 * w, 1.22, 0))
	var arm := _cached("arm|%s|%s|%s|%s|%s" % [torso_col.to_html(), hands.to_html(), weapon, w, ab], func() -> Array:
		var p := [[box(0.12 * w, 0.48, 0.14 * w), at(0, -0.24, 0), torso_col],
			[ball(0.07, 6, 3), at(0, -0.51, 0), hands]]
		match ab:
			"platemail":                             # the right pauldron moves with the arm
				p.append([ball(0.14, 7, 4), at(0.02, 0.0, 0, Vector3.ZERO, Vector3(1.1, 0.75, 1.1)), torso_col.lightened(0.08)])
			"leather_armor", "studded_armor":         # a bracer
				p.append([box(0.14 * w, 0.14, 0.16 * w), at(0, -0.38, 0), Color(0.22, 0.15, 0.1)])
		p.append_array(_weapon_parts(weapon))
		return p)
	_instance(arm_piv, arm, vc_mat(), meshes)
	arm_piv.rotation.x = float(model["arm_rest"])
	model["arm"] = arm_piv


## The extra pieces of each kind of armor on the body (the left arm is part of the body).
static func _armor_parts(p: Array, ab: String, col: Color, cloth: Color, w: float, ex: bool) -> void:
	match ab:
		"platemail":
			p.append([ball(0.14, 7, 4), at(-0.32 * w, 1.22, 0, Vector3.ZERO, Vector3(1.1, 0.75, 1.1)), col.lightened(0.08)])
			p.append([box(0.26, 0.08, 0.22), at(0, 1.3, 0), col.darkened(0.1)])          # gorget
			p.append([box(0.06, 0.4, 0.04), at(0, 1.02, -0.15 * w), col.lightened(0.12)])  # chest ridge
			p.append([box(0.5 * w, 0.14, 0.32 * w), at(0, 0.66, 0), col.darkened(0.06)])  # tassets
			if ex:
				p.append([box(0.47 * w, 0.03, 0.29 * w), at(0, 1.27, 0), TRIM])
		"chainmail":
			p.append([box(0.5 * w, 0.18, 0.31 * w), at(0, 0.65, 0), col.darkened(0.1)])   # the hauberk's skirt
			if ex:
				p.append([box(0.5 * w, 0.03, 0.31 * w), at(0, 0.57, 0), TRIM])
		"studded_armor":
			for row in range(3):
				for c in range(3):
					p.append([box(0.035, 0.035, 0.02), at((c - 1) * 0.12 * w, 1.15 - row * 0.13, -0.145 * w), TRIM if ex else STEEL])
			p.append([box(0.14, 0.06, 0.3 * w), at(-0.3 * w, 1.24, 0), STUDDED.darkened(0.2)])
		"leather_armor":
			p.append([box(0.06, 0.62, 0.02), at(0, 1.0, -0.145 * w, Vector3(0, 0, 0.65)), Color(0.22, 0.15, 0.1)])  # a strap
			p.append([box(0.14 * w, 0.14, 0.16 * w), at(-0.3 * w, 0.84, 0), Color(0.22, 0.15, 0.1)])            # a bracer
			if ex:
				p.append([box(0.47 * w, 0.03, 0.29 * w), at(0, 1.27, 0), TRIM])


## Each shield has its own shape: a round wooden one with planks and a rim, a round bronze one
## with a boss, and a heater (the classic knight's shield) with a cross in the bearer's colour.
static func _shield_parts(p: Array, shield: String, cloth: Color, w: float) -> void:
	var x := -0.42 * w
	match Gear.base(shield):
		"heater_shield":
			var sc := metal_of(shield, Color(0.6, 0.64, 0.72))
			p.append([box(0.04, 0.34, 0.36), at(x, 1.02, 0), sc])
			p.append([box(0.04, 0.26, 0.26), at(x, 0.84, 0, Vector3(PI / 4, 0, 0)), sc])    # the point
			p.append([box(0.01, 0.4, 0.07), at(x - 0.025, 0.95, 0), cloth])                  # the cross
			p.append([box(0.01, 0.07, 0.28), at(x - 0.025, 1.04, 0), cloth])
		"bronze_shield":
			var bc := metal_of(shield, Color(0.74, 0.52, 0.26))
			p.append([cone(0.23, 0.04, 0.23, 12), at(x, 0.95, 0, Vector3(0, 0, PI / 2)), bc])
			p.append([cone(0.25, 0.02, 0.25, 12), at(x + 0.01, 0.95, 0, Vector3(0, 0, PI / 2)), bc.darkened(0.3)])
			p.append([ball(0.07, 6, 3), at(x - 0.03, 0.95, 0), bc.lightened(0.25)])          # the boss
		_:
			p.append([cone(0.22, 0.04, 0.22, 10), at(x, 0.95, 0, Vector3(0, 0, PI / 2)), WOOD])
			p.append([cone(0.235, 0.025, 0.235, 10), at(x + 0.01, 0.95, 0, Vector3(0, 0, PI / 2)), DARK])  # rim
			for i in [-1, 1]:
				p.append([box(0.01, 0.4, 0.02), at(x - 0.022, 0.95, 0.07 * i), WOOD.darkened(0.35)])     # planks
			p.append([ball(0.045, 6, 3), at(x - 0.03, 0.95, 0), STEEL])


## A weapon held in the right hand (the hand is at y -0.51 in the arm's space).
static func _weapon_parts(weapon: String) -> Array:
	var p := []
	var hy := -0.51
	var steel := metal_of(weapon, STEEL)        # blades and heads take their metal's colour
	match Gear.base(weapon):
		"dagger", "kryss":
			p.append([box(0.04, 0.03, 0.32), at(0, hy, -0.2), steel])
			p.append([box(0.14, 0.03, 0.03), at(0, hy, -0.04), DARK])
		"short_sword", "longsword", "broadsword", "bonecleaver":
			var length := 0.55 if Gear.base(weapon) == "short_sword" else 0.78
			p.append([box(0.05, 0.03, length), at(0, hy, -length / 2.0 - 0.05), steel])
			p.append([box(0.2, 0.04, 0.04), at(0, hy, -0.05), Color(0.6, 0.5, 0.2)])
			p.append([box(0.04, 0.04, 0.14), at(0, hy, 0.04), WOOD])
		"mace", "club":
			p.append([box(0.04, 0.04, 0.5), at(0, hy, -0.22), WOOD])
			var is_mace := Gear.base(weapon) == "mace"
			p.append([ball(0.09 if is_mace else 0.12, 6, 3), at(0, hy, -0.5), steel if is_mace else WOOD.darkened(0.2)])
		"war_hammer":
			p.append([box(0.04, 0.04, 0.7), at(0, hy, -0.3), WOOD])
			p.append([box(0.24, 0.12, 0.12), at(0, hy, -0.66), steel])
		"halberd":
			p.append([box(0.04, 1.5, 0.04), at(0, hy + 0.3, -0.06), WOOD])
			p.append([box(0.03, 0.26, 0.2), at(0, hy + 0.98, -0.14), steel])
		"bow":
			p.append([box(0.03, 0.4, 0.03), at(0, hy + 0.2, -0.12, Vector3(-0.35, 0, 0)), WOOD])
			p.append([box(0.03, 0.4, 0.03), at(0, hy - 0.2, -0.12, Vector3(0.35, 0, 0)), WOOD])
			p.append([box(0.01, 0.75, 0.01), at(0, hy, -0.01), Color(0.9, 0.9, 0.85)])
		"priest_staff":                                # a pale staff topped with a gold sunburst
			p.append([box(0.05, 1.6, 0.05), at(0, hy + 0.3, -0.06), Color(0.85, 0.8, 0.68)])
			p.append([ball(0.1, 7, 4), at(0, hy + 1.12, -0.06), Color(1.0, 0.9, 0.55)])
			p.append([box(0.3, 0.03, 0.03), at(0, hy + 1.12, -0.06), TRIM])
			p.append([box(0.03, 0.3, 0.03), at(0, hy + 1.12, -0.06), TRIM])
		"composite_bow":                               # a recurve: darker limbs with horn tips
			var horn := Color(0.85, 0.8, 0.65)
			var limb := Color(0.3, 0.18, 0.1)
			p.append([box(0.035, 0.42, 0.035), at(0, hy + 0.22, -0.14, Vector3(-0.45, 0, 0)), limb])
			p.append([box(0.035, 0.42, 0.035), at(0, hy - 0.22, -0.14, Vector3(0.45, 0, 0)), limb])
			p.append([box(0.03, 0.1, 0.03), at(0, hy + 0.43, -0.16, Vector3(0.5, 0, 0)), horn])
			p.append([box(0.03, 0.1, 0.03), at(0, hy - 0.43, -0.16, Vector3(-0.5, 0, 0)), horn])
			p.append([box(0.05, 0.12, 0.05), at(0, hy, -0.05), DARK])      # the grip
			p.append([box(0.01, 0.84, 0.01), at(0, hy, -0.01), Color(0.9, 0.9, 0.85)])
		"crossbow":
			p.append([box(0.06, 0.06, 0.55), at(0, hy, -0.22), WOOD])
			p.append([box(0.55, 0.04, 0.04), at(0, hy, -0.42), WOOD.darkened(0.3)])
			p.append([box(0.5, 0.01, 0.01), at(0, hy + 0.035, -0.36), Color(0.9, 0.9, 0.85)])   # the string
		"heavy_crossbow":                              # bigger, with a steel prod and a crank
			p.append([box(0.08, 0.08, 0.7), at(0, hy, -0.28), WOOD.darkened(0.15)])
			p.append([box(0.7, 0.05, 0.06), at(0, hy, -0.55), steel])
			p.append([box(0.64, 0.01, 0.01), at(0, hy + 0.04, -0.46), Color(0.9, 0.9, 0.85)])
			p.append([ball(0.05, 6, 3), at(0.07, hy, 0.02), steel])
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
		"nightmare":
			fur = Color(0.1, 0.08, 0.1)
			length = 1.15
			girth = 0.44
			leg_len = 0.72
		"swamp_dragon":
			fur = Color(0.3, 0.45, 0.25)
			length = 1.3
			girth = 0.5
			leg_len = 0.38
		"beetle":
			fur = Color(0.14, 0.17, 0.24)
			length = 1.0
			girth = 0.5
			leg_len = 0.3
	var top := leg_len + girth / 2.0
	var necked := look in ["hind", "horse", "llama", "nightmare"]
	var neck := 0.6 if look == "llama" else (0.42 if look == "horse" else 0.32)
	var key := "quad|" + look
	var body := _cached(key, func() -> Array:
		var p := [[box(girth, girth, length), at(0, top, 0), fur]]
		var head_y := top + (neck if necked else 0.08)
		var head_z := -length / 2.0 - 0.12
		if necked:
			p.append([box(girth * 0.45, neck + 0.15, girth * 0.45), at(0, top + neck * 0.5, -length / 2.0 + 0.02, Vector3(0.45 if look != "llama" else 0.15, 0, 0)), fur])
		if look == "horse" or look == "nightmare":
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
			"nightmare":
				p.append([box(0.05, 0.05, 0.03), at(-girth * 0.2, head_y + 0.05, head_z - girth * 0.42), Color(1.0, 0.25, 0.1)])
				p.append([box(0.05, 0.05, 0.03), at(girth * 0.2, head_y + 0.05, head_z - girth * 0.42), Color(1.0, 0.25, 0.1)])
			"swamp_dragon":
				for k in range(4):
					p.append([cone(0.07, 0.18, 0.0, 4), at(0, top + girth * 0.55, -length * 0.3 + k * length * 0.2), Color(0.55, 0.6, 0.3)])
				p.append([cone(0.14, 0.9, 0.02, 5), at(0, top - 0.05, length / 2.0 + 0.4, Vector3(-1.35, 0, 0)), fur.darkened(0.1)])
				p.append([box(0.04, 0.03, 0.03), at(-0.08, head_y - 0.1, head_z - girth * 0.8), Color(0.95, 0.92, 0.85)])
				p.append([box(0.04, 0.03, 0.03), at(0.08, head_y - 0.1, head_z - girth * 0.8), Color(0.95, 0.92, 0.85)])
				p.append([box(girth * 1.02, 0.1, 0.4), at(0, top + girth * 0.5, 0.05), Color(0.35, 0.2, 0.1)])   # saddle
			"beetle":
				p.append([ball(girth * 0.85, 8, 4), at(0, top + girth * 0.2, 0.05, Vector3.ZERO, Vector3(1.0, 0.6, 1.25)), fur.lightened(0.12)])
				p.append([cone(0.07, 0.35, 0.0, 5), at(0, head_y + 0.12, head_z - 0.1, Vector3(-0.9, 0, 0)), Color(0.2, 0.22, 0.3)])
				p.append([box(girth * 0.8, 0.1, 0.4), at(0, top + girth * 0.62, 0.05), Color(0.35, 0.2, 0.1)])   # saddle
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


## A big running bird: long legs, a neck reaching forward, a crest and a tail.
static func _ostard(model: Dictionary) -> void:
	var root: Node3D = model["root"]
	var meshes: Array = model["meshes"]
	var hide := Color(0.55, 0.42, 0.24)
	var body := _cached("ostard", func() -> Array:
		return [[ball(0.34, 8, 5), at(0, 0.95, 0.05, Vector3.ZERO, Vector3(0.9, 0.8, 1.3)), hide],
			[box(0.14, 0.5, 0.14), at(0, 1.25, -0.35, Vector3(0.6, 0, 0)), hide],
			[box(0.2, 0.18, 0.3), at(0, 1.5, -0.55), hide.lightened(0.1)],
			[cone(0.06, 0.2, 0.0, 4), at(0, 1.47, -0.78, Vector3(-PI / 2, 0, 0)), Color(0.85, 0.7, 0.3)],
			[cone(0.05, 0.25, 0.0, 4), at(0, 1.7, -0.5, Vector3(-0.4, 0, 0)), Color(0.75, 0.25, 0.2)],
			[box(0.04, 0.04, 0.03), at(-0.08, 1.54, -0.69), DARK], [box(0.04, 0.04, 0.03), at(0.08, 1.54, -0.69), DARK],
			[cone(0.18, 0.6, 0.02, 5), at(0, 1.0, 0.55, Vector3(-1.2, 0, 0)), hide.darkened(0.15)],
			[box(0.5, 0.1, 0.4), at(0, 1.22, 0.05), Color(0.35, 0.2, 0.1)]])   # saddle
	_instance(root, body, vc_mat(), meshes)
	var leg := _cached("ostard_leg", func() -> Array:
		return [[box(0.08, 0.72, 0.08), at(0, -0.36, 0), Color(0.75, 0.6, 0.3)],
			[box(0.16, 0.04, 0.2), at(0, -0.72, -0.05), Color(0.6, 0.45, 0.2)]])
	for side in [-1.0, 1.0]:
		var piv := _pivot(root, Vector3(0.14 * side, 0.74, 0.05))
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


# --- loot icons -------------------------------------------------------------

## The kind of thing an item is, for its icon and colour.
static func item_category(id: String) -> String:
	if id == "gold" or id == "reagents":
		return id
	if Gear.has(id):
		return String(Gear.stats(id)["slot"])
	if Items.is_scroll(id):
		return "scroll"
	if Items.is_potion(id):
		return "potion"
	if Items.is_food(id):
		return "food"
	if Items.is_tool_item(id):
		return "tool"
	if Items.is_instrument(id):
		return "instrument"
	if id == "log":
		return "log"
	if id.begins_with("ingot_") or id.begins_with("ore_"):
		return "metal"
	if id == "wolf_pelt":
		return "pelt"
	return "trophy"


static func item_color(id: String) -> Color:
	match item_category(id):
		"gold":
			return Color(1.0, 0.85, 0.3)
		"reagents":
			return Color(0.75, 0.55, 0.95)
		"weapon", "armor", "shield":
			return Color(0.7, 0.85, 1.0)
		"scroll":
			return Color(0.95, 0.9, 0.7)
		"potion":
			return Color(1.0, 0.5, 0.5)
		"metal", "log", "pelt":
			return Color(0.85, 0.7, 0.5)
	return Color(0.92, 0.92, 0.88)


## A small icon for a looted item (cached per kind).
static func item_icon(id: String) -> ArrayMesh:
	var cat := item_category(id)
	return _cached("icon|" + cat, func() -> Array:
		match cat:
			"gold":
				return [[cone(0.12, 0.03, 0.12, 10), at(0, 0, 0, Vector3(PI / 2, 0, 0)), Color(1.0, 0.82, 0.25)],
					[cone(0.12, 0.03, 0.12, 10), at(0.08, -0.06, 0.02, Vector3(PI / 2, 0, 0)), Color(0.95, 0.75, 0.2)]]
			"reagents":
				return [[ball(0.12, 6, 3), at(0, -0.02, 0), Color(0.45, 0.3, 0.55)], [box(0.06, 0.06, 0.06), at(0, 0.11, 0), Color(0.3, 0.2, 0.35)]]
			"weapon":
				return [[box(0.04, 0.4, 0.02), at(0, 0.06, 0), STEEL], [box(0.16, 0.03, 0.04), at(0, -0.14, 0), Color(0.6, 0.5, 0.2)],
					[box(0.04, 0.1, 0.04), at(0, -0.2, 0), WOOD]]
			"armor":
				return [[box(0.26, 0.24, 0.08), at(0, 0, 0), CHAIN], [box(0.36, 0.08, 0.09), at(0, 0.1, 0), CHAIN.lightened(0.15)]]
			"shield":
				return [[cone(0.16, 0.03, 0.16, 10), at(0, 0, 0, Vector3(PI / 2, 0, 0)), WOOD], [ball(0.04, 5, 3), at(0, 0, -0.02), STEEL]]
			"scroll":
				return [[cone(0.05, 0.26, 0.05, 7), at(0, 0, 0, Vector3(0, 0, PI / 2)), Color(0.93, 0.87, 0.68)],
					[box(0.02, 0.12, 0.12), at(0, 0, 0), Color(0.7, 0.2, 0.2)]]
			"potion":
				return [[ball(0.09, 7, 4), at(0, -0.04, 0), Color(0.9, 0.25, 0.25)], [box(0.04, 0.1, 0.04), at(0, 0.08, 0), Color(0.8, 0.85, 0.9)]]
			"food":
				return [[ball(0.12, 6, 3), at(0, 0, 0, Vector3.ZERO, Vector3(1.3, 0.7, 0.9)), Color(0.8, 0.6, 0.3)]]
			"tool":
				return [[box(0.04, 0.34, 0.04), at(0, 0, 0), WOOD], [box(0.2, 0.06, 0.05), at(0, 0.15, 0), STEEL]]
			"instrument":
				return [[ball(0.1, 7, 4), at(0, -0.06, 0), WOOD], [box(0.04, 0.24, 0.03), at(0, 0.1, 0), WOOD.darkened(0.3)]]
			"metal":
				return [[box(0.24, 0.07, 0.11), at(0, 0, 0), Color(0.62, 0.62, 0.66)]]
			"log":
				return [[cone(0.06, 0.3, 0.06, 6), at(0, 0, 0, Vector3(0, 0, PI / 2)), Color(0.45, 0.3, 0.15)]]
			"pelt":
				return [[box(0.3, 0.03, 0.22), at(0, 0, 0, Vector3(0.6, 0, 0)), Color(0.55, 0.55, 0.58)]]
		return [[ball(0.08, 6, 3), at(0, 0, 0), Color(0.85, 0.85, 0.8)], [box(0.05, 0.12, 0.05), at(0, 0.08, 0), Color(0.75, 0.75, 0.7)]])


# --- health bars ----------------------------------------------------------------

const HP_BAR_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform float fill = 1.0;
uniform vec4 tint : source_color = vec4(0.0);    // alpha > 0.5: a fixed colour (the cast bar)

void vertex() {
	// always face the camera
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec3 full = vec3(0.25, 0.85, 0.3);
	vec3 half_hp = vec3(0.95, 0.8, 0.2);
	vec3 low = vec3(0.9, 0.2, 0.15);
	vec3 bar = fill > 0.5 ? mix(half_hp, full, (fill - 0.5) * 2.0) : mix(low, half_hp, fill * 2.0);
	if (tint.a > 0.5) {
		bar = tint.rgb;
	}
	vec3 col = UV.x < fill ? bar : vec3(0.12, 0.12, 0.14);
	float edge = step(UV.x, 0.025) + step(0.975, UV.x) + step(UV.y, 0.15) + step(0.85, UV.y);
	ALBEDO = edge > 0.0 ? vec3(0.02) : col;
	ALPHA = 0.95;
}
"""

static var _hp_shader: Shader


## A small health bar that always faces the camera; set its "fill" (0..1).
static func hp_bar() -> MeshInstance3D:
	if _hp_shader == null:
		_hp_shader = Shader.new()
		_hp_shader.code = HP_BAR_SHADER
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.13)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	var m := ShaderMaterial.new()
	m.shader = _hp_shader
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	return mi


## A flat glowing ring on the ground (under the hero and its target).
static func ground_ring(c: Color, radius: float) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = radius * 0.86
	t.outer_radius = radius
	t.rings = 24
	t.ring_segments = 6
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = m
	mi.scale = Vector3(1.0, 0.15, 1.0)         # flattened onto the ground
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
