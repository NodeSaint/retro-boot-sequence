#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
#  CAIS — Central Armament & Intelligence System
#  Boot Sequence Simulator (Terminal Edition)
# ═══════════════════════════════════════════════════════════════

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
MENU_RESULT=0

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

fload() {
    local label="$1" dur="${2:-1.0}" steps=20
    local step_delay
    step_delay=$(echo "$dur / $steps" | bc -l 2>/dev/null || echo "0.05")
    for ((i=0; i<=steps; i++)); do
        local pct=$((i * 100 / steps))
        printf '\r  %b%-32s%b [' "$C" "$label" "$RST"
        for ((j=0; j<steps; j++)); do
            if ((j<i)); then printf '%b█' "$G"
            else printf '%b░' "$D"; fi
        done
        printf '%b] %3d%%' "$G" "$pct"
        sleep "$step_delay"
    done
    printf '\n'
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

# Menu select — displays numbered options, reads choice, sets MENU_RESULT
menu_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local count=${#options[@]}

    echo ""
    printf '  %b┌─ %s %s┐%b\n' "$G" "$prompt" "$(printf '%.0s─' $(seq 1 $((48 - ${#prompt}))))" "$RST"
    for ((i=0; i<count; i++)); do
        printf '  %b│  [%d] %-42s│%b\n' "$C" "$((i+1))" "${options[$i]}" "$RST"
    done
    printf '  %b└%s┘%b\n' "$G" "$(printf '%.0s─' {1..50})" "$RST"
    echo ""

    while true; do
        printf '  %b%bSELECT [1-%d] > %b' "$G" "$BD" "$count" "$RST"
        read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= count)); then
            MENU_RESULT=$((choice - 1))
            printf '  %b%b> %s%b\n' "$G" "$BD" "${options[$MENU_RESULT]}" "$RST"
            return
        fi
        printf '  %bINVALID — ENTER 1-%d%b\n' "$R" "$count" "$RST"
    done
}

# ── Cleanup ──────────────────────────────────────────────────
cleanup() { tput cnorm 2>/dev/null; printf '%b\n' "$RST"; }
trap cleanup EXIT INT TERM

# ══════════════════════════════════════════════════════════════
#  BOOT SEQUENCE
# ══════════════════════════════════════════════════════════════

run_boot() {
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
    printf '%b  DEPARTMENT OF WAR  //  JSOC TIER-1 CLEARANCE REQUIRED%b\n' "$D" "$RST"
    local serial="CAIS-$(printf '%04X-%04X-%04X' $RANDOM $RANDOM $RANDOM)"
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

    local stages=("STAGE 0  HARDWARE ROOT OF TRUST" "STAGE 1  BOOTLOADER" "STAGE 2  KERNEL" "STAGE 3  SECOPS LAYER" "STAGE 4  CAIS CORE")
    for s in "${stages[@]}"; do
        printf '  %b■%b %-35s ' "$G" "$RST" "$s"
        sha_hash; printf '  '
        for ((k=0; k<3; k++)); do
            printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
            sha_hash; printf '  '
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

    local mesh_nodes=(
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

    local weapons=(
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

    for wpn in "${weapons[@]}"; do
        local wstatus="${wpn##* }"
        local wrest="${wpn% *}"
        if [[ "$wstatus" == "ARMED" ]]; then
            printf '  %b%-14s %-30s %-12s' "$C" $(echo "$wrest")
            printf ' %b▲ %s%b\n' "$R$BD" "$wstatus" "$RST"
            printf '%b' "$BELL"
        elif [[ "$wstatus" == "CHARGING" ]]; then
            printf '  %b%-14s %-30s %-12s' "$C" $(echo "$wrest")
            printf ' %b◆ %s%b\n' "$Y" "$wstatus" "$RST"
        elif [[ "$wstatus" == "ACTIVE" ]]; then
            printf '  %b%-14s %-30s %-12s' "$C" $(echo "$wrest")
            printf ' %b● %s%b\n' "$G" "$wstatus" "$RST"
        else
            printf '  %b%-14s %-30s %-12s' "$C" $(echo "$wrest")
            printf ' %b○ %s%b\n' "$D" "$wstatus" "$RST"
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

    local feeds=(
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

    tput cnorm 2>/dev/null
}

# ══════════════════════════════════════════════════════════════
#  INTERACTIVE COMMAND CENTER
# ══════════════════════════════════════════════════════════════

command_center() {
    echo ""
    hr '═' "$G"
    printf '%b ■ COMMAND CENTER — SELECT OPERATION%b\n' "$W$BD" "$RST"
    hr '═' "$G"

    menu_select "OPERATION SELECT" \
        "LAUNCH OPERATION" \
        "POSTPONE OPERATION" \
        "CALL FOR BACKUP" \
        "CALL PRESIDENT (DIRECT LINE)" \
        "MANUAL COMMAND INPUT"

    case $MENU_RESULT in
        0) launch_operation ;;
        1) postpone_operation ;;
        2) call_backup ;;
        3) call_president ;;
        4) manual_input ;;
    esac

    end_menu
}

