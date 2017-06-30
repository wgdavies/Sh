#!/bin/ksh

PATH=/bin:/usr/bin

typeset -i ret_val=0

alias diag=''
#set +o nounset
#alias diag='set -o xtrace'
#PS4='${.sh.fun}($@): ${LINENO} @ ${SECONDS}s xtrace> '

typeset -i count idx jdx

typeset -C TIME=(
	typeset -il ee
	typeset -ril cur=$(printf '%(%s)T' now)
)

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

typeset -C DIRS=(
    typeset -a TOP=( site-profiles contrib salt )
    typeset -a END=( 6.6/nodes 6.6/x86_64/RPMS '' )
)

function error {
print -u2 "error return ${ret_val}"
	diag
	print -u2 "ERROR: $@" && false
	(( ret_val = 4 ))
print -u2 "error return ${ret_val}"
	exit ${ret_val}
print -u2 "error return ${ret_val}"
}

(( TIME.ee = (( TIME.cur + 43210 )) ))

printf "current time: %s (%d)\nest.end time: %s (%d)\n" "$(printf '%(%F %T)T' '#'${TIME.cur})" ${TIME.cur} "$(printf '%(%F %T)T' '#'${TIME.ee})" ${TIME.ee}

typeset TLD="export/rocks"
typeset env

# for (( count = 0 ; count < 3 ; ++count )); do
#     nameref dirsadd=DIRS.CNT${count}
#     dirsadd=( a${count} b${count} )
# done

# for dircnt in ${!DIRS.CNT*}; do
#     nameref dircntelem=${dircnt}
#     print "${dircnt} ${#dircntelem[@]} elements: ${dircntelem[*]}"
# done

typeset DS=20161219
typeset PRI=test
typeset SEC=dev

