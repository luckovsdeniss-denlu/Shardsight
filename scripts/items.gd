class_name Items
## Trophy items dropped by monsters (no use except selling). Gear ids from Gear also work as items.

const LIST := {
	"rat_tail": {"name": "Rat Tail", "value": 3},
	"wolf_pelt": {"name": "Wolf Pelt", "value": 8},
	"orc_ear": {"name": "Orc Ear", "value": 10},
	"mage_robe": {"name": "Mage Robe", "value": 20},
	# Potions (Alchemy, or bought from the merchant). Kept, never sold.
	"potion_heal": {"name": "Heal Potion", "value": 15, "potion": true},
	"potion_greater_heal": {"name": "Greater Heal Potion", "value": 30, "potion": true},
	"potion_cure": {"name": "Cure Potion", "value": 15, "potion": true},
	"potion_refresh": {"name": "Refresh Potion", "value": 10, "potion": true},
	# Instruments (bards need one to play). Kept, never sold.
	"lute": {"name": "Lute", "value": 20, "instrument": true},
	# Tools wear out with use and break (they are kept, never sold).
	"pickaxe": {"name": "Pickaxe", "value": 12, "tool": true},
	"hatchet": {"name": "Hatchet", "value": 12, "tool": true},
	"tool_kit": {"name": "Tool Kit", "value": 15, "tool": true},
}


## Crafting materials: ore and ingots of every metal, logs and wolf pelts (hides).
static func is_material(id: String) -> bool:
	if id == "log" or id == "wolf_pelt":
		return true
	if id.begins_with("ore_"):
		return not Crafting.tier(id.trim_prefix("ore_")).is_empty()
	if id.begins_with("ingot_"):
		return not Crafting.tier(id.trim_prefix("ingot_")).is_empty()
	return false


static func is_potion(id: String) -> bool:
	return LIST.has(id) and bool(LIST[id].get("potion", false))


static func is_instrument(id: String) -> bool:
	return LIST.has(id) and bool(LIST[id].get("instrument", false))


static func is_tool(id: String) -> bool:
	return LIST.has(id) and bool(LIST[id].get("tool", false))


static func is_known(id: String) -> bool:
	return Gear.has(id) or LIST.has(id) or is_material(id)


static func item_name(id: String) -> String:
	if id == "log":
		return "Log"
	if id.begins_with("ore_") and is_material(id):
		return String(Crafting.tier(id.trim_prefix("ore_"))["name"]) + " Ore"
	if id.begins_with("ingot_") and is_material(id):
		return String(Crafting.tier(id.trim_prefix("ingot_"))["name"]) + " Ingot"
	if Gear.has(id):
		var g := Gear.stats(id)
		return String(g["name"]) + (" (your maker's mark)" if bool(g["exceptional"]) else "")
	return String(LIST[id]["name"])


## What the merchant pays: full value for trophies, half for used gear.
static func value(id: String) -> int:
	if id == "log":
		return 1
	if id.begins_with("ore_") and is_material(id):
		return int(Crafting.tier(id.trim_prefix("ore_"))["value"])
	if id.begins_with("ingot_") and is_material(id):
		return int(Crafting.tier(id.trim_prefix("ingot_"))["value"]) * 2
	if Gear.has(id):
		return maxi(1, int(Gear.stats(id)["value"]) / 2)
	return int(LIST[id]["value"])


static func material_count(inv: Dictionary) -> int:
	var n := 0
	for id in inv:
		if is_material(id):
			n += int(inv[id])
	return n


static func mats_text(mats: Dictionary) -> String:
	var parts: Array[String] = []
	for k in mats:
		var label := "ingots" if k == "ingot" else ("reagents" if k == "reagent" else item_name(k))
		parts.append("%d %s" % [int(mats[k]), label])
	return ", ".join(parts)
