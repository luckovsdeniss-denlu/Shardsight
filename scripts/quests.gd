class_name Quests
## Kill quests from Captain Marcus in town, given in order and repeating. Walk up to him to take
## one and come back when it's done for the reward.

const GIVER := "Captain Marcus"

const LIST := [
	{"target": "Rat", "count": 5, "reward": 60, "text": "Rats are into the grain stores. Slay 5 of them."},
	{"target": "Wolf", "count": 2, "reward": 90, "text": "A wolf keeps taking our sheep. Kill it twice over: 2 wolves."},
	{"target": "Orc", "count": 3, "reward": 160, "text": "Orcs camp in the south. Bring down 3."},
	{"target": "Evil Mage", "count": 1, "reward": 200, "text": "An evil mage lurks by the southern rocks. End him."},
	{"target": "Skeleton", "count": 4, "reward": 260, "text": "The dead walk in the eastern dungeon. Put 4 skeletons to rest."},
	{"target": "Ogre", "count": 1, "reward": 350, "text": "An ogre guards the dungeon's middle hall. Fell it."},
	{"target": "Lich", "count": 1, "reward": 600, "text": "A lich rules the dungeon's deepest hall. Destroy it."},
]
