class_name Property
## The hero's bank box and house (mechanics reference: one bank account per character, reachable
## at any bank and safe from theft and death; large purchases come straight from the bank;
## houses give secure storage but decay and fall if neglected, dropping their contents).

const DEED_PRICE := 1500          # paid from the bank
const POCKET_GOLD := 50           # gold the hero keeps on hand when banking automatically
const COLLAPSE_DAYS := 7.0        # real days away before an unvisited house collapses
const STAGES := [
	"Like new", "Slightly worn", "Somewhat worn", "Fairly worn", "Greatly worn",
	"In danger of collapsing",
]

var bank_gold := 0
var bank_items := {}
var has_deed := false
var house_origin := Vector2i(-1, -1)   # top-left tile of the 3x3 house
var house_chest := {}
var house_last_visit := 0.0            # unix time
var rune := Vector2i(-1, -1)           # where Recall and Gate Travel lead (set with Mark)
var quest_index := 0                   # which of Quests.LIST is next or active
var quest_active := false
var quest_kills := 0


func has_house() -> bool:
	return house_origin.x >= 0


func house_center_tile() -> Vector2i:
	return house_origin + Vector2i(1, 1)


func days_since_visit() -> float:
	return maxf(0.0, (Time.get_unix_time_from_system() - house_last_visit) / 86400.0)


func condition() -> String:
	var per_stage := COLLAPSE_DAYS / STAGES.size()
	return STAGES[clampi(int(days_since_visit() / per_stage), 0, STAGES.size() - 1)]


func should_collapse() -> bool:
	return has_house() and days_since_visit() >= COLLAPSE_DAYS


## Being near the house keeps it standing.
func refresh() -> void:
	house_last_visit = Time.get_unix_time_from_system()


func clear_house() -> void:
	house_origin = Vector2i(-1, -1)
	house_chest = {}


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
		"bank_gold": bank_gold, "bank_items": bank_items, "has_deed": has_deed,
		"rune": [rune.x, rune.y], "quest_index": quest_index, "quest_active": quest_active,
		"quest_kills": quest_kills,
	}
	if has_house():
		d["house"] = {
			"x": house_origin.x, "y": house_origin.y,
			"chest": house_chest, "last_visit": house_last_visit,
		}
	return d


## Loads saved data, ignoring anything invalid.
func load_dict(d: Dictionary) -> void:
	bank_gold = maxi(0, int(d.get("bank_gold", 0)))
	bank_items = _clean_items(d.get("bank_items", {}))
	has_deed = bool(d.get("has_deed", false))
	var r: Variant = d.get("rune", [])
	if typeof(r) == TYPE_ARRAY and (r as Array).size() == 2:
		rune = Vector2i(int(r[0]), int(r[1]))
	quest_index = clampi(int(d.get("quest_index", 0)), 0, Quests.LIST.size() - 1)
	quest_active = bool(d.get("quest_active", false))
	quest_kills = maxi(0, int(d.get("quest_kills", 0)))
	clear_house()
	var h: Variant = d.get("house", null)
	if typeof(h) == TYPE_DICTIONARY:
		var hd: Dictionary = h
		house_origin = Vector2i(int(hd.get("x", -1)), int(hd.get("y", -1)))
		house_chest = _clean_items(hd.get("chest", {}))
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