# ── LAUNCH OPERATION ──────────────────────────────────────────

launch_operation() {
    printf '%b' "$BELL"
    echo ""
    twc "$R$BD" "■ LAUNCH OPERATIONS MODULE ACTIVATED" 0.02; echo ""
    twc "$Y" "TARGETING COMPUTER ONLINE — SELECT STRIKE PACKAGE:" 0.02; echo ""

    menu_select "STRIKE PACKAGE" \
        "ALPHA — SURGICAL STRIKE (TOMAHAWK CRUISE)" \
        "BRAVO — HYPERSONIC FIRST STRIKE (DARK EAGLE)" \
        "CHARLIE — ORBITAL KINETIC BOMBARDMENT (HACKSAW)" \
        "DELTA — FULL NUCLEAR RESPONSE (TRIDENT + SENTINEL)" \
        "ABORT — CANCEL LAUNCH SEQUENCE"

    echo ""
    if ((MENU_RESULT == 4)); then
        twc "$G$BD" "LAUNCH SEQUENCE ABORTED — STANDING DOWN" 0.02; echo ""
        return
    fi

    local pkg_names=("ALPHA" "BRAVO" "CHARLIE" "DELTA")
    local pkg_types=("TOMAHAWK BLOCK V" "LRHW DARK EAGLE" "HACKSAW ORBITAL" "TRIDENT II D5 + SENTINEL")
    local pkg_counts=(24 6 3 48)
    local pkg_warheads=("CONVENTIONAL 1,000LB" "HYPERSONIC BOOST-GLIDE" "TUNGSTEN KINETIC ROD" "W88 THERMONUCLEAR")

    twc "$R$BD" "STRIKE PACKAGE ${pkg_names[$MENU_RESULT]} SELECTED" 0.02; echo ""
    printf '  %bPLATFORM:  %s%b\n' "$C" "${pkg_types[$MENU_RESULT]}" "$RST"
    printf '  %bORDNANCE:  %d UNITS%b\n' "$C" "${pkg_counts[$MENU_RESULT]}" "$RST"
    printf '  %bWARHEAD:   %s%b\n' "$C" "${pkg_warheads[$MENU_RESULT]}" "$RST"
    echo ""

    fload "CALCULATING TRAJECTORY" 1.5
    fload "PROGRAMMING GUIDANCE" 1.2
    fload "ARMING WARHEADS" 1.8
    echo ""

    printf '%b' "$BELL"
    twc "$R$BD" "■ TWO-PERSON INTEGRITY PROTOCOL REQUIRED" 0.02; echo ""
    twc "$Y" "AUTHENTICATING LAUNCH OFFICER #1..." 0.02; echo ""
    fload "BIOMETRIC SCAN" 1.0
    printf '  %bOFFICER #1: AUTHENTICATED%b\n\n' "$G$BD" "$RST"
    sleep 0.4

    twc "$Y" "AUTHENTICATING LAUNCH OFFICER #2..." 0.02; echo ""
    fload "BIOMETRIC SCAN" 1.5
    printf '%b' "$BELL"
    printf '  %bOFFICER #2: ■ AUTHENTICATION FAILED%b\n' "$R$BD" "$RST"
    printf '  %bSECOND KEY NOT PRESENT IN TERMINAL PROXIMITY%b\n\n' "$R" "$RST"
    sleep 0.3
    twc "$Y" "LAUNCH DENIED — DUAL-KEY REQUIREMENT NOT MET" 0.02; echo ""
    twc "$D" "INCIDENT LOGGED — REF: CAIS-LAUNCH-$(printf '%04d' $((RANDOM % 9999)))" 0.02; echo ""
}

# ── POSTPONE OPERATION ────────────────────────────────────────

