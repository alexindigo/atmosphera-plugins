#!/bin/sh
# apply-profile.sh <profile_dir> <cfg_dir>
# Publication errors are failures, never swallowed success.
set -eu
evidence=${4:-"$2/.profile-operations"}
if [ -n "${3:-}" ]; then
  exec python3 "$(dirname "$0")/profile-files.py" apply "$2" "$1" --baseline "$3" --evidence "$evidence"
fi
exec python3 "$(dirname "$0")/profile-files.py" apply "$2" "$1" --evidence "$evidence"
