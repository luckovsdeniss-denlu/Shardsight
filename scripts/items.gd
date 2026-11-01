class_name Items
## Trophy items dropped by monsters. They have no use except selling to the merchant.

const LIST := {
	"rat_tail": {"name": "Rat Tail", "value": 3},
	"wolf_pelt": {"name": "Wolf Pelt", "value": 8},
	"orc_ear": {"name": "Orc Ear", "value": 10},
	"mage_robe": {"name": "Mage Robe", "value": 20},
}


static func item_name(id: String) -> String:
	return String(LIST[id]["name"])


static func value(id: String) -> int:
	return int(LIST[id]["value"])
