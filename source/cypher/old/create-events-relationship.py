import pandas as pd


# %%
df_distinct_lines = pd.read_csv('data/distinct-lines-vehicles.csv')

df_distinct_lines.head()

# %%

from neo4j import GraphDatabase

NEO4J_URI = 'bolt://localhost:7687'
NEO4J_USER = 'neo4j'
NEO4J_PASSWORD = 'neo4j2018'

_driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))

def connect_events(vehicle,line_code,date):

    connect_evt = """ MATCH (p:Position {vehicle: $vehicle,line_code: $line_code,date: $date })
                     WITH p ORDER BY p.event_timestamp DESC
                        WITH collect(p) as entries
                        FOREACH(i in RANGE(0, size(entries)-2) |
                        FOREACH(e1 in [entries[i]] |
                        FOREACH(e2 in [entries[i+1]] |
                        MERGE (e2)-[ :MOVES_TO ]->(e1)))) """

    with _driver.session() as session:
        return session.run(connect_evt, vehicle=vehicle,line_code=line_code,date=date)


for index, row in df_distinct_lines.iterrows():
    connect_events(row['vehicle'],row['line_code'],row['date'])
