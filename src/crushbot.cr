require "json"

bot = CrushBot.new
bot.run()

class State
  JSON.mapping(
    planets: Array(Planet),
    expeditions: Array(Expedition)
  )
end

class Planet
  JSON.mapping(
    x: Float32,
    y: Float32,
    owner: {type: Int32, nilable: true},
    ship_count: Int32,
    name: String
  )

  def to_s(io)
    io << "Planet #{@name}"
  end
end

class Expedition
  JSON.mapping(
    id: Int32,
    origin: String,
    destination: String,
    turns_remaining: Int32,
    owner: Int32,
    ship_count: Int32
  )
end

class Move
  JSON.mapping(
    origin: String,
    destination: String,
    ship_count: Int32
  )

  def initialize(@origin, @destination, @ship_count)
  end
end

class Response
  JSON.mapping(
    moves: Array(Move)
  )
  def initialize
    @moves = [] of Move
  end

  def add_move(m)
    @moves << m
  end
end

class CrushBot

  def initialize(@input_file=STDIN)
    @planets = Hash(String, Planet).new
    @planet_distances = Hash({String, String}, Float32).new

    @own_planets = [] of Planet
    @free_planets = [] of Planet
    @enemy_planets = [] of Planet
  end

  def run
    @input_file.each_line do |line|
      state = State.from_json(line)
      response = do_move(state)
      puts response
    end
  end

  def closest_free_planet
    closest = nil
    @own_planets.each do |own|
      @free_planets.each do |free|
        d = @planet_distances[{own, free}]
        if closest.nil? || d < closest[0]
          closest = {d, own, free}
        end
      end
    end
    return closest
  end

  def init_planets(state)

    state.planets.each do |planet|
      @planets[planet.name] = planet
    end


    state.planets.size.times do |i|
      (i...state.planets.size).each do |j|
        p1 = state.planets[i]
        p2 = state.planets[j]
        d = ((p1.x - p2.x)**2 + (p1.y - p2.y)**2)**0.5
        @planet_distances[{p1.name, p2.name}] = d
        @planet_distances[{p2.name, p1.name}] = d
      end
    end
  end

  def do_move(state)
    init_planets(state) if @planets.empty?

    @own_planets.clear
    @free_planets.clear
    @enemy_planets.clear

    state.planets.each do |planet|
      if planet.owner.nil?
        @free_planets << planet
      elsif planet.owner == 1
        @own_planets << planet
      else
        @enemy_planets << planet
      end
    end

    closest = closest_free_planet

    r = Response.new

    if !closest.nil?
      _, origin, destination = closest
      r.add_move Move.new(origin.name, destination.name, origin.ship_count)
    end

    return r.to_json
  end

end


