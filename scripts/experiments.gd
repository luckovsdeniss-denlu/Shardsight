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
	{"id": "pro_combat", "name": "Weighty combat", "desc": "Blows are drawn back, struck and followed through, and land at the moment of impact with a brief freeze; clean flinches.", "restart": false},
]
const CFG := "user://shardsight_experiments.json"

static var active := false              # true in experimental mode
static var enabled := {}                # experiment id -> true when switched on


## Whether an experiment is on (never outside experimental mode).
static func on(id: String) -> bool:
	return active and bool(enabled.get(id, false))


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
