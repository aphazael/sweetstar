class Const::GridSubstrate < Const::Terrain
    set_filename "grid_substrates"
    enum_accessor :shortname

    field :shortname, default: nil
    field :softness, default: 0
    field :fertility, default: 0

    field :not_landforms, default: []
    field :not_veg, default: []
    # Eventually also things like icon, etc.
end
