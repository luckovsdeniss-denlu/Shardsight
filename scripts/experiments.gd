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
	{"id": "dimension_car", "name": "Dimension car", "desc": "Everyone gets the Riftrunner: a car that drives itself after you, goes fast, and with Rift jump drives through a ring of light into the Shardveil - the land in another dimension (violet sky, crystal trees, glowing water, its own music, gold counts double) - and back.", "restart": false, "default": true},
	{"id": "rich_graphics", "name": "Richer graphics", "desc": "Rounder, smoother creatures with bevelled armour; soft shadows under everyone; a rim of light; finer ground; stone walls with windows that glow at night (from the next start).", "restart": true},
	{"id": "wild_life", "name": "Wild life", "desc": "Deer grazing at the edges of the woods, rabbits in the meadows, ducks on the lakes, fish leaping, and bats at night - they bolt when you come close.", "restart": false},
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
