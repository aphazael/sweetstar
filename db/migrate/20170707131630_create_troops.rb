class CreateTroops < ActiveRecord::Migration[5.0]
  def change
    create_table :troops do |t|
      t.string :name
      t.integer :unittype_id
      t.integer :gait_id
      t.integer :max_hp
      t.integer :civ_lvl
      t.integer :spd
      t.integer :dmg
      t.integer :stl
      t.integer :vis
      t.integer :hp
      t.belongs_to :map_grid, index: true
      t.belongs_to :tribe, index: true
      t.json :orders
      t.boolean :alive, default: true
      t.boolean :moving, default: false
      t.boolean :fighting, default: false


      # from classes:
      t.float :movement_factor_roughness
      t.float :movement_factor_density
      t.float :movement_factor_softness

      t.timestamps
    end
  end
end
