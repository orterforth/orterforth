#!/usr/bin/env sh

set -eu

# prompt.sh

# displays a message then waits for the <enter> key

printf "* \033[1;35m${1}\033[0;0m\n"
printf "  \033[1;35mthen on this machine press <enter>\033[0;0m\n"
read   LINE
