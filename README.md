# TRX-duo Buildroot external tree

A [Buildroot](https://buildroot.org) *external tree* (`BR2_EXTERNAL`) for the
**TRX-duo**, a Xilinx **Zynq-7010** based SDR board (Red Pitaya / STEMlab
125-14 compatible).

It builds a bootable SD-card image using **mainline** components only — the
Xilinx forks of Linux and U-Boot are deliberately *not* used:

| Component | Version | Config |
|-----------|---------|--------|
| Buildroot | 2026.08 | `configs/trx-duo_defconfig` |
| Linux kernel | mainline 7.2.8 | `multi_v7_defconfig` + `board/trx-duo/linux-7.2.8_fragment` |
| U-Boot | mainline v2026.07 | `xilinx_zynq_virt_defconfig` (SPL first stage, no Xilinx FSBL) |

> `multi_v7_defconfig` (kernel) covers Zynq-7000 in mainline (ARCH_ZYNQ, MACB/GEM
> ethernet, Xilinx PS UART, Arasan SDHCI); the TRX-duo extras (Intel XWAY PHY,
> SPIDEV, AD5624R, FPGA manager) come from the fragment. `xilinx_zynq_virt` is an
> in-tree **mainline** U-Boot defconfig, not the Xilinx vendor tree. Mainline has
> no `xilinx_zynq` *kernel* defconfig — that exists only in the Xilinx fork.

Initial goal: boot Linux on the TRX-duo and run Pavel Demin's `led_blinker`
example. U-Boot boots the mainline kernel (it does **not** program the PL); once
Linux is up you load the bitstream **from Linux** with:

```sh
start-project led_blinker     # stop-project to unload
```

`start-project` applies a device-tree overlay to the mainline `fpga-region` (via
the `dtbocfg` configfs interface), so the Zynq FPGA manager programs the PL from
`/lib/firmware/led_blinker.bit.bin`. led_blinker is pure-PL, so once programmed the
user LED blinks with no userspace program.

## Prebuilt image

If you just want to try it, download the ready-made `sdcard.img` from the
[latest release](https://github.com/fventuri/trx-duo-buildroot/releases/latest),
verify it against `SHA256SUMS.txt`, and skip to the *Flashing* step below.

## Building

Buildroot itself lives *outside* this tree. Clone this repository, then point an
unpacked Buildroot 2026.08 at it with `BR2_EXTERNAL`:

```sh
git clone https://github.com/fventuri/trx-duo-buildroot.git

cd buildroot-2026.08
make BR2_EXTERNAL=../trx-duo-buildroot trx-duo_defconfig
make
```

The result is `output/images/sdcard.img`.

## Flashing

Write the image to a micro-SD card:

```sh
sudo dd if=output/images/sdcard.img of=/dev/sdX bs=4M conv=fsync status=progress
```

Boot the TRX-duo from that card with a serial console on `ttyPS0` @ 115200 8N1.

## Layout

```
external.desc / external.mk / Config.in   BR2_EXTERNAL glue
configs/trx-duo_defconfig                 the board defconfig
board/trx-duo/
  linux-7.2.8_fragment                    kernel config fragment
  uboot.fragment                          U-Boot config fragment
  boot.cmd  -> boot.scr                   U-Boot boot script (compiled by post-image.sh)
  uEnv.txt                                manual-boot fallback env
  genimage-template.cfg                   SD-card image layout
  post-build.sh / post-image.sh           image hooks
  overlay/                                 rootfs overlay
  patches/linux/7.2.8/                     DTS, XWAY PHY, macb jumbo + zcudp
  patches/uboot/2026.07/                   TRX-duo DTS
package/fpgautil/                          FPGA bitstream loader (placeholder)
```

## Documentation

Full documentation — the mainline-only toolchain rationale, the boot chain, and the
led_blinker demo — is published at
<https://fventuri.github.io/trx-duo-buildroot/>.

## License

[MIT](LICENSE) © Franco Venturi.

The TRX-duo / Red Pitaya board support and the `led_blinker` example derive from
[Pavel Demin's red-pitaya-notes](https://github.com/pavel-demin/red-pitaya-notes)
(MIT).
