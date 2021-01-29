
//calculates minimum distance from every bus stop to its closest health unity in the same district:
MATCH (bs:BusStop),(poi:Poi)
WHERE bs.section_name = poi.section_name
CALL apoc.algo.dijkstra(bs, poi, 'NEXT_STOP|WALK', 'distance') YIELD weight
RETURN bs.section_name as regional
      ,bs.neighbourhood as bairro
      ,bs.number AS numero
      ,bs.name as bus_stop
      ,bs.latitude as latitude
      ,bs.longitude as longitude
      ,poi.name as nome_us
      ,poi.section_name,poi.latitude as us_latitude, poi.longitude as us_longitude, min(weight) as distancia



MATCH (p:PontoLinha),(poi:Poi{categoria:'Unidade Saude Basica',source:'planilha'})
WHERE p.regional = poi.distrito
CALL apoc.algo.dijkstra(p, poi, 'proximo|caminhar', 'distancia') YIELD weight
RETURN p.numero AS numero, p.latitude as latitude, p.longitude as longitude, min(weight) as distancia




match(l:Line {line_code:'666'})-[:HAS_TRIP]-(t:Trip)
with l.name as line_name ,t.line_way as line_way
match (t:Trip {line_way: line_way})-[:STARTS_ON_POINT]->(bs:BusStop )<-[:EVENT_STOP]-(ss:Stop {vehicle: 'GN606'})
with ss, line_name , line_way
MATCH(t:Trip {line_way: line_way})-[:ENDS_ON_POINT]->(bs:BusStop )<-[:EVENT_STOP]-(se:Stop {vehicle: 'GN606'})
with line_name , line_way,ss.event_time as start_event, se.event_time as end_event where ss.event_time < se.event_time
with line_name , line_way, start_event, min(end_event) as end_event
with line_name , line_way, min(start_event) as start_event , end_event
match (t:Trip {line_way: line_way})-[:STARTS_ON_POINT]->(bs:BusStop )<-[:EVENT_STOP]-(ss:Stop {vehicle: 'GN606'})
where ss.event_time = start_event
with line_name , line_way, ss,start_event, end_event
MATCH(t:Trip {line_way: line_way})-[:ENDS_ON_POINT]->(bs:BusStop  )<-[:EVENT_STOP]-(se:Stop {vehicle: 'GN606'})
where se.event_time = end_event
WITH line_name , line_way, ss, se ,start_event , end_event
match p = (ss)-[m:MOVED_TO*]->(se)
with line_name , line_way, start_event , end_event, extract(s in relationships(p) | toFloat(s.delta_time))     as delta_time
    ,extract(s in relationships(p) | toFloat(s.delta_distance)) as delta_distance
    ,extract(s in relationships(p) | toFloat(s.delta_velocity)) as delta_velocity
    ,length(extract(s in nodes(p) where 'Stop' IN LABELS(s) )) as stop
return line_name , line_way, min(start_event) as start_event, end_event, apoc.coll.sum(delta_time)/60        as time_in_minutes
      ,apoc.coll.sum(delta_distance)/1000  as distance_in_kilometers
      ,apoc.coll.avg(delta_velocity)       as velocity_in_kmh
      ,stop
order by start_event, end_event


CALL algo.pageRank.stream('BusStop', 'NEXT_STOP', {iterations:20, dampingFactor:0.85})
YIELD nodeId, score
RETURN algo.asNode(nodeId).name AS page,score
ORDER BY score DESC


CALL algo.articleRank.stream('BusStop', 'NEXT_STOP', {iterations:20, dampingFactor:0.85})
YIELD nodeId, score
RETURN algo.asNode(nodeId).name AS page,score
ORDER BY score DESC


CALL algo.betweenness.stream('BusStop', 'NEXT_STOP',{direction:'out'})
YIELD nodeId, centrality
RETURN algo.asNode(nodeId).name AS page,centrality
ORDER BY centrality DESC


CALL algo.closeness.harmonic.stream('BusStop', 'NEXT_STOP')
YIELD nodeId, centrality
RETURN algo.asNode(nodeId).name AS node, centrality
ORDER BY centrality DESC
LIMIT 20;

CALL algo.pageRank.stream('BusStop', 'NEXT_STOP', {iterations:20, dampingFactor:0.85})
YIELD nodeId, score
with algo.asNode(nodeId) as bs ,score ORDER BY score DESC
MATCH()-[r:NEXT_STOP]->(bs) return distinct r.line_name,r.line_code,r.line_way,bs.name

CALL algo.louvain.stream('BusStop', 'NEXT_STOP', {includeIntermediateCommunities: true})
YIELD nodeId, communities
with algo.asNode(nodeId) AS bs, communities
MATCH()-[r:NEXT_STOP]->(bs) return bs.name,bs.latitude,bs.longitude,communities

CALL algo.louvain.stream('BusStop', 'NEXT_STOP', {})
YIELD nodeId, community
RETURN algo.asNode(nodeId).name AS user, community
ORDER BY community;
