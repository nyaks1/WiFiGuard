# WiFiGuard SDK — Hackathon Build Plan
### Team Themis | ITWeb Security Summit 2026

---

## GROUND RULES (Read Before Anything Else)

1. **Function contract is agreed by Hour 2, Day 1. No exceptions.** Nelly cannot start on the Kotlin bridge until Nyakallo has defined the Rust function signatures.
2. **iOS is cut from the hackathon scope.** Any iOS mention in the pitch is framed as "Phase 3." Do not waste a single minute on it.
3. **The demo toggle is the most important deliverable.** A working live toggle beats a polished UI every time.
4. **Fail secure.** If anything breaks during the demo, the app shows BLOCKED — not a crash, not a white screen. Build this assumption in from Day 1.
5. **Siwa runs a full dry-run demo at Hour 20.** Not Hour 22. Not Hour 23. Hour 20. If it breaks at Hour 20, there is time to fix it.

---

## TEAM OVERVIEW

| Name | Lane | Key Deliverable |
|------|------|----------------|
| **Nyakallo** | Rust core + Flutter app + integration | `assess_network()` engine, `.so` compilation, three Flutter screens, `wifiguard_service.dart` wired to real Rust output |
| **Nelly** | Android native bridge | `WifiTelemetry.kt` reads real BSSID/RSSI, `MainActivity.kt` registers `MethodChannel`, `AndroidManifest.xml` permissions |
| **Ziphezinhle** | Rogue AP lab | Live toggleable Evil Twin: `hostapd` + `dnsmasq`, `toggle.py` script, confirmed DNS poison on demo device |
| **Siwa** | Pitch + dashboard | 5-minute demo script, slide deck, FastAPI dashboard showing live block events from `events.json` |

---

## PRE-HACKATHON CHECKLIST
### Complete this BEFORE the event. Every item. No skipping.

### All 4 People

- [ ] Join a shared group chat (WhatsApp or Discord — agree before the event)
- [ ] Read the full whitepaper once. Every person. You need to be able to answer judge questions about any section.
- [ ] Agree on demo day network SSID name (e.g., `"Themis_Safe"` for real, `"Themis_Safe"` cloned for rogue). Lock this in. Ziphezinhle needs to hardcode it in `hostapd.conf`.
- [ ] Agree on demo device — which Android phone runs the app? Whose is it? It must be Android 10+. Confirm this before the event.
- [ ] Everyone installs Git. Everyone is on the same repo. Agree on branching: `main` is always demo-ready. Feature branches only.

---

### Nyakallo — Pre-Hackathon

