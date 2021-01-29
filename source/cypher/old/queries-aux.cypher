

match(y:Year)-[:CONTAINS]-(m:Month)-[:CONTAINS]-(d:Day) return y.value, count(distinct  m), count(d)

match (d:Day)-[r2:EXISTS_LINE]->(l:Line) where l.line_code = '666' return *


match (d:Day)-[:EXISTS_BUS_STOP]->(bs:BusStop) where bs.number = '190309' return *


MATCH (bs:BusStop {number:'190309'})-[:NEXT_STOP]->(bse:BusStop) return *

match (d:Day)-[r2:EXISTS_LINE]->(l:Line)-[:HAS_TRIP]->(t:Trip) where l.line_code = '666' return *

match (d:Day)-[r2:EXISTS_LINE]->(l:Line)-[:HAS_TRIP]->(t:Trip)-[:STARTS_ON_POINT]-(bs:BusStop) where l.line_code = '666' return *

match (d:Day)-[:EXISTS_VEHICLE]->(v:Vehicle {vehicle:'MT013'}) return *


match(s:Schedule) return count(s)

match (d:Day)-[r2:EXISTS_LINE]->(l:Line)-[:HAS_TRIP]->(t:Trip)-[:HAS_SCHEDULE_AT]->(s:Schedule)<-[:EXISTS_SCHEDULE]-(d) where l.line_code = '666' and d.value= 2  return * order by d.value, s.start_time

match (mi:Minute)-[:EXISTS_STOP]->(s:Stop) return * limit 5

match (mi:Minute)-[:EXISTS_STOP]->(s:Stop)<-[:VEHICLE_HAS_STOPPED]->(v:Vehicle) return * limit 5

match (d:Day)-[:CONTAINS]->(h:Hour)-[:CONTAINS]->(m:Minute)-[:EXISTS_STOP]->(s:Stop) where d.value=1 return count(s)

match (d:Day)-[:CONTAINS]->(h:Hour)-[:CONTAINS]->(m:Minute)-[:EXISTS_STOP]->(s:Stop)<-[:VEHICLE_HAS_STOPPED]-(v:Vehicle) where d.value=1 return s.line_code, v.vehicle,count(s) order by s.line_code, v.vehicle

match (d:Day {value:1})-[:EXISTS_VEHICLE]->(v:Vehicle)-[:HAS_VEHICLE_SCHEDULE]->(s:Schedule)<-[:HAS_SCHEDULE_AT]-(t:Trip)<-[:HAS_TRIP]-(l:Line) return v.vehicle,l.name,t.line_way,count(s)


match (d:Day)-[:EXISTS_LINE]-(l:Line)-[:HAS_TRIP]-(t:Trip)-[:HAS_SCHEDULE_AT]-(s:Schedule)-[:HAS_VEHICLE_SCHEDULED]-(v:Vehicle)
 return d.value, l.line_code, t.line_way,v.vehicle, s.start_time order by d.value, v.vehicle, s.start_time

match (d:Day)-[:EXISTS_LINE]-(l:Line)-[:HAS_TRIP]-(t:Trip)-[:HAS_SCHEDULE_AT]-(s:Schedule)-[:HAS_VEHICLE_SCHEDULED]-(v:Vehicle) 
with distinct d.value as dia, l.line_code as linha, t.line_way as sentido,v.vehicle as veiculo return dia, linha, sentido, count(veiculo)


MATCH (y:Year {value: 2019})-[:CONTAINS]->(m:Month {value: 1})-[:CONTAINS]->(d:Day {value: 2})-[r2:EXISTS_LINE]->(l:Line {line_code:"761"})-[:HAS_TRIP]->(t:Trip)-[:HAS_SCHEDULE_AT]->(s:Schedule {day:'1'}) return l.line_code, t.line_way,s.start_time,s.end_time,s.time_table order by s.start_time

match (d:Day)-[:CONTAINS]-(h:Hour)-[:EXISTS_STOP]->(s:Stop)-[r:EVENT_STOP]->(bs:BusStop)<-[:HAS_BUS_STOP]-(t:Trip)<-[:HAS_TRIP]-(l:Line) return d.value, h.value,l.line_code,t.line_way,bs.number,count(r) order by d.value, h.value,bs.number

match (d:Day {value:1})-[:CONTAINS]-(h:Hour {value:22})-[:EXISTS_STOP]->(s:Stop)-[r:EVENT_STOP]->(bs:BusStop)<-[:HAS_BUS_STOP]-(t:Trip )<-[:HAS_TRIP]-(l:Line ) return d.value, h.value,l.line_code,t.line_way,count(bs) order by d.value, h.value

----------------------

match (d:Day)-[:EXISTS_LINE]-(l:Line)-[:HAS_TRIP]-(t:Trip)-[:HAS_SCHEDULE_AT]-(s:Schedule)-[:HAS_VEHICLE_SCHEDULED]-(v:Vehicle)-[:VEHICLE_HAS_STOPPED]-(st:Stop) 
return d.value,l.line_code,t.line_way,v.vehicle,count(s)


