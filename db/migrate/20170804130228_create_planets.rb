class CreatePlanets < ActiveRecord::Migration[5.0]
  def change
    create_table :planets do |t|
      t.string  :name
      t.integer :size
      t.integer :bodytype_id

      t.string  :bodytype_sym
      t.integer :water
      t.integer :temp
      t.string  :resource_map # should be t.json or something
                              # Actually we might not even want this. If we populate
                              # at the map level, we probably dont need the planet
                              # to care after init.


      t.timestamps
    end
  end
end
