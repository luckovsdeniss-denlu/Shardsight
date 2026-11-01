class_name Hero
## No classes or levels: three stats, skills 0..100, hard caps.

enum Skill {
	SWORDSMANSHIP, TACTICS, ANATOMY, MAGERY, MEDITATION, HEALING, WRESTLING,
	EVALUATING_INTELLECT, RESISTING_SPELLS,
}

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


## Skills rise only by use: gains slow as a skill climbs and stop at the 700-point total cap.
func try_gain(skill: int) -> bool:
	var v: float = skills[skill]
	if v >= Rules.SKILL_MAX or skill_total() >= Rules.SKILL_CAP_TOTAL:
		return false
	if randf() < (Rules.SKILL_MAX - v) / Rules.SKILL_MAX * 0.5:
		skills[skill] = minf(v + 0.1, Rules.SKILL_MAX)
		return true
	return false
