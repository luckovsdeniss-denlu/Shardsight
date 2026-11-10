class_name Spells
## Magery spells. Circle, mana and minimum Magery follow the mechanics reference (all 8 circles;
## 7 and 8 are "about" figures there). Damage/heal ranges and reagent counts are tuning guesses.
## Kinds: attack (one target), heal (self), cure (self, removes poison), poison (one target),
## area (everything hostile around the caster), paralyze (one target can't move or act until hit
## or the spell wears off), resurrect (raises a ghost player), summon (a creature fights for the
## caster for "secs"; min/max_dmg rank how strong it is), buff (the caster: stat "mods" and/or a
## "flag" for "secs"), curse (a foe, or every foe around with "area": negative "mods"), drain
## (takes a foe's mana; "steal" gives it to the caster), field (on the ground at the target:
## fire, poison, paralyze, trap or a wall), dispel (removes traps, fields or summons), util
## (one-off effects handled by id), travel (Recall, Mark, Gate Travel: Menu > Travel).
## The full classic list: 8 spells in each of the 8 circles.
## A spell must be in the caster's spellbook (copied from a scroll) to be cast.
## Circles 1 and 2 have the classic negative minimums (-20 and -6), so a beginner with no Magery
## can already cast them, often fizzling at first (50% and 15%), and learns by doing.

const ORDER := [
	"magic_arrow", "heal", "clumsy", "create_food", "feeblemind", "night_sight", "reactive_armor",
	"weaken", "harm", "cure", "agility", "cunning", "magic_trap", "magic_untrap", "protection",
	"strength", "poison", "fireball", "bless", "magic_lock", "telekinesis", "teleport", "unlock",
	"wall_of_stone", "lightning", "greater_heal", "arch_cure", "arch_protection", "curse",
	"fire_field", "mana_drain", "mind_blast", "paralyze", "blade_spirits", "dispel_field",
	"incognito", "magic_reflection", "poison_field", "summon_creature", "energy_bolt",
	"explosion", "dispel", "invisibility", "mass_curse", "paralyze_field", "reveal",
	"flamestrike", "chain_lightning", "energy_field", "mana_vampire", "mass_dispel",
	"meteor_swarm", "polymorph", "earthquake", "resurrection", "summon_elemental",
	"horrific_beast", "wraith_form", "lich_form",
	"energy_vortex", "summon_air", "summon_daemon", "summon_fire", "summon_water", "recall",
	"mark", "gate_travel",
]
## The spells a new character's spellbook starts with: all of the first four circles.
const STARTER := [
	"magic_arrow", "heal", "clumsy", "create_food", "feeblemind", "night_sight", "reactive_armor",
	"weaken", "harm", "cure", "agility", "cunning", "magic_trap", "magic_untrap", "protection",
	"strength", "poison", "fireball", "bless", "magic_lock", "telekinesis", "teleport", "unlock",
	"wall_of_stone", "lightning", "greater_heal", "arch_cure", "arch_protection", "curse",
	"fire_field", "mana_drain", "recall",
]
const PARALYZE_BASE := 4.0         # seconds, + Magery / 25
const SUMMON_SECONDS := 90.0
const AREA_RADIUS := 5.0

## Transformations ("transform" spells): your body becomes something else for a while. "look" is
## the model ("ghost" for the wraith's shroud); "mods" are stat changes; "speed", "melee" (damage
## of your blows), "taken" (damage you take), "mana_regen" and "regen" (health a second) and
## "armor" change how you fight; beasts ("cast": false) can't cast spells until they change back.
## Polymorph picks its beast by Magery: a wolf, a bear, then an ogre.
const FORMS := {
	"wolf": {"name": "Wolf Form", "look": "wolf", "scale": 1.15, "mods": {"dex": 15}, "speed": 1.35, "melee": 1.15, "cast": false},
	"bear": {"name": "Bear Form", "look": "bear", "scale": 1.1, "mods": {"str": 20}, "armor": 3.0, "melee": 1.3, "cast": false},
	"ogre": {"name": "Ogre Form", "look": "ogre", "scale": 0.8, "mods": {"str": 30}, "armor": 2.0, "melee": 1.45, "speed": 0.9, "cast": false},
	"horrific_beast": {"name": "Horrific Beast", "look": "daemon", "scale": 0.85, "mods": {"str": 10}, "melee": 1.25, "regen": 1.0, "cast": false},
	"wraith": {"name": "Wraith Form", "look": "ghost", "mods": {}, "taken": 0.75, "mana_regen": 1.5, "cast": true},
	"lich": {"name": "Lich Form", "look": "lich", "scale": 1.0, "mods": {"int": 20}, "mana_regen": 3.0, "taken": 1.1, "cast": true},
}


