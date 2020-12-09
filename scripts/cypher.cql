MATCH (n)
DETACH DELETE n;
LOAD CSV WITH HEADERS FROM 'file:///all-pos-on-ice-data.csv' AS row
MERGE (p:Player {playerId: row.p1name, name: row.p1name, position: row.p1pos, type: row.p1type, teamInt: toInteger(row.p1team), team: row.p1teamname, iceTime: toInteger(row.p1icetime)})
RETURN COUNT(*);
LOAD CSV WITH HEADERS FROM 'file:///all-pos-on-ice-data.csv' AS row
MERGE (p:Player {playerId: row.p2name, name: row.p2name, position: row.p2pos, type: row.p2type, teamInt: toInteger(row.p2team), team: row.p2teamname, iceTime: toInteger(row.p2icetime)})
RETURN COUNT(*);
LOAD CSV WITH HEADERS FROM 'file:///all-pos-on-ice-data.csv' AS row
MATCH (p1:Player {playerId: row.p1name })
MATCH (p2:Player {playerId: row.p2name })
MERGE (p1)-[:ONICE {weight: toInteger(row.time)}]-(p2)
RETURN COUNT(*);
