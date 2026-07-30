set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR "General")
set(CMAKE_CROSSCOMPILING True)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)


if(NOT CMAKE_BUILD_TYPE)
    message(STATUS "Defaulting build type to Debug.")
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build." FORCE)
endif()

set(CMAKE_C_FLAGS_DEBUG "-g")
set(CMAKE_CXX_FLAGS_DEBUG "-g")

set(CMAKE_C_FLAGS_RELEASE "-O2")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

add_compile_options(
    $<$<COMPILE_LANGUAGE:ASM>:-Wa,-gdwarf2>
    -DALT_SINGLE_THREADED
    -Wall -Wformat-security
    -march=rv32ia -mabi=ilp32
)

add_link_options(
    -march=rv32ia -mabi=ilp32
)

add_compile_definitions(

)

remove_definitions(
)
