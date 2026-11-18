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
## The "Richer graphics" experiment: round things shaded smooth, a rim of light on everything, and
## creatures built finer (rounder limbs and heads, bevelled edges). Set before the world is built.
static var rich := false
static var _hi := false                 # (while a creature is being built: the finer shapes)
## The light of the other dimension (the Shardveil) on everything built from shapes: walls, rocks,
## creatures, the car. White at home.
static var tint := Color.WHITE


static func set_tint(c: Color) -> void:
	tint = c
	for m in _mat_cache.values():
		if m is StandardMaterial3D and (m as StandardMaterial3D).vertex_color_use_as_albedo:
			(m as StandardMaterial3D).albedo_color = c


# --- materials ------------------------------------------------------------

## The shared material for merged meshes: albedo from the vertex (and instance) colours.
static func vc_mat(alpha := false) -> StandardMaterial3D:
	var key := "vc%s" % alpha
	if not _mat_cache.has(key):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		m.albedo_color = tint
		if rich:
			m.rim_enabled = true                   # a soft rim of light round every edge against the sky
			m.rim = 0.3
			m.rim_tint = 0.45
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
	if _hi:
		segments = maxi(segments, 12)
		rings = maxi(rings, 7)
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
	if _hi:
		segments = maxi(segments, 10)
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
		var prim: PrimitiveMesh = p[0]
		var arr: Array
		if _hi and prim is BoxMesh:
			arr = _bevel_box((prim as BoxMesh).size)   # (richer: a box with its edges bevelled)
		else:
			arr = prim.get_mesh_arrays()
		var xf: Transform3D = p[1]
		var col: Color = p[2]
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		# richer: round things shaded smooth (their own normals), the rest flat
		var smooth := rich and (prim is SphereMesh or prim is CapsuleMesh or prim is CylinderMesh or prim is TorusMesh)
		var vn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if smooth else PackedVector3Array()
		var nb := xf.basis.inverse().transposed()
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
			for k in range(3):
				if smooth:
					var sn: Vector3 = (nb * vn[ix[t + k]]).normalized()
					norms.append(sn if sn.dot(n) > -0.2 else n)
				else:
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


## A box of `size` with its twelve edges bevelled (a cut across each edge and each corner), as mesh
## arrays: catches the light along its edges like a carved or forged thing, not a block.
static func _bevel_box(size: Vector3) -> Array:
	var h := size * 0.5
	var r := minf(minf(h.x, h.y), h.z) * 0.38
	var pts := func(sx: float, sy: float, sz: float, axis: int) -> Vector3:
		var q := Vector3(sx * (h.x - r), sy * (h.y - r), sz * (h.z - r))
		q[axis] = [sx, sy, sz][axis] * h[axis]
		return q
	var tris: Array[Vector3] = []
	for a in range(3):                                   # the six faces
		var u := (a + 1) % 3
		var w := (a + 2) % 3
		for s in [-1.0, 1.0]:
			var fq: Array[Vector3] = []
			for uv in [[-1.0, -1.0], [1.0, -1.0], [1.0, 1.0], [-1.0, 1.0]]:
				var c := [0.0, 0.0, 0.0]
				c[a] = s
				c[u] = uv[0]
				c[w] = uv[1]
				fq.append(pts.call(c[0], c[1], c[2], a))
			tris.append_array([fq[0], fq[1], fq[2], fq[0], fq[2], fq[3]])
	for a in range(3):                                   # the twelve edges
		var b := (a + 1) % 3
		var k := (a + 2) % 3
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var c0 := [0.0, 0.0, 0.0]
				c0[a] = sa
				c0[b] = sb
				c0[k] = -1.0
				var c1 := c0.duplicate()
				c1[k] = 1.0
				var e0: Vector3 = pts.call(c0[0], c0[1], c0[2], a)
				var e1: Vector3 = pts.call(c1[0], c1[1], c1[2], a)
				var e2: Vector3 = pts.call(c1[0], c1[1], c1[2], b)
				var e3: Vector3 = pts.call(c0[0], c0[1], c0[2], b)
				tris.append_array([e0, e1, e2, e0, e2, e3])
	for sx in [-1.0, 1.0]:                               # the eight corners
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				tris.append_array([pts.call(sx, sy, sz, 0), pts.call(sx, sy, sz, 1), pts.call(sx, sy, sz, 2)])
	var verts := PackedVector3Array()
	var idx := PackedInt32Array()
	for t in range(0, tris.size(), 3):                  # every triangle facing outwards
		var p0 := tris[t]
		var p1 := tris[t + 1]
		var p2 := tris[t + 2]
		if (p1 - p0).cross(p2 - p0).dot(p0 + p1 + p2) < 0.0:
			var tmp := p1
			p1 = p2
			p2 = tmp
		for corner in [p0, p1, p2]:
			idx.append(verts.size())
			verts.append(corner)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_INDEX] = idx
	return out


