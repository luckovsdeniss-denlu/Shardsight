class_name Bestiary
## Stat blocks for everything that walks the map.
## Keys: inventory (starting bag), species + tame (minimum Animal Taming; tameable animals), passive (never starts a fight),
## poison ([level, chance per hit]), danger (monster toughness: players only start fights they can win), pk (preys on innocents), crafter (gathers and crafts when idle), weapon/wear/shield (starting gear ids from Gear), bandages, str/dex/int, skills, reagents, gold (carried), loot (monster drops), dmg_min/dmg_max (weapon roll), wspeed (weapon speed 20..60),
## move (m/s), armor, leash (wander radius in tiles), aggro (m), respawn (s), role, scale,
## look (which Art model: humanoid by default; rat, wolf, bear, hind, spider, orc, skeleton...).

## What every player starts with in the bag, the hero and the computer players alike.
const PLAYER_KIT := {"lute": 1, "pickaxe": 1, "hatchet": 1, "tool_kit": 1}

const HERO := {
	"str": 25, "dex": 20, "int": 20, "wspeed": 45, "dmg_min": 5, "dmg_max": 10,
	"move": 4.0, "leash": 8, "aggro": 5.0, "respawn": 5.0,
	"reagents": 30, "gold": 20, "weapon": "short_sword", "bandages": 5, "crafter": true,
	"arrows": 0,
	"skills": {Hero.Skill.SWORDSMANSHIP: 50.0, Hero.Skill.TACTICS: 30.0, Hero.Skill.MAGERY: 30.0},
}

# Other players, played by the computer.
const WARRIOR := {
	"str": 35, "dex": 20, "int": 10, "wspeed": 45, "dmg_min": 5, "dmg_max": 10,
	"move": 3.6, "leash": 8, "aggro": 5.0, "respawn": 5.0, "gold": 20, "weapon": "longsword", "wear": "chainmail",
	"fame": 1500, "karma": 2000,
	"shield": "bronze_shield", "bandages": 8,
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 60.0, Hero.Skill.TACTICS: 50.0, Hero.Skill.ANATOMY: 40.0,
		Hero.Skill.PARRYING: 50.0, Hero.Skill.HEALING: 40.0,
	},
}
const FIGHTER := {
	"str": 30, "dex": 25, "int": 10, "wspeed": 55, "dmg_min": 4, "dmg_max": 8,
	"move": 3.8, "leash": 8, "aggro": 5.0, "respawn": 5.0, "gold": 20,
	"weapon": "kryss", "wear": "studded_armor", "shield": "wooden_shield", "bandages": 8,
	"fame": 800, "karma": 1300,
	"skills": {
		Hero.Skill.FENCING: 55.0, Hero.Skill.TACTICS: 55.0, Hero.Skill.ANATOMY: 45.0,
		Hero.Skill.PARRYING: 40.0, Hero.Skill.HEALING: 30.0,
	},
}

const MAGE := {
	"str": 20, "dex": 20, "int": 40, "wspeed": 30, "dmg_min": 2, "dmg_max": 4,
	"move": 3.4, "leash": 8, "aggro": 6.0, "respawn": 5.0, "reagents": 40, "gold": 60, "weapon": "dagger", "bandages": 3,
	"spellbook": "all", "fame": 1300, "karma": 1500,
	"skills": {
		Hero.Skill.FENCING: 20.0, Hero.Skill.MAGERY: 70.0, Hero.Skill.EVALUATING_INTELLECT: 50.0,
		Hero.Skill.MEDITATION: 50.0, Hero.Skill.RESISTING_SPELLS: 30.0, Hero.Skill.HEALING: 20.0,
	},
}

