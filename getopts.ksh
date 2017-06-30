#!/bin/ksh
#

## Default environment settings
#
PATH=/bin:/usr/bin
typeset PROGNAME="incchk"
typeset WORKDIR=""
typeset HOME=""
typeset CONFDIR="${HOME}/${WORKDIR}/conf"

## Default external command arguments
#
typeset RS_ARGS='--rsh="ssh -q" --archive --quiet --no-motd --relative'
typeset C_FIND_ARGS=""
typeset FIND_ARGS='-type f -exec md5sum {} \;'
typeset SSH_ARGS='-q'

## Global variables for primary and secondary cluster names
#
typeset PRI PDSC SEC SDSC CLUSTOPT
typeset -a primary secondary

## Default timestamp (c.f -d, --date flag)
#
typeset DS=$(printf '%(%Y%m%d)T' now)

## Default collection top-level directory
#
typeset TLD="export/rocks"

## Configuration file defaults
#
typeset CLIST="${CONFDIR}/ignore-list"
typeset RLIST="${CONFDIR}/ignore-report-list"
typeset MLIST="${CONFDIR}/map"
typeset WLIST="${CONFDIR}/whitelist"

## Global output file variable
#
typeset OUTFILE=""

## Diagnostics and debugging; set DEBUG=${OFF} for production
#
typeset -ir OFF=0
typeset -ir ON=1
typeset -ir VERBOSE=${ON}
typeset -ir TRACE=2
typeset -ir DIAGNOSTIC=3
typeset -i DEBUG=${OFF}
alias diag=''

## When diagnostic-level debugging is required, hard-set the value of "DEBUG",
#  above, to "DIAGNOSTIC" to enable the following intra-function tracing
if (( DEBUG >= DIAGNOSTIC )); then
    set +o nounset
    alias diag='set -o xtrace'
    PS4='${.sh.fun}($@): ${LINENO} @ ${SECONDS}s xtrace> '
fi

## Global return value for status checking
#
typeset -i ret_val=0

