class_name Frontier
extends Node3D
## The wider world beyond the main story: the dungeon's deeper levels, the biomes and their
## creatures, the caves, boats on the lakes, the tavern and townsfolk who keep a daily round,
## side quests told in dialogue with choices, bounty boards, cooking, the new brews and blade
## poisons, house decoration, the arena and the guild towers.
## One panel reaches all of it: Main Menu > Adventures, or the action button that appears at the
## bottom of the screen when you stand by something you can use. Progress is kept in
## Property.frontier (saved with the game).

# --- places --------------------------------------------------------------------------------
const TAVERN := Vector2i(53, 36)            # the Drunken Shard, in Southmoor (its bar)
const TAVERN_NAME := "the Drunken Shard"
const HEARTH := Vector2i(55, 35)            # the tavern's hearth: you can cook at it
const ARENA := Vector2i(89, 91)             # the arena ring, by Midmark in the middle of the land
const ARENA_RADIUS := 3.5
const STAIRS := Vector2i(14, 77)            # the stairs down, in the dungeon's deepest hall
const DUNGEON_DOOR := Vector2i(5, 72)      # where you arrive on a new level
const DEPTH_BOSS_AT := Vector2i(6, 69)
const BOARDS := [Vector2i(36, 11), Vector2i(113, 50), Vector2i(45, 34), Vector2i(109, 15), Vector2i(101, 107),
	Vector2i(12, 97), Vector2i(44, 109), Vector2i(85, 82), Vector2i(129, 51)]   # a bounty board in each town
const DOCKS := [
	{"name": "Westmere Landing", "tile": Vector2i(5, 15), "to": 1},
	{"name": "Eastmere Landing", "tile": Vector2i(13, 15), "to": 0},
	{"name": "Northlake Pier", "tile": Vector2i(66, 11), "to": 3},
	{"name": "Frostshore Pier", "tile": Vector2i(78, 11), "to": 2},
	{"name": "Fen Jetty", "tile": Vector2i(31, 39), "to": 5},
	{"name": "Reedbank Jetty", "tile": Vector2i(41, 39), "to": 4},
	{"name": "Tidewater Harbour", "tile": Vector2i(48, 55), "to": 7},      # the sea voyage
	{"name": "Isle Landing", "tile": Vector2i(48, 64), "to": 6},
	{"name": "Mirrormere West", "tile": Vector2i(110, 34), "to": 9},       # the lake of the eastern lands
	{"name": "Mirrormere East", "tile": Vector2i(126, 34), "to": 8},
	{"name": "Reedmere West", "tile": Vector2i(12, 116), "to": 11},        # the lake of the south-west
	{"name": "Reedmere East", "tile": Vector2i(28, 116), "to": 10},
]
const LAKE_DOCKS := 6                       # the first six are on the lakes
const ISLE_SHRINE := Vector2i(47, 66)
const BOAT_PRICE := 300
const FERRY_PRICE := 8
const POLE_PRICE := 15
const BOAT_SPEED := 2.2
const DAY := 480.0                         # one game day (Main.DAY_SECONDS)

# --- the dungeon's depths --------------------------------------------------------------------
const DEPTHS := [
	{"name": "The Upper Halls", "boss": "The Bone King", "tint": Color(1, 1, 1)},
	{"name": "The Bone Galleries", "boss": "Gravelord Ossian", "look": "skeleton", "tint": Color(0.75, 0.78, 0.95)},
	{"name": "The Weeping Crypts", "boss": "The Hollow Matron", "look": "lich", "tint": Color(0.6, 0.85, 0.65)},
	{"name": "The Ember Deep", "boss": "Ashen Colossus", "look": "ogre", "tint": Color(1.0, 0.6, 0.45)},
	{"name": "The Abyss", "boss": "Vorghast the Abyssal", "look": "daemon", "tint": Color(0.65, 0.45, 0.8)},
]

# --- townsfolk with a daily round ------------------------------------------------------------
## work: where they spend the day; tavern: the evening; home: the night ("" for those who never
## leave their post or camp).
const VILLAGERS := [
	{"name": "Farmer Tobin", "work": Vector2i(14, 9), "tavern": Vector2i(52, 37), "home": Vector2i(28, 10), "color": Color("b89a6a")},
	{"name": "Nell the Fisher", "work": Vector2i(5, 14), "tavern": Vector2i(54, 37), "home": Vector2i(35, 10), "color": Color("6a8ab8")},
	{"name": "Old Tam the Minstrel", "work": Vector2i(32, 9), "tavern": Vector2i(52, 35), "home": Vector2i(36, 12), "color": Color("a86ab8")},
	{"name": "Rosa the Barkeep", "work": Vector2i(53, 35), "color": Color("c86a5a")},
	{"name": "Kael the Arena Master", "work": Vector2i(93, 90), "color": Color("c8a040")},
	{"name": "Hunter Bram", "work": Vector2i(59, 10), "color": Color("8a7a6a")},
	{"name": "Wren the Herbwife", "work": Vector2i(28, 34), "color": Color("6aa86a")},
	{"name": "Zahir the Nomad", "work": Vector2i(72, 38), "color": Color("d8b878")},
	{"name": "Old Garret the Miner", "work": Vector2i(13, 42), "color": Color("8a8a7a")},
	{"name": "Smith Orla", "work": Vector2i(113, 13), "color": Color("b8643a")},
	{"name": "Warden Sela", "work": Vector2i(103, 106), "color": Color("4a7a5a")},
	{"name": "Bryn the Fisher", "work": Vector2i(109, 34), "home": Vector2i(106, 15), "color": Color("6a8ab8")},     # Mirrormere, home in Dawnport
	{"name": "Ada the Shepherd", "work": Vector2i(94, 96), "home": Vector2i(99, 104), "color": Color("b89a6a")},     # the fields by Highmoor
	{"name": "Old Cole the Hermit", "work": Vector2i(52, 118), "color": Color("8a7a6a")},                            # out on the southern plain
]

# --- side quests: dialogue with choices -----------------------------------------------------
## Each: giver, title, intro (the offer), choices (go: accept, decline or stay; say: the reply;
## advance: gold now; mult: share of the reward later; karma/fame), goal (kill a creature, or
## fetch items), the reward (gold, fame, karma, items), remind (while under way), done_text and
## turn_in choices (take: items handed over; mult; bonus gold; karma; fame; items; go "stay" to
## keep the quest open).
const SIDE_QUESTS := {
	"tobin_wolves": {
		"giver": "Farmer Tobin", "title": "Wolves at the Fold",
		"intro": "\"Stranger! Wolves have been at my sheep three nights running. I've a wife and four little ones, and the fold is half empty. Will you thin the pack?\"",
		"choices": [
			{"text": "\"I'll hunt them down.\"", "go": "accept", "say": "\"Bless you! Kill four of the beasts and the rest will keep away.\""},
			{"text": "\"Half the reward up front.\"", "go": "accept", "advance": 40, "mult": 0.5, "karma": -30, "say": "Tobin counts out forty coins with shaking hands. \"There. Now please, go.\""},
			{"text": "\"Not my problem.\"", "go": "decline", "say": "Tobin's face falls. \"Aye. Nobody's ever is.\""},
		],
		"goal": {"kind": "kill", "target": "Wolf", "count": 4},
		"gold": 120, "fame": 40, "karma": 80,
		"remind": "\"Four wolves, friend. The fold won't last another week.\"",
		"done_text": "\"You did it! Not a howl last night. Here, it's all I can spare.\"",
		"turn_in": [
			{"text": "Take the reward.", "say": "Tobin presses the coins into your hand."},
			{"text": "\"Keep it. Feed your children.\"", "mult": 0.0, "karma": 150, "fame": 60, "say": "Tobin weeps openly. Word of your kindness will travel."},
		],
	},
	"nell_pearl": {
		"giver": "Nell the Fisher", "title": "The Drowned Pearl",
		"intro": "\"My mother's pearl went into the lake when my boat turned over. The fish swallowed it long ago, I'd wager. If you ever pull a pearl from the water - any pearl - I'd pay what I can. It's all I have left of her.\"",
		"choices": [
			{"text": "\"I'll keep an eye out.\"", "go": "accept", "say": "\"Fish from a boat, out in the deep water. That's where the old ones lie.\""},
			{"text": "\"Pearls fetch a fine price at market.\"", "go": "stay", "say": "\"I know. I'd still pay. Please.\""},
			{"text": "\"I've no time for fishing.\"", "go": "decline", "say": "Nell nods and turns back to her nets."},
		],
		"goal": {"kind": "fetch", "item": "pearl", "count": 1},
		"gold": 90, "fame": 30, "karma": 60, "items": {"big_fish": 2},
		"remind": "\"Any pearl will do. The lakes give them up to a patient hand.\"",
		"done_text": "Nell's eyes fill as she sees the pearl. \"Is it... may I?\"",
		"turn_in": [
			{"text": "Give her the pearl.", "take": {"pearl": 1}, "say": "\"Thank you. Take these, they're the best of today's catch.\""},
			{"text": "\"Twice the price, or no pearl.\"", "take": {"pearl": 1}, "mult": 2.0, "karma": -80, "say": "Nell pays, but she will not look at you again."},
			{"text": "\"Not yet.\"", "go": "stay", "say": "\"I'll be here.\""},
		],
	},
	"bram_yeti": {
		"giver": "Hunter Bram", "title": "The White Death",
		"intro": "\"A yeti came down from the Frostmarch and took my brother on the ice. I've not the arm for it any more. Kill the beast, and I'll give you everything I've saved.\"",
		"choices": [
			{"text": "\"It will die. You have my word.\"", "go": "accept", "say": "\"It hunts the snowfields north of the lake. Go warm, and go armed.\""},
			{"text": "\"Why not hire the guilds?\"", "go": "stay", "say": "\"The guilds want ten times what I've got. You don't look like guild.\""},
			{"text": "\"Yetis are beyond me.\"", "go": "decline", "say": "\"Then don't go north. Not alone.\""},
		],
		"goal": {"kind": "kill", "target": "Yeti", "count": 1},
		"gold": 250, "fame": 120, "karma": 60,
		"remind": "\"The yeti still walks. I hear it some nights.\"",
		"done_text": "\"It's dead? Truly? Then my brother can rest.\"",
		"turn_in": [
			{"text": "Give him a frost pelt as proof.", "take": {"frost_pelt": 1}, "bonus": 100, "fame": 40, "say": "Bram runs his hand over the pelt. \"Aye. That's the one.\" He adds his last hundred coins."},
			{"text": "Take the reward.", "say": "\"Spend it well.\""},
		],
	},
	"wren_herbs": {
		"giver": "Wren the Herbwife", "title": "Herbs of the Fen",
		"intro": "\"The fever's in Southmoor again and my stores are bare. Swamp herbs grow where the leeches feed - nasty work. Bring me five and I'll pay in coin and brews.\"",
		"choices": [
			{"text": "\"Five herbs. Easy.\"", "go": "accept", "say": "\"Ha! Mind the leeches. They bite back.\""},
			{"text": "\"What brews?\"", "go": "stay", "say": "\"Agility, and a blade poison or two. Things a fighter finds useful.\""},
			{"text": "\"Not today.\"", "go": "decline", "say": "\"The fever won't wait, you know.\""},
		],
		"goal": {"kind": "fetch", "item": "swamp_herb", "count": 5},
		"gold": 60, "fame": 30, "karma": 70, "items": {"potion_agility": 1, "poison_lesser": 2},
		"remind": "\"Five swamp herbs, dear. The leeches of the Fen carry them.\"",
		"done_text": "\"Lovely, lovely. These will save lives.\"",
		"turn_in": [
			{"text": "Hand over the herbs.", "take": {"swamp_herb": 5}, "say": "Wren wraps the brews in cloth for you."},
			{"text": "\"Not yet.\"", "go": "stay", "say": "\"Don't dawdle.\""},
		],
	},
	"zahir_venom": {
		"giver": "Zahir the Nomad", "title": "Venom for the Antidote",
		"intro": "\"Peace, traveller. A scorpion stung my youngest. I can make the antidote, but it needs the venom of the beast itself - three stings' worth. Will you help a stranger?\"",
		"choices": [
			{"text": "\"I'll bring the venom.\"", "go": "accept", "say": "\"The sands will remember this. They nest among the rocks of the Wastes.\""},
			{"text": "\"For a price.\"", "go": "accept", "mult": 1.5, "karma": -40, "say": "Zahir's jaw tightens. \"Then for a price.\""},
			{"text": "\"I'm sorry.\"", "go": "decline", "say": "\"So am I.\""},
		],
		"goal": {"kind": "fetch", "item": "scorpion_venom", "count": 3},
		"gold": 160, "fame": 50, "karma": 120,
		"remind": "\"Three stings' worth. Please hurry.\"",
		"done_text": "Zahir takes the vials and is already grinding them as he speaks. \"The child will live.\"",
		"turn_in": [
			{"text": "Give him the venom.", "take": {"scorpion_venom": 3}, "say": "\"Take this, and my thanks.\""},
			{"text": "\"Not yet.\"", "go": "stay", "say": "Zahir looks at the sun and says nothing."},
		],
	},
	"garret_chief": {
		"giver": "Old Garret the Miner", "title": "The Goblin Warren",
		"intro": "\"Goblins took my mine, the little wretches - dug right into it and made a warren. Their chief sits on my best seam. Clear him out and the ore is yours to dig.\"",
		"choices": [
			{"text": "\"I'll deal with the chief.\"", "go": "accept", "say": "\"The way in is on its east side. Bring a pickaxe when you're done.\""},
			{"text": "\"What's in it for me?\"", "go": "stay", "say": "\"Gold, crystals, and every scrap of ore in there. The deeper veins run rich.\""},
			{"text": "\"Goblins are your trouble.\"", "go": "decline", "say": "Garret spits. \"Fine.\""},
		],
		"goal": {"kind": "kill", "target": "Goblin Chief", "count": 1},
		"gold": 300, "fame": 100, "karma": 40, "items": {"cave_crystal": 2},
		"remind": "\"Their chief still squats on my seam.\"",
		"done_text": "\"Ha! The warren's ours again. You've earned this.\"",
		"turn_in": [
			{"text": "Take the reward.", "say": "Garret hands over a heavy purse and two glittering crystals."},
			{"text": "\"I'd rather have your old map.\"", "mult": 0.5, "map": true, "say": "Garret grins and digs out a stained treasure map. \"Never had the legs for it.\""},
		],
	},
	"tam_song": {
		"giver": "Old Tam the Minstrel", "title": "A Song for the Road",
		"intro": "\"A song, friend? I'll write one about you - but a minstrel's throat runs dry. Bring old Tam a mug of ale from the tavern and you'll have a verse to make the crowds cheer.\"",
		"choices": [
			{"text": "\"One ale, coming up.\"", "go": "accept", "say": "\"Rosa at the Drunken Shard pours the best in Southmoor.\""},
			{"text": "\"I'm no hero for songs.\"", "go": "decline", "say": "\"They all say that.\""},
		],
		"goal": {"kind": "fetch", "item": "ale", "count": 1},
		"gold": 0, "fame": 80, "karma": 20, "song": true,
		"remind": "\"Ale first, then the song.\"",
		"done_text": "Tam drains the mug, tunes his lute, and sings of your deeds. People stop in the street to listen.",
		"turn_in": [
			{"text": "Hand him the ale.", "take": {"ale": 1}, "say": "The song stays with you: you feel quicker for it."},
		],
	},
	"orla_ember": {
		"giver": "Smith Orla", "title": "The Ember Lord",
		"intro": "\"See that glow to the east at night? The Ashlands. Something walks there made of fire - the Ember Lord - and its hounds come closer every week. Dawnport is timber and thatch. Put it out, and I'll pay you in the best stones I own.\"",
		"choices": [
			{"text": "\"I'll quench it.\"", "go": "accept", "say": "\"It keeps to the heart of the ash. Steel alone won't be enough; bring potions.\""},
			{"text": "\"How strong is it?\"", "go": "stay", "say": "\"Stronger than an ogre and twice as angry. Its imps throw fire.\""},
			{"text": "\"Not yet.\"", "go": "decline", "say": "\"Then pray for rain.\""},
		],
		"goal": {"kind": "kill", "target": "The Ember Lord", "count": 1},
		"gold": 500, "fame": 200, "karma": 100, "items": {"ruby": 2, "diamond": 1},
		"remind": "\"The east still glows at night.\"",
		"done_text": "\"The glow's gone! You've saved the town.\"",
		"turn_in": [
			{"text": "Take the reward.", "say": "Orla tips two rubies and a diamond into your palm."},
			{"text": "\"Keep the stones. Rebuild with them.\"", "mult": 0.0, "karma": 250, "fame": 150, "say": "Orla stares, then laughs. \"They'll name a street for you.\""},
		],
	},
	"sela_bears": {
		"giver": "Warden Sela", "title": "The Southern Wilds",
		"intro": "\"Highmoor is the last town before the wild south, and the wild is pushing back - bears on the roads, orcs in the hills. Thin out the bears, and the farms can breathe again.\"",
		"choices": [
			{"text": "\"I'll clear the roads.\"", "go": "accept", "say": "\"Five bears. They range all over the south - follow the roads out of Highmoor.\""},
			{"text": "\"Not now.\"", "go": "decline", "say": "\"The south will still be here.\""},
		],
		"goal": {"kind": "kill", "target": "Brown Bear", "count": 5},
		"gold": 260, "fame": 90, "karma": 60, "items": {"emerald": 1},
		"remind": "\"Five bears, friend. The farms are waiting.\"",
		"done_text": "\"The roads are quiet. Highmoor owes you.\"",
		"turn_in": [{"text": "Take the reward.", "say": "Sela hands over a purse and an emerald from the warden's chest."}],
	},
	"rosa_rats": {
		"giver": "Rosa the Barkeep", "title": "Rats in the Cellar",
		"intro": "\"The rats are in the grain again, and in the ale - don't ask. Kill six of the vermin anywhere you find them and drinks are on the house.\"",
		"choices": [
			{"text": "\"Six rats. Done.\"", "go": "accept", "say": "\"My hero. Of the cellar, at least.\""},
			{"text": "\"Rats? Beneath me.\"", "go": "decline", "say": "\"Then you'll be paying for your ale.\""},
		],
		"goal": {"kind": "kill", "target": "Rat", "count": 6},
		"gold": 60, "fame": 15, "karma": 30, "items": {"ale": 3, "hearty_stew": 1},
		"remind": "\"Six rats. They're everywhere, you can't miss them.\"",
		"done_text": "\"Six! The cellar's quiet. Here - on the house.\"",
		"turn_in": [
			{"text": "Take the reward.", "say": "Rosa slides three mugs and a bowl of stew across the bar."},
		],
	},
}

# --- bounties --------------------------------------------------------------------------------
const EPITHETS := ["Grimfang", "Old Scar", "Bloodmaw", "Ironhide", "Ashtooth", "Nightclaw", "Bonegnaw", "Redeye"]
## Creatures an elite bounty can be put on: [name, where it is spawned].
const ELITE_KINDS := [
	["Wolf", Rect2i(52, 10, 20, 10)], ["Orc", Rect2i(10, 16, 22, 6)], ["Brown Bear", Rect2i(60, 14, 15, 8)],
	["Frost Wolf", Rect2i(61, 1, 20, 7)], ["Sand Scorpion", Rect2i(70, 40, 12, 6)], ["Bog Troll", Rect2i(24, 41, 8, 5)],
	["Skeleton", Rect2i(96, 127, 10, 10)], ["Giant Spider", Rect2i(2, 20, 15, 5)],
	["Brown Bear", Rect2i(30, 85, 30, 20)], ["Orc", Rect2i(90, 110, 30, 20)], ["Giant Spider", Rect2i(10, 120, 25, 15)],
	["Wolf", Rect2i(110, 70, 25, 20)], ["Skeleton", Rect2i(60, 125, 30, 15)],
]
const HUNTS := [["Orc", 5, 140], ["Skeleton", 4, 180], ["Frost Wolf", 4, 170], ["Sand Scorpion", 4, 170],
	["Bog Leech", 6, 110], ["Goblin", 5, 150], ["Mummy", 3, 220], ["Zombie", 4, 160], ["Giant Spider", 4, 120]]

# --- cooking -------------------------------------------------------------------------------
const RECIPES := {
	"cooked_fish": {"min": 0.0, "mats": {"fish": 1}},
	"grilled_steak": {"min": 10.0, "mats": {"raw_meat": 1}},
	"fish_pie": {"min": 30.0, "mats": {"big_fish": 1, "bread": 1}},
	"hearty_stew": {"min": 45.0, "mats": {"raw_meat": 2, "swamp_herb": 1}},
	"frost_chowder": {"min": 70.0, "mats": {"fish": 2, "raw_meat": 1, "swamp_herb": 1}},
	"bread": {"min": 0.0, "mats": {"wheat": 2}},
	"vegetable_stew": {"min": 20.0, "mats": {"carrot": 2, "raw_meat": 1}},
	"pumpkin_pie": {"min": 40.0, "mats": {"pumpkin": 1, "wheat": 1}},
}
const RECIPE_ORDER := ["bread", "cooked_fish", "grilled_steak", "vegetable_stew", "fish_pie", "hearty_stew", "pumpkin_pie", "frost_chowder"]
## What eating does: health back, and a "well fed" spell of stats for a while.
const MEALS := {
	"cooked_fish": {"heal": 15, "secs": 600.0, "mods": {"int": 4}},
	"grilled_steak": {"heal": 20, "secs": 600.0, "mods": {"str": 5}},
	"fish_pie": {"heal": 35, "secs": 900.0, "mods": {"int": 6, "dex": 3}},
	"hearty_stew": {"heal": 45, "secs": 900.0, "mods": {"str": 6, "dex": 4}},
	"frost_chowder": {"heal": 60, "secs": 1200.0, "mods": {"str": 5, "dex": 5, "int": 5}},
	"ale": {"heal": 0, "secs": 300.0, "mods": {"str": 3, "dex": -2}},
	"vegetable_stew": {"heal": 30, "secs": 900.0, "mods": {"str": 4, "int": 3}},
	"pumpkin_pie": {"heal": 40, "secs": 1200.0, "mods": {"dex": 6, "int": 4}},
	"bread": {"heal": 10, "secs": 0.0, "mods": {}},
	"fish": {"heal": 10, "secs": 0.0, "mods": {}},
	"big_fish": {"heal": 20, "secs": 0.0, "mods": {}},
}
const BREWS := ["potion_strength", "potion_agility", "potion_invisibility", "poison_lesser", "poison_deadly"]

# --- house decoration ------------------------------------------------------------------------
const DECOR := {
	"rug": {"name": "Woven Rug", "price": 200, "comfort": 1},
	"table": {"name": "Oak Table", "price": 250, "comfort": 1},
	"chair": {"name": "Carved Chair", "price": 150, "comfort": 1},
	"plant": {"name": "Potted Fern", "price": 100, "comfort": 1},
	"lantern": {"name": "Brass Lantern", "price": 150, "comfort": 1},
	"weapon_rack": {"name": "Weapon Rack", "price": 350, "comfort": 1},
	"bed": {"name": "Feather Bed (rest)", "price": 800, "comfort": 3},
	"bookshelf": {"name": "Bookshelf (study)", "price": 700, "comfort": 2},
	"hearth": {"name": "Stone Hearth (cook at home)", "price": 900, "comfort": 3},
	"garden": {"name": "Herb Garden (herbs every day)", "price": 600, "comfort": 1},
	"trophy_bone_king": {"name": "Trophy: the Bone King's Crown", "price": 0, "comfort": 3, "trophy": "The Bone King"},
	"trophy_malgrath": {"name": "Trophy: Malgrath's Broken Staff", "price": 0, "comfort": 4, "trophy": "Malgrath the Shardbreaker"},
	"trophy_yeti": {"name": "Trophy: Yeti Hide", "price": 0, "comfort": 2, "trophy": "Yeti"},
	"trophy_chief": {"name": "Trophy: Goblin Chief's Skull", "price": 0, "comfort": 2, "trophy": "Goblin Chief"},
	"trophy_abyss": {"name": "Trophy: Horn of the Abyss", "price": 0, "comfort": 5, "trophy": "Vorghast the Abyssal"},
}
const DECOR_ORDER := ["rug", "table", "chair", "plant", "lantern", "weapon_rack", "bed", "bookshelf", "hearth", "garden",
	"trophy_bone_king", "trophy_malgrath", "trophy_yeti", "trophy_chief", "trophy_abyss"]

