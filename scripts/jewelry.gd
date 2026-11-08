class_name Jewelry
## Rings and amulets: one of each can be worn. Each has a magic property:
## "mods" (stat bonuses), "power" (spell damage, a fraction), "cast" (faster casting, a fraction),
## "resist" (extra chance to shrug off hostile spells), "armor" (armour rating), "regen" (health
## a second). Found in treasure chests, now and then on monsters, and the plainer ones are sold
## by merchants.

const LIST := {
	"ring_strength": {"name": "Ring of Strength", "slot": "ring", "mods": {"str": 5}, "value": 120, "shop": true},
	"ring_agility": {"name": "Ring of Agility", "slot": "ring", "mods": {"dex": 5}, "value": 120, "shop": true},
	"ring_wits": {"name": "Ring of Wits", "slot": "ring", "mods": {"int": 5}, "value": 120, "shop": true},
	"ring_power": {"name": "Ring of Power", "slot": "ring", "power": 0.15, "value": 320},
	"ring_swiftness": {"name": "Ring of Swift Casting", "slot": "ring", "cast": 0.15, "value": 300},
	"ring_life": {"name": "Ring of Life", "slot": "ring", "regen": 0.5, "value": 260},
	"amulet_guard": {"name": "Amulet of Guarding", "slot": "amulet", "armor": 2.0, "value": 140, "shop": true},
	"amulet_warding": {"name": "Amulet of Warding", "slot": "amulet", "resist": 0.15, "value": 280},
	"amulet_mind": {"name": "Amulet of the Mind", "slot": "amulet", "mods": {"int": 8}, "value": 260},
	"amulet_titan": {"name": "Amulet of the Titan", "slot": "amulet", "mods": {"str": 6, "dex": 3}, "value": 340},
}
## The gem colour each piece shows (on the amulet pendant).
const GEM := {
	"amulet_guard": Color(0.7, 0.75, 0.85), "amulet_warding": Color(0.55, 0.75, 1.0),
	"amulet_mind": Color(0.75, 0.5, 1.0), "amulet_titan": Color(1.0, 0.45, 0.3),
}


static func has(id: String) -> bool:
	return LIST.has(id)


static func slot(id: String) -> String:
	return String(LIST[id]["slot"]) if LIST.has(id) else ""


## A word on what it does: "Str +5", "spell damage +15%"...
static func describe(id: String) -> String:
	if not LIST.has(id):
		return ""
	var j: Dictionary = LIST[id]
	var parts: Array[String] = []
	var mods: Dictionary = j.get("mods", {})
	for k in mods:
		parts.append("%s +%d" % [String(k).capitalize(), int(mods[k])])
	if j.has("power"):
		parts.append("spell damage +%d%%" % roundi(float(j["power"]) * 100.0))
	if j.has("cast"):
		parts.append("casting %d%% faster" % roundi(float(j["cast"]) * 100.0))
	if j.has("resist"):
		parts.append("+%d%% to resist spells" % roundi(float(j["resist"]) * 100.0))
	if j.has("armor"):
		parts.append("armour +%d" % int(j["armor"]))
	if j.has("regen"):
		parts.append("+%.1f health a second" % float(j["regen"]))
	return ", ".join(parts)


static func random_id() -> String:
	var ids := LIST.keys()
	return String(ids[randi() % ids.size()])


static func shop_ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in LIST:
		if bool(LIST[k].get("shop", false)):
			out.append(k)
	return out
