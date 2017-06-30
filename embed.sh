#!/bin/bash

PATH=/bin:/usr/bin

declare ext="extVar"

funca () {
	funcia () {
		local fed=${1};
#		${!fed}=${int}:${fed};
		eval "fed=${ext}:${!fed}"

		printf "funca: funcia fed: %s (%s)\n" ${fed} ${!fed};
		printf "funca: funcia ext: %s\n" ${ext};
		printf "funca: funcia int: %s\n" ${int};
	
		funcib
	}

	funcib () {
		printf "funca: funcib ext: %s\n" ${ext};
		printf "funca: funcib int: %s\n" ${int};
	}

	local int="intVar";
	
	funcia extVar;
}

funca;

