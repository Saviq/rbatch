#!/bin/bash

set -e

usage() {
  echo "Usage:"
  echo "  $0 command src dest"
  echo
  echo "  command: (sync|copy|move)-name, determining rclone operation"
  echo
  echo "  The following environment variables are parsed, in order of precedence:"
  echo "    name_EXCLUDE:"
  echo "    RCLONE_EXCLUDE: passed as --exclude-from, if exists under src/ and/or dest/"
  echo "    name_OPTIONS:"
  echo "    RCLONE_OPTIONS: both passed to rclone as-is"
}

if [ $# -ne 3 ]; then
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

exclude_varname="${name}_EXCLUDE"
options_varname="${name}_OPTIONS"

exclude=${!exclude_varname-${RCLONE_EXCLUDE-".rclone.exclude"}}

src="$2"
dest="$3"
read -a opts <<< "${RCLONE_OPTIONS} ${!options_varname}"
opts+=("--exclude=${exclude}")

item=$( echo ${src} | awk -F/ '{ print $(NF) }' )

echo "========== ${item} =========="

if [ ! -d "${src}" -a ! -d "${dest}" ]; then
  printf "INFO: ${item} Missing.\n\n"
  exit 0
fi

[ -f "${src}/${exclude}" ] && \
  opts+=("--exclude-from=${src}/${exclude}")
[ -f "${dest}/${exclude}" ] && \
  opts+=("--exclude-from=${dest}/${exclude}")

opts+=("$op")
opts+=("$src")
opts+=("$dest")

rclone "${opts[@]}"