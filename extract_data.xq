declare function local:getAirCountry($iata as xs:string) as node()
{
    <country>{doc("countries.xml")/root/response/response[./code = doc("airports.xml")/root/response/response[./iata_code = $iata]/country_code]/name/text()}</country>
};

declare function local:getAirName($iata as xs:string) as node()
{
    (: I use /text() because if there is no airport name listed, instead of returning
        an empty sequence (which causes errors), it returns an empty node :)
    <name>doc("airports.xml")/root/response/response[./iata_code = $iata]/name/text()</name>
};

declare function local:getDep($flight as element(response)) as node()
{
    <departure_airport>
        {local:getAirCountry($flight/dep_iata[position() = 1])}
        {local:getAirName($flight/dep_iata[position() = 1])}
    </departure_airport>
};

declare function local:getArr($flight as element(response)) as node()
{
    <arrival_airport>
        {local:getAirCountry($flight/arr_iata[position() = 1])}
        {local:getAirName($flight/arr_iata[position() = 1])}
    </arrival_airport>
};

declare function local:getFlight($flight as element(response)) as node()
{
    <flight id="{$flight/hex}">
        <country>{ doc("countries.xml")/root/response/response[./code = $flight/flag]/name/text() }</country>
        <position>
            {$flight/lat}
            {$flight/lng}
        </position>
        {$flight/status}
        {if (fn:exists($flight/dep_iata))
            then local:getDep($flight)
            else ()}
        {if (fn:exists($flight/arr_iata))
            then local:getArr($flight)
            else ()}
    </flight>
};

<flights_data>
{
    if (every $flight in doc("flights.xml")/root/response/response satisfies 
        (fn:exists($flight/hex) and 
        fn:exists($flight/lat) and 
        fn:exists($flight/lng) and 
        fn:exists($flight/status)))
    then
        for $flight in doc("flights.xml")/root/response/response
        return local:getFlight($flight)
    else <error>Unknown error when retrieving data.</error>
}
</flights_data>
