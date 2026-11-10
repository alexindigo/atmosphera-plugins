#!/bin/sh
# save-profile.sh <cfg_dir> <profile_dir>
# Preserve the existing command entrypoint; all selected raw files share one IO owner.
set -eu
wallpapers='{}'
meta='{}'
if [ "$#" -ge 3 ]; then wallpapers=$3; fi
if [ "$#" -ge 4 ]; then meta=$4; fi
exec python3 "$(dirname "$0")/profile-files.py" save "$1" "$2" \
  --wallpapers "$wallpapers" --meta "$meta"