# --- the arena -------------------------------------------------------------------------------
const ARENA_TIERS := [
	{"name": "Novice", "foe": "Pit Fighter Dunn", "fee": 20, "purse": 70, "str": 35, "dex": 30, "lo": 3, "hi": 7, "skill": 45.0,
		"weapon": "short_sword", "wear": "leather_armor", "shield": "", "armor": 1.0, "danger": 2},
	{"name": "Adept", "foe": "Sela the Swift", "fee": 60, "purse": 220, "str": 55, "dex": 55, "lo": 5, "hi": 10, "skill": 65.0,
		"weapon": "katana", "wear": "studded_armor", "shield": "", "armor": 2.0, "danger": 4},
	{"name": "Veteran", "foe": "Brannoc Ironjaw", "fee": 150, "purse": 550, "str": 90, "dex": 50, "lo": 8, "hi": 15, "skill": 85.0,
		"weapon": "war_hammer", "wear": "chainmail", "shield": "heater_shield", "armor": 3.0, "danger": 6},
	{"name": "Champion", "foe": "Valka the Undefeated", "fee": 400, "purse": 1500, "str": 140, "dex": 70, "lo": 11, "hi": 20, "skill": 100.0,
		"weapon": "viking_sword", "wear": "platemail", "shield": "heater_shield", "armor": 4.5, "danger": 8},
]
const BETS := [0, 50, 200, 500]
const GLADIATORS := ["Grosk the Bull", "Ilsa Redhand", "Twin-Blade Oro", "Mother Vey", "Kettle the Ox", "Ser Aldous", "Quick Jory", "The Masked Brute"]

# --- guild towers ----------------------------------------------------------------------------
const TOWERS := [
	{"name": "Eastwatch Tower", "start": "oss"},
	{"name": "Southfold Tower", "start": "wos"},
	{"name": "Westmere Tower", "start": "shd"},
	{"name": "Southwatch Tower", "start": "wos"},
	{"name": "Eastmarch Tower", "start": "oss"},
	{"name": "Farhold Tower", "start": "shd"},
]
const CAPTURE_SECS := 20.0
const TOWER_RANGE := 3.5
const TOWER_INCOME := 150                   # gold a tower brings its guild each day (to your bank)
const GUILD_COLORS := {"oss": Color(0.82, 0.84, 0.92), "wos": Color(0.3, 0.7, 0.35), "shd": Color(0.45, 0.2, 0.55), "player": Color(0.95, 0.78, 0.25)}

const RUMOURS := [
	"\"They say there's a stair in the Bone King's hall that goes down and down. Nobody who went to the bottom came back the same.\"",
	"\"Old Garret's lost his mine to goblins. Poor fool won't stop talking about it.\"",
	"\"Fish from a boat, out in the deep water - that's where the pearls are.\"",
	"\"The guilds are fighting over the old towers again. Whoever holds them collects the tolls.\"",
	"\"A yeti in the Frostmarch, can you believe it? Hunter Bram's been asking for help.\"",
	"\"Kael pays good gold to anyone who lasts in his ring. Better gold if you bet on yourself.\"",
	"\"Wren the herbwife can't keep up with the fever. She needs swamp herbs.\"",
	"\"Zahir out in the Wastes - his child was stung. Scorpion venom's what he needs.\"",
	"\"Steak by the fire, a stew from the fen... a full belly makes a strong arm.\"",
	"\"A cave in the north, all ice and crystals. The frost giant there doesn't like visitors.\"",
	"\"There's a bounty board in every town. Elite beasts, outlaws - the guild of hunters pays well.\"",
]
const BANTER := [
	"%s laughs at something only they found funny.",
	"%s orders another round.",
	"%s tells the story of the wolf that got away.",
	"%s hums along with the fiddle.",
	"%s argues about the price of fish.",
]

var game
var world: World
var hero: Entity
var data: Dictionary
var depth := 1
var _depth_boss: Entity
var _out_of_dungeon := 0.0
var villagers: Array = []                  # [{"e": Entity, "def": Dictionary, "phase": String}]
var _route_acc := 0.0
var sail := {}                             # the boat trip under way (empty when ashore)
var _sail_node: Node3D
var bounty_target: Entity
var duel := {}
var bout := {}
var towers: Array = []                     # [{"node", "flag": StandardMaterial3D, "guild", "p"}]
var _tower_acc := 0.0
var _raid_in := 200.0
var raids: Array = []                      # [{"members": [Entity], "tower": int, "left": float}]
var _snow: CPUParticles3D
var _biome := ""
var _cave := -1
var _env_acc := 0.0
var _on_isle := false
var _banter_acc := 0.0
var _decor_node: Node3D
var _decor_key := ""
var _act_acc := 0.0
var _act := {}
var _hearth_fire: Node3D

# UI
var panel: Control
var box: VBoxContainer
var act_button: Button
var page := "hub"
var talk_with := ""                        # the villager being talked to
var talk_text := ""                        # what was last said in the dialogue
var dock_i := 0
var tower_i := 0
var _arena_bet := 0


func setup(p_game, layer: CanvasLayer) -> void:
	game = p_game
	world = game.world
	hero = game.hero
	data = game.property.frontier
	for k in ["sq", "towers"]:
		if not data.has(k) or not (data[k] is Dictionary):
			data[k] = {}
	for k in ["decor", "board"]:
		if not data.has(k) or not (data[k] is Array):
			data[k] = []
	if not data.has("bounty") or not (data["bounty"] is Dictionary):
		data["bounty"] = {}
	game.add_child(self)
	_spawn_wildlife()
	_spawn_villagers()
	_build_docks()
	_build_tavern()
	_build_arena()
	_build_boards()
	_build_church()
	_build_cemetery()
	_build_stairs()
	_build_towers()
	_build_snow()
	_build_ui(layer)
	if not data["bounty"].is_empty() and String(data["bounty"].get("kind", "")) == "elite":
		_spawn_elite(data["bounty"])          # the elite you were hunting is still out there


# --- helpers ---------------------------------------------------------------------------------

func _i(key: String, fallback := 0) -> int:
	return int(data.get(key, fallback))


## An open, walkable tile at or near `t` (outside the towns).
func _spot(t: Vector2i) -> Vector2i:
	if not world.is_blocked(t):
		return t
	var rng := RandomNumberGenerator.new()
	rng.seed = t.x * 97 + t.y
	return world.open_tile_in(Rect2i(t - Vector2i(2, 2), Vector2i(5, 5)), rng)


func _near(t: Vector2i, r: float) -> bool:
	var c := world.tile_center(t)
	return Vector2(c.x - hero.position.x, c.z - hero.position.z).length() <= r


func _has(item: String, n := 1) -> bool:
	return int(hero.inventory.get(item, 0)) >= n


func _give(item: String, n := 1) -> void:
	hero.inventory[item] = int(hero.inventory.get(item, 0)) + n


func _take(item: String, n := 1) -> void:
	Crafting.take_mats(hero.inventory, {item: n}, 1.0)


func _pay(n: int) -> bool:
	if hero.gold < n:
		game.log_event("You need %d gold for that." % n)
		return false
	hero.gold -= n
	return true


func _mesh(parts: Array, at: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Art.merge(parts)
	mi.material_override = Art.vc_mat()
	if parent != null:
		parent.add_child(mi)
	else:
		add_child(mi)
	mi.position = at
	return mi


func _killed(creature_name: String) -> bool:
	return int(game.property.stats_counts.get("hero_killed_" + creature_name, 0)) > 0


# --- the wild: biome creatures and cave dwellers ---------------------------------------------

func _spawn_wildlife() -> void:
	var r := func(cfg: Dictionary, look: String, sc: float, extra: Dictionary) -> Dictionary:
		var c := cfg.duplicate(true)
		c["look"] = look
		c["scale"] = sc
		c.merge(extra, true)
		return c
	var list := [
		["Frost Wolf", Bestiary.FROST_WOLF, Color("c8d8e8"), [Vector2i(64, 4), Vector2i(70, 5), Vector2i(75, 3), Vector2i(80, 7)]],
		["Yeti", Bestiary.YETI, Color("e8eef4"), [Vector2i(78, 5)]],
		["Sand Scorpion", Bestiary.SAND_SCORPION, Color("b08a40"), [Vector2i(58, 45), Vector2i(72, 42), Vector2i(80, 44), Vector2i(90, 45)]],
		["Mummy", Bestiary.MUMMY, Color("c8b890"), [Vector2i(76, 40), Vector2i(88, 44)]],
		["Bog Leech", Bestiary.BOG_LEECH, Color("4a3a2a"), [Vector2i(28, 37), Vector2i(36, 44), Vector2i(26, 42), Vector2i(41, 35)]],
		["Bog Troll", Bestiary.BOG_TROLL, Color("4a6a3a"), [Vector2i(30, 44)]],
		# the caves
		["Cave Spider", Bestiary.CAVE_SPIDER, Color("3a3a4a"), [Vector2i(54, 5), Vector2i(58, 7)]],
		["Frost Giant", r.call(Bestiary.CAVE_CHIEF, "ogre", 1.8, {}), Color("a8c8e8"), [Vector2i(56, 6)]],
		["Sand Scorpion", Bestiary.SAND_SCORPION, Color("b08a40"), [Vector2i(62, 40), Vector2i(66, 42)]],
		["Scorpion Queen", r.call(Bestiary.CAVE_CHIEF, "scorpion", 1.6, {"poison": [3, 0.25]}), Color("d0a030"), [Vector2i(64, 41)]],
		["Goblin", Bestiary.GOBLIN, Color("6a8a3a"), [Vector2i(5, 41), Vector2i(8, 43), Vector2i(9, 41)]],
		["Goblin Chief", r.call(Bestiary.CAVE_CHIEF, "goblin", 1.5, {}), Color("8aa83a"), [Vector2i(6, 42)]],
		# the eastern lands and the Ashlands
		["Ash Hound", r.call(Bestiary.FROST_WOLF, "wolf", 1.0, {"str": 50, "danger": 4,
			"loot": {"gold_min": 15, "gold_max": 30, "drops": [["raw_meat", 0.5], ["ruby", 0.03]]}}), Color("6a3a2a"),
			[Vector2i(127, 10), Vector2i(132, 12), Vector2i(136, 13), Vector2i(134, 8)]],
		["Cinder Imp", r.call(Bestiary.EVIL_MAGE, "daemon", 0.65, {"danger": 5, "int": 55,
			"loot": {"gold_min": 30, "gold_max": 60, "reagents": 6, "drops": [["cave_crystal", 0.15], ["ruby", 0.06]]}}), Color("c8502a"),
			[Vector2i(130, 4), Vector2i(139, 8)]],
		["The Ember Lord", r.call(Bestiary.CAVE_CHIEF, "fire_elemental", 1.7, {"str": 160, "danger": 9, "armor": 4.5,
			"loot": {"gold_min": 500, "gold_max": 900, "reagents": 20, "drops": [["ruby", 1.0], ["ruby", 0.6], ["diamond", 0.4], ["cave_crystal", 1.0]]}}),
			Color("ff7a2a"), [Vector2i(137, 4)]],
		["Wolf", Bestiary.WOLF, Color("c0392b"), [Vector2i(100, 20), Vector2i(120, 22)]],
		["Brown Bear", Bestiary.BROWN_BEAR, Color("6b4a2a"), [Vector2i(135, 25), Vector2i(130, 40)]],
		["Orc", Bestiary.ORC, Color("c0392b"), [Vector2i(140, 30), Vector2i(138, 44), Vector2i(98, 4)]],
		["Hind", Bestiary.HIND, Color("b08a5a"), [Vector2i(102, 30), Vector2i(105, 40)]],
		["Horse", Bestiary.HORSE, Color("7a5232"), [Vector2i(118, 26), Vector2i(100, 36)]],
		# the south and the far east: the Whitepeaks, the Dunes of Kesh, the Reedmarsh, the Cinderfields
		["Frost Wolf", Bestiary.FROST_WOLF, Color("c8d8e8"), [Vector2i(122, 76), Vector2i(136, 78), Vector2i(124, 90)]],
		["Yeti", Bestiary.YETI, Color("e8eef4"), [Vector2i(138, 90)]],
		["Cave Spider", Bestiary.CAVE_SPIDER, Color("3a3a4a"), [Vector2i(130, 84), Vector2i(134, 86)]],
		["Icejaw", r.call(Bestiary.CAVE_CHIEF, "yeti", 1.6, {}), Color("b8d8f0"), [Vector2i(132, 85)]],
		["Sand Scorpion", Bestiary.SAND_SCORPION, Color("b08a40"), [Vector2i(114, 114), Vector2i(120, 130), Vector2i(138, 128)]],
		["Mummy", Bestiary.MUMMY, Color("c8b890"), [Vector2i(116, 124), Vector2i(128, 119), Vector2i(132, 121)]],
		["The Dune Pharaoh", r.call(Bestiary.CAVE_CHIEF, "mummy", 1.6, {"poison": [3, 0.2]}), Color("e0c060"), [Vector2i(130, 120)]],
		["Bog Leech", Bestiary.BOG_LEECH, Color("4a3a2a"), [Vector2i(6, 108), Vector2i(34, 110), Vector2i(10, 122), Vector2i(32, 122)]],
		["Bog Troll", Bestiary.BOG_TROLL, Color("4a6a3a"), [Vector2i(22, 124)]],
		["Ash Hound", r.call(Bestiary.FROST_WOLF, "wolf", 1.0, {"str": 50, "danger": 4,
			"loot": {"gold_min": 15, "gold_max": 30, "drops": [["raw_meat", 0.5], ["ruby", 0.03]]}}), Color("6a3a2a"),
			[Vector2i(44, 128), Vector2i(56, 134), Vector2i(64, 140)]],
		["Cinder Imp", r.call(Bestiary.EVIL_MAGE, "daemon", 0.65, {"danger": 5, "int": 55,
			"loot": {"gold_min": 30, "gold_max": 60, "reagents": 6, "drops": [["cave_crystal", 0.15], ["ruby", 0.06]]}}), Color("c8502a"),
			[Vector2i(50, 138)]],
		["Skeleton", Bestiary.SKELETON, Color("d8d2c0"), [Vector2i(64, 94), Vector2i(68, 96)]],
		["Skeleton Archer", Bestiary.SKELETON_ARCHER, Color("d8d2c0"), [Vector2i(65, 95)]],
		["The Bone Warden", r.call(Bestiary.CAVE_CHIEF, "lich", 1.5, {}), Color("8a7aa8"), [Vector2i(67, 94)]],
		# the Isle of Tides
		["Giant Crab", r.call(Bestiary.SAND_SCORPION, "scorpion", 1.25, {"poison": [], "armor": 3.5, "str": 55,
			"loot": {"gold_min": 20, "gold_max": 45, "drops": [["pearl", 0.2], ["raw_meat", 0.6]]}}), Color("c05a3a"),
			[Vector2i(40, 67), Vector2i(38, 68), Vector2i(50, 70), Vector2i(40, 70)]],
		["Drowned Sailor", r.call(Bestiary.MUMMY, "zombie", 1.05, {"loot": {"gold_min": 50, "gold_max": 110,
			"drops": [["pearl", 0.25], ["scimitar", 0.15], ["sapphire", 0.06]]}}), Color("5a8a8a"), [Vector2i(46, 68), Vector2i(50, 66)]],
		["The Drowned King", r.call(Bestiary.CAVE_CHIEF, "lich", 1.6, {"str": 150, "danger": 8, "reagents": 999, "int": 90,
			"loot": {"gold_min": 400, "gold_max": 800, "reagents": 20, "drops": [["diamond", 0.7], ["sapphire", 1.0], ["pearl", 1.0], ["pearl", 0.6], ["platemail", 0.3]]},
			"skills": {Hero.Skill.SWORDSMANSHIP: 80.0, Hero.Skill.TACTICS: 80.0, Hero.Skill.MAGERY: 85.0, Hero.Skill.EVALUATING_INTELLECT: 70.0,
				Hero.Skill.MEDITATION: 70.0, Hero.Skill.RESISTING_SPELLS: 60.0}}), Color("3a6a8a"), [Vector2i(56, 68)]],
	]
	for row in list:
		for t in row[3]:
			game._spawn(Entity.Kind.MONSTER, String(row[0]), row[1], row[2], t if world.on_island(t) else _spot(t))
	# an ankh on the isle (the dead there need not wait for a ship)
	for st in [ISLE_SHRINE]:
		_add_ankh(world.tile_center(_spot(st) if not world.on_island(st) else st))


func _add_ankh(sp: Vector3) -> void:
	game.shrines.append(sp)
	var ankh := _mesh([[Art.box(0.12, 0.9, 0.12), Art.at(0, 0.55, 0), Color(0.8, 0.9, 1.0)], [Art.box(0.5, 0.12, 0.12), Art.at(0, 0.75, 0), Color(0.8, 0.9, 1.0)],
		[Art.ring_mesh(0.1, 0.2), Art.at(0, 1.15, 0, Vector3(PI / 2.0, 0, 0)), Color(0.8, 0.9, 1.0)], [Art.box(0.6, 0.1, 0.6), Art.at(0, 0.05, 0), Color(0.5, 0.52, 0.56)]], sp)
	var al := OmniLight3D.new()
	al.light_color = Color(0.6, 0.8, 1.0)
	al.omni_range = 3.5
	al.position = Vector3(0, 1.2, 0)
	ankh.add_child(al)


# --- townsfolk and their daily round ---------------------------------------------------------

func _spawn_villagers() -> void:
	for d in VILLAGERS:
		var e: Entity = game._spawn(Entity.Kind.NPC, String(d["name"]), Bestiary.VILLAGER, d["color"], d["work"])
		villagers.append({"e": e, "def": d, "phase": "work"})


## Where a villager should be now: at work by day, at the tavern in the evening, home at night.
func _phase_now() -> String:
	var t: float = game.day_time
	if t >= 0.25 and t < 0.72:
		return "work"
	if t >= 0.72 and t < 0.92:
		return "tavern"
	return "home"


func _routines(delta: float) -> void:
	_route_acc += delta
	if _route_acc < 2.0:
		return
	_route_acc = 0.0
	var phase := _phase_now()
	for v in villagers:
		var e: Entity = v["e"]
		var d: Dictionary = v["def"]
		var want := "work"
		if d.has(phase):
			want = phase
		var spot: Vector2i = d[want]
		var dest := world.tile_center(spot)
		if String(v["phase"]) != want:
			v["phase"] = want
			e.home = dest
			e.go_to(dest)
		elif e.path.is_empty() and Vector2(e.position.x - dest.x, e.position.z - dest.z).length() > 3.0:
			e.go_to(dest)                     # still on the way (or wandered off)
		if want == "home" and e._near and randf() < 0.15:
			e._pop("Zzz", Color(0.7, 0.8, 1.0))
	# evening at the tavern: the regulars talk
	if phase == "tavern" and _near(TAVERN, 7.0):
		_banter_acc += 2.0
		if _banter_acc >= 16.0:
			_banter_acc = 0.0
			var here: Array[String] = []
			for v in villagers:
				var e2: Entity = v["e"]
				if String(v["phase"]) == "tavern" and e2.position.distance_to(world.tile_center(TAVERN)) < 6.0:
					here.append(e2.display_name)
			if not here.is_empty():
				game.world_event(String(BANTER[randi() % BANTER.size()]) % here[randi() % here.size()])


func villager(n: String) -> Entity:
	for v in villagers:
		if (v["e"] as Entity).display_name == n:
			return v["e"]
	return null


# --- the tavern --------------------------------------------------------------------------------

func _build_tavern() -> void:
	var c := world.tile_center(TAVERN)
	var wood := Color(0.42, 0.27, 0.14)
	var dark := Color(0.28, 0.18, 0.1)
	# the bar counter, with mugs and barrels behind it
	_mesh([[Art.box(2.6, 0.9, 0.45), Art.at(0, 0.45, 0), wood], [Art.box(2.7, 0.08, 0.55), Art.at(0, 0.92, 0), dark],
		[Art.cone(0.06, 0.14, 0.06, 6), Art.at(-0.6, 1.03, 0), Color(0.75, 0.65, 0.4)],
		[Art.cone(0.06, 0.14, 0.06, 6), Art.at(0.4, 1.03, 0.05), Color(0.75, 0.65, 0.4)],
		[Art.cone(0.3, 0.7, 0.3, 8), Art.at(-1.0, 0.35, -0.75), wood], [Art.cone(0.3, 0.7, 0.3, 8), Art.at(1.0, 0.35, -0.75), wood]],
		c + Vector3(0, 0, 0.45))
	# tables and stools
	for p in [Vector3(-1.6, 0, 1.6), Vector3(1.4, 0, 1.8), Vector3(-0.1, 0, 2.9)]:
		var parts := [[Art.cone(0.45, 0.06, 0.45, 10), Art.at(0, 0.62, 0), wood], [Art.cone(0.08, 0.6, 0.08, 6), Art.at(0, 0.3, 0), dark]]
		for a in range(3):
			var ang := TAU * a / 3.0
			parts.append([Art.cone(0.16, 0.4, 0.16, 8), Art.at(cos(ang) * 0.7, 0.2, sin(ang) * 0.7), dark])
		_mesh(parts, c + p)
	# a hanging sign on a post
	_mesh([[Art.box(0.1, 2.2, 0.1), Art.at(0, 1.1, 0), dark], [Art.box(0.9, 0.08, 0.08), Art.at(0.4, 2.1, 0), dark],
		[Art.box(0.7, 0.45, 0.06), Art.at(0.5, 1.75, 0), Color(0.6, 0.35, 0.2)], [Art.ball(0.12), Art.at(0.5, 1.75, -0.05), Color(0.6, 0.85, 1.0)]],
		c + Vector3(-2.3, 0, -0.8))
	# the hearth
	var h := world.tile_center(HEARTH)
	_mesh([[Art.box(1.0, 0.5, 0.6), Art.at(0, 0.25, 0), Color(0.45, 0.43, 0.42)], [Art.box(0.6, 0.12, 0.4), Art.at(0, 0.55, 0), Color(0.2, 0.15, 0.12)]], h)
	_hearth_fire = Node3D.new()
	add_child(_hearth_fire)
	_hearth_fire.position = h + Vector3(0, 0.6, 0)
	var fire := Fx.flame(0.3, 18, 0.6)
	_hearth_fire.add_child(fire)
	fire.add_to_group("view_fx")
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.3)
	light.omni_range = 6.0
	light.position.y = 0.6
	_hearth_fire.add_child(light)


func _at_tavern() -> bool:
	return _near(TAVERN, 4.5)


func _page_tavern() -> void:
	_h("%s, Southmoor" % TAVERN_NAME.capitalize())
	var rosa := villager("Rosa the Barkeep")
	var present: Array[String] = []
	for v in villagers:
		var e: Entity = v["e"]
		if e != rosa and e.position.distance_to(world.tile_center(TAVERN)) < 6.0:
			present.append(e.display_name)
	_t("A low room of smoke, song and spilled ale. Rosa keeps the bar. " + \
		("In tonight: %s." % ", ".join(present) if not present.is_empty() else "It is quiet; the regulars come in the evening."))
	if not _at_tavern():
		_t("You are not at the tavern.")
		_b("Walk to the tavern", _walk_to.bind(TAVERN))
		return
	_b("Mug of ale (4 gold)", _tavern_buy.bind("ale", 4))
	_b("Hot meal (12 gold): heals, well fed", _tavern_meal)
	_b("Rent a room (25 gold): sleep till morning", _tavern_room)
	_b("Listen for rumours (2 gold)", _tavern_rumour)
	_b("Play dice (10 gold)", _tavern_dice)
	_b("Cook at the hearth", _open.bind("cook"))


func _tavern_buy(item: String, price: int) -> void:
	if _pay(price):
		_give(item)
		game.log_event("Rosa pours you a %s." % Items.item_name(item).to_lower())
	_refresh()


func _tavern_meal() -> void:
	if _pay(12):
		hero.hp = float(hero.stats.max_hp())
		hero.stamina = float(hero.stats.max_stamina())
		hero.add_effect("well_fed", {"secs": 600.0, "mods": {"str": 3, "dex": 3, "int": 3}, "name": "Well fed", "color": Color(1.0, 0.85, 0.4)})
		game.log_event("A bowl of Rosa's stew and a heel of bread. You feel ready for anything.")
		game.count("food_eaten")
	_refresh()


func _tavern_room() -> void:
	if _pay(25):
		hero.hp = float(hero.stats.max_hp())
		hero.mana = float(hero.stats.max_mana())
		hero.stamina = float(hero.stats.max_stamina())
		if game.is_night():
			game.day_time = 0.27
		hero.add_effect("rested", {"secs": 900.0, "mods": {"int": 3, "dex": 3}, "name": "Rested", "color": Color(0.7, 0.9, 1.0)})
		game.log_event("You sleep in a soft bed upstairs and wake rested.")
	_refresh()


func _tavern_rumour() -> void:
	if _pay(2):
		game.log_event("You overhear: " + String(RUMOURS[randi() % RUMOURS.size()]))
		if randf() < 0.06:
			var m: String = game.make_treasure_map()
			_give(m)
			game.log_event("A drunk sells you an old treasure map for a song. (Bag > Read)")
	_refresh()


func _tavern_dice() -> void:
	if _pay(10):
		var mine := randi_range(1, 6) + randi_range(1, 6)
		var theirs := randi_range(1, 6) + randi_range(1, 6)
		if mine > theirs:
			hero.gold += 20
			game.log_event("Dice: you roll %d against %d. You win 20 gold!" % [mine, theirs])
		elif mine == theirs:
			hero.gold += 10
			game.log_event("Dice: %d each. Your stake comes back." % mine)
		else:
			game.log_event("Dice: you roll %d against %d. You lose." % [mine, theirs])
	_refresh()


