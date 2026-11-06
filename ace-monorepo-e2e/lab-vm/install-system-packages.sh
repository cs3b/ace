#!/bin/sh
# Install pinned snapshot dependencies only after every archive is available.
set -eu
[ "$#" -ge 2 ] || { echo "usage: install-system-packages.sh SNAPSHOT_LIST PACKAGE..." >&2; exit 2; }
snapshot_list=$1
shift
[ -f "$snapshot_list" ] || { echo "snapshot list missing" >&2; exit 2; }

apt_snapshot() {
  apt-get -o Acquire::Retries=0 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 \
    -o "Dir::Etc::sourcelist=$snapshot_list" -o Dir::Etc::sourceparts=- "$@"
}

retry_acquisition() {
  attempt=1
  while :; do
    if apt_snapshot "$@"; then return 0; else result=$?; fi
    # apt 3.0.3 can accumulate delayed-retry warnings until OOM (#1152704).
    # A new process releases that state; never retry package installation.
    if [ "$result" -ne 100 ] || [ "$attempt" -ge 3 ]; then return "$result"; fi
    echo "Snapshot acquisition failed; retrying in a fresh process ($attempt/3)" >&2
    sleep 5
    attempt=$((attempt + 1))
  done
}

retry_acquisition -o APT::Update::Error-Mode=any update
retry_acquisition install --download-only -y "$@"
apt_snapshot install --no-download -y "$@"
