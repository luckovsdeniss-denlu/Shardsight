package com.shardsight.game

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.shardsight.game.core.Character
import com.shardsight.game.core.Rules
import com.shardsight.game.sensors.SensorHub
import kotlin.math.cos
import kotlin.math.sin

/** Fixed-timestep-ish render loop on its own thread. Placeholder world: a grid that rotates with the compass. */
class GameView(ctx: Context, private val sensors: SensorHub) :
    SurfaceView(ctx), SurfaceHolder.Callback, Runnable {

    private val hero = Character()
    private var thread: Thread? = null
    @Volatile private var running = false

    private val text = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; textSize = 38f }
    private val line = Paint().apply { color = Color.rgb(60, 70, 90); strokeWidth = 2f }
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)

    init { holder.addCallback(this) }

    override fun surfaceCreated(h: SurfaceHolder) {
        running = true
        thread = Thread(this, "game-loop").also { it.start() }
    }

    override fun surfaceChanged(h: SurfaceHolder, f: Int, w: Int, ht: Int) {}

    override fun surfaceDestroyed(h: SurfaceHolder) {
        running = false
        thread?.join()
        thread = null
    }

    override fun run() {
        while (running) {
            val c = holder.lockCanvas() ?: continue
            try { draw(c) } finally { holder.unlockCanvasAndPost(c) }
            Thread.sleep(16)
        }
    }

    private fun draw(c: Canvas) {
        c.drawColor(Color.rgb(14, 16, 24))
        val w = c.width.toFloat(); val h = c.height.toFloat()
        val cx = w / 2; val cy = h * 0.45f
        val heading = Math.toRadians(sensors.headingDeg.toDouble())

        // World grid rotated against the heading, so "forward" is always up the screen.
        c.save()
        c.rotate(-sensors.headingDeg, cx, cy)
        val step = 90f
        var g = -12
        while (g <= 12) {
            c.drawLine(cx + g * step, cy - 12 * step, cx + g * step, cy + 12 * step, line)
            c.drawLine(cx - 12 * step, cy + g * step, cx + 12 * step, cy + g * step, line)
            g++
        }
        fill.color = Color.rgb(200, 60, 60)           // "north" marker
        c.drawCircle(cx, cy - 6 * step, 18f, fill)
        c.restore()

        // Player.
        fill.color = Color.rgb(240, 200, 80)
        c.drawCircle(cx, cy, 26f, fill)

        // Mic: loud shout lights the ring (stand-in for "guards!" / spell words of power).
        fill.color = Color.argb((sensors.micLevel * 255).toInt(), 90, 200, 255)
        c.drawCircle(cx, cy, 60f + sensors.micLevel * 140f, fill)

        // HUD.
        var y = 90f
        fun row(s: String) { c.drawText(s, 32f, y, text); y += 50f }
        row("Heading  %.0f°".format(sensors.headingDeg))
        row("Gyro     %.2f  %.2f  %.2f".format(sensors.gyroX, sensors.gyroY, sensors.gyroZ))
        row(if (sensors.hasFix) "GPS      %.5f, %.5f".format(sensors.latitude, sensors.longitude)
            else "GPS      searching…")
        row("Mic      %d%%".format((sensors.micLevel * 100).toInt()))
        y = h - 160f
        row("HP ${hero.maxHp}  Stam ${hero.maxStamina}  Mana ${hero.maxMana}")
        row("Hit 100v100: %.0f%%".format(Rules.hitChance(100f, 100f) * 100))
    }
}
