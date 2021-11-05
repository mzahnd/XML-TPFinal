#!/usr/bin/bash

shopt -s extglob

readonly AIRLABS_API_KEY="$(cat apikey.txt)"

readonly FAIRPORTS='airports.xml'
readonly FCOUNTRIES='countries.xml'
readonly FFLIGHTS='flights.xml'

readonly FXSLT='generate_report.xsl'
readonly FXQ='extract_data.xq'
readonly FXSD_XML='flights_data.xml'

readonly TEX_OUTPUT='report.tex'


FETCH=true
MAX=0

function usage() {
cat <<EOF
Usage: ${0##*/} [OPTION]

OPTIONS:
    [-]qty=N        Maximum number of flights to include in the final document.

    [-]no-fetch     Do not fetch new data from AirLabs Data API. Uses only
                    local files, failing if at least one does not exist.

    [-]h            This message.
EOF
}

function fetch_data() {
    echo "fetch"

    local ret=0

    echo "Fetching '$FAIRPORTS'..."
    curl \
        "https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FAIRPORTS"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FAIRPORTS'."
    
    echo "Fetching '$FCOUNTRIES'..."
    curl \
        "https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FCOUNTRIES"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FCOUNTRIES'."
    
    echo "Fetching '$FFLIGHTS'..."
    curl \
        "https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FFLIGHTS"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FFLIGHTS'."

    [ $ret -eq 0 ] && echo "All files fetched successfully" || echo "Aborting"

    return 0
}

function check_files() {
    echo "check"

    local ret=0

    for fname in "$FAIRPORTS" "$FCOUNTRIES" "$FFLIGHTS"; do
        if [ ! -f "$fname" ]; then
           echo "Missing XML file '${fname}'."
           ret=1
        fi
    done

    [ $ret -gt 0 ] && echo "Aborting."

    return $ret
}

function gen_tex() {
    local xslt_with_params="$FXSLT"

    echo "xslt with qty=${MAX}"

    # XQuery
    java net.sf.saxon.Query "$FXQ" > "$FXSD_XML"

    # XSLT
    [ $MAX -gt 0 ] && xslt_with_params="$xslt_with_params qty=$MAX"

    java net.sf.saxon.Transform         \
        -s:"$FXSD_XML"                  \
        -xsl:"$xslt_with_params"        \
        -o:"$TEX_OUTPUT"

    return 0
}

for (( i=1; i <= ${#}; i++ )); do
    case "${!i,,}" in
        ?(-)qty\=+([0-9]))
            MAX="$(echo "${!i,,}" | awk -F= '{print $2}')"
            ;;
        ?(-)no-fetch)
            FETCH=false
            ;;
        "") ;;
        *) usage
           exit 1
           ;;
    esac
done

if ( $FETCH ); then
    fetch_data
fi

[ $? -eq 0 ] && check_files && gen_tex

exit $?
