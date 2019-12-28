class CreateMapGrids < ActiveRecord::Migration[5.0]
  def change
    create_table :map_grids do |t|
      t.string     :location
      t.string     :terrain

      t.belongs_to :planet_tile, index: true

      t.integer    :veg_lvl_id
      t.integer    :substrate_id
      t.integer    :landform_id

      t.integer :roughness
      t.integer :softness
      t.integer :density
      t.integer :grade

      t.timestamps
    end
  end
end
