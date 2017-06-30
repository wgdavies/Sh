#!/bin/ksh

PROGNAME=${0##*/}

## Report on error conditions in a standardised format to STDERR.
#  Causes program to exit with non-zero value (0 > x > 256) as
#  interpolated from ${ret_val}. 
#
function error {
#    diag
    if (( ret_val == 0 )); then
	(( ret_val++ ))
    elif (( ret_val > 254 )); then
	ret_val=255
    fi
    
    print "${PROGNAME} error: $@" 1>&2
    
    exit ${ret_val}
}

## List of required external commands
#
typeset -a EXTERNS=(
    find
    hostname
    rm
    rsync
    scp
    sed
    ssh
    poop
)

## Create the ALLCAPS variables from the list of required externals
#
declareXterns () {
    typeset cmdname

    for cmdname in ${EXTERNS[@]}; do
	typeset -u CMDREF=${cmdname}
	nameref cmdref=${CMDREF}
	
	cmdref=$(whence ${cmdname})
	if (( $? == 0 )); then
	    readonly cmdref
	    debug "typeset -r ${CMDREF} = ${cmdref}"
	else
	    error "unable to resolve required external command \"${cmdname}\""
	fi
    done
    
    return ${ret_val}
}

## Make externs available or fail with an error if any can not be found
#
declareXterns
