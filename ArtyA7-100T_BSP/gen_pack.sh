#!/usr/bin/env bash
# Version: 3.1
# Date: 2024-04-17
# This bash script generates a CMSIS Software Pack:
#

set -o pipefail

REQUIRED_GEN_PACK_LIB="0.14.0"

DEFAULT_ARGS=()

PACK_BASE_FILES="
  LICENSE.txt
  Abstract.txt
"

function preprocess() {
  return 0
}

function postprocess() {
  return 0
}

############ DO NOT EDIT BELOW ###########

if [[ -n "${GEN_PACK_LIB_PATH}" ]] && [[ -f "${GEN_PACK_LIB_PATH}/gen-pack" ]]; then
  . "${GEN_PACK_LIB_PATH}/gen-pack"
else
  . <(curl -sL "https://raw.githubusercontent.com/Open-CMSIS-Pack/gen-pack/main/bootstrap")
fi

gen_pack "${DEFAULT_ARGS[@]}" "$@"

exit 0
