package com.shardsight.game.sensors

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Bundle
import kotlin.math.sqrt

/**
 * Compass, gyroscope, GPS and microphone in one place.
 * All fields are @Volatile snapshots, so the game thread reads them without locking.
 * Call start() from onResume and stop() from onPause.
 */
class SensorHub(private val ctx: Context) : SensorEventListener, LocationListener {

    @Volatile var headingDeg = 0f; private set            // 0 = north, clockwise
    @Volatile var gyroX = 0f; private set                  // rad/s
    @Volatile var gyroY = 0f; private set
    @Volatile var gyroZ = 0f; private set
    @Volatile var latitude = 0.0; private set
    @Volatile var longitude = 0.0; private set
    @Volatile var hasFix = false; private set
    @Volatile var micLevel = 0f; private set               // 0..1 loudness

    private val sm = ctx.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val lm = ctx.getSystemService(Context.LOCATION_SERVICE) as LocationManager
    @Volatile private var micThread: Thread? = null

    private val rotation = FloatArray(9)
    private val orientation = FloatArray(3)

    private fun granted(p: String) =
        ctx.checkSelfPermission(p) == PackageManager.PERMISSION_GRANTED

    fun start() {
        sm.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)?.let {
            sm.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }
        sm.getDefaultSensor(Sensor.TYPE_GYROSCOPE)?.let {
            sm.registerListener(this, it, SensorManager.SENSOR_DELAY_GAME)
        }
        if (granted(Manifest.permission.ACCESS_FINE_LOCATION) &&
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER)
        ) {
            lm.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000L, 1f, this)
        }
        if (granted(Manifest.permission.RECORD_AUDIO)) startMic()
    }

    fun stop() {
        sm.unregisterListener(this)
        lm.removeUpdates(this)
        micThread?.interrupt()
        micThread = null
    }

    // --- compass + gyroscope ---
    override fun onSensorChanged(e: SensorEvent) {
        when (e.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                SensorManager.getRotationMatrixFromVector(rotation, e.values)
                SensorManager.getOrientation(rotation, orientation)
                headingDeg = ((Math.toDegrees(orientation[0].toDouble()) + 360.0) % 360.0).toFloat()
            }
            Sensor.TYPE_GYROSCOPE -> {
                gyroX = e.values[0]; gyroY = e.values[1]; gyroZ = e.values[2]
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    // --- GPS ---
    override fun onLocationChanged(loc: Location) {
        latitude = loc.latitude
        longitude = loc.longitude
        hasFix = true
    }

    @Deprecated("Needed for API < 30")
    override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    override fun onProviderEnabled(provider: String) {}
    override fun onProviderDisabled(provider: String) {}

    // --- microphone (RMS loudness only; no audio is stored) ---
    private fun startMic() {
        if (micThread != null) return
        val rate = 16000
        val min = AudioRecord.getMinBufferSize(
            rate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT
        )
        if (min <= 0) return
        val t = Thread {
            val rec = try {
                AudioRecord(
                    MediaRecorder.AudioSource.MIC, rate,
                    AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, min * 2
                )
            } catch (_: SecurityException) { return@Thread }
            if (rec.state != AudioRecord.STATE_INITIALIZED) { rec.release(); return@Thread }
            val buf = ShortArray(min)
            try {
                rec.startRecording()
                while (!Thread.currentThread().isInterrupted) {
                    val n = rec.read(buf, 0, buf.size)
                    if (n <= 0) continue
                    var sum = 0.0
                    for (i in 0 until n) sum += buf[i].toDouble() * buf[i]
                    micLevel = (sqrt(sum / n) / 8000.0).coerceIn(0.0, 1.0).toFloat()
                }
            } finally {
                rec.stop(); rec.release(); micLevel = 0f
            }
        }
        micThread = t
        t.start()
    }
}