# --- side quests ---------------------------------------------------------------------------

func _sq(id: String) -> Dictionary:
	var all: Dictionary = data["sq"]
	if not all.has(id) or not (all[id] is Dictionary):
		all[id] = {"state": "", "kills": 0, "mult": 1.0}
	return all[id]


func _quests_of(giver: String) -> Array[String]:
	var out: Array[String] = []
	for id in SIDE_QUESTS:
		if String(SIDE_QUESTS[id]["giver"]) == giver:
			out.append(String(id))
	return out


## The quest a villager has for you now (the first not yet finished), or "".
func _quest_now(giver: String) -> String:
	for id in _quests_of(giver):
		if String(_sq(id)["state"]) != "done":
			return id
	return ""


func _goal_done(id: String) -> bool:
	var q: Dictionary = SIDE_QUESTS[id]
	var g: Dictionary = q["goal"]
	if String(g["kind"]) == "kill":
		return int(_sq(id)["kills"]) >= int(g["count"])
	return _has(String(g["item"]), int(g["count"]))


func _goal_text(id: String) -> String:
	var g: Dictionary = SIDE_QUESTS[id]["goal"]
	if String(g["kind"]) == "kill":
		return "Slay %s: %d/%d" % [g["target"], mini(int(_sq(id)["kills"]), int(g["count"])), int(g["count"])]
	return "Bring %s: %d/%d" % [Items.item_name(String(g["item"])), mini(int(hero.inventory.get(String(g["item"]), 0)), int(g["count"])), int(g["count"])]


## A mark for the action button: ! a new quest, ? one ready to hand in.
func _talk_mark(giver: String) -> String:
	var id := _quest_now(giver)
	if id == "":
		return ""
	var st := String(_sq(id)["state"])
	if st == "active":
		return " (?)" if _goal_done(id) else ""
	return " (!)"


func _page_talk() -> void:
	var e := villager(talk_with)
	_h(talk_with)
	if e != null and e.position.distance_to(hero.position) > 4.0:
		_t("%s is not here. %s" % [talk_with, "They're at the tavern this evening." if String(_vphase(talk_with)) == "tavern" else ""])
		_b("Walk to %s" % talk_with, _walk_to_villager.bind(talk_with))
		return
	if talk_text != "":
		_t(talk_text)
		talk_text = ""
		_b("Continue", _refresh)
		return
	match talk_with:
		"Rosa the Barkeep":
			_b("The tavern", _open.bind("tavern"))
		"Kael the Arena Master":
			_b("The arena", _open.bind("arena"))
	var id := _quest_now(talk_with)
	if id == "":
		_t("\"Good to see you again, friend. Thanks to you, things are better round here.\"" if not _quests_of(talk_with).is_empty() \
			else "\"%s\"" % ["Busy day.", "Mind how you go.", "Fine weather for it, eh?"][randi() % 3])
		return
	var q: Dictionary = SIDE_QUESTS[id]
	var st: Dictionary = _sq(id)
	_small_text(String(q["title"]))
	if String(st["state"]) == "active":
		if _goal_done(id):
			_t(String(q["done_text"]))
			for i in range(q["turn_in"].size()):
				var ch: Dictionary = q["turn_in"][i]
				var ok := true
				var take: Dictionary = ch.get("take", {})
				for item in take:
					ok = ok and _has(String(item), int(take[item]))
				_b(String(ch["text"]), _turn_in.bind(id, i), ok)
		else:
			_t(String(q["remind"]))
			_small_text(_goal_text(id))
			_b("Abandon this task", _abandon.bind(id))
		return
	_t(String(q["intro"]))
	for i in range(q["choices"].size()):
		_b(String(q["choices"][i]["text"]), _choose.bind(id, i))


func _vphase(n: String) -> String:
	for v in villagers:
		if (v["e"] as Entity).display_name == n:
			return String(v["phase"])
	return ""


func _choose(id: String, i: int) -> void:
	var q: Dictionary = SIDE_QUESTS[id]
	var ch: Dictionary = q["choices"][i]
	var st: Dictionary = _sq(id)
	match String(ch.get("go", "stay")):
		"accept":
			st["state"] = "active"
			st["kills"] = 0
			st["mult"] = float(ch.get("mult", 1.0))
			game.log_event("New task: %s (%s)." % [q["title"], talk_with])
		"decline":
			st["state"] = "declined"
	if int(ch.get("advance", 0)) > 0:
		hero.gold += int(ch["advance"])
	if int(ch.get("karma", 0)) != 0:
		hero.add_karma(int(ch["karma"]))
	talk_text = String(ch.get("say", ""))
	_refresh()


func _abandon(id: String) -> void:
	_sq(id)["state"] = "declined"
	talk_text = "\"Oh. Well, if you change your mind...\""
	_refresh()


func _turn_in(id: String, i: int) -> void:
	var q: Dictionary = SIDE_QUESTS[id]
	var ch: Dictionary = q["turn_in"][i]
	var st: Dictionary = _sq(id)
	talk_text = String(ch.get("say", ""))
	if String(ch.get("go", "")) == "stay":
		_refresh()
		return
	var take: Dictionary = ch.get("take", {})
	for item in take:
		_take(String(item), int(take[item]))
	var gold := roundi(float(q["gold"]) * float(st["mult"]) * float(ch.get("mult", 1.0))) + int(ch.get("bonus", 0))
	hero.gold += gold
	hero.add_fame(int(q["fame"]) + int(ch.get("fame", 0)))
	hero.add_karma(int(q["karma"]) + int(ch.get("karma", 0)))
	var items: Dictionary = q.get("items", {})
	for item in items:
		_give(String(item), int(items[item]))
	if bool(ch.get("map", false)):
		_give(game.make_treasure_map())
	if bool(q.get("song", false)):
		hero.add_effect("song", {"secs": 1800.0, "mods": {"dex": 5}, "name": "Inspired by song", "color": Color(0.9, 0.7, 1.0)})
	st["state"] = "done"
	game.count("side_quests")
	game.log_event("Task done: %s.%s" % [q["title"], (" +%d gold." % gold) if gold > 0 else ""])
	game.sound("gain", hero.position)
	_refresh()


func _page_quests() -> void:
	_h("Side quests")
	_t("Townsfolk across the land need help. Walk up to them and talk (the action button appears). ! means they have work for you, ? that you can hand it in.")
	for v in villagers:
		var n := (v["e"] as Entity).display_name
		var ids := _quests_of(n)
		if ids.is_empty():
			continue
		var line := ""
		for id in ids:
			var st := String(_sq(id)["state"])
			var q: Dictionary = SIDE_QUESTS[id]
			match st:
				"done":
					line += "%s: done. " % q["title"]
				"active":
					line += "%s: %s%s. " % [q["title"], _goal_text(id), " - hand it in!" if _goal_done(id) else ""]
				_:
					line += "%s: not taken. " % q["title"]
		_small_text("%s (%s)\n%s" % [n, world.place_name(world.to_tile((v["e"] as Entity).position)) if world.place_name(world.to_tile((v["e"] as Entity).position)) != "" else "out in the wilds", line])
		_b("Walk to %s" % n, _walk_to_villager.bind(n))


func _walk_to_villager(n: String) -> void:
	var e := villager(n)
	if e != null:
		game.hero_journey(world.to_tile(e.position))
		_close()


func _walk_to(t: Vector2i) -> void:
	game.hero_journey(t)
	_close()


# --- bounty boards ---------------------------------------------------------------------------

func _new_board() -> void:
	var offers: Array = []
	var k: Array = ELITE_KINDS[randi() % ELITE_KINDS.size()]
	var nm := "%s the %s" % [EPITHETS[randi() % EPITHETS.size()], k[0]]
	var base := _cfg_of(String(k[0]))
	var reward := 120 + int(float(base.get("danger", 2)) * 60.0)
	offers.append({"kind": "elite", "target": nm, "base": k[0], "count": 1, "reward": reward, "fame": 60,
		"text": "WANTED: %s, a beast of uncommon size. %d gold." % [nm, reward], "rect": [k[1].position.x, k[1].position.y, k[1].size.x, k[1].size.y]})
	var h: Array = HUNTS[randi() % HUNTS.size()]
	offers.append({"kind": "hunt", "target": h[0], "count": h[1], "reward": h[2], "fame": 30,
		"text": "CULL: %d %s. %d gold." % [h[1], h[0], h[2]]})
	for item in game.creatures:
		var e := item as Entity
		if e.kind == Entity.Kind.PLAYER and not e.is_hero and not e.dead and e.notoriety() == Entity.Notoriety.RED:
			var r2 := 150 + 40 * e.murder_counts
			offers.append({"kind": "outlaw", "target": e.display_name, "count": 1, "reward": r2, "fame": 80,
				"text": "OUTLAW: %s, murderer (%d counts). %d gold, dead." % [e.display_name, e.murder_counts, r2]})
			break
	data["board"] = offers
	data["board_at"] = game.property.play_time


static func _cfg_of(n: String) -> Dictionary:
	match n:
		"Wolf":
			return Bestiary.WOLF
		"Orc":
			return Bestiary.ORC
		"Brown Bear":
			return Bestiary.BROWN_BEAR
		"Frost Wolf":
			return Bestiary.FROST_WOLF
		"Sand Scorpion":
			return Bestiary.SAND_SCORPION
		"Bog Troll":
			return Bestiary.BOG_TROLL
		"Skeleton":
			return Bestiary.SKELETON
		"Giant Spider":
			return Bestiary.GIANT_SPIDER
	return Bestiary.ORC


func _spawn_elite(b: Dictionary) -> void:
	var cfg := _cfg_of(String(b.get("base", "Orc"))).duplicate(true)
	cfg["str"] = int(float(cfg.get("str", 30)) * 1.9)
	cfg["dex"] = int(float(cfg.get("dex", 30)) * 1.2)
	cfg["dmg_min"] = float(cfg.get("dmg_min", 2)) * 1.5
	cfg["dmg_max"] = float(cfg.get("dmg_max", 5)) * 1.5
	cfg["armor"] = float(cfg.get("armor", 0.0)) + 2.0
	cfg["scale"] = float(cfg.get("scale", 1.0)) * 1.3
	cfg["danger"] = float(cfg.get("danger", 2)) + 2.0
	cfg["passive"] = false
	cfg["tame"] = -1.0
	cfg["species"] = ""
	var loot: Dictionary = cfg.get("loot", {}).duplicate(true)
	loot["gold_min"] = int(loot.get("gold_min", 10)) * 3 + 20
	loot["gold_max"] = int(loot.get("gold_max", 20)) * 3 + 40
	cfg["loot"] = loot
	var rr: Array = b.get("rect", [20, 16, 10, 6])
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var t := world.open_tile_in(Rect2i(int(rr[0]), int(rr[1]), int(rr[2]), int(rr[3])), rng)
	bounty_target = game.pool_spawn(String(b["target"]), cfg, Color(0.9, 0.3, 0.2), world.tile_center(t))


## A notice board on two posts in each town, pinned with papers.
func _build_boards() -> void:
	var wood := Color(0.4, 0.27, 0.14)
	for t in BOARDS:
		_mesh([[Art.box(0.08, 1.6, 0.08), Art.at(-0.5, 0.8, 0), wood], [Art.box(0.08, 1.6, 0.08), Art.at(0.5, 0.8, 0), wood],
			[Art.box(1.15, 0.75, 0.06), Art.at(0, 1.15, 0), wood.lightened(0.15)],
			[Art.box(0.25, 0.3, 0.02), Art.at(-0.3, 1.2, 0.04), Color(0.92, 0.88, 0.75)],
			[Art.box(0.22, 0.28, 0.02), Art.at(0.05, 1.1, 0.04), Color(0.95, 0.9, 0.8)],
			[Art.box(0.25, 0.22, 0.02), Art.at(0.35, 1.25, 0.04), Color(0.9, 0.85, 0.7)],
			[Art.box(1.25, 0.08, 0.15), Art.at(0, 1.56, 0), wood.darkened(0.2)]], world.tile_center(t) + Vector3(0, 0, -0.35))


func _at_board() -> bool:
	for t in BOARDS:
		if _near(t, 2.6):
			return true
	return false


func _page_board() -> void:
	_h("Bounty board")
	if data["board"].is_empty() or game.property.play_time - float(data.get("board_at", -1.0e9)) > DAY:
		_new_board()
	var b: Dictionary = data["bounty"]
	if not b.is_empty():
		_t("Your bounty: " + String(b["text"]))
		if String(b["kind"]) == "hunt":
			_small_text("Progress: %d/%d" % [int(b.get("done", 0)), int(b["count"])])
		elif String(b["kind"]) == "elite" and bounty_target != null and not bounty_target.dead:
			_small_text("It roams %s (a red mark on the map)." % _where(bounty_target.position))
		_b("Give up this bounty", _drop_bounty)
		return
	if not _at_board():
		_t("The boards stand in each town: the main town, the outpost and Southmoor.")
		_b("Walk to the nearest board", _walk_to.bind(_nearest_board()))
	_t("Posted notices (one bounty at a time; paid as soon as the deed is done):")
	for i in range(data["board"].size()):
		var o: Dictionary = data["board"][i]
		_b(String(o["text"]), _take_bounty.bind(i), _at_board())


func _nearest_board() -> Vector2i:
	var best: Vector2i = BOARDS[0]
	for t in BOARDS:
		if world.tile_center(t).distance_to(hero.position) < world.tile_center(best).distance_to(hero.position):
			best = t
	return best


func _where(p: Vector3) -> String:
	var v := p - hero.position
	return "%d m %s" % [roundi(v.length()), game._compass(v)]


func _take_bounty(i: int) -> void:
	var o: Dictionary = (data["board"][i] as Dictionary).duplicate(true)
	o["done"] = 0
	data["bounty"] = o
	(data["board"] as Array).remove_at(i)
	if String(o["kind"]) == "elite":
		_spawn_elite(o)
	game.log_event("Bounty taken: " + String(o["text"]))
	_refresh()


func _drop_bounty() -> void:
	if bounty_target != null and not bounty_target.dead:
		bounty_target.vanish()
	bounty_target = null
	data["bounty"] = {}
	_refresh()


func _bounty_paid(b: Dictionary) -> void:
	hero.gold += int(b["reward"])
	hero.add_fame(int(b["fame"]))
	game.count("bounties")
	game.log_event("Bounty claimed: %d gold." % int(b["reward"]))
	game.sound("loot", hero.position)
	data["bounty"] = {}
	bounty_target = null


# --- the dungeon's depths ------------------------------------------------------------------

func _build_stairs() -> void:
	var c := world.tile_center(STAIRS)
	var parts := []
	for i in range(4):
		parts.append([Art.box(0.9, 0.12, 0.25), Art.at(0, 0.06 - i * 0.12 + 0.36, -0.36 + i * 0.24), Color(0.3, 0.28, 0.26).darkened(i * 0.15)])
	parts.append([Art.box(1.0, 0.05, 1.0), Art.at(0, 0.0, 0), Color(0.05, 0.04, 0.04)])
	_mesh(parts, c + Vector3(0, -0.3, 0))
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.6, 0.3, 0.9)
	glow.omni_range = 3.0
	glow.position = c + Vector3(0, 0.8, 0)
	add_child(glow)


func deepest() -> int:
	var d := maxi(_i("deepest", 1), 1)
	if d < 2 and _killed("The Bone King"):
		d = 2
	return mini(d, DEPTHS.size())


func _page_stairs() -> void:
	_h("The stairs down")
	_t("Stone steps wind down into the dark beneath the Bone King's hall. Each level is darker, its dead stronger and richer. Slay a level's master to open the way deeper.")
	_small_text("You are on level %d: %s. Deepest open: %d." % [depth, DEPTHS[depth - 1]["name"], deepest()])
	if deepest() < 2:
		_t("The way down is sealed while the Bone King rules the halls.")
	for d in range(1, deepest() + 1):
		if d != depth:
			_b("%s to level %d: %s" % ["Descend" if d > depth else "Climb", d, DEPTHS[d - 1]["name"]], _go_depth.bind(d), _near(STAIRS, 2.5))


func _go_depth(d: int) -> void:
	_set_depth(d)
	hero.position = world.tile_center(DUNGEON_DOOR if d > 1 else STAIRS)
	hero.path.clear()
	hero.target = null
	hero.has_journey = false
	for p in hero.pets:
		if not p.dead and not p.parked:
			p.position = hero.position
	var verb := "descend" if d > 1 else "climb back"
	game.log_event("You %s to level %d: %s." % [verb, d, DEPTHS[d - 1]["name"]])
	game.sound("cast", hero.position)
	_close()


func _set_depth(d: int) -> void:
	depth = d
	var m := 1.0 + 0.4 * (d - 1)
	for item in game.creatures:
		var e := item as Entity
		if e.kind != Entity.Kind.MONSTER or game._pool.has(e) or not world.is_dungeon(world.to_tile(e.home)):
			continue
		if not e.has_meta("fr_base"):
			e.set_meta("fr_base", [e.stats.strength, e.stats.dexterity, e.dmg_min, e.dmg_max, e.armor, e.danger])
		var b: Array = e.get_meta("fr_base")
		e.stats.strength = roundi(float(b[0]) * m)
		e.stats.dexterity = roundi(float(b[1]) * (1.0 + 0.15 * (d - 1)))
		e.dmg_min = float(b[2]) * m
		e.dmg_max = float(b[3]) * m
		e.armor = float(b[4]) + (d - 1)
		e.danger = float(b[5]) + (d - 1)
		if not e.dead:
			e.hp = float(e.stats.max_hp())
	var tint: Color = DEPTHS[d - 1]["tint"]
	if world.dungeon_floor_mat != null:
		world.dungeon_floor_mat.albedo_color = tint
	if _depth_boss != null and not _depth_boss.dead:
		_depth_boss.vanish()
	_depth_boss = null
	if d > 1:
		var cfg := Bestiary.BONE_KING.duplicate(true)
		cfg["look"] = String(DEPTHS[d - 1]["look"])
		cfg["str"] = 300 + 90 * d
		cfg["dmg_min"] = 12.0 + 3.0 * d
		cfg["dmg_max"] = 24.0 + 5.0 * d
		cfg["armor"] = 5.0 + d
		cfg["danger"] = 8 + d
		cfg["loot"] = {"gold_min": 400 * d, "gold_max": 700 * d, "reagents": 30,
			"drops": [["platemail", 0.5], ["cave_crystal", 1.0], ["scroll_meteor_swarm", 0.4], ["bonecleaver", 0.3], ["diamond", 0.5]]}
		_depth_boss = game.pool_spawn(String(DEPTHS[d - 1]["boss"]), cfg, tint.darkened(0.3), world.tile_center(DEPTH_BOSS_AT))


func _depth_tick(delta: float) -> void:
	if depth <= 1:
		return
	if hero.dead or not world.is_dungeon(world.to_tile(hero.position)):
		_out_of_dungeon += delta
		if _out_of_dungeon > 3.0:
			_out_of_dungeon = 0.0
			_set_depth(1)
			if not hero.dead:
				game.log_event("You climb back up into the daylight. The depths fall quiet behind you.")
	else:
		_out_of_dungeon = 0.0


# --- boats ---------------------------------------------------------------------------------

func _boat_parts() -> Array:
	var wood := Color(0.45, 0.3, 0.16)
	return [[Art.box(0.7, 0.25, 1.5), Art.at(0, 0.12, 0), wood], [Art.box(0.5, 0.05, 1.2), Art.at(0, 0.26, 0), wood.darkened(0.3)],
		[Art.cone(0.35, 0.5, 0.0, 4), Art.at(0, 0.12, 0.95, Vector3(PI / 2.0, 0, 0)), wood],
		[Art.box(0.6, 0.06, 0.18), Art.at(0, 0.3, 0.1), wood.lightened(0.15)],
		[Art.box(0.04, 0.04, 1.2), Art.at(0.38, 0.28, -0.3, Vector3(0.3, 0, 0)), Color(0.6, 0.45, 0.25)]]


func _build_docks() -> void:
	for d in DOCKS:
		var t: Vector2i = d["tile"]
		var other: Vector2i = DOCKS[int(d["to"])]["tile"]
		var dir := (Vector2(other) - Vector2(t)).normalized()
		var c := world.tile_center(t)
		var pier := _mesh([[Art.box(0.9, 0.08, 1.4), Art.at(0, 0.2, 0.5), Color(0.5, 0.36, 0.2)],
			[Art.box(0.1, 0.5, 0.1), Art.at(-0.4, 0.05, 1.1), Color(0.3, 0.2, 0.1)], [Art.box(0.1, 0.5, 0.1), Art.at(0.4, 0.05, 1.1), Color(0.3, 0.2, 0.1)]], c)
		pier.rotation.y = atan2(dir.x, dir.y)
		var boat := _mesh(_boat_parts(), c + Vector3(dir.x, 0.0, dir.y) * 1.4 + Vector3(0.6 * dir.y, -0.05, -0.6 * dir.x))
		boat.position.y = 0.02
		boat.rotation.y = atan2(dir.x, dir.y)
	_sail_node = _mesh(_boat_parts(), Vector3.ZERO)
	_sail_node.visible = false


func _at_dock() -> int:
	for i in range(DOCKS.size()):
		if _near(DOCKS[i]["tile"], 2.2):
			return i
	return -1


func _page_dock() -> void:
	var d: Dictionary = DOCKS[dock_i]
	var to: Dictionary = DOCKS[int(d["to"])]
	_h(String(d["name"]))
	var own := bool(data.get("boat", false))
	_t("A wooden landing on the lake. %s" % ("Your own boat is tied up here." if own else "A ferryman rows travellers across for a few coins; boats are for sale."))
	if _at_dock() != dock_i:
		_b("Walk to the landing", _walk_to.bind(d["tile"]))
		return
	_b("Sail across to %s%s" % [to["name"], "" if own else " (%d gold)" % FERRY_PRICE], _sail.bind(dock_i, false))
	if own:
		_b("Fish from the boat, out on the deep water", _sail.bind(dock_i, true), _has("fishing_pole"))
		if not _has("fishing_pole"):
			_small_text("You need a fishing pole (any merchant sells them).")
	else:
		_b("Buy a boat (%d gold)" % BOAT_PRICE, _buy_boat)
	if not _has("fishing_pole"):
		_b("Buy a fishing pole (%d gold)" % POLE_PRICE, _buy_pole)


func _buy_pole() -> void:
	if _pay(POLE_PRICE):
		_give("fishing_pole")
		game.log_event("The ferryman sells you a fishing pole.")
	_refresh()


func _buy_boat() -> void:
	if _pay(BOAT_PRICE):
		data["boat"] = true
		game.log_event("You buy a little rowing boat. It waits for you at every landing.")
	_refresh()


func _sail(i: int, fishing: bool) -> void:
	if not fishing and not bool(data.get("boat", false)) and not _pay(FERRY_PRICE):
		_refresh()
		return
	if hero.mounted_on != null:
		hero.dismount()
	var a := world.tile_center(DOCKS[i]["tile"])
	var b := world.tile_center(DOCKS[int(DOCKS[i]["to"])]["tile"])
	if fishing:
		b = a.lerp(b, 0.5)                     # out to the middle of the lake
	sail = {"a": a, "b": b, "t": 0.0, "dur": a.distance_to(b) / BOAT_SPEED, "mode": "fish_out" if fishing else "cross", "wait": 0.0, "home": a}
	_sail_node.visible = true
	game.log_event("You push off from %s." % DOCKS[i]["name"])
	_close()


func _sail_tick(delta: float) -> void:
	if sail.is_empty():
		return
	if hero.dead:
		sail = {}
		_sail_node.visible = false
		return
	var a: Vector3 = sail["a"]
	var b: Vector3 = sail["b"]
	var mode := String(sail["mode"])
	var p := b
	if mode == "fish_wait":
		sail["wait"] = float(sail["wait"]) + delta
		if float(sail["wait"]) >= 2.5:
			sail["wait"] = 0.0
			sail["casts"] = int(sail.get("casts", 0)) + 1
			_boat_cast()
			if int(sail["casts"]) >= 4:
				sail["mode"] = "fish_back"
				sail["a"] = b
				sail["b"] = sail["home"]
				sail["t"] = 0.0
	else:
		sail["t"] = float(sail["t"]) + delta
		var f := clampf(float(sail["t"]) / maxf(float(sail["dur"]), 0.1), 0.0, 1.0)
		p = a.lerp(b, f)
		if f >= 1.0:
			if mode == "fish_out":
				sail["mode"] = "fish_wait"
				game.log_event("You ship the oars and cast your line.")
			else:
				sail = {}
				_sail_node.visible = false
				hero.position = b
				hero.path.clear()
				game.log_event("The boat bumps against the landing. You step ashore.")
				return
	if mode != "fish_wait":
		sail["oar"] = float(sail.get("oar", 0.0)) - delta
		if float(sail["oar"]) <= 0.0:
			sail["oar"] = 1.1                   # a stroke of the oars
			game.sound("oar", hero.position, randf_range(0.9, 1.1), -4.0)
	var bob := sin(Time.get_ticks_msec() / 400.0) * 0.04
	_sail_node.position = Vector3(p.x, 0.02 + bob, p.z)
	var dir := b - a
	if dir.length() > 0.1:
		_sail_node.rotation.y = atan2(dir.x, dir.z)
	hero.position = Vector3(p.x, 0.12 + bob, p.z)
	hero.path.clear()
	hero.target = null
	hero.has_journey = false
	hero.pause = 0.5
	hero.gather_tile = Vector2i(-1, -1)


