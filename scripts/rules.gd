class_name Rules
## Classic UO rule constants and formulas, from the project's mechanics reference.
## Formulas marked "reconstruction" are emulator approximations: tune, don't trust.

const STAT_CAP := 225
const STAT_MIN := 10
const STAT_MAX := 100           # per stat
const STAT_MAX_AT_CREATION := 45
const STAT_POINTS_AT_CREATION := 65
const SKILL_CAP_TOTAL := 700  # "template": seven skills at 100
const SKILL_MAX := 100


## Reconstruction (RunUO pre-AoS): (atk + 50) / (2 * (def + 50)), clamped to 0..1.
static func hit_chance(attacker_skill: float, defender_skill: float) -> float:
	return clampf((attacker_skill + 50.0) / (2.0 * (defender_skill + 50.0)), 0.0, 1.0)


## Players (the hero and the computer players) land at least this share of their swings, so a
## new character with no weapon skill hits most of the time; skill raises it to 95%.
const PLAYER_HIT_FLOOR := 0.85
## Players' melee damage is multiplied by this (zero Tactics would otherwise halve every blow).
const PLAYER_MELEE_BONUS := 1.5


static func player_hit_chance(attacker_skill: float, defender_skill: float) -> float:
	return maxf(hit_chance(attacker_skill, defender_skill), minf(PLAYER_HIT_FLOOR + attacker_skill / 1000.0, 0.95))


## Reconstruction: seconds per swing = 15000 / ((stamina + 100) * weapon_speed).
static func swing_seconds(stamina: int, weapon_speed: int) -> float:
	return 15000.0 / ((stamina + 100.0) * weapon_speed)


## Tactics scales damage by (-50% + Tactics/200): 0 halves it, 100 gives full.
static func tactics_multiplier(tactics: float) -> float:
	return 0.5 + tactics / 200.0


## Reconstruction: damage scaling from Tactics (-50%..0), Strength (~+20% at 100)
## and Anatomy (~Anatomy/2 %). Multiply the weapon's base damage roll by this.
static func damage_multiplier(strength: float, tactics: float, anatomy: float) -> float:
	return tactics_multiplier(tactics) * (1.0 + 0.2 * strength / 100.0) * (1.0 + anatomy / 200.0)


## Approximate: success rises from the circle's minimum skill to a sure cast about 40 points
## above it. Below the minimum the spell cannot be attempted.
static func cast_chance(magery: float, min_skill: float) -> float:
	if magery < min_skill:
		return 0.0
	return clampf((magery - min_skill) / 40.0, 0.05, 1.0)


## Approximate: Evaluating Intellect raises spell damage, up to +50% at 100.
static func spell_damage_multiplier(eval_int: float) -> float:
	return 1.0 + eval_int / 200.0


## Approximate: Resisting Spells lets the target halve spell damage (up to a 50% chance).
static func resist_chance(resisting: float) -> float:
	return clampf(resisting / 200.0, 0.0, 0.5)


## Mana per second. Meditation speeds it up; standing still ("active meditation") doubles it.
static func mana_regen(meditation: float, resting: bool) -> float:
	var rate := 0.3 * (1.0 + meditation / 50.0)
	return rate * 2.0 if resting else rate


## Approximate: bandages succeed more often with Healing; interrupted by taking damage.
static func bandage_chance(healing: float) -> float:
	return clampf(0.3 + healing / 150.0, 0.3, 0.95)


## Approximate: Healing and Anatomy both add to what a bandage restores.
static func bandage_heal(healing: float, anatomy: float) -> float:
	return 3.0 + healing / 20.0 + anatomy / 20.0


## Approximate: with a shield, Parry / 2 % chance (at most) to block part or all of a hit.
static func parry_chance(parrying: float) -> float:
	return clampf(parrying / 200.0, 0.0, 0.5)


## Approximate: gathering (Mining, Lumberjacking) succeeds more often with skill.
static func gather_chance(skill: float) -> float:
	return clampf(0.5 + skill / 200.0, 0.5, 0.95)


## Approximate: smelting uses Mining; rarer ore is harder. Failure loses the ore.
static func smelt_chance(mining: float, ore_min: float) -> float:
	return clampf(0.6 + (mining - ore_min) / 100.0, 0.1, 1.0)


## Approximate: 50% at the recipe's minimum skill, sure 25 points above it.
static func craft_chance(skill: float, min_skill: float) -> float:
	if skill < min_skill:
		return 0.0
	return clampf(0.5 + (skill - min_skill) / 50.0, 0.0, 1.0)


## Poison strengths: 0 none, 1 lesser, 2 regular, 3 greater. Damage per 2-second tick.
const POISON_DAMAGE := [0.0, 1.5, 3.0, 5.0]
const POISON_NAMES := ["", "lesser", "regular", "greater"]


## Approximate: how strong a poison a caster's Poison spell inflicts.
static func spell_poison_level(magery: float) -> int:
	if magery >= 90.0:
		return 3
	return 2 if magery >= 60.0 else 1


