#!/usr/bin/env sh

set -eu

# start.sh

# start a background process, redirect stdin, stdout, write pidfile

# get args
IN="$1"
OUT="$2"
PIDFILE="$3"

# stop existing processes in pidfile
if [ -f "$PIDFILE" ]; then
  kill $(cat "$PIDFILE") 2> /dev/null || true
  sleep 1
  kill -9 $(cat "$PIDFILE") 2> /dev/null || true
fi

# now get command and args
shift
shift
shift

# redirect stdin and stdout
"$@" < "$IN" 1> "$OUT" &

# write pidfile
echo $! > "$PIDFILE"
