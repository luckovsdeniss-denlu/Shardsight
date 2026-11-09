class_name SaveGame
## Saves the hero (with bank and house) to user://shardsight_save.json (readable JSON). The world, monsters and the
## other characters are not saved; they start fresh each launch.

const PATH := "user://shardsight_save.json"
static var slot := ""                     # "" for the ordinary game, "_experimental" for experimental mode


static func path() -> String:
	return "user://shardsight_save%s.json" % slot
const FORMAT := 1


static func exists() -> bool:
	return FileAccess.file_exists(path())


static func erase() -> void:
	if exists():
		DirAccess.remove_absolute(path())


static func _pets_of(hero: Entity) -> Array:
	var out := []
	for p in hero.pets:
		if not p.dead and p.species != "" and not p.summoned:   # summons fade, they aren't kept
			out.append({"species": p.species, "name": p.display_name, "hp": p.hp})
	return out


static func save(hero: Entity, property: Property) -> bool:
	var skills := {}
	for s in hero.stats.skills:
		skills[str(s)] = hero.stats.skills[s]
	var locks := {}
	for s in hero.stats.locks:
		locks[str(s)] = hero.stats.locks[s]
	var tile := hero.world.to_tile(hero.position)
	var data := {
		"format": FORMAT,
		"version": ProjectSettings.get_setting("application/config/version", ""),
		"str": hero.stats.strength,
		"dex": hero.stats.dexterity,
		"int": hero.stats.intelligence,
		"skills": skills,
		"locks": locks,
		"bandages": hero.bandages,
		"arrows": hero.arrows,
		"tool_uses": hero.tool_uses,
		"murders": hero.murder_counts,
		"fame": hero.fame,
		"karma": hero.karma,
		"guilds": hero.game.guilds.to_dict(hero.display_name),
		"pets": _pets_of(hero),
		"mounted": hero.mounted_on != null,
		"auto_equip": hero.auto_equip,
		"spellbook": hero.spellbook.keys(),
		"property": property.to_dict(),
		"shield": hero.shield_id,
		"gold": hero.gold,
		"reagents": hero.reagents,
		"inventory": hero.inventory,
		"weapon": hero.weapon,
		"armor": hero.armor_id,
		"ring": hero.ring_id,
		"wear": hero.wear,
		"amulet": hero.amulet_id,
		"tile": [tile.x, tile.y],
	}
	var f := FileAccess.open(path(), FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


## Loads a save into the hero. Everything is validated; bad or old data is ignored.
static func load_into(hero: Entity, property: Property) -> bool:
	if not exists():
		return false
	var f := FileAccess.open(path(), FileAccess.READ)
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

	var locks: Dictionary = d.get("locks", {})
	for key in locks:
		var id := int(key)
		if hero.stats.locks.has(id):
			hero.stats.locks[id] = clampi(int(locks[key]), 0, 2)

	hero.murder_counts = clampi(int(d.get("murders", 0)), 0, 99)
	hero.fame = clampi(int(d.get("fame", 0)), 0, Rules.FAME_MAX)
	hero.karma = clampi(int(d.get("karma", 0)), -Rules.KARMA_MAX, Rules.KARMA_MAX)
	var gd: Variant = d.get("guilds", {})
	if typeof(gd) == TYPE_DICTIONARY:
		var names := []
		for e in hero.game.creatures:
			if e.kind == Entity.Kind.PLAYER:
				names.append(e.display_name)
		hero.game.guilds.load_dict(gd, hero.display_name, names)
	var pets: Variant = d.get("pets", [])
	if typeof(pets) == TYPE_ARRAY:
		hero.game.saved_pets = pets            # spawned next to the hero once the world is up
	hero.game.saved_mounted = bool(d.get("mounted", false))
	hero.auto_equip = bool(d.get("auto_equip", true))
	hero.murder_timer = Entity.MURDER_DECAY
	hero.bandages = clampi(int(d.get("bandages", hero.bandages)), 0, Entity.MAX_BANDAGES)
	hero.arrows = clampi(int(d.get("arrows", hero.arrows)), 0, 500)
	var uses = d.get("tool_uses", {})
	if uses is Dictionary:
		for t in Entity.TOOLS:
			if uses.has(t):
				hero.tool_uses[t] = clampi(int(uses[t]), 1, Entity.TOOL_USES)
	# Saves from before spellbooks keep the starting circles plus the travel spells they had.
	var book: Variant = d.get("spellbook", Spells.STARTER + ["mark", "gate_travel"])
	if typeof(book) == TYPE_ARRAY:
		hero.spellbook.clear()
		for id in book:
			if Spells.LIST.has(String(id)):
				hero.spellbook[String(id)] = true
	hero.gold = maxi(0, int(d.get("gold", 0)))
	hero.reagents = clampf(float(d.get("reagents", hero.reagents)), 0.0, Entity.MAX_REAGENTS)

	hero.inventory.clear()
	var inv: Dictionary = d.get("inventory", {})
	for key in inv:
		var item_id := String(key)
		if Items.is_known(item_id):
			hero.inventory[item_id] = maxi(1, int(inv[key]))

	var w := String(d.get("weapon", hero.weapon))
	hero.weapon = w if Gear.has(w) and String(Gear.stats(w)["slot"]) == "weapon" else ""
	var a := String(d.get("armor", hero.armor_id))
	hero.armor_id = a if Gear.has(a) and String(Gear.stats(a)["slot"]) == "armor" else ""
	var sh := String(d.get("shield", hero.shield_id))
	hero.shield_id = sh if Gear.has(sh) and String(Gear.stats(sh)["slot"]) == "shield" else ""
	var wr: Variant = d.get("wear", {})
	if wr is Dictionary:
		for k in wr:
			if Gear.has(String(k)):
				hero.wear[String(k)] = clampi(int(wr[k]), 1, Gear.max_durability(String(k)))
	var rg := String(d.get("ring", ""))
	hero.ring_id = rg if Jewelry.slot(rg) == "ring" else ""
	var am := String(d.get("amulet", ""))
	hero.amulet_id = am if Jewelry.slot(am) == "amulet" else ""
	hero._recompute_effects()

	var t: Array = d.get("tile", [])
	if t.size() == 2:
		var c := Vector2i(int(t[0]), int(t[1]))
		if not hero.world.is_blocked(c):
			hero.position = hero.world.tile_center(c)
	var prop: Variant = d.get("property", {})
	if typeof(prop) == TYPE_DICTIONARY:
		property.load_dict(prop)
	hero.hp = float(hero.stats.max_hp())
	hero.mana = float(hero.stats.max_mana())
	return true
