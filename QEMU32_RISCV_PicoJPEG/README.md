# Ashling.QEMU32_RISCV_PicoJPEG

Bare-metal RV32IA picojpeg JPEG-decode example, built with CMake and run/debugged
under QEMU's "virt" machine model. Distributed as an [Open-CMSIS-Pack](https://open-cmsis-pack.github.io/Open-CMSIS-Pack-Spec/main/html/index.html).

See [Abstract.txt](Abstract.txt) for the full technical description.

## Building

```
cmake -G "Unix Makefiles" -S . -B build ^
    -DCMAKE_C_COMPILER=<toolchain>/riscv64-unknown-elf-gcc.exe ^
    -DCMAKE_CXX_COMPILER=<toolchain>/riscv64-unknown-elf-g++.exe ^
    -DCMAKE_ASM_COMPILER=<toolchain>/riscv64-unknown-elf-gcc.exe
cmake --build build
```

This produces `build/picojpeg.elf`.

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
