class_name Rules
## Classic UO rule constants and formulas, from the project's mechanics reference.
## Formulas marked "reconstruction" are emulator approximations: tune, don't trust.

const STAT_CAP := 225
const STAT_MIN := 10
const STAT_MAX_AT_CREATION := 45
const STAT_POINTS_AT_CREATION := 65
const SKILL_CAP_TOTAL := 700  # "template": seven skills at 100
const SKILL_MAX := 100


## Reconstruction (RunUO pre-AoS): (atk + 50) / (2 * (def + 50)), clamped to 0..1.
static func hit_chance(attacker_skill: float, defender_skill: float) -> float:
	return clampf((attacker_skill + 50.0) / (2.0 * (defender_skill + 50.0)), 0.0, 1.0)


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
