#!/bin/ksh

PATH=/bin:/usr/bin

typeset -i ds yr mon day

yr=${1:-$(printf '%(%Y)T')}
mon=${2:-$(printf '%(%m)T')}
day=${3:-$(printf '%(%d)T')}

if (( day >= 1 )) && (( day <= 31 )) &&
   (( mon >= 1 )) && (( mon <= 12 )) &&
   (( yr >= 2017 )); then
	typeset -Z4 -R4 yr
	typeset -Z2 -R2 mon day
	print "setting date to ${yr}-${mon}-${day}"
else
	print "error: please set date appropriately in YYYY MM DD format"
	exit 1
fi

ds=${yr}${mon}${day}
