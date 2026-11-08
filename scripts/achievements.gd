class_name Achievements
## Deeds worth remembering. Each is met by a statistic ("stat" reaching "goal"), a skill at 100,
## any skill at 100, a level, or artifacts found. Unlocking one pays "gold" and earns its title,
## which you may wear after your name (Statistics > Titles).

const LIST := [
	{"id": "first_blood", "name": "First Blood", "title": "the Blooded", "desc": "Slay your first monster", "stat": "kills", "goal": 1, "gold": 20},
	{"id": "slayer", "name": "Monster Slayer", "title": "the Slayer", "desc": "Slay 100 monsters", "stat": "kills", "goal": 100, "gold": 200},
	{"id": "legend", "name": "Legend of the Realm", "title": "the Legendary", "desc": "Slay 1000 monsters", "stat": "kills", "goal": 1000, "gold": 2000},
	{"id": "bone_breaker", "name": "Bone Breaker", "title": "Bane of the Bone King", "desc": "Slay the Bone King", "stat": "hero_killed_The Bone King", "goal": 1, "gold": 500},
	{"id": "champion", "name": "Champion Slayer", "title": "the Champion", "desc": "Slay a champion", "stat": "champions_slain", "goal": 1, "gold": 500},
	{"id": "defender", "name": "Defender of the Towns", "title": "the Defender", "desc": "Help repel 3 orc warbands", "stat": "invasions_repelled", "goal": 3, "gold": 300},
	{"id": "treasure", "name": "Treasure Hunter", "title": "the Treasure Hunter", "desc": "Dig up 5 buried treasures", "stat": "treasures_dug", "goal": 5, "gold": 300},
	{"id": "angler", "name": "Angler", "title": "the Angler", "desc": "Catch 50 fish", "stat": "fish_caught", "goal": 50, "gold": 100},
	{"id": "trader", "name": "Trader", "title": "the Trader", "desc": "Sell 100 things to merchants", "stat": "shop_sold", "goal": 100, "gold": 150},
	{"id": "wealthy", "name": "Wealthy", "title": "the Wealthy", "desc": "Earn 10,000 gold", "stat": "gold_earned", "goal": 10000, "gold": 500},
	{"id": "spellslinger", "name": "Spellslinger", "title": "the Spellslinger", "desc": "Cast 500 spells", "stat": "spells_cast", "goal": 500, "gold": 200},
	{"id": "craftsman", "name": "Craftsman", "title": "the Craftsman", "desc": "Craft 100 things", "stat": "crafted", "goal": 100, "gold": 150},
	{"id": "beastmaster", "name": "Beastmaster", "title": "the Beastmaster", "desc": "Tame 5 animals", "stat": "tamed", "goal": 5, "gold": 150},
	{"id": "undying", "name": "Death's Old Friend", "title": "the Undying", "desc": "Die 10 times (and come back)", "stat": "hero_deaths", "goal": 10, "gold": 50},
	{"id": "collector", "name": "Collector", "title": "the Collector", "desc": "Find 3 artifacts", "stat": "artifacts_found", "goal": 3, "gold": 400},
	{"id": "archmage", "name": "Archmage", "title": "the Archmage", "desc": "Reach Magery 100", "skill": Hero.Skill.MAGERY, "goal": 100, "gold": 1000},
	{"id": "grandmaster", "name": "Grandmaster", "title": "the Grandmaster", "desc": "Reach 100 in any skill", "any_skill": true, "goal": 100, "gold": 500},
	{"id": "seasoned", "name": "Seasoned", "title": "the Seasoned", "desc": "Reach level 100", "level": true, "goal": 100, "gold": 300},
	{"id": "hero", "name": "Hero of the Realm", "title": "Hero of the Realm", "desc": "Reach level 500", "level": true, "goal": 500, "gold": 2000},
]


## [have, goal] for an achievement, from the hero's statistics, skills and level.
static func progress(a: Dictionary, stats_counts: Dictionary, hero_stats: Hero) -> Array:
	var goal := int(a["goal"])
	var have := 0
	if a.has("stat"):
		have = int(stats_counts.get(String(a["stat"]), 0))
	elif a.has("skill"):
		have = floori(float(hero_stats.skills.get(int(a["skill"]), 0.0)))
	elif a.has("any_skill"):
		for s in hero_stats.skills:
			have = maxi(have, floori(float(hero_stats.skills[s])))
	elif a.has("level"):
		have = hero_stats.level()
	return [mini(have, goal), goal]


static func by_id(id: String) -> Dictionary:
	for a: Dictionary in LIST:
		if String(a["id"]) == id:
			return a
	return {}
