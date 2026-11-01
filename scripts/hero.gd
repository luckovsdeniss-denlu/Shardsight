class_name Hero
## No classes or levels: three stats, skills 0..100, hard caps.

enum Skill { SWORDSMANSHIP, TACTICS, ANATOMY, MAGERY, MEDITATION, HEALING, WRESTLING }

var strength := 25
var dexterity := 20
var intelligence := 20
var skills := {}


func _init() -> void:
	for s in Skill.values():
		skills[s] = 0.0


func max_hp() -> int:
	return strength


func max_stamina() -> int:
	return dexterity


func max_mana() -> int:
	return intelligence


func stat_total() -> int:
	return strength + dexterity + intelligence


func skill_total() -> float:
	var t := 0.0
	for v in skills.values():
		t += v
	return t
