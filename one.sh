#!/bin/bash

declare MODNAME="one_rec";

source ./rec.sh;
source ./dup.sh;

function loopit {
	local -i idx;
	local upset;

	rec H first second third;
#	echo  first second third;
	
	for (( idx = 0 ; idx < 10 ; ++idx )); do
#		echo  ${idx} $(( ++idx )) $(( ++idx ));
		if (( idx == 9 )); then
			rec D "one" "two" "three"
			(( ++idx ));
			(( ++idx ));
		else
			rec D ${idx} $(( ++idx )) $(( ++idx ));
		fi;
	done;
	
#	echo  "done"
	rec P;
	dupit "one";
}

loopit;

