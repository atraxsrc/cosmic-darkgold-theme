#!/bin/bash
set -eo pipefail

# ─────────────────────────────────────────────
#  Harbor Dark
#  bg:      #1B1B1B   fg:      #efebdc
#  accent:  #e75a50   brass:   #a99b7a
#  gold:    #C0AF7F   salmon:  #e58980
#  slate:   #77838a   error:   #F44336
#  dim:     #6d6d6d   cream:   #E1CE98
# ─────────────────────────────────────────────

CORAL=$'\033[38;2;231;90;80m'     # #e75a50  - section headers, logo rule
BRASS=$'\033[38;2;169;155;122m'   # #a99b7a  - info / commands, logo rule
CREAM=$'\033[38;2;225;206;152m'   # #E1CE98  - success
GOLD=$'\033[38;2;192;175;127m'    # #C0AF7F  - warnings
OLIVE=$'\033[38;2;129;127;104m'   # #817f68  - skipped
RED=$'\033[38;2;244;67;54m'       # #F44336  - errors
DIM=$'\033[38;2;109;109;109m'     # #6d6d6d  - comments / dim text
BOLD=$'\033[1m'
RESET=$'\033[0m'

# ── Helpers ────────────────────────────────────────────────────────────────────

print_header() {
    echo
    echo -e "${CORAL}${BOLD}┌─ $1 ${DIM}──────────────────────────────────────${RESET}"
}

print_success() { echo -e "  ${CREAM}✓ $1${RESET}"; }
print_info()    { echo -e "  ${BRASS}→ $1${RESET}"; }
print_warn()    { echo -e "  ${GOLD}⚠ $1${RESET}"; }
print_skip()    { echo -e "  ${OLIVE}⊘ $1${RESET}"; }
print_error()   { echo -e "  ${RED}✗ $1${RESET}"; }
print_dim()     { echo -e "  ${DIM}$1${RESET}"; }

command_exists() { command -v "$1" >/dev/null 2>&1; }

# ── Config ─────────────────────────────────────────────────────────────────────

INCLUDE_PHASED=true

PHASED_OPT=()
if [ "$INCLUDE_PHASED" = true ]; then
    PHASED_OPT=(-o APT::Get::Always-Include-Phased-Updates=true)
fi

# ── Update functions ───────────────────────────────────────────────────────────

# Packages whose removal can leave an encrypted Pop!_OS install unbootable
# (no LUKS prompt, no initramfs, no bootloader). If an upgrade wants to remove
# any of these, the system upgrade is aborted instead of auto-confirmed.
CRITICAL_PKGS='^(systemd|systemd-cryptsetup|systemd-boot|systemd-boot-efi|cryptsetup|cryptsetup-bin|libcryptsetup12|dracut|dracut-core|lvm2|kernelstub|linux-generic|linux-image-generic)(:amd64)?$'

# Simulate the upgrade and look at what it would remove.
#   0 = nothing removed      -> safe to run with -y
#   1 = removals, none critical -> run interactively so you can review them
#   2 = critical removal, or simulation failed -> abort
# nala and apt-get share the same package state, so apt-get's simulation is a
# close preview of what nala will do.
check_removals() {
    local sim removals pkg

    if ! sim=$(apt-get -s dist-upgrade "${PHASED_OPT[@]}" 2>&1); then
        print_error "Upgrade simulation failed:"
        while IFS= read -r pkg; do print_dim "  $pkg"; done <<< "$sim"
        return 2
    fi

    removals=$(awk '/^Remv /{print $2}' <<< "$sim")
    if [ -z "$removals" ]; then
        print_dim "No packages will be removed"
        return 0
    fi

    print_warn "This upgrade wants to remove:"
    while IFS= read -r pkg; do print_dim "  $pkg"; done <<< "$removals"

    if grep -qE "$CRITICAL_PKGS" <<< "$removals"; then
        print_error "A boot-critical package would be removed - not upgrading"
        print_dim "Investigate with: apt-get -s dist-upgrade | grep ^Remv"
        return 2
    fi
    return 1
}

