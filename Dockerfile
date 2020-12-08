FROM neo4j:latest

COPY ./scripts scripts/
COPY ./import import/
ENV NEO4J_AUTH=none
