/// Known consumer/cheap chipset OUIs used in Evil Twin hardware
/// (Huawei pocket routers, TP-Link, cheap no-brand hotspots)
const KNOWN_BAD_OUIS: &[&str] = &[
    "AC:23:3F",  // Generic consumer hotspot chipset
    "02:00:00",  // Locally administered — always suspicious
    "DA:A1:19",  // Randomized MAC prefix pattern
];

/// Known enterprise AP OUIs (Cisco, Aruba, Ruckus, Ubiquiti)
const KNOWN_GOOD_OUIS: &[&str] = &[
    "00:0B:86",  // Aruba Networks
    "00:1A:1E",  // Aruba Networks
    "00:17:DF",  // Aruba Networks
    "58:AC:78",  // Ruckus
    "EC:8C:A2",  // Ruckus
    "24:A4:3C",  // Ubiquiti
    "70:A7:41",  // Cisco Meraki
    "00:18:0A",  // Cisco Meraki
];

#[derive(Debug, Clone, PartialEq)]
pub enum BssidVerdict {
    KnownGood,
    Unknown,
    KnownBad,
    LocallyAdministered,  // MAC starts with 02, 06, 0A, 0E — always a red flag
}

pub fn classify_bssid(bssid: &str) -> BssidVerdict {
    // Validate format first
    let parts: Vec<&str> = bssid.split(':').collect();
    if parts.len() != 6 {
        return BssidVerdict::KnownBad; // malformed = suspicious
    }

    // Check if each part is exactly a 2-digit hex number
    for part in &parts {
        if part.len() != 2 || !part.chars().all(|c| c.is_ascii_hexdigit()) {
            return BssidVerdict::KnownBad;
        }
    }

    // Check if locally administered (bit 1 of first byte set)
    if let Ok(first_byte) = u8::from_str_radix(parts[0], 16) {
        if first_byte & 0x02 != 0 {
            return BssidVerdict::LocallyAdministered;
        }
    }

    let oui = format!("{}:{}:{}", 
        parts[0].to_uppercase(), 
        parts[1].to_uppercase(), 
        parts[2].to_uppercase()
    );

    if KNOWN_GOOD_OUIS.contains(&oui.as_str()) {
        return BssidVerdict::KnownGood;
    }

    if KNOWN_BAD_OUIS.contains(&oui.as_str()) {
        return BssidVerdict::KnownBad;
    }

    BssidVerdict::Unknown
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_locally_administered_flagged() {
        assert_eq!(classify_bssid("02:AB:CD:EF:01:23"), BssidVerdict::LocallyAdministered);
        assert_eq!(classify_bssid("0A:12:34:56:78:90"), BssidVerdict::LocallyAdministered);
        assert_eq!(classify_bssid("0e:FF:EE:DD:CC:BB"), BssidVerdict::LocallyAdministered);
    }

    #[test]
    fn test_known_good_aruba() {
        assert_eq!(classify_bssid("00:0B:86:AA:BB:CC"), BssidVerdict::KnownGood);
        assert_eq!(classify_bssid("00:1A:1E:11:22:33"), BssidVerdict::KnownGood);
    }

    #[test]
    fn test_known_bad_oui() {
        assert_eq!(classify_bssid("AC:23:3F:AA:BB:CC"), BssidVerdict::KnownBad);
    }

    #[test]
    fn test_malformed_returns_bad() {
        assert_eq!(classify_bssid("not:a:mac"), BssidVerdict::KnownBad);
        assert_eq!(classify_bssid("00:1A:1E:11:22"), BssidVerdict::KnownBad);
        assert_eq!(classify_bssid("00:1A:1E:11:22:3G"), BssidVerdict::KnownBad);
        assert_eq!(classify_bssid(""), BssidVerdict::KnownBad);
    }
}
