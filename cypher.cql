MATCH (n)
DETACH DELETE n;
LOAD CSV WITH HEADERS FROM 'file:///on-ice-data.csv' AS row
MERGE (p:Player {playerId: row.p1, name: row.p1})
RETURN COUNT(*);
LOAD CSV WITH HEADERS FROM 'file:///on-ice-data.csv' AS row
MERGE (p:Player {playerId: row.p2, name: row.p2})
RETURN COUNT(*);
LOAD CSV WITH HEADERS FROM 'file:///on-ice-data.csv' AS row
MATCH (p1:Player {playerId: row.p1 })
MATCH (p2:Player {playerId: row.p2 })
MERGE (p1)-[:WEIGHT {weight: row.time}]->(p2)
