import 'dart:io';
import 'package:flutter/services.dart';

class PlatformChannel {
  static const MethodChannel _channel = MethodChannel('com.teamthemis.wifiguard/wifi');

  /// Fetches the connected BSSID from the native Android layer.
  /// Returns '00:00:00:00:00:00' if not available or on unsupported platforms.
  static Future<String> getBssid() async {
    if (!Platform.isAndroid) {
      return '00:00:00:00:00:00';
    }
    try {
      final String? bssid = await _channel.invokeMethod<String>('getBssid');
      return bssid ?? '00:00:00:00:00:00';
    } on PlatformException catch (_) {
      return '00:00:00:00:00:00';
    }
  }

  /// Fetches 5 RSSI samples from the native Android layer.
  /// Returns empty list if not on Android or call fails.
  static Future<List<int>> getRssiSamples() async {
    if (!Platform.isAndroid) {
      return [];
    }
    try {
      final List<dynamic>? samples = await _channel.invokeMethod<List<dynamic>>('getRssiSamples');
      if (samples == null) return [];
      return samples.cast<int>();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Checks if the device is currently connected to WiFi.
  /// Returns false if not on Android.
  static Future<bool> isOnWifi() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final bool? isWifi = await _channel.invokeMethod<bool>('isOnWifi');
      return isWifi ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Measures round-trip time (RTT) latency by attempting to open a TCP socket
  /// to Cloudflare's public DNS (1.1.1.1:53).
  ///
  /// Returns latency in milliseconds. If connection fails or times out,
  /// returns a high RTT (999.0) to signal network degradation/MITM.
  static Future<double> measureRtt() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Connect to a public DNS server over port 53 (TCP)
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 1500),
      );
      await socket.close();
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / 1000.0;
    } catch (_) {
      stopwatch.stop();
      // Fail-secure: if socket fails (e.g., rogue AP is captive/not routing),
      // return a very high RTT.
      return 999.0;
    }
  }
}