func _boat_cast() -> void:
	if not hero._use_tool("fishing_pole"):
		game.log_event("Your fishing pole breaks.")
		sail["casts"] = 99
		return
	hero.stats.try_gain(Hero.Skill.FISHING)
	var sk: float = hero._skill(Hero.Skill.FISHING)
	if randf() > 0.45 + sk / 200.0:
		hero._pop("nothing bites", Color(0.75, 0.75, 0.75))
		return
	var roll := randf()
	var got := "fish"
	if roll < 0.04 + sk / 1000.0:
		got = "pearl"
	elif roll < 0.3 + sk / 400.0:
		got = "big_fish"
	elif roll > 0.95:
		got = "old_boot"
	_give(got)
	hero._pop("+1 " + Items.item_name(got), Color(0.6, 0.85, 1.0))
	game.count("fish_caught")
	if got == "pearl":
		game.log_event("Something glints on the hook: a pearl!")


# --- cooking ------------------------------------------------------------------------------

func _can_cook_here() -> bool:
	return game.near_campfire(hero.position) or _near(HEARTH, 3.0) or (_decor_has("hearth") and game._hero_at_house())


func _page_cook() -> void:
	_h("Cooking   (Cooking %.1f)" % hero._skill(Hero.Skill.COOKING))
	var here := _can_cook_here()
	_t("Cook at a campfire, the tavern's hearth or a hearth in your house. A good meal heals you and makes you stronger for a while (one meal's strength at a time)." if here \
		else "You need a fire to cook: light a campfire (one log), or use the tavern's hearth in Southmoor.")
	if not here:
		_b("Light a campfire (1 log)", _make_fire, _has("log"))
	for id in RECIPE_ORDER:
		var r: Dictionary = RECIPES[id]
		var ok := here and hero._skill(Hero.Skill.COOKING) >= float(r["min"]) and Crafting.has_mats(hero.inventory, r["mats"])
		_b("Cook %s: %s (%d%%)" % [Items.item_name(id), Items.mats_text(r["mats"]),
			roundi(Rules.craft_chance(hero._skill(Hero.Skill.COOKING), float(r["min"])) * 100.0)], _cook.bind(id), ok)
	_h("Eat")
	var any := false
	for id in MEALS:
		if _has(String(id)):
			any = true
			var m: Dictionary = MEALS[id]
			_b("Eat %s (x%d): +%d HP%s" % [Items.item_name(String(id)), int(hero.inventory[id]), int(m["heal"]), _mods_text(m["mods"])], _eat.bind(String(id)))
	if not any:
		_small_text("Nothing to eat in your bag. Hunt for meat (deer, bears, wolves), fish, or visit the tavern.")


static func _mods_text(mods: Dictionary) -> String:
	var parts: Array[String] = []
	for k in mods:
		parts.append("%s%d %s" % ["+" if int(mods[k]) >= 0 else "", int(mods[k]), String(k).capitalize()])
	return (", " + ", ".join(parts)) if not parts.is_empty() else ""


func _make_fire() -> void:
	if _has("log"):
		_take("log")
		game.light_campfire(hero.position)
		hero.stats.try_gain(Hero.Skill.CAMPING)
		game.log_event("You build a small fire.")
	_refresh()


func _cook(id: String) -> void:
	var r: Dictionary = RECIPES[id]
	if not _can_cook_here() or not Crafting.has_mats(hero.inventory, r["mats"]):
		_refresh()
		return
	Crafting.take_mats(hero.inventory, r["mats"], 1.0)
	hero.stats.try_gain(Hero.Skill.COOKING)
	if randf() < Rules.craft_chance(hero._skill(Hero.Skill.COOKING), float(r["min"])):
		_give(id)
		game.count("cooked")
		game.log_event("You cook %s." % Items.item_name(id).to_lower())
		game.sound("gather", hero.position)
	else:
		game.log_event("You burn the %s." % Items.item_name(id).to_lower())
	_refresh()


func _eat(id: String) -> void:
	if not _has(id):
		return
	_take(id)
	var m: Dictionary = MEALS[id]
	hero.hp = minf(hero.hp + float(m["heal"]), float(hero.stats.max_hp()))
	if float(m["secs"]) > 0.0:
		if id == "ale":
			hero.stamina = float(hero.stats.max_stamina())
			hero.add_effect("tipsy", {"secs": float(m["secs"]), "mods": m["mods"], "name": "Tipsy", "color": Color(0.9, 0.75, 0.4)})
		else:
			hero.add_effect("well_fed", {"secs": float(m["secs"]), "mods": m["mods"], "name": "Well fed", "color": Color(1.0, 0.85, 0.4)})
	game.count("food_eaten")
	game.log_event("You eat the %s." % Items.item_name(id).to_lower())
	_refresh()


# --- alchemy: brews and blade poisons -----------------------------------------------------

func _page_alchemy() -> void:
	_h("Alchemy   (Alchemy %.1f, reagents %d)" % [hero._skill(Hero.Skill.ALCHEMY), int(hero.reagents)])
	_t("Brew with reagents and what the wilds give: swamp herbs from the Fen, scorpion venom from the Wastes, crystals from the caves, meat from the hunt. Poison your blade and the next blows may poison your foe.")
	for id in BREWS:
		var r: Dictionary = Crafting.RECIPES[id]
		_b("Brew %s: %s, Alchemy %d (%d%%)" % [Items.item_name(id), Items.mats_text(r["mats"]), int(r["min"]),
			roundi(Rules.craft_chance(hero._skill(Hero.Skill.ALCHEMY), float(r["min"])) * 100.0)], _brew.bind(id), hero.craft_problem(id) == "")
	_h("Use")
	if hero.blade_poison_hits > 0:
		_small_text("Your blade is poisoned (%s, %d blows left)." % [Rules.POISON_NAMES[hero.blade_poison], hero.blade_poison_hits])
	var any := false
	for id in BREWS:
		if _has(id):
			any = true
			_b("%s %s (x%d)" % ["Coat your blade:" if id.begins_with("poison") else "Drink", Items.item_name(id), int(hero.inventory[id])], _use_brew.bind(id))
	if not any:
		_small_text("You carry none of these brews.")


func _brew(id: String) -> void:
	hero.craft(id)
	_refresh()


func _use_brew(id: String) -> void:
	if not _has(id):
		return
	if id.begins_with("poison") and (hero.weapon == "" or Gear.is_ranged(hero.weapon)):
		game.log_event("You need a blade in hand to poison it.")
		return
	_take(id)
	match id:
		"potion_strength":
			hero.add_effect("potion_strength", {"secs": 180.0, "mods": {"str": 10}, "name": "Strength!", "color": Color(1.0, 0.55, 0.3)})
		"potion_agility":
			hero.add_effect("potion_agility", {"secs": 180.0, "mods": {"dex": 10}, "name": "Agility!", "color": Color(0.5, 1.0, 0.6)})
		"potion_invisibility":
			hero.add_effect("potion_invisibility", {"secs": 30.0, "flag": "invisible", "name": "You fade from sight", "color": Color(0.7, 0.8, 1.0)})
			hero.target = null
		"poison_lesser":
			hero.blade_poison = 1
			hero.blade_poison_hits = 12
			game.log_event("You coat your blade with a lesser poison.")
		"poison_deadly":
			hero.blade_poison = 3
			hero.blade_poison_hits = 8
			game.log_event("You coat your blade with a deadly poison.")
	game.count("potions_drunk")
	game.sound("gulp", hero.position, 1.0, -4.0)
	_refresh()


# --- house decoration -----------------------------------------------------------------------

func _decor_has(id: String) -> bool:
	return (data["decor"] as Array).has(id)


func comfort() -> int:
	var n := 0
	for id in data["decor"]:
		if DECOR.has(String(id)):
			n += int(DECOR[String(id)]["comfort"])
	return n


func _decor_slots() -> int:
	return 4 + game.property.house_size * 2


func _page_house() -> void:
	var pr: Property = game.property
	_h("Your home")
	if not pr.has_house():
		_t("You have no house yet. Buy a deed at the bank (Bank & House) and place it out in the wilds; then furnish it here.")
		return
	var at_home: bool = game._hero_at_house()
	_t("Comfort %d. Furniture %d/%d. A comfortable home makes resting in it count for more: after a night in your own bed you're Rested for longer (comfort x 2 minutes)." % [comfort(), data["decor"].size(), _decor_slots()])
	if not at_home:
		_b("Walk home", _walk_to.bind(pr.house_center_tile()))
	if _decor_has("bed"):
		_b("Sleep in your bed", _rest, at_home and game.property.play_time - float(data.get("rest_at", -1.0e9)) > 120.0)
	if _decor_has("bookshelf"):
		_b("Study at the bookshelf (once a day)", _study, at_home and game.property.play_time - float(data.get("study_at", -1.0e9)) > DAY)
	if _decor_has("garden"):
		_b("Gather from the herb garden (once a day)", _garden, at_home and game.property.play_time - float(data.get("garden_at", -1.0e9)) > DAY)
	if _decor_has("hearth"):
		_b("Cook at the hearth", _open.bind("cook"), at_home)
	_h("Furnish (delivered at once)")
	for id in DECOR_ORDER:
		var d: Dictionary = DECOR[id]
		if d.has("trophy"):
			if not _killed(String(d["trophy"])) or _decor_has(id):
				continue
			_b("Place %s (earned)" % d["name"], _buy_decor.bind(id), data["decor"].size() < _decor_slots())
		else:
			_b("%s: %d gold" % [d["name"], int(d["price"])], _buy_decor.bind(id), data["decor"].size() < _decor_slots() and hero.gold >= int(d["price"]))
	if not data["decor"].is_empty():
		_h("Placed")
		for i in range(data["decor"].size()):
			var id2 := String(data["decor"][i])
			if DECOR.has(id2):
				_b("Remove %s (half back)" % DECOR[id2]["name"], _remove_decor.bind(i))


func _buy_decor(id: String) -> void:
	var price := int(DECOR[id]["price"])
	if price > 0 and not _pay(price):
		return
	(data["decor"] as Array).append(id)
	game.log_event("%s is set up in your house." % DECOR[id]["name"])
	_decor_key = ""
	_refresh()


func _remove_decor(i: int) -> void:
	var id := String(data["decor"][i])
	hero.gold += int(DECOR.get(id, {"price": 0})["price"]) / 2
	(data["decor"] as Array).remove_at(i)
	_decor_key = ""
	_refresh()


func _rest() -> void:
	data["rest_at"] = game.property.play_time
	hero.hp = float(hero.stats.max_hp())
	hero.mana = float(hero.stats.max_mana())
	hero.stamina = float(hero.stats.max_stamina())
	if game.is_night():
		game.day_time = 0.27
	var c := comfort()
	hero.add_effect("rested", {"secs": 300.0 + c * 120.0, "mods": {"str": 2 + c / 4, "dex": 2 + c / 4, "int": 2 + c / 4}, "name": "Rested", "color": Color(0.7, 0.9, 1.0)})
	game.log_event("You sleep soundly in your own bed and wake Rested.")
	_refresh()


func _study() -> void:
	data["study_at"] = game.property.play_time
	for s in [Hero.Skill.ITEM_IDENTIFICATION, Hero.Skill.ARMS_LORE, Hero.Skill.EVALUATING_INTELLECT, Hero.Skill.ANIMAL_LORE]:
		hero.stats.try_gain(s)
	game.log_event("You spend an hour with your books. Your mind feels keener.")
	_refresh()


func _garden() -> void:
	data["garden_at"] = game.property.play_time
	_give("swamp_herb", 3)
	game.log_event("You gather three herbs from your garden.")
	_refresh()


## Rebuilds the furniture when the house or what's in it changes.
func _decor_tick() -> void:
	var pr: Property = game.property
	var key := "%s|%d|%s" % [pr.house_origin, pr.house_size, ",".join(PackedStringArray(data["decor"]))]
	if key == _decor_key:
		return
	_decor_key = key
	if _decor_node != null:
		_decor_node.queue_free()
		_decor_node = null
	if not pr.has_house():
		return
	_decor_node = Node3D.new()
	add_child(_decor_node)
	var slots := _decor_positions(pr.house_origin, pr.house_size)
	for i in range(mini(data["decor"].size(), slots.size())):
		var id := String(data["decor"][i])
		var parts := _decor_parts(id)
		if parts.is_empty():
			continue
		var mi := _mesh(parts, slots[i], _decor_node)
		mi.rotation.y = (i % 4) * PI / 2.0
		if id == "lantern" or id == "hearth":
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.7, 0.4)
			l.omni_range = 3.0
			l.position = Vector3(0, 0.8, 0)
			mi.add_child(l)
		if id == "hearth":
			var fl := Fx.flame(0.2, 12, 0.4)
			fl.position = Vector3(0, 0.5, 0)
			mi.add_child(fl)


