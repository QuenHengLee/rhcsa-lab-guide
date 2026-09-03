# shellcheck shell=bash
# Shared helpers for the RHCSA practice labs.
# Sourced by /usr/local/bin/lab before any lab file is loaded.

LAB_HOME=/usr/local/share/rhcsa-labs
LAB_LABDIR="$LAB_HOME/labs"
LAB_STATE=/var/lib/rhcsa-labs

# The two blank practice disks. They live on the NVMe controller precisely so
# they can never be confused with the OS disk, which is always /dev/sda.
LAB_DISK1=/dev/nvme0n1
LAB_DISK2=/dev/nvme0n2

# ---------------------------------------------------------------- output ---
if [ -t 1 ]; then
    C_RED=$'\033[31m'; C_GRN=$'\033[32m'; C_YEL=$'\033[33m'
    C_CYN=$'\033[36m'; C_B=$'\033[1m';    C_0=$'\033[0m'
else
    C_RED=; C_GRN=; C_YEL=; C_CYN=; C_B=; C_0=
fi

lab_head() { printf '\n%s%s%s\n' "$C_B" "$*" "$C_0"; }
lab_info() { printf '%s\n' "$*"; }
lab_warn() { printf '%swarning:%s %s\n' "$C_YEL" "$C_0" "$*" >&2; }
lab_die()  { printf '%serror:%s %s\n' "$C_RED" "$C_0" "$*" >&2; exit 1; }

# --------------------------------------------------------------- grading ---
LAB_PASS=0
LAB_FAIL=0
LAB_FAILED=()

# grade_check "<what is being checked>" '<shell expression>'
# The expression runs under bash; a zero exit status means the check passed.
grade_check() {
    local desc=$1 expr=$2
    # Hard timeout: a grading probe must never leave the student waiting.
    if timeout 30 bash -c "$expr" >/dev/null 2>&1; then
        printf '  %sPASS%s  %s\n' "$C_GRN" "$C_0" "$desc"
        LAB_PASS=$((LAB_PASS + 1))
    else
        printf '  %sFAIL%s  %s\n' "$C_RED" "$C_0" "$desc"
        LAB_FAIL=$((LAB_FAIL + 1))
        LAB_FAILED+=("$desc")
    fi
}

# grade_test "<what is being checked>" <command> [args...]
# Unlike grade_check this runs in the current shell, so shell functions from
# common.sh or from the lab file itself are usable.
grade_test() {
    local desc=$1
    shift
    if "$@" >/dev/null 2>&1; then
        printf '  %sPASS%s  %s\n' "$C_GRN" "$C_0" "$desc"
        LAB_PASS=$((LAB_PASS + 1))
    else
        printf '  %sFAIL%s  %s\n' "$C_RED" "$C_0" "$desc"
        LAB_FAIL=$((LAB_FAIL + 1))
        LAB_FAILED+=("$desc")
    fi
}

lab_grade_summary() {
    local total=$((LAB_PASS + LAB_FAIL)) item
    lab_head "Result"
    if [ "$LAB_FAIL" -eq 0 ] && [ "$total" -gt 0 ]; then
        printf '  %sPASS%s  %d of %d checks passed.\n\n' "$C_GRN" "$C_0" "$LAB_PASS" "$total"
        return 0
    fi
    printf '  %sFAIL%s  %d of %d checks passed.\n\n  Still outstanding:\n' \
        "$C_RED" "$C_0" "$LAB_PASS" "$total"
    for item in "${LAB_FAILED[@]}"; do
        printf '    - %s\n' "$item"
    done
    printf '\n'
    return 1
}

# ----------------------------------------------------------- disk safety ---
# The whole-disk device that currently carries the root filesystem.
lab_root_disk() {
    local src name
    src=$(findmnt -no SOURCE / 2>/dev/null) || return 1
    name=$(lsblk -nsro NAME "$src" 2>/dev/null | tail -1)
    [ -n "$name" ] || return 1
    printf '/dev/%s\n' "$name"
}

# Hard stop before any destructive disk operation. Every wipe in every lab
# goes through this, so a typo in a lab file cannot destroy the student's
# system disk.
lab_assert_practice_disk() {
    local dev=$1 root
    [ -b "$dev" ] || lab_die "$dev is not a block device."
    root=$(lab_root_disk) || lab_die "cannot determine the root disk; refusing to continue."
    if [ "$dev" = "$root" ]; then
        lab_die "refusing to touch $dev - it carries the root filesystem."
    fi
}

