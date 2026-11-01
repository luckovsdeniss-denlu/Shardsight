package com.shardsight.game

import android.Manifest
import android.app.Activity
import android.os.Bundle
import com.shardsight.game.sensors.SensorHub

class MainActivity : Activity() {
    private lateinit var sensors: SensorHub

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        sensors = SensorHub(this)
        setContentView(GameView(this, sensors))
        requestPermissions(
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.RECORD_AUDIO), 1
        )
    }

    override fun onResume() { super.onResume(); sensors.start() }
    override fun onPause() { sensors.stop(); super.onPause() }

    override fun onRequestPermissionsResult(code: Int, perms: Array<out String>, res: IntArray) {
        super.onRequestPermissionsResult(code, perms, res)
        sensors.stop(); sensors.start()   // pick up newly granted permissions
    }
}
