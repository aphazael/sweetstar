module Types
  class Unittype < Base
    set_filename "unittypes"
    enum_accessor :sym

    shared_fields civ_lvl: 1,
                  max_hp: 1,
                  spd: 1,
                  dmg: 1,
                  stl: 1,
                  vis: 1

    field :gait, default: "foot"
    field :name, default: nil 
    field :sym, default: nil
    field :desc, default: nil
    field :icon, default: "man"
  end
end