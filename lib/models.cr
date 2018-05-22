
class State
  JSON.mapping(
    planets: Array(Planet),
    expeditions: Array(Expedition)
  )
end

enum PlanetState
  Endangered
  Expected
  Safe
  Unconquered
end

class Planet
  JSON.mapping(
    x: Float32,
    y: Float32,
    owner: {type: Int32, nilable: true},
    ship_count: Int32,
    name: String,
    state: {type: PlanetState, default: PlanetState::Unconquered},
    incoming: {type: Array(Expedition), default: [] of Expedition},
    needed: {type: Array(Tuple(Int32,Int32)), default: [] of Tuple(Int32, Int32)}
  )

  def to_s(io)
    io << "Planet #{@name}"
  end

  def <=>(other)
    other.ship_count - self.ship_count
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