const LIST := {
	"magic_arrow": {
		"name": "Magic Arrow", "words": "Yn Pohr Ylaem", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 1, "kind": "attack", "min_dmg": 3.0, "max_dmg": 7.0,
		"color": Color(1.0, 0.85, 0.3),
	},
	"heal": {
		"name": "Heal", "words": "Yn Mahni", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 1, "kind": "heal", "min_dmg": 6.0, "max_dmg": 10.0,
		"color": Color(0.5, 1.0, 0.5),
	},
	"harm": {
		"name": "Harm", "words": "Ahn Mahni", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 1, "kind": "attack", "min_dmg": 4.0, "max_dmg": 9.0,
		"color": Color(0.5, 0.8, 1.0),
	},
	"cure": {
		"name": "Cure", "words": "Ahn Nokh", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 2, "kind": "cure", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 1.0, 0.6),
	},
	"poison": {
		"name": "Poison", "words": "Yn Nokh", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "poison", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.4, 0.9, 0.3),
	},
	"fireball": {
		"name": "Fireball", "words": "Vaas Flaem", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "attack", "min_dmg": 7.0, "max_dmg": 13.0,
		"color": Color(1.0, 0.45, 0.1),
	},
	"lightning": {
		"name": "Lightning", "words": "Pohr Orth Graav", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "attack", "min_dmg": 10.0, "max_dmg": 18.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"greater_heal": {
		"name": "Greater Heal", "words": "Yn Vaas Mahni", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "heal", "min_dmg": 14.0, "max_dmg": 20.0,
		"color": Color(0.4, 1.0, 0.7),
	},
	"mind_blast": {
		"name": "Mind Blast", "words": "Pohr Korph Wys", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "attack", "min_dmg": 12.0, "max_dmg": 20.0,
		"color": Color(0.9, 0.5, 1.0),
	},
	"energy_bolt": {
		"name": "Energy Bolt", "words": "Korph Pohr", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "attack", "min_dmg": 16.0, "max_dmg": 26.0,
		"color": Color(0.6, 0.4, 1.0),
	},
	"explosion": {
		"name": "Explosion", "words": "Vaas Orth Flaem", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "attack", "min_dmg": 15.0, "max_dmg": 25.0,
		"color": Color(1.0, 0.55, 0.2),
	},
	"flamestrike": {
		"name": "Flamestrike", "words": "Khal Vaas Flaem", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 2, "kind": "attack", "min_dmg": 24.0, "max_dmg": 36.0,
		"color": Color(1.0, 0.3, 0.1),
	},
	"earthquake": {
		"name": "Earthquake", "words": "Yn Vaas Pohr", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "area", "min_dmg": 14.0, "max_dmg": 24.0,
		"color": Color(0.7, 0.55, 0.35),
	},
	"paralyze": {
		"name": "Paralyze", "words": "Ahn Eks Pohr", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "paralyze", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.85, 0.7, 1.0),
	},
	"resurrection": {
		"name": "Resurrection", "words": "Ahn Korph", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 3, "kind": "resurrect", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 1.0, 0.8),
	},
	"summon_elemental": {
		"name": "Summon Earth Elemental", "words": "Khal Vaas Zhen Ylaem", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 8.0, "max_dmg": 15.0,
		"color": Color(0.6, 0.45, 0.3), "summon": "EARTH_ELEMENTAL", "secs": 90.0,
	},
	"recall": {
		"name": "Recall", "words": "Khal Orth Pohr", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "travel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 0.7, 1.0),
	},
	"mark": {
		"name": "Mark", "words": "Khal Pohr Ylaem", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 3, "kind": "travel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 0.7, 1.0),
	},
	"gate_travel": {
		"name": "Gate Travel", "words": "Vaas Rhel Pohr", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 3, "kind": "travel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.4, 0.6, 1.0),
	},
	"clumsy": {
		"name": "Clumsy", "words": "Uhs Juks", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 2, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.6, 0.9), "mods": {"dex": -10}, "secs": 60.0,
	},
	"create_food": {
		"name": "Create Food", "words": "Yn Mahni Ylaem", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 3, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.85, 0.5),
	},
	"feeblemind": {
		"name": "Feeblemind", "words": "Rhel Wys", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 2, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.6, 0.9), "mods": {"int": -10}, "secs": 60.0,
	},
	"night_sight": {
		"name": "Night Sight", "words": "Yn Lhor", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 1.0, 0.7), "flag": "night_sight", "secs": 600.0,
	},
	"reactive_armor": {
		"name": "Reactive Armor", "words": "Flaem Sankt", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.6, 0.3), "flag": "reactive_armor", "secs": 60.0,
	},
	"weaken": {
		"name": "Weaken", "words": "Dess Mahni", "circle": 1, "mana": 4, "min": -20.0,
		"reagents": 2, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.6, 0.9), "mods": {"str": -10}, "secs": 60.0,
	},
	"agility": {
		"name": "Agility", "words": "Eks Uhs", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 1.0, 0.8), "mods": {"dex": 10}, "secs": 120.0,
	},
	"cunning": {
		"name": "Cunning", "words": "Uhs Wys", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.8, 1.0), "mods": {"int": 10}, "secs": 120.0,
	},
	"magic_trap": {
		"name": "Magic Trap", "words": "Yn Juks", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 3, "kind": "field", "min_dmg": 12.0, "max_dmg": 22.0,
		"color": Color(1.0, 0.4, 0.2), "field": "trap", "secs": 300.0,
	},
	"magic_untrap": {
		"name": "Magic Untrap", "words": "Ahn Juks", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 2, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "trap",
	},
	"protection": {
		"name": "Protection", "words": "Uhs Sankt", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.9, 1.0), "flag": "protection", "secs": 90.0,
	},
	"strength": {
		"name": "Strength", "words": "Uhs Mahni", "circle": 2, "mana": 6, "min": -6.0,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.7, 0.6), "mods": {"str": 10}, "secs": 120.0,
	},
	"bless": {
		"name": "Bless", "words": "Rhel Sankt", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.95, 0.6), "mods": {"str": 10, "dex": 10, "int": 10}, "secs": 120.0,
	},
	"magic_lock": {
		"name": "Magic Lock", "words": "Ahn Pohr", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 3, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"telekinesis": {
		"name": "Telekinesis", "words": "Orth Pohr Ylaem", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"teleport": {
		"name": "Teleport", "words": "Rhel Pohr", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.8, 1.0),
	},
	"unlock": {
		"name": "Unlock", "words": "Eks Pohr", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"wall_of_stone": {
		"name": "Wall of Stone", "words": "Yn Sankt Ylaem", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "field", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.6, 0.6), "field": "wall", "secs": 10.0,
	},
	"arch_cure": {
		"name": "Arch Cure", "words": "Vaas Ahn Nokh", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 1.0, 0.6),
	},
	"arch_protection": {
		"name": "Arch Protection", "words": "Vaas Uhs Sankt", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 4, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.9, 1.0), "flag": "protection", "secs": 90.0,
	},
	"curse": {
		"name": "Curse", "words": "Dess Sankt", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.5, 0.9), "mods": {"str": -10, "dex": -10, "int": -10}, "secs": 60.0,
	},
	"fire_field": {
		"name": "Fire Field", "words": "Yn Flaem Graav", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "field", "min_dmg": 3.0, "max_dmg": 3.0,
		"color": Color(1.0, 0.45, 0.1), "field": "fire", "secs": 12.0,
	},
	"mana_drain": {
		"name": "Mana Drain", "words": "Orth Rhel", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "drain", "min_dmg": 10.0, "max_dmg": 20.0,
		"color": Color(0.4, 0.5, 1.0),
	},
	"blade_spirits": {
		"name": "Blade Spirits", "words": "Yn Juks Hyr Ylaem", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "summon", "min_dmg": 6.0, "max_dmg": 12.0,
		"color": Color(0.8, 0.8, 0.9), "summon": "BLADE_SPIRITS", "secs": 45.0,
	},
	"dispel_field": {
		"name": "Dispel Field", "words": "Ahn Graav", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 2, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "any",
	},
	"incognito": {
		"name": "Incognito", "words": "Khal Yn Eks", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.7, 0.7), "flag": "incognito", "secs": 120.0,
	},
	"magic_reflection": {
		"name": "Magic Reflection", "words": "Yn Juks Sankt", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.9, 0.9, 1.0), "flag": "magic_reflection", "secs": 120.0,
	},
	"poison_field": {
		"name": "Poison Field", "words": "Yn Nokh Graav", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "field", "min_dmg": 1.0, "max_dmg": 1.0,
		"color": Color(0.4, 1.0, 0.3), "field": "poison", "secs": 15.0,
	},
	"summon_creature": {
		"name": "Summon Creature", "words": "Khal Zhen", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "summon", "min_dmg": 5.0, "max_dmg": 10.0,
		"color": Color(0.6, 0.5, 0.3), "summon": "CREATURE", "secs": 60.0,
	},
	"dispel": {
		"name": "Dispel", "words": "Ahn Orth", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 3, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "summon",
	},
	"invisibility": {
		"name": "Invisibility", "words": "Ahn Lhor Zhen", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 0.8), "flag": "invisible", "secs": 15.0,
	},
	"mass_curse": {
		"name": "Mass Curse", "words": "Vaas Dess Sankt", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 4, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.4, 0.8), "mods": {"str": -10, "dex": -10, "int": -10}, "secs": 60.0, "area": true,
	},
	"paralyze_field": {
		"name": "Paralyze Field", "words": "Yn Eks Graav", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 3, "kind": "field", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.85, 0.7, 1.0), "field": "paralyze", "secs": 15.0,
	},
	"reveal": {
		"name": "Reveal", "words": "Wys Kwas", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 1.0, 0.8),
	},
	"chain_lightning": {
		"name": "Chain Lightning", "words": "Vaas Orth Graav", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "area", "min_dmg": 16.0, "max_dmg": 26.0,
		"color": Color(0.6, 0.8, 1.0),
	},
	"energy_field": {
		"name": "Energy Field", "words": "Yn Sankt Graav", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "field", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 0.6, 1.0), "field": "wall", "secs": 20.0,
	},
	"mana_vampire": {
		"name": "Mana Vampire", "words": "Orth Sankt", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "drain", "min_dmg": 20.0, "max_dmg": 35.0,
		"color": Color(0.3, 0.4, 1.0), "steal": true,
	},
	"mass_dispel": {
		"name": "Mass Dispel", "words": "Vaas Ahn Orth", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "all",
	},
	"meteor_swarm": {
		"name": "Meteor Swarm", "words": "Flaem Khal Dess Ylaem", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "area", "min_dmg": 18.0, "max_dmg": 28.0,
		"color": Color(1.0, 0.5, 0.2),
	},
	"polymorph": {
		"name": "Polymorph", "words": "Vaas Ylaem Rhel", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 3, "kind": "transform", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.9, 0.6, 0.4), "form": "beast", "secs": 150.0,
	},
	"horrific_beast": {
		"name": "Horrific Beast", "words": "Rhel Zhen Vaas Bhal", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 2, "kind": "transform", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.85, 0.3, 0.2), "form": "horrific_beast", "secs": 120.0,
	},
	"wraith_form": {
		"name": "Wraith Form", "words": "Rhel Zhen Uhm", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "transform", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.7, 0.95), "form": "wraith", "secs": 120.0,
	},
	"lich_form": {
		"name": "Lich Form", "words": "Rhel Zhen Korph Orth", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "transform", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.35, 0.8), "form": "lich", "secs": 180.0,
	},
	"energy_vortex": {
		"name": "Energy Vortex", "words": "Vaas Korph Pohr", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 14.0, "max_dmg": 24.0,
		"color": Color(0.5, 0.5, 1.0), "summon": "ENERGY_VORTEX", "secs": 60.0,
	},
	"summon_air": {
		"name": "Summon Air Elemental", "words": "Khal Vaas Zhen Hyr", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 3, "kind": "summon", "min_dmg": 9.0, "max_dmg": 16.0,
		"color": Color(0.8, 0.9, 1.0), "summon": "AIR_ELEMENTAL", "secs": 90.0,
	},
	"summon_daemon": {
		"name": "Summon Daemon", "words": "Khal Vaas Zhen Korph", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 14.0, "max_dmg": 26.0,
		"color": Color(0.8, 0.2, 0.2), "summon": "DAEMON", "secs": 90.0,
	},
	"summon_fire": {
		"name": "Summon Fire Elemental", "words": "Khal Vaas Zhen Flaem", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 11.0, "max_dmg": 19.0,
		"color": Color(1.0, 0.4, 0.1), "summon": "FIRE_ELEMENTAL", "secs": 90.0,
	},
	"summon_water": {
		"name": "Summon Water Elemental", "words": "Khal Vaas Zhen Ahn Flaem", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 9.0, "max_dmg": 16.0,
		"color": Color(0.3, 0.5, 1.0), "summon": "WATER_ELEMENTAL", "secs": 90.0,
	},
}


## The item id of a spell's scroll, and back.
static func scroll_id(spell_id: String) -> String:
	return "scroll_" + spell_id


static func spell_of_scroll(item_id: String) -> String:
	if not item_id.begins_with("scroll_"):
		return ""
	var id := item_id.trim_prefix("scroll_")
	return id if LIST.has(id) else ""


## A random spell of circle `lo`..`hi` (for loot and merchant stock).
static func random_of_circles(lo: int, hi: int) -> String:
	var pool: Array[String] = []
	for id in ORDER:
		var c := int(LIST[id]["circle"])
		if c >= lo and c <= hi:
			pool.append(id)
	return "" if pool.is_empty() else pool[randi() % pool.size()]
