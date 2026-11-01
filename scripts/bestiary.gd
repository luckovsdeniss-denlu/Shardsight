class_name Bestiary
## Stat blocks for everything that walks the map.
## Keys: str/dex/int, skills, dmg_min/dmg_max (weapon roll), wspeed (weapon speed 20..60),
## move (m/s), armor, leash (wander radius in tiles), aggro (m), respawn (s), role, scale.

const HERO := {
	"str": 25, "dex": 20, "int": 20, "wspeed": 45, "dmg_min": 5, "dmg_max": 10,
	"move": 4.0, "leash": 8, "aggro": 5.0, "respawn": 5.0,
	"skills": {Hero.Skill.SWORDSMANSHIP: 50.0, Hero.Skill.TACTICS: 50.0, Hero.Skill.ANATOMY: 50.0},
}

# Other players, played by the computer.
const WARRIOR := {
	"str": 35, "dex": 20, "int": 10, "wspeed": 45, "dmg_min": 5, "dmg_max": 10,
	"move": 3.6, "leash": 8, "aggro": 5.0, "respawn": 5.0, "armor": 1.0,
	"skills": {Hero.Skill.SWORDSMANSHIP: 60.0, Hero.Skill.TACTICS: 50.0, Hero.Skill.ANATOMY: 40.0},
}
const FIGHTER := {
	"str": 30, "dex": 25, "int": 10, "wspeed": 55, "dmg_min": 4, "dmg_max": 8,
	"move": 3.8, "leash": 8, "aggro": 5.0, "respawn": 5.0,
	"skills": {Hero.Skill.SWORDSMANSHIP: 55.0, Hero.Skill.TACTICS: 55.0, Hero.Skill.ANATOMY: 45.0},
}

# Peaceful NPCs.
const MERCHANT := {"str": 20, "dex": 15, "int": 30, "move": 1.5, "leash": 2, "role": "merchant"}
const HEALER := {"str": 25, "dex": 15, "int": 35, "move": 1.5, "leash": 2, "role": "healer"}

# Hostile monsters.
const RAT := {
	"str": 12, "dex": 25, "int": 5, "wspeed": 35, "dmg_min": 1, "dmg_max": 3,
	"move": 2.6, "leash": 5, "aggro": 4.0, "respawn": 10.0, "scale": 0.5,
	"skills": {Hero.Skill.SWORDSMANSHIP: 25.0, Hero.Skill.TACTICS: 20.0},
}
const WOLF := {
	"str": 28, "dex": 50, "int": 5, "wspeed": 50, "dmg_min": 2, "dmg_max": 6,
	"move": 3.8, "leash": 6, "aggro": 5.0, "respawn": 12.0, "scale": 0.8, "armor": 1.0,
	"skills": {Hero.Skill.SWORDSMANSHIP: 45.0, Hero.Skill.TACTICS: 30.0},
}
const ORC := {
	"str": 45, "dex": 40, "int": 10, "wspeed": 30, "dmg_min": 3, "dmg_max": 8,
	"move": 2.2, "leash": 5, "aggro": 5.0, "respawn": 15.0, "scale": 1.15, "armor": 2.0,
	"skills": {Hero.Skill.SWORDSMANSHIP: 60.0, Hero.Skill.TACTICS: 40.0, Hero.Skill.ANATOMY: 30.0},
}
