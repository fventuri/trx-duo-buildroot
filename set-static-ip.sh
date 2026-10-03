#!/bin/sh
# set-static-ip.sh — post-process a built TRX-duo SD image (or an already-written
# SD card) to use a static IPv4 address.
#
# It does NOT touch the Buildroot tree or rebuild anything: it loop-mounts the
# ext4 root filesystem (partition 2) and rewrites /etc/network/interfaces and
# /etc/resolv.conf in place. Run it AFTER the Buildroot build is fully done.
#
# Usage:
#   sudo ./set-static-ip.sh [IMAGE_OR_DEVICE]
#
#   IMAGE_OR_DEVICE  path to sdcard.img (default) or a block device such as
#                    /dev/sdX or /dev/mmcblk0 (the whole disk, not a partition).
#
# Re-running it is safe; the previous interfaces file is backed up alongside.

set -eu

# ---- desired network configuration (edit here if needed) -------------------
IFACE="eth0"
ADDRESS="192.168.255.20"
NETMASK="255.255.255.0"        # /24
NETWORK="192.168.255.0"
BROADCAST="192.168.255.255"
GATEWAY="192.168.255.1"
DNS="192.168.0.1"
# ----------------------------------------------------------------------------

IMG="${1:-output/images/sdcard.img}"

if [ "$(id -u)" -ne 0 ]; then
    echo "error: needs root to loop-mount the partition. Re-run with sudo:" >&2
    echo "  sudo $0 \"$IMG\"" >&2
    exit 1
fi

if [ ! -e "$IMG" ]; then
    echo "error: not found: $IMG" >&2
    exit 1
fi

MNT="$(mktemp -d)"
LOOP=""

cleanup() {
    sync || true
    if mountpoint -q "$MNT" 2>/dev/null; then umount "$MNT" || true; fi
    [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null || true
    rmdir "$MNT" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# Resolve the rootfs (2nd) partition, whether IMG is an image file or a device.
if [ -b "$IMG" ]; then
    if   [ -b "${IMG}p2" ]; then PART="${IMG}p2"     # mmcblk0 / nvme0n1 / loopN
    elif [ -b "${IMG}2"  ]; then PART="${IMG}2"      # sdX
    else echo "error: cannot find partition 2 of device $IMG" >&2; exit 1; fi
else
    LOOP="$(losetup -f --show -P "$IMG")"
    PART="${LOOP}p2"
    # wait for the kernel/udev to create the partition node
    i=0
    while [ ! -b "$PART" ] && [ "$i" -lt 20 ]; do
        partprobe "$LOOP" 2>/dev/null || true
        command -v udevadm >/dev/null 2>&1 && udevadm settle 2>/dev/null || true
        sleep 0.5
        i=$((i + 1))
    done
fi

if [ ! -b "$PART" ]; then
    echo "error: rootfs partition not found ($PART)" >&2
    exit 1
fi

mount "$PART" "$MNT"

ETC="$MNT/etc"
if [ ! -d "$ETC/network" ]; then
    echo "error: $PART does not look like the TRX-duo rootfs (no /etc/network)" >&2
    exit 1
fi

# ---- /etc/network/interfaces ----
if [ -f "$ETC/network/interfaces" ]; then
    cp -a "$ETC/network/interfaces" "$ETC/network/interfaces.bak.$(date +%Y%m%d%H%M%S)"
fi
cat > "$ETC/network/interfaces" <<EOF
auto lo
iface lo inet loopback

auto $IFACE
iface $IFACE inet static
	address $ADDRESS
	netmask $NETMASK
	network $NETWORK
	broadcast $BROADCAST
	gateway $GATEWAY
EOF

# ---- /etc/resolv.conf ----
# By default it's a symlink to ../run/resolv.conf (tmpfs), which stays empty on a
# static setup, so there'd be no DNS. Replace it with a real file.
rm -f "$ETC/resolv.conf"
printf 'nameserver %s\n' "$DNS" > "$ETC/resolv.conf"

sync

echo "OK: patched rootfs on $PART"
echo "--- /etc/network/interfaces ---"
sed 's/^/  /' "$ETC/network/interfaces"
echo "--- /etc/resolv.conf ---"
sed 's/^/  /' "$ETC/resolv.conf"
echo "Done. Flash the image (or eject the card) and boot the TRX-duo."
