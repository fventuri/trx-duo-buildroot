# Building and flashing

## Option A — the prebuilt image

Every [release](https://github.com/fventuri/trx-duo-buildroot/releases) ships a
ready-to-write `sdcard.img` together with a `SHA256SUMS.txt`. Download both, verify,
and skip to [Flashing](#flashing):

```sh
sha256sum -c SHA256SUMS.txt
```

## Option B — build it yourself

Buildroot itself lives *outside* this external tree. Clone this repository, then point
an unpacked **Buildroot 2026.08** at it with `BR2_EXTERNAL`:

```sh
git clone https://github.com/fventuri/trx-duo-buildroot.git

cd buildroot-2026.08
make BR2_EXTERNAL=../trx-duo-buildroot trx-duo_defconfig
make
```

The build produces `output/images/sdcard.img`.

## Flashing

Write the image to a micro-SD card (replace `/dev/sdX` with your card — double-check
it, `dd` is unforgiving):

```sh
sudo dd if=sdcard.img of=/dev/sdX bs=4M conv=fsync status=progress
```

## First boot

Insert the card, connect a serial console to `ttyPS0` at **115200 8N1**, and power the
board. You should see U-Boot's SPL, then U-Boot, then the kernel. Log in as `root`,
then program the FPGA and start the demo:

```sh
start-project led_blinker     # stop-project to unload
```

See [the led_blinker demo](/led-blinker/) for how the bitstream is loaded.

## Image layout

The `sdcard.img` is a two-partition card:

![SD-card layout](/img/sd-layout.png)

- a small **FAT** boot partition carrying the SPL/U-Boot, the device tree, the kernel,
  and the boot script;
- an **ext4** root filesystem built by Buildroot from the overlay in
  `board/trx-duo/overlay/`, which also holds the bitstream
  (`/lib/firmware/led_blinker.bit.bin`) and the `start-project` tooling.
