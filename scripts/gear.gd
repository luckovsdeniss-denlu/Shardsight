class_name Gear
## Weapons and armor. Weapon speed spans the reference's range (halberd 25 ... kryss 58);
## the damage, rating, Strength and price numbers are tuning guesses.
## Metal armor wrecks Meditation (the classic reason mages stay in cloth).

const ORDER := [
	"dagger", "kryss", "longsword", "broadsword", "halberd",
	"leather_armor", "studded_armor", "chainmail", "platemail",
]

const LIST := {
	"dagger": {"name": "Dagger", "slot": "weapon", "speed": 55, "min": 2.0, "max": 6.0, "str": 10, "value": 15},
	"kryss": {"name": "Kryss", "slot": "weapon", "speed": 58, "min": 3.0, "max": 7.0, "str": 10, "value": 40},
	"longsword": {"name": "Longsword", "slot": "weapon", "speed": 35, "min": 5.0, "max": 13.0, "str": 25, "value": 55},
	"broadsword": {"name": "Broadsword", "slot": "weapon", "speed": 30, "min": 7.0, "max": 15.0, "str": 35, "value": 90},
	"halberd": {"name": "Halberd", "slot": "weapon", "speed": 25, "min": 8.0, "max": 18.0, "str": 50, "value": 160},
	"leather_armor": {"name": "Leather Armor", "slot": "armor", "rating": 2.0, "str": 10, "value": 25, "metal": false},
	"studded_armor": {"name": "Studded Armor", "slot": "armor", "rating": 3.0, "str": 25, "value": 60, "metal": false},
	"chainmail": {"name": "Chainmail", "slot": "armor", "rating": 5.0, "str": 35, "value": 110, "metal": true},
	"platemail": {"name": "Platemail", "slot": "armor", "rating": 7.0, "str": 60, "value": 260, "metal": true},
}


## Comparable only within a slot. Weapons: average damage times speed (about damage per second).
static func score(id: String) -> float:
	if id == "":
		return 0.0
	var g: Dictionary = LIST[id]
	if String(g["slot"]) == "weapon":
		return (float(g["min"]) + float(g["max"])) / 2.0 * float(g["speed"]) / 10.0
	return float(g["rating"])


static func is_metal(id: String) -> bool:
	return id != "" and bool(LIST[id].get("metal", false))
