#[derive(Debug, Clone, PartialEq)]
pub enum RssiVerdict {
    Normal,
    Suspicious,
}

/// samples: vec of RSSI readings in dBm (negative integers)
/// Returns Suspicious if signal is abnormally strong AND highly variable
pub fn analyse_rssi(samples: &[i32]) -> RssiVerdict {
    if samples.is_empty() {
        return RssiVerdict::Suspicious;
    }

    let avg: f64 = samples.iter().sum::<i32>() as f64 / samples.len() as f64;

    // Abnormally strong in a public space = rogue AP very close to victim
    // Legitimate fixed infrastructure rarely exceeds -40 dBm at user distance
    let abnormally_strong = avg > -40.0;

    // High variance = portable device (backpack router) shifting position
    let variance: f64 = samples.iter()
        .map(|&s| (s as f64 - avg).powi(2))
        .sum::<f64>() / samples.len() as f64;
    let std_dev = variance.sqrt();
    let high_variance = std_dev > 8.0;

    // Flag only when BOTH conditions — reduces false positives
    if abnormally_strong && high_variance {
        RssiVerdict::Suspicious
    } else {
        RssiVerdict::Normal
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_empty_samples() {
        assert_eq!(analyse_rssi(&[]), RssiVerdict::Suspicious);
    }

    #[test]
    fn test_stable_legitimate_signal() {
        // Fixed AP, stable signal, normal strength
        let samples = vec![-65, -66, -65, -67, -65];
        assert_eq!(analyse_rssi(&samples), RssiVerdict::Normal);
    }

    #[test]
    fn test_portable_evil_twin() {
        // Strong signal, highly variable (backpack router)
        // Average = -34.2 dBm (> -40 dBm), Std Dev = 11.08 (> 8 dBm)
        let samples = vec![-25, -45, -28, -50, -23];
        assert_eq!(analyse_rssi(&samples), RssiVerdict::Suspicious);
    }

    #[test]
    fn test_strong_but_stable_not_flagged() {
        // Could be sitting next to a legitimate AP — don't false-positive
        let samples = vec![-38, -39, -38, -40, -39];
        assert_eq!(analyse_rssi(&samples), RssiVerdict::Normal);
    }
}
