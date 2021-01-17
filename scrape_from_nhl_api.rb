require 'httparty'

def make_pairs(on_ice, end_time, start_time)
  duration = (@time[end_time] - @time[start_time])/60.0
  forwards = on_ice.reject do |player_id|
    player = @players[player_id]
    !player || player[:position_type] != "Forward" || player[:team] != 6
  end

  forwards.each do |player_id|
    @players[player_id][:ice_time] += duration
  end

  forwards.combination(2).each do |pair|
    @pairs[pair.to_set] += duration
  end
end

@players = Hash.new  do |h, player_id|
  response = HTTParty.get("https://statsapi.web.nhl.com/api/v1/people/#{player_id}")
  player = response["people"].first
  h[player_id] = {
    name: player["fullName"],
    position: player["primaryPosition"]["name"],
    position_type: player["primaryPosition"]["type"],
    team: player["currentTeam"] ?  player["currentTeam"]["id"] : 0,
    team_name: player["currentTeam"] ?  player["currentTeam"]["name"] : "No team",
    ice_time: 0
  }
end
@pairs = Hash.new { |h, k| h[k] = 0 }
@time = Hash.new { |h, time| h[time] = Time.strptime(time, "%M:%S") }

def calc_on_ice(stats)
  on_ice = []
  last_sub_time = "00:00"
  stats.group_by{ |d| d["startTime"] }.sort.each do |time, subs|
    make_pairs(on_ice.map { |p| p["playerId"] }, time, last_sub_time)
    on_ice = on_ice.reject { |oi| oi["endTime"] == time }
    on_ice += subs
    last_sub_time = time
  end

  make_pairs(on_ice.map { |p| p["playerId"] }, "20:00", last_sub_time)
end

=begin
team_ids = HTTParty.get("https://statsapi.web.nhl.com/api/v1/teams")["teams"].
  map { |team| team["id"] }

game_ids = team_ids.map do |team_id|
  response = HTTParty.get("https://statsapi.web.nhl.com/api/v1/schedule?teamId=#{team_id}&startDate=2019-09-01&endDate=2020-03-30")
  response["dates"].flat_map { |r| r["games"].map { |g| g["gamePk"] }}
end.flatten.uniq.sort
=end

game_ids = [2020020023]

game_ids.each do |game_id|
  sd = HTTParty.get("https://api.nhle.com/stats/rest/en/shiftcharts?cayenneExp=gameId=#{game_id}")["data"]
  # EVG as eventDescription means a goal
  sd.select { |d| !d["eventDescription"] }.
    group_by { |d| d["teamName"] }.map do |_, team_stats|
    team_stats.group_by { |d| d["period"] }.map do |period, stats|
      calc_on_ice(stats) if period < 4
    end
  end

  puts "Game data for #{game_id}: #{@pairs.size}"
end

File.write("import/bs-10-15.csv",
           ([%w[
           p1name
           p1pos
           p1type
           p1team
           p1teamname
           p1icetime
           p2name
           p2pos
           p2type
           p2team
           p2teamname
           p2icetime
           time
            ]] +
            @pairs.sort_by { |_, duration| duration }.map do |pair, duration|
              [pair.map do |player_id|
                player = @players[player_id]
                [
                  player[:name],
                  player[:position],
                  player[:position_type],
                  player[:team],
                  player[:team_name],
                  player[:ice_time].round(2)
                ]
              end, duration.round(2)].
              flatten
            end).map(&:to_csv).join
          )
