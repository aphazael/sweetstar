# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170804222710) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "event_ticks", force: :cascade do |t|
    t.string   "event_class"
    t.integer  "instance_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "grid_edges", force: :cascade do |t|
    t.integer  "planet"
    t.integer  "orient"
    t.integer  "from_grid_id", null: false
    t.integer  "to_grid_id",   null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "map_grids", force: :cascade do |t|
    t.string   "location"
    t.string   "terrain"
    t.integer  "planet_tile_id"
    t.integer  "veg_lvl_id"
    t.integer  "substrate_id"
    t.integer  "landform_id"
    t.integer  "roughness"
    t.integer  "softness"
    t.integer  "density"
    t.integer  "grade"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["planet_tile_id"], name: "index_map_grids_on_planet_tile_id", using: :btree
  end

  create_table "planet_tiles", force: :cascade do |t|
    t.string   "adjacency"
    t.integer  "planet_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["planet_id"], name: "index_planet_tiles_on_planet_id", using: :btree
  end

  create_table "planets", force: :cascade do |t|
    t.string   "name"
    t.integer  "size"
    t.integer  "bodytype_id"
    t.string   "bodytype_sym"
    t.integer  "water"
    t.integer  "temp"
    t.string   "resource_map"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "tribes", force: :cascade do |t|
    t.string   "name"
    t.string   "faction"
    t.integer  "player"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "troop_events", force: :cascade do |t|
    t.integer  "troop_id"
    t.string   "command",                    null: false
    t.jsonb    "args",                       null: false
    t.datetime "start",                      null: false
    t.datetime "finish",                     null: false
    t.boolean  "completed"
    t.boolean  "cancelled",  default: false
    t.boolean  "initiated",  default: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.index ["troop_id"], name: "index_troop_events_on_troop_id", using: :btree
  end

  create_table "troops", force: :cascade do |t|
    t.string   "name"
    t.integer  "unittype_id"
    t.integer  "gait_id"
    t.integer  "max_hp"
    t.integer  "civ_lvl"
    t.integer  "spd"
    t.integer  "dmg"
    t.integer  "stl"
    t.integer  "vis"
    t.integer  "hp"
    t.integer  "map_grid_id"
    t.integer  "tribe_id"
    t.json     "orders"
    t.boolean  "alive",                     default: true
    t.boolean  "moving",                    default: false
    t.boolean  "fighting",                  default: false
    t.float    "movement_factor_roughness"
    t.float    "movement_factor_density"
    t.float    "movement_factor_softness"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.index ["map_grid_id"], name: "index_troops_on_map_grid_id", using: :btree
    t.index ["tribe_id"], name: "index_troops_on_tribe_id", using: :btree
  end

  add_foreign_key "troop_events", "troops"
end