func _decor_positions(o: Vector2i, size: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var centre := World.house_center(o, size)
	for dy in range(1, size - 1):
		for dx in range(1, size - 1):
			var t := o + Vector2i(dx, dy)
			for off in [Vector3(-0.25, 0, 0.25), Vector3(0.25, 0, 0.25), Vector3(-0.25, 0, -0.25), Vector3(0.25, 0, -0.25)]:
				if t == centre and off.z < 0.0:
					continue                    # the chest stands there
				out.append(world.tile_center(t) + off)
	# then the yard: along the sides and the back, outside the walls
	for k in range(size):
		for t2 in [o + Vector2i(-1, k), o + Vector2i(size, k), o + Vector2i(k, -1)]:
			if not world.is_blocked(t2):
				out.append(world.tile_center(t2))
	return out


func _decor_parts(id: String) -> Array:
	var wood := Color(0.45, 0.29, 0.15)
	var dark := Color(0.28, 0.18, 0.1)
	match id:
		"rug":
			return [[Art.box(0.5, 0.02, 0.7), Art.at(0, 0.01, 0), Color(0.6, 0.15, 0.15)], [Art.box(0.4, 0.025, 0.6), Art.at(0, 0.012, 0), Color(0.8, 0.6, 0.2)]]
		"table":
			return [[Art.box(0.45, 0.05, 0.35), Art.at(0, 0.4, 0), wood], [Art.box(0.05, 0.4, 0.05), Art.at(-0.18, 0.2, -0.13), dark],
				[Art.box(0.05, 0.4, 0.05), Art.at(0.18, 0.2, -0.13), dark], [Art.box(0.05, 0.4, 0.05), Art.at(-0.18, 0.2, 0.13), dark],
				[Art.box(0.05, 0.4, 0.05), Art.at(0.18, 0.2, 0.13), dark]]
		"chair":
			return [[Art.box(0.25, 0.04, 0.25), Art.at(0, 0.24, 0), wood], [Art.box(0.25, 0.3, 0.04), Art.at(0, 0.4, -0.11), wood],
				[Art.box(0.04, 0.24, 0.04), Art.at(-0.1, 0.12, 0.1), dark], [Art.box(0.04, 0.24, 0.04), Art.at(0.1, 0.12, 0.1), dark]]
		"plant":
			return [[Art.cone(0.1, 0.18, 0.13, 8), Art.at(0, 0.09, 0), Color(0.65, 0.35, 0.2)], [Art.ball(0.17), Art.at(0, 0.3, 0), Color(0.25, 0.55, 0.25)]]
		"lantern":
			return [[Art.box(0.04, 0.8, 0.04), Art.at(0, 0.4, 0), dark], [Art.box(0.12, 0.16, 0.12), Art.at(0, 0.85, 0), Color(1.0, 0.8, 0.4)]]
		"weapon_rack":
			return [[Art.box(0.45, 0.06, 0.1), Art.at(0, 0.5, 0), wood], [Art.box(0.04, 0.6, 0.04), Art.at(-0.15, 0.3, 0.03), Color(0.7, 0.7, 0.75)],
				[Art.box(0.04, 0.65, 0.04), Art.at(0.0, 0.32, 0.03), Color(0.7, 0.7, 0.75)], [Art.box(0.04, 0.55, 0.04), Art.at(0.15, 0.28, 0.03), Color(0.6, 0.45, 0.3)]]
		"bed":
			return [[Art.box(0.45, 0.2, 0.75), Art.at(0, 0.1, 0), wood], [Art.box(0.43, 0.06, 0.55), Art.at(0, 0.23, 0.08), Color(0.25, 0.35, 0.7)],
				[Art.box(0.35, 0.07, 0.14), Art.at(0, 0.24, -0.27), Color(0.95, 0.95, 0.92)]]
		"bookshelf":
			var p := [[Art.box(0.45, 0.8, 0.18), Art.at(0, 0.4, 0), dark]]
			for row in range(3):
				for b in range(4):
					p.append([Art.box(0.08, 0.18, 0.12), Art.at(-0.15 + b * 0.1, 0.18 + row * 0.25, 0.04), [Color(0.6, 0.2, 0.2), Color(0.2, 0.3, 0.6), Color(0.3, 0.5, 0.3), Color(0.6, 0.5, 0.2)][(row + b) % 4]])
			return p
		"hearth":
			return [[Art.box(0.55, 0.45, 0.3), Art.at(0, 0.22, 0), Color(0.5, 0.48, 0.46)], [Art.box(0.3, 0.2, 0.05), Art.at(0, 0.18, 0.14), Color(0.1, 0.07, 0.05)]]
		"garden":
			var g := [[Art.box(0.7, 0.08, 0.7), Art.at(0, 0.04, 0), Color(0.35, 0.24, 0.14)]]
			for k in range(6):
				g.append([Art.ball(0.09), Art.at(-0.22 + (k % 3) * 0.22, 0.14, -0.15 + (k / 3) * 0.3), Color(0.3, 0.6 + 0.05 * k, 0.25)])
			return g
	if id.begins_with("trophy"):
		var top := Color(0.9, 0.75, 0.3)
		match id:
			"trophy_yeti":
				top = Color(0.95, 0.97, 1.0)
			"trophy_chief":
				top = Color(0.9, 0.88, 0.8)
			"trophy_abyss":
				top = Color(0.6, 0.2, 0.3)
			"trophy_malgrath":
				top = Color(0.6, 0.4, 0.9)
		return [[Art.box(0.3, 0.45, 0.3), Art.at(0, 0.22, 0), Color(0.55, 0.53, 0.5)], [Art.ball(0.13), Art.at(0, 0.56, 0), top]]
	return []


# --- the arena ----------------------------------------------------------------------------

func _build_arena() -> void:
	var c := world.tile_center(ARENA)
	var n := 16
	for i in range(n):
		var ang := TAU * i / n
		var p := c + Vector3(cos(ang), 0, sin(ang)) * ARENA_RADIUS
		p.y = world.height_at(p)
		var post := _mesh([[Art.box(0.12, 0.9, 0.12), Art.at(0, 0.45, 0), Color(0.4, 0.28, 0.15)],
			[Art.box(0.08, 0.08, 1.4), Art.at(0, 0.75, 0), Color(0.5, 0.35, 0.2)]], p)
		post.rotation.y = -ang
	for side in [-1.0, 1.0]:
		var bp := c + Vector3(side * (ARENA_RADIUS + 0.4), 0, -ARENA_RADIUS - 0.4)
		bp.y = world.height_at(bp)
		_mesh([[Art.box(0.1, 2.0, 0.1), Art.at(0, 1.0, 0), Color(0.3, 0.2, 0.1)], [Art.box(0.5, 0.35, 0.03), Art.at(0.25, 1.8, 0), Color(0.75, 0.2, 0.15)]], bp)


func _in_arena() -> bool:
	return _near(ARENA, ARENA_RADIUS + 1.0)


func _page_arena() -> void:
	_h("The Arena")
	_t("Kael the Arena Master runs the ring. Pay the fee and fight his champions for the purse; bet on yourself and win double your stake. Or watch a bout and bet on a fighter. Leave the ring and you forfeit. Wins so far: %d." % _i("arena_wins"))
	if not duel.is_empty():
		_t("A duel is under way!")
		return
	var here := _near(ARENA, ARENA_RADIUS + 4.0)
	if not here:
		_b("Walk to the arena", _walk_to.bind(ARENA))
	_b("Your bet on yourself: %d gold (tap to change)" % _arena_bet, _cycle_bet)
	for i in range(ARENA_TIERS.size()):
		var t: Dictionary = ARENA_TIERS[i]
		_b("%s: fight %s. Fee %d, purse %d" % [t["name"], t["foe"], int(t["fee"]), int(t["purse"])], _start_duel.bind(i),
			here and hero.gold >= int(t["fee"]) + _arena_bet and not hero.dead)
	_h("Races")
	if race.is_empty():
		var riding := hero.mounted_on != null
		_small_text("A lap of the course on your own mount against three riders. First home takes the purse and three times the stake; second gets the stake back." + ("" if riding else " You must be in the saddle (Ride)."))
		_b("Race (stake 50 gold)", _start_race.bind(50), here and riding and hero.gold >= 50)
		_b("Race (stake 200 gold)", _start_race.bind(200), here and riding and hero.gold >= 200)
	else:
		_small_text("A race is on!")
	_h("Bouts")
	if bout.is_empty():
		_b("Watch a bout and bet (50 gold)", _start_bout.bind(50), here and hero.gold >= 50)
		_b("Watch a bout and bet (200 gold)", _start_bout.bind(200), here and hero.gold >= 200)
	else:
		_small_text("A bout is on: %s against %s." % [bout["a"], bout["b"]])


func _cycle_bet() -> void:
	var i := BETS.find(_arena_bet)
	_arena_bet = int(BETS[(i + 1) % BETS.size()])
	_refresh()


func _start_duel(i: int) -> void:
	var t: Dictionary = ARENA_TIERS[i]
	if not _pay(int(t["fee"]) + _arena_bet):
		return
	if hero.mounted_on != null:
		hero.dismount()
	var s: float = t["skill"]
	var cfg := {
		"look": "humanoid", "str": t["str"], "dex": t["dex"], "int": 20, "wspeed": 45, "dmg_min": t["lo"], "dmg_max": t["hi"],
		"move": 3.6, "leash": 30, "aggro": 30.0, "respawn": 1.0e9, "armor": t["armor"], "danger": t["danger"],
		"weapon": t["weapon"], "wear": t["wear"], "shield": t["shield"], "bandages": 0,
		"loot": {"gold_min": 0, "gold_max": 0, "drops": []},
		"skills": {Hero.Skill.SWORDSMANSHIP: s, Hero.Skill.TACTICS: s, Hero.Skill.MACE_FIGHTING: s, Hero.Skill.FENCING: s,
			Hero.Skill.PARRYING: s * 0.8, Hero.Skill.ANATOMY: s * 0.6},
	}
	var c := world.tile_center(ARENA)
	hero.position = c + Vector3(-1.5, 0, 0)
	hero.path.clear()
	hero.has_journey = false
	var opp: Entity = game.pool_spawn(String(t["foe"]), cfg, Color(0.85, 0.3, 0.25), c + Vector3(1.5, 0, 0))
	opp.target = hero
	hero.target = opp
	duel = {"opp": opp, "bet": _arena_bet, "purse": int(t["purse"]), "tier": i, "t": 0.0, "away": 0.0}
	game.world_event("The crowd roars as %s steps into the ring against %s!" % [hero.display_name, t["foe"]])
	_close()


func _duel_tick(delta: float) -> void:
	if duel.is_empty():
		return
	var opp: Entity = duel["opp"]
	duel["t"] = float(duel["t"]) + delta
	if opp.dead:
		var won := int(duel["purse"]) + int(duel["bet"]) * 2
		hero.gold += won
		hero.add_fame(20 * (int(duel["tier"]) + 1))
		data["arena_wins"] = _i("arena_wins") + 1
		game.count("arena_wins")
		game.event_about("%s wins in the arena and takes %d gold!" % [hero.display_name, won], true)
		game.sound("cheer", world.tile_center(ARENA))
		duel = {}
		return
	if hero.dead:
		opp.vanish()
		game.event_about("%s falls in the arena. The crowd groans." % hero.display_name, true)
		duel = {}
		return
	opp.target = hero
	if not _near(ARENA, ARENA_RADIUS + 3.0):
		duel["away"] = float(duel["away"]) + delta
	else:
		duel["away"] = 0.0
	if float(duel["away"]) > 4.0 or float(duel["t"]) > 180.0:
		opp.vanish()
		game.event_about("%s leaves the ring and forfeits the duel." % hero.display_name, true)
		duel = {}


func _start_bout(bet: int) -> void:
	if not _pay(bet):
		return
	var pool := GLADIATORS.duplicate()
	pool.shuffle()
	var ra := randi_range(40, 90)
	var rb := randi_range(40, 90)
	bout = {"a": pool[0], "b": pool[1], "ra": ra, "rb": rb, "bet": bet, "pick": -1, "t": 0.0, "step": 0}
	_open("bout")


func _page_bout() -> void:
	_h("A bout: %s against %s" % [bout["a"], bout["b"]])
	var ra := float(bout["ra"])
	var rb := float(bout["rb"])
	if int(bout["pick"]) < 0:
		_t("Kael calls the odds. Pick your fighter (stake %d gold):" % int(bout["bet"]))
		_b("%s (wins %d%% of fights; pays %.1fx)" % [bout["a"], roundi(ra / (ra + rb) * 100.0), 1.0 + rb / ra], _pick_fighter.bind(0))
		_b("%s (wins %d%% of fights; pays %.1fx)" % [bout["b"], roundi(rb / (ra + rb) * 100.0), 1.0 + ra / rb], _pick_fighter.bind(1))
	else:
		_t("The bout is on - watch the log.")


func _pick_fighter(i: int) -> void:
	bout["pick"] = i
	bout["win"] = 0 if randf() < float(bout["ra"]) / (float(bout["ra"]) + float(bout["rb"])) else 1
	_close()


func _bout_tick(delta: float) -> void:
	if bout.is_empty() or int(bout["pick"]) < 0:
		return
	bout["t"] = float(bout["t"]) + delta
	if float(bout["t"]) < 2.0:
		return
	bout["t"] = 0.0
	var a := String(bout["a"])
	var b := String(bout["b"])
	var w := a if int(bout["win"]) == 0 else b
	var l := b if int(bout["win"]) == 0 else a
	match int(bout["step"]):
		0:
			game.world_event("Arena: %s and %s circle each other..." % [a, b])
		1:
			game.world_event("Arena: %s lands a heavy blow! The crowd roars." % [l if randf() < 0.5 else w])
		2:
			game.world_event("Arena: %s staggers, but keeps their feet!" % l)
		3:
			game.world_event("Arena: %s wins the bout!" % w)
			game.sound("cheer", world.tile_center(ARENA), 1.0, -6.0)
			if int(bout["pick"]) == int(bout["win"]):
				var mine := float(bout["ra"]) if int(bout["win"]) == 0 else float(bout["rb"])
				var theirs := float(bout["rb"]) if int(bout["win"]) == 0 else float(bout["ra"])
				var pay := roundi(int(bout["bet"]) * (1.0 + theirs / mine))
				hero.gold += pay
				game.log_event("Your fighter won! You collect %d gold." % pay)
			else:
				game.log_event("Your fighter lost. So goes your stake.")
			bout = {}
			return
	bout["step"] = int(bout["step"]) + 1


# --- guild towers -----------------------------------------------------------------------------

func _build_towers() -> void:
	for i in range(TOWERS.size()):
		var tt: Vector2i = World.TOWER_TILES[i]
		var key := str(i)
		if not data["towers"].has(key):
			data["towers"][key] = TOWERS[i]["start"]
		var c := world.tile_center(tt)
		var node := Node3D.new()
		add_child(node)
		node.position = c
		var stone := Color(0.55, 0.53, 0.5)
		var parts := [[Art.cone(0.78, 3.2, 0.68, 10), Art.at(0, 1.6, 0), stone], [Art.cone(0.86, 0.3, 0.86, 10), Art.at(0, 3.3, 0), stone.darkened(0.1)],
			[Art.box(0.3, 0.5, 0.06), Art.at(0, 0.25, 0.75), Color(0.25, 0.16, 0.1)], [Art.box(0.05, 1.3, 0.05), Art.at(0, 4.0, 0), Color(0.3, 0.2, 0.1)]]
		for k in range(5):
			var ang := TAU * k / 5.0
			parts.append([Art.box(0.25, 0.25, 0.25), Art.at(cos(ang) * 0.75, 3.55, sin(ang) * 0.75), stone])
		_mesh(parts, Vector3.ZERO, node)
		var flag := MeshInstance3D.new()
		flag.mesh = Art.box(0.7, 0.45, 0.03)
		var fm := StandardMaterial3D.new()
		fm.albedo_color = _guild_color(String(data["towers"][key]))
		flag.material_override = fm
		flag.position = Vector3(0.37, 4.4, 0)
		node.add_child(flag)
		towers.append({"node": node, "flag": fm, "guild": "", "p": 0.0})


func _guild_color(g: String) -> Color:
	return GUILD_COLORS.get(g, Color(0.9, 0.9, 0.9))


func _guild_name(g: String) -> String:
	if g == "":
		return "no one"
	return String(game.guilds.list[g]["name"]) if game.guilds.list.has(g) else g


func tower_owner(i: int) -> String:
	return String(data["towers"].get(str(i), ""))


func _towers_tick(delta: float) -> void:
	_tower_acc += delta
	if _tower_acc < 0.5:
		return
	var step := _tower_acc
	_tower_acc = 0.0
	for i in range(towers.size()):
		var tw: Dictionary = towers[i]
		var c := world.tile_center(World.TOWER_TILES[i])
		var holder := tower_owner(i)
		var present := {}
		for item in game.creatures:
			var e := item as Entity
			if e.kind != Entity.Kind.PLAYER or e.dead or e.ghost or e.position.distance_to(c) > TOWER_RANGE:
				continue
			var gid := e.guild_id()
			if gid != "":
				present[gid] = true
		var defended := false
		var attackers: Array[String] = []
		for pg in present:
			if game.guilds.allied(String(pg), holder):
				defended = true
			else:
				attackers.append(String(pg))
		if attackers.size() == 1 and not defended:
			if String(tw["guild"]) != attackers[0]:
				tw["guild"] = attackers[0]
				tw["p"] = 0.0
			tw["p"] = float(tw["p"]) + step
			if float(tw["p"]) >= CAPTURE_SECS:
				_capture(i, attackers[0])
		elif attackers.is_empty():
			tw["p"] = maxf(float(tw["p"]) - step, 0.0)
	_raid_in -= step
	if _raid_in <= 0.0:
		_raid_in = randf_range(180.0, 320.0)
		_start_raid()
	for r in raids.duplicate():
		r["left"] = float(r["left"]) - step
		var dest := world.tile_center(World.TOWER_TILES[int(r["tower"])])
		for m in r["members"]:
			var e2 := m as Entity
			if is_instance_valid(e2) and not e2.dead and e2.target == null and not e2.recovering and not e2.retreating \
					and e2.position.distance_to(dest) > 2.5 and not e2.has_journey:
				e2.set_journey(dest)
		if float(r["left"]) <= 0.0:
			raids.erase(r)


func _capture(i: int, g: String) -> void:
	data["towers"][str(i)] = g
	towers[i]["p"] = 0.0
	towers[i]["guild"] = ""
	(towers[i]["flag"] as StandardMaterial3D).albedo_color = _guild_color(g)
	var mine := g != "" and g == hero.guild_id()
	game.event_about("%s takes %s!" % [_guild_name(g), TOWERS[i]["name"]], mine)
	if mine and hero.position.distance_to(world.tile_center(World.TOWER_TILES[i])) <= TOWER_RANGE + 1.0:
		game.count("towers_taken")
		hero.add_fame(50)


## A computer guild sends a couple of its members to take a tower from a rival.
func _start_raid() -> void:
	var ids: Array = game.guilds.list.keys()
	ids.shuffle()
	for g in ids:
		if String(g) == "player":
			continue
		var choices: Array[int] = []
		for i in range(TOWERS.size()):
			var o := tower_owner(i)
			if o != String(g) and not game.guilds.allied(String(g), o):
				choices.append(i)
		if choices.is_empty():
			continue
		var ti: int = choices[randi() % choices.size()]
		var members: Array = []
		for item in game.creatures:
			var e := item as Entity
			if e.kind == Entity.Kind.PLAYER and not e.is_hero and not e.dead and e.guild_id() == String(g) and members.size() < 2:
				members.append(e)
		if members.is_empty():
			continue
		raids.append({"members": members, "tower": ti, "left": 90.0})
		game.world_event("%s march on %s." % [_guild_name(String(g)), TOWERS[ti]["name"]])
		return


func _tower_income() -> void:
	var t: float = game.property.play_time
	if t - float(data.get("income_at", 0.0)) < DAY:
		return
	data["income_at"] = t
	var g := hero.guild_id()
	if g == "":
		return
	var n := 0
	for i in range(TOWERS.size()):
		if tower_owner(i) == g:
			n += 1
	if n > 0:
		game.property.bank_gold += TOWER_INCOME * n
		hero.add_fame(10 * n)
		game.log_event("Your guild's towers pay their tolls: %d gold to your bank." % (TOWER_INCOME * n))


func _at_tower() -> int:
	for i in range(TOWERS.size()):
		if _near(World.TOWER_TILES[i], TOWER_RANGE):
			return i
	return -1


func _page_towers() -> void:
	_h("Guild towers")
	var g := hero.guild_id()
	_t("Three old watchtowers stand in the wilds. A guild takes one by holding the ground round it (%d seconds, with no defenders of its owner or their allies nearby). Each tower pays its guild %d gold a day - into your bank, if it's your guild's. %s" % [
		int(CAPTURE_SECS), TOWER_INCOME, "You fight for %s." % _guild_name(g) if g != "" else "Join or found a guild (Guild & Fame) to take part."])
	for i in range(TOWERS.size()):
		var tw: Dictionary = towers[i]
		var prog := ""
		if float(tw["p"]) > 0.0:
			prog = "  %s taking it: %d%%" % [_guild_name(String(tw["guild"])), roundi(float(tw["p"]) / CAPTURE_SECS * 100.0)]
		_small_text("%s: held by %s. %s%s" % [TOWERS[i]["name"], _guild_name(tower_owner(i)), _where(world.tile_center(World.TOWER_TILES[i])), prog])
		_b("Walk to %s" % TOWERS[i]["name"], _walk_to.bind(World.TOWER_TILES[i] + Vector2i(0, 1)))


# --- what's around: the action button, biomes, snow -------------------------------------------

func _build_snow() -> void:
	_snow = CPUParticles3D.new()
	_snow.amount = 150
	_snow.lifetime = 4.0
	_snow.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_snow.emission_box_extents = Vector3(10, 0.5, 10)
	_snow.direction = Vector3(0.2, -1, 0)
	_snow.spread = 15.0
	_snow.initial_velocity_min = 0.6
	_snow.initial_velocity_max = 1.2
	_snow.gravity = Vector3(0, -0.6, 0)
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	_snow.mesh = q
	_snow.emitting = false
	add_child(_snow)


func _env_tick(delta: float) -> void:
	_env_acc += delta
	if _snow.emitting:
		_snow.position = hero.position + Vector3(0, 5.0, 0)
	if _env_acc < 1.0:
		return
	_env_acc = 0.0
	var t := world.to_tile(hero.position)
	var bk := world.biome_key_at(t)                  # (the region: its own name)
	if bk != _biome:
		if bk != "":
			game.log_event("You enter %s." % World.BIOME_NAMES[bk])
		elif _biome != "":
			game.log_event("You leave %s." % World.BIOME_NAMES[_biome])
		_biome = bk
	var b := world.biome_at(t)
	_snow.emitting = (b == "snow" or snowing()) and game.property.weather_on and not world.is_dungeon(t)
	_sound_tick(b)
	var isle := world.on_island(t)
	if isle != _on_isle:
		_on_isle = isle
		if isle:
			game.log_event("You land on %s: crabs on the sand, drowned sailors in the surf, and a ruin where their king still holds court." % World.ISLAND_NAME)
	var cv := world.cave_at(t)
	if cv != _cave:
		if cv >= 0:
			game.log_event("You enter %s. The air is cold and still." % World.CAVES[cv]["name"])
		_cave = cv


## The beasts' voices (as they turn on you): [sound, pitch].
const VOICES := {"Yeti": ["roar", 0.8], "Bog Troll": ["roar", 1.0], "Frost Giant": ["roar", 0.7], "Brown Bear": ["roar", 1.15],
	"Goblin Chief": ["roar", 1.3], "Goblin": ["roar", 1.7], "Ogre": ["roar", 0.9], "Sand Scorpion": ["hiss", 1.1],
	"Scorpion Queen": ["hiss", 0.8], "Bog Leech": ["hiss", 1.4], "Cave Spider": ["hiss", 1.2], "Giant Spider": ["hiss", 1.1],
	"Mummy": ["rattle", 0.9], "Skeleton": ["rattle", 1.2], "Skeleton Archer": ["rattle", 1.25], "The Barrow King": ["rattle", 0.6]}


## The loops of the wider world (each second): the wind in the snow, the tavern's hum and lute,
## the arena's crowd; and the voices of beasts that turn on you.
func _sound_tick(biome: String) -> void:
	var on: bool = game.property.sound_on and not game.autotest and not hero.dead
	if not on:
		for k in ["wind", "tavern", "crowd"]:
			game._amb_set(k, -80.0)
		return
	game._amb_set("wind", -14.0 if biome == "snow" or season() == "winter" and not world.is_town(world.to_tile(hero.position)) else -80.0)
	var td := world.tile_center(TAVERN).distance_to(hero.position)
	var evening := _phase_now() == "tavern"
	game._amb_set("tavern", lerpf(-8.0 if evening else -16.0, -34.0, td / 12.0) if td < 12.0 else -80.0)
	var crowd_on := (not duel.is_empty() or not bout.is_empty()) and _near(ARENA, 14.0)
	game._amb_set("crowd", -12.0 if crowd_on else -80.0)
	for item in game.creatures:
		var e := item as Entity
		if e.kind != Entity.Kind.MONSTER or e.dead or not VOICES.has(e.display_name):
			continue
		if e.target == null:
			if e.has_meta("voiced"):
				e.remove_meta("voiced")
			continue
		if not e.has_meta("voiced") and e.position.distance_to(hero.position) < 14.0:
			e.set_meta("voiced", true)
			var v: Array = VOICES[e.display_name]
			game.sound(String(v[0]), e.position, float(v[1]), 2.0)


func _act_tick(delta: float) -> void:
	_act_acc += delta
	if _act_acc < 0.3:
		return
	_act_acc = 0.0
	_act = _find_act()
	act_button.visible = not _act.is_empty() and not panel.visible and not game.paused \
		and game._flyby_t < 0.0 and game._cine_phase == 0
	if act_button.visible:
		act_button.text = String(_act["label"])


func _find_act() -> Dictionary:
	if hero.dead or not sail.is_empty() or not duel.is_empty() or not race.is_empty():
		return {}
	for v in villagers:
		var e: Entity = v["e"]
		if e.position.distance_to(hero.position) <= 2.6:
			return {"label": "Talk: %s%s" % [e.display_name, _talk_mark(e.display_name)], "page": "talk", "who": e.display_name}
	if world.in_church(world.to_tile(hero.position)):
		return {"label": "Church", "page": "church"}
	if _near(TOMB_DOOR, 2.4):
		return {"label": "The Tomb of the Old Kings", "page": "tomb"}
	if _at_board():
		return {"label": "Bounty board", "page": "board"}
	var d := _at_dock()
	if d >= 0:
		return {"label": "Boat: %s" % DOCKS[d]["name"], "page": "dock", "dock": d}
	if world.is_dungeon(world.to_tile(hero.position)) and _near(STAIRS, 2.5):
		return {"label": "Stairs down", "page": "stairs"}
	var tw := _at_tower()
	if tw >= 0:
		return {"label": TOWERS[tw]["name"], "page": "towers"}
	if _at_tavern():
		return {"label": "Tavern", "page": "tavern"}
	if _in_arena():
		return {"label": "Arena", "page": "arena"}
	if game._hero_at_house():
		return {"label": "Home", "page": "house"}
	if game.near_campfire(hero.position):
		for id in RECIPES:
			if Crafting.has_mats(hero.inventory, RECIPES[id]["mats"]):
				return {"label": "Cook", "page": "cook"}
	return {}


func _on_act() -> void:
	if _act.is_empty():
		return
	if _act.has("who"):
		talk_with = String(_act["who"])
		talk_text = ""
	if _act.has("dock"):
		dock_i = int(_act["dock"])
	_open(String(_act["page"]))


# --- the game's hooks -------------------------------------------------------------------------

func tick(delta: float) -> void:
	_sail_tick(delta)
	_routines(delta)
	_depth_tick(delta)
	_duel_tick(delta)
	_bout_tick(delta)
	_towers_tick(delta)
	_env_tick(delta)
	_act_tick(delta)
	_auto_tick(delta)
	_race_tick(delta)
	_tutorial_tick(delta)
	_season_acc += delta
	if _season_acc >= 1.0:
		_season_tick(_season_acc)
		_farm_tick(_season_acc)
		_bell_tick()
		_cemetery_tick()
		_world_boss_tick(_season_acc)
		_season_acc = 0.0
	if Engine.get_process_frames() % 30 == 0:
		_decor_tick()
		_tower_income()


func on_kill(killer: Entity, victim: Entity) -> void:
	if world_boss != null and victim == world_boss:
		_world_boss_slain(killer)
	if killer == null or not killer.is_hero:
		return
	for id in SIDE_QUESTS:
		var st: Dictionary = _sq(String(id))
		var g: Dictionary = SIDE_QUESTS[id]["goal"]
		if String(st["state"]) == "active" and String(g["kind"]) == "kill" and String(g["target"]) == victim.display_name \
				and int(st["kills"]) < int(g["count"]):
			st["kills"] = int(st["kills"]) + 1
			game.log_event("%s: %s" % [SIDE_QUESTS[id]["title"], _goal_text(String(id))])
			if int(st["kills"]) >= int(g["count"]):
				game.log_event("Return to %s." % SIDE_QUESTS[id]["giver"])
	var b: Dictionary = data["bounty"]
	if not b.is_empty() and String(b["target"]) == victim.display_name:
		if String(b["kind"]) == "hunt":
			b["done"] = int(b.get("done", 0)) + 1
			if int(b["done"]) >= int(b["count"]):
				_bounty_paid(b)
			else:
				game.log_event("Bounty: %d/%d %s." % [int(b["done"]), int(b["count"]), b["target"]])
		else:
			_bounty_paid(b)
	if depth > 1 and victim.kind == Entity.Kind.MONSTER and world.is_dungeon(world.to_tile(victim.position)):
		var bonus := randi_range(5, 15) * (depth - 1)
		hero.gold += bonus
		hero._pop("+%d gold (depth %d)" % [bonus, depth], Color(1.0, 0.85, 0.3))
		if victim == _depth_boss:
			data["deepest"] = maxi(deepest(), mini(depth + 1, DEPTHS.size()))
			game.count("depth_bosses")
			game.event_about("%s has fallen! %s" % [victim.display_name,
				"The way deeper lies open." if depth < DEPTHS.size() else "The Abyss is silent at last."], true)


func hud_text() -> String:
	var parts: Array[String] = []
	if depth > 1:
		parts.append("Dungeon level %d: %s" % [depth, DEPTHS[depth - 1]["name"]])
	var b: Dictionary = data["bounty"]
	if not b.is_empty():
		var extra := ""
		if String(b["kind"]) == "hunt":
			extra = " (%d/%d)" % [int(b.get("done", 0)), int(b["count"])]
		elif bounty_target != null and not bounty_target.dead:
			extra = " (%s)" % _where(bounty_target.position)
		parts.append("Bounty: %s%s" % [b["target"], extra])
	if hero.blade_poison_hits > 0:
		parts.append("Poisoned blade: %d" % hero.blade_poison_hits)
	if not duel.is_empty():
		var opp: Entity = duel["opp"]
		parts.append("Arena: %s %d/%d" % [opp.display_name, ceili(opp.hp), opp.stats.max_hp()])
	return ("\n" + "   ".join(parts)) if not parts.is_empty() else ""


## Marks on the minimap: towers in their guild's colours, the arena, the tavern, the landings and
## the elite you're hunting. Called from the minimap's _draw.
func draw_marks(mm) -> void:
	_draw_quest_marks(mm)
	for i in range(towers.size()):
		var tp: Vector2 = mm._to_map(world.tile_center(World.TOWER_TILES[i]))
		mm.draw_rect(Rect2(tp - Vector2(3.5, 3.5), Vector2(7, 7)), Color.BLACK)
		mm.draw_rect(Rect2(tp - Vector2(2.5, 2.5), Vector2(5, 5)), _guild_color(tower_owner(i)))
	var ap: Vector2 = mm._to_map(world.tile_center(ARENA))
	mm.draw_arc(ap, 4.0, 0.0, TAU, 12, Color(0.95, 0.75, 0.3), 1.5)
	var tvp: Vector2 = mm._to_map(world.tile_center(TAVERN))
	mm.draw_circle(tvp, 3.0, Color(0.0, 0.0, 0.0, 0.6))
	mm.draw_circle(tvp, 2.0, Color(0.95, 0.6, 0.2))
	for d in DOCKS:
		var dp: Vector2 = mm._to_map(world.tile_center(d["tile"]))
		mm.draw_rect(Rect2(dp - Vector2(1.5, 1.5), Vector2(3, 3)), Color(0.75, 0.55, 0.3))
	if bounty_target != null and is_instance_valid(bounty_target) and not bounty_target.dead:
		var bp: Vector2 = mm._to_map(bounty_target.position)
		mm.draw_circle(bp, 4.5, Color(0, 0, 0, 0.7))
		mm.draw_circle(bp, 3.2, Color(0.95, 0.15, 0.1))


# --- the panel -------------------------------------------------------------------------------

func _build_ui(layer: CanvasLayer) -> void:
	panel = game._make_overlay(layer)
	box = panel.get_meta("box")
	act_button = game._menu_button("", _on_act)
	act_button.custom_minimum_size = Vector2(320, 70)
	act_button.add_theme_font_size_override("font_size", 24)
	act_button.visible = false
	layer.add_child(act_button)
	act_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 16)
	act_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	act_button.offset_top -= 190.0
	act_button.offset_bottom -= 190.0


func open_hub() -> void:
	_open("hub")


func _open(p: String) -> void:
	page = p
	game.paused = true
	game.menu.visible = false
	panel.visible = true
	act_button.visible = false
	_refresh()


func _close() -> void:
	panel.visible = false
	talk_text = ""
	game._resume()


func _refresh() -> void:
	if not panel.visible:
		return
	for ch in box.get_children():
		box.remove_child(ch)
		ch.queue_free()
	match page:
		"hub":
			_page_hub()
		"talk":
			_page_talk()
		"quests":
			_page_quests()
		"tavern":
			_page_tavern()
		"board":
			_page_board()
		"dock":
			_page_dock()
		"stairs":
			_page_stairs()
		"arena":
			_page_arena()
		"bout":
			_page_bout()
		"cook":
			_page_cook()
		"alchemy":
			_page_alchemy()
		"house":
			_page_house()
		"towers":
			_page_towers()
		"farm":
			_page_farm()
		"journal":
			_page_journal()
		"enchant":
			_page_enchant()
		"auto":
			_page_auto()
		"church":
			_page_church()
		"tomb":
			_page_tomb()
	if page != "hub":
		_b("Adventures", _open.bind("hub"))
	_b("Close", _close)


func _page_hub() -> void:
	_h("Adventures")
	var b: Dictionary = data["bounty"]
	_t("Beyond the story: the Frostmarch in the north, the Sunscar Wastes in the south-east and the Blackwater Fen round the southern lake, each with its own creatures; three caves; the dungeon's depths; boats on the lakes; the tavern in Southmoor; the arena south of town; and the guild towers.")
	var active := 0
	for id in SIDE_QUESTS:
		if String(_sq(String(id))["state"]) == "active":
			active += 1
	_b("Journal: everything you're doing", _open.bind("journal"))
	_b("What Auto does: choose its errands", _open.bind("auto"))
	_b("Side quests (%d under way)" % active, _open.bind("quests"))
	_b("Bounties%s" % (": " + String(b["target"]) if not b.is_empty() else ""), _open.bind("board"))
	_b("The church", _open.bind("church"))
	_b("The tavern", _open.bind("tavern"))
	_b("Cooking", _open.bind("cook"))
	_b("Alchemy: brews and poisons", _open.bind("alchemy"))
	_b("Furnish your house", _open.bind("house"))
	_b("Your fields", _open.bind("farm"))
	_b("Enchant & set gems (at the forge)", _open.bind("enchant"))
	_b("The arena", _open.bind("arena"))
	_b("Guild towers", _open.bind("towers"))
	_b("The dungeon's depths (deepest: %d)" % deepest(), _open.bind("stairs"))
	var dk := _at_dock()
	if dk >= 0:
		dock_i = dk
		_b("Boat", _open.bind("dock"))
	else:
		_small_text("Boats: walk to a landing on one of the three lakes, or to Tidewater Harbour, south of Southmoor, for the voyage to the Isle of Tides (brown marks on the map).")


func _h(text: String) -> void:
	box.add_child(game._heading(text))


func _t(text: String) -> void:
	box.add_child(game._info(text))


func _small_text(text: String) -> void:
	box.add_child(game._small(text))


func _b(text: String, cb: Callable, enabled := true) -> void:
	var b: Button = game._action(text, cb, enabled)
	b.custom_minimum_size = Vector2(840, 64)
	b.add_theme_font_size_override("font_size", 22)
	b.clip_text = true
	box.add_child(b)


