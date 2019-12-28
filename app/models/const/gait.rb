class Const::Gait < Const::Base
  set_filename "gaits"
  enum_accessor :shortname

  field :shortname, default: nil
  field :roughness_penalty, default: 1
  field :density_penalty, default: 1
  field :softness_penalty, default: 1

end
