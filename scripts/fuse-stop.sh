#!/usr/bin/env sh

set -e

# fuse-stop.sh

# find pidfile
PIDFILE=spectrum/fuse.pid
if [ -f $PIDFILE ]; then
	kill -9 $(cat $PIDFILE)
  rm -f $PIDFILE
fi
