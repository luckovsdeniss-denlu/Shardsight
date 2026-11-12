class_name Guilds
## Guilds (mechanics reference: guild members show green to each other, enemies at war orange;
## members of guilds at war may fight anywhere outside town without becoming criminals or
## murderers; allied guilds don't fight each other). Three guilds of computer players exist from
## the start; the hero can join one, or found their own and invite players into it.

const FOUND_COST := 1000          # gold from the bank to found a guild
const INVITE_COOLDOWN := 120.0    # a player who said no won't be asked again for this long

## The guilds of the computer players: id -> name, abbreviation, starting members.
const STARTING := {
	"oss": {"name": "Order of the Silver Serpent", "abbr": "OSS", "members": ["Aldric", "Mira", "Gareth", "Rowan", "Torin"]},
	"wos": {"name": "Wardens of Southmoor", "abbr": "WOS", "members": ["Dorian", "Lyra", "Isla", "Faye"]},
	"shd": {"name": "Shadowclan", "abbr": "SHD", "members": ["Vex", "Morg", "Garrick"]},
}
const STARTING_WARS := [["oss", "shd"], ["wos", "shd"]]
const STARTING_ALLIES := [["oss", "wos"]]

var list := {}                    # id -> {"name", "abbr", "members": Array, "leader"}
var wars := {}                    # "a|b" (sorted) -> true
var allies := {}                  # "a|b" (sorted) -> true
var member_of := {}               # player name -> guild id
var invite_cd := {}               # player name -> seconds before they can be asked again


func _init() -> void:
	for id in STARTING:
		var g: Dictionary = STARTING[id]
		list[id] = {"name": g["name"], "abbr": g["abbr"], "members": (g["members"] as Array).duplicate(), "leader": ""}
		for m in g["members"]:
			member_of[m] = id
	for p in STARTING_WARS:
		wars[_pair(p[0], p[1])] = true
	for p in STARTING_ALLIES:
		allies[_pair(p[0], p[1])] = true


static func _pair(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func guild_of(player_name: String) -> String:
	return String(member_of.get(player_name, ""))


func abbr(id: String) -> String:
	return String(list[id]["abbr"]) if list.has(id) else ""


func at_war(a: String, b: String) -> bool:
	return a != "" and b != "" and a != b and wars.has(_pair(a, b))


func allied(a: String, b: String) -> bool:
	return a != "" and b != "" and (a == b or allies.has(_pair(a, b)))


func join(player_name: String, id: String) -> void:
	leave(player_name)
	if not list.has(id):
		return
	(list[id]["members"] as Array).append(player_name)
	member_of[player_name] = id


func leave(player_name: String) -> void:
	var id := guild_of(player_name)
	if id == "":
		return
	(list[id]["members"] as Array).erase(player_name)
	member_of.erase(player_name)
	if id == "player" and String(list[id]["leader"]) == player_name:
		disband("player")               # the founder leaving ends the guild


func found(leader: String, guild_name: String, guild_abbr: String) -> void:
	leave(leader)
	list["player"] = {"name": guild_name, "abbr": guild_abbr, "members": [leader], "leader": leader}
	member_of[leader] = "player"


func disband(id: String) -> void:
	if not list.has(id):
		return
	for m in (list[id]["members"] as Array).duplicate():
		member_of.erase(m)
	list.erase(id)
	for k in wars.keys():
		if (k as String).split("|").has(id):
			wars.erase(k)
	for k in allies.keys():
		if (k as String).split("|").has(id):
			allies.erase(k)


func set_war(a: String, b: String, on: bool) -> void:
	if on:
		allies.erase(_pair(a, b))
		wars[_pair(a, b)] = true
	else:
		wars.erase(_pair(a, b))


func set_ally(a: String, b: String, on: bool) -> void:
	if on:
		wars.erase(_pair(a, b))
		allies[_pair(a, b)] = true
	else:
		allies.erase(_pair(a, b))


func tick(delta: float) -> void:
	for n in invite_cd.keys():
		invite_cd[n] = float(invite_cd[n]) - delta
		if float(invite_cd[n]) <= 0.0:
			invite_cd.erase(n)


## Saved with the game: the hero's own guild (if any), which guild the hero is in, and the
## hero guild's wars and alliances. The computer guilds always start from STARTING.
func to_dict(hero_name: String) -> Dictionary:
	var d := {"member": guild_of(hero_name)}
	if list.has("player"):
		d["own"] = list["player"].duplicate(true)
		var rel := {}
		for id in list:
			if id == "player":
				continue
			if at_war("player", id):
				rel[id] = "war"
			elif allied("player", id):
				rel[id] = "ally"
		d["relations"] = rel
	return d


func load_dict(d: Dictionary, hero_name: String, valid_names: Array) -> void:
	var own: Variant = d.get("own", null)
	if typeof(own) == TYPE_DICTIONARY:
		var o: Dictionary = own
		found(hero_name, String(o.get("name", hero_name + "'s Company")), String(o.get("abbr", "HCO")).left(4))
		for m in o.get("members", []):
			var n := String(m)
			if n != hero_name and valid_names.has(n):
				join(n, "player")
		var rel: Variant = d.get("relations", {})
		if typeof(rel) == TYPE_DICTIONARY:
			for id in rel:
				if list.has(id) and id != "player":
					if String(rel[id]) == "war":
						set_war("player", id, true)
					elif String(rel[id]) == "ally":
						set_ally("player", id, true)
	var member := String(d.get("member", ""))
	if member != "" and list.has(member) and guild_of(hero_name) != member:
		join(hero_name, member)
