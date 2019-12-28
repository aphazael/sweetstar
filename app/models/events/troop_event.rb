module Events
  class TroopEvent < ApplicationRecord
    # t.integer  "troop_id"
    # t.string   "command",    null: false
    # t.string   "args",       null: false
    # t.datetime "start",      null: false
    # t.datetime "finish",     null: false
    # t.boolean  "completed"   # null means not done, true indicates success and false indicates failure
    # t.boolean  "cancelled"
    # t.datetime "created_at", null: false
    # t.datetime "updated_at", null: false
    #       t.boolean :initiated


    belongs_to :troop
  end
end