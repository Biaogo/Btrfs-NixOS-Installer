#!/usr/bin/env bash
# Regression tests for GitHub issues #4 and #5.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck disable=SC1091
source "$ROOT/btrfs-nixos-installer"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

pass() {
    echo "PASS: $*"
}

require_parse() {
    nix-instantiate --parse "$1" >/dev/null
}

# --- issue #5: a no-desktop install must boot to a TTY ---

validate_desktop none || fail "validate_desktop rejects none"
desktop_choices | grep -qx none || fail "desktop_choices does not list none"

cfg=$(mktemp)
generate_configuration_nix "$cfg" zh_CN Asia/Shanghai us Nix nixos hash nixos none "" true 25.05 "" "" "" ""
if grep -q 'services\.xserver' "$cfg"; then
    fail "none desktop still enables xserver"
fi
if grep -q 'displayManager' "$cfg"; then
    fail "none desktop still enables a display manager"
fi
if grep -q 'desktopManager' "$cfg"; then
    fail "none desktop still enables a desktop manager"
fi
grep -q 'console.keyMap = "us";' "$cfg" || fail "none desktop does not honor the keyboard on the TTY"
grep -q '"video"' "$cfg" || fail "none desktop user cannot open DRM later"
grep -q '"input"' "$cfg" || fail "none desktop user is missing the input group"
require_parse "$cfg"
pass "issue #5 none desktop"

generate_configuration_nix "$cfg" zh_CN Asia/Shanghai us Nix nixos hash nixos plasma6 sddm true 25.05 "" "" "" ""
grep -q 'desktopManager.plasma6.enable = true;' "$cfg" || fail "plasma6 desktop not enabled"
grep -q 'displayManager.sddm.enable = true;' "$cfg" || fail "sddm not enabled for plasma6"
if grep -q 'console.keyMap' "$cfg"; then
    fail "plasma6 should keep the xkb layout, not console.keyMap"
fi
require_parse "$cfg"
pass "plasma6 unchanged"

# --- issue #4: stage-1 must see the disk that actually holds the root UUID ---

sys=$(mktemp -d)
mkdir -p "$sys/bus/pci/devices/0000:00:1f.2/driver" "$sys/module/megaraid_sas" \
    "$sys/bus/usb/devices" "$sys/class/block" "$sys/class/mmc_host"
printf '0x010400\n' > "$sys/bus/pci/devices/0000:00:1f.2/class"
printf '0x1000\n' > "$sys/bus/pci/devices/0000:00:1f.2/vendor"
printf '0x005d\n' > "$sys/bus/pci/devices/0000:00:1f.2/device"
ln -s ../../../../../module/megaraid_sas "$sys/bus/pci/devices/0000:00:1f.2/driver/module"

mods=$(SYSFS_ROOT="$sys" detect_initrd_modules)
echo "$mods" | grep -qw megaraid_sas || fail "did not detect the bound storage driver: $mods"
echo "$mods" | grep -qw vmd && fail "vmd was forced even though it is not the bound driver: $mods"
pass "detect bound storage driver"

hw=$(mktemp)
SYSFS_ROOT="$sys" generate_hardware_configuration "$hw" \
    b1e432dd-a2da-4da8-81bf-dfc817175fe8 AAAA-BBBB ssd no "" no
grep -q megaraid_sas "$hw" || fail "hardware config dropped the detected storage driver"
grep -q '"vmd"' "$hw" && fail "hardware config still forces vmd"
grep -q 'b1e432dd-a2da-4da8-81bf-dfc817175fe8' "$hw" || fail "root uuid missing"
require_parse "$hw"
pass "issue #4 detected module is in the initrd list"

# Live ISO may not have the driver symlink yet. Common controllers must still
# be available or stage-1 waits forever for a UUID that blkid can already see.
empty=$(mktemp -d)
mkdir -p "$empty/bus/pci/devices" "$empty/bus/usb/devices" "$empty/class/block" "$empty/class/mmc_host"
SYSFS_ROOT="$empty" generate_hardware_configuration "$hw" \
    b1e432dd-a2da-4da8-81bf-dfc817175fe8 AAAA-BBBB ssd no "" no
grep -q '"ahci"' "$hw" || fail "initrd fallback missing ahci (SATA root never appears)"
grep -q '"nvme"' "$hw" || fail "initrd fallback missing nvme"
grep -q '"uas"' "$hw" || fail "initrd fallback missing uas"
grep -q '"vmd"' "$hw" && fail "fallback must not force vmd"
require_parse "$hw"
pass "issue #4 common storage modules are available"

# Encrypted installs put the btrfs UUID on an LVM LV. Without LVM in the
# initrd the UUID the user checked with blkid never shows up at stage-1.
SYSFS_ROOT="$empty" generate_hardware_configuration "$hw" \
    b1e432dd-a2da-4da8-81bf-dfc817175fe8 AAAA-BBBB ssd no \
    11111111-2222-3333-4444-555555555555 yes
grep -q 'boot.initrd.services.lvm.enable = true;' "$hw" || fail "encrypted install does not activate LVM in stage-1"
grep -q '11111111-2222-3333-4444-555555555555' "$hw" || fail "luks uuid missing"
grep -q 'b1e432dd-a2da-4da8-81bf-dfc817175fe8' "$hw" || fail "inner btrfs uuid missing"
require_parse "$hw"
pass "issue #4 luks activates LVM before looking for the btrfs UUID"

SYSFS_ROOT="$empty" generate_hardware_configuration "$hw" \
    b1e432dd-a2da-4da8-81bf-dfc817175fe8 AAAA-BBBB ssd no "" no
if grep -q 'lvm.enable' "$hw"; then
    fail "unencrypted install must not enable LVM"
fi
require_parse "$hw"
pass "unencrypted hardware config has no LVM"

rm -f "$cfg" "$hw"
rm -rf "$sys" "$empty"
echo "ALL PASS"
