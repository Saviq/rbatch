#!/bin/bash

set -e

usage() {
  echo "Usage:"
  echo "  $0 command item"
  echo
  echo "  command: oper-name, where oper is one of copy, sync, move"
  echo "  item:    name of the subdirectory to process"
  echo
  echo "  The following environment variables are read, in order of precedence:"
  echo "    name_SRC:"
  echo "    name_DEST:      rclone source and destination paths"
  echo "    name_EXCLUDE:"
  echo "    RCLONE_EXCLUDE: passed as --exclude-from, if exists under src/ and/or dest/"
  echo "    name_OPTIONS:"
  echo "    RCLONE_OPTIONS: both passed to rclone as-is"
}

if [ $# -ne 2 ]; then
  usage
  exit 2
fi

if [[ $1 =~ ^(sync|copy|move)-([[:alnum:]]+)$ ]]; then
  op=${BASH_REMATCH[1]}
  name=${BASH_REMATCH[2]}
else
  echo "ERROR: Wrong command used: $1"
  echo
  usage
  exit 1
fi

src_varname="${name}_SRC"
dest_varname="${name}_DEST"
exclude_varname="${name}_EXCLUDE"
options_varname="${name}_OPTIONS"

exclude=${!exclude_varname-${RCLONE_EXCLUDE-".rclone.exclude"}}

item="$2"
src="${!src_varname}/${item}"
dest="${!dest_varname}/${item}"

read -a opts <<< "${RCLONE_OPTIONS} ${!options_varname}"
opts+=("--exclude=${exclude}")

echo "========== ${item} =========="

if ( rclone lsd "${src}" && rclone lsd "${dest}" ) 2>&1 > /dev/null; then
  [ -f "${src}/${exclude}" ] && \
    opts+=("--exclude-from=${src}/${exclude}")
  [ -f "${dest}/${exclude}" ] && \
    opts+=("--exclude-from=${dest}/${exclude}")

  opts+=("$op")
  opts+=("$src")
  opts+=("$dest")

  rclone "${opts[@]}"
else
  echo "INFO: ${item} not present on both sides, ignoring."
fi
