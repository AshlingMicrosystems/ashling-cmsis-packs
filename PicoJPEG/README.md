# Ashling.PicoJPEG

Bare-metal RV32IA picojpeg JPEG-decode example, built with CMake. Distributed
as an [Open-CMSIS-Pack](https://open-cmsis-pack.github.io/Open-CMSIS-Pack-Spec/main/html/index.html)
Generic Software Pack (GSP), runnable on two boards:

- **`qemu/`** — QEMU's "virt" machine model. See [qemu/Abstract.txt](qemu/Abstract.txt).
- **`arty/`** — Digilent Arty A7-100T (SiFive E31 core). See [arty/Abstract.txt](arty/Abstract.txt).

Device and board metadata live in separate packs this one depends on:
`QEMU_RISCV_DFP`, `QEMU_RISCV_BSP`, `SiFive_E_DFP`, `ArtyA7-100T_BSP` — so
future example packs targeting either board can reuse them without
redeclaring devices/boards from scratch.

## Toolchain setup

Both variants resolve their RISC-V GCC toolchain (and, for `qemu/`, QEMU
itself) via a [vcpkg artifact registry](https://github.com/AshlingMicrosystems/ashling-vcpkg-registry)
(see each variant's own `vcpkg-configuration.json`) rather than a fixed
install path. Before building, running, or debugging, activate the toolchain
in your terminal, from within the variant's own folder:

```
cd qemu   (or: cd arty)
vcpkg activate
```

This adds `riscv64-unknown-elf-gcc`/`-gdb` (and, for `qemu/`,
`qemu-system-riscv32`) to `PATH` for **that shell and its subprocesses
only**. If you're using VS Code's integrated terminal or debugger, open a
**new** terminal (or restart VS Code) after activating — an already-open
terminal or already-running VS Code process won't see the update.

## Building

From within `qemu/` or `arty/`:

```
cmake -G "Unix Makefiles" -S . -B build ^
    -DCMAKE_C_COMPILER=riscv64-unknown-elf-gcc.exe ^
    -DCMAKE_CXX_COMPILER=riscv64-unknown-elf-g++.exe ^
    -DCMAKE_ASM_COMPILER=riscv64-unknown-elf-gcc.exe
cmake --build build
```

This produces `build/picojpeg.elf`.

## Building with cbuild (experimental)

Each variant's `build-cbuild.ps1` wraps `vcpkg activate` plus CMSIS-Toolbox's
own toolchain registration (`GCC_TOOLCHAIN_12_1_0`, `CMSIS_COMPILER_ROOT`)
and runs `cbuild picojpeg.csolution.yml --packs`. This is project-local,
first-of-its-kind wiring of a non-Arm GCC into CMSIS-Toolbox (see each
variant's `cmsis-toolchain-config\GCC.12.1.0.cmake`) — not an
upstream-supported CMSIS-Toolbox feature — so it may need troubleshooting.
The plain CMake build above remains the primary, proven path.

## Running (qemu/)

```
qemu-system-riscv32 -machine virt -nographic -bios none -kernel build/picojpeg.elf
```

## Running (arty/)

Program the resulting `build/picojpeg.elf` onto the Arty A7-100T board via
your JTAG probe / debug launch configuration — not yet included in this
pack, to be added separately.

## Installing the pack

Add this pack, and its four dependency packs, with [cpackget](https://github.com/Open-CMSIS-Pack/cpackget):

```
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/QEMU_RISCV_DFP/Ashling.QEMU_RISCV_DFP.1.0.0.pack
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/QEMU_RISCV_BSP/Ashling.QEMU_RISCV_BSP.1.0.0.pack
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/SiFive_E_DFP/Ashling.SiFive_E_DFP.1.0.0.pack
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/ArtyA7-100T_BSP/Ashling.ArtyA7-100T_BSP.1.0.0.pack
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/PicoJPEG/Ashling.PicoJPEG.1.0.0.pack
```

(`-a` auto-accepts the GPL-3.0 embedded license non-interactively; omit it to be
prompted instead.) Note `cpackget add` does **not** accept an `index.pidx` URL directly
— only a pack id, a `.pack` file/URL, or a local `.pdsc` path. For local development,
install straight from your working copy:

```
cpackget add PicoJPEG/Ashling.PicoJPEG.pdsc
```

## Note on cbuild support

`csolution.yml`/`cproject.yml` are included in both variants purely so
they're listed in the CMSIS Solution VS Code extension's "Create Solution"
picker — actually building via `cbuild` remains experimental (see above).
Open-CMSIS-Pack's device model doesn't have a real RISC-V core type, and
CMSIS-Toolbox's shipped GCC toolchain file hard-codes the `arm-none-eabi-`
prefix and an Arm-only CPU whitelist — this repo's `build-cbuild.ps1` works
around that with a project-local toolchain file, not an upstream-supported
mechanism.

## License

See [LICENSE.txt](LICENSE.txt) (GPL-3.0-or-later). Files under `src/` carry Embecosm/
University of Bristol (Embench) copyright notices under the same license.
