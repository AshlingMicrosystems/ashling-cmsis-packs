# Builds picojpeg.csolution.yml via CMSIS-Toolbox's cbuild, using the RISC-V GCC
# toolchain resolved by `vcpkg activate` (see vcpkg-configuration.json). This is
# project-local: GCC_TOOLCHAIN_12_1_0 and CMSIS_COMPILER_ROOT are only set in this
# script's own process, never globally, since within this scope "GCC" is bound to
# our RISC-V toolchain rather than the usual arm-none-eabi-gcc.
vcpkg activate

$gcc = (Get-Command riscv64-unknown-elf-gcc.exe -ErrorAction Stop).Source
$env:GCC_TOOLCHAIN_12_1_0 = Split-Path $gcc -Parent
$env:CMSIS_COMPILER_ROOT = "$PSScriptRoot\cmsis-toolchain-config"

cbuild picojpeg.csolution.yml --packs
