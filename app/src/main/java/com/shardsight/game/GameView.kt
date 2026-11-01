package com.shardsight.game

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.view.MotionEvent
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.shardsight.game.core.Character
import com.shardsight.game.core.Rules

/** Render loop on its own thread. Placeholder world: tile grid, tap a tile to walk there. */
class GameView(ctx: Context) : SurfaceView(ctx), SurfaceHolder.Callback, Runnable {

    private val hero = Character()
    private var thread: Thread? = null
    @Volatile private var running = false

    private val tile = 96f
    private val cols = 40
    private val rows = 40
    private var px = 20f; private var py = 20f           // player position in tile units
    @Volatile private var tx = 20f; @Volatile private var ty = 20f  // target tile
    private val speed = 4f                               // tiles per second

    private val text = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; textSize = 36f }
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

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (e.action == MotionEvent.ACTION_DOWN || e.action == MotionEvent.ACTION_MOVE) {
            // Camera is centred on the player, so screen offset maps to tile offset.
            tx = (px + (e.x - width / 2f) / tile).coerceIn(0f, cols - 1f)
            ty = (py + (e.y - height / 2f) / tile).coerceIn(0f, rows - 1f)
        }
        return true
    }

    override fun run() {
        var last = System.nanoTime()
        while (running) {
            val now = System.nanoTime()
            val dt = (now - last) / 1e9f
            last = now
            update(dt)
            val c = holder.lockCanvas() ?: continue
            try { draw(c) } finally { holder.unlockCanvasAndPost(c) }
            Thread.sleep(16)
        }
    }

    private fun update(dt: Float) {
        val dx = tx - px; val dy = ty - py
        val dist = kotlin.math.sqrt(dx * dx + dy * dy)
        val step = speed * dt
        if (dist <= step) { px = tx; py = ty } else { px += dx / dist * step; py += dy / dist * step }
    }

    private fun draw(c: Canvas) {
        c.drawColor(Color.rgb(14, 16, 24))
        val cx = c.width / 2f; val cy = c.height / 2f
        val ox = cx - px * tile; val oy = cy - py * tile   // world -> screen offset

        for (i in 0..cols) c.drawLine(ox + i * tile, oy, ox + i * tile, oy + rows * tile, line)
        for (j in 0..rows) c.drawLine(ox, oy + j * tile, ox + cols * tile, oy + j * tile, line)

        fill.color = Color.rgb(240, 200, 80)
        c.drawCircle(cx, cy, 26f, fill)
        fill.color = Color.argb(120, 90, 200, 255)
        c.drawCircle(ox + tx * tile, oy + ty * tile, 10f, fill)   // move target

        c.drawText("HP ${hero.maxHp}   Stam ${hero.maxStamina}   Mana ${hero.maxMana}", 32f, 60f, text)
        c.drawText("Hit chance 100 vs 100: %.0f%%".format(Rules.hitChance(100f, 100f) * 100), 32f, 106f, text)
    }
}
