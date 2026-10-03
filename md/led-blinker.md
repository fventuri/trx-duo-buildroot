# The led_blinker demo

The image runs Pavel Demin's `led_blinker` example. It is a **pure-PL** design: the
blink logic lives entirely in the FPGA fabric, so once the bitstream is loaded the
user LED blinks with no userspace program and nothing to keep running.

On this image the PL is **not** programmed by U-Boot. U-Boot only boots Linux; the
bitstream is loaded **from Linux**, on demand, with `start-project`.

## Boot, then load the demo

![Boot and load](/img/boot-chain.png)

**Boot (automatic):**

1. **BootROM → U-Boot SPL.** The Zynq BootROM loads U-Boot's own SPL from the FAT
   partition. There is no Xilinx FSBL — the mainline U-Boot SPL is the first stage.
2. **SPL → U-Boot.** The SPL brings up DRAM and loads full U-Boot, which reads the
   stored MAC address from the board EEPROM and boots the kernel.
3. **U-Boot → Linux.** The mainline kernel and device tree come up. The PL is still
   empty at this point.

**Load the demo (from a shell):**

4. **`start-project led_blinker`.** This applies a device-tree overlay to the mainline
   `fpga-region` through the `dtbocfg` configfs interface.
5. **FPGA manager programs the PL.** The in-kernel Zynq FPGA manager, driven by the
   fpga-region, loads `/lib/firmware/led_blinker.bit.bin` into the fabric.
6. **The LED blinks.** led_blinker is pure PL, so it blinks on its own; `stop-project`
   removes the overlay and unloads it.

```sh
start-project led_blinker      # program the PL and start the demo
stop-project                   # unload it
```

## How a "project" is laid out

`start-project <name>` loads a project from `/usr/share/trx-duo/projects/<name>/`. A
project provides a device-tree overlay (and, for designs that need one, a userspace
app — led_blinker has none, being pure PL):

```
/lib/firmware/led_blinker.bit.bin                       the bitstream, byte-swapped
    to the .bin the mainline Zynq FPGA driver loads (converted from the .bit by
    bit2bin.py at build time)
/usr/share/trx-duo/projects/led_blinker/led_blinker.dtbo
    the overlay that points fpga-region at that firmware
```

The device-tree overlay interface (`/sys/kernel/config/device-tree/overlays/`) that
mainline dropped is restored by the `dtbocfg` kernel module; `configfs` is mounted at
boot.

## Where things live in the repo

```
board/trx-duo/
  led_blinker.bit            the PL bitstream source (converted to .bit.bin at build)
  led_blinker-overlay.dts    the fpga-region overlay (compiled to .dtbo)
  bit2bin.py                 .bit -> .bin converter (run by post-build.sh)
  boot.cmd  -> boot.scr      the U-Boot boot script (boots Linux; does NOT load the PL)
  post-build.sh              builds the project layout into the rootfs
  post-image.sh              compiles boot.scr and assembles the SD-card image
  overlay/                   files merged into the root filesystem (start-project, …)
package/fpgautil/            a helper for loading bitstreams from Linux
```