match (l:Line {line_code:'666'})-[:HAS_TRIP]->(t:Trip)-[:STARTS_ON_POINT]->(bs:BusStop) ,(t)-[:ENDS_ON_POINT]->(bse:BusStop) 
return bs, be 


WITH t,bs 
match (t)-[:ENDS_ON_POINT]->(bse:BusStop) 
with bs, bse match (bs)-[:NEXT_STOP* {line_code:'666'}]->(bse) return *




CALL algo.pageRank.stream(
  'MATCH (u:User) WHERE exists( (u)-[:FRIENDS]-() ) RETURN id(u) as id',
  'MATCH (u1:User)-[:FRIENDS]-(u2:User) RETURN id(u1) as lib, id(u2) as target',
  {graph:'cypher'}
) YIELD nodeId,score with algo.asNode(nodeId) as node, score order by score desc limit 10
RETURN node {.name, .review_count, .average_stars,.useful,.yelping_since,.funny}, score


CALL algo.pageRank.stream(
'MATCH (bs:BusStop)<-[:EVENT_STOP]-(s:Stop)<-[:EXISTS_STOP]-(h:Hour {value:5})<-[:CONTAINS]-(d:Day {value:2})<-[:CONTAINS]-(m:Month {value:5})<-[:CONTAINS]-(y:Year) RETURN id(bs) as lib, id(s) as target',
'EVENT_STOP')
YIELD nodeId, score
with algo.asNode(nodeId) as node, score order by score desc limit 10  
RETURN node, score


CALL algo.pageRank.stream(
  'MATCH (bs:BusStop) WHERE exists( (bs)-[:EVENT_STOP]-() ) RETURN id(bs) as id',
  'MATCH (bs:BusStop)-[:EVENT_STOP]<-(s:Stop)-[:EXISTS_STOP]-(h:Hour {value:5})<-[:CONTAINS]-(d:Day {value:2})<-[:CONTAINS]-(m:Month {value:5})<-[:CONTAINS]-(y:Year) RETURN id(bs) as lib, id(s) as target',
  {graph:'cypher'}
) YIELD nodeId,score with algo.asNode(nodeId) as node, score order by score desc limit 10


CALL algo.pageRank.stream('BusStop', 'EVENT_STOP', {iterations:20, dampingFactor:0.85})
YIELD nodeId, score
RETURN algo.asNode(nodeId).name AS bus_stop,score
ORDER BY score DESC LIMIT 10


CALL algo.pageRank.stream('
MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour {value:8})-[:EXISTS_STOP]-(s:Stop) return s',
'MATCH (s)-[r]-(bs:BusStop) return id(s) as lib, id(bs) as target, count(*) as weight ORDER BY weight DESC limit 20',
{graph:'cypher'}
) YIELD nodeId,score with algo.asNode(nodeId) as node, score order by score desc limit 10
return node, score 


CALL algo.pageRank.stream(
 "MATCH (bs:BusStop) return id(bs) as id",
 "MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour {value:10})-[:EXISTS_STOP]->(s:Stop)-[:EVENT_STOP]->(bs:BusStop)-[:NEXT_STOP]->(be:BusStop) 
  RETURN id(bs) AS lib, id(be) AS target, count(*) as weight
 ",
 {graph:"cypher", weightProperty: "weight"})
YIELD nodeId, score
RETURN algo.getNodeById(nodeId).name AS busstop, score
ORDER BY score DESC
LIMIT 10




CALL algo.pageRank.stream(
 "MATCH (bs:BusStop) return id(bs) as id",
 "MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour {value:10})-[:EXISTS_STOP]->(s:Stop)-[:EVENT_STOP]->(bs:BusStop)-[:NEXT_STOP]->(be:BusStop) 
  RETURN id(bs) AS lib, id(be) AS target, count(*) as weight
 ",
 {graph:"cypher", weightProperty: "weight"})
YIELD nodeId, score 
with  algo.getNodeById(nodeId) AS busstop, score ORDER BY score DESC LIMIT 10
MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour {value:10})-[:EXISTS_STOP]->(s:Stop)-[e:EVENT_STOP]->(bs:BusStop)-[n:NEXT_STOP]->(be:BusStop) 
return busstop,n, be, stop,e 




CALL algo.pageRank.stream(
 "MATCH (bs:BusStop) return id(bs) as id",
 "MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour)-[:EXISTS_STOP]->(s:Stop)-[:EVENT_STOP]->(bs:BusStop)-[:NEXT_STOP]->(be:BusStop) 
  WHERE h.value IN [7,8,9]
  RETURN id(bs) AS lib, id(be) AS target, count(*) as weight
 ",
 {graph:"cypher", weightProperty: "weight"})
YIELD nodeId, score
with algo.getNodeById(nodeId) AS busstop, score ORDER BY score DESC LIMIT 10
MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour {value:10})-[:EXISTS_STOP]->(s:Stop)-[:EVENT_STOP]->(busstop)-[r:NEXT_STOP]->(be:BusStop) 
return busstop.number,busstop.name,count(distinct r.line_code) as linhas,count(distinct s.vehicle) as vehicles, count(s) as nr_stops, score as pagerank  order by count(s) desc


