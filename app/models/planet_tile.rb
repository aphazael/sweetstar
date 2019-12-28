class PlanetTile < ApplicationRecord
  # t.integer  "planet"
  # t.string   "adjacency"

  belongs_to :planet
  has_many :map_grids

  # This is probably part of some sort of concern, or something
  ORIENTATIONS = MapGrid::ORIENTATIONS.freeze
  DIRECTIONS = ORIENTATIONS.keys.freeze

  def initialize(args)
    super(args)
    populate_tile_with_hexes(planet.size)
  end

  def self.inc_dir(val, steps=1)
    orig = val.to_s.to_i # oy!
    num = DIRECTIONS.count
    return DIRECTIONS[(orig+steps)%num]
  end

  def populate_tile_with_hexes(num_sides)
    def new_grid
      return MapGrid.create!(planet_tile: self)
    end

    # Create the center hex:
    center = new_grid()

    # Then six around it, one in each direction:
    spoke_ends = {}.tap do |h|
      DIRECTIONS.each do |dir|
        grid = new_grid()
        center.d_link(grid, dir)
        h[dir] = grid
      end
    end

    # Now connect up each of the edges
    spoke_ends.each do |dir, grid|
      next_grid = spoke_ends[self.class.inc_dir(dir)]
      grid.d_link(next_grid, self.class.inc_dir(dir, 2))
    end


    # Repeat N times for additional layers:
    num_sides.times do |num|
      # Extend the spokes:
      DIRECTIONS.each do |dir|
        spoke = new_grid()
        spoke_ends[dir].d_link(spoke, dir)
        spoke_ends[dir] = spoke
      end
      # Fill in the spaces:

      DIRECTIONS.each do |dir|
        start_spoke = spoke_ends[dir]
        end_spoke = spoke_ends[self.class.inc_dir(dir)]
        travel_dir = self.class.inc_dir(dir, 2)

        # we need 3 pointers to make this work:
        prev = start_spoke
        corner = start_spoke.adjacency[ORIENTATIONS[dir]] #reverse of dir
        below = corner.adjacency[travel_dir]
        #

        # Conveniently, the number of extra grids in this row is equal to the
        # `num` that we are up to. (except that `times` starts at zero, so +1)
        (num+1).times do |nn|
          next_grid = new_grid()
          below.d_link(next_grid, dir)
          corner.d_link(next_grid, self.class.inc_dir(dir))
          prev.d_link(next_grid, travel_dir)

          # Update pointers:
          prev = next_grid
          below = below.adjacency[travel_dir]
          corner = corner.adjacency[travel_dir]
        end

        # Now just link up the last new grid in the chain to the next spoke:
        prev.d_link(end_spoke, travel_dir)
      end
    end

    # Go through and link up the end of each line to the other end:
    loose_ends = self.map_grids.select{|mg| mg.map_grids.count < 6}

    loose_ends.each do |grid|
      filled = Set.new(grid.adjacency.keys)
      empty = Set.new(DIRECTIONS) - filled
      empty.each do |dir|
        reverse = ORIENTATIONS[dir]
        # walk down the list in the other direction until we can't go any further
        # (My god this is going to be so slow)
        next_grid = grid
        while next_grid.grid_toward(reverse)
          next_grid = next_grid.grid_toward(reverse)
        end
        # ~~Link the two together only in one direction (not because we're not sure~~
        # ~~that the dual edge is correct, but because I'm unsure about modifying~~
        # ~~the structure while looping over it)~~
        # But we have to do both at once, or we get infinite loops next time. Lolz!
        grid.d_link(next_grid, dir)
        # TODO: There's something weird going on here. The hex browser gets funky
        # at the edges. Unclear whether the linkages are wrong, or if it's just 
        # a quirk of the way we're generating the thing in return_terrain_grid. It's
        # probably that second thing
      end
    end

  end

  # Helper for display in controller
  def self.return_terrain_grid(center_map_grid_id, row_direction=:"0", radius=1)
    center = MapGrid.find(center_map_grid_id)
    upper_corner = center.grid_toward(inc_dir(row_direction, -2), radius)

    table = []
    corner = upper_corner
    len = radius+1
    # Do upper half
    radius.times do |nn|
      row = []
      grid = corner
      len.times do |tt|
        row << grid
        grid = grid.grid_toward(row_direction)
      end
      table << row
      corner = corner.grid_toward(inc_dir(row_direction, 2))
      len = len+1
    end

    # Do midline row
    row = []
    start = corner
    len.times do |nn|
      row << start
      start = start.grid_toward(row_direction)
    end
    corner = corner.grid_toward(inc_dir(row_direction, 1))
    len = len-1
    table << row

    # Do the bottom half:
    radius.times do |nn|
      row = []
      grid = corner
      len.times do |tt|
        row << grid
        grid = grid.grid_toward(row_direction)
      end
      table << row
      corner = corner.grid_toward(inc_dir(row_direction, 1))
      len = len-1
    end

    return table # f.u rubocop
  end

  # def self.create_surface(planet)
  #   # eventually, this will need to do something clever with hexagons
  #   # and tiling. For now, just generate one quadrant per size, and leave
  #   # them floating, disconnected from each other
  #   number_to_gen = planet.size
  #   number_to_gen.times do
  #     quad = self.create!(planet: planet)
  #   end
  # end

end