## getopts() parameters; there's a lot of extra stuff here used for online docs
#
typeset argc
typeset USAGE_PARAMS=$'[-?\n@(#)$Id: incchk (Inconsistency Checker) version: 1.0.0 $\n]'
USAGE_PARAMS+=$'[-author?Walter G Davies <walter.g.davies@gmail.com>]'
USAGE_PARAMS+=$'[-copyright?Copyright (c) 2017 Walter G Davies]'
USAGE_PARAMS+=$'[-license?3BSD]'
USAGE_PARAMS+=$'[+NAME?incchk --- check files for inter-cluster continuity]'
USAGE_PARAMS+=$'[+DESCRIPTION?The \bincchk\b program is the Inconsistency Check that runs on a given node, typically by scheduled execution of the \bincchk.sh\b script, which finds and reports differences between cluster configuration files on different nodes. Note that to gather the required information, the package must be installed on each node which will be included in a report.]'
USAGE_PARAMS+=$'[+USAGE?This package is designed to typically run as a standalone job from e.g \vcron(1)\v. The program can also be run manually to generate \aad-hoc\a reports, check that additions to an ignore-list or white-list are properly accounted for, or view reports for previous date periods to track and trend progress.]'
USAGE_PARAMS+=$'[f:fetch?Collect file data for all supported \anode\as, if specified. \bNOTE:\b the \vfetch\v option must be run apart from subsequent file checking; any other options are ignored.]:?[\anode\a]'
USAGE_PARAMS+=$'[p:primary?Specify the primary cluster for comparison. See the \bVALID CLUSTERS\b section, below, for the list of currently supported clusters.]:[\acluster\a]'
USAGE_PARAMS+=$'[s:secondary?Specify the secondary cluster to compare against the primary. See the \bVALID CLUSTERS\b section, below, for the list of currently supported clusters.]:[\acluster\a]'
USAGE_PARAMS+=$'[o:output?Send text-format output (currently, plaintext and CSV formats; see \vplain\v and \vcsv\v options) to output file(s). If no file name is specified, defaults to "incchk_PRI-SEC_DATE.fmt" written to the local \vfe-files\v directory, where "PRI/SEC" are the primary and secondary cluster names, "DATE" is the datestamp, and "fmt" is the output format. Plaintext output sets "fmt" to ".txt" and CSV output sets "fmt" to ".csv". \bNote:\b Data-format output (e.g JSON, see \vjson\v option), if specified, is always sent to STDOUT.]:?[\aoutfile\a]'
USAGE_PARAMS+=$'[m:map?Enable, and optionally specify, the file map. Contains a list of mappings for the same file with different names in different cluters. Exits with an error if the file cannot be found. This option is not currently supported.]:?[\a'"${MLIST}"$'\a]'
USAGE_PARAMS+=$'[w:whitelist?Enable, and optionally specify, the whitelist file. Contains a list of regular expressions for lines of files to ignore. See the \bWHITELIST\b section for more information. This option is not currently supported.]:?[\a'"${WLIST}"$'\a]'
USAGE_PARAMS+=$'[d:date?Select the comparison to run based on date. \bNote:\b the corresponding data files must exist for the given date and the date format must (currently) be in the format \aYYYYMMDD\a. This option has no affect on initial data collection (see \vfetch\v option). A default comparison date is shown.]:[\a'"${DS}"$'\a]'
USAGE_PARAMS+=$'[x:ignore?Specify a list of files to ignore from collection. These files will be skipped on the initial data collection run (see the \vfetch\v option).]:?[\a'"${CLIST}"$'\a]'
USAGE_PARAMS+=$'[X:ignore-report?Specify a list of files to ignore in the report. These files will be skipped when the report is generated (default action). This option is not currently supported.]:?[\a'"${RLIST}"$'\a]'
USAGE_PARAMS+=$'[H:no-headers?Turn off printing section headers.]'
USAGE_PARAMS+=$'[S:no-summaries?Turn off printing section summaries.]'
USAGE_PARAMS+=$'[D:no-diffs?Turn off printing file difference output.]'
USAGE_PARAMS+=$'[E:equivalent?Turn \bon\b printing file equivalencies. \bNote:\b this feature is \boff\b by defualt.]'
USAGE_PARAMS+=$'[M:no-maps?Turn off printing file mapping notifications.]'
USAGE_PARAMS+=$'[C:csv?Output CSV format rather than plain text.]'
USAGE_PARAMS+=$'[J:json?Output JSON format rather than plain text.]'
USAGE_PARAMS+=$'[P:plain?Explicitly turn on plain text output. Oh baby.]'
USAGE_PARAMS+=$'[v:verbose?Increase the verbosity of output and optionally set debugging level.]#?'"[#:=${OFF}]"
USAGE_PARAMS+=$'[+VALID CLUSTERS?The currently supported list of cluster names is:]{\fvalidClusters\f}'
USAGE_PARAMS+=$'[+WHITELIST?This option is not currently supported.]'

## Flags to notify that certain options are enabled
#
compound FLAG=(
    typeset -i csv=0
    typeset -i json=0
    typeset -i plain=0
    typeset -i fetch=0
    typeset -i clist=0
    typeset -i rlist=0
    typeset -i mlist=0
    typeset -i wlist=0
    typeset -i equals=0
    typeset -i nodiff=0
    typeset -i nohead=0
    typeset -i nosumm=0
    typeset -i output=0
)

## Data structure of directory combinations and their descriptions
#
compound DIRS=(
    typeset -a TOP=( site-profiles contrib salt salt )
    typeset -a END=( 6.6/nodes 6.6/x86_64/RPMS '' ../default )
    typeset -a SCT=( Site-Profiles Contrib Salt Default )
)

