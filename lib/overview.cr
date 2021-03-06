require "models"

class Overview

  getter planets
  getter planet_distances
  getter own_planets
  getter free_planets
  getter enemy_planets
  getter safe_planets
  getter endangered_planets
  getter conquerable_planets
  getter state

  @state : State?

  def initialize
    @planets = Hash(String, Planet).new
    @planet_distances = Hash({String, String}, Float32).new
    @own_planets = [] of Planet
    @free_planets = [] of Planet
    @enemy_planets = [] of Planet
    @conquerable_planets = [] of Planet
    @safe_planets = [] of Planet
    @endangered_planets = [] of Planet
    @state = nil
  end


  def update(state)
    @state = state
    state.planets.each do |planet|
      @planets[planet.name] = planet
    end

    state.expeditions.each do |exp|
      @planets[exp.destination].incoming << exp
    end

    init_planet_distances(state) if @planet_distances.empty?

    @own_planets = @planets.values.select{|p| p.owner == 1}
    @free_planets = @planets.values.select{|p| p.owner.nil?}
    @enemy_planets = @planets.values.select{|p| !(p.owner.nil? || p.owner == 1)}
    @conquerable_planets = @free_planets + @enemy_planets

    @own_planets.each do |planet|
      planet.state = PlanetState::Safe
      planet.incoming.sort_by!{|exp| exp.turns_remaining}
      ships = planet.ship_count

      attacked = 0
      turns = 0
      generated = 0
      planet.incoming.each do |exp|
        attacked += exp.ship_count
        generated += exp.turns_remaining - turns
        turns = exp.turns_remaining
        diff = ships + generated - attacked
        if diff <= 0
          planet.needed << {turns, diff}
          planet.state = PlanetState::Endangered
        end
      end

      if planet.state == PlanetState::Safe
        @safe_planets << planet
      else
        @endangered_planets << planet
      end
    end
  end

  def closest_safe_planets(planet)
    @safe_planets.reject{|p| p == planet}
                .map{|p| {planet, @planet_distances[{planet.name, p.name}]}}
                .sort_by{|_,d| d}
  end

  def closest_captureable_planets(planet)
    closest = [] of Tuple(Planet, Float32)
    @conquerable_planets.each do |p|
      dist = @planet_distances[{planet.name, p.name}]
      other_ships = p.ship_count
      other_ships += dist unless p.owner.nil?
      if planet.ship_count + dist >= other_ships
        closest << {p, dist}
      end
    end
    closest.sort_by{|_,d| d}
  end


  def closest_free_planet
    closest = nil
    @own_planets.each do |own|
      @free_planets.each do |free|
        d = @planet_distances[{own.name, free.name}]
        if closest.nil? || d < closest[0]
          closest = {d, own, free}
        end
      end
    end
    return closest
  end

  private def init_planet_distances(state)
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
end
