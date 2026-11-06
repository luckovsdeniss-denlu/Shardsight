class_name Hero
## No classes or levels: three stats, skills 0..100, hard caps. Skills and stats rise only by use.

signal skill_gained(skill_name: String, value: float)
signal stat_gained(stat_name: String, value: int)

# Append new skills at the end: saved games store skills by number.
enum Skill {
	SWORDSMANSHIP, TACTICS, ANATOMY, MAGERY, MEDITATION, HEALING, WRESTLING,
	EVALUATING_INTELLECT, RESISTING_SPELLS, PARRYING,
	MINING, LUMBERJACKING, BLACKSMITHY, TAILORING, CARPENTRY, ALCHEMY,
	ANIMAL_TAMING, ANIMAL_LORE, VETERINARY,
	MUSICIANSHIP, PEACEMAKING, PROVOCATION, ENTICEMENT,
	ARCHERY, FENCING, MACE_FIGHTING, TRACKING, CAMPING, ARMS_LORE, ITEM_IDENTIFICATION, BEGGING,
	SPIRIT_SPEAK,
}
enum Lock { UP, DOWN, LOCKED }   # up: may rise; down: may be lost near the cap; locked: frozen
enum Stat { STR, DEX, INT }

const STAT_NAMES := ["Strength", "Dexterity", "Intelligence"]
const STAT_OF := {
	Skill.SWORDSMANSHIP: Stat.STR, Skill.TACTICS: Stat.STR, Skill.WRESTLING: Stat.STR,
	Skill.ANATOMY: Stat.STR, Skill.PARRYING: Stat.DEX, Skill.HEALING: Stat.DEX,
	Skill.MAGERY: Stat.INT, Skill.MEDITATION: Stat.INT,
	Skill.EVALUATING_INTELLECT: Stat.INT, Skill.RESISTING_SPELLS: Stat.INT,
	Skill.MINING: Stat.STR, Skill.LUMBERJACKING: Stat.STR, Skill.BLACKSMITHY: Stat.STR,
	Skill.TAILORING: Stat.DEX, Skill.CARPENTRY: Stat.STR, Skill.ALCHEMY: Stat.INT,
	Skill.ANIMAL_TAMING: Stat.INT, Skill.ANIMAL_LORE: Stat.INT, Skill.VETERINARY: Stat.DEX,
	Skill.MUSICIANSHIP: Stat.DEX, Skill.PEACEMAKING: Stat.INT, Skill.PROVOCATION: Stat.INT,
	Skill.ENTICEMENT: Stat.INT,
	Skill.ARCHERY: Stat.DEX, Skill.FENCING: Stat.DEX, Skill.MACE_FIGHTING: Stat.STR,
	Skill.TRACKING: Stat.INT, Skill.CAMPING: Stat.INT, Skill.ARMS_LORE: Stat.INT,
	Skill.ITEM_IDENTIFICATION: Stat.INT, Skill.BEGGING: Stat.DEX, Skill.SPIRIT_SPEAK: Stat.INT,
}
const STAT_GAIN_CHANCE := 0.06   # per skill gain: stats rise much slower than skills

var strength := 25
var dexterity := 20
var intelligence := 20
var skills := {}
var locks := {}


func _init() -> void:
	for s in Skill.values():
		skills[s] = 0.0
		locks[s] = Lock.UP


static func skill_name(s: int) -> String:
	return String(Skill.keys()[s]).capitalize()


## Temporary changes from spells (Bless, Weaken, Curse...): they never touch the stats themselves,
## so saving, stat gains and the stat cap only ever see the real values.
var str_mod := 0
var dex_mod := 0
var int_mod := 0


func eff_str() -> int:
	return maxi(1, strength + str_mod)


func max_hp() -> int:
	return eff_str()


func max_stamina() -> int:
	return maxi(1, dexterity + dex_mod)


func max_mana() -> int:
	return maxi(0, intelligence + int_mod)


func stat_total() -> int:
	return strength + dexterity + intelligence


func skill_total() -> float:
	var t := 0.0
	for v in skills.values():
		t += v
	return t


## Player level 1..1000, from the total of all skills: a new hero is level 1, and a full
## skill total (the cap) is level 1000. Derived, so nothing extra is saved.
const LEVEL_MAX := 1000

func level() -> int:
	var frac := clampf(skill_total() / float(Rules.SKILL_CAP_TOTAL), 0.0, 1.0)
	return clampi(1 + floori(frac * (LEVEL_MAX - 1)), 1, LEVEL_MAX)


func get_stat(stat: int) -> int:
	match stat:
		Stat.STR:
			return strength
		Stat.DEX:
			return dexterity
		_:
			return intelligence


func set_stat(stat: int, value: int) -> void:
	match stat:
		Stat.STR:
			strength = value
		Stat.DEX:
			dexterity = value
		_:
			intelligence = value


## Skills rise only by use: gains slow as a skill climbs. At the 700-point cap a gain must be
## paid for by a skill marked "down"; if there is none, the gain is refused.
func try_gain(skill: int) -> bool:
	if int(locks.get(skill, Lock.UP)) != Lock.UP:
		return false
	var v: float = skills[skill]
	if v >= Rules.SKILL_MAX:
		return false
	if randf() >= (Rules.SKILL_MAX - v) / Rules.SKILL_MAX * 0.5:
		return false
	if skill_total() + 0.1 > Rules.SKILL_CAP_TOTAL + 0.001 and not _take_from_down_skill(skill):
		return false
	var nv := snappedf(minf(v + 0.1, Rules.SKILL_MAX), 0.1)
	skills[skill] = nv
	if floorf(nv) > floorf(v):
		skill_gained.emit(skill_name(skill), nv)
	_try_stat_gain(skill)
	return true


func _take_from_down_skill(except: int) -> bool:
	var best := -1
	var best_v := 0.0
	for s in skills:
		if s == except or int(locks[s]) != Lock.DOWN:
			continue
		if float(skills[s]) > best_v:
			best = s
			best_v = float(skills[s])
	if best < 0 or best_v < 0.1:
		return false
	skills[best] = snappedf(best_v - 0.1, 0.1)
	return true


## Using a skill slowly raises its stat. At the 225 stat cap, raising one lowers another.
func _try_stat_gain(skill: int) -> void:
	if not STAT_OF.has(skill) or randf() >= STAT_GAIN_CHANCE:
		return
	var stat: int = STAT_OF[skill]
	if get_stat(stat) >= Rules.STAT_MAX:
		return
	if stat_total() >= Rules.STAT_CAP and not _lower_other_stat(stat):
		return
	set_stat(stat, get_stat(stat) + 1)
	stat_gained.emit(STAT_NAMES[stat], get_stat(stat))


func _lower_other_stat(except: int) -> bool:
	var best := -1
	var best_v := Rules.STAT_MIN
	for stat in [Stat.STR, Stat.DEX, Stat.INT]:
		if stat != except and get_stat(stat) > best_v:
			best = stat
			best_v = get_stat(stat)
	if best < 0:
		return false
	set_stat(best, get_stat(best) - 1)
	return true
