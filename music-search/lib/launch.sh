#!/usr/bin/env bash
# launch.sh — mpv launch helpers

launch_youtube_stream() {
  local source_url="$1"
  local speed="${2-1}"
  local -a mpv_cmd=(
    mpv
    --no-video
    --force-window=no
    --audio-display=no
    --ytdl-format=bestaudio/best
    --demuxer-max-bytes=256K
    --speed="$speed"
    --log-file="$LOG_FILE"
    --input-ipc-server="$SOCKET_FILE"
    --title="Noctalia music-search"
  )
  local raw_opt
  raw_opt="$(yt_mpv_raw_option)"
  [[ -n "$raw_opt" ]] && mpv_cmd+=("$raw_opt")
  mpv_cmd+=("$source_url")

  nohup setsid "${mpv_cmd[@]}" >/dev/null 2>&1 &
}

launch_youtube_cached() {
  local source_url="$1"
  local speed="${2-1}"
  local extractor_arg
  extractor_arg="$(yt_extractor_args)"

  nohup setsid python3 "${SCRIPT_DIR}/lib/playback-cache.py" play "$CACHE_DIR" \
    "$source_url" "$extractor_arg" "$speed" >>"$LOG_FILE" 2>&1 &
}

wait_for_audio_start() {
  local pid="$1"
  local attempts="${2-24}"

  for _ in $(seq 1 "$attempts"); do
    if [[ -f "$LOG_FILE" ]] && grep -q "starting audio playback" "$LOG_FILE" 2>/dev/null; then
      return 0
    fi

    if ! is_running_pid "$pid"; then
      return 1
    fi

    sleep 0.25
  done

  return 2
}
