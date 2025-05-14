#!/usr/bin/env sh

set -eu

# stop.sh

# stop a process, remove pidfile

# get filename
PIDFILE="$1"

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
