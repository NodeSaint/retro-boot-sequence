#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  CAIS — Central Armament & Intelligence System
#  Boot Sequence Simulator (Terminal Edition)
# ═══════════════════════════════════════════════════════════════

set -e

# ── Colors ───────────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
W='\033[1;37m'
D='\033[2m'
BD='\033[1m'
BL='\033[5m'
RST='\033[0m'
BG_R='\033[41m'
BG_Y='\033[43m'

BELL=$'\a'
COLS=$(tput cols 2>/dev/null || echo 80)

# ── Utilities ────────────────────────────────────────────────

tw() {
    local text="$1" delay="${2:-0.02}"
    for ((i=0; i<${#text}; i++)); do
        printf '%s' "${text:$i:1}"
        sleep "$delay"
    done
}

twc() { printf '%b' "$1"; tw "$2" "${3:-0.02}"; printf '%b' "$RST"; }

hr() {
    local ch="${1:-─}" col="${2:-$D}"
    printf '%b' "$col"
    printf '%*s' "$COLS" '' | tr ' ' "$ch"
    printf '%b\n' "$RST"
}

scramble() {
    local final="$1" iters="${2:-8}"
    local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*<>{}[]|'
    local len=${#final}
    for ((iter=0; iter<iters; iter++)); do
        printf '\r'
        for ((i=0; i<len; i++)); do
            if ((iter >= iters-1)); then
                printf '%b%s' "$G" "${final:$i:1}"
            elif ((i < iter * len / iters / 2)); then
                printf '%b%s' "$G" "${final:$i:1}"
            else
                printf '%b%s' "$C" "${chars:$((RANDOM % ${#chars})):1}"
            fi
        done
        sleep 0.06
    done
    printf '%b\n' "$RST"
}

pbar() {
    local label="$1" steps=30 dur="$2" slow="${3:-0}"
    local step_delay
    step_delay=$(echo "$dur / $steps" | bc -l 2>/dev/null || echo "0.04")
    for ((i=0; i<=steps; i++)); do
        local pct=$((i * 100 / steps))
        printf '\r  %b%-30s%b [' "$C" "$label" "$RST"
        for ((j=0; j<steps; j++)); do
            if ((j<i)); then printf '%b█' "$G"
            else printf '%b░' "$D"; fi
        done
        printf '%b] %3d%%' "$G" "$pct"

        # Glitch on nuclear auth module
        if ((slow && pct == 33)); then
            printf '%b' "$BELL"
            sleep 0.3
            printf '\r  %b%-30s%b [' "$Y" "$label" "$RST"
            for ((j=0; j<steps; j++)); do printf '%b▓' "$Y"; done
            printf '%b] AUTH' "$Y"
            sleep 0.5
        fi
        sleep "$step_delay"
    done
    if ((slow)); then
        printf '%b  ■ ARMED%b\n' "$Y" "$RST"
    else
        printf '%b  ✓%b\n' "$G" "$RST"
    fi
}

hexblock() {
    local lines="${1:-6}" speed="${2:-0.02}"
    for ((i=0; i<lines; i++)); do
        local addr=$(printf '%08X' $((RANDOM * RANDOM + i * 16)))
        printf '%b  %s: ' "$D" "$addr"
        for ((j=0; j<12; j++)); do printf '%02X ' $((RANDOM % 256)); done
        printf '|'
        for ((j=0; j<12; j++)); do
            printf "\\$(printf '%03o' $((RANDOM % 95 + 32)))"
        done
        printf '|%b\n' "$RST"
        sleep "$speed"
    done
}

sha_hash() {
    printf '%b' "$D"
    for ((i=0; i<16; i++)); do printf '%02x' $((RANDOM % 256)); done
    printf '%b' "$RST"
}

# ── Cleanup ──────────────────────────────────────────────────
cleanup() { tput cnorm 2>/dev/null; printf '%b\n' "$RST"; exit 0; }
trap cleanup EXIT INT TERM

# ══════════════════════════════════════════════════════════════
#  BOOT SEQUENCE
# ══════════════════════════════════════════════════════════════

clear
tput civis 2>/dev/null

# ── PHASE 1: CLASSIFICATION BANNER ───────────────────────────
printf '%b' "$BELL"
sleep 0.2
printf '%b' "$BELL"

hr '━' "$R"
printf '%b%b' "$BG_R" "$W"
printf '  %-*s' "$((COLS-2))" '██ TOP SECRET // SCI // NOFORN // ORCON'
printf '%b\n' "$RST"
printf '%b%b' "$BG_R" "$W"
printf '  %-*s' "$((COLS-2))" '██ WARNING: UNAUTHORIZED ACCESS WILL BE PROSECUTED UNDER 10 U.S.C. §906a / 18 U.S.C. §1030'
printf '%b\n' "$RST"
hr '━' "$R"
echo ""
sleep 0.5

# ── PHASE 2: SYSTEM DESIGNATION ──────────────────────────────
printf '%b' "$G"
cat << 'HEADER'
   ▄████▄   ▄▄▄       ██▓  ██████
  ▒██▀ ▀█  ▒████▄    ▓██▒▒██    ▒
  ▒▓█    ▄ ▒██  ▀█▄  ▒██▒░ ▓██▄
  ▒▓▓▄ ▄██▒░██▄▄▄▄██ ░██░  ▒   ██▒
  ▒ ▓███▀ ░ ▓█   ▓██▒░██░▒██████▒▒
  ░ ░▒ ▒  ░ ▒▒   ▓▒█░░▓  ▒ ▒▓▒ ▒ ░
    ░  ▒     ▒   ▒▒ ░ ▒ ░░ ░▒  ░ ░
  ░          ░   ▒    ▒ ░░  ░  ░
  ░ ░            ░  ░ ░        ░
  ░
HEADER
printf '%b' "$RST"

printf '%b  CENTRAL ARMAMENT & INTELLIGENCE SYSTEM%b\n' "$BD$G" "$RST"
printf '%b  DEPARTMENT OF DEFENSE  //  JSOC TIER-1 CLEARANCE REQUIRED%b\n' "$D" "$RST"
serial="CAIS-$(printf '%04X-%04X-%04X' $RANDOM $RANDOM $RANDOM)"
printf '%b  SYSTEM ID: %s  //  BUILD 7.4.1-CLASSIFIED%b\n' "$D" "$serial" "$RST"
echo ""
sleep 0.6

# ── PHASE 3: FIRMWARE POST ──────────────────────────────────
twc "$Y" "POWER-ON SELF TEST" 0.02
echo ""
hr '─' "$D"

printf '%b  PLATFORM:   %b' "$D" "$RST"; scramble "LOCKHEED MARTIN MIL-SPEC HARDENED PLATFORM"
printf '%b  CPU:        %b' "$D" "$RST"; scramble "XEON CLASSIFIED 64-CORE @ 4.2GHz (TEMPEST SHIELDED)"
printf '%b  CRYPTO:     %b' "$D" "$RST"; scramble "NSA TYPE-1 SUITE B // QUANTUM-RESISTANT LATTICE"
printf '%b  TPM:        %b' "$D" "$RST"; scramble "TRUSTED PLATFORM MODULE v3.1 — FIPS 140-3 LVL 4"
printf '%b  ENCLAVE:    %b' "$D" "$RST"; scramble "SGX SECURE ENCLAVE ACTIVE — 512MB ISOLATED"
echo ""

# ── PHASE 4: SECURE BOOT CHAIN ──────────────────────────────
twc "$Y" "VERIFYING SECURE BOOT CHAIN" 0.02
echo ""

stages=("STAGE 0  HARDWARE ROOT OF TRUST" "STAGE 1  BOOTLOADER" "STAGE 2  KERNEL" "STAGE 3  SECOPS LAYER" "STAGE 4  CAIS CORE")
for s in "${stages[@]}"; do
    printf '  %b■%b %-35s ' "$G" "$RST" "$s"
    sha_hash
    printf '  '
    # Quick hash scramble animation
    for ((k=0; k<3; k++)); do
        printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
        sha_hash
        printf '  '
        sleep 0.08
    done
    printf '%bVALID%b\n' "$G" "$RST"
    sleep 0.1
done
printf '\n  %bSECURE BOOT CHAIN: INTACT ■■■■■%b\n\n' "$G$BD" "$RST"
sleep 0.3

# ── PHASE 5: MEMORY INIT ────────────────────────────────────
twc "$Y" "INITIALIZING PROTECTED MEMORY" 0.02
echo ""
printf '%b  ECC RAM SCAN: ' "$D"
for bank in "BANK-0 128GB" "BANK-1 128GB" "BANK-2 128GB" "BANK-3 128GB"; do
    printf '%s...' "$bank"
    sleep 0.15
    printf '%bOK%b  ' "$G" "$D"
done
printf '%b\n' "$RST"
printf '%b  TOTAL: 512GB ECC DDR5 — TEMPEST CERTIFIED%b\n' "$G" "$RST"
printf '%b  LOADING ENCRYPTED MEMORY IMAGE...%b\n' "$D" "$RST"
hexblock 6 0.02
echo ""

# ── PHASE 6: CORE SYSTEMS ───────────────────────────────────
hr '═' "$G"
printf '%b ■ CORE SYSTEMS INITIALIZATION%b\n' "$W$BD" "$RST"
hr '═' "$G"
echo ""

pbar "HARDENED KERNEL (SELINUX)" 0.8
pbar "CRYPTOGRAPHIC KEY STORE" 0.6
pbar "RADAR FUSION ENGINE" 0.9
pbar "SATELLITE LINK (MILSTAR/AEHF)" 1.0
pbar "TACTICAL DATA LINK (LINK-16)" 0.7
pbar "FIRE CONTROL COMPUTER" 0.8
pbar "ELECTRONIC WARFARE SUITE" 1.1
pbar "HYPERSONIC GUIDANCE SYSTEM" 1.2
pbar "ACOUSTIC DEEP-SEA ARRAY" 0.6
pbar "DIRECTED ENERGY WEAPONS" 0.9
pbar "NUCLEAR COMMAND AUTH MODULE" 2.0 1
echo ""
sleep 0.3

# ── PHASE 7: ENCRYPTED MESH ─────────────────────────────────
hr '═' "$G"
printf '%b ■ ESTABLISHING ENCRYPTED MESH%b\n' "$W$BD" "$RST"
hr '═' "$G"
echo ""

declare -a mesh_nodes=(
    "OLYMPUS         STRATCOM          CH-01A   AES-256-GCM"
    "LOOKING GLASS   AIRBORNE CMD      CH-03F   TYPE-1/SCI"
    "KEYHOLE-19      NRO SIGINT SAT    CH-07X   QKD-ENABLED"
    "ECHELON-VII     NSA/CSS INTERCEPT CH-12R   QUANTUM-OTP"
    "PRISM-NODE      CIA SOG           CH-14D   AES-256-GCM"
    "DEEP BLUE       SUBSURFACE CMD    CH-22S   TYPE-1/SCI"
    "IRON DOME+      MISSILE DEFENSE   CH-31M   AES-256-GCM"
    "SHADOW NET      JSOC MESH         CH-99X   QKD-ENABLED"
)

printf '  %b%-16s %-18s %-9s %-14s STATUS%b\n' "$D" "CALLSIGN" "NETWORK" "CHANNEL" "ENCRYPTION" "$RST"
printf '  %b%s%b\n' "$D" "$(printf '%.0s─' {1..75})" "$RST"

for node in "${mesh_nodes[@]}"; do
    printf '  %b%-16s %-18s %-9s %-14s' "$C" $(echo "$node")
    sleep 0.12
    printf '%b■ SYNC%b\n' "$G$BD" "$RST"
done

echo ""
printf '%b  MESH INTEGRITY: 100%%  //  LATENCY: <2ms  //  QUANTUM-HARDENED%b\n\n' "$G$BD" "$RST"
sleep 0.3

# ── PHASE 8: WEAPONS PLATFORM STATUS ────────────────────────
hr '═' "$G"
printf '%b ■ WEAPONS PLATFORM STATUS%b\n' "$W$BD" "$RST"
hr '═' "$G"
echo ""

printf '  %b%-14s %-30s %-12s %s%b\n' "$D" "DESIGNATION" "PLATFORM" "TYPE" "STATUS" "$RST"
printf '  %b%s%b\n' "$D" "$(printf '%.0s─' {1..75})" "$RST"

weapons=(
    "MMIII-07A      LGM-30G MINUTEMAN III         ICBM         STANDBY"
    "MMIII-12C      LGM-30G MINUTEMAN III         ICBM         STANDBY"
    "SENTINEL-01    LGM-35A SENTINEL               ICBM         ARMED"
    "TRIDENT-D5     UGM-133A TRIDENT II            SLBM         PATROL"
    "LRSO-ALPHA     AGM-181A LONG RANGE STANDOFF   CRUISE       LOADED"
    "ARRW-09        AGM-183A HYPERSONIC BOOST-GLIDE HYPERSONIC   ARMED"
    "DARK EAGLE-03  LRHW HYPERSONIC WEAPON         HYPERSONIC   ARMED"
    "HACKSAW-7      CLASSIFIED ORBITAL PLATFORM    KINETIC      STANDBY"
    "AEGIS-BMD      SM-3 BLOCK IIA INTERCEPTOR     ABM          ACTIVE"
    "THAAD-BRAVO    TERMINAL HIGH ALTITUDE DEFENSE ABM          ACTIVE"
    "GBI-ALPHA      GROUND BASED INTERCEPTOR       ABM          ACTIVE"
    "DEW-LANCE      HIGH ENERGY LASER SYSTEM       DIRECTED-E   CHARGING"
)

for w in "${weapons[@]}"; do
    local_status="${w##* }"
    local_rest="${w% *}"

    if [[ "$local_status" == "ARMED" ]]; then
        printf '  %b%-14s %-30s %-12s' "$C" $(echo "$local_rest")
        printf ' %b▲ %s%b\n' "$R$BD" "$local_status" "$RST"
        printf '%b' "$BELL"
    elif [[ "$local_status" == "CHARGING" ]]; then
        printf '  %b%-14s %-30s %-12s' "$C" $(echo "$local_rest")
        printf ' %b◆ %s%b\n' "$Y" "$local_status" "$RST"
    elif [[ "$local_status" == "ACTIVE" ]]; then
        printf '  %b%-14s %-30s %-12s' "$C" $(echo "$local_rest")
        printf ' %b● %s%b\n' "$G" "$local_status" "$RST"
    else
        printf '  %b%-14s %-30s %-12s' "$C" $(echo "$local_rest")
        printf ' %b○ %s%b\n' "$D" "$local_status" "$RST"
    fi
    sleep 0.08
done

echo ""
printf '%b  12 PLATFORMS ONLINE  //  3 ARMED  //  3 INTERCEPTORS ACTIVE%b\n\n' "$Y$BD" "$RST"
sleep 0.4

# ── PHASE 9: SURVEILLANCE & LISTENING ────────────────────────
hr '═' "$G"
printf '%b ■ SURVEILLANCE & INTELLIGENCE GRID%b\n' "$W$BD" "$RST"
hr '═' "$G"
echo ""

printf '  %b%-24s %-10s %-8s %s%b\n' "$D" "FEED" "STATUS" "SIGNAL" "METRICS" "$RST"
printf '  %b%s%b\n' "$D" "$(printf '%.0s─' {1..75})" "$RST"

feeds=(
    "SIGINT (NSA/CSS)          ACTIVE     ██████  1,247 INTERCEPTS/HR"
    "GEOINT (NGA KEYHOLE)      ACTIVE     █████░  14 IMAGING SATS"
    "MASINT (DIA SENSORS)      ACTIVE     ██████  SEISMIC+ACOUSTIC+EM"
    "HUMINT (CIA/SOG)          ACTIVE     ████░░  ██ CLASSIFIED ██"
    "OSINT AGGREGATOR          ACTIVE     ██████  2.4M SOURCES/MIN"
    "DEEP-SEA HYDROPHONE NET   ACTIVE     █████░  SOSUS+IUSS COVERAGE"
    "OVER-HORIZON RADAR        ACTIVE     ██████  3,200NM RANGE"
    "SPACE-BASED INFRARED      ACTIVE     ██████  SBIRS CONSTELLATION"
    "CYBER THREAT FEEDS        ACTIVE     █████░  47K INDICATORS/HR"
    "EW SPECTRUM MONITOR       ACTIVE     ██████  0.1Hz — 100GHz"
)

for f in "${feeds[@]}"; do
    printf '  %b%s%b\n' "$C" "$f" "$RST"
    sleep 0.06
done

echo ""
sleep 0.3

# ── PHASE 10: THREAT BOARD ──────────────────────────────────
hr '═' "$R"
printf '%b%b ■ GLOBAL THREAT ASSESSMENT%b\n' "$R" "$BD" "$RST"
hr '═' "$R"
echo ""
printf '%b' "$BELL"

printf '%b' "$G"
cat << 'THREAT'
  ┌─────────────────────────────────────────────────────────────────┐
  │  DEFCON STATUS:         ██████ 3 — INCREASE IN FORCE READINESS │
  │  GLOBAL THREAT LEVEL:   ████████ ELEVATED                      │
  │  ACTIVE RADAR TRACKS:   1,247                                  │
  │  HOSTILE DESIGNATIONS:  3  (SEE CLASSIFIED ANNEX)              │
  │  UNKNOWN TRACKS:        17                                     │
  │  AIRBORNE ASSETS:       42 SORTIES                             │
  │  SUBMARINE PATROLS:     6 ACTIVE (POSITIONS WITHHELD)          │
  │  FORCE POSTURE:         ENHANCED READINESS                     │
  ├─────────────────────────────────────────────────────────────────┤
  │  MISSILE WARNING:       ░░░░░░░░░░░░░░░░ NO ACTIVE THREATS     │
  │  CYBER THREATCON:       ████░░░░░░░░░░░░ BRAVO                 │
  │  CBRN STATUS:           ░░░░░░░░░░░░░░░░ NOMINAL               │
  └─────────────────────────────────────────────────────────────────┘
THREAT
printf '%b\n' "$RST"

sleep 0.8

# ── PHASE 11: SYSTEM ONLINE ─────────────────────────────────
hr '═' "$G"
echo ""
printf '%b' "$BELL"
sleep 0.15
printf '%b' "$BELL"

printf '%b%b' "$G" "$BD"
cat << 'ONLINE'

   ▄████▄   ▄▄▄       ██▓  ██████      ▒█████   ███▄    █  ██▓     ██▓ ███▄    █ ▓█████
  ▒██▀ ▀█  ▒████▄    ▓██▒▒██    ▒     ▒██▒  ██▒ ██ ▀█   █ ▓██▒    ▓██▒ ██ ▀█   █ ▓█   ▀
  ▒▓█    ▄ ▒██  ▀█▄  ▒██▒░ ▓██▄       ▒██░  ██▒▓██  ▀█ ██▒▒██░    ▒██▒▓██  ▀█ ██▒▒███
  ▒▓▓▄ ▄██▒░██▄▄▄▄██ ░██░  ▒   ██▒    ▒██   ██░▓██▒  ▐▌██▒▒██░    ░██░▓██▒  ▐▌██▒▒▓█  ▄
  ▒ ▓███▀ ░ ▓█   ▓██▒░██░▒██████▒▒    ░ ████▓▒░▒██░   ▓██░░██████▒░██░▒██░   ▓██░░▒████▒
  ░ ░▒ ▒  ░ ▒▒   ▓▒█░░▓  ▒ ▒▓▒ ▒ ░    ░ ▒░▒░▒░░ ▒░   ▒ ▒ ░ ▒░▓  ░░▓  ░ ▒░   ▒ ▒ ░░ ▒░ ░
    ░  ▒     ▒   ▒▒ ░ ▒ ░░ ░▒  ░ ░      ░ ▒ ▒░  ░   ░ ░ ░ ░ ▒  ░ ▒ ░  ░   ░ ░  ░ ░  ░
  ░          ░   ▒    ▒ ░░  ░  ░       ░ ░ ░ ▒ ░   ░     ░ ░    ▒ ░░   ░      ░
  ░ ░            ░  ░ ░        ░           ░ ░       ░       ░  ░ ░          ░    ░  ░
  ░
ONLINE
printf '%b\n' "$RST"

printf '%b  ALL SYSTEMS NOMINAL — AWAITING COMMAND AUTHORITY%b\n' "$G$BD" "$RST"
echo ""
hr '━' "$R"
printf '%b%b  ██ TOP SECRET // SCI // NOFORN // ORCON%b\n' "$BG_R" "$W" "$RST"
hr '━' "$R"
echo ""

sleep 0.5
printf '%b' "$BELL"

# ── INTERACTIVE PROMPT ───────────────────────────────────────
tput cnorm 2>/dev/null

printf '%b' "$G"
tw "CAIS://> " 0.04
printf '%b' "$RST"
read -r user_input

if [[ -n "$user_input" ]]; then
    upper=$(echo "$user_input" | tr '[:lower:]' '[:upper:]')
    echo ""

    if [[ "$upper" == *"LAUNCH"* ]]; then
        twc "$R" "■ LAUNCH COMMAND RECEIVED" 0.03; echo ""
        twc "$Y" "AUTHENTICATION REQUIRED: TWO-PERSON INTEGRITY PROTOCOL" 0.02; echo ""
        sleep 0.4
        twc "$R" "ERROR: SECOND AUTHORIZATION KEY NOT DETECTED" 0.02; echo ""
        twc "$D" "LAUNCH SEQUENCE ABORTED — SINGLE-KEY OVERRIDE DENIED" 0.02; echo ""
    elif [[ "$upper" == *"DEFCON"* ]]; then
        twc "$Y" "DEFCON STATUS CHANGE REQUIRES JOINT CHIEFS AUTHORIZATION" 0.02; echo ""
        twc "$D" "CURRENT: DEFCON 3 — INCREASE IN FORCE READINESS" 0.02; echo ""
    elif [[ "$upper" == *"STATUS"* ]]; then
        twc "$G" "ALL SYSTEMS NOMINAL" 0.02; echo ""
        twc "$D" "12 PLATFORMS ONLINE // 3 ARMED // MESH INTEGRITY 100%" 0.02; echo ""
    else
        twc "$G" "PROCESSING: \"$upper\"" 0.02; echo ""
        sleep 0.3
        twc "$Y" "COMMAND NOT RECOGNIZED IN CURRENT AUTHORIZATION CONTEXT" 0.02; echo ""
        twc "$D" "CONTACT JSOC SYSTEMS ADMINISTRATOR — REF: CAIS-ERR-4017" 0.02; echo ""
    fi
fi

echo ""
printf '%b[SESSION TERMINATED — AUDIT LOG ENTRY CREATED]%b\n' "$D" "$RST"
