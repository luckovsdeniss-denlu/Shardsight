class_name Bestiary
## Stat blocks for everything that walks the map.
## Keys: poison ([level, chance per hit]), danger (monster toughness: players only start fights they can win), pk (preys on innocents), crafter (gathers and crafts when idle), weapon/wear/shield (starting gear ids from Gear), bandages, str/dex/int, skills, reagents, gold (carried), loot (monster drops), dmg_min/dmg_max (weapon roll), wspeed (weapon speed 20..60),
## move (m/s), armor, leash (wander radius in tiles), aggro (m), respawn (s), role, scale.

const HERO := {
	"str": 25, "dex": 20, "int": 20, "wspeed": 45, "dmg_min": 5, "dmg_max": 10,
	"move": 4.0, "leash": 8, "aggro": 5.0, "respawn": 5.0,
	"reagents": 30, "gold": 20, "weapon": "dagger", "bandages": 5, "crafter": true,
	"skills": {Hero.Skill.SWORDSMANSHIP: 50.0, Hero.Skill.TACTICS: 30.0, Hero.Skill.MAGERY: 30.0},
}

# Other players, played by the computer.
const WARRIOR := {
	"str": 35, "dex": 20, "int": 10, "wspeed": 45, "dmg_min": 5, "dmg_max": 10,
	"move": 3.6, "leash": 8, "aggro": 5.0, "respawn": 5.0, "gold": 20, "weapon": "longsword", "wear": "chainmail",
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
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 55.0, Hero.Skill.TACTICS: 55.0, Hero.Skill.ANATOMY: 45.0,
		Hero.Skill.PARRYING: 40.0, Hero.Skill.HEALING: 30.0,
	},
}

const MAGE := {
	"str": 20, "dex": 20, "int": 40, "wspeed": 30, "dmg_min": 2, "dmg_max": 4,
	"move": 3.4, "leash": 8, "aggro": 6.0, "respawn": 5.0, "reagents": 40, "gold": 60, "weapon": "dagger", "bandages": 3,
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 20.0, Hero.Skill.MAGERY: 70.0, Hero.Skill.EVALUATING_INTELLECT: 50.0,
		Hero.Skill.MEDITATION: 50.0, Hero.Skill.RESISTING_SPELLS: 30.0, Hero.Skill.HEALING: 20.0,
	},
}

# A player killer: preys on innocent players in the wilderness.
const PKILLER := {
	"str": 30, "dex": 30, "int": 10, "wspeed": 58, "dmg_min": 1, "dmg_max": 2,
	"move": 3.7, "leash": 9, "aggro": 7.0, "respawn": 8.0, "pk": true, "gold": 30,
	"weapon": "kryss", "wear": "leather_armor", "bandages": 5,
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 55.0, Hero.Skill.TACTICS: 45.0, Hero.Skill.ANATOMY: 30.0,
		Hero.Skill.HEALING: 20.0,
	},
}

# Peaceful NPCs.
const MERCHANT := {"str": 20, "dex": 15, "int": 30, "move": 1.5, "leash": 2, "role": "merchant"}
const GUARD := {"str": 60, "dex": 40, "int": 10, "move": 1.5, "leash": 2, "role": "guard"}
const BANKER := {"str": 20, "dex": 15, "int": 30, "move": 1.2, "leash": 1, "role": "banker"}
const QUESTGIVER := {"str": 50, "dex": 30, "int": 20, "move": 1.2, "leash": 1, "role": "questgiver"}
const HEALER := {"str": 25, "dex": 15, "int": 35, "move": 1.5, "leash": 2, "role": "healer"}

