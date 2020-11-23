require 'httparty'

def make_pairs(on_ice, end_time, start_time, pairs)
  duration = Time.strptime(end_time, "%M:%S") - Time.strptime(start_time, "%M:%S")
  on_ice.combination(2).each do |pair|
    pairs[pair.to_set] += duration
  end
  pairs
end

def calc_on_ice(stats, pairs)
  on_ice = []
  last_sub_time = "00:00"
  stats.group_by{ |d| d["startTime"] }.sort.each do |k, subs|
    pairs = make_pairs(on_ice.map { |p| p["playerId"] }, k, last_sub_time, pairs)
    on_ice = on_ice.reject { |oi| oi["endTime"] == k }
    on_ice += subs
    last_sub_time = k
  end
  pairs
end

response = HTTParty.get("https://statsapi.web.nhl.com/api/v1/schedule?teamId=06&startDate=2019-09-01&endDate=2020-03-30")
pairs = Hash.new { |h, k| h[k] = 0 }
game_ids = response["dates"].flat_map { |r| r["games"].map { |g| g["gamePk"] }}
players = {}

game_ids.each do |game_id|
  sd = HTTParty.get("https://api.nhle.com/stats/rest/en/shiftcharts?cayenneExp=gameId=#{game_id}")["data"]
  players = players.merge(sd.map { |d| [d['playerId'], "#{d['firstName']} #{d['lastName']}"] }.to_h)

  # EVG as eventDescription means a goal
  bb_by_period = sd.select do |d|
    d["teamName"] == "Boston Bruins" &&
      !d["eventDescription"] &&
      d["lastName"] != "Halak" &&
      d["lastName"] != "Rask"
  end.group_by { |d| d["period"] }.map do |period, stats|
    pairs = calc_on_ice(stats, pairs)
  end

  puts "Game data for #{game_id}: #{pairs.size}"
end

pairs.keys.map(&:to_a).flatten.uniq.each do |player_id|
  response = HTTParty.get("https://statsapi.web.nhl.com/api/v1/people/#{player_id}")
  player = response["people"].first
  players[player_id] = {
    name: player["fullName"],
    position: player["primaryPosition"]["name"],
    position_type: player["primaryPosition"]["type"]
  }
end

pairs = pairs.reject do |pair, _|
  pair.map { |pid| players[pid] }.select do |player|
    !player || player[:position_type] != "Forward"
  end.any?
end

File.write("pos-on-ice-data.csv",
           pairs.sort_by { |_, duration| duration }.
           reject { |_, duration| duration < 8000 }.map do |pair, duration|
             [pair.map do |player_id|
               [
                 players[player_id][:name],
                 players[player_id][:position],
                 players[player_id][:position_type],
               ]
             end, (duration / 60).round].
               flatten
           end.map(&:to_csv).join
          )
