class CreatePlanetTiles < ActiveRecord::Migration[5.0]
  def change
    create_table :planet_tiles do |t|
      t.string :adjacency

      t.belongs_to :planet, index: true

      t.timestamps
    end
  end
end
