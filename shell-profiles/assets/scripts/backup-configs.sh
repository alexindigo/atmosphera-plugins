#!/bin/sh
# backup-configs.sh <cfg_dir> <backup_dir>
# The auto-backup and named profile cover exactly the same raw file family.
set -eu
exec sh "$(dirname "$0")/save-profile.sh" "$@"
