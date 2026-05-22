# WiFiGuard SDK

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

WiFiGuard is a lightweight (~2MB), fully offline, on-device SDK that South African banking apps embed directly. Before any login or transaction packet leaves the device, WiFiGuard inspects the WiFi environment for Evil Twin rogue access points — the primary network-layer vector behind SA's R1.888 billion digital banking fraud crisis.

**The check happens in under 150ms. Before TLS. Before any data moves.**

No cloud. No PII off-device. POPIA-compliant by architecture.

---

## The Problem in One Paragraph

South Africa's zero-rated banking agreements keep apps active on public WiFi to save airtime. Attackers exploit this by deploying Evil Twin rogue access points — same network name, different hardware — at taxi ranks, malls, and airports. Once connected, they intercept session tokens, poison DNS, and inject phishing overlays before a single TLS handshake occurs. SABRIC 2024 recorded 97,975 digital banking incidents — an 86% year-on-year increase — with total losses of R1.888 billion. Existing solutions don't stop it at the network layer. WiFiGuard does.

---

## Repository Structure

```
wifiguard/
├── core/                        # Rust detection engine (Nyakallo)
│   ├── src/
│   │   ├── lib.rs               # assess_network() — main SDK entry point
│   │   ├── bssid.rs             # BSSID/OUI fingerprinting module
│   │   └── rssi.rs              # RSSI variance analysis module
│   └── Cargo.toml
│
├── app/                         # Flutter demo application (Nyakallo)
│   ├── lib/
│   │   ├── main.dart            # Entry point
│   │   ├── app.dart             # MaterialApp root
│   │   ├── screens/
│   │   │   ├── scan_screen.dart       # Scanning state (spinner)
│   │   │   └── result_screen.dart     # SAFE / SUSPECT / BLOCKED display
│   │   ├── services/
│   │   │   ├── wifiguard_service.dart # Calls Rust via FFI, returns verdict
│   │   │   └── platform_channel.dart  # Dart side of Android MethodChannel
│   │   └── src/rust/            # flutter_rust_bridge generated — DO NOT EDIT
│   │
│   └── android/
│       └── app/src/main/
│           ├── kotlin/.../
│           │   ├── WifiTelemetry.kt   # Reads BSSID + RSSI from WifiManager (Nelly)
│           │   └── MainActivity.kt    # MethodChannel setup (Nelly)
│           ├── AndroidManifest.xml    # WiFi permissions (Nelly)
│           └── jniLibs/              # Compiled Rust .so files (auto-generated)
│               ├── arm64-v8a/
│               │   └── libwifiguard_core.so
│               └── x86_64/
│                   └── libwifiguard_core.so
│
├── lab/                         # Evil Twin lab (Ziphezinhle)
│   ├── toggle.py                # Live demo toggle — on/off/status
│   ├── events.json              # Auto-generated event log
│   └── configs/
│       ├── evil_twin.conf       # hostapd rogue AP config
│       └── dnsmasq.conf         # DNS poisoning config
│
├── dashboard/                   # FastAPI block-event dashboard (Siwa)
│   └── main.py                  # Live threat monitor — http://localhost:8000
│
└── docs/
    ├── WiFiGuard_Technical_Whitepaper.docx
    ├── Technical_Outline.pptx
    └── WiFiGuard_Business_Model.pptx
```

---

## Team

| Name | Lane | Owns |
|------|------|------|
| **Nyakallo** | Rust core + Flutter app + Integration | `core/` + `app/lib/` + bridge compilation |
| **Nelly** | Android native layer | `WifiTelemetry.kt` + `MainActivity.kt` + `AndroidManifest.xml` |
| **Ziphezinhle** | Rogue AP lab | `lab/` — hostapd, dnsmasq, toggle script |
| **Siwa** | Demo + Dashboard + Pitch | `dashboard/` + demo script + slide deck |

---

## Prerequisites

### Nyakallo (Rust + Flutter)

```bash
# Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add aarch64-linux-android x86_64-linux-android
cargo install cargo-ndk flutter_rust_bridge_codegen

# Flutter
flutter doctor   # Fix every red item before the hackathon
cd app && flutter pub get
```

### Nelly (Android / Kotlin)

```bash
# Android Studio with SDK + NDK installed
# Kotlin plugin (bundled with Android Studio)
# No additional installs — works within the Flutter Android project
```

### Ziphezinhle (Lab — Linux required)

```bash
sudo apt update
sudo apt install hostapd dnsmasq iptables python3 -y

# Verify WiFi adapter supports AP mode
iw list | grep -A 10 "Supported interface modes" | grep AP
# Must print "AP" — if not, use TP-Link TL-WN722N USB adapter
```

### Siwa (Dashboard + Pitch)

```bash
pip3 install fastapi uvicorn
# Python 3.8+ required
```

---

## Building

### 1. Rust Core (Nyakallo)

