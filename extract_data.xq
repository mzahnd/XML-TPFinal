<flights_data xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:noNamespaceSchemaLocation="flights_data.xsd">
    { for $flight in doc("flights.xml")/root/response/response
    order by $flight/hex 
    return <flight id="{$flight/hex}">
        <country>{doc("countries.xml")/root/response/response[./code = $flight/flag]/name/text()}</country>
        <position>
            <lat>{$flight/lat/text()}</lat>
            <lng>{$flight/lng/text()}</lng>
        </position>
        <status>{$flight/status/text()}</status>
        {
            if (fn:exists($flight/dep_iata)) then
        <departure_airport>
            <country>{doc("countries.xml")/root/response/response[./code = doc("airports.xml")/root/response/response[./iata_code = $flight/dep_iata]/country_code]/name/text()}</country>
            <name>{doc("airports.xml")/root/response/response[./iata_code = $flight/dep_iata]/name/text()}</name>
        </departure_airport>
        else ()
        }
        {
            if (fn:exists($flight/arr_iata)) then
        <arrival_airport>
            <country>{doc("countries.xml")/root/response/response[./code = doc("airports.xml")/root/response/response[./iata_code = $flight/arr_iata]/country_code]/name/text()}</country>
            <name>{doc("airports.xml")/root/response/response[./iata_code = $flight/arr_iata]/name/text()}</name>
        </arrival_airport>
        else ()
        }
    </flight>}
</flights_data>