class_name Bestiary
## Stat blocks for everything that walks the map.
## Keys: pk (preys on innocents), weapon/wear/shield (starting gear ids from Gear), bandages, str/dex/int, skills, reagents, gold (carried), loot (monster drops), dmg_min/dmg_max (weapon roll), wspeed (weapon speed 20..60),
## move (m/s), armor, leash (wander radius in tiles), aggro (m), respawn (s), role, scale.

const HERO := {
	"str": 25, "dex": 20, "int": 20, "wspeed": 45, "dmg_min": 5, "dmg_max": 10,
	"move": 4.0, "leash": 8, "aggro": 5.0, "respawn": 5.0,
	"reagents": 30, "gold": 20, "weapon": "dagger", "bandages": 5,
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
const HEALER := {"str": 25, "dex": 15, "int": 35, "move": 1.5, "leash": 2, "role": "healer"}

# Hostile monsters.
const RAT := {
	"str": 12, "dex": 25, "int": 5, "wspeed": 35, "dmg_min": 1, "dmg_max": 3,
	"move": 2.6, "leash": 5, "aggro": 4.0, "respawn": 10.0, "scale": 0.5,
	"loot": {"gold_min": 1, "gold_max": 5, "drops": [["rat_tail", 0.7]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 25.0, Hero.Skill.TACTICS: 20.0},
}
const WOLF := {
	"str": 28, "dex": 50, "int": 5, "wspeed": 50, "dmg_min": 2, "dmg_max": 6,
	"move": 3.8, "leash": 6, "aggro": 5.0, "respawn": 12.0, "scale": 0.8, "armor": 1.0,
	"loot": {"gold_min": 2, "gold_max": 8, "drops": [["wolf_pelt", 0.7], ["leather_armor", 0.12]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 45.0, Hero.Skill.TACTICS: 30.0},
}
const ORC := {
	"str": 45, "dex": 40, "int": 10, "wspeed": 30, "dmg_min": 3, "dmg_max": 8,
	"move": 2.2, "leash": 5, "aggro": 5.0, "respawn": 15.0, "scale": 1.15, "armor": 2.0,
	"loot": {"gold_min": 8, "gold_max": 25, "drops": [["orc_ear", 0.8], ["longsword", 0.15], ["studded_armor", 0.15], ["chainmail", 0.08], ["wooden_shield", 0.12], ["bronze_shield", 0.06]]},
	"skills": {Hero.Skill.SWORDSMANSHIP: 60.0, Hero.Skill.TACTICS: 40.0, Hero.Skill.ANATOMY: 30.0},
}
const EVIL_MAGE := {
	"str": 25, "dex": 25, "int": 45, "wspeed": 30, "dmg_min": 1, "dmg_max": 3,
	"move": 2.4, "leash": 5, "aggro": 6.0, "respawn": 20.0, "reagents": 999,
	"loot": {"gold_min": 10, "gold_max": 30, "reagents": 4, "drops": [["mage_robe", 0.4], ["kryss", 0.15], ["dagger", 0.2]]},
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 20.0, Hero.Skill.MAGERY: 55.0, Hero.Skill.EVALUATING_INTELLECT: 40.0,
		Hero.Skill.MEDITATION: 40.0, Hero.Skill.RESISTING_SPELLS: 30.0,
	},
}