# Hostile monsters.
const RAT := {
	"danger": 1,
	"str": 12, "dex": 25, "int": 5, "wspeed": 35, "dmg_min": 1, "dmg_max": 3,
	"move": 2.6, "leash": 5, "aggro": 4.0, "respawn": 10.0, "scale": 0.5,
	"loot": {"gold_min": 1, "gold_max": 5, "drops": [["rat_tail", 0.7]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 25.0, Hero.Skill.TACTICS: 20.0},
}
const WOLF := {
	"danger": 2,
	"str": 28, "dex": 50, "int": 5, "wspeed": 50, "dmg_min": 2, "dmg_max": 6,
	"move": 3.8, "leash": 6, "aggro": 5.0, "respawn": 12.0, "scale": 0.8, "armor": 1.0,
	"loot": {"gold_min": 2, "gold_max": 8, "drops": [["wolf_pelt", 0.7], ["leather_armor", 0.12]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 45.0, Hero.Skill.TACTICS: 30.0},
}
const ORC := {
	"danger": 3,
	"str": 45, "dex": 40, "int": 10, "wspeed": 30, "dmg_min": 3, "dmg_max": 8,
	"move": 2.2, "leash": 5, "aggro": 5.0, "respawn": 15.0, "scale": 1.15, "armor": 2.0,
	"loot": {"gold_min": 8, "gold_max": 25, "drops": [["orc_ear", 0.8], ["longsword", 0.15], ["studded_armor", 0.15], ["chainmail", 0.08], ["wooden_shield", 0.12], ["bronze_shield", 0.06]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 60.0, Hero.Skill.TACTICS: 40.0, Hero.Skill.ANATOMY: 30.0},
}
const EVIL_MAGE := {
	"danger": 4,
	"str": 25, "dex": 25, "int": 45, "wspeed": 30, "dmg_min": 1, "dmg_max": 3,
	"move": 2.4, "leash": 5, "aggro": 6.0, "respawn": 20.0, "reagents": 999,
	"loot": {"gold_min": 10, "gold_max": 30, "reagents": 4, "drops": [["mage_robe", 0.4], ["kryss", 0.15], ["dagger", 0.2]]},
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 20.0, Hero.Skill.MAGERY: 55.0, Hero.Skill.EVALUATING_INTELLECT: 40.0,
		Hero.Skill.MEDITATION: 40.0, Hero.Skill.RESISTING_SPELLS: 30.0,
	},
}

# Dungeon dwellers: tougher, and better loot.
const SKELETON := {
	"danger": 4,
	"str": 40, "dex": 35, "int": 10, "wspeed": 35, "dmg_min": 4, "dmg_max": 10,
	"move": 2.6, "leash": 4, "aggro": 5.0, "respawn": 20.0, "armor": 2.0, "scale": 1.0,
	"loot": {"gold_min": 15, "gold_max": 40, "drops": [["broadsword", 0.12], ["heater_shield", 0.08], ["chainmail", 0.08]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 65.0, Hero.Skill.TACTICS: 60.0, Hero.Skill.ANATOMY: 30.0},
}
const ZOMBIE := {
	"poison": [2, 0.25],
	"danger": 4,
	"str": 55, "dex": 20, "int": 5, "wspeed": 25, "dmg_min": 5, "dmg_max": 12,
	"move": 1.8, "leash": 4, "aggro": 4.0, "respawn": 20.0, "armor": 1.0, "scale": 1.05,
	"loot": {"gold_min": 10, "gold_max": 30, "drops": [["studded_armor", 0.15]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 55.0, Hero.Skill.TACTICS: 55.0},
}
const OGRE := {
	"danger": 6,
	"str": 90, "dex": 40, "int": 15, "wspeed": 25, "dmg_min": 9, "dmg_max": 18,
	"move": 2.3, "leash": 4, "aggro": 5.0, "respawn": 30.0, "armor": 3.0, "scale": 1.5,
	"loot": {"gold_min": 40, "gold_max": 90, "drops": [["halberd", 0.15], ["platemail", 0.08]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 75.0, Hero.Skill.TACTICS: 70.0, Hero.Skill.ANATOMY: 50.0},
}
const LICH := {
	"danger": 8,
	"str": 50, "dex": 40, "int": 80, "wspeed": 30, "dmg_min": 3, "dmg_max": 8,
	"move": 2.2, "leash": 3, "aggro": 7.0, "respawn": 45.0, "reagents": 999, "scale": 1.2,
	"loot": {"gold_min": 80, "gold_max": 160, "reagents": 12, "drops": [["platemail", 0.15], ["heater_shield", 0.15], ["mage_robe", 0.5]]},
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 40.0, Hero.Skill.MAGERY: 90.0, Hero.Skill.EVALUATING_INTELLECT: 80.0,
		Hero.Skill.MEDITATION: 80.0, Hero.Skill.RESISTING_SPELLS: 70.0,
	},
}

# Poisons on hit (lesser poison). Lives in the woods north of the start.
const GIANT_SPIDER := {
	"danger": 2, "poison": [1, 0.35],
	"str": 22, "dex": 40, "int": 5, "wspeed": 45, "dmg_min": 2, "dmg_max": 5,
	"move": 3.0, "leash": 5, "aggro": 4.0, "respawn": 15.0, "scale": 0.7,
	"loot": {"gold_min": 3, "gold_max": 10, "reagents": 2, "drops": [["potion_cure", 0.15]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 45.0, Hero.Skill.TACTICS: 30.0},
}
