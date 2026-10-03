# U-Boot boot script for the TRX-duo (compiled to boot.scr by post-image.sh).
#
# Boots the mainline kernel from the SD card FAT partition. The PL is NO LONGER
# programmed here: led_blinker (and future SDR bitstreams) are loaded from Linux
# via the mainline FPGA manager + a device-tree overlay (see the dtbocfg module
# and /lib/firmware/led_blinker.{bit.bin,dtbo} on the rootfs).

setenv kernel_image zImage
setenv devicetree_image system.dtb
setenv bootargs console=ttyPS0,115200 root=/dev/mmcblk0p2 rw rootwait earlyprintk

# Persistent MAC address. The TRX-duo/Red Pitaya stores a U-Boot environment in
# the on-board 24c64 EEPROM (i2c0 @ 0x50): 4-byte CRC at 0x1800, then NUL-
# separated key=value data from 0x1804. Read a small chunk of that data (< 255
# bytes, which the Cadence i2c controller can do in one segment - a full-env read
# times out) and import ONLY ethaddr from it with `env import -b` (raw NUL-
# separated, no CRC). Requires CONFIG_ENV_OVERWRITE (uboot.fragment) so this can
# replace the random ethaddr U-Boot assigns during net-init. U-Boot then fixes up
# the kernel DT, so Linux gets a stable MAC.
# If the read/import fails, fall back to a locally-administered placeholder
# (02:00:00:00:00:01) - not tied to any board, and makes a failed read obvious
# (you'll see that MAC on eth0).
i2c dev 0
if i2c read 0x50 0x1804.2 0xc0 0x3000000 && env import -b 0x3000000 0xc0 ethaddr; then echo "ethaddr from EEPROM: ${ethaddr}"; else setenv ethaddr 02:00:00:00:00:01; echo "ethaddr fallback (EEPROM read failed): ${ethaddr}"; fi

# Boot the kernel + device tree.
load mmc 0 0x2080000 ${kernel_image} && load mmc 0 0x2000000 ${devicetree_image} && bootz 0x2080000 - 0x2000000
