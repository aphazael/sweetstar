class CreateGridEdges < ActiveRecord::Migration[5.0]
  def change
    create_table :grid_edges do |t|
      t.integer :planet
      t.integer :orient
      t.integer "from_grid_id", null: false
      t.integer "to_grid_id", null: false

      t.timestamps
    end
  end
end
