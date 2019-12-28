module Types
  class Bodytype < Base
    set_filename "bodytypes"
    enum_accessor :sym

    range_fields [:water_range, :temp_range] 
#    shared_fields weather: 'hello',   # example. these fields must be defined in the model
#                  aaaa: 1234

    field :name, default: nil 
    field :sym, default: nil
    field :desc, default: nil
    field :substrates, default: {}
    field :landforms, default: {}
    field :veg_lvls, default: {}
  end
end