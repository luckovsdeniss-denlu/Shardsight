class_name Items
## Trophy items dropped by monsters (no use except selling). Gear ids from Gear also work as items.

const LIST := {
	"rat_tail": {"name": "Rat Tail", "value": 3},
	"wolf_pelt": {"name": "Wolf Pelt", "value": 8},
	"orc_ear": {"name": "Orc Ear", "value": 10},
	"mage_robe": {"name": "Mage Robe", "value": 20},
	"crown_of_bones": {"name": "Crown of Bones", "value": 400},
	# Potions (Alchemy, or bought from the merchant). Kept, never sold.
	"potion_heal": {"name": "Heal Potion", "value": 15, "potion": true},
	"potion_greater_heal": {"name": "Greater Heal Potion", "value": 30, "potion": true},
	"potion_cure": {"name": "Cure Potion", "value": 15, "potion": true},
	"potion_refresh": {"name": "Refresh Potion", "value": 10, "potion": true},
	# Instruments (bards need one to play). Kept, never sold.
	"lute": {"name": "Lute", "value": 20, "instrument": true},
	# Food (Create Food): eaten to heal a little out of combat. Kept, never sold.
	"bread": {"name": "Loaf of Bread", "value": 2, "food": true},
	# Tools wear out with use and break (they are kept, never sold).
	"pickaxe": {"name": "Pickaxe", "value": 12, "tool": true},
	"hatchet": {"name": "Hatchet", "value": 12, "tool": true},
	"tool_kit": {"name": "Tool Kit", "value": 15, "tool": true},
	"shovel": {"name": "Shovel", "value": 15, "tool": true},           # digging up treasure
	"fishing_pole": {"name": "Fishing Pole", "value": 12, "tool": true},
	# Fishing: fish sell, and can be eaten (food); now and then something else bites.
	"fish": {"name": "Fish", "value": 4, "food": true},
	"big_fish": {"name": "Big Fish", "value": 18, "food": true},
	"old_boot": {"name": "Old Boot", "value": 1},
	"pearl": {"name": "Pearl", "value": 60},
	# The story's fragments of the Shard of Sight (kept, never sold).
	"shard_fragment_1": {"name": "Shard Fragment (the Warlord's)", "value": 0},
	"shard_fragment_2": {"name": "Shard Fragment (the Graveyard's)", "value": 0},
	"shard_fragment_3": {"name": "Shard Fragment (the Bone King's)", "value": 0},
	"shard_of_sight": {"name": "The Shard of Sight", "value": 0},
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


static func is_food(id: String) -> bool:
	return LIST.has(id) and bool(LIST[id].get("food", false))


static func is_instrument(id: String) -> bool:
	return LIST.has(id) and bool(LIST[id].get("instrument", false))


static func is_tool_item(id: String) -> bool:
	return LIST.has(id) and bool(LIST[id].get("tool", false))


## Spell scrolls: "scroll_<spell id>". Copied into a spellbook, or sold.
static func is_scroll(id: String) -> bool:
	return Spells.spell_of_scroll(id) != ""


static func is_known(id: String) -> bool:
	return Gear.has(id) or LIST.has(id) or is_material(id) or is_scroll(id) or Jewelry.has(id) or is_map(id)


## Treasure maps: "tmap@<x>_<y>", the tile where the chest is buried.
static func is_map(id: String) -> bool:
	return id.begins_with("tmap@")


static func map_tile(id: String) -> Vector2i:
	var p := id.trim_prefix("tmap@").split("_")
	if p.size() != 2:
		return Vector2i(-1, -1)
	return Vector2i(int(p[0]), int(p[1]))


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
	if is_scroll(id):
		return "Scroll of " + String(Spells.LIST[Spells.spell_of_scroll(id)]["name"])
	if Jewelry.has(id):
		return String(Jewelry.LIST[id]["name"])
	if is_map(id):
		return "Treasure Map"
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
	if is_scroll(id):
		return scroll_price(id) / 2
	if Jewelry.has(id):
		return int(Jewelry.LIST[id]["value"]) / 2
	if is_map(id):
		return 40
	return int(LIST[id]["value"])


## What a merchant charges for a scroll: 12 gold per circle.
static func scroll_price(id: String) -> int:
	return 12 * int(Spells.LIST[Spells.spell_of_scroll(id)]["circle"])


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
