package com.teamthemis.wifiguard

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager

class WifiTelemetry(private val context: Context) {
    private val wifiManager: WifiManager by lazy {
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }

    // Reads the BSSID — the hardware MAC address of the connected router
    // Example return value: "AA:BB:CC:DD:EE:FF"
    // Returns "00:00:00:00:00:00" if no WiFi is connected
    fun getBssid(): String {
        val info = wifiManager.connectionInfo
        return info?.bssid ?: "00:00:00:00:00:00"
    }

    // Takes 5 RSSI signal strength readings, 100ms apart
    // Returns a list like: [-65, -67, -66, -65, -68]
    // Nyakallo's engine needs multiple readings to detect signal variance
    fun getRssiSamples(sampleCount: Int = 5): List<Int> {
        val samples = mutableListOf<Int>()
        repeat(sampleCount) {
            samples.add(wifiManager.connectionInfo?.rssi ?: -100)
            Thread.sleep(100)
        }
        return samples
    }

    // Confirms the phone is on WiFi (not mobile data)
    // Returns true = on WiFi, false = not on WiFi
    fun isOnWifi(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE)
                as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(network) ?: return false
        return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }
}
