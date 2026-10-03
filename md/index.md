# TRX-duo Buildroot

A [Buildroot](https://buildroot.org) *external tree* (`BR2_EXTERNAL`) for the
**TRX-duo**, a Xilinx **Zynq-7010** based SDR board (Red Pitaya / STEMlab 125-14
compatible). It builds a bootable micro-SD image from **mainline** Linux and U-Boot
— the Xilinx vendor forks are deliberately not used — and runs Pavel Demin's
`led_blinker` example, programmed into the FPGA from Linux.

1. [Why mainline](/toolchain/) — the component matrix and the vendor-fork-free rationale
1. [Building and flashing](/build/) — build the image, or grab the prebuilt one, and write it to a card
1. [The led_blinker demo](/led-blinker/) — the boot chain and how the PL gets programmed

## Quick start

Download the ready-made `sdcard.img` from the
[latest release](/), verify it against `SHA256SUMS.txt`, and write it to a micro-SD
card:

```sh
sudo dd if=sdcard.img of=/dev/sdX bs=4M conv=fsync status=progress
```

Boot the TRX-duo from that card with a serial console on `ttyPS0` @ 115200 8N1, log
in as `root`, and start the demo:

```sh
start-project led_blinker     # stop-project to unload
```

The user LED now blinks with no userspace program running — the blink is pure PL
(FPGA). See [the led_blinker demo](/led-blinker/) for how it is programmed.

## Source

The repository is on GitHub at
[fventuri/trx-duo-buildroot](https://github.com/fventuri/trx-duo-buildroot), released
under the [MIT license](https://github.com/fventuri/trx-duo-buildroot/blob/main/LICENSE).
The board support and the `led_blinker` example derive from
[Pavel Demin's red-pitaya-notes](https://github.com/pavel-demin/red-pitaya-notes).
