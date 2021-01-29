MATCH (n) DETACH DELETE n;

MATCH ()-[r]-() DELETE r;

CALL apoc.periodic.iterate("MATCH ()-[r:MOVES_TO]-() return r","with r  DELETE r", {batchSize:1000,iterateList:true, parallel:false})
