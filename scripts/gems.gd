class_name Gems
## Enchanting and gem sockets. Gear ids carry them as parts after "@" (like the metal and the
## maker's mark): "e1".."e3" for an enchantment (each level +8% damage or armour), and a gem's id for
## the one socketed stone (a ruby lends strength, a sapphire intelligence, an emerald dexterity, a
## diamond a little of all three). Both are done at the forge: enchanting costs cave crystals and
## gold and may fail; socketing a gem always works, but a piece holds only one.

const GEMS := {
	"ruby": {"name": "Ruby", "value": 90, "mods": {"str": 4}},
	"sapphire": {"name": "Sapphire", "value": 90, "mods": {"int": 4}},
	"emerald": {"name": "Emerald", "value": 90, "mods": {"dex": 4}},
	"diamond": {"name": "Diamond", "value": 160, "mods": {"str": 2, "dex": 2, "int": 2}},
}
const MAX_ENCHANT := 3
const ENCHANT_BONUS := 0.08
const ENCHANT_GOLD := 100          # times the new level
const ENCHANT_CHANCE := [0.9, 0.7, 0.5]


static func is_gem(id: String) -> bool:
	return GEMS.has(id)


static func enchant_level(id: String) -> int:
	for p in id.split("@"):
		if p.length() == 2 and p.begins_with("e") and p[1].is_valid_int():
			return int(p[1])
	return 0


## The gem set in this piece, or "".
static func gem_of(id: String) -> String:
	var parts := id.split("@")
	for i in range(1, parts.size()):
		if GEMS.has(parts[i]):
			return parts[i]
	return ""


## The id with its enchantment raised to `level`.
static func with_enchant(id: String, level: int) -> String:
	var keep: Array[String] = []
	for p in id.split("@"):
		if not (p.length() == 2 and p.begins_with("e") and p[1].is_valid_int()):
			keep.append(p)
	keep.append("e%d" % level)
	return "@".join(keep)


static func with_gem(id: String, gem: String) -> String:
	return id + "@" + gem


## The stats a piece of gear lends through its gem.
static func mods_of(id: String) -> Dictionary:
	var g := gem_of(id)
	return GEMS[g]["mods"] if g != "" else {}


## "+2" and "(Ruby)" for the gear's name.
static func label(id: String) -> String:
	var out := ""
	var e := enchant_level(id)
	if e > 0:
		out += " +%d" % e
	var g := gem_of(id)
	if g != "":
		out += " (%s)" % GEMS[g]["name"]
	return out


static func describe_mods(mods: Dictionary) -> String:
	var parts: Array[String] = []
	for k in mods:
		parts.append("+%d %s" % [int(mods[k]), String(k).capitalize()])
	return ", ".join(parts)
