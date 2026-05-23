// Stub file representing flutter_rust_bridge v2 generated bindings.
// This allows compiling the Dart project on Windows before running codegen.
// The actual flutter_rust_bridge generator will overwrite this file.

abstract class NetworkVerdict {
  const NetworkVerdict();
}

class NetworkVerdict_Safe extends NetworkVerdict {
  const NetworkVerdict_Safe();
}

class NetworkVerdict_Suspect extends NetworkVerdict {
  const NetworkVerdict_Suspect();
}

class NetworkVerdict_Blocked extends NetworkVerdict {
  final String reason;
  const NetworkVerdict_Blocked({required this.reason});
}

NetworkVerdict assessNetwork({
  required String bssid,
  required List<int> rssiSamples,
  required double rttMs,
  required double rttBaselineMs,
  required bool dnsClean,
}) {
  // In stub mode, we just return Safe.
  return const NetworkVerdict_Safe();
}