# --- Auto: the hero plays everything, a little of each ---------------------------------------
## On Auto the hero doesn't only fight, loot and gather: every minute or so, when nothing presses,
## it picks an errand - whichever kind it has gone longest without, weighted - walks there and
## does it: side quests (taking them, hunting or fetching for them, handing them in), bounties,
## cooking, brewing, the tavern, fishing from a boat, the arena, the dungeon's depths, the guild
## towers, its house, and now and then a look at a cave or a biome. In a fight it drinks a
## strength or agility potion and poisons its blade against tough foes, and it keeps itself fed.
const ERRANDS := {"story": 6.0, "world_boss": 2.5, "race": 0.8, "enchant": 0.8, "farm": 1.2, "quest": 3.0, "bounty": 2.0, "cook": 1.5, "brew": 1.0, "tavern": 1.0, "fishing": 1.0,
	"arena": 1.0, "depths": 1.0, "tower": 1.0, "house": 1.0, "explore": 0.7}
## Where a fetched item comes from: the creature that drops it.
const DROPPED_BY := {"swamp_herb": "Bog Leech", "scorpion_venom": "Sand Scorpion", "frost_pelt": "Frost Wolf"}
var errand := {}                           # {"kind", "dest", "who", "reach", "do", "until"}
var auto_last := {}                        # errand kind -> play time when last tried
var _auto_acc := 0.0
var _auto_wait := 40.0


func _now() -> float:
	return game.property.play_time


func _auto_tick(delta: float) -> void:
	if not hero.ai_enabled or hero.dead or hero.ghost or not sail.is_empty() or not duel.is_empty() or not race.is_empty():
		return
	_auto_acc += delta
	if _auto_acc < 0.5:
		return
	var step := _auto_acc
	_auto_acc = 0.0
	if auto_on("potions"):
		_auto_combat_aids()
	if auto_on("meals"):
		_auto_food()
	if hero.pause > 0.0 and errand.is_empty():
		return                                 # you tapped: hands off for a moment
	if not errand.is_empty():
		_errand_step()
		return
	_auto_wait -= step
	if armour_due and hero.target == null and not hero.has_journey:
		_auto_wait = 0.0                           # (better armour first)
	if _auto_wait > 8.0 and auto_on("story") and hero.target == null and not hero.has_journey \
			and not game.property.story_done and game.has_story_target \
			and hero.position.distance_to(game.story_target) > 3.0:
		_auto_wait = 0.0                           # (the main story waits for nobody: on with it)
	if _auto_wait > 0.0 or hero.target != null or hero.recovering or hero.retreating or hero.has_journey:
		return
	_auto_wait = randf_range(35.0, 60.0)
	_pick_errand()


func _pick_errand() -> void:
	if world.on_island(world.to_tile(hero.position)):
		if randf() < 0.3:                          # time to sail home from the isle
			_go("sail_home", world.tile_center(DOCKS[7]["tile"]), _sail.bind(7, false), null, 1.8)
		return
	if armour_due and _errand_armour():
		return                                     # (a couple of levels on: better armour, if there's any to be had)
	if auto_on("story") and _errand_story():
		auto_last["story"] = _now()
		return                                     # (the main story first, whenever it leads somewhere)
	var kinds: Array = ERRANDS.keys()
	kinds.erase("story")
	kinds.sort_custom(func(a, b) -> bool:
		return (_now() - float(auto_last.get(a, -1000.0))) * float(ERRANDS[a]) > (_now() - float(auto_last.get(b, -1000.0))) * float(ERRANDS[b]))
	for k in kinds:
		if not auto_on(String(k)):
			continue                               # switched off in the Auto settings
		auto_last[k] = _now()
		var started := false
		match String(k):
			"story":
				started = _errand_story()
			"quest":
				started = _errand_quest()
			"bounty":
				started = _errand_bounty()
			"cook":
				started = _errand_cook()
			"brew":
				started = _errand_brew()
			"tavern":
				started = _errand_tavern()
			"fishing":
				started = _errand_fishing()
			"arena":
				started = _errand_arena()
			"depths":
				started = _errand_depths()
			"tower":
				started = _errand_tower()
			"house":
				started = _errand_house()
			"explore":
				started = _errand_explore()
			"farm":
				started = _errand_farm()
			"enchant":
				started = _errand_enchant()
			"race":
				started = _errand_race()
			"world_boss":
				started = _errand_world_boss()
		if started:
			return


## Sets off on an errand: walk to `dest` (or after `who`, who may move) and then call `then`.
func _go(kind: String, dest: Vector3, then: Callable, who: Entity = null, reach := 2.2) -> bool:
	errand = {"kind": kind, "dest": dest, "who": who, "reach": reach, "do": then, "until": _now() + 180.0}
	return true


func _errand_step() -> void:
	if _now() > float(errand["until"]):
		errand = {}
		return
	var dest: Vector3 = errand["dest"]
	var wv: Variant = errand["who"]
	if wv != null:
		if not is_instance_valid(wv) or (wv as Entity).dead:
			errand = {}
			return
		dest = (wv as Entity).position
		errand["dest"] = dest
	if Vector2(hero.position.x - dest.x, hero.position.z - dest.z).length() <= float(errand["reach"]):
		var then: Callable = errand["do"]
		errand = {}
		hero.has_journey = false
		hero.path.clear()
		then.call()
		return
	if hero.target == null and hero.loot_target == null and not hero.recovering and not hero.retreating \
			and hero.pause <= 0.0:                 # (never cut short a fight or the looting of a corpse)
		if not hero.has_journey or hero.journey.distance_to(dest) > 2.5:
			hero.set_journey(dest)
			if String(errand["kind"]) == "story":
				hero.journey_direct = true         # (the story: straight there, no detours)
	hero.roam_timer = maxf(hero.roam_timer, 30.0)   # don't wander off to another region meanwhile


func _nearest_named(n: String) -> Entity:
	var best: Entity = null
	var best_d := INF
	for item in game.creatures:
		var e := item as Entity
		if e.dead or e.kind == Entity.Kind.NPC or e.display_name != n or e.parked:
			continue
		var d := e.position.distance_to(hero.position)
		if d < best_d:
			best = e
			best_d = d
	return best


## A fight the hero can take on: not far stronger than it is.
func _can_take(e: Entity) -> bool:
	return e != null and e.threat() <= hero.power() + 1.0


func _hunt(kind: String, n: String) -> bool:
	var e := _nearest_named(n)
	if e == null or not _can_take(e):
		return false
	return _go(kind, e.position, _engage.bind(e), e, 6.0)


func _engage(e: Entity) -> void:
	if is_instance_valid(e) and not e.dead:
		hero.target = e


## The seasoned hero (the "Seasoned hero" experiment): every couple of levels the hero (on Auto)
## looks for better armour - the best it's strong enough for and can afford (a mage keeps off
## metal, which stops Meditation) - puts it on at once if it's in the bag, or goes to the nearest
## merchant to buy it.
var armour_due := false
var _armour_level := 0
const ARMOUR_TIERS := ["platemail", "chainmail", "studded_armor", "leather_armor"]


func check_armour_level(lv: int) -> void:
	if not Experiments.on("seasoned"):
		return
	if _armour_level == 0:
		_armour_level = lv
	elif lv >= _armour_level + 2:
		_armour_level = lv
		armour_due = true


func _nearest_merchant() -> Entity:
	var best: Entity = null
	var best_d := INF
	for item in game.creatures:
		var e := item as Entity
		if e.shop == null or e.dead:
			continue
		var d := e.position.distance_to(hero.position)
		if d < best_d:
			best = e
			best_d = d
	return best


func _armour_upgrade(m: Entity) -> String:
	var cur := 0.0
	if hero.armor_id != "":
		cur = float(Gear.stats(hero.armor_id).get("rating", 0.0))
	var mage := hero._skill(Hero.Skill.MAGERY) > hero._skill(hero._weapon_skill())
	var purse: int = hero.gold + int(game.property.bank_gold)
	for id: String in ARMOUR_TIERS:
		var g: Dictionary = Gear.stats(id)
		if float(g["rating"]) <= cur or (mage and bool(g.get("metal", false))) or hero.stats.eff_str() < int(g.get("str", 0)):
			continue
		if hero.inventory.has(id):
			return id
		if m != null and purse >= m.shop.price(Items.value(id)) + 40:
			return id
	return ""


func _errand_armour() -> bool:
	armour_due = false
	var m := _nearest_merchant()
	var id := _armour_upgrade(m)
	if id == "":
		return false
	if hero.inventory.has(id):
		hero._equip(id)
		game.log_event("A couple of levels stronger, you put on your %s." % Gear.stats(id)["name"])
		return false
	return _go("armour", m.position, _auto_buy_armour.bind(m, id), m, 2.5)


func _auto_buy_armour(m: Entity, id: String) -> void:
	if m == null or not is_instance_valid(m) or m.shop == null:
		return
	var cost: int = m.shop.price(Items.value(id))
	if hero.gold + game.property.bank_gold < cost:
		return
	var from_purse := mini(hero.gold, cost)
	hero.gold -= from_purse
	game.property.bank_gold -= cost - from_purse
	m.shop.take_payment(cost)
	hero.inventory[id] = int(hero.inventory.get(id, 0)) + 1
	hero._equip(id)
	game.log_event("A couple of levels stronger, you buy %s from %s for %d gold and put it on." % [Gear.stats(id)["name"], m.display_name, cost])


## The main story: off to wherever it leads now (the person to see, a shrine, the lair, the Broken
## Circle), straight there; the chapter moves on by itself on arrival (or once the foe falls).
func _errand_story() -> bool:
	if game.property.story_done or not game.property.story_started or not game._story_goal_pos():
		return false
	var dest: Vector3 = game.story_target
	var who: Entity = null
	var step: Dictionary = Story.STEPS[game.property.story_step]
	match String(step["kind"]):
		"talk":
			who = _nearest_named(String(step["who"]))
		"kill", "boss":                            # (the one to slay: after it, and at it)
			var foe: Entity = game.story_boss if String(step["kind"]) == "boss" else _nearest_named(String(step["target"]))
			if foe != null and is_instance_valid(foe) and not foe.dead:
				return _go("story", foe.position, _engage.bind(foe), foe, 6.0)
	if hero.position.distance_to(dest) < 3.0:
		return false
	return _go("story", dest, func() -> void:
		_auto_wait = 3.0, who, 2.5)                # (and soon after, the next chapter's errand)


# side quests: take one, work at it, hand it in
func _errand_quest() -> bool:
	var active := 0
	for id in SIDE_QUESTS:
		if String(_sq(String(id))["state"]) == "active":
			active += 1
	for v in villagers:
		var e: Entity = v["e"]
		var id := _quest_now(e.display_name)
		if id == "":
			continue
		var st := String(_sq(id)["state"])
		if st == "active" and _goal_done(id):
			return _go("quest", e.position, _auto_talk.bind(e.display_name, id), e, 2.5)
		if st != "active" and active < 2:
			return _go("quest", e.position, _auto_talk.bind(e.display_name, id), e, 2.5)
	for id in SIDE_QUESTS:                     # under way: go and get it done
		if String(_sq(String(id))["state"]) != "active" or _goal_done(String(id)):
			continue
		var g: Dictionary = SIDE_QUESTS[id]["goal"]
		if String(g["kind"]) == "kill":
			if _hunt("quest", String(g["target"])):
				return true
		elif DROPPED_BY.has(String(g["item"])):
			if _hunt("quest", String(DROPPED_BY[String(g["item"])])):
				return true
		elif String(g["item"]) == "ale":
			return _errand_tavern()
		elif String(g["item"]) == "pearl":
			return _errand_fishing()
	return false


func _auto_talk(giver: String, id: String) -> void:
	talk_with = giver
	var q: Dictionary = SIDE_QUESTS[id]
	if String(_sq(id)["state"]) == "active":
		if not _goal_done(id):
			return
		for i in range(q["turn_in"].size()):
			var ch: Dictionary = q["turn_in"][i]
			if String(ch.get("go", "")) == "stay":
				continue
			var ok := true
			var take: Dictionary = ch.get("take", {})
			for item in take:
				ok = ok and _has(String(item), int(take[item]))
			if ok:
				_turn_in(id, i)
				return
		return
	for i in range(q["choices"].size()):
		if String(q["choices"][i].get("go", "")) == "accept":
			_choose(id, i)
			return


# bounties: take one at a board, then hunt it down
func _errand_bounty() -> bool:
	var b: Dictionary = data["bounty"]
	if b.is_empty():
		return _go("bounty", world.tile_center(_nearest_board()), _auto_take_bounty)
	match String(b["kind"]):
		"elite":
			if bounty_target != null and is_instance_valid(bounty_target) and not bounty_target.dead and _can_take(bounty_target):
				return _go("bounty", bounty_target.position, _engage.bind(bounty_target), bounty_target, 6.0)
		_:
			return _hunt("bounty", String(b["target"]))
	return false


func _auto_take_bounty() -> void:
	if data["board"].is_empty() or _now() - float(data.get("board_at", -1.0e9)) > DAY:
		_new_board()
	var best := -1
	for i in range(data["board"].size()):
		var o: Dictionary = data["board"][i]
		var ok := false
		match String(o["kind"]):
			"hunt":
				var e := _nearest_named(String(o["target"]))
				ok = e != null and _can_take(e)
			"elite":
				ok = float(_cfg_of(String(o.get("base", "Orc"))).get("danger", 2)) + 2.0 <= hero.power()
			"outlaw":
				ok = hero.power() >= 4.0
		if ok:
			best = i
			break
	if best >= 0:
		_take_bounty(best)


# cooking: light a fire if need be, cook what there is
func _errand_cook() -> bool:
	var any := false
	for id in RECIPE_ORDER:
		var r: Dictionary = RECIPES[id]
		if hero._skill(Hero.Skill.COOKING) >= float(r["min"]) and Crafting.has_mats(hero.inventory, r["mats"]):
			any = true
	if not any:
		return false
	if not _can_cook_here():
		if not _has("log"):
			return false
		_make_fire()
	for _n in range(4):
		var made := false
		for id in RECIPE_ORDER:
			var r2: Dictionary = RECIPES[id]
			if hero._skill(Hero.Skill.COOKING) >= float(r2["min"]) and Crafting.has_mats(hero.inventory, r2["mats"]):
				_cook(String(id))
				made = true
				break
		if not made:
			break
	return true


# brewing: a strength or agility potion, a blade poison, while the makings last
func _errand_brew() -> bool:
	for id in BREWS:
		if int(hero.inventory.get(id, 0)) < 2 and hero.craft_problem(String(id)) == "":
			hero.craft(String(id))
			return true
	return false


# the tavern: a meal, a bed at night, the talk of the room, an ale for the minstrel
func _errand_tavern() -> bool:
	if hero.gold < 40:
		return false
	return _go("tavern", world.tile_center(TAVERN) + Vector3(0, 0, 1.2), _auto_tavern)


func _auto_tavern() -> void:
	var tam := String(_sq("tam_song")["state"])
	if tam == "active" and not _has("ale") and hero.gold >= 4:
		_tavern_buy("ale", 4)
	if hero.hp < float(hero.stats.max_hp()) * 0.8 and hero.gold >= 60:
		_tavern_meal()
	if game.is_night() and hero.gold >= 80:
		_tavern_room()
	if hero.gold >= 20:
		_tavern_rumour()


# fishing from a boat (buying the boat and a pole when there's gold to spare), or the ferry
func _errand_fishing() -> bool:
	var best := 0
	for i in range(LAKE_DOCKS):                     # the lakes only: the sea voyage is yours to choose
		if world.tile_center(DOCKS[i]["tile"]).distance_to(hero.position) < world.tile_center(DOCKS[best]["tile"]).distance_to(hero.position):
			best = i
	if not bool(data.get("boat", false)) and hero.gold < BOAT_PRICE + 150:
		return false
	return _go("fishing", world.tile_center(DOCKS[best]["tile"]), _auto_dock.bind(best), null, 1.8)


func _auto_dock(i: int) -> void:
	if not bool(data.get("boat", false)) and hero.gold >= BOAT_PRICE + 150:
		_buy_boat()
	if not _has("fishing_pole") and hero.gold >= POLE_PRICE + 50:
		_buy_pole()
	if bool(data.get("boat", false)) and _has("fishing_pole"):
		_sail(i, true)
	else:
		_sail(i, false)


# the arena: the hardest champion it can beat, when the fee is easily spared
func _errand_arena() -> bool:
	var pick := -1
	for i in range(ARENA_TIERS.size()):
		var t: Dictionary = ARENA_TIERS[i]
		if float(t["danger"]) <= hero.power() and hero.gold >= int(t["fee"]) + 150:
			pick = i
	if pick < 0:
		return false
	_arena_bet = 0
	return _go("arena", world.tile_center(ARENA), _start_duel.bind(pick), null, 3.0)


# the depths: down the stairs as deep as it can safely go
func _errand_depths() -> bool:
	var d := clampi(int(hero.power()) - 5, 0, deepest())
	if d < 2:
		return false
	return _go("depths", world.tile_center(STAIRS), _go_depth.bind(d), null, 1.8)


# the guild towers: stand on one that isn't your guild's until it falls
func _errand_tower() -> bool:
	var g := hero.guild_id()
	if g == "":
		return false
	for i in range(TOWERS.size()):
		var o := tower_owner(i)
		if o != g and not game.guilds.allied(g, o):
			return _go("tower", world.tile_center(World.TOWER_TILES[i] + Vector2i(0, 1)), _hold_tower, null, 2.0)
	return false


func _hold_tower() -> void:
	hero.pause = CAPTURE_SECS + 4.0            # stays put (and fights anyone who comes) till it's taken


# home: sleep, the garden, the books, and a new piece of furniture when there's gold
func _errand_house() -> bool:
	if not game.property.has_house():
		return false
	return _go("house", world.tile_center(game.property.house_center_tile()), _auto_home, null, 1.2)


func _auto_home() -> void:
	if _decor_has("bed") and (game.is_night() or hero.hp < float(hero.stats.max_hp()) * 0.6) and _now() - float(data.get("rest_at", -1.0e9)) > 120.0:
		_rest()
	if _decor_has("garden") and _now() - float(data.get("garden_at", -1.0e9)) > DAY:
		_garden()
	if _decor_has("bookshelf") and _now() - float(data.get("study_at", -1.0e9)) > DAY:
		_study()
	if data["decor"].size() < _decor_slots():
		for id in DECOR_ORDER:
			var d: Dictionary = DECOR[id]
			if _decor_has(String(id)):
				continue
			if d.has("trophy"):
				if _killed(String(d["trophy"])):
					_buy_decor(String(id))
					return
			elif hero.gold >= int(d["price"]) + 400:
				_buy_decor(String(id))
				return


# a look at a cave or one of the biomes
func _errand_explore() -> bool:
	var spots: Array[Vector2i] = []
	for cave in World.CAVES:
		spots.append(cave["out"])
	for k in World.BIOMES:
		spots.append((World.BIOMES[k] as Rect2i).get_center())
	var t: Vector2i = spots[randi() % spots.size()]
	t = _spot(t)
	game.log_event("Your hero sets off to see %s." % world.place_name(t) if world.place_name(t) != "" else "Your hero sets off exploring.")
	return _go("explore", world.tile_center(t), func() -> void: pass, null, 2.5)


# in a fight: potions and blade poison against tough foes; invisibility to escape
func _auto_combat_aids() -> void:
	var t := hero.target
	if t != null and is_instance_valid(t) and not t.dead and t.kind == Entity.Kind.MONSTER:
		if t.is_boss or t.threat() >= hero.power() - 0.5:
			if _has("potion_strength") and not hero.effects.has("potion_strength"):
				_use_brew("potion_strength")
			elif _has("potion_agility") and not hero.effects.has("potion_agility"):
				_use_brew("potion_agility")
			if hero.blade_poison_hits <= 0 and hero.weapon != "" and not Gear.is_ranged(hero.weapon):
				if _has("poison_deadly"):
					_use_brew("poison_deadly")
				elif _has("poison_lesser"):
					_use_brew("poison_lesser")
	if hero.retreating and hero.hp < float(hero.stats.max_hp()) * 0.25 and _has("potion_invisibility") \
			and not hero.flags.has("invisible"):
		_use_brew("potion_invisibility")


# keep fed: a cooked meal when hungry for strength or hurt, out of a fight
func _auto_food() -> void:
	if hero.target != null:
		return
	var hurt := hero.hp < float(hero.stats.max_hp()) * 0.5
	if hero.effects.has("well_fed") and not hurt:
		return
	var best := ""
	for id in RECIPE_ORDER:
		if _has(String(id)) and MEALS.has(id) and (hurt or float(MEALS[id]["secs"]) > 0.0):
			best = String(id)                  # the order runs plain to rich: the last one held is best
	if best != "":
		_eat(best)


# --- the seasons -------------------------------------------------------------------------------
## Spring, summer, autumn and winter, three days each. The ground and the trees take their colours
## (green, golden, russet, frosted), snow lies in winter and the rain falls as snow; crops grow
## fastest in summer and not at all in winter.
const SEASONS := ["spring", "summer", "autumn", "winter"]
const SEASON_DAYS := 3
const SEASON_LOOK := {
	"spring": {"ground": Color(1.0, 1.05, 0.95), "leaves": Color(0.95, 1.08, 0.92), "snow": 0.0, "frost": 0.0},
	"summer": {"ground": Color(1.06, 1.02, 0.85), "leaves": Color(1.0, 1.0, 0.88), "snow": 0.0, "frost": 0.0},
	"autumn": {"ground": Color(1.12, 0.95, 0.72), "leaves": Color(1.4, 0.82, 0.42), "snow": 0.0, "frost": 0.0},
	"winter": {"ground": Color(0.94, 0.97, 1.06), "leaves": Color(0.85, 0.9, 0.96), "snow": 0.8, "frost": 0.55},
}
const SEASON_NEWS := {
	"spring": "Spring comes: the snow melts and the fields wake.",
	"summer": "Summer comes: long golden days, and the crops grow fast.",
	"autumn": "Autumn comes: the leaves turn red and gold.",
	"winter": "Winter comes: snow on the land, and nothing grows in the fields.",
}
var _season_acc := 0.0
var _season_seen := ""
var _look := {"ground": Color(1, 1, 1), "leaves": Color(1, 1, 1), "snow": 0.0, "frost": 0.0}


func season_index() -> int:
	return int(game.property.play_time / (DAY * SEASON_DAYS)) % SEASONS.size()


func season() -> String:
	return String(SEASONS[season_index()])


## "Day 7 of autumn" for the clock.
func season_text() -> String:
	var day := int(fmod(game.property.play_time, DAY * SEASON_DAYS) / DAY) + 1
	return "%s, day %d" % [season().capitalize(), day]


func _season_tick(step: float) -> void:
	var s := season()
	if s != _season_seen:
		if _season_seen != "":
			game.log_event(String(SEASON_NEWS[s]))
		else:
			_look = (SEASON_LOOK[s] as Dictionary).duplicate()   # straight to it at start
		_season_seen = s
	var want: Dictionary = SEASON_LOOK[s]
	var k := minf(1.0, step / 20.0)                  # the change creeps over twenty seconds
	var cg: Color = _look["ground"]
	var cl: Color = _look["leaves"]
	_look["ground"] = cg.lerp(want["ground"], k)
	_look["leaves"] = cl.lerp(want["leaves"], k)
	_look["snow"] = lerpf(float(_look["snow"]), float(want["snow"]), k)
	_look["frost"] = lerpf(float(_look["frost"]), float(want["frost"]), k)
	var g: Color = _look["ground"]
	var l: Color = _look["leaves"]
	if world.ground_material != null:
		world.ground_material.set_shader_parameter("season_tint", Vector3(g.r, g.g, g.b))
		world.ground_material.set_shader_parameter("snow", float(_look["snow"]))
	var fm := World._foliage_mat()
	fm.set_shader_parameter("season_tint", Vector3(l.r, l.g, l.b))
	fm.set_shader_parameter("frost", float(_look["frost"]))


## In winter the rain falls as snow.
func snowing() -> bool:
	return season() == "winter" and game.weather in ["rain", "storm"]


# --- farming ---------------------------------------------------------------------------------
## Fields by your house: plant wheat, carrots or pumpkins (seed bought here), and they grow with
## the seasons - fastest in summer, slowest in autumn, not at all in winter. Farming skill makes the
## harvest bigger. Wheat bakes into bread, carrots into stew, pumpkins into pie.
const CROPS := {
	"wheat": {"name": "Wheat", "seed": 5, "secs": 240.0, "yield": 3, "color": Color(0.9, 0.78, 0.35)},
	"carrot": {"name": "Carrots", "seed": 8, "secs": 360.0, "yield": 3, "color": Color(0.95, 0.5, 0.15)},
	"pumpkin": {"name": "Pumpkins", "seed": 15, "secs": 600.0, "yield": 2, "color": Color(0.95, 0.55, 0.1)},
}
const CROP_ORDER := ["wheat", "carrot", "pumpkin"]
const GROWTH := {"spring": 1.0, "summer": 1.4, "autumn": 0.8, "winter": 0.0}
const PLOTS := 4
var _farm_node: Node3D
var _farm_key := ""


