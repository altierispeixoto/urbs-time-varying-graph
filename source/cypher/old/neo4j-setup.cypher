CALL spatial.addWKTLayer('layer_curitiba','geometry');
//https://www.graphgrid.com/modeling-time-series-data-with-neo4j/

//create constraint on (m:Month) ASSERT m.value is unique;
//create constraint on (d:Day) assert d.value is unique;
//create constraint on (h:Hour) assert h.value is unique;
//create constraint on (m:Minute) assert m.value is unique;
//create constraint on (s:Second) assert s.value is unique;

//Create Time Tree Indexes
//CREATE INDEX ON :Year(value);

//create index on :BusStop (number);
//create index on :BusStop (latitude,longitude);
//
//
//create index on :Schedule (start_time, end_time, time_table);
//create index on :Schedule (start_time, end_time, time_table, line_code, start_point);
//create index on :Schedule (start_time, end_time, time_table, line_code, start_point, year, month, day, vehicle, line_way);
//
//create index on :Schedule (line_code, start_point);
//
//create index on :Stop (latitude, longitude,event_timestamp, event_time,line_code);
//
//create index on :Stop (line_code,vehicle, event_timestamp);
//create index on :Stop (line_code ,latitude ,longitude,vehicle,event_time);
//create index on :Stop (line_code ,latitude ,longitude,event_time);
//

//create index on :Trip(line_way);
//create index on :Schedule (start_time, end_time, time_table);


//create constraint on (v:Vehicle) ASSERT v.vehicle is UNIQUE;


create index on :Line(line_code);
create constraint on (y:Year) ASSERT y.value IS UNIQUE;
CREATE INDEX ON :Month(value);
CREATE INDEX ON :Day(value);
CREATE INDEX ON :Hour(value);
// CREATE INDEX ON :Minute(value);
// CREATE INDEX ON :Second(value);


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

//Create Time Tree with Minute Depth
// match(y:Year)-[:CONTAINS]->(m:Month)-[:CONTAINS]->(d:Day)-[:CONTAINS]->(h:Hour)
// WITH collect(h) AS hours
//   FOREACH(h IN hours  |
//      FOREACH (minute in range(1,60) |
//        CREATE (mi:Minute {value: minute})
//        MERGE (h)-[:CONTAINS]->(mi)));


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

// Connect Minutes Sequentially
// MATCH (year:Year)-[:CONTAINS]->(month)-[:CONTAINS]->(day)-[:CONTAINS]->(hour)-[:CONTAINS]->(minute)
// WITH year, month, day, hour, minute
// ORDER BY year.value, month.value, day.value, hour.value, minute.value
// WITH collect(minute) AS minutes
// FOREACH(i in RANGE(0, length(minutes)-2) |
//     FOREACH(minute1 in [minutes[i]] |
//         FOREACH(minute2 in [minutes[i+1]] |
//             CREATE UNIQUE (minute1)-[:NEXT]->(minute2))));



//Lookup Time Tree example with Year, Month and Day Showing Next Relationship Across Months
MATCH (y:Year) WHERE y.value = 2019
WITH y
MATCH (y)-[:CONTAINS]->(m:Month) WHERE m.value = 1 OR m.value = 12 WITH y, m
MATCH (m)-[:CONTAINS]->(d)
RETURN y, m, d;


// delete large nodes
call apoc.periodic.iterate("MATCH (s:Stop)  return s", "DETACH DELETE s", {batchSize:10000})
yield batches, total return batches, total