```bash
cd core

# Run all tests — must pass before compiling
cargo test

# Compile for physical demo device (ARM64)
cargo ndk -t arm64-v8a -o ../app/android/app/src/main/jniLibs build --release

# Compile for emulator (x86_64)
cargo ndk -t x86_64 -o ../app/android/app/src/main/jniLibs build --release

# Generate Dart bridge code (run from repo root)
flutter_rust_bridge_codegen generate
# Output lands in app/lib/src/rust/ — do not edit these files
```

Confirm `.so` files exist before telling Nelly and running Flutter:

```bash
ls app/android/app/src/main/jniLibs/
# arm64-v8a/libwifiguard_core.so
# x86_64/libwifiguard_core.so
```

### 2. Android Native Layer (Nelly)

Work inside `app/android/app/src/main/`:

**AndroidManifest.xml** — add before `<application>`:
```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE"/>
```

**WifiTelemetry.kt** — reads real device WiFi state:
```kotlin
class WifiTelemetry(private val context: Context) {
    private val wifiManager =
        context.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager

    fun getBssid(): String = wifiManager.connectionInfo?.bssid ?: "00:00:00:00:00:00"

    fun getRssiSamples(count: Int = 5): List<Int> {
        val samples = mutableListOf<Int>()
        repeat(count) {
            samples.add(wifiManager.connectionInfo?.rssi ?: -100)
            Thread.sleep(100)
        }
        return samples
    }
}
```

**MainActivity.kt** — wire to Flutter MethodChannel:
```kotlin
override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val telemetry = WifiTelemetry(applicationContext)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
                  "com.teamthemis.wifiguard/wifi")
        .setMethodCallHandler { call, result ->
            when (call.method) {
                "getBssid"       -> result.success(telemetry.getBssid())
                "getRssiSamples" -> result.success(telemetry.getRssiSamples())
                else             -> result.notImplemented()
            }
        }
}
```

### 3. Flutter App (Nyakallo)

```bash
cd app
flutter pub get
flutter run                    # Emulator
flutter run -d [device-id]    # Physical device
flutter devices                # List connected devices
flutter build apk --release   # Build APK for demo device
```

### 4. Evil Twin Lab (Ziphezinhle)

```bash
# Assign IP to adapter
sudo ip addr add 192.168.1.1/24 dev wlan0
sudo ip link set wlan0 up

# Start rogue AP + DNS poison
python3 lab/toggle.py on

# Stop — restore clean network
python3 lab/toggle.py off

# Check current state
python3 lab/toggle.py status
```

**Verify DNS poison is working** (from a device connected to the rogue AP):
```bash
nslookup fnb.co.za
# Should return 192.168.1.1 — not FNB's real IP
```

### 5. Live Dashboard (Siwa)

```bash
cd dashboard
uvicorn main:app --host 0.0.0.0 --port 8000
# Open http://localhost:8000
# Page auto-refreshes every 3 seconds — shows live toggle events
```

---

## How Detection Works

```
                    assess_network()
                          │
          ┌───────────────┼───────────────┐
          │               │               │
     BSSID Check     RSSI Check      RTT Check
     OUI lookup      Variance        Baseline
     Local MAC?      > 8 dBm?        × 2.5 AND
     Known-bad?      Too strong?     + 15ms?
          │               │               │
        SUSPECT?        SUSPECT?        SUSPECT?
          └───────────────┼───────────────┘
                          │
                     DNS Check (runs first)
                     Layer 1: baked-in IP list
                     Layer 2: DoH over cellular
                          │
               ┌──────────┴──────────┐
          DNS mismatch          DNS clean
               │                     │
           BLOCKED ◄─── 3+ SUSPECT signals
                        1-2 SUSPECT → SUSPECT
                        0 SUSPECT   → SAFE
```

**Fail-secure:** Any SDK exception returns `BLOCKED`, never `SAFE`.

---

## Verdict Reference

| Verdict | Trigger | App Behaviour |
|---------|---------|---------------|
| `SAFE` | All checks pass | Banking flow proceeds normally |
| `SUSPECT` | 1–2 anomalous signals | Advisory shown, flow continues with flag |
| `BLOCKED` | DNS mismatch OR 3+ signals | Hard block — transaction and login disabled |

---

## Detection Logic Reference

**BSSID Fingerprinting**
Extracts the OUI (first 3 bytes of MAC address). Flags locally administered MACs (bit 1 of first byte set — always suspicious), known-bad consumer hotspot chipsets, and unknown OUIs not in the enterprise allowlist.

**RSSI Variance Analysis**
Takes 5 samples over 500ms. Flags when signal is abnormally strong (> -40 dBm, indicating a portable device very close to the victim) AND variance exceeds 8 dBm (indicating a moving/portable device). Both conditions required — prevents false positives from sitting near a legitimate fixed AP.

**RTT Baseline Engine**
On first BSSID encounter, no baseline exists — RTT contributes reduced weight. On repeat visits, 5 probes taken and median compared to encrypted on-device baseline (Android Keystore). Flag raised only when `current > (baseline × 2.5) AND current > (baseline + 15ms)` — dual condition prevents false positives from congested public WiFi.