func _plots() -> Array:
	if not data.has("farm") or not (data["farm"] is Array):
		data["farm"] = []
	var f: Array = data["farm"]
	while f.size() < PLOTS:
		f.append({"crop": "", "growth": 0.0})
	return f


## Where the fields lie: open ground round the house, two tiles out.
func _plot_tiles() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var pr: Property = game.property
	if not pr.has_house():
		return out
	var o := pr.house_origin
	var n := pr.house_size
	var door_out := World.house_door(o, n) + Vector2i(0, 1)
	for ring in range(2, 5):
		for y in range(o.y - ring, o.y + n + ring):
			for x in range(o.x - ring, o.x + n + ring):
				var t := Vector2i(x, y)
				var edge := x == o.x - ring or y == o.y - ring or x == o.x + n + ring - 1 or y == o.y + n + ring - 1
				if not edge or world.is_blocked(t) or world.is_town(t) or absi(t.x - door_out.x) <= 1 and t.y >= door_out.y:
					continue
				out.append(t)
				if out.size() >= PLOTS:
					return out
	return out


func _farm_tick(step: float) -> void:
	if not game.property.has_house():
		return
	var rate: float = GROWTH[season()]
	var key := ""
	for p in _plots():
		var crop := String(p["crop"])
		if crop != "" and rate > 0.0:
			p["growth"] = minf(1.0, float(p["growth"]) + step * rate / float(CROPS[crop]["secs"]))
		key += "%s%d," % [crop, int(float(p["growth"]) * 3.0)]
	key += str(game.property.house_origin)
	if key != _farm_key:
		_farm_key = key
		_build_fields()


func _build_fields() -> void:
	if _farm_node != null:
		_farm_node.queue_free()
		_farm_node = null
	var tiles := _plot_tiles()
	if tiles.is_empty():
		return
	_farm_node = Node3D.new()
	add_child(_farm_node)
	var plots := _plots()
	for i in range(mini(tiles.size(), PLOTS)):
		var p: Dictionary = plots[i]
		var parts := [[Art.box(0.9, 0.06, 0.9), Art.at(0, 0.03, 0), Color(0.33, 0.22, 0.12)]]
		for r in range(3):
			parts.append([Art.box(0.85, 0.04, 0.08), Art.at(0, 0.07, -0.3 + r * 0.3), Color(0.26, 0.17, 0.09)])
		var crop := String(p["crop"])
		if crop != "":
			var g := float(p["growth"])
			var col: Color = CROPS[crop]["color"]
			var green := Color(0.3, 0.6, 0.22)
			for r in range(3):
				for c in range(3):
					var at := Art.at(-0.3 + c * 0.3, 0.07, -0.3 + r * 0.3)
					match crop:
						"wheat":
							var hgt := 0.1 + 0.45 * g
							parts.append([Art.box(0.05, hgt, 0.05), at * Art.at(0, hgt / 2.0, 0), green.lerp(col, smoothstep(0.6, 1.0, g))])
							if g >= 0.95:
								parts.append([Art.box(0.08, 0.12, 0.08), at * Art.at(0, hgt, 0), col])
						"carrot":
							parts.append([Art.cone(0.05 + 0.05 * g, 0.12 + 0.18 * g, 0.0, 5), at * Art.at(0, 0.08 + 0.09 * g, 0), green])
						"pumpkin":
							parts.append([Art.ball(0.04 + 0.04 * g), at * Art.at(0, 0.05, 0), green])
							if g > 0.3 and (r + c) % 2 == 0:
								parts.append([Art.ball(0.05 + 0.12 * g, 8, 5), at * Art.at(0, 0.06 + 0.06 * g, 0), green.lerp(col, smoothstep(0.4, 1.0, g))])
		_mesh(parts, world.tile_center(tiles[i]), _farm_node)


func _page_farm() -> void:
	_h("Your fields   (Farming %.1f)" % hero._skill(Hero.Skill.FARMING))
	if not game.property.has_house():
		_t("Fields lie round a house. Buy a deed at the bank (Bank & House) and place it out in the wilds first.")
		return
	var at_home: bool = game._hero_at_house() or _near(game.property.house_center_tile(), 6.0)
	_t("It is %s. Crops grow %s." % [season_text(), {"spring": "well", "summer": "fast", "autumn": "slowly", "winter": "not at all: the ground is frozen"}[season()]])
	if not at_home:
		_b("Walk home", _walk_to.bind(game.property.house_center_tile()))
	var plots := _plots()
	for i in range(PLOTS):
		var p: Dictionary = plots[i]
		var crop := String(p["crop"])
		if crop == "":
			_small_text("Field %d: bare earth." % (i + 1))
			for c in CROP_ORDER:
				var cd: Dictionary = CROPS[c]
				_b("Plant %s (%d gold)" % [cd["name"], int(cd["seed"])], _plant.bind(i, String(c)), at_home and hero.gold >= int(cd["seed"]))
		elif float(p["growth"]) >= 1.0:
			_small_text("Field %d: %s, ripe!" % [i + 1, CROPS[crop]["name"]])
			_b("Harvest the %s" % String(CROPS[crop]["name"]).to_lower(), _harvest.bind(i), at_home)
		else:
			_small_text("Field %d: %s, %d%% grown." % [i + 1, CROPS[crop]["name"], roundi(float(p["growth"]) * 100.0)])


func _plant(i: int, crop: String) -> void:
	if not _pay(int(CROPS[crop]["seed"])):
		return
	var p: Dictionary = _plots()[i]
	p["crop"] = crop
	p["growth"] = 0.0
	hero.stats.try_gain(Hero.Skill.FARMING)
	game.log_event("You sow %s." % String(CROPS[crop]["name"]).to_lower())
	_refresh()


func _harvest(i: int) -> void:
	var p: Dictionary = _plots()[i]
	var crop := String(p["crop"])
	if crop == "" or float(p["growth"]) < 1.0:
		return
	var n := int(CROPS[crop]["yield"]) + int(hero._skill(Hero.Skill.FARMING) / 34.0)
	_give(crop, n)
	hero.stats.try_gain(Hero.Skill.FARMING)
	p["crop"] = ""
	p["growth"] = 0.0
	game.count("harvests")
	game.log_event("You harvest %d %s." % [n, Items.item_name(crop).to_lower()])
	_refresh()


## Auto: go home to harvest what's ripe and sow the bare fields (not in winter).
func _errand_farm() -> bool:
	if not game.property.has_house():
		return false
	var work := false
	for p in _plots():
		if String(p["crop"]) != "" and float(p["growth"]) >= 1.0:
			work = true
		elif String(p["crop"]) == "" and season() != "winter" and hero.gold >= 60:
			work = true
	if not work:
		return false
	return _go("farm", world.tile_center(game.property.house_center_tile()), _auto_farm, null, 3.0)


func _auto_farm() -> void:
	var plots := _plots()
	for i in range(PLOTS):
		var p: Dictionary = plots[i]
		if String(p["crop"]) != "" and float(p["growth"]) >= 1.0:
			_harvest(i)
		if String(p["crop"]) == "" and season() != "winter":
			var pick := String(CROP_ORDER[i % CROP_ORDER.size()])
			if hero.gold >= int(CROPS[pick]["seed"]) + 50:
				_plant(i, pick)


# --- the journal and the quest marks on the map --------------------------------------------
## Gold "!" over townsfolk with work for you, green "?" over those waiting for what you bring, and
## a small orange ring on the nearest creature a task asks you to slay.
func _draw_quest_marks(mm) -> void:
	var font := ThemeDB.fallback_font
	for v in villagers:
		var e: Entity = v["e"]
		var mark := _talk_mark(e.display_name).strip_edges()
		if mark == "":
			continue
		var p: Vector2 = mm._to_map(e.position)
		var col := Color(0.4, 1.0, 0.45) if mark == "(?)" else Color(1.0, 0.85, 0.3)
		var ch := "?" if mark == "(?)" else "!"
		mm.draw_circle(p, 5.0, Color(0, 0, 0, 0.75))
		mm.draw_string(font, p + Vector2(-3.0, 5.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	for id in SIDE_QUESTS:
		var st: Dictionary = _sq(String(id))
		var g: Dictionary = SIDE_QUESTS[id]["goal"]
		if String(st["state"]) != "active" or _goal_done(String(id)):
			continue
		var want := String(g.get("target", DROPPED_BY.get(String(g.get("item", "")), "")))
		if want == "":
			continue
		var e2 := _nearest_named(want)
		if e2 != null:
			mm.draw_arc(mm._to_map(e2.position), 4.0, 0.0, TAU, 12, Color(1.0, 0.6, 0.2), 1.5)
	var b: Dictionary = data["bounty"]
	if not b.is_empty() and String(b["kind"]) != "elite":
		var e3 := _nearest_named(String(b["target"]))
		if e3 != null:
			mm.draw_arc(mm._to_map(e3.position), 4.5, 0.0, TAU, 12, Color(0.95, 0.2, 0.15), 1.5)


## Everything under way in one list: the story, the captain's quest, side quests, the bounty, the
## arena, the depths, the towers, the fields - each with a way to walk there.
func _page_journal() -> void:
	_h("Journal")
	var pr: Property = game.property
	_small_text(season_text() + ".   Gold %d, bank %d." % [hero.gold, pr.bank_gold])
	_h("The story")
	if pr.story_done:
		_t("The Shattered Sight: done. You are the Shardbearer.")
	else:
		var st: Dictionary = Story.STEPS[pr.story_step]
		_t("%s - %s" % [st["title"], st["goal"]])
		if game.has_story_target:
			_b("Walk there (violet mark on the map)", _walk_to.bind(world.to_tile(game.story_target)))
	_h("The captain's work")
	_t(String(game._quest_text()).trim_prefix("Quest: "))
	_h("Side quests")
	var any := false
	for id in SIDE_QUESTS:
		var sid := String(id)
		var q: Dictionary = SIDE_QUESTS[id]
		var state := String(_sq(sid)["state"])
		if state != "active":
			continue
		any = true
		var giver := String(q["giver"])
		if _goal_done(sid):
			_t("%s: done - return to %s (green ? on the map)." % [q["title"], giver])
			_b("Walk to %s" % giver, _walk_to_villager.bind(giver))
		else:
			_t("%s (%s): %s." % [q["title"], giver, _goal_text(sid)])
			var g: Dictionary = q["goal"]
			var want := String(g.get("target", DROPPED_BY.get(String(g.get("item", "")), "")))
			var e: Entity = _nearest_named(want) if want != "" else null
			if e != null:
				_b("Walk towards the nearest %s (orange ring)" % want, _walk_to.bind(world.to_tile(e.position)))
	var offers: Array[String] = []
	for v in villagers:
		var n := (v["e"] as Entity).display_name
		if _talk_mark(n) == " (!)":
			offers.append(n)
	if not any:
		_small_text("None under way.")
	if not offers.is_empty():
		_small_text("Work on offer (gold ! on the map): " + ", ".join(offers) + ".")
	_h("Bounty")
	var b: Dictionary = data["bounty"]
	if b.is_empty():
		_small_text("None taken. The boards stand in every town.")
	else:
		_t(String(b["text"]))
		var tgt := bounty_target if String(b["kind"]) == "elite" else _nearest_named(String(b["target"]))
		if tgt != null and is_instance_valid(tgt) and not tgt.dead:
			_b("Walk towards it (%s)" % _where(tgt.position), _walk_to.bind(world.to_tile(tgt.position)))
	_h("Elsewhere")
	_small_text("Arena wins: %d.   The depths: deepest level %d.   Your boat: %s." % [_i("arena_wins"), deepest(), "yes" if bool(data.get("boat", false)) else "none"])
	var g2 := hero.guild_id()
	if g2 != "":
		var held: Array[String] = []
		for i in range(TOWERS.size()):
			if tower_owner(i) == g2:
				held.append(String(TOWERS[i]["name"]))
		_small_text("Your guild holds: %s." % (", ".join(held) if not held.is_empty() else "no towers"))
	if pr.has_house():
		var ripe := 0
		for p in _plots():
			if String(p["crop"]) != "" and float(p["growth"]) >= 1.0:
				ripe += 1
		_small_text("Your fields: %d ripe for the harvest." % ripe)


# --- enchanting and gem sockets (at the forge) -------------------------------------------------

## The gear you could work on: what you wear, then what's in the bag.
func _workable() -> Array[String]:
	var out: Array[String] = []
	for sl in ["weapon", "armor", "shield"]:
		var id: String = hero._equipped_id(sl)
		if id != "":
			out.append(id)
	for id in hero.inventory:
		if Gear.has(String(id)) and out.size() < 14 and not out.has(String(id)):
			out.append(String(id))
	return out


func _page_enchant() -> void:
	_h("Enchanting and gems")
	var here: bool = world.near_forge(hero.position)
	_t("At the forge in the smith's house: enchant a weapon, armour or shield with cave crystals (each level +8% damage or armour, up to +3; it may fail and the crystals are lost), or set one gem in it (a ruby lends strength, a sapphire intelligence, an emerald dexterity, a diamond a little of each). Crystals %d.  Gems: %s." % [
		int(hero.inventory.get("cave_crystal", 0)), _gems_held_text()])
	if not here:
		_b("Walk to the forge", _walk_to.bind(world.forge_tile + Vector2i(0, 1)))
	for id in _workable():
		var lv := Gems.enchant_level(id)
		var worn := id == hero.weapon or id == hero.armor_id or id == hero.shield_id
		_small_text("%s%s" % [Items.item_name(id), "  (worn)" if worn else ""])
		if lv < Gems.MAX_ENCHANT:
			var need := lv + 1
			var gold := Gems.ENCHANT_GOLD * need
			_b("Enchant to +%d: %d crystal%s, %d gold (%d%%)" % [need, need, "" if need == 1 else "s", gold,
				roundi(_enchant_chance(lv) * 100.0)], _enchant.bind(id), here and _has("cave_crystal", need) and hero.gold >= gold)
		if Gems.gem_of(id) == "":
			for gem in Gems.GEMS:
				if _has(String(gem)):
					_b("Set the %s (%s)" % [Gems.GEMS[gem]["name"], Gems.describe_mods(Gems.GEMS[gem]["mods"])], _socket.bind(id, String(gem)), here)


func _gems_held_text() -> String:
	var parts: Array[String] = []
	for gem in Gems.GEMS:
		if _has(String(gem)):
			parts.append("%s x%d" % [Gems.GEMS[gem]["name"], int(hero.inventory[gem])])
	return ", ".join(parts) if not parts.is_empty() else "none"


func _enchant_chance(lv: int) -> float:
	return minf(0.98, float(Gems.ENCHANT_CHANCE[lv]) + hero._skill(Hero.Skill.MAGERY) / 400.0 + hero._skill(Hero.Skill.BLACKSMITHY) / 400.0)


## Swaps a piece of gear for its improved self, wherever it is (worn or in the bag).
func _replace_gear(old: String, new_id: String) -> void:
	if hero.weapon == old:
		hero.weapon = new_id
	elif hero.armor_id == old:
		hero.armor_id = new_id
	elif hero.shield_id == old:
		hero.shield_id = new_id
	else:
		_take(old)
		_give(new_id)
	if hero.wear.has(old):                          # it keeps its wear
		hero.wear[new_id] = hero.wear[old]
		hero.wear.erase(old)
	hero.refresh_look()
	hero._recompute_effects()


func _enchant(id: String) -> void:
	var lv := Gems.enchant_level(id)
	var need := lv + 1
	if lv >= Gems.MAX_ENCHANT or not _has("cave_crystal", need) or not _pay(Gems.ENCHANT_GOLD * need):
		_refresh()
		return
	_take("cave_crystal", need)
	hero.stats.try_gain(Hero.Skill.MAGERY)
	if randf() < _enchant_chance(lv):
		var nid := Gems.with_enchant(id, need)
		_replace_gear(id, nid)
		game.log_event("The crystals flare and sink into the metal: %s." % Items.item_name(nid))
		game.count("enchanted")
		game.sound("cast", hero.position)
		Fx.sparkle(game, hero.position + Vector3(0, 1.0, 0), Color(0.6, 0.85, 1.0), 30)
	else:
		game.log_event("The enchanting fails; the crystals crumble to dust.")
	_refresh()


func _socket(id: String, gem: String) -> void:
	if Gems.gem_of(id) != "" or not _has(gem):
		return
	_take(gem)
	var nid := Gems.with_gem(id, gem)
	_replace_gear(id, nid)
	game.log_event("You set the %s: %s." % [String(Gems.GEMS[gem]["name"]).to_lower(), Items.item_name(nid)])
	game.count("gems_set")
	_refresh()


## Auto: set any gem into the weapon (then armour), and enchant the weapon when crystals and gold
## allow, at the forge.
func _errand_enchant() -> bool:
	var w := hero.weapon
	if w == "" and hero.armor_id == "":
		return false
	var gem := ""
	for g in Gems.GEMS:
		if _has(String(g)):
			gem = String(g)
	var target := w if w != "" and Gems.gem_of(w) == "" else (hero.armor_id if hero.armor_id != "" and Gems.gem_of(hero.armor_id) == "" else "")
	var socket_ok := gem != "" and target != ""
	var lv := Gems.enchant_level(w) if w != "" else 99
	var enchant_ok := w != "" and lv < Gems.MAX_ENCHANT and _has("cave_crystal", lv + 1) and hero.gold >= Gems.ENCHANT_GOLD * (lv + 1) + 200
	if not socket_ok and not enchant_ok:
		return false
	return _go("enchant", world.tile_center(world.forge_tile + Vector2i(0, 1)), _auto_enchant.bind(gem, target, enchant_ok), null, 2.0)


func _auto_enchant(gem: String, target: String, enchant_ok: bool) -> void:
	if gem != "" and target != "" and _has(gem):
		_socket(target, gem)
	if enchant_ok and hero.weapon != "":
		_enchant(hero.weapon)


# --- what Auto does: its switches --------------------------------------------------------------
const AUTO_NAMES := {
	"story": "Following the main story", "quest": "Side quests", "bounty": "Bounties", "cook": "Cooking", "brew": "Brewing potions and poisons",
	"tavern": "Visiting the tavern", "fishing": "Boats and fishing", "arena": "Arena duels", "race": "Horse races",
	"depths": "The dungeon's depths", "tower": "Taking guild towers", "house": "Home: rest, garden, furniture",
	"farm": "Farming", "enchant": "Enchanting and gems", "explore": "Exploring caves and biomes",
	"world_boss": "Joining the fight against world bosses",
	"potions": "Potions and blade poison in a fight", "meals": "Eating cooked meals",
}
const AUTO_ORDER := ["story", "quest", "bounty", "world_boss", "cook", "meals", "brew", "potions", "tavern", "fishing", "arena", "race",
	"depths", "tower", "house", "farm", "enchant", "explore"]


func auto_on(kind: String) -> bool:
	var off: Variant = data.get("auto_off", {})
	return not (off is Dictionary and bool((off as Dictionary).get(kind, false)))


func _page_auto() -> void:
	_h("What Auto does")
	_t("With Auto on, your hero fights, loots, gathers, crafts and banks by itself, and every minute or so runs one of these errands when nothing presses. Switch off the ones you'd rather do yourself (or not at all).")
	for k in AUTO_ORDER:
		_b("%s: %s" % [AUTO_NAMES[k], "On" if auto_on(String(k)) else "Off"], _toggle_auto_kind.bind(String(k)))


func _toggle_auto_kind(kind: String) -> void:
	if not (data.get("auto_off") is Dictionary):
		data["auto_off"] = {}
	data["auto_off"][kind] = auto_on(kind)
	if errand.get("kind", "") == kind:
		errand = {}
	_refresh()


# --- horse races -----------------------------------------------------------------------------
## A lap from the arena round a course of posts and back, on your own mount, against three riders
## whose times are drawn from their horses' pace.
const RACE_COURSE := [Vector2i(93, 86), Vector2i(100, 88), Vector2i(100, 94), Vector2i(93, 94), Vector2i(89, 91)]
const RACERS := ["Swift Marigold", "Old Thunder", "Ser Aldous on Nightwind", "The Stable Boy", "Red Fenna", "Hal's Grey"]
var race := {}
var _race_posts: Array[MeshInstance3D] = []


func _start_race(bet: int) -> void:
	if hero.mounted_on == null or not _pay(bet):
		return
	var pts: Array[Vector3] = []
	var length := 0.0
	var prev := hero.position
	for t in RACE_COURSE:
		var p := world.tile_center(_spot(t))
		pts.append(p)
		length += prev.distance_to(p) * 1.25          # paths wind a little
		prev = p
	var names := RACERS.duplicate()
	names.shuffle()
	var rivals: Array = []
	for i in range(3):
		rivals.append({"name": names[i], "time": length / randf_range(4.6, 6.4), "in": false})
	race = {"pts": pts, "i": 0, "t": 0.0, "bet": bet, "rivals": rivals}
	for p in pts:                                    # a flag at each post
		var post := _mesh([[Art.box(0.08, 1.8, 0.08), Art.at(0, 0.9, 0), Color(0.3, 0.2, 0.1)],
			[Art.box(0.45, 0.3, 0.03), Art.at(0.25, 1.6, 0), Color(0.95, 0.85, 0.2)]], p)
		_race_posts.append(post)
	game.world_event("The riders line up at the arena... and they're off!")
	game.sound("cheer", hero.position, 1.0, -4.0)
	_close()


func _end_race() -> void:
	for post in _race_posts:
		if is_instance_valid(post):
			post.queue_free()
	_race_posts.clear()
	race = {}


func _race_tick(delta: float) -> void:
	if race.is_empty():
		return
	race["t"] = float(race["t"]) + delta
	if hero.dead or hero.mounted_on == null or float(race["t"]) > 240.0:
		game.log_event("You are out of the race.")
		_end_race()
		return
	for r in race["rivals"]:
		if not bool(r["in"]) and float(race["t"]) >= float(r["time"]):
			r["in"] = true
			game.world_event("Race: %s crosses the line." % r["name"])
	var pts: Array = race["pts"]
	var dest: Vector3 = pts[int(race["i"])]
	if Vector2(hero.position.x - dest.x, hero.position.z - dest.z).length() <= 2.2:
		race["i"] = int(race["i"]) + 1
		if int(race["i"]) >= pts.size():
			var place := 1
			for r in race["rivals"]:
				if bool(r["in"]):
					place += 1
			var bet := int(race["bet"])
			if place == 1:
				hero.gold += bet * 3 + 100
				hero.add_fame(40)
				game.count("races_won")
				game.event_about("%s wins the race! %d gold." % [hero.display_name, bet * 3 + 100], true)
				game.sound("cheer", hero.position)
			elif place == 2:
				hero.gold += bet
				game.log_event("Second place: your stake comes back.")
			else:
				game.log_event("You finish %s. The stake is lost." % ("third" if place == 3 else "last"))
			_end_race()
		return
	hero.target = null                               # nothing but the course
	if not hero.has_journey or hero.journey.distance_to(dest) > 1.0:
		hero.set_journey(dest)
	hero.pause = 0.5


## Auto: enter a race when riding (or with a mount to hand) and gold to stake.
func _errand_race() -> bool:
	if hero.gold < 250:
		return false
	var has_mount := hero.mounted_on != null
	for p in hero.pets:
		if hero.can_ride(p):
			has_mount = true
	if not has_mount:
		return false
	return _go("race", world.tile_center(ARENA), _auto_race, null, 3.0)


func _auto_race() -> void:
	if hero.mounted_on == null:
		for p in hero.pets:
			if hero.can_ride(p) and not p.dead:
				p.position = hero.position
				hero.mount(p)
				break
	if hero.mounted_on != null:
		_start_race(50)


# --- world bosses ----------------------------------------------------------------------------
## Now and then a giant wakes somewhere in the wilds. The whole land hears of it, and the stronger
## players come from every side to bring it down. It leaves two treasure chests, and gold, fame
## and a diamond for a hero who was in the fight.
const WORLD_BOSSES := [
	{"name": "Tharok the World-Eater", "look": "ogre", "scale": 2.6, "color": Color(0.5, 0.35, 0.25)},
	{"name": "The Frost Wyrm", "look": "swamp_dragon", "scale": 2.3, "color": Color(0.7, 0.85, 1.0)},
	{"name": "The Queen of Ashes", "look": "daemon", "scale": 2.2, "color": Color(0.8, 0.3, 0.15)},
	{"name": "Grandfather Yeti", "look": "yeti", "scale": 2.4, "color": Color(0.9, 0.95, 1.0)},
]
const WORLD_BOSS_EVERY := 1200.0
const WORLD_BOSS_LASTS := 600.0
var world_boss: Entity
var _wb_in := 700.0
var _wb_left := 0.0
var _wb_call := 0.0
var _wb_hero_fought := false


func _world_boss_tick(step: float) -> void:
	if game.autotest:
		return                                     # the play-test keeps to the ordinary world
	if world_boss == null:
		_wb_in -= step
		if _wb_in <= 0.0:
			_spawn_world_boss()
		return
	if hero.target == world_boss or world_boss.target == hero:
		_wb_hero_fought = true
	_wb_left -= step
	if world_boss.dead:
		world_boss = null
		_wb_in = WORLD_BOSS_EVERY * randf_range(0.8, 1.2)
		return
	if _wb_left <= 0.0:
		game.world_event("%s sinks back into the earth, unbeaten." % world_boss.display_name)
		world_boss.vanish()
		world_boss = null
		_wb_in = WORLD_BOSS_EVERY * randf_range(0.8, 1.2)
		return
	_wb_call -= step
	if _wb_call <= 0.0:                              # the strong answer the call
		_wb_call = 12.0
		var sent := 0
		for item in game.creatures:
			var e := item as Entity
			if e.kind != Entity.Kind.PLAYER or e.is_hero or e.dead or e.ghost or e.target != null or e.recovering or e.retreating:
				continue
			if e.power() >= 3.5 and sent < 6 and e.position.distance_to(world_boss.position) > 6.0:
				e.set_journey(world_boss.position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)))
				e.roam_timer = maxf(e.roam_timer, 120.0)
				sent += 1