- [ ] Install Rust toolchain
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  rustup target add aarch64-linux-android
  rustup target add x86_64-linux-android
  ```
- [ ] Install Android NDK (r25c or later). Note the NDK path — you will need it.
  ```bash
  # Via Android Studio SDK Manager → SDK Tools → NDK (Side by side)
  # Or: sdkmanager "ndk;25.2.9519653"
  ```
- [ ] Install `cargo-ndk`
  ```bash
  cargo install cargo-ndk
  ```
- [ ] Create the Rust project skeleton locally and confirm it compiles:
  ```bash
  cargo new wifiguard_core --lib
  cd wifiguard_core
  # Edit Cargo.toml — add crate-type = ["cdylib", "staticlib"]
  cargo build
  ```
- [ ] Write and share the **function contract** with Nelly before the event. This is the single most important pre-hackathon task.

  ```rust
  // This exact signature. No changes without telling Nelly.
  pub fn assess_network(
      bssid: String,
      rssi: i32,
      rtt_ms: f64,
      dns_clean: bool,
  ) -> NetworkVerdict
  ```

- [ ] Install `flutter_rust_bridge` CLI:
  ```bash
  cargo install flutter_rust_bridge_codegen
  ```
- [ ] Read the OUI database format. Download a copy of the IEEE OUI list:
  ```bash
  wget https://standards-oui.ieee.org/oui/oui.txt -O oui_full.txt
  # Pre-process it into a Rust-embeddable format (see Day 1 tasks)
  ```

---

### Nelly — Pre-Hackathon

- [ ] Install Android Studio + Android SDK
- [ ] Open the Flutter project's `android/` folder in Android Studio — confirm it loads without errors
- [ ] Confirm Kotlin plugin is active (bundled with Android Studio by default)
- [ ] Read `WifiTelemetry.kt` and `MainActivity.kt` from the build plan. Understand what each method does before the hackathon.
- [ ] Read the function contract from Nyakallo. Your Kotlin bridge passes data *into* that function. Know the four inputs: `bssid`, `rssiSamples`, `rttMs`, `dnsClean`.
- [ ] If you've never written Kotlin, spend 1 hour on the basics — it reads like Java with cleaner syntax. Focus only on: classes, functions, when expressions, and Android `MethodChannel`.

---

### Ziphezinhle — Pre-Hackathon

- [ ] Confirm Linux laptop is available (Kali preferred, Ubuntu works)
- [ ] Confirm WiFi adapter supports AP mode:
  ```bash
  iw list | grep -A 10 "Supported interface modes" | grep AP
  # Must see "AP" in output
  ```
- [ ] If built-in card doesn't support AP mode, buy TP-Link TL-WN722N (~R200) before the event
- [ ] Install required tools:
  ```bash
  sudo apt update
  sudo apt install hostapd dnsmasq iptables python3 python3-pip -y
  pip3 install fastapi uvicorn
  ```
- [ ] Write and test `hostapd.conf` at home before the event:
  ```bash
  # /etc/hostapd/evil_twin.conf
  interface=wlan0
  ssid=Themis_Safe          # AGREED SSID — same as real network
  channel=6
  hw_mode=g
  ```
  ```bash
  sudo hostapd /etc/hostapd/evil_twin.conf
  # Verify it broadcasts. Check with another device.
  sudo pkill hostapd
  ```
- [ ] Write and test `dnsmasq.conf` at home:
  ```bash
  # /etc/dnsmasq.conf
  interface=wlan0
  dhcp-range=192.168.1.2,192.168.1.20,12h
  address=/fnb.co.za/192.168.1.1
  address=/capitecbank.co.za/192.168.1.1
  address=/tymebank.co.za/192.168.1.1
  address=/standardbank.co.za/192.168.1.1
  ```
- [ ] Write the Python toggle script and test it (see Day 1 tasks for full version)
- [ ] Bring a phone or laptop to verify DNS poisoning works (curl fnb.co.za on the rogue network, confirm it resolves to 192.168.1.1)

---

### Siwa — Pre-Hackathon

- [ ] Read every slide in both PowerPoint decks
- [ ] Read the full whitepaper — you will be answering questions judges direct to you
- [ ] Write a first draft of the 5-minute pitch script (structure: Problem → Stats → Solution → Demo → Business → Ask)
- [ ] Prepare the slide deck for the hackathon presentation (it may differ from the pre-submitted deck)
- [ ] Bring HDMI adapter for the demo laptop. Bring a backup USB-C to HDMI. Bring both.
- [ ] Create a shared task board (Notion, Trello, even a Google Sheet). Everyone updates it in real time.

---

## DAY 1 BUILD PLAN

### Hour 0–1: Setup Sprint (All 4 People Together)

**Everyone in the same physical location or call.**

- [ ] Siwa pulls up the task board. Every task is visible to everyone.
- [ ] Nyakallo shares the Rust function contract on the group chat. Everyone acknowledges it.
- [ ] Nelly confirms the contract. Asks any remaining questions NOW.
- [ ] Ziphezinhle confirms the demo SSID. Confirms adapter is working.
- [ ] Everyone clones the repo:
  ```bash
  git clone https://github.com/[org]/wifiguard
  cd wifiguard
  ```
- [ ] Repo structure agreed:
  ```
  wifiguard/
  ├── core/          ← Nyakallo (Rust)
  ├── app/           ← Nyakallo (Flutter + integration)
  ├── lab/           ← Ziphezinhle (rogue AP scripts)
  ├── dashboard/     ← Siwa (FastAPI dashboard)
  └── docs/          ← Siwa (pitch, demo script)
  ```

---

### Nyakallo — Hour-by-Hour (Day 1)

#### Hour 1–2: Project Scaffold

```bash
cd wifiguard/core
cargo init --lib
```

Edit `Cargo.toml`:
```toml
[package]
name = "wifiguard_core"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "staticlib"]

[dependencies]
flutter_rust_bridge = "2"

[profile.release]
opt-level = "z"      # Optimize for size
lto = true
strip = true
```

Create `src/lib.rs` with the agreed contract — **mock implementation first**:

```rust
use flutter_rust_bridge::frb;

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq)]
pub enum NetworkVerdict {
    Safe,
    Suspect,
    Blocked { reason: String },
}

#[frb(sync)]
pub fn assess_network(
    bssid: String,
    rssi: i32,
    rtt_ms: f64,
    dns_clean: bool,
) -> NetworkVerdict {
    // MOCK — replace with real logic
    NetworkVerdict::Safe
}
```

Confirm it compiles:
```bash
cargo build
```

**Checkpoint Hour 2:** Push `core/` to repo. Tell Nelly it's ready.

---

#### Hour 2–5: BSSID Fingerprinter

Goal: Given a BSSID string like `"AA:BB:CC:DD:EE:FF"`, extract the OUI (first 3 bytes) and classify it.

```rust
// src/bssid.rs

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
    }

    #[test]
    fn test_known_good_aruba() {
        assert_eq!(classify_bssid("00:0B:86:AA:BB:CC"), BssidVerdict::KnownGood);
    }

    #[test]
    fn test_malformed_returns_bad() {
        assert_eq!(classify_bssid("not:a:mac"), BssidVerdict::KnownBad);
    }
}
```

Run tests after writing:
```bash
cargo test
```

**Checkpoint Hour 5:** BSSID module passes all tests. Push.

---

#### Hour 5–8: RSSI Analyser

The flaw to fix: don't use absolute threshold alone. Use threshold AND variance.

```rust
// src/rssi.rs

#[derive(Debug, Clone, PartialEq)]
pub enum RssiVerdict {
    Normal,
    Suspicious,
}