**DNS Consistency Check**
Layer 1: local DNS resolution result compared against baked-in signed IP list. Zero network calls. Mismatch = immediate hard block. Layer 2: DoH query to 1.1.1.1 / 9.9.9.9 bound exclusively to cellular interface — never sent over the suspect WiFi. Skipped gracefully if cellular unavailable.

---

## Hackathon Scope

**In scope — built and demoed:**
- Android API 28+ (covers 95%+ of SA banking devices)
- BSSID OUI fingerprinting
- RSSI variance analysis
- RTT engine (first-visit mode for demo — no pre-existing baseline)
- DNS Layer 1 (baked-in IP list)
- Flutter demo app: Scan → SAFE / SUSPECT / BLOCKED
- Live toggleable Evil Twin lab
- FastAPI threat dashboard

**Out of scope — Phase 3:**
- iOS (requires Apple NEHotspotHelper entitlement — weeks of approval)
- DNS Layer 2 DoH over cellular (requires production cellular binding)
- ML-based anomaly scoring (TFLite on-device model)
- Crowdsourced AP threat intelligence

---

## Demo Sequence

```
[Ziphezinhle] python3 lab/toggle.py off
  → One network in room. Phone connects to real AP.
  → Nyakallo runs app.
  → WiFiGuard: BSSID known, RSSI stable, DNS clean → ✅ SAFE

[Ziphezinhle] python3 lab/toggle.py on
  → Evil Twin activates. Same SSID. Different BSSID. DNS poisoned.
  → Nyakallo runs app.
  → WiFiGuard: BSSID mismatch + DNS mismatch → 🚫 BLOCKED

[Ziphezinhle] python3 lab/toggle.py off
  → Evil Twin down. Clean network restored.
  → Nyakallo runs app.
  → WiFiGuard: All clear → ✅ SAFE

[Siwa] Points judges to http://localhost:8000
  → Dashboard shows live event log of all three toggles.
```

Total demo time: under 3 minutes.

---

## Key Design Decisions

**Why Rust for the core?**
No garbage collector means no GC pause spikes during a banking transaction. Compiled to native ARM64 — no JVM overhead, no runtime dependencies. ~600KB binary. Memory safety enforced at compile time.

**Why fully offline?**
POPIA Section 19 requires zero PII off-device. All WiFi telemetry (BSSID, RSSI, RTT) is assessed on-device and logged encrypted in Android Keystore. DoH Layer 2 uses the cellular interface only — never traverses the suspect WiFi — and is gracefully skipped when unavailable.

**Why Android-first?**
80%+ of SA banking devices run Android. iOS has restricted raw BSSID access since iOS 13 without a special Apple entitlement that takes months to approve. Android is where the problem lives and where the solution ships.

**Why pre-transaction?**
Zimperium and F5 MobileSafe detect threats at session time — after a network pipe to the attacker already exists. WiFiGuard blocks before TLS starts. There is no pipe for the attack to travel through.

**Why a SDK and not an app?**
Banks already have 10M+ users on their apps. They are not replacing their app with ours. WiFiGuard embeds into the host app via a single function call and returns a verdict. The bank controls all UX. We sell the detection layer, not the product.

---

## Compliance Positioning

| Regulation | Requirement | WiFiGuard Response |
|------------|-------------|-------------------|
| **POPIA Section 19** | Appropriate, reasonable technical measures against unauthorised access | Pre-transaction block before any data traverses attacker-controlled network |
| **Joint Standard 2** | Documented third-party security controls + periodic audits | Tamper-evident on-device audit log, MSTG-verified OWASP compliance |
| **OWASP M5** | No insecure communication permitted | Hard block before TLS — no insecure channel opens |
| **OWASP M3** | Insecure authentication prevention | Network-layer block prevents credential harvesting via phishing overlay |

---

## Competitive Advantage

| Feature | WiFiGuard | Zimperium zIAP | F5 MobileSafe | Bank Advisory |
|---------|-----------|---------------|--------------|--------------|
| Fully offline | ✅ | ❌ Cloud ML | ❌ Cloud | N/A |
| < 2MB footprint | ✅ | ❌ 20+ MB | ❌ Heavy suite | N/A |
| Pre-transaction block | ✅ | ⚠️ Session-time | ⚠️ Session-time | ❌ None |
| SA zero-rated optimised | ✅ | ❌ Generic | ❌ Generic | ❌ None |
| < 150ms latency | ✅ | ⚠️ Cloud RTT | ⚠️ Cloud RTT | N/A |
| Zero PII off-device | ✅ | ⚠️ Cloud telemetry | ⚠️ Cloud telemetry | ✅ |
| Freemium entry | ✅ R0.15/MAU | ❌ Enterprise only | ❌ Enterprise only | Free (no value) |

---

## Licence

MIT — build on it, embed it, ship it.

The incumbents sell shovels to the entire 0gold rush.
WiFiGuard is the one tool SA banks actually need right now.
That's not a student project. That's the shovel they've been missing.

---

*Team Themis — ITWeb Security Summit 2026*