postpone_operation() {
    echo ""
    twc "$Y" "OPERATION POSTPONEMENT MODULE" 0.02; echo ""

    menu_select "POSTPONEMENT REASON" \
        "WEATHER — ADVERSE CONDITIONS AT TARGET ZONE" \
        "INTEL — AWAITING UPDATED RECONNAISSANCE" \
        "POLITICAL — DIPLOMATIC CHANNELS STILL OPEN" \
        "ASSET REPOSITION — FORCES NOT IN PLACE" \
        "STAND DOWN — THREAT LEVEL REDUCED"

    local reasons=("WEATHER/ADVERSE" "INTEL/RECON" "POLITICAL/DIPLOMATIC" "ASSET/REPOSITION" "STAND-DOWN")
    echo ""
    fload "UPDATING OPERATION STATUS" 1.2
    echo ""
    printf '  %bOPERATION STATUS: POSTPONED%b\n' "$Y$BD" "$RST"
    printf '  %bREASON CODE: %s%b\n' "$C" "${reasons[$MENU_RESULT]}" "$RST"
    printf '  %bALL ASSETS HOLDING CURRENT POSITIONS%b\n' "$D" "$RST"
    printf '  %bNEXT REVIEW: 0600Z — STRATCOM J3 BRIEFING%b\n' "$D" "$RST"
}

# ── CALL FOR BACKUP ───────────────────────────────────────────

call_backup() {
    echo ""
    twc "$Y$BD" "■ EMERGENCY SUPPORT REQUEST" 0.02; echo ""

    menu_select "SUPPORT TYPE" \
        "REQUEST QRF (QUICK REACTION FORCE)" \
        "CALL IN AIRSTRIKE (CAS)" \
        "REQUEST MEDEVAC (DUSTOFF)" \
        "DEPLOY DRONE SWARM (REAPER WING)" \
        "REQUEST NAVAL GUNFIRE SUPPORT" \
        "ACTIVATE CYBER WARFARE UNIT"

    local callsigns=("VIPER 6" "HAWKEYE 3-1" "DUSTOFF 7" "REAPER WING" "USS ZUMWALT" "CYBER CMD")
    local freqs=("327.45" "251.80" "123.025" "datalink" "naval-tac-3" "SIPR-NET")
    local idx=$MENU_RESULT

    echo ""
    fload "ESTABLISHING COMMS" 1.5
    printf '%b' "$BELL"
    echo ""
    twc "$C" "HAILING ${callsigns[$idx]} ON ${freqs[$idx]}..." 0.02; echo ""
    sleep 0.8
    twc "$G$BD" "SIGNAL ACQUIRED — TRANSMITTING REQUEST..." 0.02; echo ""
    fload "ENCRYPTING TRANSMISSION" 0.8
    sleep 0.5
    echo ""

    local r0=("QRF VIPER 6 COPIES — OSCAR MIKE IN 12 MIKES" "CHALK 2 INBOUND — 8 OPERATORS + K9 UNIT" "LZ COORDINATES LOCKED — AUTHENTICATION: TANGO-FOXTROT-7")
    local r1=("HAWKEYE 3-1 COPIES — WINCHESTER IN 8 MIKES" "ORDNANCE: 2x GBU-39 SDB + 1x AGM-114R" "TARGET COORDINATES RECEIVED — CONFIRM DANGER CLOSE")
    local r2=("DUSTOFF 7 COPIES — WHEELS UP IN 4 MIKES" "UH-60M + FLIGHT SURGEON ON BOARD" "LZ SECURITY REQUIRED — POP SMOKE ON ARRIVAL")
    local r3=("REAPER WING COPIES — 4x MQ-9B ON STATION" "SENSOR PACKAGE: EO/IR + SAR + SIGINT" "LOITER TIME: 18 HOURS — WEAPONS HOT AUTHORIZED")
    local r4=("USS ZUMWALT COPIES — READY TO FIRE" "155MM AGS — 24 ROUNDS STANDING BY" "FIRE MISSION COORDINATES LOCKED — SPLASH IN 47 SEC")
    local r5=("CYBER CMD COPIES — PAYLOAD STAGED" "TARGET NETWORK MAPPED — 47 NODES IDENTIFIED" "ZERO-DAY EXPLOIT LOADED — AWAITING EXECUTE ORDER")

    local -n responses="r${idx}"
    for line in "${responses[@]}"; do
        printf '  %b>> %s%b\n' "$G$BD" "$line" "$RST"
        sleep 0.2
    done
    echo ""
    printf '  %bSUPPORT REQUEST CONFIRMED — COMMS CHANNEL OPEN%b\n' "$G$BD" "$RST"
}

# ── CALL PRESIDENT ────────────────────────────────────────────

