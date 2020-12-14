MATCH (n:Team)
DETACH DELETE n;
LOAD CSV WITH HEADERS FROM 'file:///all-pos-on-ice-data.csv' AS row
MERGE (t:Team {teamId: toInteger(row.p1team), teamName: row.p1teamname})
RETURN COUNT(*);
