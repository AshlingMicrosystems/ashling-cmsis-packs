cmake_minimum_required(VERSION 3.14)

include(toolchain.cmake)

project(picojpeg)

add_executable(picojpeg.elf)

target_sources(picojpeg.elf
    PRIVATE
    	src/init.S
        src/main.c
        src/picojpeg_test.c
        src/libpicojpeg.c
)

target_include_directories(picojpeg.elf
    PRIVATE
    PUBLIC
)

if(NOT DEFINED ExtraArchiveLibraries)
    set(ExtraArchiveLibraries "")
endif()

target_link_libraries(picojpeg.elf
    PRIVATE
    	-T "${CMAKE_CURRENT_SOURCE_DIR}/src/link.ld" -nostartfiles
        "${ExtraArchiveLibraries}"
        -Xlinker --no-warn-rwx-segments
        -Wl,--start-group -lc -lstdc++ -lgcc -lm -Wl,--end-group
)

# Create objdump from ELF. ToolchainObjdump/ToolchainObjdumpFlags are supplied
# by IDE integrations (e.g. -D on the cmake configure line); skip this target
# entirely for a plain command-line build where they aren't set.
if(DEFINED ToolchainObjdump)
    set(objdump picojpeg.elf.objdump)
    add_custom_command(
        OUTPUT "${objdump}"
        DEPENDS picojpeg.elf
        COMMAND "${ToolchainObjdump}" "${ToolchainObjdumpFlags}" picojpeg.elf >
                "${objdump}"
        COMMENT "Creating ${objdump}."
        VERBATIM
    )
    add_custom_target(create-objdump ALL DEPENDS "${objdump}")
endif()

enable_language(ASM)
enable_language(C)
enable_language(CXX)
