package com.shardsight.game.core

/**
 * Classic UO rule constants and formulas, from the project's mechanics reference.
 * Formulas marked "reconstruction" are emulator approximations: tune, don't trust.
 */
object Rules {
    const val STAT_CAP = 225
    const val STAT_MIN = 10
    const val STAT_MAX_AT_CREATION = 45
    const val STAT_POINTS_AT_CREATION = 65
    const val SKILL_CAP_TOTAL = 700      // "template": seven skills at 100
    const val SKILL_MAX = 100

    /** Reconstruction (RunUO pre-AoS): (atk+50) / (2*(def+50)), clamped to 0..1. */
    fun hitChance(attackerSkill: Float, defenderSkill: Float): Float =
        ((attackerSkill + 50f) / (2f * (defenderSkill + 50f))).coerceIn(0f, 1f)

    /** Reconstruction: seconds per swing = 15000 / ((stamina + 100) * weaponSpeed) */
    fun swingSeconds(stamina: Int, weaponSpeed: Int): Float =
        15000f / ((stamina + 100f) * weaponSpeed)

    /** Tactics scales damage by (-50% + Tactics/200): 0 halves it, 100 gives full. */
    fun tacticsMultiplier(tactics: Float): Float = 1f - 0.5f + tactics / 200f
}

enum class Skill { SWORDSMANSHIP, TACTICS, ANATOMY, MAGERY, MEDITATION, HEALING, WRESTLING }

/** No classes or levels: three stats, skills 0..100, hard caps. */
class Character(var str: Int = 25, var dex: Int = 20, var int: Int = 20) {
    val skills = Skill.values().associateWith { 0f }.toMutableMap()

    val maxHp get() = str
    val maxStamina get() = dex
    val maxMana get() = int
    val statTotal get() = str + dex + int
    val skillTotal get() = skills.values.sum()
}