call_president() {
    echo ""
    printf '%b' "$BELL"
    twc "$R$BD" "■ INITIATING PRESIDENTIAL DIRECT LINE" 0.02; echo ""
    twc "$Y" "YANKEE WHITE CLEARANCE VERIFIED" 0.02; echo ""
    echo ""

    fload "ROUTING THROUGH DISN" 1.0
    fload "ENGAGING SECURE VOICE (STE)" 0.8
    fload "AUTHENTICATING GOLD CODE" 1.5
    echo ""

    twc "$C" "CONNECTING TO NATIONAL COMMAND AUTHORITY..." 0.02; echo ""
    sleep 0.6
    printf '%b  ╔══════════════════════════════════════════════╗%b\n' "$Y" "$RST"
    printf '%b  ║  DIRECT LINE — PRESIDENT / NATIONAL COMMAND ║%b\n' "$Y" "$RST"
    printf '%b  ║  CLASSIFICATION: TOP SECRET // UMBRA        ║%b\n' "$Y" "$RST"
    printf '%b  ╚══════════════════════════════════════════════╝%b\n' "$Y" "$RST"
    echo ""
    sleep 0.5

    printf '%b' "$BELL"
    twc "$R" ">> SIGNAL INTERFERENCE DETECTED ON PRIMARY CHANNEL" 0.02; echo ""
    twc "$Y" ">> REROUTING THROUGH MILSTAR BACKUP..." 0.02; echo ""
    fload "SATELLITE HANDSHAKE" 1.2
    sleep 0.4

    printf '%b' "$BELL"
    echo ""
    twc "$R$BD" "■ CONNECTION FAILED — PRESIDENTIAL BUNKER COMMS OFFLINE" 0.02; echo ""
    twc "$Y" "FAILOVER PROTOCOL ACTIVE — ROUTING TO SECRETARY OF DEFENSE" 0.02; echo ""

    menu_select "FALLBACK ACTION" \
        "RETRY PRESIDENTIAL LINE" \
        "CONNECT TO SECDEF" \
        "ACTIVATE CONTINUITY OF GOVERNMENT" \
        "ISSUE EMERGENCY ACTION MESSAGE (EAM)"

    echo ""
    case $MENU_RESULT in
        0)
            fload "RETRYING SECURE CHANNEL" 1.5
            printf '%b' "$BELL"
            printf '  %b■ CONNECTION TIMED OUT — RETRY LIMIT REACHED%b\n' "$R$BD" "$RST"
            printf '  %bRECOMMEND: ACTIVATE CONTINUITY PROTOCOLS%b\n' "$Y" "$RST"
            ;;
        1)
            fload "CONNECTING TO PENTAGON" 1.2
            printf '  %b>> SECDEF ONLINE — VOICE AUTHENTICATED%b\n' "$G$BD" "$RST"
            printf '  %b>> BRIEFING: DEFCON 3 POSTURE // 3 HOSTILE TRACKS%b\n' "$C" "$RST"
            printf '  %b>> AWAITING NATIONAL COMMAND AUTHORITY DECISION%b\n' "$D" "$RST"
            ;;
        2)
            printf '%b' "$BELL"
            twc "$R$BD" "■ COG PROTOCOL ACTIVATED — EXECUTIVE ORDER 12656" 0.02; echo ""
            fload "ALERTING MOUNT WEATHER" 1.0
            fload "ALERTING RAVEN ROCK" 0.8
            fload "DISPERSING CONTINUITY TEAMS" 1.2
            printf '  %bALL CONTINUITY SITES: ACTIVATED%b\n' "$Y$BD" "$RST"
            printf '  %bSUCCESSOR CHAIN: INTACT — 18 DESIGNATED SURVIVORS%b\n' "$D" "$RST"
            ;;
        3)
            printf '%b' "$BELL"
            printf '%b' "$BELL"
            twc "$R$BD" "■ EAM BROADCAST INITIATED" 0.02; echo ""
            printf '  %bSKYKING, SKYKING, DO NOT ANSWER%b\n' "$R$BD" "$RST"
            printf '  %bAUTHENTICATION: FOXTROT-LIMA-7-7-ALPHA-TANGO%b\n' "$Y" "$RST"
            fload "TRANSMITTING ON ALL FREQUENCIES" 2.0
            printf '  %bEAM TRANSMITTED — ALL UNITS ACKNOWLEDGE%b\n' "$Y$BD" "$RST"
            ;;
    esac
}

