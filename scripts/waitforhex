#!/usr/bin/env sh

set -eu

# wait for disc file to appear
while ! [ -f "$1" ]; do
  sleep 1
done

# wait for the terminating block to be written to the disc
while ! grep ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ "$1" > /dev/null ; do
  sleep 1
done

echo "terminating block written"
