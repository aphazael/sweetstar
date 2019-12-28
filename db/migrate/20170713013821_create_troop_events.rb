class CreateTroopEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :troop_events do |t|
      t.references :troop, foreign_key: true
      t.string :command, null: false
      t.jsonb :args, null: false
      t.timestamp :start, null: false
      t.timestamp :finish, null: false
      t.boolean :completed
      t.boolean :cancelled, default: false
      t.boolean :initiated, default: false

      t.timestamps
    end
  end
end
