## Visualising NHL Time on Ice Data

This is a project to visualize shared time on ice data. A visualization of this data is available [here][blog-vis].

When I first started watching hockey, I was consistently astounded by line changes. Even today, as an avid hockey fan, I am always eager to learn more about which defensive pairings work best, how different lines' chemistry works, and most of all, who is actually playing together on a team. 

This project seeks to answer the question of who shares time on ice with who. It also served as a tool for me to learn about graph databases and server and network setup.

This repo contains the scripts used to scrape the data, import it into a [Neo4j] database, and a sample index.html file detailing how to display it with [NeoVis].   

### Scraping NHL API Data

The NHL API exposes many pages with information on teams, games and players. For this project, I use this [teams page][teams-page] to get all teams' IDs. Given those IDs, I scrape each team's [schedule]. I pull the game IDs from the schedule, and using them can get [shift data][shifts]. For more information about the positions of individual players, I scrape the [player's page][player].

This is where it gets interesting! Shift data only represents when a player enters and leaves the ice for a given shift. But, this project asks the question of who shares the ices with who. So, `scrape_from_nhl_api.rb` implements a small algorithm to calculate who is actually on the ice together, and give these pairings shared time. It does this for all pairings _of the same position_.

Then, the final step of scraping the data is writing it to a csv (`import/all-pos-on-ice-data.csv`), which is used in the next step to import the data into Neo4j.

### Importing the data into a Neo4j DB

Fortunately, Neo4j has import from csv functionality. `scripts/load_players.cql` has the details for this import. It is run with [cypher-shell]. 

The script loads the players as nodes in a weighted graph. The nodes have descriptions of the players including position and current team. Edges between each pair of players are weighted by their shared time on ice. So if two players spent 200 minutes on ice together over the course of a season, the edge connecting them would have a weight of 200. Notably, in an effort not to overcrowd the data, only players who shared the ice for at least two hours are loaded into the csv.

### Visualizing with NeoVis

The next step in this pipeline is to actually display data. [NeoVis] is a javascript library for displaying Neo4j data. This controls the size and color of the nodes and their edges. Unfortunately, it does not allow one to hardcode colors, so I couldn't hardcode the players' nodes' colors to match their team colors. One potential future extension for this project would be to use [vis.js] which does have these configuration options.

 
### Exposing the DB from a DigitalOcean Droplet

Lastly, to set up a server running Neo4j, I installed and configured Neo4j on a [DigitalOcean droplet][digital-ocean].

## Future Work

There are many potential avenues to explore this more deeply. In no particular order, some on my mind are:

* Looking into the NHL API, and scraping different data
* Automating the data scraping to happen nightly (maybe with the next season?)
* Using [vis.js] to have more control over tuning the data visualization
* Putting a load balancer and lambda on top of the server to direct traffic

[neo4j]: https://neo4j.com/
[neovis]: https://github.com/neo4j-contrib/neovis.js/
[blog-vis]: https://jemma.dev/blog/nhl-time-on-ice
[teams-page]: https://statsapi.web.nhl.com/api/v1/teams
[schedule]: https://statsapi.web.nhl.com/api/v1/schedule?teamId=6&startDate=2019-09-01&endDate=2020-03-30
[shifts]: https://api.nhle.com/stats/rest/en/shiftcharts?cayenneExp=gameId=2019020351
[player]: https://statsapi.web.nhl.com/api/v1/people/8478075
[cypher-shell]: https://neo4j.com/docs/operations-manual/current/tools/cypher-shell/
[vis.js]: https://visjs.org/
[digital-ocean]: https://www.digitalocean.com/products/droplets/

