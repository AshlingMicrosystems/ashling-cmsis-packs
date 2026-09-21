set(AS "as")
set(CC "gcc")
set(CXX "g++")
set(CPP "gcc")
set(OC "objcopy")

set(TOOLCHAIN_ROOT "${REGISTERED_TOOLCHAIN_ROOT}")
set(TOOLCHAIN_VERSION "${REGISTERED_TOOLCHAIN_VERSION}")

if(DEFINED TOOLCHAIN_ROOT)
  set(PREFIX riscv64-unknown-elf-)
  set(AS ${TOOLCHAIN_ROOT}/${PREFIX}${AS})
  set(CC ${TOOLCHAIN_ROOT}/${PREFIX}${CC})
  set(CXX ${TOOLCHAIN_ROOT}/${PREFIX}${CXX})
  set(CPP ${TOOLCHAIN_ROOT}/${PREFIX}${CPP})
  set(OC ${TOOLCHAIN_ROOT}/${PREFIX}${OC})
endif()

# Deliberately does not switch on CPU/FPU/DSP and does not FATAL_ERROR on an
# unrecognized core (unlike Arm's stock GCC.<version>.cmake): this project's
# csolution.yml misc: blocks already supply 100% of the real compile/link
# flags (-march=rv32ia -mabi=ilp32 -nostartfiles), matching Dcore="other".

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_CROSSCOMPILING TRUE)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_ASM_COMPILER "${CC}")
set(CMAKE_C_COMPILER "${CC}")
set(CMAKE_CXX_COMPILER "${CXX}")
set(CMAKE_OBJCOPY "${OC}")
