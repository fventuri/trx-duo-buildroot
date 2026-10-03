#!/bin/sh
set -e

BOARD_DIR="$(dirname $0)"

cp -f ${BOARD_DIR}/uEnv.txt ${BINARIES_DIR}

# led_blinker is now programmed from Linux (not U-Boot): the mainline Zynq FPGA
# manager is driven by a device-tree overlay applied to the fpga-region. Load it
# on the running board with `start-project led_blinker` (stop-project to unload).
# Build its two artifacts into the "project" layout (see start-project):
#
#   /lib/firmware/led_blinker.bit.bin              - the .bit converted to the
#       byte-swapped .bin the mainline zynq-fpga driver requires (request_firmware
#       finds it here via the overlay's firmware-name).
#   .../projects/led_blinker/led_blinker.dtbo      - the overlay that adds
#       firmware-name to fpga_full.
mkdir -p ${TARGET_DIR}/lib/firmware
mkdir -p ${TARGET_DIR}/usr/share/trx-duo/projects/led_blinker
python3 ${BOARD_DIR}/bit2bin.py ${BOARD_DIR}/led_blinker.bit \
	${TARGET_DIR}/lib/firmware/led_blinker.bit.bin
${HOST_DIR}/bin/dtc -@ -I dts -O dtb \
	-o ${TARGET_DIR}/usr/share/trx-duo/projects/led_blinker/led_blinker.dtbo \
	${BOARD_DIR}/led_blinker-overlay.dts
