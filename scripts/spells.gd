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

const LIST := {
	"magic_arrow": {
		"name": "Magic Arrow", "words": "In Por Ylem", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 1, "kind": "attack", "min_dmg": 3.0, "max_dmg": 7.0,
		"color": Color(1.0, 0.85, 0.3),
	},
	"heal": {
		"name": "Heal", "words": "In Mani", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 1, "kind": "heal", "min_dmg": 6.0, "max_dmg": 10.0,
		"color": Color(0.5, 1.0, 0.5),
	},
	"harm": {
		"name": "Harm", "words": "An Mani", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 1, "kind": "attack", "min_dmg": 4.0, "max_dmg": 9.0,
		"color": Color(0.5, 0.8, 1.0),
	},
	"cure": {
		"name": "Cure", "words": "An Nox", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 2, "kind": "cure", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 1.0, 0.6),
	},
	"poison": {
		"name": "Poison", "words": "In Nox", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "poison", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.4, 0.9, 0.3),
	},
	"fireball": {
		"name": "Fireball", "words": "Vas Flam", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "attack", "min_dmg": 7.0, "max_dmg": 13.0,
		"color": Color(1.0, 0.45, 0.1),
	},
	"lightning": {
		"name": "Lightning", "words": "Por Ort Grav", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "attack", "min_dmg": 10.0, "max_dmg": 18.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"greater_heal": {
		"name": "Greater Heal", "words": "In Vas Mani", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "heal", "min_dmg": 14.0, "max_dmg": 20.0,
		"color": Color(0.4, 1.0, 0.7),
	},
	"mind_blast": {
		"name": "Mind Blast", "words": "Por Corp Wis", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "attack", "min_dmg": 12.0, "max_dmg": 20.0,
		"color": Color(0.9, 0.5, 1.0),
	},
	"energy_bolt": {
		"name": "Energy Bolt", "words": "Corp Por", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "attack", "min_dmg": 16.0, "max_dmg": 26.0,
		"color": Color(0.6, 0.4, 1.0),
	},
	"explosion": {
		"name": "Explosion", "words": "Vas Ort Flam", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "attack", "min_dmg": 15.0, "max_dmg": 25.0,
		"color": Color(1.0, 0.55, 0.2),
	},
	"flamestrike": {
		"name": "Flamestrike", "words": "Kal Vas Flam", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 2, "kind": "attack", "min_dmg": 24.0, "max_dmg": 36.0,
		"color": Color(1.0, 0.3, 0.1),
	},
	"earthquake": {
		"name": "Earthquake", "words": "In Vas Por", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "area", "min_dmg": 14.0, "max_dmg": 24.0,
		"color": Color(0.7, 0.55, 0.35),
	},
	"paralyze": {
		"name": "Paralyze", "words": "An Ex Por", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "paralyze", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.85, 0.7, 1.0),
	},
	"resurrection": {
		"name": "Resurrection", "words": "An Corp", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 3, "kind": "resurrect", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 1.0, 0.8),
	},
	"summon_elemental": {
		"name": "Summon Earth Elemental", "words": "Kal Vas Xen Ylem", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 8.0, "max_dmg": 15.0,
		"color": Color(0.6, 0.45, 0.3), "summon": "EARTH_ELEMENTAL", "secs": 90.0,
	},
	"recall": {
		"name": "Recall", "words": "Kal Ort Por", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "travel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 0.7, 1.0),
	},
	"mark": {
		"name": "Mark", "words": "Kal Por Ylem", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 3, "kind": "travel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 0.7, 1.0),
	},
	"gate_travel": {
		"name": "Gate Travel", "words": "Vas Rel Por", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 3, "kind": "travel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.4, 0.6, 1.0),
	},
	"clumsy": {
		"name": "Clumsy", "words": "Uus Jux", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 2, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.6, 0.9), "mods": {"dex": -10}, "secs": 60.0,
	},
	"create_food": {
		"name": "Create Food", "words": "In Mani Ylem", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 3, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.85, 0.5),
	},
	"feeblemind": {
		"name": "Feeblemind", "words": "Rel Wis", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 2, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.6, 0.9), "mods": {"int": -10}, "secs": 60.0,
	},
	"night_sight": {
		"name": "Night Sight", "words": "In Lor", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 1.0, 0.7), "flag": "night_sight", "secs": 600.0,
	},
	"reactive_armor": {
		"name": "Reactive Armor", "words": "Flam Sanct", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.6, 0.3), "flag": "reactive_armor", "secs": 60.0,
	},
	"weaken": {
		"name": "Weaken", "words": "Des Mani", "circle": 1, "mana": 4, "min": 0.1,
		"reagents": 2, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.6, 0.9), "mods": {"str": -10}, "secs": 60.0,
	},
	"agility": {
		"name": "Agility", "words": "Ex Uus", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 1.0, 0.8), "mods": {"dex": 10}, "secs": 120.0,
	},
	"cunning": {
		"name": "Cunning", "words": "Uus Wis", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.8, 1.0), "mods": {"int": 10}, "secs": 120.0,
	},
	"magic_trap": {
		"name": "Magic Trap", "words": "In Jux", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 3, "kind": "field", "min_dmg": 12.0, "max_dmg": 22.0,
		"color": Color(1.0, 0.4, 0.2), "field": "trap", "secs": 300.0,
	},
	"magic_untrap": {
		"name": "Magic Untrap", "words": "An Jux", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 2, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "trap",
	},
	"protection": {
		"name": "Protection", "words": "Uus Sanct", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.9, 1.0), "flag": "protection", "secs": 90.0,
	},
	"strength": {
		"name": "Strength", "words": "Uus Mani", "circle": 2, "mana": 6, "min": 0.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.7, 0.6), "mods": {"str": 10}, "secs": 120.0,
	},
	"bless": {
		"name": "Bless", "words": "Rel Sanct", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 0.95, 0.6), "mods": {"str": 10, "dex": 10, "int": 10}, "secs": 120.0,
	},
	"magic_lock": {
		"name": "Magic Lock", "words": "An Por", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 3, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"telekinesis": {
		"name": "Telekinesis", "words": "Ort Por Ylem", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"teleport": {
		"name": "Teleport", "words": "Rel Por", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.8, 1.0),
	},
	"unlock": {
		"name": "Unlock", "words": "Ex Por", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 1.0),
	},
	"wall_of_stone": {
		"name": "Wall of Stone", "words": "In Sanct Ylem", "circle": 3, "mana": 9, "min": 10.1,
		"reagents": 2, "kind": "field", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.6, 0.6), "field": "wall", "secs": 10.0,
	},
	"arch_cure": {
		"name": "Arch Cure", "words": "Vas An Nox", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 1.0, 0.6),
	},
	"arch_protection": {
		"name": "Arch Protection", "words": "Vas Uus Sanct", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 4, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.9, 1.0), "flag": "protection", "secs": 90.0,
	},
	"curse": {
		"name": "Curse", "words": "Des Sanct", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.5, 0.9), "mods": {"str": -10, "dex": -10, "int": -10}, "secs": 60.0,
	},
	"fire_field": {
		"name": "Fire Field", "words": "In Flam Grav", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "field", "min_dmg": 3.0, "max_dmg": 3.0,
		"color": Color(1.0, 0.45, 0.1), "field": "fire", "secs": 12.0,
	},
	"mana_drain": {
		"name": "Mana Drain", "words": "Ort Rel", "circle": 4, "mana": 11, "min": 24.1,
		"reagents": 3, "kind": "drain", "min_dmg": 10.0, "max_dmg": 20.0,
		"color": Color(0.4, 0.5, 1.0),
	},
	"blade_spirits": {
		"name": "Blade Spirits", "words": "In Jux Hur Ylem", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "summon", "min_dmg": 6.0, "max_dmg": 12.0,
		"color": Color(0.8, 0.8, 0.9), "summon": "BLADE_SPIRITS", "secs": 45.0,
	},
	"dispel_field": {
		"name": "Dispel Field", "words": "An Grav", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 2, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "any",
	},
	"incognito": {
		"name": "Incognito", "words": "Kal In Ex", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.7, 0.7), "flag": "incognito", "secs": 120.0,
	},
	"magic_reflection": {
		"name": "Magic Reflection", "words": "In Jux Sanct", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.9, 0.9, 1.0), "flag": "magic_reflection", "secs": 120.0,
	},
	"poison_field": {
		"name": "Poison Field", "words": "In Nox Grav", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "field", "min_dmg": 1.0, "max_dmg": 1.0,
		"color": Color(0.4, 1.0, 0.3), "field": "poison", "secs": 15.0,
	},
	"summon_creature": {
		"name": "Summon Creature", "words": "Kal Xen", "circle": 5, "mana": 14, "min": 38.1,
		"reagents": 3, "kind": "summon", "min_dmg": 5.0, "max_dmg": 10.0,
		"color": Color(0.6, 0.5, 0.3), "summon": "CREATURE", "secs": 60.0,
	},
	"dispel": {
		"name": "Dispel", "words": "An Ort", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 3, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "summon",
	},
	"invisibility": {
		"name": "Invisibility", "words": "An Lor Xen", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.8, 0.8, 0.8), "flag": "invisible", "secs": 15.0,
	},
	"mass_curse": {
		"name": "Mass Curse", "words": "Vas Des Sanct", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 4, "kind": "curse", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.6, 0.4, 0.8), "mods": {"str": -10, "dex": -10, "int": -10}, "secs": 60.0, "area": true,
	},
	"paralyze_field": {
		"name": "Paralyze Field", "words": "In Ex Grav", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 3, "kind": "field", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.85, 0.7, 1.0), "field": "paralyze", "secs": 15.0,
	},
	"reveal": {
		"name": "Reveal", "words": "Wis Quas", "circle": 6, "mana": 20, "min": 52.1,
		"reagents": 2, "kind": "util", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(1.0, 1.0, 0.8),
	},
	"chain_lightning": {
		"name": "Chain Lightning", "words": "Vas Ort Grav", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "area", "min_dmg": 16.0, "max_dmg": 26.0,
		"color": Color(0.6, 0.8, 1.0),
	},
	"energy_field": {
		"name": "Energy Field", "words": "In Sanct Grav", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "field", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.5, 0.6, 1.0), "field": "wall", "secs": 20.0,
	},
	"mana_vampire": {
		"name": "Mana Vampire", "words": "Ort Sanct", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "drain", "min_dmg": 20.0, "max_dmg": 35.0,
		"color": Color(0.3, 0.4, 1.0), "steal": true,
	},
	"mass_dispel": {
		"name": "Mass Dispel", "words": "Vas An Ort", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "dispel", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.7, 0.8, 1.0), "field": "all",
	},
	"meteor_swarm": {
		"name": "Meteor Swarm", "words": "Flam Kal Des Ylem", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 4, "kind": "area", "min_dmg": 18.0, "max_dmg": 28.0,
		"color": Color(1.0, 0.5, 0.2),
	},
	"polymorph": {
		"name": "Polymorph", "words": "Vas Ylem Rel", "circle": 7, "mana": 40, "min": 67.0,
		"reagents": 3, "kind": "buff", "min_dmg": 0.0, "max_dmg": 0.0,
		"color": Color(0.9, 0.6, 0.4), "mods": {"str": 20, "dex": 5}, "secs": 120.0, "flag": "polymorph",
	},
	"energy_vortex": {
		"name": "Energy Vortex", "words": "Vas Corp Por", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 14.0, "max_dmg": 24.0,
		"color": Color(0.5, 0.5, 1.0), "summon": "ENERGY_VORTEX", "secs": 60.0,
	},
	"summon_air": {
		"name": "Summon Air Elemental", "words": "Kal Vas Xen Hur", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 3, "kind": "summon", "min_dmg": 9.0, "max_dmg": 16.0,
		"color": Color(0.8, 0.9, 1.0), "summon": "AIR_ELEMENTAL", "secs": 90.0,
	},
	"summon_daemon": {
		"name": "Summon Daemon", "words": "Kal Vas Xen Corp", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 14.0, "max_dmg": 26.0,
		"color": Color(0.8, 0.2, 0.2), "summon": "DAEMON", "secs": 90.0,
	},
	"summon_fire": {
		"name": "Summon Fire Elemental", "words": "Kal Vas Xen Flam", "circle": 8, "mana": 50, "min": 81.0,
		"reagents": 4, "kind": "summon", "min_dmg": 11.0, "max_dmg": 19.0,
		"color": Color(1.0, 0.4, 0.1), "summon": "FIRE_ELEMENTAL", "secs": 90.0,
	},
	"summon_water": {
		"name": "Summon Water Elemental", "words": "Kal Vas Xen An Flam", "circle": 8, "mana": 50, "min": 81.0,
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
