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
	"mace", "war_hammer", "scimitar", "katana", "viking_sword", "axe", "battle_axe", "double_axe",
	"short_spear", "spear", "war_fork", "quarterstaff", "war_axe", "maul",
	"bow", "composite_bow", "crossbow", "heavy_crossbow",
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
	"scimitar": {"name": "Scimitar", "slot": "weapon", "skill": "swords", "speed": 45, "min": 4.0, "max": 10.0, "str": 20, "value": 45},
	"katana": {"name": "Katana", "slot": "weapon", "skill": "swords", "speed": 46, "min": 5.0, "max": 11.0, "str": 25, "value": 75},
	"viking_sword": {"name": "Viking Sword", "slot": "weapon", "skill": "swords", "speed": 32, "min": 6.0, "max": 14.0, "str": 35, "value": 85},
	"axe": {"name": "Axe", "slot": "weapon", "skill": "swords", "speed": 34, "min": 6.0, "max": 13.0, "str": 30, "value": 55},
	"battle_axe": {"name": "Battle Axe", "slot": "weapon", "skill": "swords", "speed": 28, "min": 8.0, "max": 17.0, "str": 40, "value": 100, "two_handed": true},
	"double_axe": {"name": "Double Axe", "slot": "weapon", "skill": "swords", "speed": 25, "min": 10.0, "max": 19.0, "str": 50, "value": 140, "two_handed": true},
	"short_spear": {"name": "Short Spear", "slot": "weapon", "skill": "fencing", "speed": 45, "min": 4.0, "max": 10.0, "str": 25, "value": 40},
	"spear": {"name": "Spear", "slot": "weapon", "skill": "fencing", "speed": 30, "min": 7.0, "max": 15.0, "str": 35, "value": 75, "two_handed": true},
	"war_fork": {"name": "War Fork", "slot": "weapon", "skill": "fencing", "speed": 38, "min": 5.0, "max": 12.0, "str": 35, "value": 60},
	"quarterstaff": {"name": "Quarterstaff", "slot": "weapon", "skill": "mace", "speed": 36, "min": 5.0, "max": 12.0, "str": 30, "value": 30, "two_handed": true},
	"war_axe": {"name": "War Axe", "slot": "weapon", "skill": "mace", "speed": 33, "min": 6.0, "max": 13.0, "str": 35, "value": 70},
	"maul": {"name": "Maul", "slot": "weapon", "skill": "mace", "speed": 30, "min": 7.0, "max": 15.0, "str": 45, "value": 90},
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
	# The Shardveil's guns (the "Shardveil chaos" experiment): never sold, made or dropped - in the
	# other dimension everyone simply has one in hand. They shoot without arrows and never wear out.
	"rift_shotgun": {"name": "Rift Shotgun", "slot": "weapon", "skill": "archery", "speed": 26, "min": 9.0, "max": 18.0, "str": 10, "value": 0, "range": 5.0, "gun": "shotgun"},
	"shard_rocket": {"name": "Shard Rocket Launcher", "slot": "weapon", "skill": "archery", "speed": 16, "min": 14.0, "max": 26.0, "str": 10, "value": 0, "range": 9.0, "gun": "rocket"},
	"spike_gun": {"name": "Spike Gun", "slot": "weapon", "skill": "archery", "speed": 58, "min": 4.0, "max": 8.0, "str": 10, "value": 0, "range": 8.0, "gun": "spike"},
	"arc_caster": {"name": "Arc Caster", "slot": "weapon", "skill": "archery", "speed": 52, "min": 5.0, "max": 10.0, "str": 10, "value": 0, "range": 6.0, "gun": "arc"},
	"ember_launcher": {"name": "Ember Launcher", "slot": "weapon", "skill": "archery", "speed": 20, "min": 12.0, "max": 22.0, "str": 10, "value": 0, "range": 7.0, "gun": "grenade"},
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


## How much wear a piece takes before it breaks: weapons 50, armour 70, shields 60; exceptional
## work lasts half as long again, artifacts twice as long, coloured metals a little longer.
static func max_durability(id: String) -> int:
	if not has(id):
		return 1
	var g := stats(id)
	var d := {"weapon": 50.0, "armor": 70.0, "shield": 60.0}.get(String(g["slot"]), 50.0) as float
	if bool(g["exceptional"]):
		d *= 1.5
	if bool(g["artifact"]):
		d *= 2.0
	for p in id.split("@"):
		var t := Crafting.tier_index(p)
		if t > 0:
			d += 5.0 * t
	return roundi(d)


## How a weapon wounds: "slash" (swords, axes), "pierce" (daggers, kryss, spears, bows) or
## "bash" (maces, hammers, staves). Bash is strong against metal armour and bone, pierce slips
## through armour, slash bites deep into the unarmoured.
static func dtype(id: String) -> String:
	if not has(id):
		return "bash"                      # fists, claws and clubs
	match String(LIST[base(id)].get("skill", "")):
		"fencing", "archery":
			return "pierce"
		"mace":
			return "bash"
	return "slash"


## Each weapon's special move (fired now and then by skilled fighters): "bleed" (a wound that
## keeps hurting), "armor_ignore" (straight through the armour), "crush" (a heavy blow that stuns
## for a moment), "double" (a quick second strike) or "concuss" (knocks the mana out of a caster).
const SPECIALS := {
	"dagger": "double", "kryss": "double", "scimitar": "double", "katana": "double", "double_axe": "double",
	"quarterstaff": "concuss", "war_fork": "concuss", "halberd": "crush", "war_axe": "crush",
}


static func special(id: String) -> String:
	if not has(id) or is_ranged(id):
		return ""
	var b := base(id)
	if SPECIALS.has(b):
		return String(SPECIALS[b])
	match dtype(id):
		"pierce":
			return "armor_ignore"
		"bash":
			return "crush"
	return "bleed"


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
		elif Gems.is_gem(p):
			pass                                    # a socketed gem: its stats come through Gems.mods_of
		elif p.length() == 2 and p.begins_with("e") and p[1].is_valid_int():
			mult += Gems.ENCHANT_BONUS * int(p[1])   # enchanted at the forge
		else:
			var t := Crafting.tier_index(p)
			if t > 0:
				mult += TIER_BONUS * t
				prefix = String(Crafting.ORE_TIERS[t]["name"]) + " " + prefix
	if exceptional:
		prefix = "Exceptional " + prefix
	g["name"] = (art_name if art_name != "" else prefix + String(g["name"])) + Gems.label(id)
	g["exceptional"] = exceptional
	g["artifact"] = art_name != ""
	g["value"] = roundi(int(g["value"]) * mult * (1.25 if exceptional else 1.0) * (6.0 if art_name != "" else 1.0))
	var gem := Gems.gem_of(id)
	if gem != "":
		g["value"] = int(g["value"]) + int(Gems.GEMS[gem]["value"])
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


## What kind of Shardveil gun an item is ("shotgun", "rocket", "spike", "arc", "grenade"), or "".
static func gun(id: String) -> String:
	return String(LIST[base(id)].get("gun", "")) if has(id) else ""
