class_name Gear
## Weapons, armor and shields. Weapon speed spans the reference's range (halberd 25 ... kryss 58);
## the damage, rating, Strength and price numbers are tuning guesses.
## Metal armor and shields wreck Meditation (the classic reason mages stay in cloth).
## Shields need a free hand: two-handed weapons cannot be used with one.
## Each weapon is trained by its own skill: swords, fencing, mace or archery. Bows and crossbows
## shoot arrows from range.
##
## An item id can carry variants after "@": a metal tier ("longsword@valorite", made from
## coloured ingots, a little better per tier) and "ex" (exceptional: made by a Grandmaster-level
## crafter, better still and bearing the maker's mark). Always read gear through stats().

const ORDER := [
	"dagger", "kryss", "short_sword", "longsword", "broadsword", "halberd",
	"mace", "war_hammer", "bow", "composite_bow", "crossbow", "heavy_crossbow",
	"leather_armor", "studded_armor", "chainmail", "platemail",
	"wooden_shield", "bronze_shield", "heater_shield",
]

const LIST := {
	"dagger": {"name": "Dagger", "slot": "weapon", "skill": "fencing", "speed": 55, "min": 2.0, "max": 6.0, "str": 10, "value": 15},
	"kryss": {"name": "Kryss", "slot": "weapon", "skill": "fencing", "speed": 58, "min": 3.0, "max": 7.0, "str": 10, "value": 40},
	"short_sword": {"name": "Short Sword", "slot": "weapon", "skill": "swords", "speed": 50, "min": 3.0, "max": 8.0, "str": 15, "value": 25},
	"longsword": {"name": "Longsword", "slot": "weapon", "skill": "swords", "speed": 35, "min": 5.0, "max": 13.0, "str": 25, "value": 55},
	"bonecleaver": {"name": "Bonecleaver", "slot": "weapon", "skill": "swords", "speed": 38, "min": 12.0, "max": 24.0, "str": 30, "value": 1200},
	"broadsword": {"name": "Broadsword", "slot": "weapon", "skill": "swords", "speed": 30, "min": 7.0, "max": 15.0, "str": 35, "value": 90},
	"halberd": {"name": "Halberd", "slot": "weapon", "skill": "swords", "speed": 25, "min": 8.0, "max": 18.0, "str": 50, "value": 160, "two_handed": true},
	"mace": {"name": "Mace", "slot": "weapon", "skill": "mace", "speed": 40, "min": 4.0, "max": 10.0, "str": 20, "value": 35},
	"war_hammer": {"name": "War Hammer", "slot": "weapon", "skill": "mace", "speed": 28, "min": 8.0, "max": 16.0, "str": 45, "value": 110, "two_handed": true},
	"bow": {"name": "Bow", "slot": "weapon", "skill": "archery", "speed": 30, "min": 5.0, "max": 12.0, "str": 20, "value": 50, "two_handed": true, "range": 7.0},
	"composite_bow": {"name": "Composite Bow", "slot": "weapon", "skill": "archery", "speed": 34, "min": 6.0, "max": 14.0, "str": 30, "value": 110, "two_handed": true, "range": 8.0},
	"heavy_crossbow": {"name": "Heavy Crossbow", "slot": "weapon", "skill": "archery", "speed": 18, "min": 12.0, "max": 22.0, "str": 45, "value": 160, "two_handed": true, "range": 8.0},
	"crossbow": {"name": "Crossbow", "slot": "weapon", "skill": "archery", "speed": 22, "min": 8.0, "max": 16.0, "str": 35, "value": 90, "two_handed": true, "range": 7.0},
	"leather_armor": {"name": "Leather Armor", "slot": "armor", "rating": 2.0, "str": 10, "value": 25, "metal": false},
	"studded_armor": {"name": "Studded Armor", "slot": "armor", "rating": 3.0, "str": 25, "value": 60, "metal": false},
	"chainmail": {"name": "Chainmail", "slot": "armor", "rating": 5.0, "str": 35, "value": 110, "metal": true},
	"platemail": {"name": "Platemail", "slot": "armor", "rating": 7.0, "str": 60, "value": 260, "metal": true},
	"wooden_shield": {"name": "Wooden Shield", "slot": "shield", "block": 0.6, "str": 10, "value": 20, "metal": false},
	"bronze_shield": {"name": "Bronze Shield", "slot": "shield", "block": 0.75, "str": 20, "value": 45, "metal": true},
	"heater_shield": {"name": "Heater Shield", "slot": "shield", "block": 0.9, "str": 35, "value": 95, "metal": true},
}

const TIER_BONUS := 0.04          # per metal tier above iron
const EXCEPTIONAL_BONUS := 0.2