func _spawn_world_boss() -> void:
	var d: Dictionary = WORLD_BOSSES[randi() % WORLD_BOSSES.size()]
	var cfg := Bestiary.BONE_KING.duplicate(true)
	cfg["look"] = d["look"]
	cfg["scale"] = d["scale"]
	cfg["str"] = 900
	cfg["dex"] = 70
	cfg["dmg_min"] = 20.0
	cfg["dmg_max"] = 36.0
	cfg["armor"] = 7.0
	cfg["danger"] = 12
	cfg["leash"] = 5
	cfg["aggro"] = 9.0
	cfg["loot"] = {"gold_min": 1500, "gold_max": 2500, "reagents": 40,
		"drops": [["diamond", 1.0], ["ruby", 0.5], ["sapphire", 0.5], ["emerald", 0.5], ["cave_crystal", 1.0], ["cave_crystal", 1.0], ["platemail", 0.6]]}
	var at: Vector3 = game._wild_spot()
	world_boss = game.pool_spawn(String(d["name"]), cfg, d["color"], at)
	_wb_left = WORLD_BOSS_LASTS
	_wb_call = 0.0
	_wb_hero_fought = false
	game.log_event("The earth shakes: %s has woken, %s! The strong are gathering." % [d["name"], _where(at)])
	game.sound("thunder", hero.position)
	game.sound_here("braam", 0.8, 2.0)                   # and a great brass blast: a giant wakes


func _world_boss_slain(killer: Entity) -> void:
	game._drop_chest(world_boss)
	game._drop_chest(world_boss)
	game.event_about("%s has fallen%s! The land breathes again." % [world_boss.display_name,
		(" to " + killer.display_name) if killer != null else ""], true)
	if _wb_hero_fought or (killer != null and killer.is_hero) or hero.position.distance_to(world_boss.position) < 12.0:
		hero.gold += 500
		hero.add_fame(200)
		_give("diamond")
		game.count("world_bosses")
		game.log_event("For your part in the fight: 500 gold and a diamond.")


## Auto: join the fight when strong enough.
func _errand_world_boss() -> bool:
	if world_boss == null or world_boss.dead or hero.power() < 6.0:
		return false
	return _go("world_boss", world_boss.position, _engage.bind(world_boss), world_boss, 7.0)


# --- the tutorial (chosen on the start screen) -----------------------------------------------
const TUTORIAL := [
	"Welcome! Tap the ground to walk there. (Walk a few steps.)",
	"Tap a monster to attack it - a rat is a fair first fight. (Slay something.)",
	"Tap its corpse to take what it carried. (Loot something.)",
	"The Menu button, top right, opens every other button. Open the Bag from it.",
	"Main Menu > Adventures holds quests, bounties, the tavern, the arena and more. Open it.",
	"Last: Menu > Auto lets your hero play by itself (fight, loot, quests, errands). Switch it on.",
	"That's all you need. Tap the minimap to travel; Main Menu > Help has the rest. Good luck!",
]
var tutorial := -1                         # the step showing (-1: no tutorial)
var _tut_label: Label
var _tut_from := Vector3.ZERO
var _tut_base := 0
var _tut_wait := 0.0


func start_tutorial() -> void:
	if game.auto:
		game._toggle_auto()                        # hands on: you do it yourself
	_tut_label = Label.new()
	_tut_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tut_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tut_label.custom_minimum_size = Vector2(760, 0)
	_tut_label.add_theme_font_size_override("font_size", 28)
	_tut_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	_tut_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_tut_label.add_theme_constant_override("outline_size", 10)
	_tut_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	act_button.get_parent().add_child(_tut_label)
	_tut_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 70)
	_tut_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tutorial_show(0)


func _tutorial_show(i: int) -> void:
	tutorial = i
	_tut_label.text = "%d/%d  %s" % [i + 1, TUTORIAL.size(), TUTORIAL[i]]
	_tut_from = hero.position
	_tut_base = int(game.property.stats_counts.get("kills" if i == 1 else "loot", 0))
	_tut_wait = 0.0
	game.sound("gain", hero.position)


func _tutorial_tick(delta: float) -> void:
	if tutorial < 0:
		return
	var done := false
	match tutorial:
		0:
			done = hero.position.distance_to(_tut_from) > 3.0
		1:
			done = int(game.property.stats_counts.get("kills", 0)) > _tut_base
		2:
			done = int(game.property.stats_counts.get("loot", 0)) > _tut_base
		3:
			done = _tut_seen(game.bag_panel)
		4:
			done = _tut_seen(panel)
		5:
			done = game.auto
		_:
			_tut_wait += delta
			if _tut_wait > 12.0:
				tutorial = -1
				_tut_label.queue_free()
				return
	if done:
		hero.gold += 10
		game.log_event("Well done! (+10 gold)")
		_tutorial_show(tutorial + 1)


func _tut_seen(p: Control) -> bool:
	return p.has_meta("tut_seen")


## Called while the game is stopped behind a menu or panel: the tutorial notes which were opened.
func while_paused() -> void:
	if tutorial < 0:
		return
	for p in [game.bag_panel, panel]:
		if (p as Control).visible:
			(p as Control).set_meta("tut_seen", true)


# --- the church ------------------------------------------------------------------------------
## The Church of the Shard, far in the south-west below the Reedmarsh: a stone nave with a paved floor and a red
## runner from the doors to the altar, pews, candles, windows of coloured glass glowing in the
## south wall, and a bell tower that tolls morning, noon and dusk. Father Corwin keeps it. Pray at
## the altar once a day (healing, poison drawn out, a little karma, a blessing of the mind), or
## give to the poor.
var _bell_hour := -1


func _build_church() -> void:
	var r: Rect2i = World.CHURCH
	var inner := Rect2i(r.position + Vector2i(1, 1), r.size - Vector2i(2, 2))
	var mid := Vector3(inner.position.x + inner.size.x / 2.0, 0.0, inner.position.y + inner.size.y / 2.0)
	var stone := Color(0.62, 0.6, 0.56)
	var parts := [[Art.box(inner.size.x, 0.04, inner.size.y), Art.at(0, 0.02, 0), stone]]
	for iy in range(inner.size.y):                    # paving: alternate slabs a shade darker
		for ix in range(inner.size.x):
			if (ix + iy) % 2 == 0:
				parts.append([Art.box(0.94, 0.045, 0.94), Art.at(ix - inner.size.x / 2.0 + 0.5, 0.022, iy - inner.size.y / 2.0 + 0.5), stone.darkened(0.12)])
	parts.append([Art.box(1.0, 0.05, inner.size.y + 1.0), Art.at(0, 0.03, -0.5), Color(0.6, 0.12, 0.12)])   # the runner
	_mesh(parts, mid)
	# the altar at the south end: a stone table, a gold ankh, two candles
	var altar := mid + Vector3(0, 0, inner.size.y / 2.0 - 0.45)
	var gold := Color(0.95, 0.8, 0.35)
	_mesh([[Art.box(1.6, 0.7, 0.6), Art.at(0, 0.35, 0), Color(0.8, 0.78, 0.74)], [Art.box(1.7, 0.06, 0.7), Art.at(0, 0.73, 0), Color(0.92, 0.9, 0.86)],
		[Art.box(0.08, 0.5, 0.08), Art.at(0, 1.05, 0), gold], [Art.box(0.34, 0.07, 0.07), Art.at(0, 1.12, 0), gold],
		[Art.ring_mesh(0.07, 0.12), Art.at(0, 1.4, 0, Vector3(PI / 2.0, 0, 0)), gold],
		[Art.box(0.06, 0.3, 0.06), Art.at(-0.6, 0.9, 0), Color(0.95, 0.93, 0.85)], [Art.box(0.06, 0.3, 0.06), Art.at(0.6, 0.9, 0), Color(0.95, 0.93, 0.85)]], altar)
	for cx in [-0.6, 0.6]:
		var fl := Fx.flame(0.08, 6, 0.25)
		fl.position = altar + Vector3(cx, 1.08, 0)
		add_child(fl)
		fl.add_to_group("view_fx")
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.85, 0.6)
	glow.omni_range = 5.0
	glow.position = altar + Vector3(0, 1.6, -0.5)
	add_child(glow)
	# pews either side of the runner
	var wood := Color(0.4, 0.26, 0.14)
	for row in range(3):
		for px in [-1.25, 1.25]:
			_mesh([[Art.box(1.1, 0.08, 0.3), Art.at(0, 0.3, 0), wood], [Art.box(1.1, 0.4, 0.06), Art.at(0, 0.5, -0.14), wood.darkened(0.1)],
				[Art.box(0.06, 0.3, 0.3), Art.at(-0.5, 0.15, 0), wood.darkened(0.2)], [Art.box(0.06, 0.3, 0.3), Art.at(0.5, 0.15, 0), wood.darkened(0.2)]],
				mid + Vector3(px, 0, -1.6 + row * 1.0))
	# coloured glass glowing in the south wall, behind the altar
	var wall_z := float(r.end.y) - 1.0 + 0.02
	var colours := [Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.25), Color(0.25, 0.45, 0.9), Color(0.3, 0.75, 0.4)]
	for i in range(4):
		var win := MeshInstance3D.new()
		win.mesh = Art.box(0.5, 0.9, 0.06)
		win.material_override = Art.glow_mat(colours[i])
		win.position = Vector3(r.position.x + 1.5 + i * 1.0, 1.0, wall_z)
		add_child(win)
	# the bell tower on the north-west corner, with a pointed roof, a bell and an ankh on top
	var corner := world.tile_center(r.position)
	_mesh([[Art.box(1.04, 4.6, 1.04), Art.at(0, 2.3, 0), Color(0.5, 0.5, 0.53)], [Art.box(1.2, 0.12, 1.2), Art.at(0, 3.4, 0), Color(0.62, 0.62, 0.65)],
		[Art.box(0.6, 0.7, 1.08), Art.at(0, 3.95, 0), Color(0.1, 0.09, 0.08)], [Art.box(1.08, 0.7, 0.6), Art.at(0, 3.95, 0), Color(0.1, 0.09, 0.08)],
		[Art.ball(0.22, 8, 5), Art.at(0, 3.95, 0), gold],
		[Art.cone(0.85, 1.4, 0.0, 4), Art.at(0, 5.3, 0, Vector3(0, PI / 4.0, 0)), Color(0.45, 0.2, 0.16)],
		[Art.box(0.06, 0.5, 0.06), Art.at(0, 6.2, 0), gold], [Art.box(0.3, 0.06, 0.06), Art.at(0, 6.25, 0), gold]], corner)
	# an arch over the doors
	var door_mid := (world.tile_center(World.CHURCH_DOORS[0]) + world.tile_center(World.CHURCH_DOORS[1])) / 2.0
	_mesh([[Art.box(2.3, 0.3, 1.06), Art.at(0, 1.85, 0), Color(0.5, 0.5, 0.53)], [Art.cone(0.9, 0.7, 0.0, 4), Art.at(0, 2.35, 0, Vector3(0, PI / 4.0, 0)), Color(0.45, 0.2, 0.16)],
		[Art.ring_mesh(0.1, 0.18), Art.at(0, 1.85, -0.55, Vector3(PI / 2.0, 0, 0)), gold]], door_mid)


## The bell tolls at six in the morning, at noon and at eight in the evening.
func _bell_tick() -> void:
	var hour := int(game.day_time * 24.0)
	if hour == _bell_hour:
		return
	_bell_hour = hour
	if hour in [6, 12, 20] and not game.autotest:
		var at := world.tile_center(World.CHURCH.position)
		game.sound("toll", at, 1.0, 4.0)               # a deep bronze bell
		if at.distance_to(hero.position) < 25.0:
			game.world_event("The church bell tolls %s." % {6: "the morning", 12: "noon", 20: "the evening"}[hour])


func _page_church() -> void:
	_h("The Church of the Shard")
	var inside := world.in_church(world.to_tile(hero.position))
	_t("Stone walls, coloured glass and candlelight, far in the south-west below the Reedmarsh. Father Corwin keeps it; the bell tolls morning, noon and dusk. Karma %d." % hero.karma)
	if not inside:
		_b("Walk to the church", _walk_to.bind(Vector2i(12, 128)))
		return
	var prayed := _now() - float(data.get("pray_at", -1.0e9)) < DAY
	_b("Pray at the altar (once a day)" if not prayed else "You have prayed today", _pray, not prayed)
	_b("Give 50 gold to the poor", _alms, hero.gold >= 50)
	_b("Speak with Father Corwin (blessing, confession)", _see_priest)


func _pray() -> void:
	data["pray_at"] = _now()
	hero.hp = minf(hero.hp + float(hero.stats.max_hp()) * 0.5, float(hero.stats.max_hp()))
	hero.mana = float(hero.stats.max_mana())
	hero.poison_level = 0
	hero.add_karma(15)
	hero.add_effect("prayer", {"secs": 600.0, "mods": {"int": 3}, "name": "At peace", "color": Color(1.0, 0.95, 0.7)})
	game.log_event("You kneel at the altar. The candlelight steadies you: your wounds ease and your mind clears.")
	game.count("prayers")
	_refresh()


func _alms() -> void:
	if _pay(50):
		hero.add_karma(60)
		hero.add_fame(5)
		game.log_event("You give fifty gold to the poor box. Father Corwin nods his thanks.")
	_refresh()


func _see_priest() -> void:
	var priest: Entity = null
	for item in game.creatures:
		var e := item as Entity
		if e.display_name == "Father Corwin":
			priest = e
	panel.visible = false
	if priest != null:
		game._open_priest(priest)
	else:
		game._resume()


# --- Ravenhollow Cemetery ----------------------------------------------------------------------
## The walled graveyard of the south-east, dressed as a cemetery: rows of headstones, crosses,
## stone tombs and a tall obelisk over fresh and sunken mounds, bare dead trees, lanterns that
## burn with a cold green light, an iron gate on the west side, and in the north the Tomb of the
## Old Kings. Wisps drift among the graves at night. Once a night you may open the tomb - and
## wake the Barrow King, who keeps the old kings' gold.
const TOMB_DOOR := Vector2i(104, 130)
var _wisps: CPUParticles3D
var tomb_king: Entity


func _build_cemetery() -> void:
	var r: Rect2i = World.CEMETERY
	var rng := RandomNumberGenerator.new()
	rng.seed = 1313
	var stone := Color(0.55, 0.55, 0.58)
	var soil := Color(0.24, 0.2, 0.16)
	var parts := []
	for y in range(r.position.y + 2, r.end.y - 1):
		if y == 34:
			continue                                   # the path through from the gate
		for x in range(r.position.x + 2, r.end.x - 1):
			var t := Vector2i(x, y)
			if world.is_blocked(t) or (x - r.position.x) % 2 == 1 or (absi(x - TOMB_DOOR.x) <= 1 and y <= TOMB_DOOR.y + 1):
				continue
			var at := Vector3(x + 0.5, 0.0, y + 0.5) - Vector3(r.position.x, 0, r.position.y)
			var tone := stone.darkened(rng.randf_range(0.0, 0.3))
			var lean := Vector3(rng.randf_range(-0.12, 0.12), 0, rng.randf_range(-0.15, 0.15))   # old stones lean
			parts.append([Art.box(0.5, 0.06, 0.8), Art.at(at.x, 0.03, at.z + 0.1), soil.darkened(rng.randf_range(0.0, 0.2))])   # the mound
			match rng.randi() % 5:
				0, 1:                                   # a round-topped headstone
					parts.append([Art.box(0.36, 0.42, 0.08), Art.at(at.x, 0.21, at.z - 0.3, lean), tone])
					parts.append([Art.cone(0.18, 0.08, 0.18, 8), Art.at(at.x, 0.42, at.z - 0.3, lean + Vector3(PI / 2.0, 0, 0)), tone])
				2:                                      # a cross
					parts.append([Art.box(0.08, 0.6, 0.08), Art.at(at.x, 0.3, at.z - 0.3, lean), tone])
					parts.append([Art.box(0.34, 0.08, 0.08), Art.at(at.x, 0.44, at.z - 0.3, lean), tone])
				3:                                      # a stone tomb
					parts.append([Art.box(0.55, 0.3, 0.85), Art.at(at.x, 0.15, at.z), tone])
					parts.append([Art.box(0.62, 0.06, 0.92), Art.at(at.x, 0.32, at.z), tone.lightened(0.1)])
				_:                                      # a broken stone, half sunk
					parts.append([Art.box(0.3, 0.22, 0.08), Art.at(at.x, 0.1, at.z - 0.3, lean * 2.0), tone.darkened(0.15)])
	parts.append([Art.cone(0.22, 1.8, 0.04, 4), Art.at(5.5, 0.9, 10.5, Vector3(0, PI / 4.0, 0)), stone.lightened(0.05)])    # an obelisk
	parts.append([Art.box(0.6, 0.2, 0.6), Art.at(5.5, 0.1, 10.5), stone])
	_mesh(parts, Vector3(r.position.x, world.tile_center(r.get_center()).y, r.position.y))
	# the Tomb of the Old Kings: columns, a pediment and a dark door
	var tomb := world.tile_center(TOMB_DOOR) + Vector3(0, 0, -0.6)
	var marble := Color(0.7, 0.7, 0.72)
	_mesh([[Art.box(2.6, 2.0, 1.6), Art.at(0, 1.0, -0.4), marble.darkened(0.15)], [Art.box(2.9, 0.18, 2.0), Art.at(0, 2.08, -0.3), marble],
		[Art.cone(1.6, 0.7, 0.0, 4), Art.at(0, 2.5, -0.3, Vector3(0, PI / 4.0, 0), Vector3(1.0, 1.0, 0.7)), marble.darkened(0.05)],
		[Art.box(0.2, 1.9, 0.2), Art.at(-1.1, 0.95, 0.5), marble], [Art.box(0.2, 1.9, 0.2), Art.at(1.1, 0.95, 0.5), marble],
		[Art.box(0.2, 1.9, 0.2), Art.at(-0.55, 0.95, 0.5), marble], [Art.box(0.2, 1.9, 0.2), Art.at(0.55, 0.95, 0.5), marble],
		[Art.box(0.8, 1.3, 0.05), Art.at(0, 0.65, 0.42), Color(0.04, 0.03, 0.03)], [Art.box(3.0, 0.15, 1.4), Art.at(0, 0.075, 0.2), marble.darkened(0.25)],
		[Art.ring_mesh(0.12, 0.2), Art.at(0, 1.7, 0.45, Vector3(PI / 2.0, 0, 0)), Color(0.75, 0.65, 0.4)]], tomb)
	# bare dead trees
	for tt in [Vector2i(84, 30), Vector2i(92, 38), Vector2i(84, 38)]:
		var bark := Color(0.2, 0.18, 0.16)
		_mesh([[Art.cone(0.12, 1.8, 0.05, 5), Art.at(0, 0.9, 0), bark], [Art.box(0.06, 0.7, 0.06), Art.at(0.2, 1.4, 0, Vector3(0, 0, -0.8)), bark],
			[Art.box(0.05, 0.6, 0.05), Art.at(-0.2, 1.55, 0.05, Vector3(0.2, 0, 0.9)), bark], [Art.box(0.04, 0.5, 0.04), Art.at(0.05, 1.75, -0.15, Vector3(-0.7, 0, 0)), bark],
			[Art.box(0.04, 0.35, 0.04), Art.at(0.42, 1.65, 0, Vector3(0, 0, -0.3)), bark]], world.tile_center(tt) + Vector3(0.3, 0, 0.2))
	# lanterns with a cold green flame, and an iron gate at the west opening
	for lt in [Vector2i(83, 33), Vector2i(83, 35), Vector2i(91, 32)]:
		var lp := world.tile_center(lt)
		_mesh([[Art.box(0.06, 1.3, 0.06), Art.at(0, 0.65, 0), Color(0.12, 0.12, 0.13)], [Art.box(0.18, 0.22, 0.18), Art.at(0, 1.4, 0), Color(0.5, 0.95, 0.6)]], lp)
		var gl := OmniLight3D.new()
		gl.light_color = Color(0.45, 1.0, 0.6)
		gl.omni_range = 3.5
		gl.light_energy = 0.9
		gl.position = lp + Vector3(0, 1.45, 0)
		add_child(gl)
	var iron := Color(0.1, 0.1, 0.11)
	var gate := []
	for k in range(7):
		gate.append([Art.box(0.04, 1.3, 0.04), Art.at(0, 0.65, -1.2 + k * 0.4), iron])
		gate.append([Art.cone(0.04, 0.12, 0.0, 4), Art.at(0, 1.36, -1.2 + k * 0.4), iron])
	gate.append([Art.box(0.05, 0.05, 2.5), Art.at(0, 1.1, 0), iron])
	gate.append([Art.box(0.05, 0.05, 2.5), Art.at(0, 0.35, 0), iron])
	var gate_mesh := _mesh(gate, world.tile_center(Vector2i(82, 34)) + Vector3(-0.35, 0, 0))
	gate_mesh.rotation.y = 0.25                         # left standing ajar
	# wisps that drift among the graves at night
	_wisps = CPUParticles3D.new()
	_wisps.amount = 18
	_wisps.lifetime = 5.0
	_wisps.mesh = Fx._quad(0.14, Color(0.6, 1.0, 0.75))
	_wisps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_wisps.emission_box_extents = Vector3(r.size.x / 2.0 - 1.0, 0.4, r.size.y / 2.0 - 1.0)
	_wisps.direction = Vector3(0, 1, 0)
	_wisps.spread = 70.0
	_wisps.initial_velocity_min = 0.05
	_wisps.initial_velocity_max = 0.25
	_wisps.gravity = Vector3(0, 0.03, 0)
	var ramp := Gradient.new()
	ramp.colors = PackedColorArray([Color(0.6, 1.0, 0.75, 0.0), Color(0.6, 1.0, 0.75, 0.9)])
	ramp.offsets = PackedFloat32Array([0.0, 0.5])
	ramp.add_point(1.0, Color(0.6, 1.0, 0.75, 0.0))
	_wisps.color_ramp = ramp
	_wisps.position = world.tile_center(r.get_center()) + Vector3(0, 0.6, 0)
	_wisps.emitting = false
	add_child(_wisps)
	_wisps.add_to_group("view_fx")


func _cemetery_tick() -> void:
	if _wisps != null:
		_wisps.emitting = game.is_night()


func _page_tomb() -> void:
	_h("The Tomb of the Old Kings")
	_t("A marble tomb in the heart of Ravenhollow, its door black and cold. The old kings were buried with their gold - and with the one who swore to keep it. The seal can be broken once a night.")
	if tomb_king != null and is_instance_valid(tomb_king) and not tomb_king.dead:
		_t("The Barrow King is awake!")
		return
	if not _near(TOMB_DOOR, 2.6):
		_b("Walk to the tomb", _walk_to.bind(TOMB_DOOR + Vector2i(0, 1)))
		return
	var opened := _now() - float(data.get("tomb_at", -1.0e9)) < DAY
	if not game.is_night():
		_small_text("By day the seal holds fast. Come back after dark.")
	_b("Break the seal" if not opened else "The seal is broken for tonight", _open_tomb, game.is_night() and not opened)


func _open_tomb() -> void:
	data["tomb_at"] = _now()
	var cfg := Bestiary.LICH.duplicate(true)
	cfg["look"] = "skeleton"
	cfg["scale"] = 1.5
	cfg["str"] = 160
	cfg["armor"] = 5.0
	cfg["danger"] = 8
	cfg["boss"] = true
	cfg["weapon"] = "broadsword"
	cfg["wear"] = "platemail"
	cfg["loot"] = {"gold_min": 600, "gold_max": 1100, "reagents": 20,
		"drops": [["diamond", 0.4], ["sapphire", 0.7], ["ruby", 0.5], ["crown_of_bones", 0.5], ["platemail", 0.3]]}
	tomb_king = game.pool_spawn("The Barrow King", cfg, Color(0.75, 0.7, 0.55), world.tile_center(TOMB_DOOR + Vector2i(0, 2)))
	tomb_king.target = hero
	game.log_event("The seal cracks. Cold air pours out - and the Barrow King rises to defend his gold!")
	game.sound("roar", world.tile_center(TOMB_DOOR), 0.6, 4.0)
	_close()
