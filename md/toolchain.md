# Why mainline

This tree builds the whole system from **upstream** sources. No Xilinx fork of Linux
or U-Boot is involved.

| Component | Version | Config |
|-----------|---------|--------|
| Buildroot | 2026.08 | `configs/trx-duo_defconfig` |
| Linux kernel | mainline 7.2.8 | `multi_v7_defconfig` + `board/trx-duo/linux-7.2.8_fragment` |
| U-Boot | mainline v2026.07 | `xilinx_zynq_virt_defconfig` (SPL first stage, no Xilinx FSBL) |

## The rationale

`multi_v7_defconfig` already covers Zynq-7000 in mainline — `ARCH_ZYNQ`, the MACB/GEM
ethernet, the Xilinx PS UART, and the Arasan SDHCI controller are all in-tree. The
TRX-duo extras that mainline does not enable by default come from the kernel
*fragment*:

- the **Intel XWAY** ethernet PHY on this board,
- `SPIDEV` and the **AD5624R** DAC,
- the **FPGA manager** used to program the PL.

On the boot side, `xilinx_zynq_virt_defconfig` is an **in-tree mainline** U-Boot
defconfig — not the Xilinx vendor tree. U-Boot's own SPL is the first-stage loader, so
there is no Xilinx FSBL in the chain.

> Mainline has no `xilinx_zynq` *kernel* defconfig — that one exists only in the
> Xilinx fork. `multi_v7_defconfig` plus the fragment is the mainline equivalent for
> this board.

## Board-specific patches

Small, focused patches live under `board/trx-duo/patches/`:

- **`patches/linux/7.2.8/`** — the TRX-duo device tree, the Intel XWAY PHY support,
  and two generic MACB ethernet features (jumbo frames, and a zero-copy UDP TX path)
  carried in the base tree.
- **`patches/uboot/2026.07/`** — the TRX-duo device tree and `ps7_init` for U-Boot.