function comparePS {
diag
typeset cfile fpath section secfile lpath=build
typeset -a mdlist misslist maplist maptemp
typeset -i tmatches=0 tmisses=0 smatches=0 smisses=0 tmaps=0 smaps=0 stotal=0 ttotal=0 count=0 cnt=0 idx=0 jdx=0 kdx=0
typeset mmm=( # data structure for misses, matches, and maps
    typeset -a mapfile0 # cluster map MD5sum field [0] and file name [1]
    typeset -a match0 # cluster matches MD5sum field [0] and file name [1]
    typeset -a miss0 # cluster misses MD5sum field [0] and file name [1]
    typeset -i mapcnt=0 # index counter for mapfiles
    typeset -i matcnt=0 # index counter for matches
    typeset -i miscnt=0 # index counter for misses
)
typeset -C pri=( # data strcture type for primary/secondary cluster files
    typeset -a sumfile0 # cluster file MD5sum field [0] and file name [1]
)
typeset -C sec=${pri}

slurpDF () { # pull the primary and secondary data files into memory
    typeset clusterinfo=${1}
    typeset clusterfile=${2}
    typeset -a cluster
    typeset -i idx=0

    while read -A cluster; do
	nameref sum=${clusterinfo}${idx}[0]
	nameref cfp=${clusterinfo}${idx}[1]
	sum=${cluster[0]}
	cfp=${cluster[1]}
	(( ++idx ))
    done < ${clusterfile}
}

slurpDF pri.sumfile ${lpath}/${PRI}.${DS}
slurpDF sec.sumfile ${lpath}/${SEC}.${DS}

for (( idx = 0 ; idx < ${#pri.sumfile*} ; ++idx )); do
    nameref prisf=pri.sumfile${idx}

    for (( jdx = 0 ; jdx < ${#sec.sumfile*} ; ++jdx )); do
	nameref secsf=sec.sumfile${jdx}

	if [[ ${prisf[0]} == ${secsf[0]} ]]; then
	    if [[ ${prisf[1]} == ${secsf[1]/$SEC/$PRI} ]]; then
		(( ++mmm.matcnt ))
		nameref fm=mmm.match${mmm.matcnt}
		fm[0]=${prisf[0]}
		fm[1]=${prisf[1]}
		break
	    else
		(( ++mmm.mapcnt ))
		nameref mf=mmm.mapfile${mmm.mapcnt}
		mf[0]=${prisf[1]}
		mf[1]=${secsf[1]}
		break
	    fi
	else
	    (( ++kdx ))
	fi
    done

    if (( kdx == ${#sec.sumfile*} )); then
	(( ++mmm.miscnt ))
	nameref mi=mmm.miss${mmm.miscnt}
	mi[0]=${prisf[1]}
    fi

    (( kdx = 0 ))
done

for index in mapcnt matcnt miscnt; do
    nameref mcnt=mmm.${index}

    if (( mcnt > 0 )); then
	case ${!mcnt} in
	    mmm.mapcnt) mfile=mapfile;; # print "mapfiles: ${mcnt}" ;;
	    mmm.matcnt) mfile=match;; # print "matches: ${mcnt}" ;;
	    mmm.miscnt) mfile=miss;; # print "misses: ${mcnt}" ;;
	    *) error "data structure mismatch" ;;
	esac
	
	for (( cnt = 1 ; cnt <= mcnt ; ++cnt )); do
#	    print "cnt = ${cnt}"
	    nameref pmfile0=mmm.${mfile}${cnt}[0]
	    nameref pmfile1=mmm.${mfile}${cnt}[1]

	    case ${!mcnt} in
		mmm.mapcnt) print "map ${cnt}: ${pmfile0/$PRI\/..\//} ${pmfile1/$SEC\/..\//}" ;;
		mmm.matcnt) print "match ${cnt}: ${pmfile1/$PRI\/..\//}" ;;
		mmm.miscnt) print "miss ${cnt}: ${pmfile0/$PRI\/..\//}" ;;
		*) error "another data structure mismatch" ;;
	    esac	    
	done
    fi
done
    
#    if (( mcnt > 0 )); then
#	print "${!mcnt}: ${mcnt}"
#    fi

}

## Search the cluster struct to identify clusters
#
#  With no argument, lists all cluster names with descriptions.
#  Accepts cluster or FE-node name or description as argument.
#  Returns an array of:
#    cluster-name cluster-description cluster-host
#  if the name matches a known cluster.
#  Returns success or error if no match(es) found. 
#
function validClusters {
    diag
    typeset cname cluster=${1}
    typeset -i found=0
    
    if (( ${#CLUSTERS.DIST.*} == ${#CLUSTERS.DESC.*} )); then
	if [[ -z ${cluster} ]]; then
	    for cname in ${!CLUSTERS.DIST.*}; do
		nameref pcname=${cname}
		nameref pcdesc=${cname/DIST/DESC}
		nameref pchost=${cname/DIST/HOST}

		for (( count = 0 ; count < ${#pcname[@]} ; ++count )); do
		    printf "[%s?(Refers to: %s on %s)]" "${pcname[$count]}" "${pcdesc[$count]}" "${pchost[$count]}"
		done
	    done
	else
	    for cname in ${!CLUSTERS.DIST.*}; do
		nameref pcname=${cname}
		nameref pcdesc=${cname/DIST/DESC}
		nameref pchost=${cname/DIST/HOST}

		for (( count = 0 ; count < ${#pcname[@]} ; ++count )); do
		    if [[ ${pcname[$count]}.${pcdesc[$count]}.${pchost[$count]} =~ ${cluster} ]]; then
			print ${pcname[$count]} ${pcdesc[$count]} ${pchost[$count]}
			(( ++found ))
			break
		    fi
		done

		(( found == 1 )) && break
	    done
	    
	    if (( found != 1 )); then
		error "invalid cluster name: ${cluster}"
	    fi
	fi
    else
	error "mismatch in CLUSTERS structure; please verify elements"
    fi

    return ${ret_val}
}

pubfunc () {
	diag
	print "in pubfunc(): ${@}"
}

function privfunc { 
	diag
	print "in privfunc(): ${@}"
#thisshouldfail
}

set -e
typeset -a clust
print "return ${ret_val}"
clust=( $(validClusters devcluster) )
print "set $?"
print "return ${ret_val}"
pubfunc ${clust[@]}
print "return ${ret_val}"
privfunc ${clust[@]}
print "return ${ret_val}"
return ${ret_val}
set +e
