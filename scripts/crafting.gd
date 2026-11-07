class_name Crafting
## Gathering, smelting and crafting data. Chains (from the mechanics reference):
## Mining -> smelting -> Blacksmithy;  Lumberjacking -> Carpentry;  hides (wolf pelts) -> Tailoring.
## Ore tiers and their Mining thresholds follow the classic order; values are tuning guesses.

const ORE_TIERS := [
	{"id": "iron", "name": "Iron", "min": 0.0, "value": 2},
	{"id": "dull_copper", "name": "Dull Copper", "min": 65.0, "value": 4},
	{"id": "shadow_iron", "name": "Shadow Iron", "min": 70.0, "value": 5},
	{"id": "copper", "name": "Copper", "min": 75.0, "value": 6},
	{"id": "bronze", "name": "Bronze", "min": 80.0, "value": 7},
	{"id": "golden", "name": "Golden", "min": 85.0, "value": 9},
	{"id": "agapite", "name": "Agapite", "min": 90.0, "value": 11},
	{"id": "verite", "name": "Verite", "min": 95.0, "value": 13},
	{"id": "valorite", "name": "Valorite", "min": 99.0, "value": 16},
]

## "ingot" means ingots of any metal (the cheapest are used first); "reagent" means the
## character's reagent pouch (used by Alchemy).
const RECIPES := {
	"dagger": {"skill": Hero.Skill.BLACKSMITHY, "min": 0.0, "mats": {"ingot": 3}},
	"kryss": {"skill": Hero.Skill.BLACKSMITHY, "min": 25.0, "mats": {"ingot": 8}},
	"longsword": {"skill": Hero.Skill.BLACKSMITHY, "min": 30.0, "mats": {"ingot": 12}},
	"broadsword": {"skill": Hero.Skill.BLACKSMITHY, "min": 45.0, "mats": {"ingot": 14}},
	"halberd": {"skill": Hero.Skill.BLACKSMITHY, "min": 60.0, "mats": {"ingot": 20}},
	"bronze_shield": {"skill": Hero.Skill.BLACKSMITHY, "min": 20.0, "mats": {"ingot": 12}},
	"heater_shield": {"skill": Hero.Skill.BLACKSMITHY, "min": 55.0, "mats": {"ingot": 18}},
	"chainmail": {"skill": Hero.Skill.BLACKSMITHY, "min": 50.0, "mats": {"ingot": 24}},
	"platemail": {"skill": Hero.Skill.BLACKSMITHY, "min": 70.0, "mats": {"ingot": 30}},
	"leather_armor": {"skill": Hero.Skill.TAILORING, "min": 0.0, "mats": {"wolf_pelt": 3}},
	"studded_armor": {"skill": Hero.Skill.TAILORING, "min": 35.0, "mats": {"wolf_pelt": 5}},
	"wooden_shield": {"skill": Hero.Skill.CARPENTRY, "min": 0.0, "mats": {"log": 5}},
	"short_sword": {"skill": Hero.Skill.BLACKSMITHY, "min": 10.0, "mats": {"ingot": 6}},
	"mace": {"skill": Hero.Skill.BLACKSMITHY, "min": 15.0, "mats": {"ingot": 7}},
	"war_hammer": {"skill": Hero.Skill.BLACKSMITHY, "min": 50.0, "mats": {"ingot": 16}},
	"bow": {"skill": Hero.Skill.CARPENTRY, "min": 0.0, "mats": {"log": 7}},
	"crossbow": {"skill": Hero.Skill.CARPENTRY, "min": 25.0, "mats": {"log": 10}},
	"composite_bow": {"skill": Hero.Skill.CARPENTRY, "min": 45.0, "mats": {"log": 9}},
	"heavy_crossbow": {"skill": Hero.Skill.CARPENTRY, "min": 65.0, "mats": {"log": 14}},
	"potion_refresh": {"skill": Hero.Skill.ALCHEMY, "min": 0.0, "mats": {"reagent": 1}},
	"potion_cure": {"skill": Hero.Skill.ALCHEMY, "min": 0.0, "mats": {"reagent": 2}},
	"potion_heal": {"skill": Hero.Skill.ALCHEMY, "min": 15.0, "mats": {"reagent": 2}},
	"potion_greater_heal": {"skill": Hero.Skill.ALCHEMY, "min": 55.0, "mats": {"reagent": 4}},
}
const POTIONS := ["potion_greater_heal", "potion_heal", "potion_cure", "potion_refresh"]
const ORDER := [
	"dagger", "kryss", "longsword", "broadsword", "halberd", "bronze_shield", "heater_shield",
	"chainmail", "platemail", "leather_armor", "studded_armor", "wooden_shield",
	"short_sword", "mace", "war_hammer", "bow", "crossbow", "composite_bow", "heavy_crossbow",
	"potion_refresh", "potion_cure", "potion_heal", "potion_greater_heal",
]


static func tier_index(tier_id: String) -> int:
	for i in range(ORE_TIERS.size()):
		if String(ORE_TIERS[i]["id"]) == tier_id:
			return i
	return -1


## The best metal with at least `n` ingots of its own, or "" if no single metal has enough.
static func best_single_tier(inv: Dictionary, n: int) -> String:
	for i in range(ORE_TIERS.size() - 1, -1, -1):
		var id := String(ORE_TIERS[i]["id"])
		if count(inv, "ingot_" + id) >= n:
			return id
	return ""


static func tier(tier_id: String) -> Dictionary:
	for t in ORE_TIERS:
		if String(t["id"]) == tier_id:
			return t
	return {}


## Rarer ore needs more Mining; each tier you qualify for has a small chance to turn up.
static func roll_ore(mining: float) -> String:
	var pick := "iron"
	for t in ORE_TIERS:
		if float(t["min"]) > 0.0 and float(t["min"]) <= mining and randf() < 0.25:
			pick = String(t["id"])
	return "ore_" + pick


static func count(inv: Dictionary, id: String) -> int:
	return int(inv.get(id, 0))


static func ingot_count(inv: Dictionary) -> int:
	var n := 0
	for t in ORE_TIERS:
		n += count(inv, "ingot_" + String(t["id"]))
	return n


static func ore_count(inv: Dictionary) -> int:
	var n := 0
	for t in ORE_TIERS:
		n += count(inv, "ore_" + String(t["id"]))
	return n


static func has_mats(inv: Dictionary, mats: Dictionary) -> bool:
	for k in mats:
		var have := ingot_count(inv) if k == "ingot" else count(inv, k)
		if have < int(mats[k]):
			return false
	return true


## Removes `fraction` of a recipe's materials (rounded up): 1.0 on success, 0.5 on failure.
static func take_mats(inv: Dictionary, mats: Dictionary, fraction: float) -> void:
	for k in mats:
		var n := ceili(int(mats[k]) * fraction)
		if k == "ingot":
			for t in ORE_TIERS:
				var id := "ingot_" + String(t["id"])
				var take := mini(n, count(inv, id))
				_remove(inv, id, take)
				n -= take
		else:
			_remove(inv, k, n)


static func _remove(inv: Dictionary, id: String, n: int) -> void:
	if n <= 0 or not inv.has(id):
		return
	inv[id] = int(inv[id]) - n
	if int(inv[id]) <= 0:
		inv.erase(id)
