//https://www.graphgrid.com/modeling-time-series-data-with-neo4j/

//Create Time Tree Indexes
CREATE INDEX ON :Year(value);
CREATE INDEX ON :Month(value);
CREATE INDEX ON :Day(value);
CREATE INDEX ON :Hour(value);
CREATE INDEX ON :Minute(value);
CREATE INDEX ON :Second(value);


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




//Lookup Time Tree example with Year, Month and Day Showing Next Relationship Across Months
MATCH (y:Year) WHERE y.value = 2019
WITH y
MATCH (y)-[:CONTAINS]->(m:Month) WHERE m.value = 1 OR m.value = 12 WITH y, m
MATCH (m)-[:CONTAINS]->(d)
RETURN y, m, d;
