
('&#xa;', <flights_data>&#xa; {
  for $flight in doc("test.xml")/root/response/response return
    if (fn:exists($flight/hex) and 
        fn:exists($flight/lat) and 
        fn:exists($flight/lng) and 
        fn:exists($flight/status)) then
    (
      <flight id="{$flight/hex}">&#xa;
        <country>{
          doc("countries.xml")/root/response/response[./code = $flight/flag]/name/text()
        }</country>&#xa;
        <position>&#xa;
            <lat>{$flight/lat/text()}</lat>&#xa;
            <lng>{$flight/lng/text()}</lng>&#xa;
        </position>&#xa;
        <status>{$flight/status/text()}</status>&#xa;
        {
          if (fn:exists($flight/dep_iata)) then
          (
            <departure_airport>&#xa;
              <country>{
                doc("countries.xml")/root/response/response[./code = doc("airports.xml")/root/response/response[./iata_code = $flight/dep_iata[position() = 1]]/country_code]/name/text()
              }</country>&#xa;
              <name>{
                doc("airports.xml")/root/response/response[./iata_code = $flight/dep_iata[position() = 1]]/name/text()
              }</name>&#xa;
            </departure_airport>
          )
          else ()
        }&#xa;
        {
          if (fn:exists($flight/arr_iata)) then
            (<arrival_airport>&#xa;
            <country>{
              doc("countries.xml")/root/response/response[./code = doc("airports.xml")/root/response/response[./iata_code = $flight/arr_iata[position() = 1]]/country_code]/name/text()
            }</country>&#xa;
            <name>{
              doc("airports.xml")/root/response/response[./iata_code = $flight/arr_iata[position() = 1]]/name/text()
            }</name>&#xa;
            </arrival_airport>)
          else ()
        }&#xa;
        </flight>,'&#xa;'
    )
    else
    (
      <error>Unknown error when retrieving data.</error>
    )
  }
</flights_data>)
