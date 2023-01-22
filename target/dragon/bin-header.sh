set -e

LEN=$1

FMT=$( printf '\\%03o\\%03o' $(( $LEN / 256 )) $(( $LEN % 256 )) )
printf '\125\002\006\000'
printf "$FMT"
printf '\006\000\252'
