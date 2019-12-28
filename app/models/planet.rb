class Planet < TypedObject
  type_class :bodytype
# t.string :name
# t.integer :size
# t.string :bodytype_sym # earthlike or rocky or ocean ir ice or whatever. eventually will be a ref to a rulemodel

# t.references :bodytype
# t.integer :water
# t.integer :temp

  has_many :planet_tiles

  def initialize(attrs)
    super
    self.bodytype_sym = classtype.sym
    PlanetTile.create!(planet: self)
  end

end
