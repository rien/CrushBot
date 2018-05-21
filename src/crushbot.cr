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

    closest = @o.closest_free_planet

    r = Response.new

    if !closest.nil?
      _, origin, destination = closest
      r.add_move Move.new(origin.name, destination.name, origin.ship_count)
    end

    return r.to_json
  end

end