## Approximate: Cure gets harder against stronger poison.
static func cure_chance(magery: float, level: int) -> float:
	return clampf(0.4 + magery / 100.0 - 0.2 * (level - 1), 0.05, 1.0)


## Reference: with 60 Anatomy (and Healing to match) bandages can cure poison.
static func bandage_can_cure(healing: float, anatomy: float) -> bool:
	return healing >= 60.0 and anatomy >= 60.0


## Approximate: no chance more than 10 points below an animal's taming minimum; better with
## Animal Taming above it and a little better with Animal Lore.
static func tame_chance(taming: float, lore: float, min_skill: float) -> float:
	if taming < min_skill - 10.0:
		return 0.0
	return clampf(0.3 + (taming - min_skill) / 50.0 + lore / 500.0, 0.05, 0.95)


## Approximate: every bard performance first needs a good tune (Musicianship).
static func music_chance(musicianship: float) -> float:
	return clampf(0.5 + musicianship / 200.0, 0.5, 0.98)


## Approximate: Peacemaking / Provocation / Enticement against a creature of the given
## difficulty (0..100, from how dangerous it is). Musicianship helps every one of them.
static func bard_chance(skill: float, musicianship: float, difficulty: float) -> float:
	return clampf(0.5 + (skill + musicianship) / 400.0 - difficulty / 100.0, 0.05, 0.95)


## Approximate: Grandmaster-level crafters (90+) sometimes make exceptional pieces with a maker's mark.
static func exceptional_chance(skill: float) -> float:
	if skill < 90.0:
		return 0.0
	return clampf((skill - 80.0) / 100.0, 0.0, 0.3)


## Approximate: chances for the lesser skills.
static func track_chance(tracking: float) -> float:
	return clampf(0.4 + tracking / 150.0, 0.4, 0.95)


static func camp_chance(camping: float) -> float:
	return clampf(0.5 + camping / 200.0, 0.5, 0.98)


static func beg_chance(begging: float) -> float:
	return clampf(0.2 + begging / 150.0, 0.2, 0.85)


static func spirit_speak_chance(spirit: float) -> float:
	return clampf(0.3 + spirit / 150.0, 0.3, 0.95)


## Arms Lore (gear) and Item Identification (everything else): knowing an item's worth gets a
## better price, up to +50% at 100.
static func appraisal_bonus(skill: float) -> float:
	return 1.0 + clampf(skill, 0.0, 100.0) / 200.0


# --- fame, karma and titles (mechanics reference: the classic fame x karma title table) ----

const FAME_MAX := 10000
const KARMA_MAX := 10000
## Rows: fame 0-1249, 1250-2499, 2500-4999, 5000-9999, 10000. Columns: karma 10000+, 5000+,
## 2500+, 1250+, around zero, -1250 or less, -2500, -5000, -10000.
const TITLES := [
	["Trustworthy", "Honest", "Good", "Fair", "", "Rude", "Unsavory", "Scoundrel", "Outcast"],
	["Estimable", "Commendable", "Honorable", "Kind", "Notable", "Disreputable", "Dishonorable", "Malicious", "Wretched"],
	["Great", "Famed", "Admirable", "Respectable", "Prominent", "Notorious", "Ignoble", "Vile", "Nefarious"],
	["Illustrious", "Renowned", "Noble", "Proper", "Reputable", "Infamous", "Sinister", "Villainous", "Dread"],
	["Glorious Lord", "Great Lord", "Noble Lord", "Lord", "Lord", "Dishonored Lord", "Sinister Lord", "Dark Lord", "Dread Lord"],
]


static func title(fame: int, karma: int) -> String:
	var row := 0
	for limit in [1250, 2500, 5000, 10000]:
		if fame >= limit:
			row += 1
	var col := 4
	if karma >= 10000:
		col = 0
	elif karma >= 5000:
		col = 1
	elif karma >= 2500:
		col = 2
	elif karma >= 1250:
		col = 3
	elif karma <= -10000:
		col = 8
	elif karma <= -5000:
		col = 7
	elif karma <= -2500:
		col = 6
	elif karma <= -1250:
		col = 5
	return TITLES[row][col]


# --- thieves (mechanics reference: Hiding, Stealth, Snooping, Stealing, Detecting Hidden) ---

static func hide_chance(hiding: float) -> float:
	return clampf(0.2 + hiding / 120.0, 0.2, 0.95)


## How far you can walk while hidden (metres) before you are seen.
static func stealth_distance(stealth: float) -> float:
	return stealth / 6.0


static func snoop_chance(snooping: float) -> float:
	return clampf(0.3 + snooping / 150.0, 0.3, 0.95)


static func steal_chance(stealing: float) -> float:
	return clampf(0.15 + stealing / 130.0, 0.15, 0.9)


## Even a clean theft may be noticed (a failed one always is).
static func notice_chance(stealing: float) -> float:
	return clampf(0.4 - stealing / 300.0, 0.08, 0.4)


static func detect_chance(detecting: float, hiding: float) -> float:
	return clampf(0.15 + (detecting - hiding * 0.5) / 100.0, 0.05, 0.9)
