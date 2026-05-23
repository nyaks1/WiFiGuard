mod bssid;
mod rssi;

use bssid::{classify_bssid, BssidVerdict};
use rssi::{analyse_rssi, RssiVerdict};

#[cfg(feature = "bridge")]
use flutter_rust_bridge::frb;

// Dummy macro for attribute parsing when bridge is disabled
#[cfg(not(feature = "bridge"))]
#[allow(unused_macros)]
macro_rules! frb {
    ($($tt:tt)*) => {};
}

#[cfg_attr(feature = "bridge", frb(dart_metadata=("freezed")))]
#[derive(Debug, Clone, PartialEq)]
pub enum NetworkVerdict {
    Safe,
    Suspect,
    Blocked { reason: String },
}

#[cfg_attr(feature = "bridge", frb(sync))]
pub fn assess_network(
    bssid: String,
    rssi_samples: Vec<i32>,
    rtt_ms: f64,
    rtt_baseline_ms: f64, // 0.0 = no baseline yet (first visit)
    dns_clean: bool,
) -> NetworkVerdict {

    // DNS mismatch is a HARD block — no override
    if !dns_clean {
        return NetworkVerdict::Blocked {
            reason: "DNS mismatch: suspected man-in-the-middle".to_string(),
        };
    }

    let mut suspect_count = 0u32;

    // BSSID check
    match classify_bssid(&bssid) {
        BssidVerdict::KnownBad | BssidVerdict::LocallyAdministered => {
            return NetworkVerdict::Blocked {
                reason: "BSSID flagged: known malicious or locally administered MAC".to_string(),
            };
        }
        BssidVerdict::Unknown => suspect_count += 1,
        BssidVerdict::KnownGood => {}
    }

    // RSSI check
    if analyse_rssi(&rssi_samples) == RssiVerdict::Suspicious {
        suspect_count += 1;
    }

    // RTT check — only applies if baseline exists
    if rtt_baseline_ms > 0.0 {
        let threshold = (rtt_baseline_ms * 2.5).max(rtt_baseline_ms + 15.0);
        if rtt_ms > threshold {
            suspect_count += 1;
        }
    }
    // If no baseline (first visit), RTT contributes 0 — we don't penalise first encounters

    // Three or more SUSPECT signals = BLOCK
    if suspect_count >= 3 {
        return NetworkVerdict::Blocked {
            reason: format!("{} suspicious signals detected", suspect_count),
        };
    }

    if suspect_count >= 1 {
        return NetworkVerdict::Suspect;
    }

    NetworkVerdict::Safe
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dns_mismatch_blocks_immediately() {
        let verdict = assess_network(
            "00:0B:86:AA:BB:CC".to_string(), // KnownGood
            vec![-65, -65, -65],              // Normal RSSI
            10.0,                             // Normal RTT
            10.0,                             // Normal baseline
            false,                            // DNS compromised!
        );
        assert!(matches!(verdict, NetworkVerdict::Blocked { .. }));
        if let NetworkVerdict::Blocked { reason } = verdict {
            assert!(reason.contains("DNS mismatch"));
        }
    }

    #[test]
    fn test_locally_administered_bssid_blocks_immediately() {
        let verdict = assess_network(
            "02:00:00:11:22:33".to_string(), // Locally administered
            vec![-65, -65, -65],              // Normal RSSI
            10.0,                             // Normal RTT
            10.0,                             // Normal baseline
            true,                             // DNS clean
        );
        assert!(matches!(verdict, NetworkVerdict::Blocked { .. }));
        if let NetworkVerdict::Blocked { reason } = verdict {
            assert!(reason.contains("BSSID flagged"));
        }
    }

    #[test]
    fn test_known_bad_bssid_blocks_immediately() {
        let verdict = assess_network(
            "AC:23:3F:11:22:33".to_string(), // KnownBad
            vec![-65, -65, -65],              // Normal RSSI
            10.0,                             // Normal RTT
            10.0,                             // Normal baseline
            true,                             // DNS clean
        );
        assert!(matches!(verdict, NetworkVerdict::Blocked { .. }));
        if let NetworkVerdict::Blocked { reason } = verdict {
            assert!(reason.contains("BSSID flagged"));
        }
    }

    #[test]
    fn test_all_clean_is_safe() {
        let verdict = assess_network(
            "00:0B:86:AA:BB:CC".to_string(), // KnownGood
            vec![-65, -65, -65],              // Normal RSSI
            10.0,                             // Normal RTT
            10.0,                             // Normal baseline
            true,                             // DNS clean
        );
        assert_eq!(verdict, NetworkVerdict::Safe);
    }

    #[test]
    fn test_first_visit_no_baseline_ignores_rtt() {
        // Unknown BSSID (+1 suspect)
        // Normal RSSI (+0 suspect)
        // High RTT, but 0.0 baseline so ignored (+0 suspect)
        // Total suspect = 1 -> Suspect
        let verdict = assess_network(
            "11:22:33:44:55:66".to_string(), // Unknown
            vec![-65, -65, -65],              // Normal RSSI
            500.0,                            // High RTT
            0.0,                              // First visit (no baseline)
            true,                             // DNS clean
        );
        assert_eq!(verdict, NetworkVerdict::Suspect);
    }

    #[test]
    fn test_three_suspect_signals_blocks() {
        // Unknown BSSID (+1 suspect)
        // Suspicious RSSI (+1 suspect)
        // High RTT with baseline (+1 suspect)
        // Total suspect = 3 -> Blocked
        let verdict = assess_network(
            "11:22:33:44:55:66".to_string(), // Unknown
            vec![-25, -45, -28, -50, -23],    // Suspicious RSSI (strong & high variance)
            45.0,                             // High RTT (threshold = max(10*2.5, 10+15) = 25)
            10.0,                             // Baseline exists
            true,                             // DNS clean
        );
        assert!(matches!(verdict, NetworkVerdict::Blocked { .. }));
        if let NetworkVerdict::Blocked { reason } = verdict {
            assert!(reason.contains("3 suspicious signals"));
        }
    }

    #[test]
    fn test_one_or_two_suspect_signals_is_suspect() {
        // Unknown BSSID (+1 suspect)
        // Normal RSSI (+0 suspect)
        // Normal RTT (+0 suspect)
        // Total suspect = 1 -> Suspect
        let verdict = assess_network(
            "11:22:33:44:55:66".to_string(), // Unknown
            vec![-65, -65, -65],              // Normal RSSI
            10.0,                             // Normal RTT
            10.0,                             // Baseline exists
            true,                             // DNS clean
        );
        assert_eq!(verdict, NetworkVerdict::Suspect);

        // Unknown BSSID (+1 suspect)
        // Suspicious RSSI (+1 suspect)
        // Normal RTT (+0 suspect)
        // Total suspect = 2 -> Suspect
        let verdict2 = assess_network(
            "11:22:33:44:55:66".to_string(), // Unknown
            vec![-25, -45, -28, -50, -23],    // Suspicious RSSI
            10.0,                             // Normal RTT
            10.0,                             // Baseline exists
            true,                             // DNS clean
        );
        assert_eq!(verdict2, NetworkVerdict::Suspect);
    }
}
