class MapGrid < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  # t.string   "location"
  # t.string   "terrain"
  # t.string   "adjacency"
  ORIENTATIONS = {"0": :"3", "1": :"4", "2": :"5", "3": :"0", "4": :"1", "5": :"2"}

  has_many :troops
  belongs_to :planet_tile

  # def adjacency
  has_many :grid_edges, foreign_key: :from_grid_id
  has_many :map_grids, -> { distinct }, through: :grid_edges, source: :to_grid

  # terrain classes
  belongs_to_active_hash "veg_lvl", class_name: "Const::GridVegLvl"
  belongs_to_active_hash "landform", class_name: "Const::GridLandform"
  belongs_to_active_hash "substrate", class_name: "Const::GridSubstrate"

  def initialize(args={})
    super(args)

    generate_terrain_from_bodytype

    self.density = self.veg_lvl.density
    self.roughness = self.landform.roughness
    self.grade = self.landform.grade
    self.softness = self.substrate.softness
  end

  def generate_terrain_from_bodytype
    bodytype = self.planet_tile.planet.bodytype || Bodytype.first # We need something. Default should be rocky
    water = self.planet_tile.planet.water

    # Maybe this is a water tile
    if rand(1..100) < water
      self.substrate = Const::GridSubstrate::WATER
      self.landform = Const::GridLandform::WATER
      self.veg_lvl = Const::GridVegLvl::WATER
      return
    end

    self.substrate = Const::GridSubstrate.find_by(
      shortname: weighted_choice(bodytype.substrates)
    )

    allowed_landforms = bodytype.landforms.reject {
      |type| type.in? (self.substrate.not_landforms || [])
    }
    # TODO: instead of substrates just excluding landforms, we could have
    # substrates add or subtract from the share/chance, eg make rocks
    # more likely to have peaks
    self.landform = Const::GridLandform.find_by(
      shortname: weighted_choice(allowed_landforms)
    )

    allowed_veg = bodytype.veg_lvls.reject {
      |lvl| lvl.in? (( self.substrate.not_veg || [] ) + ( self.landform.not_veg || [] ))
    }
    self.veg_lvl = Const::GridVegLvl.find_by(
      shortname: weighted_choice(allowed_veg)
    )

  end

  def weighted_choice(possible)
    # TODO: util-ize
    total = possible.values.sum
    choice = rand(1..total)
    possible.each do |k,v|
      choice -= v
      return k if choice <= 0
    end
    fail StandardError "OffByOneBug"
  end

  def land?
    [ self.substrate.land?, 
      self.landform.land?,
      self.veg_lvl.land?,
    ].all?
  end

  def link(other_grid, direction)
    map_grids << other_grid
    edge = grid_edges.last

    edge.orient = direction if direction.in?(ORIENTATIONS.keys)
    edge.save!
  end

  def d_link(other_grid, direction)
    link(other_grid, direction)
    other_grid.link(self, ORIENTATIONS[direction])
  end

  def unlink(direction)
    # Destroy the forward edge, and save the id of the target grid
    target_id = grid_edges.where(from_grid: self, orient: direction)&.first&.destroy!&.to_grid_id # grid_edges because it's one of ours
    # Now find and destroy the reverse egde
    GridEdge.where(from_grid_id: target_id, orient: ORIENTATIONS[direction])&.first&.destroy! # GridEdge because its not ours
  end

  def adjacency
    {}.tap do |h|
      grid_edges.each{ |edge| h[edge.orient.to_sym] = edge.to_grid }
    end
  end

  def adjacent?(other_grid)
    other_grid.in? map_grids
  end

  def grid_toward(direction, distance=1, behind=false)
    grid = self
    if direction.is_a? Fixnum
      direction = (direction%6).to_s.to_sym 
      # else it better be a sym
    end
    if behind
      direction = ORIENTATIONS[direction]
    end
    distance.times do |i|
      grid = grid.adjacency[direction]
      return unless grid
    end
    return grid
  end

  def terrain
    "#{veg_lvl.shortname}-#{landform.shortname}-#{substrate.shortname}"
  end

  def all_grids_within(num=0)
    grids = Set.new([self])
    num.times do |t|
      new_grids = Set.new( grids.map{ |gg| gg.map_grids.to_a }.flatten ) 
      grids = Set.new(grids.to_a + new_grids.to_a)
    end
    grids.to_a
  end

  def all_troops_within(num=0)
    grids = all_grids_within(num)
    occupied = grids.select{|gg| gg.troops.count > 0}
    occupied.map{|gg| gg.troops.to_a}.flatten
  end


end