# An archer: shoots from range with a bow and buys arrows from the merchant.
const ARCHER := {
	"str": 30, "dex": 30, "int": 15, "wspeed": 45, "dmg_min": 3, "dmg_max": 6,
	"move": 3.8, "leash": 9, "aggro": 7.0, "respawn": 5.0, "gold": 30,
	"weapon": "bow", "arrows": 60, "wear": "leather_armor", "bandages": 6,
	"fame": 900, "karma": 1000,
	"skills": {
		Hero.Skill.ARCHERY: 55.0, Hero.Skill.TACTICS: 45.0, Hero.Skill.ANATOMY: 30.0,
		Hero.Skill.HEALING: 30.0, Hero.Skill.TRACKING: 30.0,
	},
}

# A thief: hides, sneaks up on players outside town, snoops in their bags and steals.
const THIEF := {
	"str": 22, "dex": 38, "int": 20, "wspeed": 55, "dmg_min": 2, "dmg_max": 5,
	"move": 3.9, "leash": 9, "aggro": 4.0, "respawn": 6.0, "gold": 15, "thief": true,
	"weapon": "dagger", "wear": "leather_armor", "bandages": 5, "fame": 400, "karma": -800,
	"skills": {
		Hero.Skill.STEALING: 60.0, Hero.Skill.SNOOPING: 55.0, Hero.Skill.HIDING: 60.0,
		Hero.Skill.STEALTH: 50.0, Hero.Skill.FENCING: 35.0, Hero.Skill.TACTICS: 25.0,
		Hero.Skill.HEALING: 20.0,
	},
}

# A player killer: preys on innocent players in the wilderness.
const PKILLER := {
	"str": 30, "dex": 30, "int": 10, "wspeed": 58, "dmg_min": 1, "dmg_max": 2,
	"move": 3.7, "leash": 9, "aggro": 7.0, "respawn": 8.0, "pk": true, "gold": 30,
	"weapon": "kryss", "wear": "leather_armor", "bandages": 5,
	"fame": 2600, "karma": -3000,
	"skills": {
		Hero.Skill.FENCING: 55.0, Hero.Skill.TACTICS: 45.0, Hero.Skill.ANATOMY: 30.0,
		Hero.Skill.HEALING: 20.0,
	},
}

# Mounts: tame one (or buy one from the stablemaster) and ride it, much faster than walking.
const HORSE := {
	"look": "horse",
	"species": "horse", "tame": 30.0, "passive": true, "danger": 1, "color": "7a5232", "mount_speed": 1.8,
	"str": 60, "dex": 50, "int": 5, "wspeed": 40, "dmg_min": 2, "dmg_max": 6,
	"move": 4.6, "leash": 6, "aggro": 0.0, "respawn": 40.0, "scale": 1.0,
	"loot": {"gold_min": 0, "gold_max": 0, "drops": []},
	"skills": {Hero.Skill.SWORDSMANSHIP: 25.0, Hero.Skill.TACTICS: 25.0},
}
const LLAMA := {
	"look": "llama",
	"species": "llama", "tame": 35.0, "passive": true, "danger": 1, "color": "e8e0d0", "mount_speed": 1.6,
	"str": 50, "dex": 45, "int": 5, "wspeed": 40, "dmg_min": 2, "dmg_max": 5,
	"move": 4.2, "leash": 5, "aggro": 0.0, "respawn": 40.0, "scale": 0.95,
	"loot": {"gold_min": 0, "gold_max": 0, "drops": []},
	"skills": {Hero.Skill.SWORDSMANSHIP: 20.0, Hero.Skill.TACTICS: 20.0},
}

# Summoned by the circle 8 spell; fights for its caster for a while, then crumbles.
const EARTH_ELEMENTAL := {
	"look": "earth_elemental",
	"danger": 5,
	"str": 80, "dex": 30, "int": 10, "wspeed": 30, "dmg_min": 8, "dmg_max": 15,
	"move": 3.6, "leash": 3, "aggro": 6.0, "respawn": 0.0, "armor": 4.0, "scale": 1.4,
	"skills": {Hero.Skill.SWORDSMANSHIP: 70.0, Hero.Skill.TACTICS: 70.0},
}

