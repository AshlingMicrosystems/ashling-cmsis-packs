# Ashling.QEMU32_RISCV_PicoJPEG

Bare-metal RV32IA picojpeg JPEG-decode example, built with CMake and run/debugged
under QEMU's "virt" machine model. Distributed as an [Open-CMSIS-Pack](https://open-cmsis-pack.github.io/Open-CMSIS-Pack-Spec/main/html/index.html).

See [Abstract.txt](Abstract.txt) for the full technical description.

## Toolchain setup

This project's RISC-V GCC toolchain and QEMU are resolved via a
[vcpkg artifact registry](https://github.com/AshlingMicrosystems/ashling-vcpkg-registry)
(see `vcpkg-configuration.json`) rather than a fixed install path. Before building,
running, or debugging, activate the toolchain in your terminal:

```
vcpkg activate
```

This adds `riscv64-unknown-elf-gcc`/`-gdb` and `qemu-system-riscv32` to `PATH` for
**that shell and its subprocesses only**. If you're using VS Code's integrated
terminal or debugger, open a **new** terminal (or restart VS Code) after activating
— an already-open terminal or already-running VS Code process won't see the update.

## Building

```
cmake -G "Unix Makefiles" -S . -B build ^
    -DCMAKE_C_COMPILER=riscv64-unknown-elf-gcc.exe ^
    -DCMAKE_CXX_COMPILER=riscv64-unknown-elf-g++.exe ^
    -DCMAKE_ASM_COMPILER=riscv64-unknown-elf-gcc.exe
cmake --build build
```

This produces `build/picojpeg.elf`.

## Building with cbuild (experimental)

`build-cbuild.ps1` wraps `vcpkg activate` plus CMSIS-Toolbox's own toolchain
registration (`GCC_TOOLCHAIN_12_1_0`, `CMSIS_COMPILER_ROOT`) and runs
`cbuild picojpeg.csolution.yml --packs`. This is project-local, first-of-its-kind
wiring of a non-Arm GCC into CMSIS-Toolbox (see `cmsis-toolchain-config\GCC.12.1.0.cmake`)
— not an upstream-supported CMSIS-Toolbox feature — so it may need troubleshooting.
The plain CMake build above remains the primary, proven path.

## Running

```
qemu-system-riscv32 -machine virt -nographic -bios none -kernel build/picojpeg.elf
```

## Installing the pack

Add this pack with [cpackget](https://github.com/Open-CMSIS-Pack/cpackget):

```
cpackget add -a https://ashlingmicrosystems.github.io/ashling-cmsis-packs/QEMU32_RISCV_PicoJPEG/Ashling.QEMU32_RISCV_PicoJPEG.1.0.0.pack
```

(`-a` auto-accepts the GPL-3.0 embedded license non-interactively; omit it to be
prompted instead.) Note `cpackget add` does **not** accept an `index.pidx` URL directly
— only a pack id, a `.pack` file/URL, or a local `.pdsc` path. For local development,
install straight from your working copy:

```
cpackget add QEMU32_RISCV_PicoJPEG/Ashling.QEMU32_RISCV_PicoJPEG.pdsc
```

## Note: not listed in "Create Solution" examples

This example intentionally uses `<environment name="cmake" .../>` in the pdsc rather
than a `csolution.yml`-based project. Open-CMSIS-Pack's device model (`Dcore`, `Dfpu`,
`Dmpu`, ...) only enumerates Arm Cortex-M/R/A cores, and CMSIS-Toolbox's GCC toolchain
definition hard-codes the `arm-none-eabi-` compiler prefix and an Arm-only CPU
whitelist — there is no way to make `cbuild` actually target RV32IA. Separately, the
CMSIS Solution VS Code extension's "Create Solution" dropdown only lists examples whose
environment is `csolution`/`cmsis` or `uv`; anything else (including `cmake`) is never
shown there, regardless of how the pack is installed. This example therefore won't
appear in that dropdown — clone/open it directly, or install the pack and open its
folder as a plain CMake project.

## License

See [LICENSE.txt](LICENSE.txt) (GPL-3.0-or-later). Files under `src/` carry Embecosm/
University of Bristol (Embench) copyright notices under the same license.
