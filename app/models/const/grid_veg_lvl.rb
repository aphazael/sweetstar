class Const::GridVegLvl < Const::Terrain
  set_filename "grid_veg_lvls"
  enum_accessor :shortname

  field :shortname, default: nil
  field :density, default: 0
  field :richness, default: 0

  # Eventually also things like icon, etc.
end
