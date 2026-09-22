# Builds picojpeg.csolution.yml via CMSIS-Toolbox's cbuild, using the RISC-V GCC
# toolchain resolved by `vcpkg activate` (see vcpkg-configuration.json), which
# registers GCC_TOOLCHAIN_12_1_0 itself (see the riscv-toolchain artifact's
# exports.tools in the ashling-vcpkg-registry). CMSIS_COMPILER_ROOT is still set
# here, project-local: within this scope "GCC" is bound to our RISC-V toolchain
# rather than the usual arm-none-eabi-gcc, via our own GCC.12.1.0.cmake.
vcpkg activate

$env:CMSIS_COMPILER_ROOT = "$PSScriptRoot\cmsis-toolchain-config"

cbuild picojpeg.csolution.yml --packs
