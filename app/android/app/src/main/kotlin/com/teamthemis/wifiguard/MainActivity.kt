package com.teamthemis.wifiguard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // This MUST match what Nyakallo has in platform_channel.dart — exactly
    private val CHANNEL = "com.teamthemis.wifiguard/wifi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val telemetry = WifiTelemetry(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Flutter calls "getBssid" → Kotlin returns the BSSID string
                    "getBssid" -> {
                        result.success(telemetry.getBssid())
                    }
                    // Flutter calls "getRssiSamples" → Kotlin returns List<Int>
                    "getRssiSamples" -> {
                        Thread {
                            val samples = telemetry.getRssiSamples()
                            runOnUiThread {
                                result.success(samples)
                            }
                        }.start()
                    }
                    // Flutter calls "isOnWifi" → Kotlin returns true or false
                    "isOnWifi" -> {
                        result.success(telemetry.isOnWifi())
                    }
                    // Any unknown method call is handled gracefully
                    else -> result.notImplemented()
                }
            }
    }

    // Ask the user for location permission on app launch
    // Android 10+ requires this permission to return the real BSSID
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        requestLocationPermission()
    }

    private fun requestLocationPermission() {
        if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION)
            != android.content.pm.PackageManager.PERMISSION_GRANTED) {
            requestPermissions(
                arrayOf(android.Manifest.permission.ACCESS_FINE_LOCATION),
                1001
            )
        }
    }
}
