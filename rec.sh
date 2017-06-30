# rec library

# source ./dup.sh;

declare -a _REC_HEADER _REC_DATA;
declare _REC_JSON;

function rec {
    append_string () {
	local -i idx;

	if (( ${#_REC_HEADER[@]} != ${#_REC_DATA[@]} )); then
	    echo "error: wrong number of data arguments to 'D'";
	    echo "error: H ${_REC_HEADER[*]}";
	    echo "error: D ${_REC_DATA[*]}";
	    exit 1;
	fi;
	
	for (( idx = 1 ; idx < ${#_REC_HEADER[@]} ; ++idx )); do
	    _REC_JSON+="\"${_REC_HEADER[$idx]}\":";
	    if [[ ${_REC_DATA[$idx]} =~ [[:alpha:][:space:]_/*] ]]; then
		_REC_JSON+="\"${_REC_DATA[$idx]}\",";
	    elif [[ ${_REC_DATA[$idx]} =~ '.' ]]; then
		_REC_JSON+="${_REC_DATA[$idx]},";
	    else
		_REC_JSON+="${_REC_DATA[$idx]},";
	    fi;
	done;
    }

    print_json () {
	printf "{\"bdmon\":\"%s\",\"data\":[{%s}]}\n" "${MODNAME}" "${_REC_JSON%,}";
	unset _REC_JSON;
	unset _REC_HEADER;
	unset _REC_DATA;
    }
    
    case ${1} in
	H) _REC_HEADER=( $@ ) ;;
	D) _REC_DATA=( $@ ); append_string ;;
	P) print_json; dupit "rec" ;;
	*) echo "error: no such operator ${1}"; exit 1 ;;
    esac
}
