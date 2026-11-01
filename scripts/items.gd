class_name Items
## Trophy items dropped by monsters (no use except selling). Gear ids from Gear also work as items.

const LIST := {
	"rat_tail": {"name": "Rat Tail", "value": 3},
	"wolf_pelt": {"name": "Wolf Pelt", "value": 8},
	"orc_ear": {"name": "Orc Ear", "value": 10},
	"mage_robe": {"name": "Mage Robe", "value": 20},
}


static func item_name(id: String) -> String:
	if Gear.LIST.has(id):
		return String(Gear.LIST[id]["name"])
	return String(LIST[id]["name"])


## What the merchant pays: full value for trophies, half for used gear.
static func value(id: String) -> int:
	if Gear.LIST.has(id):
		return maxi(1, int(Gear.LIST[id]["value"]) / 2)
	return int(LIST[id]["value"])