## A soft dark patch on the ground under a body (the "Richer graphics" experiment): it sits the
## figure on the land instead of floating over it.
const CONTACT_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	ALBEDO = vec3(0.0);
	ALPHA = 0.42 * (1.0 - smoothstep(0.3, 1.0, d));
}
"""
static var _contact_mesh: PlaneMesh
static var _contact_mat: ShaderMaterial


static func contact_shadow(s: float) -> MeshInstance3D:
	if _contact_mesh == null:
		_contact_mesh = PlaneMesh.new()
		_contact_mesh.size = Vector2(1.0, 1.0)
		var sh := Shader.new()
		sh.code = CONTACT_SHADER
		_contact_mat = ShaderMaterial.new()
		_contact_mat.shader = sh
	var mi := MeshInstance3D.new()
	mi.mesh = _contact_mesh
	mi.material_override = _contact_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.scale = Vector3.ONE * 1.15 * s
	mi.position.y = 0.04
	return mi


## Starts afresh for the "Richer graphics" switch: the shared meshes and materials are rebuilt
## the new way (they outlive a restart of the game otherwise).
static func set_rich(on: bool) -> void:
	if on != rich:
		_mesh_cache.clear()                    # (shapes from now on built the new way)
		for m in _mat_cache.values():          # the shared colours: the rim of light on or off, in place
			if m is StandardMaterial3D and (m as StandardMaterial3D).vertex_color_use_as_albedo:
				(m as StandardMaterial3D).rim_enabled = on
				(m as StandardMaterial3D).rim = 0.3
				(m as StandardMaterial3D).rim_tint = 0.45
	rich = on


## The Riftrunner (the "Dimension car" experiment): a low open car of violet metal on four wheels,
## glowing strips along its sides, lamps before and behind, and a shard of crystal turning slowly
## in a cradle behind the seat - the heart that tears a way through to another dimension. The
## wheels turn as it goes ("wheels"); the shard spins ("spin"). Forward is -Z, like the rest.
static func _car(model: Dictionary) -> void:
	var root: Node3D = model["root"]
	var meshes: Array = model["meshes"]
	var body := _cached("car|body", func() -> Array:
		var paint := Color(0.36, 0.16, 0.62)
		var dark := Color(0.1, 0.08, 0.14)
		var chrome := Color(0.78, 0.8, 0.86)
		return [[Art.box(1.16, 0.26, 2.2), Art.at(0, 0.42, 0), paint],                                  # the body
			[Art.box(1.1, 0.14, 0.72), Art.at(0, 0.6, -0.74, Vector3(-0.1, 0, 0)), paint.lightened(0.1)],   # the bonnet
			[Art.box(1.1, 0.16, 0.56), Art.at(0, 0.6, 0.82), paint.darkened(0.1)],                       # the back
			[Art.box(1.0, 0.3, 0.04), Art.at(0, 0.78, -0.36, Vector3(0.55, 0, 0)), Color(0.6, 0.85, 0.95)],   # the windscreen
			[Art.box(0.52, 0.1, 0.44), Art.at(0, 0.6, 0.16), dark],                                      # the seat
			[Art.box(0.52, 0.42, 0.1), Art.at(0, 0.78, 0.4, Vector3(-0.15, 0, 0)), dark],                # and its back
			[Art.box(1.2, 0.08, 0.16), Art.at(0, 0.36, -1.12), chrome],                                  # the bumpers
			[Art.box(1.2, 0.08, 0.16), Art.at(0, 0.36, 1.12), chrome],
			[Art.box(0.08, 0.3, 0.32), Art.at(-0.5, 0.8, 0.98, Vector3(0.3, 0, 0)), paint.darkened(0.2)],   # two fins
			[Art.box(0.08, 0.3, 0.32), Art.at(0.5, 0.8, 0.98, Vector3(0.3, 0, 0)), paint.darkened(0.2)],
			[Art.cone(0.16, 0.1, 0.12, 8), Art.at(0, 0.73, 0.72), chrome],                               # the shard's cradle
			[Art.box(0.96, 0.05, 1.6), Art.at(0, 0.28, 0), dark]])                                       # the floor
	_instance(root, body, vc_mat(), meshes)
	var neon := _cached("car|neon", func() -> Array:
		return [[Art.box(0.04, 0.05, 1.7), Art.at(-0.59, 0.38, 0), Color.WHITE],
			[Art.box(0.04, 0.05, 1.7), Art.at(0.59, 0.38, 0), Color.WHITE]])
	_instance(root, neon, glow_mat(Color(0.3, 0.95, 1.0)), meshes).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var lamps := _cached("car|lamps", func() -> Array:
		return [[Art.ball(0.08, 6, 4), Art.at(-0.42, 0.47, -1.1), Color.WHITE],
			[Art.ball(0.08, 6, 4), Art.at(0.42, 0.47, -1.1), Color.WHITE]])
	_instance(root, lamps, glow_mat(Color(1.0, 0.95, 0.8)), meshes).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tails := _cached("car|tails", func() -> Array:
		return [[Art.box(0.16, 0.06, 0.03), Art.at(-0.42, 0.47, 1.11), Color.WHITE],
			[Art.box(0.16, 0.06, 0.03), Art.at(0.42, 0.47, 1.11), Color.WHITE]])
	_instance(root, tails, glow_mat(Color(1.0, 0.2, 0.3)), meshes).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the shard, turning in its cradle
	var spin := _pivot(root, Vector3(0, 0.96, 0.72))
	var shard := _cached("car|shard", func() -> Array:
		return [[Art.cone(0.12, 0.22, 0.0, 6), Art.at(0, 0.11, 0), Color.WHITE],
			[Art.cone(0.12, 0.16, 0.0, 6), Art.at(0, -0.08, 0, Vector3(PI, 0, 0)), Color.WHITE]])
	_instance(spin, shard, glow_mat(Color(0.85, 0.45, 1.0)), meshes).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	model["spin"] = spin
	# four wheels, each turning on its axle as the car goes (a spoke shows the turning)
	var wheel := _cached("car|wheel", func() -> Array:
		return [[Art.cone(0.28, 0.2, 0.28, 12), Art.at(0, 0, 0, Vector3(0, 0, PI * 0.5)), Color(0.08, 0.08, 0.09)],
			[Art.cone(0.15, 0.22, 0.15, 8), Art.at(0, 0, 0, Vector3(0, 0, PI * 0.5)), Color(0.78, 0.8, 0.86)],
			[Art.box(0.23, 0.07, 0.42), Art.at(0, 0, 0), Color(0.3, 0.3, 0.33)]])
	var wheels: Array = []
	for w: Vector3 in [Vector3(-0.6, 0.28, -0.72), Vector3(0.6, 0.28, -0.72), Vector3(-0.6, 0.28, 0.74), Vector3(0.6, 0.28, 0.74)]:
		var piv := _pivot(root, w)
		_instance(piv, wheel, vc_mat(), meshes)
		wheels.append(piv)
	model["wheels"] = wheels
	model["quad"] = true


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
	var model := {"root": root, "legs": [], "arm": null, "spin": null, "meshes": [], "quad": false, "arm_rest": 0.0,
		"knees": [], "hips": [], "arm_l": null, "elbow": null, "elbow_l": null, "head": null}
	_hi = rich                                     # (richer: built finer)
	match look:
		"rat", "wolf", "bear", "hind", "horse", "llama", "nightmare", "swamp_dragon", "beetle":
			_quadruped(model, look)
		"ostard":
			_ostard(model)
		"spider":
			_spider(model)
		"scorpion":
			_scorpion(model)
		"leech":
			_leech(model)
		"earth_elemental", "air_elemental", "fire_elemental", "water_elemental":
			_elemental(model, look)
		"vortex", "blades":
			_spinner(model, look)
		"car":
			_car(model)
		_:
			_humanoid(model, look, style)
	_hi = false
	return model


const HEAD_FROM := 1.31             # parts at or above this height belong to the head
const KNEE := 0.32                  # the knee below the hip, and the elbow below the shoulder
const ELBOW := 0.26


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
	var amulet := String(style.get("amulet", ""))
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
			model["arm_rest"] = 1.4
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
		"goblin":                                  # small, green, big-eared
			skin = Color(0.45, 0.62, 0.22)
			hair = DARK
			cloth = Color(0.4, 0.3, 0.18)
			pants = Color(0.3, 0.22, 0.12)
			build = 0.85
		"mummy":                                   # wrapped head to foot, reaching
			skin = Color(0.8, 0.74, 0.58)
			hair = skin
			cloth = skin
			pants = skin.darkened(0.08)
			model["arm_rest"] = 1.4
		"yeti":                                    # a great white ape of the snows
			skin = Color(0.92, 0.94, 0.97)
			hair = skin
			cloth = skin
			pants = skin.darkened(0.06)
			build = 1.45
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
	var frame_parts := func() -> Array:
		var p := []
		# a human frame: broad chest tapering to the waist, shoulders, a neck; belt and tabard
		p.append([box(0.46 * w, 0.32, 0.28 * w), at(0, 1.12, 0), torso_col])
		p.append([box(0.4 * w, 0.28, 0.25 * w), at(0, 0.86, 0), torso_col])
		p.append([ball(0.085 * w, 6, 3), at(-0.27 * w, 1.24, 0), torso_col])
		p.append([ball(0.085 * w, 6, 3), at(0.27 * w, 1.24, 0), torso_col])
		p.append([box(0.1, 0.1, 0.1), at(0, 1.29, 0), skin.darkened(0.08)])
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
		if look == "goblin":                           # long pointed ears and a hooked nose
			p.append([cone(0.05, 0.2), at(-0.2, 1.46, 0, Vector3(0, 0, 1.3)), skin.darkened(0.1)])
			p.append([cone(0.05, 0.2), at(0.2, 1.46, 0, Vector3(0, 0, -1.3)), skin.darkened(0.1)])
			p.append([cone(0.035, 0.1), at(0, 1.4, -0.18, Vector3(-1.4, 0, 0)), skin.darkened(0.15)])
		if look == "mummy":                            # the wrappings: bands round body and head
			for i in range(5):
				p.append([box(0.5 * w, 0.03, 0.31 * w), at(0, 0.8 + 0.11 * i, 0, Vector3(0, 0, 0.12 * (i % 2 * 2 - 1))), skin.darkened(0.18)])
			for i in range(3):
				p.append([box(0.36, 0.025, 0.36), at(0, 1.35 + 0.08 * i, 0, Vector3(0, 0, 0.15 * (i % 2 * 2 - 1))), skin.darkened(0.2)])
		if look == "yeti":                             # shaggy fur, a pale blue face and great horns of ice
			for i in range(6):
				var a := TAU * i / 6.0
				p.append([ball(0.12, 6, 3), at(cos(a) * 0.24 * w, 1.05 + 0.08 * (i % 2), sin(a) * 0.14 * w), skin.darkened(0.05)])
			p.append([box(0.22, 0.16, 0.03), at(0, 1.42, -0.16), Color(0.55, 0.68, 0.85)])
			p.append([cone(0.05, 0.2), at(-0.13, 1.6, 0, Vector3(0, 0, 0.5)), Color(0.75, 0.88, 1.0)])
			p.append([cone(0.05, 0.2), at(0.13, 1.6, 0, Vector3(0, 0, -0.5)), Color(0.75, 0.88, 1.0)])
		# head, hair, eyes
		p.append([ball(0.165, 8, 5), at(0, 1.44, 0, Vector3.ZERO, Vector3(0.92, 1.08, 0.98)), skin])
		p.append([box(0.2, 0.09, 0.2), at(0, 1.34, -0.02), skin])                    # the jaw
		if not bony:
			p.append([box(0.04, 0.07, 0.05), at(0, 1.41, -0.165), skin.darkened(0.06)])   # nose
			p.append([box(0.03, 0.07, 0.05), at(-0.155, 1.44, 0), skin.darkened(0.05)])   # ears
			p.append([box(0.03, 0.07, 0.05), at(0.155, 1.44, 0), skin.darkened(0.05)])
			p.append([box(0.09, 0.02, 0.02), at(0, 1.355, -0.15), skin.darkened(0.35)])   # mouth
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
		# legs: a robe, or the hips the legs hang from
		if robe:
			p.append([cone(0.36, 0.78, 0.2, 9), at(0, 0.39, 0), cloth])
		else:
			p.append([box(0.4 * w, 0.12, 0.24 * w), at(0, 0.7, 0), pants])
		return p
	# The head turns on the neck by itself: everything from the chin up is its own piece.
	var body := _cached(key, func() -> Array:
		return (frame_parts.call() as Array).filter(func(e) -> bool: return (e[1] as Transform3D).origin.y < HEAD_FROM))
	var head_mesh := _cached(key + "|head", func() -> Array:
		return (frame_parts.call() as Array).filter(func(e) -> bool: return (e[1] as Transform3D).origin.y >= HEAD_FROM))
	_instance(root, body, vc_mat(), meshes)
	var neck := Vector3(0, 1.3, 0)
	var head_piv := _pivot(root, neck)
	var head_frame := _pivot(head_piv, -neck)          # so the head's parts keep their body coordinates
	_instance(head_frame, head_mesh, vc_mat(), meshes)
	model["head"] = head_piv
	if amulet != "":                                   # a gold chain and a glowing gem on the chest
		var gem: Color = Jewelry.GEM.get(amulet, Color(0.9, 0.8, 0.4))
		var chain := _cached("amulet|" + amulet, func() -> Array:
			return [[box(0.2, 0.02, 0.02), at(0, 1.27, -0.15, Vector3(0, 0, 0)), TRIM],
				[box(0.02, 0.12, 0.02), at(-0.08, 1.21, -0.155, Vector3(0, 0, 0.5)), TRIM],
				[box(0.02, 0.12, 0.02), at(0.08, 1.21, -0.155, Vector3(0, 0, -0.5)), TRIM],
				[ball(0.045, 6, 3), at(0, 1.13, -0.165), gem]])
		_instance(root, chain, glow_mat(gem), meshes)
	if holy:                                           # a glowing halo over the hood
		var halo := _cached("halo", func() -> Array:
			return [[ring_mesh(0.17, 0.2), at(0, 1.78, 0.02), Color(1.0, 0.86, 0.4)]])
		_instance(head_frame, halo, glow_mat(Color(1.0, 0.82, 0.35)), meshes)
	if look == "lich":
		var eyes := _cached("lich_eyes", func() -> Array:
			return [[box(0.05, 0.04, 0.02), at(-0.07, 1.45, -0.19), Color(0.6, 1.0, 0.7)],
				[box(0.05, 0.04, 0.02), at(0.07, 1.45, -0.19), Color(0.6, 1.0, 0.7)]])
		_instance(head_frame, eyes, glow_mat(Color(0.5, 1.0, 0.6)), meshes)
	# legs: a thigh from the hip and a shin from the knee
	if not robe:
		var leg_parts := func() -> Array:
			var lp := [[box(0.16 * w, 0.34, 0.18 * w), at(0, -0.16, 0), pants],
				[box(0.14 * w, 0.3, 0.16 * w), at(0, -0.47, 0), pants.darkened(0.04)],
				[box(0.17 * w, 0.1, 0.24 * w), at(0, -0.64, -0.03), boots]]
			match ab:
				"platemail":                         # knee cop and a tall greave
					lp.append([ball(0.075, 6, 3), at(0, -0.33, -0.08), pants.lightened(0.1)])
					lp.append([box(0.17 * w, 0.22, 0.19 * w), at(0, -0.5, 0), boots])
				"leather_armor", "studded_armor":   # tall boots
					lp.append([box(0.165 * w, 0.2, 0.185 * w), at(0, -0.52, 0), Color(0.22, 0.15, 0.1)])
			return lp
		var leg_key := "leg|%s|%s|%s|%s" % [pants.to_html(), w, ab, boots.to_html()]
		var thigh := _cached(leg_key + "|thigh", func() -> Array:
			return (leg_parts.call() as Array).filter(func(e) -> bool: return (e[1] as Transform3D).origin.y > -KNEE))
		var shin := _cached(leg_key + "|shin", func() -> Array:
			return (leg_parts.call() as Array).filter(func(e) -> bool: return (e[1] as Transform3D).origin.y <= -KNEE))
		for side in [-1.0, 1.0]:
			var piv := _pivot(root, Vector3(0.11 * w * side, 0.7, 0))
			_instance(piv, thigh, vc_mat(), meshes)
			var knee := _pivot(piv, Vector3(0, -KNEE, 0))
			_instance(_pivot(knee, Vector3(0, KNEE, 0)), shin, vc_mat(), meshes)
			model["legs"].append(piv)
			model["knees"].append(knee)
		model["hips"] = (model["legs"] as Array).duplicate()
	# the left arm: upper arm from the shoulder, forearm (with the hand and the shield) from the elbow
	var sh_l := Vector3(-0.3 * w, 1.22, 0)
	var arm_l := _pivot(root, sh_l)
	var upper_l := _cached("arml|%s|%s" % [torso_col.to_html(), w], func() -> Array:
		return [[box(0.12 * w, 0.27, 0.14 * w), at(0, -0.13, 0), torso_col]])
	_instance(arm_l, upper_l, vc_mat(), meshes)
	var elbow_l := _pivot(arm_l, Vector3(0, -ELBOW, 0))
	var fore_l := _cached("forel|%s|%s|%s|%s|%s" % [torso_col.to_html(), hands.to_html(), shield, w, cloth.to_html()], func() -> Array:
		var fp := [[box(0.11 * w, 0.24, 0.13 * w), at(-0.3 * w, 0.85, 0), torso_col], [ball(0.07, 6, 3), at(-0.3 * w, 0.71, 0), hands]]
		if shield != "":
			_shield_parts(fp, shield, cloth, w)
		return fp)
	_instance(_pivot(elbow_l, -(sh_l + Vector3(0, -ELBOW, 0))), fore_l, vc_mat(), meshes)   # (its parts are in body coordinates)
	arm_l.rotation.x = float(model["arm_rest"])
	model["arm_l"] = arm_l
	model["elbow_l"] = elbow_l
	# the right arm with the weapon: shoulder, elbow, hand
	var arm_piv := _pivot(root, Vector3(0.3 * w, 1.22, 0))
	var upper := _cached("armu|%s|%s|%s" % [torso_col.to_html(), w, ab], func() -> Array:
		var up := [[box(0.12 * w, 0.27, 0.14 * w), at(0, -0.13, 0), torso_col]]
		if ab == "platemail":                        # the right pauldron moves with the arm
			up.append([ball(0.14, 7, 4), at(0.02, 0.0, 0, Vector3.ZERO, Vector3(1.1, 0.75, 1.1)), torso_col.lightened(0.08)])
		return up)
	_instance(arm_piv, upper, vc_mat(), meshes)
	var elbow := _pivot(arm_piv, Vector3(0, -ELBOW, 0))
	var hand_frame := _pivot(elbow, Vector3(0, ELBOW, 0))     # the forearm's parts keep the arm's coordinates
	var fore := _cached("fore|%s|%s|%s|%s|%s" % [torso_col.to_html(), hands.to_html(), weapon, w, ab], func() -> Array:
		var rp := [[box(0.11 * w, 0.24, 0.13 * w), at(0, -0.37, 0), torso_col],
			[ball(0.07, 6, 3), at(0, -0.51, 0), hands]]
		if ab in ["leather_armor", "studded_armor"]:  # a bracer
			rp.append([box(0.14 * w, 0.14, 0.16 * w), at(0, -0.38, 0), Color(0.22, 0.15, 0.1)])
		rp.append_array(_weapon_parts(weapon))
		return rp)
	_instance(hand_frame, fore, vc_mat(), meshes)
	arm_piv.rotation.x = float(model["arm_rest"])
	model["arm"] = arm_piv
	model["elbow"] = elbow
	_artifact_parts(root, hand_frame, meshes, armor, weapon, shield, hat, w)

## Artifacts stand out: glowing runes on the blade (or a glowing head, string or prod), a cape in
## the artifact's colour with glowing rune bands on the armor and a glowing eye slit or circlet,
## and a glowing rim and boss on a shield. The glow is a separate material so it can bloom.
static func _artifact_parts(root: Node3D, arm_piv: Node3D, meshes: Array, armor: String, weapon: String,
		shield: String, hat: String, w: float) -> void:
	if Gear.is_artifact(weapon):
		var wc := metal_of(weapon, STEEL)
		var wg := _cached("artw|" + weapon, func() -> Array:
			return _weapon_glow_parts(weapon, wc))
		_instance(arm_piv, wg, glow_mat(wc), meshes)
	if Gear.is_artifact(armor):
		var ac := metal_of(armor, PLATE)
		var runes := _cached("arta|%s|%s|%s" % [armor, hat, w], func() -> Array:
			var p := [[box(0.04, 0.36, 0.02), at(-0.1 * w, 1.0, -0.158 * w), ac],
				[box(0.04, 0.36, 0.02), at(0.1 * w, 1.0, -0.158 * w), ac],
				[box(0.49 * w, 0.025, 0.31 * w), at(0, 1.2, 0), ac],
				[box(0.49 * w, 0.025, 0.31 * w), at(0, 0.8, 0), ac]]
			match hat:
				"plate_helm":
					p.append([box(0.25, 0.04, 0.02), at(0, 1.46, -0.213), ac])        # glowing eyes
				"coif":
					p.append([ring_mesh(0.19, 0.215), at(0, 1.55, 0.02), ac])         # a circlet
			return p)
		_instance(root, runes, glow_mat(ac), meshes)
		var cape := _cached("cape|%s|%s" % [ac.to_html(), w], func() -> Array:
			return [[box(0.44 * w, 0.95, 0.03), at(0, 0.8, 0.19 * w, Vector3(0.12, 0, 0)), ac.darkened(0.35)],
				[box(0.4 * w, 0.06, 0.035), at(0, 0.34, 0.25 * w, Vector3(0.12, 0, 0)), ac.darkened(0.1)],
				[box(0.46 * w, 0.05, 0.06), at(0, 1.27, 0.17 * w), ac]])
		_instance(root, cape, vc_mat(), meshes)
	if Gear.is_artifact(shield):
		var sc := metal_of(shield, STEEL)
		var x := -0.42 * w - 0.03
		var sg := _cached("arts|%s|%s" % [shield, w], func() -> Array:
			return [[box(0.012, 0.42, 0.035), at(x, 0.97, 0.17), sc], [box(0.012, 0.42, 0.035), at(x, 0.97, -0.17), sc],
				[box(0.012, 0.035, 0.36), at(x, 1.18, 0), sc], [ball(0.06, 6, 3), at(x - 0.01, 1.0, 0), sc]])
		_instance(root, sg, glow_mat(sc), meshes)


## The glowing part of an artifact weapon, in the arm's space (the hand is at y -0.51).
static func _weapon_glow_parts(weapon: String, c: Color) -> Array:
	var hy := -0.51
	match Gear.base(weapon):
		"short_sword", "longsword", "broadsword", "bonecleaver":
			var length := 0.55 if Gear.base(weapon) == "short_sword" else 0.78
			return [[box(0.014, 0.036, length * 0.85), at(0, hy + 0.012, -length / 2.0 - 0.07), c],
				[ball(0.04, 6, 3), at(0, hy + 0.03, -0.05), c]]
		"dagger", "kryss":
			return [[box(0.014, 0.036, 0.27), at(0, hy + 0.012, -0.21), c], [ball(0.035, 6, 3), at(0, hy + 0.025, -0.04), c]]
		"mace", "club":
			return [[ball(0.11, 7, 4), at(0, hy, -0.5), c]]
		"war_hammer":
			return [[box(0.26, 0.05, 0.14), at(0, hy + 0.05, -0.66), c], [box(0.26, 0.05, 0.14), at(0, hy - 0.05, -0.66), c]]
		"halberd":
			return [[box(0.036, 0.22, 0.17), at(0, hy + 0.98, -0.14), c]]
		"bow", "composite_bow":
			return [[box(0.014, 0.82, 0.014), at(0, hy, -0.01), c], [ball(0.035, 6, 3), at(0, hy + 0.43, -0.16), c],
				[ball(0.035, 6, 3), at(0, hy - 0.43, -0.16), c]]
		"crossbow", "heavy_crossbow":
			var z := -0.55 if Gear.base(weapon) == "heavy_crossbow" else -0.42
			return [[box(0.6, 0.03, 0.03), at(0, hy + 0.035, z), c], [ball(0.04, 6, 3), at(0, hy + 0.05, -0.1), c]]
	return []


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
		"scimitar":                                    # a curved blade
			p.append([box(0.05, 0.03, 0.34), at(0, hy, -0.22), steel])
			p.append([box(0.05, 0.03, 0.3), at(0.03, hy, -0.5, Vector3(0, 0.35, 0)), steel])
			p.append([box(0.16, 0.04, 0.04), at(0, hy, -0.05), Color(0.6, 0.5, 0.2)])
			p.append([box(0.04, 0.04, 0.12), at(0, hy, 0.03), DARK])
		"katana":                                      # long, slim, slightly curved, a round guard
			p.append([box(0.035, 0.025, 0.8), at(0, hy + 0.03, -0.45, Vector3(0.06, 0, 0)), steel])
			p.append([cone(0.07, 0.02, 0.07, 8), at(0, hy, -0.05, Vector3(PI / 2, 0, 0)), DARK])
			p.append([box(0.04, 0.04, 0.22), at(0, hy, 0.08), Color(0.2, 0.15, 0.25)])
		"viking_sword":                                # broad and straight, a heavy pommel
			p.append([box(0.08, 0.03, 0.72), at(0, hy, -0.42), steel])
			p.append([box(0.22, 0.05, 0.05), at(0, hy, -0.05), DARK])
			p.append([ball(0.05, 6, 3), at(0, hy, 0.12), Color(0.6, 0.5, 0.2)])
		"axe", "battle_axe", "double_axe", "war_axe":  # a haft and a head (two for the double axe)
			var haft := 0.75 if Gear.base(weapon) in ["battle_axe", "double_axe"] else 0.55
			p.append([box(0.04, 0.04, haft), at(0, hy, -haft / 2.0 + 0.05), WOOD])
			var head := 0.26 if Gear.base(weapon) == "battle_axe" else 0.2
			p.append([box(0.03, head, 0.14), at(0, hy + head / 2.0, -haft + 0.08), steel])
			if Gear.base(weapon) == "double_axe":
				p.append([box(0.03, head, 0.14), at(0, hy - head / 2.0, -haft + 0.08), steel])
			if Gear.base(weapon) == "war_axe":
				p.append([cone(0.03, 0.12, 0.0, 5), at(0, hy - 0.08, -haft + 0.08, Vector3(PI, 0, 0)), steel])
		"spear", "short_spear":
			var shaft := 1.2 if Gear.base(weapon) == "spear" else 0.8
			p.append([box(0.04, 0.04, shaft), at(0, hy, -shaft / 2.0 + 0.15), WOOD])
			p.append([cone(0.05, 0.22, 0.0, 6), at(0, hy, -shaft + 0.04, Vector3(-PI / 2, 0, 0)), steel])
		"war_fork":
			p.append([box(0.04, 0.04, 0.95), at(0, hy, -0.4), WOOD])
			for side: float in [-1.0, 0.0, 1.0]:
				p.append([box(0.02, 0.02, 0.22), at(side * 0.05, hy, -0.95), steel])
			p.append([box(0.14, 0.03, 0.03), at(0, hy, -0.84), steel])
		"quarterstaff":
			p.append([box(0.045, 1.6, 0.045), at(0, hy + 0.2, -0.06), WOOD.lightened(0.1)])
			p.append([box(0.055, 0.08, 0.055), at(0, hy + 0.95, -0.06), DARK])
			p.append([box(0.055, 0.08, 0.055), at(0, hy - 0.55, -0.06), DARK])
		"maul":
			p.append([box(0.04, 0.04, 0.6), at(0, hy, -0.25), WOOD])
			p.append([box(0.2, 0.16, 0.16), at(0, hy, -0.58), steel.darkened(0.15)])
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
		"rift_shotgun":                                # two barrels, a dark body, a wooden stock
			p.append([box(0.08, 0.09, 0.22), at(0, hy, 0.0), Color(0.16, 0.15, 0.18)])
			p.append([cone(0.032, 0.5, 0.032, 8), at(-0.03, hy + 0.03, -0.34, Vector3(PI / 2, 0, 0)), Color(0.5, 0.52, 0.56)])
			p.append([cone(0.032, 0.5, 0.032, 8), at(0.03, hy + 0.03, -0.34, Vector3(PI / 2, 0, 0)), Color(0.5, 0.52, 0.56)])
			p.append([box(0.06, 0.1, 0.24), at(0, hy - 0.03, 0.2), WOOD])
		"shard_rocket":                                # a long tube with a violet band, a grip and a sight
			p.append([cone(0.085, 0.85, 0.085, 10), at(0, hy + 0.06, -0.22, Vector3(PI / 2, 0, 0)), Color(0.28, 0.3, 0.34)])
			p.append([cone(0.095, 0.08, 0.095, 10), at(0, hy + 0.06, -0.62, Vector3(PI / 2, 0, 0)), Color(0.75, 0.4, 1.0)])
			p.append([box(0.05, 0.12, 0.06), at(0, hy - 0.06, -0.1), DARK])
			p.append([box(0.03, 0.06, 0.1), at(0, hy + 0.17, -0.2), DARK])
		"spike_gun":                                   # a drum of four barrels
			for k in range(4):
				var ang := k * PI / 2.0
				p.append([cone(0.022, 0.5, 0.022, 6), at(cos(ang) * 0.045, hy + sin(ang) * 0.045, -0.32, Vector3(PI / 2, 0, 0)), Color(0.62, 0.64, 0.7)])
			p.append([cone(0.08, 0.16, 0.08, 10), at(0, hy, -0.05, Vector3(PI / 2, 0, 0)), Color(0.2, 0.2, 0.24)])
			p.append([box(0.05, 0.12, 0.08), at(0, hy - 0.08, 0.06), DARK])
		"arc_caster":                                  # coils of teal round a short barrel, a glowing tip
			p.append([box(0.08, 0.08, 0.42), at(0, hy, -0.15), Color(0.2, 0.22, 0.26)])
			for k in range(3):
				p.append([ring_mesh(0.05, 0.075), at(0, hy, -0.08 - k * 0.12, Vector3(PI / 2, 0, 0)), Color(0.35, 0.95, 1.0)])
			p.append([ball(0.05, 6, 4), at(0, hy, -0.4), Color(0.6, 1.0, 1.0)])
		"ember_launcher":                              # a short fat barrel over an ember drum
			p.append([cone(0.07, 0.4, 0.07, 10), at(0, hy + 0.04, -0.22, Vector3(PI / 2, 0, 0)), Color(0.3, 0.26, 0.24)])
			p.append([cone(0.09, 0.12, 0.09, 10), at(0, hy - 0.04, -0.02, Vector3(0, 0, PI / 2)), Color(0.8, 0.4, 0.15)])
			p.append([box(0.05, 0.12, 0.07), at(0, hy - 0.1, 0.08), DARK])
		"heavy_crossbow":                              # bigger, with a steel prod and a crank
			p.append([box(0.08, 0.08, 0.7), at(0, hy, -0.28), WOOD.darkened(0.15)])
			p.append([box(0.7, 0.05, 0.06), at(0, hy, -0.55), steel])
			p.append([box(0.64, 0.01, 0.01), at(0, hy + 0.04, -0.46), Color(0.9, 0.9, 0.85)])
			p.append([ball(0.05, 6, 3), at(0.07, hy, 0.02), steel])
	return p


## A Shardveil gun strapped onto a beast's back on a little mount plate, pointing ahead (the
## "Shardveil chaos" experiment: beasts have no hands). Its shapes sit as a held gun's would, 0.51
## below the hand - the mesh is placed that much higher.
static func gun_turret(weapon: String) -> ArrayMesh:
	return _cached("turret|" + Gear.base(weapon), func() -> Array:
		var parts: Array = Art._weapon_parts(weapon)
		parts.append([Art.box(0.2, 0.05, 0.32), Art.at(0, -0.51 - 0.08, 0.0), Art.DARK])
		parts.append([Art.box(0.05, 0.08, 0.05), Art.at(0, -0.51 - 0.04, 0.0), Art.DARK])
		return parts)


## Where a beast's back is, in its own model (a gun strapped there sits on it).
const BACK_HEIGHT := {"rat": 0.32, "wolf": 0.78, "bear": 1.0, "hind": 0.85, "horse": 1.3, "llama": 1.25,
	"nightmare": 1.3, "swamp_dragon": 0.9, "beetle": 0.75, "ostard": 1.05, "spider": 0.6, "scorpion": 0.5,
	"leech": 0.25, "earth_elemental": 1.5, "air_elemental": 1.5, "fire_elemental": 1.5, "water_elemental": 1.5,
	"vortex": 1.1, "blades": 1.0, "ghost": 1.3}


static func back_height(look: String) -> float:
	return float(BACK_HEIGHT.get(look, 0.9))


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


## A desert scorpion: a low armoured body, two great pincers and a tail curled up over its back
## with a stinger.
static func _scorpion(model: Dictionary) -> void:
	var root: Node3D = model["root"]
	var body := _cached("scorpion", func() -> Array:
		var shell := Color(0.62, 0.45, 0.2)
		var dark := shell.darkened(0.35)
		var p := [[ball(0.3, 8, 5), at(0, 0.32, 0.05, Vector3.ZERO, Vector3(1.0, 0.55, 1.4)), shell],
			[ball(0.17, 7, 4), at(0, 0.3, -0.38, Vector3.ZERO, Vector3(1.1, 0.7, 0.9)), shell.lightened(0.08)],
			[box(0.05, 0.05, 0.03), at(-0.07, 0.36, -0.52), DARK], [box(0.05, 0.05, 0.03), at(0.07, 0.36, -0.52), DARK]]
		for i in range(4):                              # the bands of the back
			p.append([box(0.5, 0.04, 0.06), at(0, 0.45, 0.25 - 0.15 * i), dark])
		for side in [-1.0, 1.0]:
			for i in range(4):                          # legs
				var z := -0.2 + 0.15 * i
				p.append([box(0.45, 0.04, 0.04), at(side * 0.32, 0.25, z, Vector3(0, 0.2 * (i - 1.5), side * -0.5)), dark])
			# the pincers: an arm and a claw
			p.append([box(0.08, 0.08, 0.35), at(side * 0.25, 0.3, -0.62, Vector3(0, side * 0.35, 0)), shell])
			p.append([box(0.16, 0.1, 0.18), at(side * 0.33, 0.3, -0.82), shell.lightened(0.05)])
			p.append([box(0.05, 0.06, 0.16), at(side * 0.4, 0.3, -0.95), dark])
		# the tail: segments rising up and over, then the stinger
		var tz := 0.45
		var ty := 0.35
		for i in range(5):
			var ang := 0.45 * i
			tz += 0.13 * cos(ang)
			ty += 0.13 * sin(ang) + 0.04
			p.append([ball(0.09 - 0.008 * i, 6, 3), at(0, ty, tz), shell])
		p.append([cone(0.05, 0.18), at(0, ty + 0.1, tz - 0.12, Vector3(-2.3, 0, 0)), Color(0.25, 0.08, 0.05)])
		return p)
	_instance(root, body, vc_mat(), model["meshes"])


## A bog leech: a fat, glistening, segmented worm, its head raised with a ring of teeth.
static func _leech(model: Dictionary) -> void:
	var root: Node3D = model["root"]
	var body := _cached("leech", func() -> Array:
		var skin := Color(0.28, 0.22, 0.16)
		var p := []
		for i in range(7):
			var r := 0.17 - absf(i - 3.0) * 0.022
			var y := 0.16 + (0.12 if i == 0 else 0.0) + 0.03 * sin(i * 1.3)
			p.append([ball(r, 7, 4), at(sin(i * 0.9) * 0.08, y, -0.3 + 0.13 * i), skin.lightened(0.04 * (i % 2))])
		p.append([ring_mesh(0.05, 0.09), at(0, 0.3, -0.42, Vector3(PI / 2.0, 0, 0)), Color(0.75, 0.3, 0.3)])
		p.append([box(0.04, 0.04, 0.02), at(-0.06, 0.38, -0.38), Color(0.9, 0.8, 0.3)])
		p.append([box(0.04, 0.04, 0.02), at(0.06, 0.38, -0.38), Color(0.9, 0.8, 0.3)])
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


# --- ghosts ---------------------------------------------------------------------

const GHOST_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.75, 0.88, 1.0, 1.0);
varying float h;

void vertex() {
	h = VERTEX.y;
	// the shroud ripples, more towards the wispy tail
	float loose = clamp(1.4 - VERTEX.y, 0.0, 1.0);
	VERTEX.x += sin(TIME * 2.5 + VERTEX.y * 5.0) * 0.045 * loose;
	VERTEX.z += cos(TIME * 2.0 + VERTEX.y * 4.0) * 0.035 * loose;
}

void fragment() {
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float fade = smoothstep(0.15, 0.8, h);        // the tail dissolves into nothing
	ALBEDO = tint.rgb * COLOR.rgb;
	ALPHA = clamp((0.22 + rim * 0.65) * fade, 0.0, 0.85);
}
"""
static var _ghost_mat: ShaderMaterial


