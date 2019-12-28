module Const
  class Base < ActiveYaml::Base
    # This baseclass is going to be pretty basic, since each different enum
    # type is going to have very different properties
    include ActiveHash::Enum # So we can use enum_accessor
    set_root_path "app/models/const/yaml" # Put the yaml definitions in this directory
  end
end
