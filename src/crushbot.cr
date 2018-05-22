require "json"
require "models"
require "overview"

bot = CrushBot.new
bot.run()

class CrushBot

  def initialize(@input_file=STDIN)
    @o = Overview.new
  end

  def run
    @input_file.each_line do |line|
      state = State.from_json(line)
      response = do_move(state)
      puts response
    end
  end

  def do_move(state)
    @o.update state
    r = Response.new

    @o.endangered_planets.each do |endangered|
      turns, needed = endangered.needed.first
      @o.closest_safe_planets(endangered).each do |planet, distance|
        break if distance > turns || needed <= 0
        next if planet.ship_count == 0
        r.add_move Move.new(planet.name, endangered.name, planet.ship_count)
        needed -= planet.ship_count
        planet.ship_count = 0
      end
    end

    @o.safe_planets.each do |planet|
      next if planet.ship_count == 0
      result = @o.conquerable_planets.map do |p|
        score = @o.planet_distances[{planet.name, p.name}]
        score += p.ship_count + 1 if p.owner.nil?
        {score, p}
      end.min?
      unless result.nil?
        _, destination = result
        r.add_move Move.new(planet.name, destination.name, planet.ship_count)
      end
    end

    return r.to_json
  end

end


