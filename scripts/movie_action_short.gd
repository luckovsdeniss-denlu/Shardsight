class_name MovieActionShort
extends MovieAction
## The short action trailer ("Action short" on the start screen): about half a minute of the
## action trailer, for sharing - the company charging in, the hunt, the dead, the Shardveil's
## chaos and the giant - cut on the beat of the score, then the logo. It's its own script, so
## nothing here changes the full one.

## The scenes, in order, and how long each runs here (seconds).
const CUT := [["SHARDSIGHT", 3.0], ["Side by side", 4.5], ["Bounty hunters", 4.0], ["Night of the dead", 4.0],
	["The Shardveil", 4.5], ["World bosses", 5.5], ["Join the fight", 3.5]]


func _shape_shots() -> void:
	var by_title := {}
	for sh: Dictionary in shots:
		by_title[String(sh["title"])] = sh
	var cut: Array = []
	for pair in CUT:
		var title := String(pair[0])
		if not by_title.has(title):
			continue
		var sh: Dictionary = by_title[title]
		sh["dur"] = float(pair[1])
		var words: Array = sh.get("words", []) as Array
		if words.size() > 1:
			sh["words"] = [words[0]]                 # one word each: short and sharp
		var story: Array = sh.get("story", []) as Array
		var kept: Array = []
		for line in story:
			if String(line[0]) != "hero":
				kept.append(line)
				break
		sh["story"] = kept
		cut.append(sh)
	shots = cut


## No loading screen first: straight in (every second counts).
func _intro_loading() -> void:
	running = true
	_next()
