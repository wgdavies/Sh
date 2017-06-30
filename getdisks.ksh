#!/usr/bin/env ksh
#
# consider using lsblk instead of facter?

PATH=/usr/local/bin

typeset line p d
typeset -a dlist plist
typeset -i idx

for line in $(facter partitions --yaml); do
	if [[ ${line} == /dev/*: ]]; then
		plist+=( ${line%:} )
	fi
done

for line in $(facter disks --yaml); do
	if [[ ${line} == ???: ]]; then
		dlist+=( ${line%:} )
	fi
done

for (( idx = 0 ; idx < ${#dlist[@]} ; ++idx )); do
	for p in ${plist[@]}; do
		if [[ ${p} =~ ${dlist[$idx]} ]]; then
			unset dlist[$idx]
		fi
	done
done

for d in ${dlist[@]}; do
	print ${d}
done