# ── MANUAL INPUT ──────────────────────────────────────────────

manual_input() {
    echo ""
    twc "$Y" "MANUAL COMMAND INTERFACE — ENTER COMMAND:" 0.02; echo ""
    printf '  %b%bCAIS://> %b' "$G" "$BD" "$RST"
    read -r user_input

    if [[ -z "$user_input" ]]; then return; fi

    local upper
    upper=$(echo "$user_input" | tr '[:lower:]' '[:upper:]')
    echo ""
    twc "$C" "PROCESSING: \"$upper\"" 0.02; echo ""
    echo ""
    fload "QUERYING COMMAND DATABASE" 1.5
    fload "AUTHENTICATING REQUEST" 1.2
    echo ""

    printf '%b' "$BELL"
    sleep 0.3
    twc "$R$BD" "■ ERROR: SECURE CONNECTION LOST" 0.02; echo ""
    twc "$R" "SATELLITE UPLINK INTERRUPTED — POSSIBLE JAMMING DETECTED" 0.02; echo ""
    twc "$Y" "LAST KNOWN SIGNAL: AEHF-6 // SIGNAL DEGRADED TO 12%" 0.02; echo ""

    menu_select "EMERGENCY COMMS" \
        "CALL FOR HELICOPTER EXTRACTION" \
        "RADIO FOR BACKUP ON EMERGENCY FREQ" \
        "SWITCH TO BURST TRANSMISSION MODE" \
        "DEPLOY PORTABLE SATCOM TERMINAL"

    echo ""
    case $MENU_RESULT in
        0)
            twc "$C" "HAILING PEDRO 6-6 ON GUARD FREQUENCY 243.0 MHz..." 0.02; echo ""
            fload "TRANSMITTING COORDINATES" 1.2
            printf '  %b>> PEDRO 6-6 COPIES — HH-60W INBOUND%b\n' "$G$BD" "$RST"
            printf '  %b>> ETA 22 MINUTES — POP IR STROBE ON APPROACH%b\n' "$G$BD" "$RST"
            printf '  %b>> ESCORT: 2x AH-64E APACHE GUARDIAN%b\n' "$D" "$RST"
            ;;
        1)
            twc "$C" "BROADCASTING ON 121.5 MHz + 243.0 MHz..." 0.02; echo ""
            fload "MAYDAY BROADCAST" 1.5
            printf '  %b>> OVERWATCH COPIES YOUR MAYDAY%b\n' "$G$BD" "$RST"
            printf '  %b>> QRF SCRAMBLED FROM FOB THUNDER — ETA 15 MIKES%b\n' "$G$BD" "$RST"
            printf '  %b>> AC-130J GHOSTRIDER PROVIDING OVERWATCH%b\n' "$D" "$RST"
            ;;
        2)
            twc "$C" "SWITCHING TO BURST MODE — 3-SECOND WINDOW..." 0.02; echo ""
            fload "COMPRESSING & ENCRYPTING" 0.8
            sleep 0.3
            printf '  %b████████████████████████████ BURST SENT%b\n' "$G$BD" "$RST"
            printf '  %b>> BURST ACKNOWLEDGED BY ECHELON-VII%b\n' "$G$BD" "$RST"
            printf '  %b>> INTELLIGENCE PACKET RECEIVED — RETRANSMITTING%b\n' "$D" "$RST"
            ;;
        3)
            twc "$C" "DEPLOYING AN/PRC-170 PORTABLE TERMINAL..." 0.02; echo ""
            fload "ALIGNING TO WGS-11" 1.5
            fload "ESTABLISHING LINK" 1.0
            printf '  %b>> SATCOM LINK ESTABLISHED — BYPASS ACTIVE%b\n' "$G$BD" "$RST"
            printf '  %b>> BANDWIDTH: 2.4 Mbps // ENCRYPTION: TYPE-1%b\n' "$G$BD" "$RST"
            printf '  %b>> COMMS RESTORED — ALL CHANNELS NOMINAL%b\n' "$D" "$RST"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════
#  END MENU — CLOSE / REBOOT / SELF-DESTRUCT
# ══════════════════════════════════════════════════════════════

end_menu() {
    echo ""
    hr '─' "$D"
    echo ""
    twc "$Y" "OPERATION COMPLETE — SELECT TERMINAL ACTION:" 0.02; echo ""

    menu_select "TERMINAL ACTION" \
        "CLOSE TERMINAL (POWER OFF)" \
        "REBOOT SYSTEM" \
        "SELF-DESTRUCT (DOOMSDAY PROTOCOL)"

    echo ""
    case $MENU_RESULT in
        0) close_terminal ;;
        1) reboot_system ;;
        2) self_destruct ;;
    esac
}

