class_name Property
## The hero's bank box, house, rune, quest progress and settings.
## Mechanics reference: one bank account per character, reachable at any bank and safe from
## theft and death; large purchases come straight from the bank; houses give secure storage but
## decay and fall if neglected, dropping their contents.

## House sizes (tiles a side): price from the bank, lock-down slots, co-owner slots.
const DEEDS := {
	3: {"name": "small house", "price": 1500, "lockdowns": 3, "co_owners": 1},
	5: {"name": "house", "price": 3500, "lockdowns": 8, "co_owners": 2},
	7: {"name": "large tower", "price": 7000, "lockdowns": 15, "co_owners": 3},
}
const CO_OWNER_DAYS := 3.0        # each co-owner looking after the house adds this many days
const POCKET_GOLD := 50           # gold the hero keeps on hand when banking automatically
const COLLAPSE_DAYS := 7.0        # real days away before an unvisited house collapses
const STAGES := [
	"Like new", "Slightly worn", "Somewhat worn", "Fairly worn", "Greatly worn",
	"In danger of collapsing",
]

var bank_gold := 0
var bank_items := {}
var has_deed := false
var deed_size := 3                     # the size of house the deed is for
var house_origin := Vector2i(-1, -1)   # top-left tile of the house
var house_size := 3
var house_chest := {}
var lockdowns := {}                    # items locked down in the house: kept even if it collapses
var co_owners: Array[String] = []      # players trusted with the house; they help it stand
var house_last_visit := 0.0            # unix time
var rune := Vector2i(-1, -1)           # the selected rune: where Recall and Gate Travel lead
var runes: Array[Vector2i] = []        # the runebook: up to MAX_RUNES marked spots
var quest_index := 0                   # which of Quests.LIST is next or active
var quest_active := false
var quest_kills := 0
var quest_escorted := false            # escort quests: the traveller got there
var vendor_hired := false              # a hired vendor in the house sells while you are away
var vendor_stock := {}
var vendor_gold := 0
var vendor_last := 0.0                 # unix time of the last offline-sale settlement
var sound_on := true                   # settings
var ruleset := "felucca"               # "felucca": open PvP; "trammel": players can't hurt each other
var music_on := true
var names_on := false                  # names over heads (off: a clean screen)
var stats_on := true                   # the stats text in the upper left
var minimap_on := true
var corpse_names_on := true           # labels over corpses and treasure chests
var first_person := false              # the camera at the hero's eyes instead of above
var graphics := "medium"               # low, medium or high
var weather_on := true
var cam_zoom := 1.0
var cam_yaw := 0.0


const MAX_RUNES := 8


## Mark: a new rune goes into the runebook (when it is full, it replaces the selected one).
func mark_rune(c: Vector2i) -> void:
	var i := runes.find(rune)
	if runes.size() < MAX_RUNES or i < 0:
		if runes.size() >= MAX_RUNES:
			runes.pop_back()
		runes.append(c)
	else:
		runes[i] = c
	rune = c


func select_rune(i: int) -> void:
	if i >= 0 and i < runes.size():
		rune = runes[i]


func forget_rune(i: int) -> void:
	if i < 0 or i >= runes.size() or runes.size() <= 1:
		return                             # the last rune stays
	var was_selected := runes[i] == rune
	runes.remove_at(i)
	if was_selected:
		rune = runes[0]


func has_house() -> bool:
	return house_origin.x >= 0


func house_center_tile() -> Vector2i:
	return World.house_center(house_origin, house_size)


func lockdown_slots() -> int:
	return int(DEEDS[house_size]["lockdowns"])


func co_owner_slots() -> int:
	return int(DEEDS[house_size]["co_owners"])


func collapse_days() -> float:
	return COLLAPSE_DAYS + CO_OWNER_DAYS * co_owners.size()


func days_since_visit() -> float:
	return maxf(0.0, (Time.get_unix_time_from_system() - house_last_visit) / 86400.0)


func condition() -> String:
	var per_stage := collapse_days() / STAGES.size()
	return STAGES[clampi(int(days_since_visit() / per_stage), 0, STAGES.size() - 1)]


func should_collapse() -> bool:
	return has_house() and days_since_visit() >= collapse_days()


## Being near the house keeps it standing.
func refresh() -> void:
	house_last_visit = Time.get_unix_time_from_system()


func clear_house() -> void:
	house_origin = Vector2i(-1, -1)
	house_size = 3
	house_chest = {}
	lockdowns = {}
	co_owners.clear()
	vendor_hired = false
	vendor_stock = {}


func _runes_list() -> Array:
	var out := []
	for c in runes:
		out.append([c.x, c.y])
	return out


static func merge(into: Dictionary, from: Dictionary) -> void:
	for k in from:
		into[k] = int(into.get(k, 0)) + int(from[k])


static func items_text(items: Dictionary) -> String:
	if items.is_empty():
		return "empty"
	var parts: Array[String] = []
	for id in items:
		parts.append("%s x%d" % [Items.item_name(id), int(items[id])])
	return ", ".join(parts)


