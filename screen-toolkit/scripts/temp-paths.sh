#!/usr/bin/env bash
# Path selection belongs to TempPaths.qml. Standalone callers supply the same
# directory explicitly; helpers never invent a second fallback or capture root.
: "${SCREEN_TOOLKIT_TMPDIR:?Screen Toolkit requires its supplied runtime directory}"
case "$SCREEN_TOOLKIT_TMPDIR" in
  /*) ;;
  *) printf '%s\n' 'Screen Toolkit requires an absolute runtime directory' >&2; exit 1 ;;
esac
umask 077
mkdir -p -- "$SCREEN_TOOLKIT_TMPDIR" || exit 1
export TMPDIR="$SCREEN_TOOLKIT_TMPDIR"
