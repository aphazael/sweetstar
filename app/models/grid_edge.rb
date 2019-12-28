class GridEdge < ApplicationRecord
  enum orient: [:"0", :"1", :"2", :"3", :"4", :"5"]

  belongs_to :from_grid, :class_name => :MapGrid
  belongs_to :to_grid, :class_name => :MapGrid
end
