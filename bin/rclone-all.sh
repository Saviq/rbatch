#!/bin/bash

set -e

usage() {
  echo "Usage:"
  echo "  $0 command"
  echo
  echo "  command: operation-all, where operation is one of copy, sync, move"
  echo
  echo "  The following environment variables are read:"
  echo "    RCLONE_NAMES: a list of names to be processed"
  echo "    name_SRC:"
  echo "    name_DEST:    rclone source and destination paths for each name"
  echo
  echo "  For each directory common between source and destination,"
  echo "  operation-name@dir.service will be started, in sequence."
  echo
  echo "  Sending SIGHUP (systemctl reload) will result in stopping the job"
  echo "  after the current transfer completes."
}

if [ $# -ne 1 ]; then
  usage
  exit 2
fi

if [[ $1 =~ ^(sync|copy|move)-all$ ]]; then
  op=${BASH_REMATCH[1]}
  name=${BASH_REMATCH[2]}
else
  echo "ERROR: Wrong command used: $1"
  echo
  usage
  exit 1
fi

for name in ${RCLONE_NAMES}; do
  src_varname="${name}_SRC"
  dest_varname="${name}_DEST"

  src="${!src_varname}"
  dest="${!src_varname}"

  items=$( comm -12 \
    <(rclone lsd "${src}" | awk '{ print substr($0, index($0, $5)) }' | sort ) \
    <(rclone lsd "${dest}" | awk '{ print substr($0, index($0, $5)) }' | sort ) )

  IFS=$'\n'

  for item in ${items}; do
    echo "INFO: ${op}ing ${item}"
    unit=$( systemd-escape --template=${op}-${name}@.service "${item}"  )
    systemctl --user start ${unit}

    while [ "$( systemctl --user is-active ${unit} )" == "active" ]; do
      sleep 30
    done

    [ "$FINISH" != "yes"  ] || exit 0
  done
done