close_terminal() {
    twc "$Y" "POWERING DOWN CAIS TERMINAL..." 0.02; echo ""
    fload "SECURING CLASSIFIED DATA" 1.0
    fload "WIPING SESSION MEMORY" 0.8
    echo ""
    printf '%b[SESSION TERMINATED — AUDIT LOG CREATED]%b\n\n' "$D" "$RST"
}

reboot_system() {
    twc "$Y" "INITIATING SYSTEM REBOOT..." 0.02; echo ""
    fload "FLUSHING CACHES" 0.6
    printf '%b[REBOOTING...]%b\n' "$D" "$RST"
    sleep 0.5
    exec "$0"
}

self_destruct() {
    printf '%b' "$BELL"
    printf '%b' "$BELL"
    echo ""
    printf '  %b╔══════════════════════════════════════════════════╗%b\n' "$R$BD" "$RST"
    printf '  %b║     ■ ■ ■  DOOMSDAY PROTOCOL ACTIVATED  ■ ■ ■  ║%b\n' "$R$BD" "$RST"
    printf '  %b╚══════════════════════════════════════════════════╝%b\n' "$R$BD" "$RST"
    echo ""

    twc "$R" "AUTHORIZATION: OMEGA-BLACK-7-7-7" 0.02; echo ""
    twc "$Y" "ALL TERMINAL DATA WILL BE DESTROYED" 0.02; echo ""
    echo ""

    # Countdown
    for ((i=10; i>=1; i--)); do
        local bar_fill=""
        local bar_empty=""
        for ((b=0; b<i*3; b++)); do bar_fill+="█"; done
        for ((b=0; b<(10-i)*3; b++)); do bar_empty+="░"; done

        if ((i <= 3)); then
            printf '\r  %b██ DETONATION IN: %02d %s%s%b' "$R$BD" "$i" "$bar_fill" "$bar_empty" "$RST"
            printf '%b' "$BELL"
        else
            printf '\r  %b██ DETONATION IN: %02d %b%s%b%s%b' "$R$BD" "$i" "$Y$BD" "$bar_fill" "$D" "$bar_empty" "$RST"
        fi
        sleep 0.8
    done

    echo ""
    echo ""

    # Explosion
    printf '%b' "$BELL"
    printf '%b' "$BELL"
    printf '%b' "$BELL"

    printf '%b' "$R$BD"
    cat << 'BOOM'

           ████████████████████████████████████████
        ██                                          ██
      ██     ██  ██  ██  ██  ██  ██  ██  ██  ██      ██
    ██       ██  ██  ██  ██  ██  ██  ██  ██  ██        ██
    ██     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░      ██
    ██     ░░  ████  █  █ ████  █    ████  ████  ░░    ██
    ██     ░░  █   █ █  █ █  █  █    █     █   █ ░░    ██
    ██     ░░  ████  █  █ ████  █    ████  ████  ░░    ██
    ██     ░░  █   █ █  █ █  █  █    █     █  █  ░░    ██
    ██     ░░  ████  ████ █  █  ████ ████  █   █ ░░    ██
    ██     ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░      ██
      ██       ██  ██  ██  ██  ██  ██  ██  ██  ██    ██
        ██                                          ██
           ████████████████████████████████████████

BOOM
    printf '%b\n' "$RST"

    sleep 0.5

    printf '  %b██████████████████████████████████████████████████████%b\n' "$R" "$RST"
    echo ""
    printf '  %b         ■ ■ ■  ALL DATA DESTROYED  ■ ■ ■%b\n' "$R$BD" "$RST"
    echo ""
    printf '  %b         TERMINAL COMPROMISED — NO RECOVERY%b\n' "$R" "$RST"
    printf '  %b         DOOMSDAY PROTOCOL COMPLETE%b\n' "$R" "$RST"
    echo ""
    printf '  %b██████████████████████████████████████████████████████%b\n' "$R" "$RST"
    echo ""

    sleep 1.5
    twc "$D" "FACILITY DECONTAMINATION IN PROGRESS..." 0.03; echo ""
    sleep 0.8
    twc "$D" "NSA/CSS FORENSIC TEAM NOTIFIED" 0.03; echo ""
    echo ""
    printf '%b[SESSION DESTROYED]%b\n\n' "$D" "$RST"
}

# ══════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════

run_boot
command_center
