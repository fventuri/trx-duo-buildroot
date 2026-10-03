#!/bin/sh
set -e

BOARD_PATH="$(dirname $0)"

# Compile the U-Boot boot script boot.cmd -> boot.scr
MKIMAGE="${HOST_DIR}/bin/mkimage"
"${MKIMAGE}" -C none -A arm -T script -d "${BOARD_PATH}/boot.cmd" \
    "${BINARIES_DIR}/boot.scr"

# Include the linux device tree name (from the defconfig) in the genimage config
DTB="$(sed -n 's/^BR2_LINUX_KERNEL_INTREE_DTS_NAME="xilinx\/\([\/a-z0-9_ \-]*\)"$/\1/p' ${BR2_CONFIG})"

GENIMAGE_CFG="$(mktemp --suffix genimage.cfg)"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

sed -e "s/%DTBFILE%/${DTB}/" \
    ${BOARD_PATH}/genimage-template.cfg \
    > ${GENIMAGE_CFG}

rm -rf "${GENIMAGE_TMP}"

genimage \
    --rootpath "${TARGET_DIR}" \
    --tmppath "${GENIMAGE_TMP}" \
    --inputpath "${BINARIES_DIR}" \
    --outputpath "${BINARIES_DIR}" \
    --config "${GENIMAGE_CFG}"

rm -f ${GENIMAGE_CFG}