update_system() {
    print_header "System Packages"

    if [ "$INCLUDE_PHASED" = true ]; then
        print_dim "Including phased updates (early-adopter mode)"
    fi

    # This function is called as `update_system || ...`, which switches off
    # `set -e` inside it - so every step checks its own exit status.
    local pm rc=0
    local yes_opt=(-y)

    if command_exists nala; then
        pm=nala
    elif command_exists apt-get; then
        pm=apt-get
    else
        print_error "No supported package manager found - skipping"
        return 1
    fi
    print_info "Package manager: $pm"

    sudo "$pm" update || { print_error "$pm update failed"; return 1; }

    check_removals || rc=$?
    case $rc in
        0) ;;
        1) print_warn "Removals found - confirm the upgrade yourself"
           yes_opt=() ;;
        *) return 1 ;;
    esac

    if [ "$pm" = nala ]; then
        # The package lists were just refreshed above, so skip nala's own
        # refresh when this nala version supports --no-update.
        local nala_opt=()
        if nala upgrade --help 2>/dev/null | grep -q -- '--no-update'; then
            nala_opt=(--no-update)
        fi
        sudo nala upgrade --full "${nala_opt[@]}" "${yes_opt[@]}" "${PHASED_OPT[@]}" \
            || { print_error "nala upgrade failed"; return 1; }
#        sudo nala autoremove -y
        sudo nala clean || print_warn "nala clean failed"
    else
        sudo apt-get dist-upgrade "${yes_opt[@]}" "${PHASED_OPT[@]}" \
            || { print_error "apt-get dist-upgrade failed"; return 1; }
#        sudo apt-get autoremove -y
        sudo apt-get autoclean || print_warn "apt-get autoclean failed"
    fi

    print_success "System update complete"
}

# After any upgrade, confirm the files systemd-boot will actually load can
# still boot this machine: both initramfs images on the ESP must contain
# systemd-cryptsetup (or there's no LUKS prompt), and both kernels on the ESP
# must have their modules installed (or nothing loads after root is mounted).
# Checks that don't apply to this machine (no kernelstub, no LUKS, no dracut)
# are skipped instead of reported as failures.
verify_boot() {
    print_header "Boot Check"

    if ! command_exists kernelstub; then
        print_skip "kernelstub not installed (not a Pop!_OS boot layout) - skipping"
        return 0
    fi

    local root_uuid esp img count kern ver ok=true check_initrd=true

    root_uuid=$(findmnt -no UUID /) || root_uuid=""
    esp="/boot/efi/EFI/Pop_OS-${root_uuid}"

    if [ -z "$root_uuid" ] || ! sudo test -d "$esp"; then
        print_error "Kernelstub folder not found on the ESP: $esp"
        print_dim "Is /boot/efi mounted? Check with: findmnt /boot/efi"
        return 1
    fi

    # Only an encrypted install needs systemd-cryptsetup in the initramfs, and
    # only dracut images can be listed with lsinitrd.
    if ! sudo grep -qvE '^[[:space:]]*(#|$)' /etc/crypttab 2>/dev/null; then
        print_skip "No LUKS volumes in /etc/crypttab - skipping initramfs check"
        check_initrd=false
    elif ! command_exists lsinitrd; then
        print_skip "lsinitrd not found (initramfs not built by dracut) - skipping initramfs check"
        check_initrd=false
    fi

    if [ "$check_initrd" = true ]; then
        for img in initrd.img initrd.img-previous; do
            if ! sudo test -f "$esp/$img"; then
                print_skip "$img not present"
                continue
            fi
            count=$(sudo lsinitrd "$esp/$img" 2>/dev/null | grep -c systemd-cryptsetup || true)
            if [ "${count:-0}" -gt 0 ]; then
                print_success "$img can unlock LUKS"
            else
                print_error "$img has no systemd-cryptsetup"
                ok=false
            fi
        done
    fi

    if ! command_exists file; then
        print_skip "file not installed - skipping kernel module check"
    else
        for kern in vmlinuz.efi vmlinuz-previous.efi; do
            if ! sudo test -f "$esp/$kern"; then
                print_skip "$kern not present"
                continue
            fi
            ver=$(sudo file -b "$esp/$kern" | sed -n 's/.*version \([^ ,]*\).*/\1/p')
            if [ -n "$ver" ] && [ -d "/lib/modules/$ver" ]; then
                print_success "$kern → $ver (modules installed)"
            else
                print_error "$kern → ${ver:-unknown version}: no matching /lib/modules"
                ok=false
            fi
        done
    fi

    [ "$ok" = true ]
}

