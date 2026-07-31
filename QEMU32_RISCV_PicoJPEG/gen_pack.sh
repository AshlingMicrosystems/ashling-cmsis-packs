#!/usr/bin/env bash
# Version: 3.1
# Date: 2024-04-17
# This bash script generates a CMSIS Software Pack:
#

set -o pipefail

# Set version of gen pack library
# For available versions see https://github.com/Open-CMSIS-Pack/gen-pack/tags.
REQUIRED_GEN_PACK_LIB="0.14.0"

# Set default command line arguments
DEFAULT_ARGS=()

# Pack warehouse directory - destination
# Default: ./output
#
# PACK_OUTPUT=./output

# Temporary pack build directory,
# Default: ./build
#
# PACK_BUILD=./build

# Specify directory names to be added to pack base directory
PACK_DIRS="
  src
"

# Specify file names to be added to pack base directory
PACK_BASE_FILES="
  LICENSE.txt
  Abstract.txt
  CMakeLists.txt
  toolchain.cmake
  picojpeg.csolution.yml
  picojpeg.cproject.yml
"

# Specify file names to be deleted from pack build directory
# Default: empty
#
# PACK_DELETE_FILES="
#   <list files here>
# "

# Specify patches to be applied
# Default: empty
#
# PACK_PATCH_FILES="
#     <list patches here>
# "

# Specify addition argument to packchk
# Default: empty
#
# PACKCHK_ARGS=()

# Specify additional dependencies for packchk
# Default: empty
#
# PACKCHK_DEPS="
#   <list pdsc files here>
# "

# Optional: restrict fallback modes for changelog generation
# Default: full
#
# PACK_CHANGELOG_MODE="<full|release|tag>"

# Specify file patterns to be excluded from the checksum file
# Default: <empty>
#
# PACK_CHECKSUM_EXCLUDE="
#   <list file patterns here>
# "

#
# custom pre-processing steps
#
# usage: preprocess <build>
#   <build>  The build folder
#
function preprocess() {
  # add custom steps here to be executed
  # before populating the pack build folder
  return 0
}

#
# custom post-processing steps
#
# usage: postprocess <build>
#   <build>  The build folder
#
function postprocess() {
  # add custom steps here to be executed
  # after populating the pack build folder
  # but before archiving the pack into output folder
  return 0
}

############ DO NOT EDIT BELOW ###########

# Set GEN_PACK_LIB_PATH to use a specific gen-pack library root
# ... instead of bootstrap based on REQUIRED_GEN_PACK_LIB
if [[ -n "${GEN_PACK_LIB_PATH}" ]] && [[ -f "${GEN_PACK_LIB_PATH}/gen-pack" ]]; then
  . "${GEN_PACK_LIB_PATH}/gen-pack"
else
  . <(curl -sL "https://raw.githubusercontent.com/Open-CMSIS-Pack/gen-pack/main/bootstrap")
fi

gen_pack "${DEFAULT_ARGS[@]}" "$@"

exit 0
