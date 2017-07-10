#!/bin/ksh

PATH=/bin:/usr/bin

typeset -Z2 -R2 day mon
typeset -Z4 -R4 yr
typeset -li ds

day=${1}
mon=${2}
yr=${3}

if (( day != 0 )) && (( mon != 0 )) && (( yr != 0 )); then
    ds=${yr}${mon}${day}
else
    day=$(printf '%(%d)T')
    mon=$(printf '%(%m)T')
    yr=$(printf '%(%Y)T')
    ds=${yr}${mon}${day}
fi

print ${ds}
