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


VERBOSE=false
FETCH=true
MAX=0

function usage() {
cat <<EOF
Usage: ${0##*/} [OPTION]

OPTIONS:
    [-]qty=N        Maximum number of flights to include in the final document.

    [-]no-fetch     Do not fetch new data from AirLabs Data API. Uses only
                    local files, failing if at least one does not exist.

    [-]verbose      
    -v              Print extra information to stdout.

    [-]h            This message.
EOF
}

# Get XML files from AirLabs API
function fetch_data() {
    local ret=0

    ($VERBOSE) && echo "Fetching '$FAIRPORTS'..."
    curl \
        "https://airlabs.co/api/v9/airports.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FAIRPORTS"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FAIRPORTS'."
    
    ($VERBOSE) && echo "Fetching '$FCOUNTRIES'..."
    curl \
        "https://airlabs.co/api/v9/countries.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FCOUNTRIES"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FCOUNTRIES'."
    
    ($VERBOSE) && echo "Fetching '$FFLIGHTS'..."
    curl \
        "https://airlabs.co/api/v9/flights.xml?api_key=${AIRLABS_API_KEY}" \
        > "$FFLIGHTS"
    [ $? -ne 0 ] && ret=1 && echo "Could not fetch '$FFLIGHTS'."

    if [ $ret -eq 0 ] && ($VERBOSE); then
        echo "All files successfully retrieved from AirLabs API."
    fi

    return $ret
}

# Needed files have read permission
function check_files() {
    local ret=0

    for fname in "$FAIRPORTS" "$FCOUNTRIES" "$FFLIGHTS"; do
        if [ ! -r "$fname" ]; then
           echo "Missing XML file '${fname}' or wrong permissions."
            # Keep testing files, so the user knows how many of them is missing
           ret=1
        fi
    done

    return $ret
}

# xQuery query using Saxon
# Encodes in UTF-16 and indents the resulting XML
function ev_xquery()
{
    ($VERBOSE) && echo "Evaluating xQuery query in '$FXQ'..."
    if ! java net.sf.saxon.Query    \
        "$FXQ"                      \
        !encoding="UTF-16"          \
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

# XSLT transformation using Saxon
function transform_xslt()
{
    local xslt_with_params="$FXSLT"

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
        ?(-)no-fetch)
            FETCH=false
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

# Verify files and run xQuery query and XSLT transformation.
[ $? -eq 0 ] \
    && check_files && ev_xquery && transform_xslt \
    || (echo "Aborted script execution."; exit 1)

exit $?
