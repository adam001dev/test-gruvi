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

ActiveRecord::Schema[8.1].define(version: 2025_12_09_095557) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "media_type", null: false
    t.string "name", null: false
    t.integer "tmdb_id", null: false
    t.datetime "updated_at", null: false
    t.index ["media_type"], name: "index_genres_on_media_type"
    t.index ["tmdb_id", "media_type"], name: "index_genres_on_tmdb_id_and_media_type", unique: true
    t.index ["tmdb_id"], name: "index_genres_on_tmdb_id"
  end

  create_table "media_genres", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "genre_id", null: false
    t.bigint "media_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["genre_id"], name: "index_media_genres_on_genre_id"
    t.index ["media_item_id", "genre_id"], name: "index_media_genres_on_media_item_id_and_genre_id", unique: true
    t.index ["media_item_id"], name: "index_media_genres_on_media_item_id"
  end

  create_table "media_items", force: :cascade do |t|
    t.boolean "adult", default: false
    t.datetime "created_at", null: false
    t.string "media_type", null: false
    t.string "original_language"
    t.text "overview"
    t.float "popularity"
    t.string "poster_path"
    t.date "release_date"
    t.string "title", null: false
    t.integer "tmdb_id", null: false
    t.datetime "updated_at", null: false
    t.float "vote_average"
    t.integer "vote_count"
    t.index ["media_type"], name: "index_media_items_on_media_type"
    t.index ["release_date"], name: "index_media_items_on_release_date"
    t.index ["tmdb_id", "media_type"], name: "index_media_items_on_tmdb_id_and_media_type", unique: true
    t.index ["tmdb_id"], name: "index_media_items_on_tmdb_id"
  end

  create_table "query_result_caches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_queried_at"
    t.integer "page", default: 1, null: false
    t.string "query_key", null: false
    t.json "results"
    t.integer "total_pages"
    t.integer "total_results"
    t.datetime "updated_at", null: false
    t.index ["last_queried_at"], name: "index_query_result_caches_on_last_queried_at"
    t.index ["query_key"], name: "index_query_result_caches_on_query_key", unique: true
  end

  create_table "search_queries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date"
    t.string "genre_ids"
    t.datetime "last_queried_at"
    t.string "media_type"
    t.float "min_rating"
    t.integer "page", default: 1
    t.string "query_key", null: false
    t.string "sort_by"
    t.date "start_date"
    t.integer "total_pages"
    t.integer "total_results"
    t.datetime "updated_at", null: false
    t.index ["last_queried_at"], name: "index_search_queries_on_last_queried_at"
    t.index ["page"], name: "index_search_queries_on_page"
    t.index ["query_key"], name: "index_search_queries_on_query_key", unique: true
  end

  create_table "search_query_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "media_item_id", null: false
    t.bigint "search_query_id", null: false
    t.datetime "updated_at", null: false
    t.index ["media_item_id"], name: "index_search_query_results_on_media_item_id"
    t.index ["search_query_id", "media_item_id"], name: "idx_on_search_query_id_media_item_id_543be3c8dd", unique: true
    t.index ["search_query_id"], name: "index_search_query_results_on_search_query_id"
  end

  add_foreign_key "media_genres", "genres"
  add_foreign_key "media_genres", "media_items"
  add_foreign_key "search_query_results", "media_items"
  add_foreign_key "search_query_results", "search_queries"
end