## Data structure of arrays of distributions with their host nodes and
#  descriptions
#
compound CLUSTERS=(
    compound DIST=(
	typeset -a E1=( devcluster testcluster prodcluster )
	typeset -a E2=( devclusterE2 testclusterE2 prodclusterE2 )
    )
    compound HOST=(
	typeset -a E1=( testhost-e1 devhost-e1 prodhost-e1 )
	typeset -a E2=( testhost-e2 devhost-e2 prodhost-e2 )
    )
    compound DESC=(
	typeset -a E1=( TestE1 DevE1 ProdE1 )
	typeset -a E2=( TestE2 DevE2 ProdE2 )
    )
)

## Structure from which to build JSON strings (and why we should have done this
#  in the first place! :P )
#
compound JSON=(
    typeset head="" data=""
    compound pri=(
	typeset matches="" deltas="" maps=""
    )
    compound sec=${!JSON.pri}
)

## Print out message for unsupported commands or options; exits with error with 
#  any argument supplied, using the argument(s) to show what is not supported.
#
function uns {
    if [[ -n ${1} ]]; then
	error "The '${1}' option is not currently supported."
    else
	print "This option is not currently supported."
    fi
}

## Print interesting information to STDOUT when verbosity is on.
#
verbose () {
    diag
    if (( DEBUG == VERBOSE )); then
	print "$@"
    fi
    
    return 0
}

## Print warning messages to STDERR but don't exit
#
warn () {
    diag
    
    print -u2 "${PROGNAME} warning - $@"
    
    return 0
}

## Print interesting information to STDOUT when verbosity is high
#
debug () {
    diag
    if (( DEBUG > VERBOSE )); then
	print -u2 "DEBUG: $@"
    fi
    
    return 0
}

## Report on error conditions in a standardised format to STDERR.
#  Causes program to exit with non-zero value (0 > x > 256) as
#  interpolated from ${ret_val}. 
#
function error {
    diag
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
)

## Create the ALLCAPS variables from the list of required externals
#
declareXterns () {
    typeset cmdname

    for cmdname in ${EXTERNS[@]}; do
	typeset -u CMDREF=${cmdname}
	nameref pcmdref=${CMDREF}
	
	pcmdref=$(whence ${cmdname})
	if (( $? == 0 )); then
	    readonly pcmdref
	    debug "typeset -r ${CMDREF} = ${pcmdref}"
	else
	    error "unable to resolve required external command \"${cmdname}\""
	fi
    done
    
    return ${ret_val}
}

## Make externs available or fail with an error if any can not be found
#
declareXterns

## Name of this host
#
readonly NODENAME=$(${HOSTNAME} -s)

## Read the command line parameters and intialise option variables to their
#  selected values
#
while getopts -a ${PROGNAME} "${USAGE_PARAMS}" argc; do
    case ${argc} in
	C) (( FLAG.csv = ON  ));;
	J) (( FLAG.json = ON  ));;
	P) (( FLAG.plain = ON  )) ;;
	D) (( FLAG.nodiff = ON )) ;;
	E) (( FLAG.equals = ON )) ;;
	H) (( FLAG.nohead = ON )) ;;
	M) (( FLAG.nomaps = ON )) ;;
	S) (( FLAG.nosumm = ON )) ;;
	f) (( FLAG.fetch = ON )); CLUSTOPT=${OPTARG} ;;
	d) DS=${OPTARG} ;;
	p) PRI=${OPTARG} ;;
	s) SEC=${OPTARG} ;;
	o) OUTFILE=${OPTARG}; (( FLAG.output = ON ));;
	m) MLIST=${OPTARG}; (( FLAG.mlist = ON )); uns ${argc};;
	w) WLIST=${OPTARG}; (( FLAG.wlist = ON )); uns ${argc};;
        x) CLIST=${OPTARG}; (( FLAG.clist = ON )) ;;
        X) RLIST=${OPTARG}; (( FLAG.rlist = ON )); uns ${argc};;
	v) if [[ -z ${OPTARG} ]]; then
	       (( ++DEBUG ))
	   else
	       (( DEBUG = ${OPTARG} ))
	   fi ;;
    esac
done
shift $(( --OPTIND ))

print "OUTFILE == ${OUTFILE} ; sizeof(OUTFILE) == ${#OUTFILE} ; FLAG.output == ${FLAG.output}"
