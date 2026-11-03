class_name Spells
## Magery spells. Circle, mana and minimum Magery follow the mechanics reference (all 8 circles;
## 7 and 8 are "about" figures there). Damage/heal ranges and reagent counts are tuning guesses.
## Kinds: attack (one target), heal (self), cure (self, removes poison), poison (one target),
## area (everything hostile around the caster),
## travel (Recall, Mark, Gate Travel: cast from Menu > Travel, never chosen by the AI).

const ORDER := [
	"magic_arrow", "heal", "harm", "cure", "fireball", "poison", "lightning", "greater_heal",
	"mind_blast", "energy_bolt", "explosion", "flamestrike", "earthquake",
	"recall", "mark", "gate_travel",
]
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
}
