class_name Story
## The main story: "The Shattered Sight". Long ago the Shard of Sight watched over the land, and
## while it shone no evil could hide. Malgrath the Shardbreaker broke it; three fragments went to
## his servants and the world went half blind. The hero gathers the fragments and faces him at the
## Broken Circle, the ring of standing stones in the heart of the land.
##
## Each step: a chapter title, the story told when it begins, what to do, and the reward.
## Objective kinds: "talk" (walk up to the named person), "shrine" (pray at any ankh shrine),
## "kill" (slay the named creature, inside "area" if given: Rect2i in tiles), "boss" (the story's
## enemy appears at the Broken Circle; slay it).

const SITE := Vector2i(66, 24)          # the Broken Circle

const STEPS := [
	{
		"title": "I. The Wanderer Wakes",
		"text": "You wake on the road with no memory of the night, only a cold ache behind your eyes, as if something you once saw has been taken away. In the town nearby, they say Father Corwin listens to strangers.",
		"goal": "Speak with Father Corwin in the main town (stand beside him).",
		"kind": "talk", "who": "Father Corwin", "gold": 30, "fame": 20,
	},
	{
		"title": "II. The Shattered Sight",
		"text": "\"You feel it too,\" Father Corwin says quietly. \"Since the Shard of Sight was broken, the land has gone half blind. The dead walk, orcs grow bold, and evil hides where once the Shard's light found it. The old ankhs still remember its light. Pray at one, and see what it shows you.\"",
		"goal": "Pray at an ankh shrine (they're marked with pale crosses on the minimap).",
		"kind": "shrine", "gold": 40, "fame": 30,
	},
	{
		"title": "III. The Warlord's Fragment",
		"text": "As you kneel, the ankh blazes and a vision fills your eyes: three shining splinters in three dark hands. The first lies in the orc fort far to the north-east, clutched by the ogre who rules it.",
		"goal": "Slay the Ogre of the orc fort, in the far north-east.",
		"kind": "kill", "target": "Ogre", "area": Rect2i(80, 1, 15, 11), "item": "shard_fragment_1", "gold": 150, "fame": 120,
	},
	{
		"title": "IV. The Graveyard Fragment",
		"text": "The ogre falls, and a sliver of light rolls from its fist into your hand: the first fragment, warm and humming. In its glow you see the second, cold and pale, in the graveyard of the south-east, where a lich keeps the restless dead.",
		"goal": "Destroy the Lich of the old graveyard, in the south-east.",
		"kind": "kill", "target": "Lich", "area": Rect2i(80, 26, 15, 16), "item": "shard_fragment_2", "gold": 250, "fame": 180,
	},
	{
		"title": "V. The King Beneath",
		"text": "The second fragment joins the first, and the two sing together. The third answers from deep below the earth: in the dungeon's lowest hall, the Bone King wears it in his crown.",
		"goal": "Bring down the Bone King, in the dungeon's deepest hall.",
		"kind": "kill", "target": "The Bone King", "item": "shard_fragment_3", "gold": 400, "fame": 250,
	},
	{
		"title": "VI. The Abbess",
		"text": "Three fragments, and the Shard is almost whole, but a dark seam still runs through it. Father Corwin cannot read it. \"Mother Isolde, the abbess of Southmoor, kept the old writings,\" he says. \"Go to her.\"",
		"goal": "Speak with Mother Isolde in Southmoor.",
		"kind": "talk", "who": "Mother Isolde", "gold": 60, "fame": 50,
	},
	{
		"title": "VII. The Shardbreaker",
		"text": "Mother Isolde turns the fragments in her hands. \"The seam is his mark. Malgrath, who broke the Shard, still lives in what he stole from it. With the fragments whole in your hands he cannot hide from you: he will come to the Broken Circle, the ring of stones in the heart of the land, to take them back. Be there first.\"",
		"goal": "Go to the Broken Circle in the heart of the land and defeat Malgrath the Shardbreaker.",
		"kind": "boss", "gold": 1500, "fame": 600,
	},
	{
		"title": "VIII. Sight Restored",
		"text": "Malgrath falls, and the dark seam burns out of the Shard. Light pours from your hands across the land: for a moment you see everything at once, every road and river, every hidden thing. Then the Shard settles, whole, and the ache behind your eyes is gone. Return to Father Corwin.",
		"goal": "Return to Father Corwin in the main town.",
		"kind": "talk", "who": "Father Corwin", "gold": 500, "fame": 300, "title_reward": "the Shardbearer",
	},
]
const EPILOGUE := "\"The Shard is whole, and so is the Sight,\" Father Corwin says, smiling for the first time. \"They will call you the Shardbearer now.\" The land is far from safe, but nothing evil can hide from it again. Your story goes on: the world is yours to wander."

## The final enemy: a lich lord, far stronger than any.
const BOSS := {
	"look": "lich", "danger": 10, "boss": true,
	"str": 140, "dex": 60, "int": 120, "wspeed": 32, "dmg_min": 10, "dmg_max": 20,
	"move": 2.4, "leash": 6, "aggro": 9.0, "respawn": 1.0e9, "reagents": 999, "scale": 1.7, "armor": 6.0,
	"loot": {"gold_min": 800, "gold_max": 1200, "reagents": 30, "drops": [["platemail", 0.5], ["heater_shield", 0.5]]},
	"skills": {
		Hero.Skill.SWORDSMANSHIP: 80.0, Hero.Skill.TACTICS: 80.0, Hero.Skill.MAGERY: 100.0,
		Hero.Skill.EVALUATING_INTELLECT: 90.0, Hero.Skill.MEDITATION: 90.0, Hero.Skill.RESISTING_SPELLS: 90.0,
	},
}
const BOSS_NAME := "Malgrath the Shardbreaker"
