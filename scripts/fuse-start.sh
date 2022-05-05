#!/usr/bin/env sh

set -e

# fuse-start.sh

# find Fuse Emulator
case "$(uname -s)" in
    CYGWIN*) FUSE="/cygdrive/c/Program Files/Fuse/fuse.exe" ;;
    *)       FUSE=fuse ;;
esac

# run Fuse and create pidfile
${FUSE} $@ & echo "$!" > spectrum/fuse.pid
