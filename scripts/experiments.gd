class_name Experiments
## Experimental mode: a separate game (its own save) where new ideas can be tried before they
## join the ordinary game. Each experiment can be switched on and off in Main Menu > Experiments;
## the choices are kept in their own small file. Add new experiments to LIST and check them with
## Experiments.on("id") wherever they change the game.

const LIST := [
	{"id": "fast_time", "name": "Fast days", "desc": "Day and night pass four times as fast.", "restart": false},
	{"id": "crowded", "name": "Crowded wilds", "desc": "Half as many monsters again in every region (from the next start).", "restart": true},
	{"id": "quick_learning", "name": "Quick learning", "desc": "Skills rise twice as fast with use.", "restart": false},
	{"id": "glass_cannon", "name": "Glass cannon", "desc": "Everyone deals and takes double damage.", "restart": false},
	{"id": "dimension_car", "name": "Dimension car", "desc": "Everyone gets the Riftrunner: a car that drives itself after you, goes fast, and with Rift jump changes - wheels folding into hover pads, wings out, lifting off - and shoots through into the Shardveil - the land in another dimension (violet sky, crystal trees, glowing water, its own music, gold counts double) - and back.", "restart": false, "default": true},
	{"id": "veil_chaos", "name": "Shardveil chaos", "desc": "In the Shardveil (through the dimension car's rift) it's every one for themselves: everyone near you with hands has a gun - a shotgun, a rocket launcher, a spike gun, an arc caster or an ember launcher - anyone fights anyone (but never in a town), and meteors keep falling out of the sky.", "restart": false, "default": true},
	{"id": "rich_graphics", "name": "Richer graphics", "desc": "Rounder, smoother creatures with bevelled armour; soft shadows under everyone; a rim of light; finer ground; stone walls with windows that glow at night (from the next start).", "restart": true},
	{"id": "wild_life", "name": "Wild life", "desc": "Deer grazing at the edges of the woods, rabbits in the meadows, ducks on the lakes, fish leaping, and bats at night - they bolt when you come close.", "restart": false},
	{"id": "death_anims", "name": "Death and resurrection", "desc": "The slain stagger, buckle and crash to the ground (beasts onto their sides) with a puff of dust and a wisp of spirit; a fallen adventurer's ghost rises out of the body; and the raised come back kneeling in a beam of light under a descending halo, then rise to their feet.", "restart": false, "default": true},
	{"id": "player_bars", "name": "Player bars", "desc": "A health bar over every player - you and every adventurer - all the time, and a blue casting bar under it while they speak a spell.", "restart": false, "default": true},
	{"id": "living_score", "name": "Living score", "desc": "New music that follows the screen: each place has a new piece in five layers - chords, motion, tune, tension, battle - turned up and down as you walk or drive, as foes close in, as you fight (a boss), or die; kills, rifts and death land as stingers on the beat.", "restart": false, "default": true},
	{"id": "safe_rising", "name": "No death loops", "desc": "Nobody fights by a resurrection shrine, and the newly raised can't be harmed (nor harm anyone) for 12 seconds; everyone remembers where they - and those near them - fell, keeps away from those spots for a few minutes, and runs far off if they find themselves there.", "restart": false, "default": true},
	{"id": "steady_growth", "name": "Steady growth", "desc": "Every second of play the hero grows a little in the way they've chosen by how they play - the fighting skill used most lately (sword, fencing, mace, bow, wrestling or magic), and the next one more slowly - so the level keeps climbing, about a level every 13 seconds, stats rising with it.", "restart": false, "default": true},
	{"id": "pro_combat", "name": "Weighty combat", "desc": "Blows are drawn back, struck and followed through, and land at the moment of impact with a brief freeze; clean flinches.", "restart": false},
]
const CFG := "user://shardsight_experiments.json"

static var active := false              # true in experimental mode
static var enabled := {}                # experiment id -> true when switched on


## Whether an experiment is on (never outside experimental mode).
static func on(id: String) -> bool:
	return active and is_enabled(id)


## Whether an experiment is switched on: as chosen, or (never chosen) as it comes - most come
## off, a few (marked "default") on for everyone.
static func is_enabled(id: String) -> bool:
	if enabled.has(id):
		return bool(enabled[id])
	for e: Dictionary in LIST:
		if String(e["id"]) == id:
			return bool(e.get("default", false))
	return false


static func load_cfg() -> void:
	enabled = {}
	if not FileAccess.file_exists(CFG):
		return
	var f := FileAccess.open(CFG, FileAccess.READ)
	if f == null:
		return
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		for k in d:
			enabled[String(k)] = bool(d[k])


static func save_cfg() -> void:
	var f := FileAccess.open(CFG, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(enabled))
