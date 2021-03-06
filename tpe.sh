#!/usr/bin/bash

shopt -s extglob

# AirLabs API Key
[ -z "$AIRLABS_API_KEY" ]

if [ -z "$AIRLABS_API_KEY" ]; then
    echo -n "Environment variable AIRLABS_API_KEY not set. "
    echo "Please provide an API key using"
    echo "export AIRLABS_API_KEY='<api-key-here>'"

    exit 1
fi

readonly FAIRPORTS='airports.xml'
readonly FCOUNTRIES='countries.xml'
readonly FFLIGHTS='flights.xml'

readonly FXSLT='generate_report.xsl'
readonly FXQ='extract_data.xq'
readonly FXSD='flights_data.xsd'
readonly FXSD_XML='flights_data.xml'

readonly TEX_OUTPUT='report.tex'

VERBOSE=false
FETCH=true
VERIFY_XSD=false
TRANS_XSL=true
QUERY_XQ=true
MAX=0

function usage() {
cat <<EOF
Usage: ${0##*/} [OPTION]

The script requires an environment variable calleed AIRLABS_API_KEY with
AirLabs provided API key.

It can be provided using the following command before running the script:

    export AIRLABS_API_KEY='<api-key-here>'


OPTIONS:
    [-]qty=N        Maximum number of flights to include in the final document.

    [-]xsd-check    Use '$FXSD' XSD file to validate the query output.

    [-]no-fetch     Do not fetch new data from AirLabs Data API. Uses only
                    local files, failing if at least one does not exist.

    [-]only-xsl     Only performs the XSL transformation and generates the
                    report file. Implies 'no-fetch'.

    [-]only-query   Only performs the XQuery query and generates the flight's
                    data file.

    [-]verbose      
    -v              Print extra information to stdout.

    [-]h
    [--]help        This message.
EOF
}

function is_readable() {
    [ ! -r "$1" ] \
        && echo "Missing file '${1}' or wrong permissions." \
        && return 1

    return 0
}

# Get XML files from AirLabs API
function fetch_data() {
    local ret=0

    local curl_args=("--silent" "--show-error")
    ($VERBOSE) && curl_args=()

    ($VERBOSE) && echo "Fetching '$FAIRPORTS'..."
    curl "${curl_args[@]}" \
        "https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FAIRPORTS"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FAIRPORTS'."
    
    ($VERBOSE) && echo "Fetching '$FCOUNTRIES'..."
    curl "${curl_args[@]}" \
        "https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FCOUNTRIES"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FCOUNTRIES'."
    
    ($VERBOSE) && echo "Fetching '$FFLIGHTS'..."
    curl "${curl_args[@]}" \
        "https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FFLIGHTS"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FFLIGHTS'."

    if [ $ret -eq 0 ] && ($VERBOSE); then
        echo "All files successfully retrieved from AirLabs API."
    fi

    return $ret
}

# Needed files have read permission
function check_essential_files() {
    local ret=0
    local files=("$FXSLT" "$FXQ")

    # Only the query needs this files.
    ($QUERY_XQ) && files+=("$FAIRPORTS" "$FCOUNTRIES" "$FFLIGHTS")

    ($VERIFY_XSD || $QUERY_XQ) && files+=("$FXSD")

    for fname in ${files[@]}
    do
        if ! is_readable "$fname"; then
            # Keep testing files, so the user knows how many of them is missing
            ret=1
        fi
    done

    return $ret
}

# XQuery query using Saxon
# Encodes in UTF-16 and indents the resulting XML
function ev_xquery()
{
    # Perform query?
    (! $QUERY_XQ) && return 0

    ($VERBOSE) && echo "Evaluating XQuery query in '$FXQ'..."
    if ! java net.sf.saxon.Query    \
        "$FXQ"                      \
        !indent="yes"               \
        > "$FXSD_XML"                                  
        then
        [ -f "$FXSD_XML" ] && rm "$FXSD_XML"
        echo -n "Saxon Query failed while evaluating file. "
        echo "File '$FXSD_XML' NOT generated"
        return 1
    fi
    
    ($VERBOSE) && echo "Successfully generated file '$FXSD_XML'"

    return 0
}

# Verify output XML from XQuery using a XSD
function xsd_check()
{
    # Perform check?
    (! $VERIFY_XSD) && return 0

    local err_msg=""

    # Needed files
    ! is_readable "$FXSD_XML" && return 1

    echo "Verifying file '$FXSD_XML'..."
    err_msg="$(java sax.Writer -v -n -s -f "$FXSD_XML" 2>&1 1> /dev/null)"

    if [ -n "$err_msg" ]
    then
        echo "$err_msg"
        echo "XSD Verification failed."
        return 1
    fi

    echo "Success. File '$FXSD_XML' validated with '$FXSD'."

    return 0
}

# XSLT transformation using Saxon
function transform_xslt()
{
    local xslt_with_params="$FXSLT"

    # Perform transformation?
    (! $TRANS_XSL) && return 0

    # Needed files
    ! is_readable "$FXSD_XML" && return 1

    # Append 'qty' to XSLT command
    [ $MAX -gt 0 ] && xslt_with_params="$xslt_with_params qty=$MAX"

    ($VERBOSE) && echo -n "Executing XSLT transformation by calling "
    ($VERBOSE) && echo "'$xslt_with_params' with '$FXSD_XML'..."

    if ! java net.sf.saxon.Transform    \
        -s:"$FXSD_XML"                  \
        -xsl:$xslt_with_params          \
        -o:"$TEX_OUTPUT"
    then
        [ -f "$TEX_OUTPUT" ] && rm "$TEX_OUTPUT"
        echo "Saxon Transform failed. File '$TEX_OUTPUT' NOT generated."
        return 1
    fi
    
    ($VERBOSE) && echo "Successfully generated file '$TEX_OUTPUT'" \

    return 0

}

# Script arguments
for (( i=1; i <= ${#}; i++ )); do
    case "${!i,,}" in
        ?(-)qty\=+([0-9]))
            MAX="$(echo "${!i,,}" | awk -F= '{print $2}')"
            ;;
        ?(-)xsd-check)
            VERIFY_XSD=true
            ;;
        ?(-)no-fetch)
            FETCH=false
            ;;
        ?(-)only-xsl)
            FETCH=false
            TRANS_XSL=true
            QUERY_XQ=false
            ;;
        ?(-)only-query)
            TRANS_XSL=false
            QUERY_XQ=true
            ;;
        ?(-)verbose|-v)
            VERBOSE=true
            ;;
        "") ;;
        *) usage
           exit 1
           ;;
    esac
done

# Fetch data from the API
if ( $FETCH ); then
    fetch_data
fi

# Verify files and run XQuery query and XSLT transformation.
[ $? -eq 0 ] \
    && check_essential_files && ev_xquery && xsd_check && transform_xslt \
    || (echo "Aborted script execution."; exit 1)

exit $?
