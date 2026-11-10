package com.vedam.myapp

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val COMPASS_CHANNEL = "org.vedam.vedam_app/compass"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, COMPASS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var sensorManager: SensorManager? = null
                private var sensorEventListener: SensorEventListener? = null
                private var currentAccuracy = SensorManager.SENSOR_STATUS_ACCURACY_HIGH

                // Fallback arrays for accel + mag
                private var lastAccelerometer = FloatArray(3)
                private var lastMagnetometer = FloatArray(3)
                private var isAccelerometerSet = false
                private var isMagnetometerSet = false

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    sensorManager = getSystemService(Context.SENSOR_SERVICE) as? SensorManager
                    if (sensorManager == null) {
                        events?.error("SENSOR_UNAVAILABLE", "SensorManager is not available on this device", null)
                        return
                    }

                    val rotationSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
                    val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
                    val magnetometer = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

                    if (rotationSensor == null && (accelerometer == null || magnetometer == null)) {
                        events?.error("SENSOR_UNAVAILABLE", "No orientation or magnetic sensor hardware found on this device", null)
                        return
                    }

                    sensorEventListener = object : SensorEventListener {
                        override fun onSensorChanged(event: SensorEvent?) {
                            if (event == null) return

                            var headingDegrees: Double? = null

                            if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
                                val rotationMatrix = FloatArray(9)
                                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                                val orientation = FloatArray(3)
                                SensorManager.getOrientation(rotationMatrix, orientation)
                                val azimuthRad = orientation[0]
                                val deg = Math.toDegrees(azimuthRad.toDouble())
                                headingDegrees = (deg + 360.0) % 360.0
                            } else {
                                if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
                                    System.arraycopy(event.values, 0, lastAccelerometer, 0, event.values.size)
                                    isAccelerometerSet = true
                                } else if (event.sensor.type == Sensor.TYPE_MAGNETIC_FIELD) {
                                    System.arraycopy(event.values, 0, lastMagnetometer, 0, event.values.size)
                                    isMagnetometerSet = true
                                }

                                if (isAccelerometerSet && isMagnetometerSet) {
                                    val rotationMatrix = FloatArray(9)
                                    val inclinationMatrix = FloatArray(9)
                                    val success = SensorManager.getRotationMatrix(
                                        rotationMatrix,
                                        inclinationMatrix,
                                        lastAccelerometer,
                                        lastMagnetometer
                                    )
                                    if (success) {
                                        val orientation = FloatArray(3)
                                        SensorManager.getOrientation(rotationMatrix, orientation)
                                        val azimuthRad = orientation[0]
                                        val deg = Math.toDegrees(azimuthRad.toDouble())
                                        headingDegrees = (deg + 360.0) % 360.0
                                    }
                                }
                            }

                            if (headingDegrees != null) {
                                val payload = HashMap<String, Any>()
                                payload["heading"] = headingDegrees
                                payload["accuracy"] = currentAccuracy
                                payload["reference"] = "MAGNETIC"
                                payload["timestamp"] = System.currentTimeMillis()
                                events?.success(payload)
                            }
                        }

                        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
                            currentAccuracy = accuracy
                        }
                    }

                    if (rotationSensor != null) {
                        sensorManager?.registerListener(
                            sensorEventListener,
                            rotationSensor,
                            SensorManager.SENSOR_DELAY_UI
                        )
                    } else {
                        sensorManager?.registerListener(
                            sensorEventListener,
                            accelerometer,
                            SensorManager.SENSOR_DELAY_UI
                        )
                        sensorManager?.registerListener(
                            sensorEventListener,
                            magnetometer,
                            SensorManager.SENSOR_DELAY_UI
                        )
                    }
                }

                override fun onCancel(arguments: Any?) {
                    sensorEventListener?.let {
                        sensorManager?.unregisterListener(it)
                    }
                    sensorEventListener = null
                    sensorManager = null
                    isAccelerometerSet = false
                    isMagnetometerSet = false
                }
            })
    }
}
