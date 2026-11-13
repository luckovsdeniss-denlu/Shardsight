class_name Quests
## Quests from Captain Marcus in town, given in order and repeating. Walk up to him to take one
## and come back when it's done for the reward (gold, plus fame and karma).
## Types: kill (slay `count` of `target`), fetch (bring `count` of item `item`), escort (lead
## `escort` to the tile `to`; they follow you) and boss (slay the dungeon's master).

const GIVER := "Captain Marcus"

const LIST := [
	{"type": "kill", "target": "Rat", "count": 5, "reward": 60, "text": "Rats are into the grain stores. Slay 5 of them."},
	{"type": "fetch", "item": "wolf_pelt", "count": 3, "reward": 110, "text": "The tanner needs hides. Bring me 3 wolf pelts."},
	{"type": "kill", "target": "Wolf", "count": 2, "reward": 90, "text": "A wolf keeps taking our sheep. Kill 2 wolves."},
	{"type": "escort", "escort": "Tobin the Trader", "to": [49, 32], "place": "Southmoor", "reward": 240,
		"text": "Tobin the Trader must reach Southmoor alive. Lead him there; he will follow you."},
	{"type": "kill", "target": "Orc", "count": 3, "reward": 160, "text": "Orcs raid the roads. Bring down 3."},
	{"type": "fetch", "item": "ingot_iron", "count": 5, "reward": 180, "text": "The armoury is short of metal. Bring me 5 iron ingots."},
	{"type": "kill", "target": "Evil Mage", "count": 1, "reward": 200, "text": "An evil mage lurks by the southern rocks. End him."},
	{"type": "fetch", "item": "orc_ear", "count": 3, "reward": 170, "text": "Proof, or it didn't happen: bring me 3 orc ears."},
	{"type": "kill", "target": "Skeleton", "count": 4, "reward": 260, "text": "The dead walk in the dungeon by the great lake. Put 4 skeletons to rest."},
	{"type": "escort", "escort": "Sister Ada", "to": [36, 5], "place": "the outpost", "reward": 220,
		"text": "Sister Ada is needed at the outpost's healer. See her safely there."},
	{"type": "kill", "target": "Ogre", "count": 1, "reward": 350, "text": "An ogre guards the dungeon's middle hall. Fell it."},
	{"type": "kill", "target": "Lich", "count": 1, "reward": 600, "text": "A lich haunts the dungeon's upper hall. Destroy it."},
	{"type": "boss", "target": "The Bone King", "count": 1, "reward": 1500,
		"text": "The Bone King rules the deepest hall of the dungeon, raising the dead around him. Bring him down, and his blade is yours."},
]


static func kind(q: Dictionary) -> String:
	return String(q.get("type", "kill"))


## How far along a quest is (0..count) given the kills counted and what the hero carries.
static func progress(q: Dictionary, kills: int, bag: Dictionary) -> int:
	match kind(q):
		"fetch":
			return mini(int(bag.get(String(q["item"]), 0)), int(q["count"]))
		"escort":
			return 0
	return mini(kills, int(q.get("count", 1)))


static func goal(q: Dictionary) -> int:
	return int(q.get("count", 1))
