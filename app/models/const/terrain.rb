module Const
  class Terrain < Base
    def self.land
      # This assumes that there is an item with id = 0 for water, and that
      # there are no gaps in the id's. This is probably a bad assumption      
      count = self.model_name.name.constantize.count
      self.model_name.name.constantize.find((1..(count-1)).to_a)
    end

    def land?
      id != 0
    end
  end
end
