#!/bin/ksh

typeset word=${1} prword
typeset -li idx jdx kdx perms

function .sh.math.fac n {
	typeset -li f=1 i

	for (( i = 2 ; i <= n ; ++i )); do
		(( f *= i ))
	done

	(( .sh.value = f ))
}

function swaprl { 
	typeset sword=${1} newsword
#	integer llet=${2} rlet rest
	integer llet=${2} rlet=${3} rest
	
	(( llet = llet % ${#sword} ))
	(( rlet = rlet % ${#sword} ))
#	(( rlet = (( llet + 1 )) % ${#sword} ))
	newsword=${sword:$rlet:1}${sword:$llet:1}
	
	for (( rest = 0 ; rest < ${#sword} ; ++rest )); do
		if (( rest != llet )) && (( rest != rlet )); then
			newsword+=${word:$rest:1}
		fi
	done
	
	print "${newsword}"
}

(( perms = fac(${#word}) ))

for (( idx = 0 ; idx < perms ; ++idx )); do
#	word=$(swaprl ${word} ${idx})

	for (( jdx = 0 ; jdx < ${#word} ; ++jdx )); do
#		(( kdx = (( idx + jdx )) % ${#word} ))
		(( kdx = idx % ${#word} ))
# set -x
#		prword+=${word:$jdx:1}
#		prword+=${word:$kdx:1}
#		prword=${word}
		if (( kdx != jdx )); then
			prword=$(swaprl ${word} ${kdx} ${jdx})
	word=${prword}
	print ${prword}
	prword=""
		fi
# set +x
	done

#	word=${prword}
#	print ${prword}
#	word=$(swaprl ${word} ${idx})
#	word=$(swaprl ${word} $(( idx + 1 )))
#	prword=""
done

