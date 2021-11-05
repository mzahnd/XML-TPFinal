
('&#xa;', <flights_data> &#xa;
    { for $flight in doc("flights.xml")/root/response/response
    return <flight id="{$flight/hex}">&#xa;
        <country>{doc("countries.xml")/root/response/response[./code = $flight/flag]/name/text()}</country>&#xa;
        <position>&#xa;
            <lat>{$flight/lat/text()}</lat>&#xa;
            <lng>{$flight/lng/text()}</lng>&#xa;
        </position>&#xa;
        <status>{$flight/status/text()}</status>&#xa;
        {
            if (fn:exists($flight/dep_iata)) then
        (<departure_airport>&#xa;
            <country>{doc("countries.xml")/root/response/response[./code = doc("airports.xml")/root/response/response[./iata_code = $flight/dep_iata]/country_code]/name/text()}</country>&#xa;
            <name>{doc("airports.xml")/root/response/response[./iata_code = $flight/dep_iata]/name/text()}</name>&#xa;
        </departure_airport>,'&#xa;')
        else ()
        }
        {
            if (fn:exists($flight/arr_iata)) then
        (<arrival_airport>&#xa;
            <country>{doc("countries.xml")/root/response/response[./code = doc("airports.xml")/root/response/response[./iata_code = $flight/arr_iata]/country_code]/name/text()}</country>&#xa;
            <name>{doc("airports.xml")/root/response/response[./iata_code = $flight/arr_iata]/name/text()}</name>&#xa;
        </arrival_airport>, '&#xa;')
        else ()
        }
    </flight>}
</flights_data>)