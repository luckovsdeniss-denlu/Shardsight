class_name SaveGame
## Saves the hero to user://shardsight_save.json (readable JSON). The world, monsters and the
## other characters are not saved; they start fresh each launch.

const PATH := "user://shardsight_save.json"
const FORMAT := 1


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func erase() -> void:
	if exists():
		DirAccess.remove_absolute(PATH)


static func save(hero: Entity) -> bool:
	var skills := {}
	for s in hero.stats.skills:
		skills[str(s)] = hero.stats.skills[s]
	var tile := hero.world.to_tile(hero.position)
	var data := {
		"format": FORMAT,
		"version": ProjectSettings.get_setting("application/config/version", ""),
		"str": hero.stats.strength,
		"dex": hero.stats.dexterity,
		"int": hero.stats.intelligence,
		"skills": skills,
		"gold": hero.gold,
		"reagents": hero.reagents,
		"inventory": hero.inventory,
		"weapon": hero.weapon,
		"armor": hero.armor_id,
		"tile": [tile.x, tile.y],
	}
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


## Loads a save into the hero. Everything is validated; bad or old data is ignored.
static func load_into(hero: Entity) -> bool:
	if not exists():
		return false
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	if int(d.get("format", 0)) != FORMAT:
		return false

	hero.stats.strength = clampi(int(d.get("str", hero.stats.strength)), Rules.STAT_MIN, Rules.STAT_CAP)
	hero.stats.dexterity = clampi(int(d.get("dex", hero.stats.dexterity)), Rules.STAT_MIN, Rules.STAT_CAP)
	hero.stats.intelligence = clampi(int(d.get("int", hero.stats.intelligence)), Rules.STAT_MIN, Rules.STAT_CAP)

	var skills: Dictionary = d.get("skills", {})
	for key in skills:
		var id := int(key)
		if hero.stats.skills.has(id):
			hero.stats.skills[id] = clampf(float(skills[key]), 0.0, float(Rules.SKILL_MAX))

	hero.gold = maxi(0, int(d.get("gold", 0)))
	hero.reagents = clampf(float(d.get("reagents", hero.reagents)), 0.0, Entity.MAX_REAGENTS)

	hero.inventory.clear()
	var inv: Dictionary = d.get("inventory", {})
	for key in inv:
		var item_id := String(key)
		if Gear.LIST.has(item_id) or Items.LIST.has(item_id):
			hero.inventory[item_id] = maxi(1, int(inv[key]))

	var w := String(d.get("weapon", hero.weapon))
	hero.weapon = w if Gear.LIST.has(w) and String(Gear.LIST[w]["slot"]) == "weapon" else ""
	var a := String(d.get("armor", hero.armor_id))
	hero.armor_id = a if Gear.LIST.has(a) and String(Gear.LIST[a]["slot"]) == "armor" else ""

	var t: Array = d.get("tile", [])
	if t.size() == 2:
		var c := Vector2i(int(t[0]), int(t[1]))
		if not hero.world.is_blocked(c):
			hero.position = hero.world.tile_center(c)
	hero.hp = float(hero.stats.max_hp())
	hero.mana = float(hero.stats.max_mana())
	return true
