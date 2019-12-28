class CreateEventTicks < ActiveRecord::Migration[5.0]
  def change
    create_table :event_ticks do |t|
      t.string :event_class
      t.integer :instance_id

      t.timestamps
    end
  end
end