update_flatpak() {
    print_header "Flatpak"
    if ! command_exists flatpak; then
        print_skip "Flatpak not installed - skipping"
        return 0
    fi

    print_info "Running flatpak update..."
    if flatpak update -y; then
        print_success "Flatpak updates applied"
    else
        print_warn "Flatpak finished with some warnings"
    fi
}

update_snap() {
    print_header "Snap"

    if ! command_exists snap; then
        print_skip "Snap not installed - skipping"
        return 0
    fi

    print_info "Running snap refresh..."
    local output
    output=$(sudo snap refresh 2>&1) || true
    while IFS= read -r line; do
        echo -e "  ${DIM}${line}${RESET}"
    done <<< "$output"

    if echo "$output" | grep -q "All snaps up to date"; then
        print_success "All snaps are already up to date"
    else
        print_success "Snap updates applied"
    fi
}

# ── Logo ───────────────────────────────────────────────────────────────────────

LOGO_ROWS=(
    ' ██████╗ ██╗  ██╗██████╗ ███████╗██╗   ██╗ ██╗'
    '██╔═████╗╚██╗██╔╝██╔══██╗██╔════╝██║   ██║███║'
    '██║██╔██║ ╚███╔╝ ██║  ██║█████╗  ██║   ██║╚██║'
    '████╔╝██║ ██╔██╗ ██║  ██║██╔══╝  ╚██╗ ██╔╝ ██║'
    '╚██████╔╝██╔╝ ██╗██████╔╝███████╗ ╚████╔╝  ██║'
    ' ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝  ╚═══╝   ╚═╝'
)

# olive #817f68 → cream #E1CE98
LOGO_GRAD=(
    "129;127;104" "131;129;105" "133;131;106" "135;132;107" "138;134;108" "140;136;109"
    "142;138;110" "144;139;111" "146;141;113" "148;143;114" "150;145;115" "152;146;116"
    "155;148;117" "157;150;118" "159;152;119" "161;153;120" "163;155;121" "165;157;122"
    "167;159;123" "170;160;124" "172;162;125" "174;164;126" "176;166;127" "178;167;129"
    "180;169;130" "182;171;131" "184;173;132" "187;174;133" "189;176;134" "191;178;135"
    "193;180;136" "195;181;137" "197;183;138" "199;185;139" "202;187;140" "204;188;141"
    "206;190;142" "208;192;143" "210;194;145" "212;195;146" "214;197;147" "216;199;148"
    "219;201;149" "221;202;150" "223;204;151" "225;206;152"
)

print_logo() {
    local LC_ALL=C.UTF-8
    local row ch out i

    echo
    for row in "${LOGO_ROWS[@]}"; do
        out=""
        for (( i = 0; i < ${#row}; i++ )); do
            ch="${row:i:1}"
            if [ "$ch" = " " ]; then
                out+=" "
            else
                out+=$'\033[1;38;2;'"${LOGO_GRAD[i]}"$'m'"$ch"
            fi
        done
        printf '  %s%s\n' "$out" "$RESET"
    done

    echo
    printf "  ${CORAL}━━━━━━━━━━━━━━━━━━━━━━━${BRASS}━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
    printf "  ${DIM}  Pop!_OS · COSMIC DE · System Update${RESET}\n"
    printf "  ${DIM}  %s${RESET}\n" "$(date '+%A %d %B %Y  %H:%M:%S')"
    echo
}

# ── Main ───────────────────────────────────────────────────────────────────────

main() {
    local start_time end_time duration boot_ok=true

    print_logo

    start_time=$(date +%s)

    update_system || {
        print_error "System package update failed - continuing with remaining tasks"
    }

    # Always run, even after a failed upgrade: a half-finished upgrade is
    # exactly when the boot files are most likely to be broken.
    verify_boot || boot_ok=false

    update_flatpak
#    update_snap

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo
    echo -e "${CORAL}${BOLD}└─ All done ${DIM}──────────────────────────────────${RESET}"
    printf "   ${CREAM}✓ Completed in ${BOLD}%dm %ds${RESET}\n" \
        $((duration / 60)) $((duration % 60))
    if [ "$boot_ok" = false ]; then
        echo
        print_error "${BOLD}Boot check failed - do NOT reboot until it's fixed"
    fi
    echo
}

main
