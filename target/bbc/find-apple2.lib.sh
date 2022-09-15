#!/usr/bin/env sh

# find-apple2.lib.sh

# script to find the file apple2.lib in the cc65 install
# in order to modify it and create a simple bbc.lib.

set -eu

# try /usr/share
if [ -f /usr/share/cc65/lib/apple2.lib ]; then
    echo /usr/share/cc65/lib/apple2.lib
    exit 0
fi

# follow symlink
if [ -L /usr/local/bin/ld65 ]; then
    READLINK=$(readlink /usr/local/bin/ld65)
    DIRNAME=$(dirname /usr/local/bin/$READLINK)
    # Homebrew
    FILENAME=$DIRNAME/../share/cc65/lib/apple2.lib
    if [ -f $FILENAME ]; then
        echo $FILENAME
        exit 0
    fi
fi

# not found
echo "apple2.lib not found" 1>&2
exit 1
