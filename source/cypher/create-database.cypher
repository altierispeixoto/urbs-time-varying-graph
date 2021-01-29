
MATCH (n) DETACH DELETE n;
MATCH ()-[r]-() DELETE r;

create constraint on (y:Year) ASSERT y.value IS UNIQUE;
CREATE INDEX ON :Month(value);
CREATE INDEX ON :Day(value);
CREATE INDEX ON :Hour(value);
CREATE INDEX ON :Trip(line_way);
CREATE INDEX ON :Line(line_code);
CREATE INDEX ON :Event(vehicle, event_timestamp);


//Create Time Tree with Day Depth
WITH range(2019, 2020) AS years, range(1,12) AS months
FOREACH(year IN years |
  CREATE (y:Year {value: year})
  FOREACH(month IN months |
    CREATE (m:Month {value: month})
    MERGE (y)-[:CONTAINS]->(m)
    FOREACH(day IN (CASE
                      WHEN month IN [1,3,5,7,8,10,12] THEN range(1,31)
                      WHEN month = 2 THEN
                        CASE
                          WHEN year % 4 <> 0 THEN range(1,28)
                          WHEN year % 100 = 0 AND year % 400 = 0 THEN range(1,29)
                          ELSE range(1,28)
                        END
                      ELSE range(1,30)
                    END) |
      CREATE (d:Day {value: day})
      MERGE (m)-[:CONTAINS]->(d))));

//Create Time Tree with Hour Depth
match(y:Year)-[:CONTAINS]->(m:Month)-[:CONTAINS]->(d:Day)
WITH collect(d) AS days
  FOREACH(d IN days  |
     FOREACH (hour in range(0,23) |
       CREATE (h:Hour {value: hour})
       MERGE (d)-[:CONTAINS]->(h)));


//Connect Years Sequentially
MATCH (year:Year)
WITH year
ORDER BY year.value
WITH collect(year) AS years
  FOREACH(i in RANGE(0, length(years)-2) |
    FOREACH(year1 in [years[i]] |
      FOREACH(year2 in [years[i+1]] |
        CREATE UNIQUE (year1)-[:NEXT]->(year2))));


//Connect Months Sequentially
MATCH (year:Year)-[:CONTAINS]->(month)
WITH year, month
ORDER BY year.value, month.value
  WITH collect(month) AS months
    FOREACH(i in RANGE(0, length(months)-2) |
      FOREACH(month1 in [months[i]] |
        FOREACH(month2 in [months[i+1]] |
          CREATE UNIQUE (month1)-[:NEXT]->(month2))));


//Connect Days Sequentially
MATCH (year:Year)-[:CONTAINS]->(month)-[:CONTAINS]->(day)
WITH year, month, day
ORDER BY year.value, month.value, day.value
WITH collect(day) AS days
FOREACH(i in RANGE(0, length(days)-2) |
    FOREACH(day1 in [days[i]] |
        FOREACH(day2 in [days[i+1]] |
            CREATE UNIQUE (day1)-[:NEXT]->(day2))));


// Connect Hours Sequentially
MATCH (year:Year)-[:CONTAINS]->(month)-[:CONTAINS]->(day)-[:CONTAINS]->(hour)
WITH year, month, day, hour
ORDER BY year.value, month.value, day.value, hour.value
WITH collect(hour) AS hours
FOREACH(i in RANGE(0, length(hours)-2) |
    FOREACH(hour1 in [hours[i]] |
        FOREACH(hour2 in [hours[i+1]] |
            CREATE UNIQUE (hour1)-[:NEXT]->(hour2))));


LOAD CSV WITH HEADERS FROM 'file:///neighborhoods/bairros.csv' AS row
MERGE (n:Neighborhood {code: row.code,name: row.name, section_code: row.section_code, section_name: row.section_name, h3_index10: row.h3_index10 })
return count(*);


LOAD CSV WITH HEADERS FROM 'file:///color/2019-05-06/color.csv' AS row
MERGE (c:Color {value: row.color})
return count(*);

LOAD CSV WITH HEADERS FROM 'file:///service_category/2019-05-06/service_category.csv' AS row
MERGE (s:ServiceCategory {value: row.service_category})
return count(*);

USING PERIODIC COMMIT 20000
LOAD CSV WITH HEADERS FROM 'file:///lines/2019-05-06/lines.csv' AS row
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})
MATCH (c:Color {value:row.color})
MATCH (s:ServiceCategory {value:row.service_category})
with d,c,s,row
MERGE (l:Line {line_code: row.line_code, line_name: row.line_name,card_only:row.card_only})
MERGE (d)-[:HAS_LINE]->(l)
MERGE (l)-[:HAS_COLOR]->(c)
MERGE (l)-[:HAS_SERVICE_CATEGORY]-(s)
return count(*);


LOAD CSV WITH HEADERS FROM 'file:///bus_stop_type/2019-05-06/bus_stop_type.csv' AS row
MERGE (t:BusStopType {value: row.type})
return count(*);




USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM 'file:///bus_stops/2019-05-06/bus_stops.csv' AS row
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})-[:HAS_LINE]->(l:Line {line_code: row.line_code})
MATCH (bst:BusStopType {value: row.type})
WITH bst, row, l
MERGE (bs:BusStop {number: row.number, name: row.name, latitude: row.latitude, longitude:row.longitude, neighborhood_code: row.code, h3_index10:row.h3_index10 })
MERGE (l)-[:HAS_TRIP]->(t:Trip {line_way:row.line_way})
MERGE (t)-[:HAS_BUS_STOP]->(bs)
MERGE (bs)-[:HAS_TYPE]->(bst)
return count(*);

USING PERIODIC COMMIT 20000
LOAD CSV WITH HEADERS FROM 'file:///trip_endpoints/2019-05-01/trip_endpoints.csv' AS row
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})-[:HAS_LINE]->(l:Line {line_code: row.line_code})-[:HAS_TRIP]->(t:Trip {line_way:row.line_way})
MATCH (t)-[:HAS_BUS_STOP]->(bss:BusStop {number:row.start_point})
MATCH (t)-[:HAS_BUS_STOP]->(bse:BusStop {number:row.end_point})
MERGE (t)-[:STARTS_ON_POINT]->(bss)
MERGE (t)-[:ENDS_ON_POINT]->(bse)
return count(*);


USING PERIODIC COMMIT 20000
LOAD CSV WITH HEADERS FROM 'file:///line_routes/2019-05-01/line_routes.csv' AS row
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})-[:HAS_LINE]->(l:Line {line_code: row.line_code})-[:HAS_TRIP]->(t:Trip {line_way:row.line_way})
MATCH (t)-[:HAS_BUS_STOP]->(bss:BusStop {number:row.start_point})
MATCH (t)-[:HAS_BUS_STOP]->(bse:BusStop {number:row.end_point})
MERGE (bss)-[r:NEXT_STOP {line_code: row.line_code, line_way: row.line_way}]->(bse)
ON CREATE SET
    r.distance = distance(point({longitude: toFloat(bss.longitude),latitude: toFloat(bss.latitude) ,crs: 'wgs-84'})
    ,point({longitude: toFloat(bse.longitude),latitude: toFloat(bse.latitude) ,crs: 'wgs-84'}))
return count(*);

USING PERIODIC COMMIT 30000
LOAD CSV WITH HEADERS FROM 'file:///events/2019-05-01/events.csv' AS row
CREATE (ev:Event {vehicle: row.vehicle, moving_status: row.moving_status, event_timestamp:row.event_timestamp,latitude:row.latitude, longitude: row.longitude, avg_velocity: row.avg_velocity})
return count(*);


USING PERIODIC COMMIT 30000
LOAD CSV WITH HEADERS FROM 'file:///events/2019-05-01/events.csv' AS row
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})-[:HAS_LINE]->(l:Line {line_code: row.line_code})-[:HAS_TRIP]->(t:Trip {line_way:row.line_way})
MATCH (ev:Event {vehicle: row.vehicle, event_timestamp:row.event_timestamp})
WITH  ev, t
MERGE (t)-[:HAS_EVENT]->(ev)
return count(*);


USING PERIODIC COMMIT 30000
LOAD CSV WITH HEADERS FROM 'file:///events/2019-05-01/events.csv' AS row
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})-[:CONTAINS]->(h:Hour {value:toInteger(row.hour)})
MATCH (ev:Event {vehicle: row.vehicle, event_timestamp:row.event_timestamp})
WITH  ev, h
MERGE (h)-[:HAS_EVENT]->(ev)
return count(*);


USING PERIODIC COMMIT 30000
LOAD CSV WITH HEADERS FROM 'file:///events/2019-05-01/events.csv' AS row
with row where toInteger(row.delta_time_in_sec) > 0 and  toFloat(row.delta_time_in_sec) <= 1200
MATCH (evi:Event {vehicle: row.vehicle, event_timestamp:row.last_timestamp}) , (evf:Event {vehicle: row.vehicle, event_timestamp:row.event_timestamp})
create (evi)-[:MOVED_TO {delta_time_in_sec: row.delta_time_in_sec}]->(evf)
return count(*);


USING PERIODIC COMMIT 20000
LOAD CSV WITH HEADERS FROM 'file:///trips/2019-05-01/trips.csv' AS row
CREATE (t:Timetable {start_point: row.start_point, end_point: row.end_point, start_time:row.start_time,timetable:row.timetable, end_time: row.end_time, line_way:row.line_way })
WITH t, row
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})-[:HAS_LINE]->(l:Line {line_code: row.line_code})
with t, row, l
MERGE (l)-[:HAS_TIMETABLE]->(t)
return count(*);


USING PERIODIC COMMIT 20000
LOAD CSV WITH HEADERS FROM 'file:///bus_event_edges/2019-05-01/bus_event_edges.csv' AS row
MATCH (evi:Event {vehicle: row.vehicle, event_timestamp:row.event_timestamp})
MATCH (y:Year {value: toInteger(row.year)})-[:CONTAINS]->(m:Month {value: toInteger(row.month)})-[:CONTAINS]->(d:Day {value: toInteger(row.day)})-[:HAS_LINE]->(l:Line {line_code: row.line_code})-[:HAS_TRIP]->(t:Trip {line_way:row.line_way})-[:HAS_BUS_STOP]->(bs:BusStop {number: row.number})
WITH bs, evi
MERGE (evi)-[:IS_NEAR_BY]->(bs)
return count(*)
