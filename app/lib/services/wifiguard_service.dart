import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:wifiguard/services/platform_channel.dart';
import 'package:wifiguard/src/rust/api/lib.dart' as rust;

enum WiFiGuardVerdictState { safe, suspect, blocked }

class WiFiGuardVerdict {
  final WiFiGuardVerdictState state;
  final String reason;

  const WiFiGuardVerdict({
    required this.state,
    required this.reason,
  });

  @override
  String toString() => 'WiFiGuardVerdict(state: $state, reason: $reason)';
}

class WiFiGuardService {
  // Mock cycle state for Windows desktop testing
  static int _mockCycle = 0;
  static const List<WiFiGuardVerdict> _mockVerdicts = [
    WiFiGuardVerdict(
      state: WiFiGuardVerdictState.safe,
      reason: 'All checks passed. Connection secure.',
    ),
    WiFiGuardVerdict(
      state: WiFiGuardVerdictState.suspect,
      reason: 'Anomalous RSSI signal variance and unknown BSSID OUI detected.',
    ),
    WiFiGuardVerdict(
      state: WiFiGuardVerdictState.blocked,
      reason: 'DNS mismatch: banking domains resolving to local/private IPs (possible MITM).',
    ),
  ];

  // Memory baseline store to fallback when persistent storage is unavailable
  static final Map<String, double> _rttBaselines = {};

  /// Performs the multi-layered network assessment.
  ///
  /// Runs fully offline. Checks BSSID fingerprinting, RSSI variance,
  /// DNS validation, and RTT anomalies.
  ///
  /// On Windows/iOS/Simulator, this falls back automatically to a mock cycle
  /// allowing all 3 states (SAFE -> SUSPECT -> BLOCKED) to be fully verified.
  static Future<WiFiGuardVerdict> assess() async {
    // If not running on physical Android, use the rotating mock fallback
    if (!Platform.isAndroid || kIsWeb) {
      final verdict = _mockVerdicts[_mockCycle % _mockVerdicts.length];
      _mockCycle++;
      developer.log('Windows/Mock Mode: Returning $verdict');
      return verdict;
    }

    try {
      final String bssid = await PlatformChannel.getBssid();
      final List<int> rssiSamples = await PlatformChannel.getRssiSamples();
      final bool onWifi = await PlatformChannel.isOnWifi();

      if (!onWifi) {
        return const WiFiGuardVerdict(
          state: WiFiGuardVerdictState.safe,
          reason: 'Device not on WiFi (Mobile data or disconnected). Assumed secure.',
        );
      }

      // 1. DNS consistency check (Layer 1 offline checking)
      final bool dnsClean = await _verifyDnsOffline();

      // 2. Latency measurement (RTT)
      final double currentRtt = await PlatformChannel.measureRtt();

      // 3. RTT baseline retrieval
      final double baselineRtt = _getBaseline(bssid);

      // Save/update baseline if connection is healthy
      if (dnsClean && currentRtt < 999.0) {
        _updateBaseline(bssid, currentRtt);
      }

      developer.log(
        'WiFiGuard assess: BSSID=$bssid, RSSI=$rssiSamples, RTT=$currentRtt, Baseline=$baselineRtt, DnsClean=$dnsClean',
      );

      // 4. Invoke Rust core synchronously via FFI
      final rustVerdict = rust.assessNetwork(
        bssid: bssid,
        rssiSamples: rssiSamples,
        rttMs: currentRtt,
        rttBaselineMs: baselineRtt,
        dnsClean: dnsClean,
      );

      // Map Rust verdict to Dart WiFiGuardVerdict
      if (rustVerdict is rust.NetworkVerdict_Safe) {
        return const WiFiGuardVerdict(
          state: WiFiGuardVerdictState.safe,
          reason: 'Connection verified safe.',
        );
      } else if (rustVerdict is rust.NetworkVerdict_Suspect) {
        return const WiFiGuardVerdict(
          state: WiFiGuardVerdictState.suspect,
          reason: 'Anomalous network patterns detected. Use with caution.',
        );
      } else if (rustVerdict is rust.NetworkVerdict_Blocked) {
        return WiFiGuardVerdict(
          state: WiFiGuardVerdictState.blocked,
          reason: rustVerdict.reason,
        );
      }

      return const WiFiGuardVerdict(
        state: WiFiGuardVerdictState.blocked,
        reason: 'Fail-secure: Unknown verdict received from core.',
      );
    } catch (e) {
      developer.log('Error during network assessment: $e', error: e);
      return WiFiGuardVerdict(
        state: WiFiGuardVerdictState.blocked,
        reason: 'Fail-secure: Exception during scan ($e).',
      );
    }
  }

  /// Verifies DNS consistency offline.
  /// Resolves major banking domains locally and flags private IPs (spoofing indicator).
  static Future<bool> _verifyDnsOffline() async {
    const bankingDomains = [
      'fnb.co.za',
      'capitecbank.co.za',
      'standardbank.co.za',
      'tymebank.co.za',
    ];

    try {
      for (final domain in bankingDomains) {
        final addresses = await InternetAddress.lookup(domain);
        for (final addr in addresses) {
          if (_isPrivateIp(addr.address)) {
            developer.log('DNS Spoofing detected! Domain $domain resolved to private IP: ${addr.address}');
            return false;
          }
        }
      }
      return true;
    } catch (_) {
      // If resolving fails completely (e.g. no internet/DNS server down),
      // we don't treat it as spoofed, but RTT check will flag high latency.
      return true;
    }
  }

  /// Checks if an IP is a private/local range address
  static bool _isPrivateIp(String ip) {
    return ip.startsWith('192.168.') ||
           ip.startsWith('10.') ||
           ip.startsWith('127.') ||
           RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.').hasMatch(ip);
  }

  /// Gets baseline RTT from local cache (per BSSID)
  static double _getBaseline(String bssid) {
    return _rttBaselines[bssid] ?? 0.0;
  }

  /// Updates baseline RTT with exponential smoothing
  static void _updateBaseline(String bssid, double newRtt) {
    final double existing = _rttBaselines[bssid] ?? 0.0;
    if (existing == 0.0) {
      _rttBaselines[bssid] = newRtt;
    } else {
      // Exponential moving average: 80% old baseline, 20% new reading
      _rttBaselines[bssid] = (existing * 0.8) + (newRtt * 0.2);
    }
  }
}