const BLADE_SPIRITS := {
	"look": "blades",
	"danger": 3, "str": 40, "dex": 60, "int": 10, "wspeed": 55, "dmg_min": 5, "dmg_max": 10,
	"move": 4.2, "leash": 3, "aggro": 6.0, "respawn": 0.0, "scale": 0.8,
	"skills": {Hero.Skill.SWORDSMANSHIP: 80.0, Hero.Skill.TACTICS: 60.0},
}
const ENERGY_VORTEX := {
	"look": "vortex",
	"danger": 6, "str": 70, "dex": 70, "int": 10, "wspeed": 50, "dmg_min": 10, "dmg_max": 18,
	"move": 4.4, "leash": 3, "aggro": 7.0, "respawn": 0.0, "scale": 1.1,
	"skills": {Hero.Skill.SWORDSMANSHIP: 85.0, Hero.Skill.TACTICS: 80.0},
}
const AIR_ELEMENTAL := {
	"look": "air_elemental",
	"danger": 5, "str": 65, "dex": 60, "int": 10, "wspeed": 45, "dmg_min": 7, "dmg_max": 13,
	"move": 4.6, "leash": 3, "aggro": 6.0, "respawn": 0.0, "armor": 2.0, "scale": 1.3,
	"skills": {Hero.Skill.SWORDSMANSHIP: 70.0, Hero.Skill.TACTICS: 70.0},
}
const FIRE_ELEMENTAL := {
	"look": "fire_elemental",
	"danger": 6, "str": 75, "dex": 45, "int": 10, "wspeed": 40, "dmg_min": 9, "dmg_max": 17,
	"move": 3.8, "leash": 3, "aggro": 6.0, "respawn": 0.0, "armor": 3.0, "scale": 1.3,
	"skills": {Hero.Skill.SWORDSMANSHIP: 75.0, Hero.Skill.TACTICS: 75.0},
}
const WATER_ELEMENTAL := {
	"look": "water_elemental",
	"danger": 5, "str": 90, "dex": 35, "int": 10, "wspeed": 30, "dmg_min": 7, "dmg_max": 13,
	"move": 3.2, "leash": 3, "aggro": 6.0, "respawn": 0.0, "armor": 4.0, "scale": 1.4,
	"skills": {Hero.Skill.SWORDSMANSHIP: 65.0, Hero.Skill.TACTICS: 70.0},
}
const DAEMON := {
	"look": "daemon",
	"danger": 7, "str": 110, "dex": 50, "int": 40, "wspeed": 35, "dmg_min": 12, "dmg_max": 22,
	"move": 3.8, "leash": 3, "aggro": 7.0, "respawn": 0.0, "armor": 4.0, "scale": 1.6,
	"skills": {Hero.Skill.SWORDSMANSHIP: 85.0, Hero.Skill.TACTICS: 85.0},
}


## The stat block a summoning spell calls up ("CREATURE": a wolf or a bear at random).
static func summon_cfg(key: String) -> Dictionary:
	match key:
		"CREATURE":
			return WOLF if randf() < 0.5 else BROWN_BEAR
		"BLADE_SPIRITS":
			return BLADE_SPIRITS
		"ENERGY_VORTEX":
			return ENERGY_VORTEX
		"AIR_ELEMENTAL":
			return AIR_ELEMENTAL
		"FIRE_ELEMENTAL":
			return FIRE_ELEMENTAL
		"WATER_ELEMENTAL":
			return WATER_ELEMENTAL
		"DAEMON":
			return DAEMON
	return EARTH_ELEMENTAL


# Peaceful NPCs.
const STABLEMASTER := {"str": 30, "dex": 20, "int": 20, "move": 1.0, "leash": 1, "role": "stable"}
const MERCHANT := {"str": 20, "dex": 15, "int": 30, "move": 1.5, "leash": 2, "role": "merchant"}
const GUARD := {"str": 60, "dex": 40, "int": 10, "move": 1.5, "leash": 2, "role": "guard"}
const VENDOR := {"str": 20, "dex": 15, "int": 20, "move": 0.0, "leash": 0, "role": "vendor"}
const BANKER := {"str": 20, "dex": 15, "int": 30, "move": 1.2, "leash": 1, "role": "banker"}
const QUESTGIVER := {"str": 50, "dex": 30, "int": 20, "move": 1.2, "leash": 1, "role": "questgiver"}
const HEALER := {"str": 25, "dex": 15, "int": 35, "move": 1.5, "leash": 2, "role": "healer"}
## Cures poison for free, sells a blessing and hears confessions (see Entity.visit_priest).
const PRIEST := {"str": 20, "dex": 15, "int": 45, "move": 1.0, "leash": 1, "role": "priest"}

