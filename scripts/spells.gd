class_name Spells
## Magery spells. Circle, mana and minimum Magery follow the mechanics reference
## (circles 1-4 of 8). Damage/heal ranges and reagent counts are tuning guesses.

const ORDER := ["magic_arrow", "heal", "harm", "fireball", "lightning", "greater_heal"]

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
}