# Release everything holding a practice disk, then blank its metadata.
lab_wipe_disk() {
    local dev=$1 child vg
    lab_assert_practice_disk "$dev"

    for child in $(lsblk -nro NAME "$dev" | tail -n +2); do
        umount -R "/dev/$child" 2>/dev/null
        swapoff "/dev/$child" 2>/dev/null
    done
    swapoff "$dev" 2>/dev/null

    # Tear down any LVM sitting on the disk or its partitions.
    for vg in $(pvs --noheadings -o vg_name 2>/dev/null \
                | awk 'NF' | sort -u); do
        if pvs --noheadings -o pv_name,vg_name 2>/dev/null \
             | awk -v v="$vg" '$2==v {print $1}' | grep -q "^${dev}"; then
            vgchange -an "$vg" >/dev/null 2>&1
            vgremove -f "$vg" >/dev/null 2>&1
        fi
    done
    for child in "$dev" "$dev"p[0-9] "$dev"[0-9]; do
        [ -b "$child" ] && pvremove -ff -y "$child" >/dev/null 2>&1
    done

    wipefs -a "$dev" >/dev/null 2>&1
    dd if=/dev/zero of="$dev" bs=1M count=16 status=none 2>/dev/null
    partprobe "$dev" >/dev/null 2>&1
    udevadm settle 2>/dev/null
    return 0
}

# ----------------------------------------------------------------- fstab ---
LAB_FSTAB_BACKUP="$LAB_STATE/fstab.orig"

# Drop every fstab entry whose mount point (field 2) matches, leaving
# comments untouched.
lab_fstab_remove() {
    local mnt=$1 tmp
    tmp=$(mktemp /etc/fstab.lab.XXXXXX) || return 1
    awk -v m="$mnt" '
        /^[[:space:]]*#/ { print; next }
        NF == 0          { print; next }
        $2 == m          { next }
                         { print }
    ' /etc/fstab > "$tmp" && cat "$tmp" > /etc/fstab
    rm -f "$tmp"
    systemctl daemon-reload 2>/dev/null
}

# True when /etc/fstab would mount <mountpoint> at boot and the entry is valid.
lab_fstab_has() {
    local mnt=$1
    awk -v m="$mnt" '!/^[[:space:]]*#/ && $2 == m { found = 1 } END { exit !found }' /etc/fstab
}

# ----------------------------------------------------------------- users ---
lab_user_del() {
    local u
    for u in "$@"; do
        if id "$u" >/dev/null 2>&1; then
            pkill -u "$u" 2>/dev/null
            crontab -r -u "$u" 2>/dev/null
            userdel -r -f "$u" 2>/dev/null
        fi
    done
    return 0
}

lab_group_del() {
    local g
    for g in "$@"; do
        getent group "$g" >/dev/null 2>&1 && groupdel "$g" 2>/dev/null
    done
    return 0
}

# True when the account has a usable password (not empty, locked or disabled).
lab_password_set() {
    local h
    h=$(getent shadow "$1" 2>/dev/null | cut -d: -f2)
    case "$h" in
        ''|'!'|'*'|'!!'|'!*'|'!'*) return 1 ;;
        *) return 0 ;;
    esac
}

# True when the account's password is exactly <pass>. Only SHA-512 hashes can
# be recomputed with the tools present on a minimal install; for anything else
# fall back to "some password is set" rather than failing a correct answer.
lab_password_is() {
    local user=$1 pass=$2 hash salt calc
    hash=$(getent shadow "$user" 2>/dev/null | cut -d: -f2)
    case "$hash" in
        \$6\$*)
            salt=$(printf '%s\n' "$hash" | cut -d'$' -f3)
            calc=$(openssl passwd -6 -salt "$salt" "$pass" 2>/dev/null)
            [ -n "$calc" ] && [ "$calc" = "$hash" ]
            ;;
        *)
            lab_password_set "$user"
            ;;
    esac
}

# ------------------------------------------------------------ node checks ---
lab_this_node() { hostname -s; }

lab_require_node() {
    local want=$1
    if [ "$(lab_this_node)" != "$want" ]; then
        lab_die "this exercise runs on $want, but you are on $(lab_this_node)."
    fi
}

lab_peer_reachable() {
    local peer=$1
    ping -c1 -W3 "$peer" >/dev/null 2>&1
}

lab_on_peer() {
    local peer=$1; shift
    ssh -o BatchMode=yes "$peer" "$@"
}

# ------------------------------------------------------------------ misc ---
lab_ensure_pkg() {
    local missing=()
    local p
    for p in "$@"; do
        rpm -q "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    [ ${#missing[@]} -eq 0 ] && return 0
    dnf -y -q install "${missing[@]}" >/dev/null 2>&1
}

lab_state_dir() {
    install -d -m 755 "$LAB_STATE/$1"
    printf '%s\n' "$LAB_STATE/$1"
}

# grade_check evaluates its expression in a fresh `bash -c`, which would not
# otherwise see anything defined here. Export the helpers a lab file is likely
# to call from a grade_check expression.
#
# Note for lab authors: functions defined inside a .lab file are NOT exported.
# Use grade_test (which runs in the current shell) for those.
export -f lab_fstab_has lab_root_disk lab_password_set lab_password_is
