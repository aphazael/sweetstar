module Types
  class Base < ActiveYaml::Base
    include ActiveHash::Enum # So we can use enum_accessor
    set_root_path "app/models/types/yaml" # Put the yaml definitions in this directory
    # set_filename self.to_s.split("::")[-1].downcase # Use just the basic class name as the yml file name

    def self.range_fields(fieldnames)
      define_method :range_field_names do # So we know about them later
        fieldnames
      end

      fieldnames.each do |fn| # For each name
        self.field(fn, default: 0..10)  # Set a field with that name
        define_method fn do             # Make an accessor that makes
          self[fn].tap do |val|         # sure to return a range
            return val if val.is_a? Range
            # Otherwise, it must be a string-ified range stored in the yml, so:
            return Range.new(*val.split("..").map(&:to_i))
          end
        end
      end
    end

    def self.shared_fields(fieldhash)
      define_method :shared_field_names do # So we know about them later
        fieldhash.keys
      end
      fieldhash.each do |fn, default| # For each name, value pair
        self.field(fn, default: default)  # Set a field with that name and the given default
      end
    end

  end
end