class CreateGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :genres do |t|
      t.integer :tmdb_id, null: false
      t.string :name, null: false
      t.string :media_type, null: false

      t.timestamps
    end

    add_index :genres, :tmdb_id
    add_index :genres, :media_type
    add_index :genres, [ :tmdb_id, :media_type ], unique: true
  end
end
