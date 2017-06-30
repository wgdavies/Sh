#!/bin/ksh

compound JSON=(
    typeset head data total
    compound pri=(
	typeset matches="" deltas="" maps=""
    )
    compound sec=${!JSON.pri}
)

JSON.pri.matches="\"first\",\"second\""
# JSON.sec.matches=${JSON.pri.matches}
print "JSON.pri.matches == ${JSON.pri.matches}"
print "JSON.sec.matches == ${JSON.sec.matches}"
print "JSON.pri struct == ${#JSON.pri.*} : ${!JSON.pri.*}"
print "JSON.sec struct == ${#JSON.sec.*} : ${!JSON.sec.*}"