CALL algo.pageRank.stream(
 "MATCH (bs:BusStop) return id(bs) as id",
 "MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour)-[:EXISTS_STOP]->(s:Stop)-[:EVENT_STOP]->(bs:BusStop)-[:NEXT_STOP]->(be:BusStop) 
  WHERE h.value IN [12,13,14]
  RETURN id(bs) AS lib, id(be) AS target, count(*) as weight
 ",
 {graph:"cypher", weightProperty: "weight"})
YIELD nodeId, score
with algo.getNodeById(nodeId) AS busstop, score ORDER BY score DESC LIMIT 10
MATCH (y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:CONTAINS]->(h:Hour {value:10})-[:EXISTS_STOP]->(s:Stop)-[:EVENT_STOP]->(busstop)-[r:NEXT_STOP]->(be:BusStop) 
return busstop.number,busstop.name,count(distinct r.line_code) as linhas,count(distinct s.vehicle) as vehicles, count(s) as nr_stops, score as pagerank  order by count(s) desc










match(y:Year)-[:CONTAINS]->(m:Month {value:1})-[:CONTAINS]->(d:Day {value:1})-[:EXISTS_LINE]->(l:Line {line_code:'001'})-[:HAS_TRIP]-(t:Trip)  
with t 
match (t)-[:STARTS_ON_POINT]->(bs:BusStop)
match (t)-[:ENDS_ON_POINT]->(be:BusStop)
with bs, be
match (bs)-[r:NEXT_STOP*]->(be) RETURN bs


match(y:Year)-[:CONTAINS]->(m:Month {value:1})-[:CONTAINS]->(d:Day {value:2})-[:EXISTS_LINE]->(l:Line {line_code:'001'})-[:HAS_TRIP]-(t:Trip)  
with t,d  
match (t)-[:STARTS_ON_POINT]->(bs:BusStop)
match (t)-[:ENDS_ON_POINT]->(be:BusStop)
with bs, be, d 
match (bs)<-[:EVENT_STOP]-(s:Stop)<-[:EXISTS_STOP]-(h:Hour {value:6})<-[:CONTAINS]-(d) 
return bs.number,h.value,count(s) order by h.value




match(y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:EXISTS_LINE]->(l:Line {line_code:'001'})-[:HAS_TRIP]-(t:Trip)  
match (t)-[:STARTS_ON_POINT]->(bs:BusStop)
match (t)-[:ENDS_ON_POINT]->(be:BusStop)
with bs, be,d,m,y
match path=(bs)-[:NEXT_STOP*]->(be) WHERE all(r in relationships(path) where r.line_code = '001')
WITH NODES(path) AS bustops , y,m,d 
UNWIND bustops AS busstop 
match (busstop)<-[:EVENT_STOP]-(s:Stop)<-[:EXISTS_STOP]-(h:Hour)<-[:CONTAINS]-(d)<-[:CONTAINS]-(m)<-[:CONTAINS]-(y)
where h.value = 8 return *



-- query_1
match(y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:EXISTS_LINE]->(l:Line {line_code:'001'})-[:HAS_TRIP]-(t:Trip)  
match (t)-[:STARTS_ON_POINT]->(bs:BusStop)
match (t)-[:ENDS_ON_POINT]->(be:BusStop)
with bs, be,d,m,y
match path=(bs)-[:NEXT_STOP*]->(be) WHERE all(r in relationships(path) where r.line_code = '001')
WITH NODES(path) AS bustops , y,m,d 
UNWIND bustops AS busstop 
match (busstop)<-[:EVENT_STOP]-(s:Stop)<-[:EXISTS_STOP]-(h:Hour)<-[:CONTAINS]-(d)<-[:CONTAINS]-(m)<-[:CONTAINS]-(y)
return busstop.number, busstop.name,d.value as day, h.value as hour, count(distinct s.vehicle) as vehicles, count(s) as nr_stops_events order by hour





match(y:Year)-[:CONTAINS]->(m:Month {value:5})-[:CONTAINS]->(d:Day {value:2})-[:EXISTS_LINE]->(l:Line {line_code:'001'})-[:HAS_TRIP]-(t:Trip)  
match (t)-[:STARTS_ON_POINT]->(bs:BusStop)
match (t)-[:ENDS_ON_POINT]->(be:BusStop)
with bs, be,d,m,y
match (bs)<-[:EVENT_STOP]-(ss:Stop)<-[:EXISTS_STOP]-(h:Hour {value:7})<-[:CONTAINS]-(d)<-[:CONTAINS]-(m)<-[:CONTAINS]-(y)
match (be)<-[:EVENT_STOP]-(se:Stop)<-[:EXISTS_STOP]-(h:Hour {value:7})<-[:CONTAINS]-(d)<-[:CONTAINS]-(m)<-[:CONTAINS]-(y)
CALL algo.shortestPath.stream(ss, se, "delta_time")
YIELD nodeId, cost return nodeId, cost
