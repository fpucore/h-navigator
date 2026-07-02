#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# SEXTANT - Version 3.0
# Copyright (c) 2026 Harmonious Platform Systems
# https://www.freedompublishersunion.net/h-linux.html
#
# This Source Code Form is subject to the terms of the Mozilla Public 
# License, v. 2.0. If a copy of the MPL was not distributed with this 
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
# -----------------------------------------------------------------------------

# SEXTANT — Core monitor for H Navigator
# Usage: > [PROGRAM] [--rate <seconds>] <command> [args...]

if [[ "${1:-}" == "--monitor" ]]; then
  TARGET_PID="$2"
  REFRESH="$3"
  CMD_LABEL="$4"
  _MONITOR_MODE=1
else
  _MONITOR_MODE=0
fi

if [[ $_MONITOR_MODE -eq 1 ]]; then

R=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[31m'
GRN=$'\033[32m'
YLW=$'\033[33m'
BLU=$'\033[34m'
MAG=$'\033[35m'
CYN=$'\033[36m'
WHT=$'\033[37m'
BG_BLU=$'\033[44m'
BG_RED=$'\033[41m'

SPARKS=('▁' '▂' '▃' '▄' '▅' '▆' '▇' '█')
cpu_history=()
MAX_HISTORY=40

tput civis 2>/dev/null
cleanup_monitor() {
  tput cnorm 2>/dev/null
  printf '\n'
}
trap cleanup_monitor EXIT INT TERM

hline() {
  local width=$1 char=${2:-─}
  [[ $width -lt 1 ]] && return
  printf '%0.s'"$char" $(seq 1 "$width")
}

bar() {
  local val=$1 max=$2 width=$3 color=$4
  [[ $width -lt 1 ]] && return
  [[ $max   -lt 1 ]] && max=1
  local filled=$(( val * width / max ))
  [[ $filled -gt $width ]] && filled=$width
  [[ $filled -lt 0      ]] && filled=0
  local empty=$(( width - filled ))
  printf '%s' "$color"
  [[ $filled -gt 0 ]] && printf '█%.0s' $(seq 1 "$filled")
  printf '%s' "$DIM"
  [[ $empty  -gt 0 ]] && printf '░%.0s' $(seq 1 "$empty")
  printf '%s' "$R"
}

strip_ansi() {
  printf '%s' "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

visible_len() {
  local s
  s=$(strip_ansi "$1")
  printf '%s' "${#s}"
}

pad_to() {
  local str=$1 target=$2
  local vlen
  vlen=$(visible_len "$str")
  local pad=$(( target - vlen ))
  [[ $pad -lt 0 ]] && pad=0
  printf '%s%*s' "$str" "$pad" ''
}

trunc() {
  local str=$1 width=$2
  [[ ${#str} -gt $width ]] && str="${str:0:$width}"
  printf '%s' "$str"
}

sparkline() {
  local spark='' val idx
  for val in "${cpu_history[@]}"; do
    # Ensure val is a number, default to 0
    val=${val:-0}
    # Calculate index (0-7) for the 8 spark characters
    idx=$(( val * 7 / 100 ))
    (( idx > 7 )) && idx=7
    (( idx < 0 )) && idx=0
    spark+="${SPARKS[$idx]}"
  done
  echo -n "$spark"
}

read_proc_io() {
  local io_file="/proc/$1/io"
  [[ ! -f "$io_file" ]] && printf '0 0' && return
  [[ ! -r "$io_file" ]] && printf 'EPERM EPERM' && return
  awk '
    /read_bytes/  { r = $2 }
    /write_bytes/ { w = $2 }
    END           { print (r+0), (w+0) }
  ' "$io_file" 2>/dev/null || printf '0 0'
}

fmt_bytes() {
  local bytes=$1
  [[ "$bytes" == "EPERM" ]] && printf 'n/a' && return
  if   (( bytes >= 1073741824 )); then
    printf '%.2f GB' "$(echo "scale=2; $bytes/1073741824" | bc)"
  elif (( bytes >= 1048576 )); then
    printf '%.2f MB' "$(echo "scale=2; $bytes/1048576" | bc)"
  elif (( bytes >= 1024 )); then
    printf '%.2f KB' "$(echo "scale=2; $bytes/1024" | bc)"
  else
    printf '%d B' "$bytes"
  fi
}

read_threads() {
  local status="/proc/$1/status"
  [[ ! -r "$status" ]] && printf '?' && return
  awk '/^Threads:/ { print $2 }' "$status" 2>/dev/null || printf '?'
}

color_for_pct() {
  local val=$1 type=$2
  if   [[ $val -ge 80 ]]; then printf '%s' "$RED"
  elif [[ $val -ge 40 ]]; then printf '%s' "$YLW"
  elif [[ "$type" == "mem" ]]; then printf '%s' "$CYN"
  else printf '%s' "$GRN"
  fi
}

read_fd_summary() {
  local fd_dir="/proc/$1/fd"
  [[ ! -d "$fd_dir" ]] && printf '0 0 0 0' && return
  local files=0 socks=0 pipes=0 other=0 target
  while IFS= read -r -d '' link; do
    target=$(readlink "$link" 2>/dev/null) || continue
    case "$target" in
      socket:*) (( socks++  )) || true ;;
      pipe:*)   (( pipes++  )) || true ;;
      /*)       (( files++  )) || true ;;
      *)        (( other++  )) || true ;;
    esac
  done < <(find "$fd_dir" -maxdepth 1 -type l -print0 2>/dev/null)
  printf '%d %d %d %d' "$files" "$socks" "$pipes" "$other"
}

read_net_connections() {
  local net_tcp="/proc/$1/net/tcp"
  [[ ! -r "$net_tcp" ]] && return
  awk '
    NR > 1 {
      split($2, la, ":"); split($3, ra, ":")
      state = $4
      if      (state == "01") s = "ESTABLISHED"
      else if (state == "0A") s = "LISTEN"
      else next
      lport = strtonum("0x" la[2])
      rport = strtonum("0x" ra[2])
      printf "  TCP :%d -> :%d [%s]\n", lport, rport, s
    }
  ' "$net_tcp" 2>/dev/null | head -5
}

row() {
  local inner=$1 content=$2
  local padded
  padded=$(pad_to "$content" "$inner")
  printf "${DIM}║${R}%s${DIM}║${R}\n" "$padded"
}

while kill -0 "$TARGET_PID" 2>/dev/null; do

  cols=$(tput cols)
  rows=$(tput lines)
  inner=$(( cols - 2 ))

  if [[ $inner -lt 20 ]]; then
    sleep "$REFRESH"
    continue
  fi

  ps_line=$(ps -o %cpu=,%mem=,etime=,nlwp= -p "$TARGET_PID" 2>/dev/null | head -1)
  [[ -z "$ps_line" ]] && sleep "$REFRESH" && continue
  read -r cpu mem elapsed threads <<< "$ps_line"
  
  cpu=$(echo "$cpu" | xargs)
  mem=$(echo "$mem" | xargs)
  elapsed=$(echo "$elapsed" | xargs)
  threads=$(echo "$threads" | xargs)

  cpu_int=${cpu%.*};     cpu_int=${cpu_int:-0}
  mem_int=${mem%.*};     mem_int=${mem_int:-0}
  threads=${threads:-0}; threads=${threads//[[:space:]]/}
  [[ $cpu_int -lt 0 ]] && cpu_int=0
  [[ $mem_int -lt 0 ]] && mem_int=0

  cpu_history+=("$cpu_int")
  if [[ ${#cpu_history[@]} -gt $MAX_HISTORY ]]; then
    cpu_history=("${cpu_history[@]:1}")
  fi
  
  read -r io_read io_write <<< "$(read_proc_io "$TARGET_PID")"
  io_r_fmt=$(fmt_bytes "$io_read")
  io_w_fmt=$(fmt_bytes "$io_write")

  read -r fd_files fd_socks fd_pipes fd_other <<< "$(read_fd_summary "$TARGET_PID")"
  fd_total=$(( fd_files + fd_socks + fd_pipes + fd_other ))

  net_lines=$(read_net_connections "$TARGET_PID")

  cpu_col=$(color_for_pct "$cpu_int" "cpu")
  mem_col=$(color_for_pct "$mem_int" "mem")

  spark_max=$(( inner - 14 ))
  [[ $spark_max -lt 1 ]] && spark_max=1
  # Ensure it doesn't exceed our MAX_HISTORY constant
  [[ $spark_max -gt $MAX_HISTORY ]] && spark_max=$MAX_HISTORY
  
  spark_str=$(sparkline)

  bar_width=$(( inner - 20 ))
  [[ $bar_width -lt 1 ]] && bar_width=1

  frame=''

  title=" PID: ${TARGET_PID}  •  $(trunc "$CMD_LABEL" 28) "
  title_len=${#title}
  pad=$(( (cols - title_len) / 2 ))
  [[ $pad -lt 0 ]] && pad=0
  rpad=$(( cols - title_len - pad ))
  [[ $rpad -lt 0 ]] && rpad=0
  frame+="${BG_RED}${BOLD}${WHT}$(printf '%*s' $pad '')${title}$(printf '%*s' $rpad '')${R}\n"
  frame+="${DIM}╔$(hline $inner ═)╗${R}\n"
  frame+="$(row $inner " ${BLU}${BOLD}ELAPSED${R}  ${WHT}${elapsed}${R}   ${DIM}threads:${R} ${WHT}${threads}${R}")\n"
  frame+="${DIM}╠$(hline $inner ═)╣${R}\n"
  frame+="$(row $inner " ${BOLD}${cpu_col}CPU${R}  ${cpu}%  $(bar $cpu_int 100 $bar_width $cpu_col)")\n"
  frame+="$(row $inner " ${BOLD}${mem_col}MEM${R}  ${mem}%  $(bar $mem_int 100 $bar_width $mem_col)")\n"
  frame+="$(row $inner " ${DIM}history:${R} ${YLW}${spark_str}${R}")\n"
  frame+="${DIM}╠$(hline $inner ═)╣${R}\n"
  frame+="$(row $inner " ${BOLD}${MAG}IO${R}  ${DIM}read${R} ${WHT}${io_r_fmt}${R}  ${DIM}write${R} ${WHT}${io_w_fmt}${R}")\n"
  frame+="$(row $inner " ${BOLD}${YLW}FD${R}  ${WHT}${fd_total}${R} total  ${DIM}files:${R}${WHT}${fd_files}${R} ${DIM}sockets:${R}${WHT}${fd_socks}${R} ${DIM}pipes:${R}${WHT}${fd_pipes}${R}")\n"
  frame+="${DIM}╠$(hline $inner ═)╣${R}\n"
  frame+="$(row $inner " ${BOLD}${CYN}NETWORK${R}")\n"
  frame+="${DIM}╟$(hline $inner ─)╢${R}\n"

  if [[ -n "$net_lines" ]]; then
    while IFS= read -r line; do
      frame+="$(row $inner " ${DIM}${line}${R}")\n"
    done <<< "$net_lines"
  else
    frame+="$(row $inner " ${DIM}no connections${R}")\n"
  fi

  frame+="${DIM}╚$(hline $inner ═)╝${R}\n"

  printf '\033[H'
  printf '%b' "$frame"
  printf '\033[J'

  sleep "$REFRESH"
done

tput cnorm 2>/dev/null
printf '\n'
printf "${BG_BLU}${BOLD}${WHT} Process ${TARGET_PID} exited ${R}\n"
read -r -n1 -p 'Press any key to close...'
exit 0

fi

# ====
# LAUNCHER MODE
# ====

REFRESH=1

usage() {
  printf 'Usage: %s [--rate <seconds>] <command> [args...]\n' "$(basename "$0")"
  printf '  --rate  Refresh interval in seconds (default: 1)\n'
  exit 1
}

while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --rate)
      [[ -z "${2:-}" ]] && usage
      REFRESH="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      printf 'Unknown option: %s\n' "$1"
      usage
      ;;
  esac
done

[[ $# -eq 0 ]] && usage

SCRIPT_PATH="$(realpath "$0")"
CMD_LABEL="$(basename "$1")"

"$@" &
TARGET_PID=$!

cleanup_launcher() {
  kill "$TARGET_PID" 2>/dev/null || true
}
trap cleanup_launcher EXIT

if command -v cherry-terminal &>/dev/null; then
  cherry-terminal -e bash "$SCRIPT_PATH" --monitor "$TARGET_PID" "$REFRESH" "$CMD_LABEL" &
elif command -v xterm &>/dev/null; then
  xterm -e bash "$SCRIPT_PATH" --monitor "$TARGET_PID" "$REFRESH" "$CMD_LABEL" &
elif command -v gnome-terminal &>/dev/null; then
  gnome-terminal -- bash "$SCRIPT_PATH" --monitor "$TARGET_PID" "$REFRESH" "$CMD_LABEL" &
else
  printf 'Error: no supported terminal found (cherry-terminal, xterm, gnome-terminal)\n' >&2
  exit 1
fi

wait "$TARGET_PID"
