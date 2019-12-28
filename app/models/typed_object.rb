class TypedObject < ApplicationRecord
  extend ActiveHash::Associations::ActiveRecordExtensions
  self.abstract_class = true

  def self.type_class(typename)
    self.belongs_to_active_hash(typename, class_name: "Types::#{typename.capitalize}")
    define_method :classtype do
      self.send(typename)
    end
  end

  def initialize(args={})
    super
    # Shared fields that are ranges must be randomized
    (classtype.try(:range_field_names) || []).each do |rangename|
      attr_name = rangename.to_s.split('_')[0...-1].join("_").to_sym
      range = classtype.send(rangename)
      self[attr_name] = rand(range)
    end

    # Other shared fields can be set directly
    (classtype.try(:shared_field_names) || []).each do |fieldname|
      self[fieldname] = classtype.send(fieldname)
    end
  end
end
