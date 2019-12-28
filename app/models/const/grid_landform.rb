class Const::GridLandform < Const::Terrain
  set_filename "grid_landforms"
  enum_accessor :shortname

  field :shortname, default: nil
  field :grade, default: 0
  field :roughness, default: 0

  field :not_veg, default: []
  # Eventually also things like icon, etc.
end
