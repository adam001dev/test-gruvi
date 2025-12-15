class CreateQueryResultCaches < ActiveRecord::Migration[8.1]
  def change
    create_table :query_result_caches do |t|
      t.string :query_key, null: false
      t.json :results
      t.datetime :last_queried_at
      t.integer :total_pages
      t.integer :total_results
      t.integer :page, default: 1, null: false

      t.timestamps
    end
    add_index :query_result_caches, :query_key, unique: true
    add_index :query_result_caches, :last_queried_at
  end
end
