#!/bin/sh
# set-static-ip-rebuild.sh — set a static IPv4 address WITHOUT root and WITHOUT
# loop-mounting anything.
#
# It writes the desired /etc/network/interfaces and /etc/resolv.conf into the
# Buildroot rootfs *overlay*, then re-runs the Buildroot build. Buildroot
# regenerates rootfs.ext4 and sdcard.img with its own fakeroot-based tooling
# (correct root ownership / permissions / device nodes) — no sudo required.
#
# Because it edits the overlay (the source of truth for those two files), the
# static config becomes the build default. To go back to the previous config:
#   git -C "<this external tree>" checkout board/trx-duo/overlay
#
# Usage:
#   ./set-static-ip-rebuild.sh [buildroot dir]

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

# This external tree (directory containing this script) and the Buildroot dir.
EXT="$(cd "$(dirname "$0")" && pwd)"
BR="${1:-.}"
OVL="$EXT/board/trx-duo/overlay"

[ -d "$OVL/etc/network" ] || { echo "error: overlay not found at $OVL" >&2; exit 1; }
[ -f "$BR/.config" ]      || { echo "error: Buildroot not configured at $BR" >&2; exit 1; }

# 1) /etc/network/interfaces
cat > "$OVL/etc/network/interfaces" <<EOF
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

# 2) /etc/resolv.conf — a real file (replaces the default symlink to
#    /run/resolv.conf, which stays empty on a static setup so DNS wouldn't work).
printf 'nameserver %s\n' "$DNS" > "$OVL/etc/resolv.conf"

echo "Updated overlay:"
sed 's/^/  /' "$OVL/etc/network/interfaces"
echo "  /etc/resolv.conf: nameserver $DNS"
echo

# 3) Rebuild the images (no root; fakeroot handles ownership/permissions).
echo "Rebuilding images in $BR ..."
if ( cd "$BR" && make ) > "$BR/make-image.log" 2>&1; then
    IMG="$BR/output/images/sdcard.img"
    echo "OK: rebuilt $IMG"
    ls -la "$IMG"
    echo "Flash it with e.g.:"
    echo "  sudo dd if=$IMG of=/dev/sdX bs=4M conv=fsync status=progress"
else
    echo "error: rebuild failed; see $BR/make-image.log" >&2
    tail -n 20 "$BR/make-image.log" >&2
    exit 1
fi
