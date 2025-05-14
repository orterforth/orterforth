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
  PID=$(cat "$PIDFILE")
  # SIGTERM
  kill $PID 2> /dev/null || true
  if ps -p $PID > /dev/null
  then
    # SIGKILL
    sleep 1
    kill -9 $PID 2> /dev/null || true
  fi

  # remove pidfile
  rm "$PIDFILE" || true
fi

# now get command and args
shift
shift
shift

# redirect stdin and stdout
"$@" < "$IN" 1> "$OUT" &

# write pidfile
echo $! > "$PIDFILE"
