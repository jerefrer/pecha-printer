# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2024_11_02_220503) do
  create_table "pdfs", force: :cascade do |t|
    t.string "file"
    t.string "paper_size"
    t.string "autoscale"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "borders"
    t.boolean "portrait", default: false
    t.integer "pages_per_sheet", default: 3
  end
end