static func ghost_mat() -> ShaderMaterial:
	if _ghost_mat == null:
		var sh := Shader.new()
		sh.code = GHOST_SHADER
		_ghost_mat = ShaderMaterial.new()
		_ghost_mat.shader = sh
	return _ghost_mat


## A ghost: a hooded shroud with a dark hollow for a face and two glowing eyes, sleeves reaching
## out, no legs (the robe narrows to a wisp that fades away), pale blue and see-through.
static func ghost(scale: float) -> Dictionary:
	var root := Node3D.new()
	root.scale = Vector3.ONE * scale
	var model := {"root": root, "legs": [], "arm": null, "spin": null, "meshes": [], "quad": false, "arm_rest": 0.0,
		"knees": [], "hips": [], "arm_l": null, "elbow": null, "elbow_l": null, "head": null}
	var meshes: Array = model["meshes"]
	var shroud := _cached("ghost_shroud", func() -> Array:
		var c := Color(0.9, 0.94, 1.0)
		return [[cone(0.05, 1.05, 0.3, 10), at(0, 0.72, 0), c],            # the robe, narrowing to a wisp
			[cone(0.3, 0.26, 0.36, 10), at(0, 1.2, 0), c],                  # shoulders
			[ball(0.24, 9, 6), at(0, 1.43, 0.02), c],                         # the hood
			[box(0.12, 0.5, 0.14), at(-0.3, 1.0, -0.06, Vector3(0.55, 0, 0.25)), c],   # sleeves reaching out
			[box(0.12, 0.5, 0.14), at(0.3, 1.0, -0.06, Vector3(0.55, 0, -0.25)), c]])
	var body := _instance(root, shroud, ghost_mat(), meshes)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var face := _cached("ghost_face", func() -> Array:
		return [[box(0.25, 0.22, 0.06), at(0, 1.4, -0.18), Color(0.03, 0.04, 0.08)]])
	var f := _instance(root, face, vc_mat(), meshes)
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var eyes := _cached("ghost_eyes", func() -> Array:
		return [[box(0.05, 0.035, 0.02), at(-0.06, 1.43, -0.215), Color(0.55, 0.9, 1.0)],
			[box(0.05, 0.035, 0.02), at(0.06, 1.43, -0.215), Color(0.55, 0.9, 1.0)]])
	_instance(root, eyes, glow_mat(Color(0.5, 0.9, 1.0)), meshes)
	return model