## Artifacts: legendary, named versions of ordinary gear, found only in the treasure chests that
## fall from the sky when monsters die. Id "<base>@art_<name>" (so the model is the base's,
## tinted in the artifact's colour); stats are the base's raised by "bonus".
const ARTIFACTS := {
	"art_vengeance": {"base": "longsword", "name": "Blade of Vengeance", "bonus": 0.6, "color": Color(0.85, 0.2, 0.2)},
	"art_dawnbreaker": {"base": "broadsword", "name": "Dawnbreaker", "bonus": 0.6, "color": Color(1.0, 0.8, 0.35)},
	"art_frostbite": {"base": "kryss", "name": "Frostbite", "bonus": 0.65, "color": Color(0.55, 0.85, 1.0)},
	"art_thunderfist": {"base": "war_hammer", "name": "Thunderfist", "bonus": 0.55, "color": Color(0.6, 0.65, 0.95)},
	"art_whisperwind": {"base": "composite_bow", "name": "Whisperwind", "bonus": 0.55, "color": Color(0.6, 0.9, 0.6)},
	"art_doombolt": {"base": "heavy_crossbow", "name": "Doombolt", "bonus": 0.5, "color": Color(0.45, 0.25, 0.55)},
	"art_starplate": {"base": "platemail", "name": "Starforged Plate", "bonus": 0.5, "color": Color(0.45, 0.55, 0.95)},
	"art_moonweave": {"base": "chainmail", "name": "Moonweave Mail", "bonus": 0.5, "color": Color(0.82, 0.86, 0.95)},
	"art_shadowhide": {"base": "studded_armor", "name": "Shadowhide", "bonus": 0.6, "color": Color(0.2, 0.18, 0.24)},
	"art_aegis": {"base": "heater_shield", "name": "Aegis of the Dawn", "bonus": 0.5, "color": Color(1.0, 0.85, 0.45)},
}


## Every artifact as an item id ("longsword@art_vengeance"...).
static func artifact_ids() -> Array[String]:
	var out: Array[String] = []
	for k: String in ARTIFACTS:
		out.append(String(ARTIFACTS[k]["base"]) + "@" + k)
	return out


static func is_artifact(id: String) -> bool:
	return id.contains("@art_")


static func base(id: String) -> String:
	return id.split("@")[0]


static func has(id: String) -> bool:
	return id != "" and LIST.has(base(id))


## The item's stats with any metal tier and exceptional quality applied.
static func stats(id: String) -> Dictionary:
	var g: Dictionary = (LIST[base(id)] as Dictionary).duplicate()
	var parts := id.split("@")
	var mult := 1.0
	var prefix := ""
	var exceptional := false
	var art_name := ""
	for i in range(1, parts.size()):
		var p := parts[i]
		if ARTIFACTS.has(p):
			mult += float(ARTIFACTS[p]["bonus"])
			art_name = String(ARTIFACTS[p]["name"])
		elif p == "ex":
			exceptional = true
			mult += EXCEPTIONAL_BONUS
		else:
			var t := Crafting.tier_index(p)
			if t > 0:
				mult += TIER_BONUS * t
				prefix = String(Crafting.ORE_TIERS[t]["name"]) + " " + prefix
	if exceptional:
		prefix = "Exceptional " + prefix
	g["name"] = art_name if art_name != "" else prefix + String(g["name"])
	g["exceptional"] = exceptional
	g["artifact"] = art_name != ""
	g["value"] = roundi(int(g["value"]) * mult * (1.25 if exceptional else 1.0) * (6.0 if art_name != "" else 1.0))
	match String(g["slot"]):
		"weapon":
			g["min"] = float(g["min"]) * mult
			g["max"] = float(g["max"]) * mult
		"armor":
			g["rating"] = float(g["rating"]) * mult
		"shield":
			g["block"] = minf(0.95, float(g["block"]) * (1.0 + (mult - 1.0) / 2.0))
	return g


## Comparable only within a slot. Weapons: average damage times speed (about damage per second).
static func score(id: String) -> float:
	if not has(id):
		return 0.0
	var g := stats(id)
	if String(g["slot"]) == "weapon":
		return (float(g["min"]) + float(g["max"])) / 2.0 * float(g["speed"]) / 10.0
	if String(g["slot"]) == "shield":
		return float(g["block"]) * 10.0
	return float(g["rating"])


static func is_metal(id: String) -> bool:
	return has(id) and bool(LIST[base(id)].get("metal", false))


static func is_ranged(id: String) -> bool:
	return has(id) and float(LIST[base(id)].get("range", 0.0)) > 0.0