/// samples: vec of RSSI readings in dBm (negative integers)
/// Returns Suspicious if signal is abnormally strong OR highly variable
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
    fn test_stable_legitimate_signal() {
        // Fixed AP, stable signal, normal strength
        let samples = vec![-65, -66, -65, -67, -65];
        assert_eq!(analyse_rssi(&samples), RssiVerdict::Normal);
    }

    #[test]
    fn test_portable_evil_twin() {
        // Strong signal, highly variable (backpack router)
        let samples = vec![-35, -55, -38, -60, -33];
        assert_eq!(analyse_rssi(&samples), RssiVerdict::Suspicious);
    }

    #[test]
    fn test_strong_but_stable_not_flagged() {
        // Could be sitting next to a legitimate AP — don't false-positive
        let samples = vec![-38, -39, -38, -40, -39];
        assert_eq!(analyse_rssi(&samples), RssiVerdict::Normal);
    }
}
```

**Checkpoint Hour 8:** RSSI module passes all tests. Push.

---

#### Hour 8–12: Decision Engine

Wire all modules together. This is the core `assess_network` function — replace the mock.

```rust
// src/lib.rs (final version)

mod bssid;
mod rssi;

use bssid::{classify_bssid, BssidVerdict};
use rssi::{analyse_rssi, RssiVerdict};
use flutter_rust_bridge::frb;

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq)]
pub enum NetworkVerdict {
    Safe,
    Suspect,
    Blocked { reason: String },
}

