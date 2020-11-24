const express = require('express')
const path = require('path')
const PORT = process.env.PORT || 5000

express()
  .use(express.static(path.join(__dirname, 'public')))
  .set('views', path.join(__dirname, 'views'))
  .set('view engine', 'ejs')
  .get('/', (req, res) => res.render('pages/index'))
  .listen(PORT, () => console.log(`Listening on ${ PORT }`))

var neo4j = require('neo4j-driver');

var graphenedbURL = process.env.GRAPHENEDB_BOLT_URL;
var graphenedbUser = process.env.GRAPHENEDB_BOLT_USER;
var graphenedbPass = process.env.GRAPHENEDB_BOLT_PASSWORD;

var driver = neo4j.driver(graphenedbURL, neo4j.auth.basic(graphenedbUser, graphenedbPass), {encrypted: 'ENCRYPTION_ON'});

var session = driver.session();

session
  .run("MATCH (:Person {name: 'Tom Hanks'})-[:ACTED_IN]->(movies) RETURN movies.title AS title")
  .subscribe({
    onNext: function(record) {
      console.log(record.get('title'));
    },
    onCompleted: function() {
        session.close();
    },
    onError: function() {
        console.log(error);
    }
  });