# Hostile monsters.
const RAT := {
	"look": "rat",
	"danger": 1,
	"str": 12, "dex": 25, "int": 5, "wspeed": 35, "dmg_min": 1, "dmg_max": 3,
	"move": 2.6, "leash": 5, "aggro": 4.0, "respawn": 10.0, "scale": 0.5,
	"loot": {"gold_min": 3, "gold_max": 8, "drops": [["rat_tail", 0.7]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 25.0, Hero.Skill.TACTICS: 20.0},
}
const WOLF := {
	"look": "wolf",
	"species": "wolf", "tame": 35.0, "color": "c0392b",
	"danger": 2,
	"str": 28, "dex": 50, "int": 5, "wspeed": 50, "dmg_min": 2, "dmg_max": 6,
	"move": 3.8, "leash": 6, "aggro": 5.0, "respawn": 12.0, "scale": 0.8, "armor": 1.0,
	"loot": {"gold_min": 6, "gold_max": 14, "drops": [["wolf_pelt", 0.7], ["leather_armor", 0.12]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 45.0, Hero.Skill.TACTICS: 30.0},
}
const ORC := {
	"look": "orc",
	"danger": 3,
	"str": 45, "dex": 40, "int": 10, "wspeed": 30, "dmg_min": 3, "dmg_max": 8,
	"move": 2.2, "leash": 5, "aggro": 5.0, "respawn": 15.0, "scale": 1.15, "armor": 2.0,
	"loot": {"gold_min": 15, "gold_max": 35, "drops": [["orc_ear", 0.8], ["longsword", 0.15], ["studded_armor", 0.15], ["chainmail", 0.08], ["wooden_shield", 0.12], ["bronze_shield", 0.06]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 60.0, Hero.Skill.TACTICS: 40.0, Hero.Skill.ANATOMY: 30.0},
}
const EVIL_MAGE := {
	"look": "evil_mage",
	"danger": 4,
	"str": 25, "dex": 25, "int": 45, "wspeed": 30, "dmg_min": 1, "dmg_max": 3,
	"move": 2.4, "leash": 5, "aggro": 6.0, "respawn": 20.0, "reagents": 999,
	"loot": {"gold_min": 25, "gold_max": 50, "reagents": 4, "drops": [["mage_robe", 0.4], ["kryss", 0.15], ["dagger", 0.2]]},
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 20.0, Hero.Skill.MAGERY: 55.0, Hero.Skill.EVALUATING_INTELLECT: 40.0,
		Hero.Skill.MEDITATION: 40.0, Hero.Skill.RESISTING_SPELLS: 30.0,
	},
}

# Dungeon dwellers: tougher, and better loot.
const SKELETON := {
	"look": "skeleton",
	"danger": 4,
	"str": 40, "dex": 35, "int": 10, "wspeed": 35, "dmg_min": 4, "dmg_max": 10,
	"move": 2.6, "leash": 4, "aggro": 5.0, "respawn": 20.0, "armor": 2.0, "scale": 1.0,
	"loot": {"gold_min": 25, "gold_max": 55, "drops": [["broadsword", 0.12], ["heater_shield", 0.08], ["chainmail", 0.08]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 65.0, Hero.Skill.TACTICS: 60.0, Hero.Skill.ANATOMY: 30.0},
}
const ZOMBIE := {
	"look": "zombie",
	"poison": [2, 0.25],
	"danger": 4,
	"str": 55, "dex": 20, "int": 5, "wspeed": 25, "dmg_min": 5, "dmg_max": 12,
	"move": 1.8, "leash": 4, "aggro": 4.0, "respawn": 20.0, "armor": 1.0, "scale": 1.05,
	"loot": {"gold_min": 20, "gold_max": 45, "drops": [["studded_armor", 0.15]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 55.0, Hero.Skill.TACTICS: 55.0},
}
const OGRE := {
	"look": "ogre",
	"danger": 6,
	"str": 90, "dex": 40, "int": 15, "wspeed": 25, "dmg_min": 9, "dmg_max": 18,
	"move": 2.3, "leash": 4, "aggro": 5.0, "respawn": 30.0, "armor": 3.0, "scale": 1.5,
	"loot": {"gold_min": 40, "gold_max": 90, "drops": [["halberd", 0.15], ["platemail", 0.08]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 75.0, Hero.Skill.TACTICS: 70.0, Hero.Skill.ANATOMY: 50.0},
}
const LICH := {
	"look": "lich",
	"danger": 8,
	"str": 50, "dex": 40, "int": 80, "wspeed": 30, "dmg_min": 3, "dmg_max": 8,
	"move": 2.2, "leash": 3, "aggro": 7.0, "respawn": 45.0, "reagents": 999, "scale": 1.2,
	"loot": {"gold_min": 80, "gold_max": 160, "reagents": 12, "drops": [["platemail", 0.15], ["heater_shield", 0.15], ["mage_robe", 0.5]]},
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 40.0, Hero.Skill.MAGERY: 90.0, Hero.Skill.EVALUATING_INTELLECT: 80.0,
		Hero.Skill.MEDITATION: 80.0, Hero.Skill.RESISTING_SPELLS: 70.0,
	},
}

# Poisons on hit (lesser poison, 15% a hit). Lives in the south-west woods, away from the start.
const GIANT_SPIDER := {
	"look": "spider",
	"danger": 2, "poison": [1, 0.15],
	"str": 22, "dex": 40, "int": 5, "wspeed": 45, "dmg_min": 2, "dmg_max": 5,
	"move": 3.0, "leash": 5, "aggro": 4.0, "respawn": 15.0, "scale": 0.7,
	"loot": {"gold_min": 5, "gold_max": 14, "reagents": 2, "drops": [["potion_cure", 0.15]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 45.0, Hero.Skill.TACTICS: 30.0},
}

# Wildlife. Hinds are passive (players leave them alone unless told to attack); bears bite.
const HIND := {
	"look": "hind",
	"species": "hind", "tame": 10.0, "passive": true, "danger": 0.5, "color": "b08a5a",
	"str": 18, "dex": 45, "int": 5, "wspeed": 45, "dmg_min": 1, "dmg_max": 3,
	"move": 3.2, "leash": 6, "aggro": 0.0, "respawn": 20.0, "scale": 0.8,
	"loot": {"gold_min": 0, "gold_max": 0, "drops": []},
	"skills": {Hero.Skill.SWORDSMANSHIP: 20.0, Hero.Skill.TACTICS: 20.0},
}
const BROWN_BEAR := {
	"look": "bear",
	"species": "brown_bear", "tame": 55.0, "danger": 3, "color": "6b4a2a",
	"str": 60, "dex": 30, "int": 10, "wspeed": 30, "dmg_min": 4, "dmg_max": 10,
	"move": 2.6, "leash": 5, "aggro": 4.0, "respawn": 30.0, "scale": 1.3, "armor": 1.0,
	"loot": {"gold_min": 5, "gold_max": 15, "drops": [["wolf_pelt", 0.5]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 55.0, Hero.Skill.TACTICS: 50.0, Hero.Skill.ANATOMY: 30.0},
}


## Stat block for a tameable species (used to bring saved pets back).
static func by_species(species: String) -> Dictionary:
	match species:
		"horse":
			return HORSE
		"llama":
			return LLAMA
		"hind":
			return HIND
		"wolf":
			return WOLF
		"brown_bear":
			return BROWN_BEAR
	return {}