#[frb(sync)]
pub fn assess_network(
    bssid: String,
    rssi_samples: Vec<i32>,  // Changed: take samples, not single value
    rtt_ms: f64,
    rtt_baseline_ms: f64,    // 0.0 = no baseline yet (first visit)
    dns_clean: bool,
) -> NetworkVerdict {

    // DNS mismatch is a HARD block — no override
    if !dns_clean {
        return NetworkVerdict::Blocked {
            reason: "DNS mismatch: suspected man-in-the-middle".to_string()
        };
    }

    let mut suspect_count = 0u32;

    // BSSID check
    match classify_bssid(&bssid) {
        BssidVerdict::KnownBad | BssidVerdict::LocallyAdministered => {
            return NetworkVerdict::Blocked {
                reason: "BSSID flagged: known malicious or locally administered MAC".to_string()
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
            reason: format!("{} suspicious signals detected", suspect_count)
        };
    }

    if suspect_count >= 1 {
        return NetworkVerdict::Suspect;
    }

    NetworkVerdict::Safe
}
```

Run full test suite:
```bash
cargo test
```

**Checkpoint Hour 12:** Full `assess_network` logic working. Push. Tell Nelly to switch from mock.

---

#### Hour 12–16: Compile to Android `.so`

```bash
cd wifiguard/core

# Generate flutter_rust_bridge bindings
flutter_rust_bridge_codegen generate

# Compile for physical Android device (ARM64)
cargo ndk -t arm64-v8a -o ../app/android/app/src/main/jniLibs build --release

# Compile for emulator (x86_64) — Nelly needs this
cargo ndk -t x86_64 -o ../app/android/app/src/main/jniLibs build --release
```

Confirm `.so` files exist:
```bash
ls ../app/android/app/src/main/jniLibs/
# Should see: arm64-v8a/libwifiguard_core.so  x86_64/libwifiguard_core.so
```

Tell Nelly: "`.so` files are in `jniLibs/`. Codegen output is in `app/lib/src/rust/`."

**Checkpoint Hour 16:** Nelly can import and call `assessNetwork()` from Dart.

---

#### Hour 16–20: Android WiFi Telemetry (Kotlin Bridge Helper)

Nyakallo writes the Kotlin helper that reads actual device WiFi state and passes it to the Rust engine. This goes in Nelly's Flutter project.

```kotlin
// android/app/src/main/kotlin/.../WifiTelemetry.kt

package com.teamthemis.wifiguard

import android.content.Context
import android.net.wifi.WifiManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities

class WifiTelemetry(private val context: Context) {

    private val wifiManager: WifiManager by lazy {
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }

    fun getBssid(): String {
        // Android 10+ requires ACCESS_FINE_LOCATION for real BSSID
        val info = wifiManager.connectionInfo
        return info?.bssid ?: "00:00:00:00:00:00"
    }

    fun getRssiSamples(sampleCount: Int = 5): List<Int> {
        // Take multiple readings over ~500ms for variance calculation
        val samples = mutableListOf<Int>()
        repeat(sampleCount) {
            samples.add(wifiManager.connectionInfo?.rssi ?: -100)
            Thread.sleep(100)
        }
        return samples
    }

    fun isOnWifi(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(network) ?: return false
        return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }
}
```

**Checkpoint Hour 20:** Siwa runs first full demo dry-run.

---

### Nelly — Hour-by-Hour (Day 1)

Nelly's lane is **entirely inside `app/android/`**. No Flutter widgets. No Dart. Pure Kotlin + Android manifest. Her job is to be the pipeline that feeds real device WiFi data into Nyakallo's Rust engine.

#### Hour 1–3: Open the Android Project + Understand the Structure

```bash
# The Flutter project is created by Nyakallo — Nelly opens only the Android subfolder
# In Android Studio: File → Open → select wifiguard/app/android/
```

Understand the file structure before writing a line:
```
app/android/
└── app/src/main/
    ├── kotlin/com/teamthemis/wifiguard/
    │   ├── MainActivity.kt     ← Nelly owns this
    │   └── WifiTelemetry.kt    ← Nelly creates this
    └── AndroidManifest.xml     ← Nelly edits this
```

**Checkpoint Hour 3:** Android project loads in Android Studio without errors.

---

#### Hour 3–8: WifiTelemetry.kt

Create `WifiTelemetry.kt` in `kotlin/com/teamthemis/wifiguard/`:

```kotlin
package com.teamthemis.wifiguard

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager

class WifiTelemetry(private val context: Context) {

    private val wifiManager: WifiManager by lazy {
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    }

    // Returns the BSSID (hardware MAC address) of the connected AP
    // Android 10+ requires ACCESS_FINE_LOCATION for the real value
    fun getBssid(): String {
        val info = wifiManager.connectionInfo
        return info?.bssid ?: "00:00:00:00:00:00"
    }

    // Takes 5 RSSI readings 100ms apart — Rust needs samples for variance analysis
    fun getRssiSamples(sampleCount: Int = 5): List<Int> {
        val samples = mutableListOf<Int>()
        repeat(sampleCount) {
            samples.add(wifiManager.connectionInfo?.rssi ?: -100)
            Thread.sleep(100)
        }
        return samples
    }

    // Confirms device is on WiFi (not mobile data)
    fun isOnWifi(): Boolean {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(network) ?: return false
        return caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
    }
}
```

**Checkpoint Hour 8:** `WifiTelemetry.kt` compiles in Android Studio without errors.

---

#### Hour 8–14: MainActivity.kt — MethodChannel Registration

The `MethodChannel` is the bridge between Dart (Nyakallo's Flutter code) and Kotlin (Nelly's telemetry). Dart calls a method by name, Kotlin handles it and returns the value.

Open `MainActivity.kt` and replace with:

```kotlin
package com.teamthemis.wifiguard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // This string must match exactly what Nyakallo uses in platform_channel.dart
    private val CHANNEL = "com.teamthemis.wifiguard/wifi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val telemetry = WifiTelemetry(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBssid" -> {
                        result.success(telemetry.getBssid())
                    }
                    "getRssiSamples" -> {
                        // Returns List<Int> — Dart receives it as List<dynamic>
                        result.success(telemetry.getRssiSamples())
                    }
                    "isOnWifi" -> {
                        result.success(telemetry.isOnWifi())
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

**Checkpoint Hour 14:** `MainActivity.kt` compiles. Channel name matches Nyakallo's `platform_channel.dart` exactly — confirm this in person.

---

#### Hour 14–16: AndroidManifest.xml — Permissions

Without these two permissions, `WifiManager` returns null or randomised values on Android 10+. Open `AndroidManifest.xml` and add inside the `<manifest>` tag, before `<application>`:

```xml
<!-- Required for WifiManager.getConnectionInfo() to return real BSSID on Android 10+ -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
```

Then add runtime permission request inside `MainActivity.kt` — Android 10+ won't give location permission at install time, you must ask at runtime:

```kotlin
// Add to MainActivity.kt, inside configureFlutterEngine or onCreate

private val LOCATION_PERMISSION_CODE = 1001

private fun requestLocationPermission() {
    if (checkSelfPermission(android.Manifest.permission.ACCESS_FINE_LOCATION)
        != android.content.pm.PackageManager.PERMISSION_GRANTED) {
        requestPermissions(
            arrayOf(android.Manifest.permission.ACCESS_FINE_LOCATION),
            LOCATION_PERMISSION_CODE
        )
    }
}

// Call it in onCreate:
override fun onCreate(savedInstanceState: android.os.Bundle?) {
    super.onCreate(savedInstanceState)
    requestLocationPermission()
}
```

**Checkpoint Hour 16:** App installed on demo phone requests location permission on first launch. `getBssid()` returns a real MAC address (not `02:00:00:00:00:00`).

---

#### Hour 16–20: Integration with Nyakallo

Sit with Nyakallo. Confirm:

- [ ] Channel name in `MainActivity.kt` matches `platform_channel.dart` character for character
- [ ] `getRssiSamples()` returns a list of 5 integers — confirm Dart receives them as `List<int>` not `List<dynamic>`
- [ ] `getBssid()` returns a real BSSID when the demo phone is on WiFi
- [ ] App does NOT crash when `isOnWifi()` returns false (i.e., no WiFi connected)
- [ ] Test on the physical demo phone — not just the emulator

**Checkpoint Hour 20:** Nyakallo's Flutter app displays a real BSSID in debug output when connected to WiFi.

---

### Ziphezinhle — Hour-by-Hour (Day 1)

#### Hour 1–2: Environment Check

```bash
# Confirm adapter
ip link show
iw list | grep -A 10 "Supported interface modes"

# Confirm tools installed
hostapd -v
dnsmasq --version
python3 --version
```

If adapter doesn't show AP mode: plug in USB adapter, run `iw list` again.

---

#### Hour 2–5: Rogue AP Lab

```bash
# Step 1: Stop conflicting services
sudo systemctl stop NetworkManager
sudo systemctl stop wpa_supplicant

# Step 2: Assign IP to the interface
sudo ip addr add 192.168.1.1/24 dev wlan0
sudo ip link set wlan0 up

# Step 3: Write hostapd config
sudo tee /etc/hostapd/evil_twin.conf > /dev/null << 'EOF'
interface=wlan0
ssid=Themis_Safe
channel=6
hw_mode=g
EOF

# Step 4: Write dnsmasq config
sudo tee /etc/dnsmasq_evil.conf > /dev/null << 'EOF'
interface=wlan0
bind-interfaces
dhcp-range=192.168.1.2,192.168.1.20,12h
address=/fnb.co.za/192.168.1.1
address=/capitecbank.co.za/192.168.1.1
address=/tymebank.co.za/192.168.1.1
address=/standardbank.co.za/192.168.1.1
EOF

# Step 5: Test it manually
sudo hostapd /etc/hostapd/evil_twin.conf &
sudo dnsmasq -C /etc/dnsmasq_evil.conf --no-daemon &

# From another device on the rogue AP:
# nslookup fnb.co.za
# Should resolve to 192.168.1.1 — that's DNS poisoning working

# Cleanup
sudo pkill hostapd
sudo pkill dnsmasq
```

**Checkpoint Hour 5:** Rogue AP broadcasts. DNS resolves to 192.168.1.1 on connected device.

---

#### Hour 5–8: Toggle Script

```python
# lab/toggle.py

import subprocess
import sys
import time
import json
from datetime import datetime

LOG_FILE = "lab/events.json"
events = []

def log_event(action):
    event = {"time": datetime.now().isoformat(), "action": action}
    events.append(event)
    with open(LOG_FILE, "w") as f:
        json.dump(events, f, indent=2)
    print(f"[{event['time']}] {action}")

def start_evil_twin():
    subprocess.run(["sudo", "ip", "addr", "add", "192.168.1.1/24", "dev", "wlan0"], 
                   capture_output=True)
    subprocess.run(["sudo", "ip", "link", "set", "wlan0", "up"], capture_output=True)
    subprocess.Popen(["sudo", "hostapd", "/etc/hostapd/evil_twin.conf"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(1)
    subprocess.Popen(["sudo", "dnsmasq", "-C", "/etc/dnsmasq_evil.conf", "--no-daemon"],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log_event("ROGUE_AP_STARTED — DNS poison active")
    print("\n🔴  EVIL TWIN IS LIVE — WiFiGuard should detect and block\n")

def stop_evil_twin():
    subprocess.run(["sudo", "pkill", "hostapd"], capture_output=True)
    subprocess.run(["sudo", "pkill", "dnsmasq"], capture_output=True)
    log_event("ROGUE_AP_STOPPED — clean network restored")
    print("\n🟢  EVIL TWIN DOWN — WiFiGuard should show SAFE\n")

def status():
    result = subprocess.run(["pgrep", "hostapd"], capture_output=True)
    if result.returncode == 0:
        print("Status: 🔴 ROGUE AP RUNNING")
    else:
        print("Status: 🟢 CLEAN NETWORK")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 toggle.py [on|off|status]")
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd == "on":
        start_evil_twin()
    elif cmd == "off":
        stop_evil_twin()
    elif cmd == "status":
        status()
    else:
        print(f"Unknown command: {cmd}")
```

Test it:
```bash
python3 lab/toggle.py on
python3 lab/toggle.py status
python3 lab/toggle.py off
```

**Checkpoint Hour 8:** Toggle works reliably. No manual commands needed during demo.

---

#### Hour 8–16: FastAPI Dashboard (If Time Allows — Do This After Lab Is Solid)

```python
# dashboard/main.py

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
import json
import os

app = FastAPI()

@app.get("/", response_class=HTMLResponse)
async def dashboard():
    return """
    <html>
    <head>
        <title>WiFiGuard — Threat Dashboard</title>
        <meta http-equiv="refresh" content="3">
        <style>
            body { background: #1a1a2e; color: white; font-family: monospace; padding: 40px; }
            .safe { color: #00ff88; }
            .blocked { color: #ff4444; }
            .suspect { color: #ffaa00; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            td, th { padding: 12px; border: 1px solid #333; text-align: left; }
        </style>
    </head>
    <body>
        <h1>🛡️ WiFiGuard — Live Threat Monitor</h1>
        <p>Team Themis | ITWeb Security Summit 2026</p>
        <div id="events"></div>
        <script>
            fetch('/events').then(r => r.json()).then(data => {
                const div = document.getElementById('events');
                div.innerHTML = '<table><tr><th>Time</th><th>Event</th></tr>' +
                    data.map(e => `<tr><td>${e.time}</td><td>${e.action}</td></tr>`).join('') +
                    '</table>';
            });
        </script>
    </body>
    </html>
    """

@app.get("/events")
async def get_events():
    try:
        with open("../lab/events.json") as f:
            return json.load(f)
    except:
        return []
```

Run it:
```bash
cd dashboard
uvicorn main:app --host 0.0.0.0 --port 8000
```

Open `http://localhost:8000` — judges can see live events as the toggle fires.

---

### Siwa — Hour-by-Hour (Day 1)

#### Hour 1–4: Demo Script (Written, Not Just Memorised)

Write this word for word. Print it. Have it on screen. Every second of the demo is planned.

```
DEMO SCRIPT — WiFiGuard (5 Minutes)

[0:00–0:30] — Setup
"We're going to show you WiFiGuard detecting a real Evil Twin attack in real time.
 On this laptop, we've set up a rogue access point — same network name, different
 hardware, DNS poisoned to redirect to an attacker machine."

[0:30–1:00] — Clean network demo
"We start with the phone on the legitimate network."
[Ziphezinhle: python3 toggle.py off]
[Nelly: runs the app]
"You can see WiFiGuard scans — BSSID matches known infrastructure, RSSI is stable,
 DNS is clean. Result: SAFE. Banking app would proceed normally."

[1:00–2:00] — Evil Twin activated
"Now we activate the Evil Twin."
[Ziphezinhle: python3 toggle.py on]
"The phone switches to the rogue AP — same SSID, you'd never know visually."
[Nelly: reruns the app]
"WiFiGuard picks up the BSSID mismatch, the DNS mismatch — hard block.
 Result: BLOCKED. Transaction flow disabled. No data traverses the rogue AP."

[2:00–3:00] — Toggle back
"We take the Evil Twin down."
[Ziphezinhle: python3 toggle.py off]
[Nelly: reruns]
"SAFE again. This happens in under 150ms — before TLS even starts."

[3:00–5:00] — Business case
"35 million South African banking users. R1.888 billion in 2024 fraud losses.
 WiFiGuard is the missing layer. 2MB. Fully offline. Sub-150ms. POPIA-compliant.
 R0.15 per MAU — at TymeBank's 10M users, that's R18M/year.
 We're not building the bank. We're selling the shovel."
```

#### Hour 4–8: Slide Deck Finalisation

Update the deck to match what the working demo actually shows. Do not let the deck promise features that aren't built.

Mandatory slides:
1. Problem (1 slide — SABRIC stat, 86% YoY)
2. The Attack (1 slide — Evil Twin diagram, simple)
3. How WiFiGuard Works (1 slide — four checks, simplified)
4. Architecture (1 slide — on-device, no cloud path)
5. Demo placeholder slide (say "Live Demo" — don't put screenshots, do the real thing)
6. Business Model (1 slide — three tiers, R18M example)
7. Compliance (1 slide — POPIA + Joint Standard 2)
8. Roadmap (1 slide — Phase 1/2/3)
9. Team (1 slide)

#### Hour 8–20: Task Board + Blocker Management

Siwa's job from Hour 8 onwards is to watch the task board and unblock people.

- Is Nyakallo stuck on a compiler error? Google it while they keep coding.
- Is Nelly waiting for the `.so`? Pull it from the repo as soon as Nyakallo pushes.
- Is Ziphezinhle's toggle script not killing processes cleanly? Debug it.
- Update the task board every hour with what's done and what's blocked.

**Hour 20: First Full Demo Dry-Run**

Everyone stops. Full demo run. Siwa times it. If anything breaks, diagnose immediately.

---

## DAY 2 BUILD PLAN

### Hour 0–4: Integration + Bug Fixes

Priority order:
1. Fix anything that broke in the dry-run
2. Make the toggle → app update cycle as fast as possible
3. Polish the UI (colours, spacing — 30 minutes max, not more)
4. Confirm the `.so` files work on the physical demo phone (not just the emulator)

### Hour 4–8: Hardening

- [ ] Nyakallo: Confirm `cargo test` passes fully. Fix any failing tests.
- [ ] Nelly: Test on the physical demo phone. Fix any runtime crashes.
- [ ] Ziphezinhle: Run toggle 20 times. Confirm no hanging processes.
- [ ] Siwa: Run full demo 3 times. Time each run. Should be under 5 minutes.

### Hour 8–12: Final Prep

- [ ] Tag the demo-ready commit: `git tag demo-ready`
- [ ] Siwa: Print the demo script
- [ ] Siwa: Confirm the presentation laptop connects to the projector
- [ ] Ziphezinhle: Confirm `toggle.py` runs without `sudo` password prompt (configure sudoers if needed)
- [ ] Everyone: Get 2 hours of sleep if possible

---

## INTEGRATION CHECKPOINTS

| Checkpoint | Time | Owner | Success Criteria |
|------------|------|-------|-----------------|
| Function contract agreed | Hour 2, Day 1 | Nyakallo + Nelly | Written in group chat, both acknowledged |
| Rust mock compiles | Hour 2, Day 1 | Nyakallo | `cargo build` succeeds |
| Flutter app launches | Hour 3, Day 1 | Nyakallo | Three screens render on emulator |
| Rogue AP broadcasts | Hour 5, Day 1 | Ziphezinhle | Second device sees SSID |
| DNS poison works | Hour 5, Day 1 | Ziphezinhle | `nslookup fnb.co.za` → 192.168.1.1 |
| Toggle script works | Hour 8, Day 1 | Ziphezinhle | `on`/`off` cycle 5 times cleanly |
| WifiTelemetry.kt compiles | Hour 8, Day 1 | Nelly | No errors in Android Studio |
| BSSID + RSSI logic passes tests | Hour 8, Day 1 | Nyakallo | `cargo test` 0 failures |
| MethodChannel registered | Hour 14, Day 1 | Nelly | `MainActivity.kt` compiles, channel name confirmed |
| Decision engine complete | Hour 12, Day 1 | Nyakallo | Full `assess_network` logic wired |
| App calls real Rust | Hour 12, Day 1 | Nyakallo | Verdict from FFI, not hardcoded |
| Real Android WiFi data | Hour 20, Day 1 | Nyakallo + Nelly | Real BSSID shown in debug logs on demo phone |
| First full dry-run | Hour 20, Day 1 | Siwa | Runs start to finish without crash |
| Demo on physical phone | Hour 4, Day 2 | Nyakallo | App installs and runs, real BSSID detected |
| Final demo run x3 | Hour 8, Day 2 | Siwa | All three runs under 5 min, no crashes |

---

---

# WiFiGuard SDK — README

```
██╗    ██╗██╗███████╗██╗ ██████╗ ██╗   ██╗ █████╗ ██████╗ ██████╗
██║    ██║██║██╔════╝██║██╔════╝ ██║   ██║██╔══██╗██╔══██╗██╔══██╗
██║ █╗ ██║██║█████╗  ██║██║  ███╗██║   ██║███████║██████╔╝██║  ██║
██║███╗██║██║██╔══╝  ██║██║   ██║██║   ██║██╔══██║██╔══██╗██║  ██║
╚███╔███╔╝██║██║     ██║╚██████╔╝╚██████╔╝██║  ██║██║  ██║██████╔╝
 ╚══╝╚══╝ ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝
```

**On-Device Evil Twin Detection for South African Mobile Banking**
Team Themis | ITWeb Security Summit 2026 | SS26Hack

---

## What This Is

WiFiGuard is a lightweight (~2MB) SDK that South African banking apps embed directly.
Before any login or transaction packet leaves the device, WiFiGuard checks the WiFi
environment for Evil Twin rogue access points — the primary network-layer vector
behind SA's R1.888 billion digital banking fraud crisis.

**The check happens in under 150ms. Before TLS. Before any data moves.**

---

## Repository Structure

```
wifiguard/
├── core/                      # Nyakallo — Rust detection engine
│   ├── src/
│   │   ├── lib.rs             # assess_network() — main entry point + decision engine
│   │   ├── bssid.rs           # BSSID/OUI fingerprinting
│   │   └── rssi.rs            # RSSI variance analysis
│   └── Cargo.toml
│
├── app/                       # Nyakallo — Flutter demo application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app.dart
│   │   ├── screens/
│   │   │   ├── scan_screen.dart      # Spinner — "Checking network safety..."
│   │   │   └── result_screen.dart    # SAFE / SUSPECT / BLOCKED verdict screen
│   │   ├── services/
│   │   │   ├── wifiguard_service.dart    # Calls Rust via FFI, returns verdict string
│   │   │   └── platform_channel.dart    # Dart side of MethodChannel → Kotlin
│   │   └── src/rust/          # flutter_rust_bridge generated — DO NOT EDIT
│   └── android/
│       └── app/src/main/
│           ├── kotlin/
│           │   ├── WifiTelemetry.kt   # Nelly — reads BSSID + RSSI from WifiManager
│           │   └── MainActivity.kt    # Nelly — MethodChannel registration
│           ├── AndroidManifest.xml    # Nelly — WiFi + Location permissions
│           └── jniLibs/              # Nyakallo — compiled Rust .so files land here
│               ├── arm64-v8a/libwifiguard_core.so
│               └── x86_64/libwifiguard_core.so
│
├── lab/                       # Ziphezinhle — Rogue AP demo environment
│   ├── toggle.py              # LIVE DEMO: python3 toggle.py [on|off|status]
│   ├── events.json            # Auto-generated event log (read by dashboard)
│   └── configs/
│       ├── evil_twin.conf     # hostapd — broadcasts fake SSID
│       └── dnsmasq.conf       # DNS poison — redirects banking domains
│
├── dashboard/                 # Siwa — FastAPI live threat monitor
│   └── main.py                # Reads events.json, serves live block event feed
│
└── docs/
    ├── WiFiGuard_Technical_Whitepaper.docx
    ├── Technical_Outline.pptx
    ├── WiFiGuard_Business_Model.pptx
    └── demo_script.md         # Siwa — word-for-word 5-minute demo script
```

---

## Team Responsibilities

| Name | Lane | Key Deliverable |
|------|------|----------------|
| **Nyakallo** | Rust core + Flutter app + integration | `assess_network()` engine, `.so` compilation, three Flutter screens, `wifiguard_service.dart` wired to real Rust output |
| **Nelly** | Android native bridge | `WifiTelemetry.kt` reads real BSSID/RSSI, `MainActivity.kt` registers `MethodChannel`, `AndroidManifest.xml` permissions |
| **Ziphezinhle** | Rogue AP lab | Live toggleable Evil Twin: `hostapd` + `dnsmasq`, `toggle.py` script, confirmed DNS poison on demo device |
| **Siwa** | Pitch + dashboard | 5-minute demo script, slide deck, FastAPI dashboard showing live block events from `events.json` |

---

## Prerequisites

### Nyakallo (Rust + Flutter)
```bash
# Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add aarch64-linux-android x86_64-linux-android
cargo install cargo-ndk flutter_rust_bridge_codegen

# Flutter
# Install Flutter SDK: https://docs.flutter.dev/get-started/install
flutter doctor       # Fix every red item before the hackathon
cd app
flutter pub get
```

### Nelly (Android Native)
```bash
# Android Studio + Android SDK required
# Kotlin plugin (bundled with Android Studio)
# No additional installs — works within the Flutter Android project
```

### Ziphezinhle (Rogue AP Lab — Linux only)
```bash
sudo apt update
sudo apt install hostapd dnsmasq iptables python3 python3-pip -y
pip3 install fastapi uvicorn

# Confirm WiFi adapter supports AP mode
iw list | grep -A 10 "Supported interface modes" | grep AP
# Must see "AP" — if not, use TP-Link TL-WN722N USB adapter
```

### Siwa (Dashboard + Pitch)
```bash
pip3 install fastapi uvicorn
# Access dashboard at http://localhost:8000 after Ziphezinhle runs toggle.py
```

---

## Building and Running

### 1. Rust Core (Nyakallo)

```bash
cd core

# Run all tests — must pass before compiling
cargo test

# Compile for physical Android device (ARM64)
cargo ndk -t arm64-v8a -o ../app/android/app/src/main/jniLibs build --release

# Compile for Android emulator (x86_64)
cargo ndk -t x86_64 -o ../app/android/app/src/main/jniLibs build --release

# Generate Dart bridge code from Rust signatures
flutter_rust_bridge_codegen generate
# Output lands in app/lib/src/rust/ — never edit these files manually
```

### 2. Flutter App (Nyakallo)

```bash
cd app
flutter pub get
flutter run                      # Emulator
flutter run -d [device-id]       # Physical demo phone
flutter devices                  # Lists connected devices and their IDs
flutter build apk --release      # Build APK for sideloading if needed
```

### 3. Rogue AP Lab (Ziphezinhle)

```bash
# Must run as root or with sudo configured for passwordless execution
python3 lab/toggle.py on      # 🔴 Evil Twin LIVE — DNS poisoned
python3 lab/toggle.py off     # 🟢 Clean network — Evil Twin down
python3 lab/toggle.py status  # Check current state
```

### 4. Live Dashboard (Siwa)

```bash
cd dashboard
uvicorn main:app --host 0.0.0.0 --port 8000
# Open http://localhost:8000 in browser during demo
# Auto-refreshes every 3 seconds with live block events
```

---

## How Detection Works

```
Banking app calls WiFiGuard.assess() before any login or transaction
                              │
                              ▼
        ┌─────────────────────────────────────────┐
        │           assess_network()               │
        │                                          │
        │  BSSID ──► OUI lookup                   │
        │             Known-bad/local MAC? ──► BLOCK│
        │             Unknown OUI? ──► +1 SUSPECT  │
        │                                          │
        │  RSSI  ──► Variance analysis             │
        │             Strong AND unstable? ──► +1  │
        │                                          │
        │  RTT   ──► Baseline comparison           │
        │             > baseline×2.5               │
        │             AND > baseline+15ms? ──► +1  │
        │             (skipped on first visit)     │
        │                                          │
        │  DNS   ──► Layer 1: baked-in IP list     │
        │             Mismatch? ──► BLOCK (hard)   │
        └─────────────────────────────────────────┘
                              │
               ┌──────────────┼──────────────┐
               ▼              ▼              ▼
            SAFE           SUSPECT        BLOCKED
         (0 signals)      (1–2 signals)  (DNS fail or
                                          3+ signals)
```

**Fail-secure:** Any SDK exception or error returns `BLOCKED`, never `SAFE`.
**DNS is a hard block:** DNS mismatch overrides all other signals immediately.
**RTT first-visit:** No baseline on first BSSID encounter — RTT contributes 0 weight.

---

## Verdict Reference

| Verdict | Trigger | App Behaviour |
|---------|---------|--------------|
| `SAFE` | All checks passed | Banking flow proceeds normally |
| `SUSPECT` | 1–2 anomaly signals | Advisory shown, user may continue |
| `BLOCKED` | DNS mismatch OR 3+ signals | Hard block — transaction and login disabled, one-tap switch to mobile data |

---

## Hackathon Scope

**Built and demo-able:**
- Android API 28+ (covers 95%+ of SA banking devices)
- BSSID OUI fingerprinting with known-bad consumer hardware patterns
- RSSI variance analysis (variance + strength dual-condition)
- RTT baseline engine (first-visit mode active for demo)
- DNS Layer 1 offline check (baked-in signed IP list)
- Flutter demo app: Scan → SAFE / SUSPECT / BLOCKED
- Live Evil Twin lab with one-command toggle
- FastAPI dashboard showing real-time block events

**Post-hackathon (Phase 2/3):**
- iOS full coverage (Apple NEHotspotHelper entitlement required)
- DNS Layer 2 DoH over cellular interface
- On-device ML anomaly detection (TFLite)
- Crowdsourced AP threat intelligence
- RegTech dashboard for bank security operations

---

## Key Design Decisions

**Why Rust for the core?**
No garbage collector means no GC pause during a transaction check. Compiled to native
ARM64 — zero JVM overhead. ~600KB binary. Memory safety enforced at compile time, not
runtime. The entire detection engine fits in 600KB with no runtime dependencies.

**Why fully offline?**
POPIA Section 19 requires zero PII off-device. A cloud-dependent check means user
network metadata leaves the device on every transaction — that's a compliance violation
and a single point of failure. WiFiGuard's core four checks need zero network calls.

**Why Android-first?**
80%+ of South African banking users are on Android. Capitec and TymeBank's demographic
is budget Android. iOS restricts BSSID access since iOS 13 without a special Apple
entitlement that takes weeks to obtain. The problem is on Android. That's where we solve it.

**Why pre-transaction?**
Zimperium and F5 detect threats at session time — the network pipe is already open.
WiFiGuard fires before TLS starts. The attacker's rogue AP never gets a packet to intercept.

---

## Licence

MIT — build on it, embed it, ship it.

The incumbents sell shovels to the entire gold rush.
WiFiGuard is the one tool South African banks actually need right now —
lightweight, offline, pre-emptive, and built for the R1.888 billion problem
in the zero-rated public WiFi channel.

**Team Themis** — ITWeb Security Summit 2026