func to_dict() -> Dictionary:
	var d := {
		"bank_gold": bank_gold, "bank_items": bank_items, "has_deed": has_deed, "deed_size": deed_size,
		"rune": [rune.x, rune.y], "runes": _runes_list(), "quest_index": quest_index, "quest_active": quest_active,
		"quest_kills": quest_kills, "quest_escorted": quest_escorted,
		"sound_on": sound_on, "cam_zoom": cam_zoom, "cam_yaw": cam_yaw, "ruleset": ruleset,
		"music_on": music_on, "weather_on": weather_on, "names_on": names_on, "stats_on": stats_on, "minimap_on": minimap_on, "first_person": first_person, "corpse_names_on": corpse_names_on, "graphics": graphics,
		"vendor_hired": vendor_hired, "vendor_stock": vendor_stock, "vendor_gold": vendor_gold,
		"vendor_last": vendor_last,
	}
	if has_house():
		d["house"] = {
			"x": house_origin.x, "y": house_origin.y,
			"chest": house_chest, "last_visit": house_last_visit,
			"size": house_size, "lockdowns": lockdowns, "co_owners": co_owners,
		}
	return d


## Loads saved data, ignoring anything invalid.
func load_dict(d: Dictionary) -> void:
	bank_gold = maxi(0, int(d.get("bank_gold", 0)))
	bank_items = _clean_items(d.get("bank_items", {}))
	has_deed = bool(d.get("has_deed", false))
	deed_size = int(d.get("deed_size", 3))
	if not DEEDS.has(deed_size):
		deed_size = 3
	var r: Variant = d.get("rune", [])
	if typeof(r) == TYPE_ARRAY and (r as Array).size() == 2:
		rune = Vector2i(int(r[0]), int(r[1]))
	runes.clear()
	var rl: Variant = d.get("runes", [])
	if typeof(rl) == TYPE_ARRAY:
		for item in rl:
			if typeof(item) == TYPE_ARRAY and (item as Array).size() == 2 and runes.size() < MAX_RUNES:
				runes.append(Vector2i(int(item[0]), int(item[1])))
	if rune.x >= 0 and not runes.has(rune):
		runes.push_front(rune)             # saves from before the runebook: their one rune
		if runes.size() > MAX_RUNES:
			runes.pop_back()
	quest_index = clampi(int(d.get("quest_index", 0)), 0, Quests.LIST.size() - 1)
	quest_active = bool(d.get("quest_active", false))
	quest_kills = maxi(0, int(d.get("quest_kills", 0)))
	quest_escorted = bool(d.get("quest_escorted", false))
	vendor_hired = bool(d.get("vendor_hired", false))
	vendor_stock = _clean_items(d.get("vendor_stock", {}))
	vendor_gold = maxi(0, int(d.get("vendor_gold", 0)))
	vendor_last = float(d.get("vendor_last", Time.get_unix_time_from_system()))
	sound_on = bool(d.get("sound_on", true))
	music_on = bool(d.get("music_on", true))
	names_on = bool(d.get("names_on", false))
	stats_on = bool(d.get("stats_on", true))
	minimap_on = bool(d.get("minimap_on", true))
	first_person = bool(d.get("first_person", false))
	corpse_names_on = bool(d.get("corpse_names_on", true))
	graphics = String(d.get("graphics", "medium"))
	if not graphics in ["low", "medium", "high"]:
		graphics = "medium"
	weather_on = bool(d.get("weather_on", true))
	ruleset = "trammel" if String(d.get("ruleset", "felucca")) == "trammel" else "felucca"
	cam_zoom = clampf(float(d.get("cam_zoom", 1.0)), 0.5, 1.8)
	cam_yaw = float(d.get("cam_yaw", 0.0))
	clear_house()
	var h: Variant = d.get("house", null)
	if typeof(h) == TYPE_DICTIONARY:
		var hd: Dictionary = h
		house_origin = Vector2i(int(hd.get("x", -1)), int(hd.get("y", -1)))
		house_chest = _clean_items(hd.get("chest", {}))
		house_size = int(hd.get("size", 3))
		if not DEEDS.has(house_size):
			house_size = 3
		lockdowns = _clean_items(hd.get("lockdowns", {}))
		var co: Variant = hd.get("co_owners", [])
		if typeof(co) == TYPE_ARRAY:
			for n in co:
				if co_owners.size() < co_owner_slots():
					co_owners.append(String(n))
		house_last_visit = float(hd.get("last_visit", Time.get_unix_time_from_system()))


static func _clean_items(raw: Variant) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	var src: Dictionary = raw
	for key in src:
		var id := String(key)
		if Items.is_known(id) and int(src[key]) > 0:
			out[id] = int(src[key])
	return out


## What a player vendor asks: the full value of an item (merchants pay half for used gear).
static func vendor_price(id: String) -> int:
	if Gear.has(id):
		return int(Gear.stats(id)["value"])
	return Items.value(id)


## Sells up to `count` random items from the vendor's stock; the vendor keeps 10%.
## Returns the gold made.
func vendor_sell(count: int) -> int:
	var made := 0
	for _i in range(count):
		if vendor_stock.is_empty():
			break
		var keys := vendor_stock.keys()
		var id := String(keys[randi() % keys.size()])
		vendor_stock[id] = int(vendor_stock[id]) - 1
		if int(vendor_stock[id]) <= 0:
			vendor_stock.erase(id)
		made += roundi(vendor_price(id) * 0.9)
	vendor_gold += made
	return made
